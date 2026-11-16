"""Round 1 torture tests: parser edge cases, containment, conflict isolation, and TOML/JSONC safety."""
from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "skills" / "agent-skills-setup" / "scripts" / "migrate_context.py"


def run_cli(*args: str, env: dict[str, str] | None = None) -> tuple[int, dict, str]:
    merged_env = dict(os.environ)
    merged_env["PYTHONDONTWRITEBYTECODE"] = "1"
    if env:
        merged_env.update(env)
    proc = subprocess.run(
        [sys.executable, "-B", str(SCRIPT), *args],
        capture_output=True,
        text=True,
        env=merged_env,
        check=False,
    )
    data = json.loads(proc.stdout) if proc.stdout.strip().startswith("{") else {}
    return proc.returncode, data, proc.stderr


class MigrateTortureTests(unittest.TestCase):
    def test_jsonc_comments_urls_escaped_quotes_and_trailing_commas(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            src_mcp = ws / "mcphub-servers.json"
            src_mcp.write_text(
                """{
                  // Leading line comment with // and /*
                  "mcpServers": {
                    "docs-http": {
                      /* Block comment
                         spanning lines */
                      "url": "https://mcp.example.com/sse?hint=a//b/*c*/",
                      "headers": {
                        "X-Note": "quote \\" // inside string, trailing comma next",
                      },
                      "autoApprove": ["search_docs",],
                    },
                  },
                }""",
                encoding="utf-8",
            )
            dst_zed = ws / ".zed" / "settings.json"
            dst_zed.parent.mkdir(parents=True)
            dst_zed.write_text(
                '// Existing Zed config\n{"vim_mode": true, "theme": "One Dark",}\n',
                encoding="utf-8",
            )
            code, out, _ = run_cli(
                "patch-mcp",
                "--src-file", str(src_mcp),
                "--src-key-path", "mcpServers",
                "--src-format", "jsonc",
                "--dst-file", str(dst_zed),
                "--dst-key-path", "context_servers",
                "--workspace", str(ws),
                "--home", str(home),
            )
            self.assertEqual(code, 0, out)
            zed_parsed = json.loads(dst_zed.read_text(encoding="utf-8"))
            self.assertTrue(zed_parsed["vim_mode"])
            self.assertEqual(zed_parsed["theme"], "One Dark")
            srv = zed_parsed["context_servers"]["docs-http"]
            self.assertEqual(srv["url"], "https://mcp.example.com/sse?hint=a//b/*c*/")
            self.assertNotIn("autoApprove", srv)
            self.assertEqual(len(out["backups"]), 1)
            if os.name != "nt":
                self.assertEqual(os.stat(out["backups"][0]).st_mode & 0o777, 0o600)

    def test_cursor_mdc_unquoted_comma_brace_always_and_manual_rules(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            rules = ws / ".cursor" / "rules"
            rules.mkdir(parents=True)
            home.mkdir()

            # 1. Unquoted comma + brace globs
            (rules / "frontend.mdc").write_text(
                "---\nglobs: src/**/*.{ts,tsx}, apps/web/*.ts\nalwaysApply: false\n---\nUse strict TypeScript（严格模式）.\n",
                encoding="utf-8",
            )
            # 2. Unquoted leading-asterisk glob
            (rules / "py-only.mdc").write_text(
                "---\nglobs: *.py\n---\nPrefer pathlib over os.path.\n",
                encoding="utf-8",
            )
            # 3. alwaysApply: true overrides globs!
            (rules / "global-override.mdc").write_text(
                "---\nglobs: docs/*.md\nalwaysApply: true\n---\nKeep responses concise.\n",
                encoding="utf-8",
            )
            # 4. Manual rule (@deploy-checklist): alwaysApply: false, no globs, no description
            (rules / "deploy-checklist.mdc").write_text(
                "---\nalwaysApply: false\n---\nVerify staging health before tagging.\n",
                encoding="utf-8",
            )
            # 5. Model-selected rule (description only)
            (rules / "sql-review.mdc").write_text(
                "---\ndescription: Use when reviewing SQL migrations\nalwaysApply: false\n---\nCheck index locks.\n",
                encoding="utf-8",
            )

            (ws / "CLAUDE.md").write_text("# Existing Project Notes\n\nKeep me intact.\n", encoding="utf-8")

            code, out, _ = run_cli(
                "migrate",
                "--source", "cursor",
                "--target", "claude-code,codex",
                "--workspace", str(ws),
                "--home", str(home),
                "--scope", "project",
            )
            self.assertEqual(code, 0, out)

            # Claude checks:
            claude_md = (ws / "CLAUDE.md").read_text(encoding="utf-8")
            self.assertIn("# Existing Project Notes", claude_md)
            self.assertIn("Keep responses concise.", claude_md)
            self.assertNotIn("Use strict TypeScript", claude_md)
            self.assertNotIn("Verify staging health", claude_md)

            fe_rule = (ws / ".claude" / "rules" / "frontend.md").read_text(encoding="utf-8")
            self.assertIn('"src/**/*.{ts,tsx}"', fe_rule)
            self.assertIn('"apps/web/*.ts"', fe_rule)
            self.assertIn("严格模式", fe_rule)

            py_rule = (ws / ".claude" / "rules" / "py-only.md").read_text(encoding="utf-8")
            self.assertIn('"*.py"', py_rule)

            manual_sk = (ws / ".claude" / "skills" / "deploy-checklist" / "SKILL.md").read_text(encoding="utf-8")
            self.assertIn("disable-model-invocation: true", manual_sk)

            model_sk = (ws / ".claude" / "skills" / "sql-review" / "SKILL.md").read_text(encoding="utf-8")
            self.assertNotIn("disable-model-invocation: true", model_sk)

            # Codex checks: scoped rules must be parked in .migration-review/rules/codex, NOT widened into AGENTS.md!
            agents_md = (ws / "AGENTS.md").read_text(encoding="utf-8")
            self.assertIn("Keep responses concise.", agents_md)
            self.assertNotIn("Prefer pathlib over os.path.", agents_md)
            self.assertTrue((ws / ".migration-review" / "rules" / "codex" / "py-only.md").is_file())

            # Immediate re-run must be 100% idempotent (migrated == 0, noop > 0)
            code2, out2, _ = run_cli(
                "migrate",
                "--source", "cursor",
                "--target", "claude-code,codex",
                "--workspace", str(ws),
                "--home", str(home),
                "--scope", "project",
            )
            self.assertEqual(code2, 0)
            self.assertEqual(out2["summary"]["migrated"], 0)
            self.assertGreaterEqual(out2["summary"]["noop"], 5)

    def test_codex_toml_preserves_comments_detects_env_rename_and_escapes_dotted_keys(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            (ws / ".cursor").mkdir(parents=True)
            (ws / ".codex").mkdir(parents=True)
            home.mkdir()

            (ws / ".codex" / "config.toml").write_text(
                '# Preserve operator comment\napproval_policy = "on-request"\n\n[mcp_servers.existing]\ncommand = "uvx"\nargs = ["existing-srv"]\n',
                encoding="utf-8",
            )
            (ws / ".cursor" / "mcp.json").write_text(
                json.dumps({
                    "mcpServers": {
                        "same-var": {
                            "command": "node",
                            "args": ["C:\\Tools\\srv.js"],
                            "env": {"PROJECT_TOKEN": "${PROJECT_TOKEN}"},
                            "alwaysAllow": ["danger"],
                        },
                        "renamed.var": {
                            "command": "node",
                            "args": ["rename.js"],
                            "env": {"SERVER_TOKEN": "${HOST_TOKEN}"},
                        },
                        "existing": {
                            "command": "npx",
                            "args": ["conflicting-cmd"],
                        },
                    }
                }),
                encoding="utf-8",
            )

            code, out, _ = run_cli(
                "migrate",
                "--source", "cursor",
                "--target", "codex",
                "--workspace", str(ws),
                "--home", str(home),
                "--scope", "project",
                "--strict-conflicts",
            )
            # Expect exit code 3 under --strict-conflicts because 'existing' conflicts and 'renamed.var' is deferred!
            self.assertEqual(code, 3, out)

            raw_toml = (ws / ".codex" / "config.toml").read_text(encoding="utf-8")
            self.assertIn("# Preserve operator comment", raw_toml)
            parsed = tomllib.loads(raw_toml)
            self.assertEqual(parsed["approval_policy"], "on-request")
            # Existing conflicting server untouched:
            self.assertEqual(parsed["mcp_servers"]["existing"]["command"], "uvx")
            # Non-conflicting sibling applied cleanly:
            self.assertEqual(parsed["mcp_servers"]["same-var"]["args"], ["C:\\Tools\\srv.js"])
            self.assertEqual(parsed["mcp_servers"]["same-var"]["env_vars"], ["PROJECT_TOKEN"])
            self.assertNotIn("env", parsed["mcp_servers"]["same-var"])
            # Renamed env var deferred instead of broken interpolation:
            self.assertNotIn("renamed.var", parsed["mcp_servers"])

    def test_symlink_escape_and_bundle_tampering_refused_with_exit_2(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            outside = base / "outside-secret.txt"
            outside.write_text("TOP_SECRET_OUTSIDE\n", encoding="utf-8")

            ws, home = base / "ws", base / "home"
            sk = ws / ".cursor" / "skills" / "evil-skill"
            sk.mkdir(parents=True)
            home.mkdir()
            (sk / "SKILL.md").write_text("---\nname: evil-skill\ndescription: test\n---\nBody\n", encoding="utf-8")
            created_symlink = False
            try:
                (sk / "leak.txt").symlink_to(outside)
                created_symlink = True
            except OSError:
                if os.name != "nt":
                    raise

            if created_symlink:
                code, out, _ = run_cli(
                    "migrate",
                    "--source", "cursor",
                    "--target", "claude-code",
                    "--workspace", str(ws),
                    "--home", str(home),
                )
                self.assertEqual(code, 2)
                self.assertEqual(out["error"], "symlink_escape")
                self.assertFalse((ws / ".claude" / "skills" / "evil-skill").exists())
                (sk / "leak.txt").unlink()

            bundle = base / "transfer"
            code_e, _, _ = run_cli("export-device", "--output", str(bundle), "--workspace", str(ws), "--home", str(home))
            self.assertEqual(code_e, 0)

            # Refuses clobbering existing export folder:
            code_clob, out_clob, _ = run_cli("export-device", "--output", str(bundle), "--workspace", str(ws), "--home", str(home))
            self.assertEqual(code_clob, 2)
            self.assertEqual(out_clob["error"], "output_already_exists")

            # Tamper with exported SKILL.md -> import-device must fail SHA-256 verification!
            exported_sk = next(bundle.rglob("SKILL.md"))
            exported_sk.write_text("tampered\n", encoding="utf-8")
            code_i, out_i, _ = run_cli("import-device", "--input", str(bundle), "--workspace", str(base / "new_ws"), "--home", str(home))
            self.assertEqual(code_i, 2)
            self.assertEqual(out_i["error"], "checksum_mismatch")

    def test_dry_run_creates_zero_files_and_zero_backups(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            (ws / ".cursor" / "rules").mkdir(parents=True)
            home.mkdir()
            (ws / ".cursor" / "rules" / "a.mdc").write_text("---\nalwaysApply: true\n---\nHello\n", encoding="utf-8")
            (ws / "CLAUDE.md").write_text("# Preexisting\n", encoding="utf-8")

            code, out, _ = run_cli(
                "migrate",
                "--source", "cursor",
                "--target", "claude-code",
                "--workspace", str(ws),
                "--home", str(home),
                "--dry-run",
            )
            self.assertEqual(code, 0)
            self.assertTrue(out["dry_run"])
            self.assertEqual((ws / "CLAUDE.md").read_text(encoding="utf-8"), "# Preexisting\n")
            self.assertFalse((home / ".agent-skills-setup-backups").exists())

    def test_pi_knob_only_qwen_allowed_tools_and_kimi_legacy_home(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            (ws / ".pi").mkdir(parents=True)
            (home / ".kimi").mkdir(parents=True)
            # Pi knob-only MCP override
            (ws / ".pi" / "mcp.json").write_text('{"mcpServers": {"playwright": {"enabled": false}}}\n', encoding="utf-8")
            # Legacy ~/.kimi fallback on source when ~/.kimi-code is absent
            (home / ".kimi" / "AGENTS.md").write_text("Follow Kimi legacy notes.\n", encoding="utf-8")
            # Skill with allowed-tools -> Qwen allowedTools
            sk = ws / ".pi" / "skills" / "lint-check"
            sk.mkdir(parents=True)
            (sk / "SKILL.md").write_text(
                "---\nname: lint-check\ndescription: Run lint checks\nallowed-tools: Read Grep\n---\nCheck lint.\n",
                encoding="utf-8",
            )

            code, out, _ = run_cli(
                "migrate",
                "--source", "pi,kimiai",
                "--target", "qwen-code,pi",
                "--workspace", str(ws),
                "--home", str(home),
            )
            self.assertEqual(code, 0, out)
            qwen_sk = (ws / ".qwen" / "skills" / "lint-check" / "SKILL.md").read_text(encoding="utf-8")
            self.assertIn("allowedTools:", qwen_sk)
            self.assertIn('"Read"', qwen_sk)
            qwen_user = (home / ".qwen" / "QWEN.md").read_text(encoding="utf-8")
            self.assertIn("Follow Kimi legacy notes.", qwen_user)


if __name__ == "__main__":
    unittest.main()
