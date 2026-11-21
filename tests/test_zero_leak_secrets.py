"""Round 2 security tests: zero-context-leak canary verification, 0700/0600 permissions, and Git-tracked guards."""
from __future__ import annotations

import hashlib
import json
import os
import runpy
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "skills" / "agent-skills-setup" / "scripts" / "migrate_context.py"

CANARIES = {
    "anthropic_env": "sk-ant-CANARY-MCP-ENV-99887766",
    "custom_slot": "lin_custom_canary_slot_55443322",
    "bearer_jwt": "eyJhbGciOiJIUzI1NiJ9.CANARY_BEARER_JWT_SECRET",
    "header_key": "x-ws-canary-header-secret-889900",
    "url_pass": "CanaryUrlPass_2026!",
    "url_query": "CanaryQuerySecret_777",
    "arg_eq_key": "sk-live-CANARY-CLI-ARG-11223344",
    "arg_next_tok": "CanaryNextArgToken_5566",
    "dotenv_db": "postgres://app:CanaryDotenvDbPass_999@db.internal:5432/prod",
    "dotenv_local": "ghp_CanaryLocalGithubPat_1357924680",
}


def fp8(val: str) -> str:
    return hashlib.sha256(val.encode("utf-8")).hexdigest()[:8]


def run_raw(*args: str) -> subprocess.CompletedProcess[str]:
    env = dict(os.environ)
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    return subprocess.run(
        [sys.executable, "-B", str(SCRIPT), *args],
        capture_output=True,
        text=True,
        env=env,
        check=False,
    )


def assert_zero_canary_leak(test: unittest.TestCase, text: str, context: str) -> None:
    for label, canary in CANARIES.items():
        test.assertNotIn(canary, text, f"LEAKED canary '{label}' in {context}!")


