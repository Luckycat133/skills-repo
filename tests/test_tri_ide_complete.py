"""Comprehensive tests for Antigravity, Claude Code, Codex full export/import & 3-way equivalent migration."""
from __future__ import annotations

import json
import os
from pathlib import Path
import re
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


class TriIdeCompleteTests(unittest.TestCase):
    def test_antigravity_full_export_and_same_profile_restore(self) -> None:
        canary = "sk-ant-AGY-ROUNDTRIP-99887766"
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "old_ws", base / "old_home"
            ws.mkdir()
            home.mkdir()

            # Project & user instructions + all 4 Antigravity trigger modes
            (ws / "AGENTS.md").write_text("Project Antigravity root rules.\n", encoding="utf-8")
            (ws / ".agents" / "rules").mkdir(parents=True)
            (ws / ".agents" / "rules" / "py.md").write_text(
                '---\ntrigger: glob\nglobs: "*.py, tests/**/*.py"\ndescription: Python style\n---\nUse type hints.\n',
                encoding="utf-8",
            )
            (ws / ".agents" / "rules" / "db.md").write_text(
                '---\ntrigger: model_decision\ndescription: "Database migrations"\n---\nUse expand-contract.\n',
                encoding="utf-8",
            )
            (ws / ".agents" / "rules" / "release.md").write_text(
                "---\ntrigger: manual\n---\nVerify changelog before tagging.\n",
                encoding="utf-8",
            )

            ag_cfg = home / ".gemini" / "config"
            (ag_cfg / "rules").mkdir(parents=True)
            (ag_cfg / "AGENTS.md").write_text("Global Antigravity guidelines.\n", encoding="utf-8")
            (ag_cfg / "rules" / "global-always.md").write_text(
                "---\ntrigger: always_on\n---\nKeep functions small.\n", encoding="utf-8"
            )

            # Skills + manifests + workflows + agents (flat & nested) + hooks + scripts + sidecars
            sk_dir = ag_cfg / "skills" / "demo-skill" / "scripts"
            sk_dir.mkdir(parents=True)
            (sk_dir.parent / "SKILL.md").write_text(
                "---\nname: demo-skill\ndescription: Demo skill\n---\nRun scripts/helper.sh\n", encoding="utf-8"
            )
            sh = sk_dir / "helper.sh"
            sh.write_text("#!/usr/bin/env bash\necho ok\n", encoding="utf-8")
            sh.chmod(0o755)

            (ag_cfg / "skills.json").write_text('{"entries": [{"path": "/tmp/custom"}]}\n', encoding="utf-8")
            (ws / ".agents" / "rules.json").write_text('{"entries": []}\n', encoding="utf-8")

            (ws / ".agents" / "workflows").mkdir(parents=True)
            (ws / ".agents" / "workflows" / "ship.md").write_text("# Ship workflow\nRun checks.\n", encoding="utf-8")

            (ag_cfg / "agents" / "nested-reviewer").mkdir(parents=True)
            (ag_cfg / "agents" / "nested-reviewer" / "agent.md").write_text(
                "---\nname: nested-reviewer\ndescription: Review diffs\ntools: [read_file]\nsubagent: true\nmainAgent: false\n---\nInspect PRs.\n",
                encoding="utf-8",
            )
            (ws / ".agents" / "agents").mkdir(parents=True)
            (ws / ".agents" / "agents" / "sec.md").write_text(
                "---\nname: sec\ndescription: Security audit\ntools: [grep_search, run_command]\n---\nAudit code.\n",
                encoding="utf-8",
            )

            (ag_cfg / "hooks.json").write_text(
                '{"lint": {"PostToolUse": [{"matcher": "write_file", "hooks": [{"type": "command", "command": "echo lint"}]}]}}\n',
                encoding="utf-8",
            )
            (ag_cfg / "scripts").mkdir(parents=True)
            sc = ag_cfg / "scripts" / "sub.py"
            sc.write_text("#!/usr/bin/env python3\nprint('hi')\n", encoding="utf-8")
            sc.chmod(0o755)

            (ag_cfg / "sidecars" / "watcher").mkdir(parents=True)
            (ag_cfg / "sidecars" / "watcher" / "sidecar.json").write_text(
                '{"command": "python3", "args": ["watch.py"]}\n', encoding="utf-8"
            )

            # Plugins (with binary asset + executable script) + config.json registry & userSettings + CLI settings
            plug = ag_cfg / "plugins" / "custom-plug"
            (plug / "assets").mkdir(parents=True)
            (plug / "plugin.json").write_text('{"name": "custom-plug", "version": "0.1.0"}\n', encoding="utf-8")
            (plug / "assets" / "logo.png").write_bytes(b"\x89PNG\r\n\x1a\n\x00\x00\x00\x01")
            (ag_cfg / "config.json").write_text(
                json.dumps({
                    "plugins": {"context7": {"installedFrom": {"id": "official/context7", "version": "1.0.1"}}},
                    "userSettings": {
                        "themeMode": "THEME_MODE_DARK",
                        "orchestratorModel": "MODEL_PLACEHOLDER_M532",
                        "permissionPreset": "AGENT_PERMISSION_PRESET_TURBO",
                        "enableTerminalSandbox": False,
                        "remoteControlEnabled": True,
                    },
                }),
                encoding="utf-8",
            )
            cli_dir = home / ".gemini" / "antigravity-cli"
            cli_dir.mkdir(parents=True)
            (cli_dir / "settings.json").write_text('{"verbosity": "low", "agentMode": "auto"}\n', encoding="utf-8")
            (cli_dir / "keybindings.json").write_text('{"cli.cycle_mode": ["shift+tab"]}\n', encoding="utf-8")

            # MCP with secret + timeoutSeconds + enabledTools
            (ag_cfg / "mcp_config.json").write_text(
                json.dumps({
                    "mcpServers": {
                        "remote-api": {
                            "serverUrl": "https://api.example.com/mcp/",
                            "headers": {"Authorization": f"Bearer {canary}"},
                            "timeoutSeconds": 600,
                            "enabledTools": ["search"],
                        }
                    }
                }),
                encoding="utf-8",
            )

            # Non-portable state must be excluded
            (home / ".gemini" / "antigravity" / "conversations").mkdir(parents=True)
            (home / ".gemini" / "jetski-standalone-oauth-token").write_text("oauth-secret", encoding="utf-8")

            bundle = base / "agy-bundle"
            code_e, out_e, err_e = run_cli(
                "export-device", "--profiles", "anti", "--workspace", str(ws), "--home", str(home), "--output", str(bundle)
            )
            self.assertEqual(code_e, 0, out_e)
            self.assertNotIn(canary, json.dumps(out_e) + err_e + (bundle / "MIGRATION.md").read_text(encoding="utf-8"))
            self.assertIn("totals", out_e)

            # Restore onto new home & workspace (default parks sidecars/hooks, --activate-hooks restores them)
            new_ws, new_home = base / "new_ws", base / "new_home"
            new_ws.mkdir()
            new_home.mkdir()
            code_i, out_i, err_i = run_cli(
                "import-device", "--input", str(bundle), "--target", "same",
                "--workspace", str(new_ws), "--home", str(new_home),
            )
            self.assertEqual(code_i, 0, out_i)
            self.assertNotIn(canary, json.dumps(out_i) + err_i)

            new_cfg = new_home / ".gemini" / "config"
            self.assertIn("Project Antigravity root rules.", (new_ws / "AGENTS.md").read_text(encoding="utf-8"))
            self.assertIn("Global Antigravity guidelines.", (new_cfg / "AGENTS.md").read_text(encoding="utf-8"))
            self.assertIn("Keep functions small.", (new_cfg / "AGENTS.md").read_text(encoding="utf-8"))
            self.assertIn("trigger: glob", (new_ws / ".agents" / "rules" / "py.md").read_text(encoding="utf-8"))
            self.assertIn("trigger: model_decision", (new_ws / ".agents" / "rules" / "db.md").read_text(encoding="utf-8"))
            self.assertIn("trigger: manual", (new_ws / ".agents" / "rules" / "release.md").read_text(encoding="utf-8"))
            self.assertTrue((new_cfg / "skills" / "demo-skill" / "SKILL.md").is_file())
            self.assertTrue((new_ws / ".agents" / "workflows" / "ship.md").is_file())
            self.assertTrue((new_cfg / "agents" / "nested-reviewer" / "agent.md").is_file())
            self.assertTrue((new_ws / ".agents" / "agents" / "sec.md").is_file())
            self.assertEqual((new_cfg / "plugins" / "custom-plug" / "assets" / "logo.png").read_bytes(), b"\x89PNG\r\n\x1a\n\x00\x00\x00\x01")
            self.assertTrue((new_cfg / "skills.json").is_file())
            self.assertTrue((new_ws / ".agents" / "rules.json").is_file())
            self.assertTrue((new_cfg / "scripts" / "sub.py").is_file())
            if os.name != "nt":
                self.assertTrue(bool((new_cfg / "scripts" / "sub.py").stat().st_mode & stat.S_IXUSR))
                self.assertEqual(os.stat(new_cfg / "mcp_config.json").st_mode & 0o777, 0o600)

            restored_cfg = json.loads((new_cfg / "config.json").read_text(encoding="utf-8"))
            self.assertIn("context7", restored_cfg["plugins"])
            self.assertEqual(restored_cfg["userSettings"]["themeMode"], "THEME_MODE_DARK")
            self.assertNotIn("permissionPreset", restored_cfg["userSettings"])
            self.assertNotIn("remoteControlEnabled", restored_cfg["userSettings"])

            restored_cli = json.loads((new_home / ".gemini" / "antigravity-cli" / "settings.json").read_text(encoding="utf-8"))
            self.assertEqual(restored_cli, {"verbosity": "low"})
            self.assertTrue((new_home / ".gemini" / "antigravity-cli" / "keybindings.json").is_file())

            restored_mcp = json.loads((new_cfg / "mcp_config.json").read_text(encoding="utf-8"))
            self.assertEqual(restored_mcp["mcpServers"]["remote-api"]["timeoutSeconds"], 600)
            self.assertEqual(restored_mcp["mcpServers"]["remote-api"]["enabledTools"], ["search"])

            # Hooks and sidecars stayed parked on default import; excluded state not copied
            self.assertFalse((new_cfg / "hooks.json").exists())
            self.assertFalse((new_cfg / "sidecars").exists())
            self.assertFalse((new_home / ".gemini" / "jetski-standalone-oauth-token").exists())
            self.assertTrue((new_ws / ".migration-review" / "sidecars" / "antigravity" / "watcher" / "sidecar.json").is_file())

            # Re-import with --activate-hooks activates hooks & sidecars cleanly
            code_act, out_act, _ = run_cli(
                "import-device", "--input", str(bundle), "--target", "same",
                "--workspace", str(new_ws), "--home", str(new_home), "--activate-hooks",
            )
            self.assertEqual(code_act, 0, out_act)
            self.assertTrue((new_cfg / "hooks.json").is_file())
            self.assertTrue((new_cfg / "sidecars" / "watcher" / "sidecar.json").is_file())

    def test_claude_code_full_export_and_restore_with_hooks_settings_memory(self) -> None:
        canary_mcp = "sk-cc-MCP-CANARY-112233"
        canary_env = "sk-cc-ENV-CANARY-445566"
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "old_proj", base / "old_home"
            ws.mkdir()
            home.mkdir()

            (ws / "CLAUDE.md").write_text("Project Claude guide.\n", encoding="utf-8")
            (home / ".claude" / "rules").mkdir(parents=True)
            (home / ".claude" / "CLAUDE.md").write_text("Global Claude guide.\n", encoding="utf-8")
            (home / ".claude" / "rules" / "tests.md").write_text('---\npaths:\n  - "tests/**"\n---\nUse unit mocks.\n', encoding="utf-8")
            (home / ".claude" / "commands").mkdir(parents=True)
            (home / ".claude" / "commands" / "ship.md").write_text("---\ndescription: Ship release\n---\nCheck git status.\n", encoding="utf-8")
            (home / ".claude" / "agents").mkdir(parents=True)
            (home / ".claude" / "agents" / "auditor.md").write_text("---\nname: auditor\ndescription: Audit code\ntools: Read, Bash\n---\nAudit.\n", encoding="utf-8")

            # settings.json with portable keys, secret env, hooks, and stripped permissions
            (home / ".claude" / "settings.json").write_text(
                json.dumps({
                    "theme": "dark",
                    "model": "sonnet",
                    "skipDangerousModePermissionPrompt": True,
                    "permissions": {"allow": ["Bash(*)"]},
                    "env": {"ANTHROPIC_API_KEY": canary_env, "CLAUDE_CODE_DISABLE_TELEMETRY": "1"},
                    "hooks": {"SessionStart": [{"hooks": [{"type": "command", "command": "echo start"}]}]},
                }),
                encoding="utf-8",
            )
            (home / ".claude" / "plugins").mkdir(parents=True)
            (home / ".claude" / "plugins" / "installed_plugins.json").write_text('{"version": 2, "plugins": {}}\n', encoding="utf-8")

            # Local project MCP in ~/.claude.json projects[ws].mcpServers
            (home / ".claude.json").write_text(
                json.dumps({
                    "mcpServers": {"user-srv": {"command": "npx", "args": ["user-srv"]}},
                    "projects": {
                        str(ws.resolve()): {
                            "mcpServers": {
                                "proj-secret": {"command": "node", "args": ["srv.js"], "env": {"API_TOKEN": canary_mcp}}
                            }
                        }
                    },
                }),
                encoding="utf-8",
            )

            # Workspace-encoded project memory
            ws_slug = re.sub(r"[^A-Za-z0-9]", "-", str(ws.resolve()))
            mem_dir = home / ".claude" / "projects" / ws_slug / "memory"
            mem_dir.mkdir(parents=True)
            (mem_dir / "MEMORY.md").write_text("Project architecture memory.\n", encoding="utf-8")
            (mem_dir.parent / "session.jsonl").write_text('{"secret_transcript": true}\n', encoding="utf-8")

            bundle = base / "cc-bundle"
            code_e, out_e, err_e = run_cli(
                "export-device", "--profiles", "cc", "--workspace", str(ws), "--home", str(home), "--output", str(bundle)
            )
            self.assertEqual(code_e, 0, out_e)
            leaked_blob = json.dumps(out_e) + err_e + (bundle / "MIGRATION.md").read_text(encoding="utf-8")
            self.assertNotIn(canary_mcp, leaked_blob)
            self.assertNotIn(canary_env, leaked_blob)

            # Restore to brand new workspace path & home
            new_ws, new_home = base / "new_proj_target", base / "new_home"
            new_ws.mkdir()
            new_home.mkdir()
            code_i, out_i, err_i = run_cli(
                "import-device", "--input", str(bundle), "--target", "same",
                "--workspace", str(new_ws), "--home", str(new_home), "--activate-hooks",
            )
            self.assertEqual(code_i, 0, out_i)
            self.assertNotIn(canary_mcp, json.dumps(out_i) + err_i)
            self.assertNotIn(canary_env, json.dumps(out_i) + err_i)

            restored_st = json.loads((new_home / ".claude" / "settings.json").read_text(encoding="utf-8"))
            self.assertEqual(restored_st["theme"], "dark")
            self.assertEqual(restored_st["env"]["ANTHROPIC_API_KEY"], canary_env)
            self.assertIn("SessionStart", restored_st["hooks"])
            self.assertNotIn("permissions", restored_st)
            self.assertNotIn("skipDangerousModePermissionPrompt", restored_st)
            if os.name != "nt":
                self.assertEqual(os.stat(new_home / ".claude" / "settings.json").st_mode & 0o777, 0o600)

            new_slug = re.sub(r"[^A-Za-z0-9]", "-", str(new_ws.resolve()))
            self.assertTrue((new_home / ".claude" / "projects" / new_slug / "memory" / "MEMORY.md").is_file())
            self.assertFalse((new_home / ".claude" / "projects" / new_slug / "session.jsonl").exists())
            self.assertTrue((new_home / ".claude" / "plugins" / "installed_plugins.json").is_file())

            restored_cj = json.loads((new_home / ".claude.json").read_text(encoding="utf-8"))
            self.assertIn("user-srv", restored_cj["mcpServers"])

            # Verify --redact-secrets on export strips canary_env & canary_mcp in bundle
            redacted_bundle = base / "cc-redacted"
            code_r, _, _ = run_cli(
                "export-device", "--profiles", "cc", "--workspace", str(ws), "--home", str(home),
                "--redact-secrets", "--output", str(redacted_bundle),
            )
            self.assertEqual(code_r, 0)
            all_redacted_text = "\n".join(p.read_text(encoding="utf-8", errors="ignore") for p in redacted_bundle.rglob("*") if p.is_file())
            self.assertNotIn(canary_mcp, all_redacted_text)
            self.assertNotIn(canary_env, all_redacted_text)

    def test_codex_full_export_and_restore_preserves_override_and_target_policy(self) -> None:
        canary = "sk-cx-TOML-CANARY-774411"
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            codex_home = home / ".codex"
            codex_home.mkdir(parents=True)

            (ws / "AGENTS.md").write_text("Project base instructions.\n", encoding="utf-8")
            (ws / "AGENTS.override.md").write_text("Project override instructions.\n", encoding="utf-8")
            (codex_home / "AGENTS.override.md").write_text("User override instructions.\n", encoding="utf-8")

            # Built-in .system skill must be skipped; user skill in ~/.agents/skills exported
            (codex_home / "skills" / ".system" / "internal").mkdir(parents=True)
            (codex_home / "skills" / ".system" / "internal" / "SKILL.md").write_text("---\nname: internal\ndescription: sys\n---\n", encoding="utf-8")
            (home / ".agents" / "skills" / "my-cx-skill").mkdir(parents=True)
            (home / ".agents" / "skills" / "my-cx-skill" / "SKILL.md").write_text("---\nname: my-cx-skill\ndescription: user\n---\nBody\n", encoding="utf-8")

            (codex_home / "prompts").mkdir(parents=True)
            (codex_home / "prompts" / "review.md").write_text("Review staged diff.\n", encoding="utf-8")
            (codex_home / "agents").mkdir(parents=True)
            (codex_home / "agents" / "helper.md").write_text("---\nname: helper\ndescription: Helper\n---\nHelp.\n", encoding="utf-8")
            (codex_home / "scripts").mkdir(parents=True)
            (codex_home / "scripts" / "lint.py").write_text("#!/usr/bin/env python3\nprint('ok')\n", encoding="utf-8")
            (codex_home / "scripts" / "lint.py").chmod(0o755)
            (codex_home / "rules").mkdir(parents=True)
            (codex_home / "rules" / "safe.rules").write_text('prefix_rule(pattern=["git", "status"], decision="allow")\n', encoding="utf-8")
            (codex_home / "memories").mkdir(parents=True)
            (codex_home / "memories" / "MEMORY.md").write_text("Auto generated memory\n", encoding="utf-8")

            (codex_home / "config.toml").write_text(
                'model = "gpt-6.1-sol"\n'
                'model_reasoning_effort = "high"\n'
                'approval_policy = "never"\n'
                'sandbox_mode = "danger-full-access"\n\n'
                '[features]\n'
                'multi_agent = true\n\n'
                '[plugins."pdf@openai"]\n'
                'enabled = true\n\n'
                '[mcp_servers.gh]\n'
                'command = "npx"\n'
                'args = ["-y", "@modelcontextprotocol/server-github"]\n\n'
                '[mcp_servers.gh.env]\n'
                f'GITHUB_TOKEN = "{canary}"\n',
                encoding="utf-8",
            )

            bundle = base / "cx-bundle"
            code_e, out_e, err_e = run_cli(
                "export-device", "--profiles", "cx", "--workspace", str(ws), "--home", str(home), "--output", str(bundle)
            )
            self.assertEqual(code_e, 0, out_e)
            self.assertNotIn(canary, json.dumps(out_e) + err_e + (bundle / "MIGRATION.md").read_text(encoding="utf-8"))
            self.assertFalse((bundle / "files" / "codex" / "user" / "skills" / ".system").exists())
            self.assertFalse(any("memories" in str(e.get("bundle_path", "")) for e in out_e["entries"]))

            # New machine already has approval_policy = "on-request" and a comment
            new_ws, new_home = base / "new_ws", base / "new_home"
            new_ws.mkdir()
            new_codex = new_home / ".codex"
            new_codex.mkdir(parents=True)
            (new_codex / "config.toml").write_text(
                '# Keep target policy\napproval_policy = "on-request"\n\n[mcp_servers.local_existing]\ncommand = "echo"\n',
                encoding="utf-8",
            )

            code_i, out_i, err_i = run_cli(
                "import-device", "--input", str(bundle), "--target", "same",
                "--workspace", str(new_ws), "--home", str(new_home),
            )
            self.assertEqual(code_i, 0, out_i)
            self.assertNotIn(canary, json.dumps(out_i) + err_i)

            self.assertIn("Project override instructions.", (new_ws / "AGENTS.override.md").read_text(encoding="utf-8"))
            self.assertIn("User override instructions.", (new_codex / "AGENTS.override.md").read_text(encoding="utf-8"))
            self.assertTrue((new_codex / "prompts" / "review.md").is_file())
            self.assertTrue((new_codex / "agents" / "helper.md").is_file())
            self.assertTrue((new_codex / "scripts" / "lint.py").is_file())
            self.assertFalse((new_codex / "rules" / "safe.rules").exists())
            self.assertTrue((new_ws / ".migration-review" / "codex-rules" / "codex" / "user" / "safe.rules").is_file())

            raw_toml = (new_codex / "config.toml").read_text(encoding="utf-8")
            self.assertIn("# Keep target policy", raw_toml)
            parsed = tomllib.loads(raw_toml)
            self.assertEqual(parsed["approval_policy"], "on-request")
            self.assertEqual(parsed["model"], "gpt-6.1-sol")
            self.assertTrue(parsed["features"]["multi_agent"])
            self.assertTrue(parsed["plugins"]["pdf@openai"]["enabled"])
            self.assertEqual(parsed["mcp_servers"]["gh"]["env"]["GITHUB_TOKEN"], canary)
            self.assertEqual(parsed["mcp_servers"]["local_existing"]["command"], "echo")
            if os.name != "nt":
                self.assertEqual(os.stat(new_codex / "config.toml").st_mode & 0o777, 0o600)

    def test_three_way_equivalent_migration_all_six_directions(self) -> None:
        canary = "sk-3way-CANARY-654321"
        # 1. Antigravity -> Claude Code & Codex
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / "AGENTS.md").write_text("AGY always-on.\n", encoding="utf-8")
            (ws / ".agents" / "rules").mkdir(parents=True)
            (ws / ".agents" / "rules" / "ts.md").write_text('---\ntrigger: glob\nglobs: "*.ts"\n---\nUse strict TS.\n', encoding="utf-8")
            (ws / ".agents" / "rules" / "sql.md").write_text('---\ntrigger: model_decision\ndescription: "SQL migrations"\n---\nUse CONCURRENTLY.\n', encoding="utf-8")
            (ws / ".agents" / "rules" / "audit.md").write_text("---\ntrigger: manual\n---\nManual audit checklist.\n", encoding="utf-8")
            (ws / ".agents" / "workflows").mkdir(parents=True)
            (ws / ".agents" / "workflows" / "deploy.md").write_text("Run deploy steps.\n", encoding="utf-8")
            (ws / ".agents" / "agents" / "sec-bot").mkdir(parents=True)
            (ws / ".agents" / "agents" / "sec-bot" / "agent.md").write_text(
                "---\nname: sec-bot\ndescription: Check security\ntools: [read_file, run_command]\nsubagent: true\nmainAgent: false\nmodel: pro\n---\nAudit.\n",
                encoding="utf-8",
            )
            (ws / ".agents" / "mcp_config.json").write_text(
                json.dumps({
                    "mcpServers": {
                        "docs": {"serverUrl": "https://docs.example.com/mcp", "headers": {"Authorization": f"Bearer {canary}"}, "timeoutSeconds": 300}
                    }
                }),
                encoding="utf-8",
            )

            code, out, err = run_cli(
                "migrate", "--source", "anti", "--target", "cc,cx", "--workspace", str(ws), "--home", str(home), "--scope", "project", "--allow-git-tracked-secrets"
            )
            self.assertEqual(code, 0, out)
            self.assertNotIn(canary, json.dumps(out) + err)

            # Claude Code targets
            self.assertIn("AGY always-on.", (ws / "CLAUDE.md").read_text(encoding="utf-8"))
            self.assertIn("paths:", (ws / ".claude" / "rules" / "ts.md").read_text(encoding="utf-8"))
            self.assertTrue((ws / ".claude" / "skills" / "sql" / "SKILL.md").is_file())
            self.assertIn("disable-model-invocation: true", (ws / ".claude" / "skills" / "audit" / "SKILL.md").read_text(encoding="utf-8"))
            self.assertTrue((ws / ".claude" / "commands" / "deploy.md").is_file())
            cc_agent = (ws / ".claude" / "agents" / "sec-bot.md").read_text(encoding="utf-8")
            self.assertIn('"Read"', cc_agent)
            self.assertIn('"Bash"', cc_agent)
            self.assertIn("model: opus", cc_agent)
            cc_mcp = json.loads((ws / ".mcp.json").read_text(encoding="utf-8"))
            self.assertEqual(cc_mcp["mcpServers"]["docs"]["url"], "https://docs.example.com/mcp")

            # Codex targets
            self.assertTrue((ws / ".agents" / "skills" / "sql" / "SKILL.md").is_file())
            self.assertTrue((ws / ".agents" / "skills" / "deploy" / "SKILL.md").is_file())
            self.assertTrue((ws / ".codex" / "agents" / "sec-bot.md").is_file())
            cx_toml = tomllib.loads((ws / ".codex" / "config.toml").read_text(encoding="utf-8"))
            self.assertEqual(cx_toml["mcp_servers"]["docs"]["url"], "https://docs.example.com/mcp")

            # Repeat run must be noop for converted items
            code2, out2, _ = run_cli(
                "migrate", "--source", "anti", "--target", "cc,cx", "--workspace", str(ws), "--home", str(home), "--scope", "project"
            )
            self.assertEqual(code2, 0, out2)
            self.assertGreater(out2["summary"]["noop"], 0)
            self.assertEqual(out2["summary"]["conflict"], 0)

        # 2. Claude Code -> Antigravity & Codex (frontmatterless skill + SSE deferral + agent translation)
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / "CLAUDE.md").write_text("Claude root rules.\n", encoding="utf-8")
            (ws / ".claude" / "rules").mkdir(parents=True)
            (ws / ".claude" / "rules" / "api.md").write_text('---\npaths:\n  - "src/**"\n---\nValidate inputs.\n', encoding="utf-8")
            (ws / ".claude" / "skills" / "raw-skill").mkdir(parents=True)
            (ws / ".claude" / "skills" / "raw-skill" / "SKILL.md").write_text("# Raw Skill\nHelps with builds.\n", encoding="utf-8")
            (ws / ".claude" / "commands").mkdir(parents=True)
            (ws / ".claude" / "commands" / "prep.md").write_text("---\ndescription: Prepare release\n---\nPrep steps.\n", encoding="utf-8")
            (ws / ".claude" / "agents").mkdir(parents=True)
            (ws / ".claude" / "agents" / "self.md").write_text(
                "---\nname: self\ndescription: Self reviewer\ntools: Read, Edit\ncolor: blue\nmodel: haiku\n---\nReview.\n",
                encoding="utf-8",
            )
            (ws / ".mcp.json").write_text(
                json.dumps({
                    "mcpServers": {
                        "legacy-sse": {"type": "sse", "url": "https://sse.example.com/events"},
                        "http-srv": {"type": "http", "url": "https://http.example.com/mcp"},
                    }
                }),
                encoding="utf-8",
            )

            code, out, _ = run_cli(
                "migrate", "--source", "claude", "--target", "anti,cx", "--workspace", str(ws), "--home", str(home), "--scope", "project"
            )
            self.assertEqual(code, 0, out)
            self.assertIn("trigger: glob", (ws / ".agents" / "rules" / "api.md").read_text(encoding="utf-8"))
            ag_sk = (ws / ".agents" / "skills" / "raw-skill" / "SKILL.md").read_text(encoding="utf-8")
            self.assertIn("name: raw-skill", ag_sk)
            self.assertIn("Helps with builds.", ag_sk)
            self.assertIn("description: Prepare release", (ws / ".agents" / "skills" / "prep" / "SKILL.md").read_text(encoding="utf-8"))
            ag_agent = (ws / ".agents" / "agents" / "self.md").read_text(encoding="utf-8")
            self.assertIn("name: claude-self", ag_agent)
            self.assertIn("subagent: true", ag_agent)
            self.assertIn("mainAgent: false", ag_agent)
            self.assertNotIn("color:", ag_agent)
            ag_mcp = json.loads((ws / ".agents" / "mcp_config.json").read_text(encoding="utf-8"))
            self.assertIn("http-srv", ag_mcp["mcpServers"])
            self.assertNotIn("legacy-sse", ag_mcp["mcpServers"])
            self.assertTrue(any(a["id"] == "legacy-sse" and a["outcome"] == "deferred" for a in out["actions"]))

    def test_cli_ergonomics_broken_symlink_and_py39_syntax(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            (ws / ".agents" / "skills").mkdir(parents=True)
            home.mkdir()
            (ws / ".agents" / "skills" / "broken-link").symlink_to(ws / ".agents" / "skills" / "missing-target")

            code_i, out_i, _ = run_cli("inspect", "--workspace", str(ws), "--home", str(home), "--profiles", "agy", "--summary")
            self.assertEqual(code_i, 0, out_i)
            self.assertIn("totals", out_i)
            self.assertEqual(out_i["profiles"][0]["counts"]["excluded"], 1)

            # Default --output on export-device creates ~/context-transfer-<UTC>
            code_e, out_e, _ = run_cli("export-device", "--workspace", str(ws), "--home", str(home), "--profiles", "agy")
            self.assertEqual(code_e, 0, out_e)
            self.assertTrue(Path(out_e["output_dir"]).is_dir())
            self.assertIn("totals", out_e)

            # Verify /usr/bin/python3 (3.9) can parse & bootstrap migrate_context.py if present
            sys_py = Path("/usr/bin/python3")
            if sys_py.is_file():
                comp = subprocess.run(
                    [str(sys_py), "-B", "-c", f"import ast, pathlib; ast.parse(pathlib.Path({str(SCRIPT)!r}).read_text(encoding='utf-8'))"],
                    capture_output=True, text=True, check=False,
                )
                self.assertEqual(comp.returncode, 0, comp.stderr)
                boot = subprocess.run([str(sys_py), "-B", str(SCRIPT), "--help"], capture_output=True, text=True, check=False)
                self.assertEqual(boot.returncode, 0, boot.stderr)


if __name__ == "__main__":
    unittest.main()
