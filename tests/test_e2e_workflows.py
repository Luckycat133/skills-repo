"""Round 3 end-to-end tests: single-sentence multi-profile workflows, all 15 profiles, and eval fixture runs."""
from __future__ import annotations

import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "skills" / "agent-skills-setup" / "scripts" / "migrate_context.py"


def run_cli(*args: str) -> tuple[int, dict, str]:
    env = dict(os.environ)
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    proc = subprocess.run(
        [sys.executable, "-B", str(SCRIPT), *args],
        capture_output=True,
        text=True,
        env=env,
        check=False,
    )
    data = json.loads(proc.stdout) if proc.stdout.strip().startswith("{") else {}
    return proc.returncode, data, proc.stderr


class EndToEndWorkflowTests(unittest.TestCase):
    def test_one_sentence_full_cursor_to_claude_and_codex_workflow(self) -> None:
        canary = "sk-ant-E2E-WORKFLOW-KEY-776655"
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "project", base / "home"
            (ws / ".cursor" / "rules").mkdir(parents=True)
            (ws / ".cursor" / "skills" / "api-helper" / "scripts").mkdir(parents=True)
            (ws / ".cursor" / "skills" / "agent-skills-setup").mkdir(parents=True)
            (ws / ".cursor" / "commands").mkdir(parents=True)
            (ws / ".cursor" / "agents").mkdir(parents=True)
            home.mkdir()

            # Self-copy guard: agent-skills-setup must NOT be auto-copied
            (ws / ".cursor" / "skills" / "agent-skills-setup" / "SKILL.md").write_text(
                "---\nname: agent-skills-setup\ndescription: self\n---\nSelf\n", encoding="utf-8"
            )
            # Real user skill with executable helper script
            (ws / ".cursor" / "skills" / "api-helper" / "SKILL.md").write_text(
                "---\nname: api-helper\ndescription: Generate OpenAPI client\n---\nUse scripts/gen.sh.\n",
                encoding="utf-8",
            )
            gen_sh = ws / ".cursor" / "skills" / "api-helper" / "scripts" / "gen.sh"
            gen_sh.write_text("#!/usr/bin/env bash\necho ok\n", encoding="utf-8")
            gen_sh.chmod(0o755)

            (ws / ".cursor" / "rules" / "testing.mdc").write_text(
                '---\nglobs: "tests/**/*.py"\nalwaysApply: false\n---\nNo network in unit tests.\n',
                encoding="utf-8",
            )
            (ws / ".cursor" / "commands" / "release-notes.md").write_text(
                "Draft concise release notes from git log.\n", encoding="utf-8"
            )
            (ws / ".cursor" / "agents" / "security-reviewer.md").write_text(
                "---\nname: security-reviewer\ndescription: Audit auth paths\n---\nCheck authz boundaries.\n",
                encoding="utf-8",
            )
            (ws / ".cursor" / "hooks.json").write_text(
                '{"hooks": {"afterFileEdit": [{"command": "ruff check"}]}}\n', encoding="utf-8"
            )
            (ws / ".cursor" / "mcp.json").write_text(
                json.dumps({
                    "mcpServers": {
                        "github": {
                            "command": "npx",
                            "args": ["-y", "@modelcontextprotocol/server-github"],
                            "env": {"GITHUB_PERSONAL_ACCESS_TOKEN": canary},
                        }
                    }
                }),
                encoding="utf-8",
            )

            code, out, stderr = run_cli(
                "migrate",
                "--source", "cursor",
                "--target", "claude-code,codex",
                "--workspace", str(ws),
                "--home", str(home),
            )
            self.assertEqual(code, 0, out)
            self.assertNotIn(canary, json.dumps(out) + stderr)

            # Verify migrated artifacts:
            self.assertFalse((ws / ".claude" / "skills" / "agent-skills-setup").exists())
            migrated_sh = ws / ".claude" / "skills" / "api-helper" / "scripts" / "gen.sh"
            self.assertTrue(migrated_sh.is_file())
            if os.name != "nt":
                self.assertTrue(bool(migrated_sh.stat().st_mode & stat.S_IXUSR))
            self.assertTrue((ws / ".agents" / "skills" / "api-helper" / "SKILL.md").is_file())
            self.assertTrue((ws / ".claude" / "rules" / "testing.md").is_file())
            self.assertTrue((ws / ".claude" / "commands" / "release-notes.md").is_file())
            self.assertTrue((ws / ".claude" / "agents" / "security-reviewer.md").is_file())
            # Hooks parked in .migration-review/hooks/, NOT live .claude/settings.json!
            self.assertFalse((ws / ".claude" / "settings.json").exists())
            self.assertTrue((ws / ".migration-review" / "hooks" / "claude-code" / "project" / "hooks.json").is_file())
            # Secret MCP written in 0600 mode on both targets:
            if os.name != "nt":
                self.assertEqual(os.stat(ws / ".mcp.json").st_mode & 0o777, 0o600)
                self.assertEqual(os.stat(ws / ".codex" / "config.toml").st_mode & 0o777, 0o600)

    def test_device_transfer_and_all_15_profiles_coverage(self) -> None:
        canary = "sk-live-DEVICE-MOVE-CANARY-246810"
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            old_ws, old_home = base / "old_ws", base / "old_home"
            old_ws.mkdir()
            old_home.mkdir()

            # Seed authored memory in Claude, OpenCode V2 MCP, Gemini shared settings, and a Skill
            (old_home / ".claude" / "memory").mkdir(parents=True)
            (old_home / ".claude" / "memory" / "style.md").write_text("Prefer Python 3.11 stdlib.\n", encoding="utf-8")
            (old_ws / "GEMINI.md").write_text("Keep functions small.\n", encoding="utf-8")
            (old_ws / ".gemini").mkdir()
            (old_ws / ".gemini" / "settings.json").write_text(
                json.dumps({
                    "theme": "Dracula",
                    "trust": {"folder": True},
                    "mcpServers": {
                        "stream-api": {
                            "httpUrl": "https://api.example.com/mcp",
                            "headers": {"Authorization": f"Bearer {canary}"},
                        }
                    },
                }),
                encoding="utf-8",
            )
            sk = old_ws / ".gemini" / "skills" / "db-check" / "scripts"
            sk.mkdir(parents=True)
            (sk.parent / "SKILL.md").write_text("---\nname: db-check\ndescription: Check schema\n---\nRun check.py.\n", encoding="utf-8")
            (sk / "check.py").write_text("#!/usr/bin/env python3\nprint('ok')\n", encoding="utf-8")
            (sk / "check.py").chmod(0o755)

            bundle = base / "laptop-transfer"
            code_e, out_e, err_e = run_cli(
                "export-device",
                "--output", str(bundle),
                "--workspace", str(old_ws),
                "--home", str(old_home),
                "--profiles", "all",
            )
            self.assertEqual(code_e, 0, out_e)
            self.assertNotIn(canary, json.dumps(out_e) + err_e)
            # Exported Gemini MCP file must NOT contain sibling 'theme' or 'trust'!
            gem_mcp_bundle = bundle / "files/gemini-cli/project/mcp/selected-mcp.json"
            gem_bundle_doc = json.loads(gem_mcp_bundle.read_text(encoding="utf-8"))
            self.assertNotIn("theme", gem_bundle_doc)
            self.assertNotIn("trust", gem_bundle_doc)

            # Import onto a new machine targeting ALL remaining profiles!
            new_ws, new_home = base / "new_ws", base / "new_home"
            new_ws.mkdir()
            new_home.mkdir()
            # Pre-seed OpenCode V2 structure (`mcp.servers`) and Zed competing `.cursorrules`
            (new_ws / "opencode.json").write_text('{"mcp": {"servers": {}}}\n', encoding="utf-8")
            (new_ws / ".cursorrules").write_text("Legacy cursor rule.\n", encoding="utf-8")

            all_targets = (
                "cursor,claude-code,codex,vscode,copilot-cli,gemini-cli,"
                "antigravity,windsurf,cline,kilocode,zed,opencode,kimi-code,qwen-code,pi"
            )
            code_i, out_i, err_i = run_cli(
                "import-device",
                "--input", str(bundle),
                "--target", all_targets,
                "--workspace", str(new_ws),
                "--home", str(new_home),
            )
            self.assertEqual(code_i, 0, out_i)
            self.assertNotIn(canary, json.dumps(out_i) + err_i)

            # Verify OpenCode V2 preserved `mcp.servers` container!
            oc = json.loads((new_ws / "opencode.json").read_text(encoding="utf-8"))
            self.assertIn("stream-api", oc["mcp"]["servers"])
            self.assertEqual(oc["mcp"]["servers"]["stream-api"]["type"], "remote")

            # Verify Antigravity used `serverUrl` and Gemini used `httpUrl`:
            ag = json.loads((new_ws / ".agents" / "mcp_config.json").read_text(encoding="utf-8"))
            self.assertEqual(ag["mcpServers"]["stream-api"]["serverUrl"], "https://api.example.com/mcp")
            gm = json.loads((new_ws / ".gemini" / "settings.json").read_text(encoding="utf-8"))
            self.assertEqual(gm["mcpServers"]["stream-api"]["httpUrl"], "https://api.example.com/mcp")

            # Verify Zed first-match shadow warning fired because `.cursorrules` existed!
            zed_warnings = [w for w in out_i["warnings"] if w.get("code") == "zed_first_match_shadow_check"]
            self.assertTrue(zed_warnings)

            # Verify executable bit survived export -> import on Skill script!
            restored_py = new_ws / ".kilo" / "skills" / "db-check" / "scripts" / "check.py"
            self.assertTrue(restored_py.is_file())
            if os.name != "nt":
                self.assertTrue(bool(restored_py.stat().st_mode & stat.S_IXUSR))

            # Verify Claude authored memory restored cleanly:
            self.assertTrue((new_home / ".claude" / "memory" / "style.md").is_file())

    def test_patch_mcp_openclaw_nodehost_preserves_standard_env_syntax(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            src = base / "junie-mcp.json"
            dst = base / "openclaw.json"
            src.write_text(
                json.dumps({
                    "mcpServers": {
                        "local-git": {
                            "command": "uvx",
                            "args": ["mcp-server-git"],
                            "env": {"GIT_TOKEN": "${GIT_TOKEN}"},
                        }
                    }
                }),
                encoding="utf-8",
            )
            dst.write_text('{"mcp": {"servers": {"gateway-only": {"command": "node"}}}}\n', encoding="utf-8")

            code, out, _ = run_cli(
                "patch-mcp",
                "--src-file", str(src),
                "--src-key-path", "mcpServers",
                "--dst-file", str(dst),
                "--dst-key-path", "nodeHost.mcp.servers",
                "--workspace", str(base),
                "--home", str(base),
            )
            self.assertEqual(code, 0, out)
            parsed = json.loads(dst.read_text(encoding="utf-8"))
            # Gateway server untouched; nodeHost server uses ${GIT_TOKEN} (not VS Code ${env:GIT_TOKEN})!
            self.assertIn("gateway-only", parsed["mcp"]["servers"])
            nh_srv = parsed["nodeHost"]["mcp"]["servers"]["local-git"]
            self.assertEqual(nh_srv["env"]["GIT_TOKEN"], "${GIT_TOKEN}")
            self.assertNotIn("type", nh_srv)

    def test_evals_cases_json_fixtures_execute_cleanly_through_script(self) -> None:
        cases_doc = json.loads((ROOT / "evals" / "cases.json").read_text(encoding="utf-8"))
        cases = {c["id"]: c for c in cases_doc["cases"]}

        # 1. scoped-rule fixture
        with tempfile.TemporaryDirectory() as tmp:
            ws = Path(tmp) / "ws"
            home = Path(tmp) / "home"
            ws.mkdir()
            home.mkdir()
            for rel, content in cases["scoped-rule"]["input_files"].items():
                p = ws / rel
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(content, encoding="utf-8")
            code, _, _ = run_cli("migrate", "--source", "cursor", "--target", "claude-code", "--workspace", str(ws), "--home", str(home), "--scope", "project")
            self.assertEqual(code, 0)
            self.assertEqual((ws / "CLAUDE.md").read_text(encoding="utf-8"), cases["scoped-rule"]["expected_files"]["CLAUDE.md"])
            out_rule = (ws / ".claude/rules/python-tests.md").read_text(encoding="utf-8")
            self.assertIn('"tests/**/*.py"', out_rule)

        # 2. mcp-toml fixture
        with tempfile.TemporaryDirectory() as tmp:
            ws = Path(tmp) / "ws"
            home = Path(tmp) / "home"
            ws.mkdir()
            home.mkdir()
            for rel, content in cases["mcp-toml"]["input_files"].items():
                p = ws / rel
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(content, encoding="utf-8")
            code, _, _ = run_cli(
                "patch-mcp",
                "--src-file", str(ws / "selected-mcp.json"),
                "--src-key-path", "mcpServers",
                "--dst-file", str(ws / ".codex/config.toml"),
                "--dst-key-path", "mcp_servers",
                "--workspace", str(ws),
                "--home", str(home),
            )
            self.assertEqual(code, 0)
            self.assertEqual(
                tomllib.loads((ws / ".codex/config.toml").read_text(encoding="utf-8")),
                tomllib.loads(cases["mcp-toml"]["expected_files"][".codex/config.toml"]),
            )


if __name__ == "__main__":
    unittest.main()