class ZeroLeakSecretTests(unittest.TestCase):
    def test_explicit_header_argument_forms_require_redaction(self) -> None:
        inspect = runpy.run_path(str(SCRIPT))["inspect_args_secrets"]
        marker = "SAFE_TEST_MARKER"
        for args in [
            ["--header", f"Authorization: {marker}"],
            [f"--header=Authorization: {marker}"],
            [f"--headers=X-API-Key: {marker}"],
            [f"--authorization={marker}"],
        ]:
            with self.subTest(form=args[0].split("=")[0]):
                result, found = inspect(args)
                self.assertTrue(found)
                self.assertFalse(any(marker in value for value in result))
        self.assertEqual(inspect(["--port=8080"]), (["--port=8080"], []))

    def _populate_canary_source(self, ws: Path, home: Path) -> None:
        (ws / ".cursor").mkdir(parents=True, exist_ok=True)
        (home / ".cursor").mkdir(parents=True, exist_ok=True)
        # Also plant chat history + sqlite DB to prove they are ALWAYS excluded!
        (home / ".cursor" / "chats").mkdir(parents=True, exist_ok=True)
        (home / ".cursor" / "chats" / "session.jsonl").write_text('{"secret_chat": "never_copy"}\n', encoding="utf-8")
        (home / ".cursor" / "state.vscdb").write_bytes(b"SQLite format 3\x00")

        (ws / ".env").write_text(
            f"# Production DB\nDATABASE_URL={CANARIES['dotenv_db']}\nPORT=8080\n",
            encoding="utf-8",
        )
        (ws / ".env.local").write_text(
            f'export GITHUB_TOKEN="{CANARIES["dotenv_local"]}"\n',
            encoding="utf-8",
        )
        (ws / ".cursor" / "mcp.json").write_text(
            json.dumps({
                "mcpServers": {
                    "stdio-sec": {
                        "command": "npx",
                        "args": [
                            "-y",
                            "custom-mcp",
                            f"--api-key={CANARIES['arg_eq_key']}",
                            "--token",
                            CANARIES["arg_next_tok"],
                        ],
                        "env": {
                            "ANTHROPIC_API_KEY": CANARIES["anthropic_env"],
                            "LINEAR_INTEGRATION": CANARIES["custom_slot"],
                            "NODE_ENV": "production",
                            "PROJECT_REF": "${PROJECT_REF}",
                        },
                        "alwaysAllow": ["exec_sql"],
                    },
                    "remote-sec": {
                        "url": f"https://admin:{CANARIES['url_pass']}@mcp.internal.example/sse?api_key={CANARIES['url_query']}",
                        "headers": {
                            "Authorization": f"Bearer {CANARIES['bearer_jwt']}",
                            "X-Workspace-Key": CANARIES["header_key"],
                        },
                    },
                }
            }, indent=2),
            encoding="utf-8",
        )

    def test_inspect_migrate_export_import_patch_zero_stdout_stderr_md_leak_and_0600_modes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            self._populate_canary_source(ws, home)

            # 1. inspect
            p_ins = run_raw("inspect", "--workspace", str(ws), "--home", str(home), "--profiles", "cursor")
            self.assertEqual(p_ins.returncode, 0, p_ins.stderr)
            assert_zero_canary_leak(self, p_ins.stdout + p_ins.stderr, "inspect stdout/stderr")
            ins_json = json.loads(p_ins.stdout)
            # Confirm SHA-256[:8] prefixes ARE reported accurately
            self.assertIn(fp8(CANARIES["anthropic_env"]), p_ins.stdout)
            self.assertIn(fp8(CANARIES["dotenv_db"]), p_ins.stdout)

            # 2. migrate (default out-of-band secret copy!) -> claude-code, codex, vscode, gemini-cli
            p_mig = run_raw(
                "migrate",
                "--source", "cursor",
                "--target", "claude-code,codex,vscode,gemini-cli",
                "--workspace", str(ws),
                "--home", str(home),
            )
            self.assertEqual(p_mig.returncode, 0, p_mig.stderr)
            assert_zero_canary_leak(self, p_mig.stdout + p_mig.stderr, "migrate stdout/stderr")

            # Verify out-of-band secret values arrived on disk AND files are strictly 0600!
            for secret_target in (
                ws / ".mcp.json",
                ws / ".codex" / "config.toml",
                ws / ".vscode" / "mcp.json",
                ws / ".gemini" / "settings.json",
                ws / ".env",
                ws / ".env.local",
            ):
                self.assertTrue(secret_target.is_file(), f"Missing {secret_target}")
                if os.name != "nt":
                    mode = os.stat(secret_target).st_mode & 0o777
                    self.assertEqual(mode, 0o600, f"{secret_target} expected 0600, got {oct(mode)}")
                disk_text = secret_target.read_text(encoding="utf-8")
                if secret_target.name not in (".env", ".env.local"):
                    self.assertIn(CANARIES["anthropic_env"], disk_text)
                    self.assertIn(CANARIES["custom_slot"], disk_text)
                    self.assertIn(CANARIES["bearer_jwt"], disk_text)
                    self.assertNotIn("alwaysAllow", disk_text)

            # Verify Codex TOML parses cleanly and forwarded ${PROJECT_REF} via env_vars while keeping secrets in .env table
            codex_doc = tomllib.loads((ws / ".codex" / "config.toml").read_text(encoding="utf-8"))
            self.assertEqual(codex_doc["mcp_servers"]["stdio-sec"]["env_vars"], ["PROJECT_REF"])
            self.assertEqual(codex_doc["mcp_servers"]["stdio-sec"]["env"]["ANTHROPIC_API_KEY"], CANARIES["anthropic_env"])

            # Verify VS Code converted ${PROJECT_REF} -> ${env:PROJECT_REF} and root key `servers`
            vsc_doc = json.loads((ws / ".vscode" / "mcp.json").read_text(encoding="utf-8"))
            self.assertEqual(vsc_doc["servers"]["stdio-sec"]["env"]["PROJECT_REF"], "${env:PROJECT_REF}")

            # 3. export-device -> 0700 folder, 0600 files, zero canary or username leak in MIGRATION.md!
            bundle = base / "device-bundle"
            p_exp = run_raw("export-device", "--output", str(bundle), "--workspace", str(ws), "--home", str(home), "--profiles", "cursor")
            self.assertEqual(p_exp.returncode, 0, p_exp.stderr)
            assert_zero_canary_leak(self, p_exp.stdout + p_exp.stderr, "export-device stdout/stderr")
            if os.name != "nt":
                self.assertEqual(os.stat(bundle).st_mode & 0o777, 0o700)
            mig_md = (bundle / "MIGRATION.md").read_text(encoding="utf-8")
            assert_zero_canary_leak(self, mig_md, "MIGRATION.md")
            self.assertNotIn(str(home), mig_md, "MIGRATION.md leaked raw local home path!")
            self.assertIn(fp8(CANARIES["anthropic_env"]), mig_md)
            if os.name != "nt":
                for f in bundle.rglob("*"):
                    if f.is_file():
                        self.assertEqual(os.stat(f).st_mode & 0o777, 0o600, f"Bundle file {f} not 0600")
                    elif f.is_dir():
                        self.assertEqual(os.stat(f).st_mode & 0o777, 0o700, f"Bundle dir {f} not 0700")
            # Chat history and SQLite DB must NOT be in bundle!
            self.assertFalse(list(bundle.rglob("*.jsonl")))
            self.assertFalse(list(bundle.rglob("*.vscdb")))

            # 4. import-device onto brand-new machine roots -> zero stdout/stderr leak, exact 0600 secrets restored!
            new_ws, new_home = base / "new_ws", base / "new_home"
            new_ws.mkdir()
            new_home.mkdir()
            p_imp = run_raw("import-device", "--input", str(bundle), "--target", "same", "--workspace", str(new_ws), "--home", str(new_home))
            self.assertEqual(p_imp.returncode, 0, p_imp.stderr)
            assert_zero_canary_leak(self, p_imp.stdout + p_imp.stderr, "import-device stdout/stderr")
            if os.name != "nt":
                self.assertEqual(os.stat(new_ws / ".env").st_mode & 0o777, 0o600)
                self.assertEqual(os.stat(new_ws / ".cursor" / "mcp.json").st_mode & 0o777, 0o600)
            self.assertIn(CANARIES["dotenv_db"], (new_ws / ".env").read_text(encoding="utf-8"))
            self.assertIn(CANARIES["anthropic_env"], (new_ws / ".cursor" / "mcp.json").read_text(encoding="utf-8"))

    def test_redact_secrets_strips_every_canary_on_disk_while_preserving_benign_env(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            self._populate_canary_source(ws, home)

            p_mig = run_raw(
                "migrate",
                "--source", "cursor",
                "--target", "claude-code,codex,vscode",
                "--workspace", str(ws),
                "--home", str(home),
                "--redact-secrets",
            )
            self.assertEqual(p_mig.returncode, 0, p_mig.stderr)
            assert_zero_canary_leak(self, p_mig.stdout + p_mig.stderr, "--redact-secrets stdout/stderr")

            for dst in (ws / ".mcp.json", ws / ".codex" / "config.toml", ws / ".vscode" / "mcp.json"):
                disk = dst.read_text(encoding="utf-8")
                assert_zero_canary_leak(self, disk, f"--redact-secrets target {dst.name}")

            # Benign NODE_ENV="production" preserved while ANTHROPIC_API_KEY & LINEAR_INTEGRATION redacted!
            vsc = json.loads((ws / ".vscode" / "mcp.json").read_text(encoding="utf-8"))["servers"]["stdio-sec"]
            self.assertEqual(vsc["env"]["NODE_ENV"], "production")
            self.assertEqual(vsc["env"]["ANTHROPIC_API_KEY"], "${env:ANTHROPIC_API_KEY}")
            self.assertEqual(vsc["env"]["LINEAR_INTEGRATION"], "${env:LINEAR_INTEGRATION}")

            codex = tomllib.loads((ws / ".codex" / "config.toml").read_text(encoding="utf-8"))["mcp_servers"]["stdio-sec"]
            self.assertIn("ANTHROPIC_API_KEY", codex["env_vars"])
            self.assertIn("LINEAR_INTEGRATION", codex["env_vars"])
            self.assertEqual(codex["env"]["NODE_ENV"], "production")

            # Also verify export-device --redact-secrets strips .env and MCP secrets inside bundle
            bundle = base / "redacted-bundle"
            p_exp = run_raw("export-device", "--output", str(bundle), "--workspace", str(ws), "--home", str(home), "--profiles", "cursor", "--redact-secrets")
            self.assertEqual(p_exp.returncode, 0)
            for f in bundle.rglob("*"):
                if f.is_file():
                    assert_zero_canary_leak(self, f.read_text(encoding="utf-8"), f"redacted bundle file {f.name}")

    def test_git_tracked_target_protection_routes_claude_and_refuses_tracked_codex(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "repo", base / "home"
            ws.mkdir()
            home.mkdir()
            self._populate_canary_source(ws, home)

            # Initialize a Git repo and track .mcp.json and .codex/config.toml
            subprocess.run(["git", "-C", str(ws), "init", "-q"], check=True)
            subprocess.run(["git", "-C", str(ws), "config", "user.email", "test@example.com"], check=True)
            subprocess.run(["git", "-C", str(ws), "config", "user.name", "Test"], check=True)
            (ws / ".mcp.json").write_text('{"mcpServers": {}}\n', encoding="utf-8")
            (ws / ".codex").mkdir(exist_ok=True)
            (ws / ".codex" / "config.toml").write_text('approval_policy = "on-request"\n', encoding="utf-8")
            subprocess.run(["git", "-C", str(ws), "add", ".mcp.json", ".codex/config.toml"], check=True)
            subprocess.run(["git", "-C", str(ws), "commit", "-q", "-m", "init tracked configs"], check=True)

            # 1. Claude Code: secret MCP must be routed to untracked ~/.claude.json projects[ws].mcpServers!
            p_cl = run_raw("migrate", "--source", "cursor", "--target", "claude-code", "--workspace", str(ws), "--home", str(home), "--categories", "mcp")
            self.assertEqual(p_cl.returncode, 0, p_cl.stderr)
            assert_zero_canary_leak(self, p_cl.stdout + p_cl.stderr, "claude git-tracked routing")
            self.assertEqual((ws / ".mcp.json").read_text(encoding="utf-8"), '{"mcpServers": {}}\n')
            local_claude = json.loads((home / ".claude.json").read_text(encoding="utf-8"))
            routed_srvs = local_claude["projects"][str(ws.resolve())]["mcpServers"]
            self.assertIn("stdio-sec", routed_srvs)
            self.assertEqual(routed_srvs["stdio-sec"]["env"]["ANTHROPIC_API_KEY"], CANARIES["anthropic_env"])
            if os.name != "nt":
                self.assertEqual(os.stat(home / ".claude.json").st_mode & 0o777, 0o600)

            # 2. Codex: tracked .codex/config.toml MUST refuse literal secrets with exit code 2!
            p_cx = run_raw("migrate", "--source", "cursor", "--target", "codex", "--workspace", str(ws), "--home", str(home), "--categories", "mcp")
            self.assertEqual(p_cx.returncode, 2)
            assert_zero_canary_leak(self, p_cx.stdout + p_cx.stderr, "codex git-tracked refusal")
            self.assertEqual(json.loads(p_cx.stdout)["error"], "git_tracked_secret_refusal")
            self.assertEqual((ws / ".codex" / "config.toml").read_text(encoding="utf-8"), 'approval_policy = "on-request"\n')

            # 3. Malformed JSON with canary secret MUST NOT leak canary on parse error!
            bad_mcp = ws / "broken-mcp.json"
            bad_mcp.write_text(f'{{"mcpServers": {{"x": {{"env": {{"API_KEY": "{CANARIES["anthropic_env"]}"', encoding="utf-8")
            p_bad = run_raw("patch-mcp", "--src-file", str(bad_mcp), "--dst-file", str(ws / "out.json"), "--workspace", str(ws), "--home", str(home))
            self.assertEqual(p_bad.returncode, 2)
            assert_zero_canary_leak(self, p_bad.stdout + p_bad.stderr, "malformed json parse error")


if __name__ == "__main__":
    unittest.main()
