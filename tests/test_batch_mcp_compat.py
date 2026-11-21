"""Offline regression coverage for MCP configuration migration and transfer."""
import json
import tempfile
import tomllib
import unittest
from pathlib import Path

from test_migrate_torture import run_cli


class BatchMcpCompat(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.root = Path(folder.name).resolve()
        self.home, self.source, self.dest = (self.root / n for n in ("home", "source", "dest"))
        for d in (self.home, self.source, self.dest):
            d.mkdir()

    def write(self, relative, value):
        path = self.source / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value if isinstance(value, str) else json.dumps(value))
        return path

    def cli(self, command, *arguments, workspace=None, code=0):
        actual, result, stderr = run_cli(
            command, *arguments, "--workspace", str(workspace or self.source), "--home", str(self.home)
        )
        self.assertEqual(actual, code, (result, stderr))
        return result

    def transfer(self, profile, strict=True, code=0):
        bundle = self.root / "transfer"
        self.cli("export-device", "--profiles", profile, "--scope", "project", "--categories", "mcp", "--output", str(bundle))
        return self.cli("import-device", "--input", str(bundle), "--target", "same",
                        *(("--strict-conflicts",) if strict else ()), workspace=self.dest, code=code)

    def test_explicit_sse_round_trip_does_not_guess_from_the_url(self):
        self.write(".mcp.json", {"mcpServers": {
            "events": {"type": "sse", "url": "https://example.invalid/events"},
            "stream": {"type": "http", "url": "https://example.invalid/sse"},
        }})
        self.transfer("claude-code")
        decoded = json.loads((self.dest / ".mcp.json").read_text())["mcpServers"]
        self.assertEqual(decoded["events"]["type"], "sse")
        self.assertEqual(decoded["stream"]["type"], "http")

    def test_codex_retains_independent_timeouts(self):
        self.write(".codex/config.toml", '[mcp_servers.demo]\ncommand = "fixture"\n'
                   'startup_timeout_sec = 120\ntool_timeout_sec = 300.5\n')
        self.transfer("codex")
        server = tomllib.loads((self.dest / ".codex/config.toml").read_text())["mcp_servers"]["demo"]
        self.assertEqual(server["startup_timeout_sec"], 120)
        self.assertEqual(server["tool_timeout_sec"], 300.5)

    def test_vscode_argument_and_url_interpolation_and_header_idempotence(self):
        self.write(".cursor/mcp.json", {"mcpServers": {
            "web": {"url": "https://${MCP_HOST}/mcp", "headers": {"Authorization": "Bearer synthetic-fixture"}},
            "local": {"command": "fixture", "args": ["--token", "fixture-only", "--path=${TEST_PATH}"]},
        }})
        args = ("--source", "cursor", "--target", "vscode", "--scope", "project",
                "--categories", "mcp", "--redact-secrets", "--strict-conflicts")
        self.cli("migrate", *args)
        file = self.source / ".vscode/mcp.json"
        before = file.read_bytes()
        servers = json.loads(before)["servers"]
        self.assertEqual(servers["web"]["url"], "https://${env:MCP_HOST}/mcp")
        self.assertEqual(servers["web"]["headers"]["Authorization"], "Bearer ${env:WEB_AUTHORIZATION}")
        self.assertEqual(servers["local"]["args"], ["--token", "${env:TOKEN}", "--path=${env:TEST_PATH}"])
        self.assertEqual(self.cli("migrate", *args)["summary"]["noop"], 2)
        self.assertEqual(file.read_bytes(), before)

    def test_transfer_defers_vscode_inputs_instead_of_installing_dangling_references(self):
        self.write(".vscode/mcp.json", {"inputs": [{"id": "fixture", "type": "promptString", "password": True}],
                   "servers": {"tool": {"type": "stdio", "command": "fixture", "args": ["${input:fixture}"]}}})
        report = self.transfer("vscode", code=3)
        self.assertEqual(report["summary"]["deferred"], 1)
        self.assertFalse((self.dest / ".vscode/mcp.json").exists())

    def test_transfer_defers_absolute_cwd_without_changing_destination(self):
        self.write(".cursor/mcp.json", {"mcpServers": {"local": {
            "command": "fixture", "cwd": str(self.source / "sub"),
        }}})
        report = self.transfer("cursor", code=3)
        self.assertEqual(report["summary"]["deferred"], 1)
        self.assertFalse((self.dest / ".cursor/mcp.json").exists())

    def test_patch_mcp_uses_requested_nested_toml_table_and_is_idempotent(self):
        src = self.write("mcp.json", {"mcpServers": {"demo": {"command": "fixture", "env": {"MODE": "offline"}}}})
        dst = self.write("config.toml", "[settings]\nkeep = true\n")
        args = ("--src-file", str(src), "--dst-file", str(dst), "--dst-key-path", "/clients/local.set")
        self.cli("patch-mcp", *args)
        before = dst.read_bytes()
        result = tomllib.loads(before.decode())
        self.assertEqual(result["clients"]["local.set"]["demo"]["env"], {"MODE": "offline"})
        self.assertTrue(result["settings"]["keep"])
        self.assertEqual(self.cli("patch-mcp", *args)["actions"][0]["outcome"], "noop")
        self.assertEqual(dst.read_bytes(), before)
