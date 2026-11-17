"""Round 1 torture tests: parser edge cases, containment, conflict isolation, and TOML/JSONC safety."""
from __future__ import annotations

import hashlib
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

    def test_mcp_url_argument_query_secrets_are_detected_and_block_tracked_write(self) -> None:
        # URL-shaped MCP args carry no secret-token prefix, so inspect_url_secrets()
        # must be invoked for them independently (finding at migrate_context.py:544).
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".cursor").mkdir(parents=True)
            (ws / ".cursor" / "mcp.json").write_text(
                json.dumps({
                    "mcpServers": {
                        "srv": {
                            "command": "node",
                            "args": ["--server-url", "https://example.test/mcp?token=CANARY_URL_TOKEN_7766"],
                        }
                    }
                }, indent=2),
                encoding="utf-8",
            )
            (ws / ".codex").mkdir(parents=True)
            (ws / ".codex" / "config.toml").write_text('approval_policy = "on-request"\n', encoding="utf-8")
            subprocess.run(["git", "-C", str(ws), "init", "-q"], check=True)
            subprocess.run(["git", "-C", str(ws), "config", "user.email", "t@t"], check=True)
            subprocess.run(["git", "-C", str(ws), "config", "user.name", "t"], check=True)
            subprocess.run(["git", "-C", str(ws), "add", ".codex/config.toml"], check=True)
            subprocess.run(["git", "-C", str(ws), "commit", "-q", "-m", "init"], check=True)

            token = "CANARY_URL_TOKEN_7766"
            code, out, _ = run_cli(
                "inspect", "--workspace", str(ws), "--home", str(home), "--profiles", "cursor",
            )
            self.assertEqual(code, 0)
            ins_text = json.dumps(out, ensure_ascii=False)
            self.assertIn("url_query:token", ins_text, "URL query parameter must be inspected as a secret")
            self.assertIn(hashlib.sha256(token.encode("utf-8")).hexdigest()[:8], ins_text)

            # The tracked Codex target must refuse the literal secret, not silently absorb it.
            code, out, _ = run_cli(
                "migrate", "--source", "cursor", "--target", "codex", "--workspace", str(ws), "--home", str(home),
                "--scope", "project", "--strict-conflicts",
            )
            self.assertEqual(code, 2, out)
            self.assertEqual(out["error"], "git_tracked_secret_refusal")
            self.assertEqual((ws / ".codex" / "config.toml").read_text(encoding="utf-8"), 'approval_policy = "on-request"\n')

    def test_dotenv_multiline_secret_fully_redacted_in_export(self) -> None:
        # Quoted multiline .env values must be parsed whole before redacting;
        # continuation lines without "=" must not survive --redact-secrets
        # (finding at migrate_context.py:563).
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".env").write_text(
                'PEM_KEY="-----BEGIN PRIVATE KEY-----\nDOTENV_MULTILINE_CANARY_5544\n-----END PRIVATE KEY-----"\nOTHER=keep-me\n',
                encoding="utf-8",
            )
            code, out, _ = run_cli(
                "export-device", "--output", str(base / "bundle"), "--workspace", str(ws), "--home", str(home),
                "--scope", "project", "--redact-secrets",
            )
            self.assertEqual(code, 0, out)
            bundled = (base / "bundle" / "files" / "workspace" / "project" / "env" / ".env").read_text(encoding="utf-8")
            self.assertNotIn("DOTENV_MULTILINE_CANARY_5544", bundled)
            self.assertNotIn("BEGIN PRIVATE KEY", bundled)
            self.assertIn("PEM_KEY=", bundled)
            self.assertIn("OTHER=keep-me", bundled)
            md = (base / "bundle" / "MIGRATION.md").read_text(encoding="utf-8")
            self.assertNotIn("DOTENV_MULTILINE_CANARY_5544", md)

    def test_mcp_same_name_differing_only_tool_restrictions_conflict(self) -> None:
        # tool_allow/tool_deny must be part of the comparison signature
        # (finding at migrate_context.py:632).
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".codex").mkdir(parents=True)
            (ws / ".codex" / "config.toml").write_text(
                '[mcp_servers.reviewer]\ncommand = "npx"\nargs = ["reviewer-mcp"]\ndisabled_tools = ["Write"]\n',
                encoding="utf-8",
            )
            (ws / ".cursor").mkdir(parents=True)
            (ws / ".cursor" / "mcp.json").write_text(
                json.dumps({"mcpServers": {"reviewer": {"command": "npx", "args": ["reviewer-mcp"]}}}),
                encoding="utf-8",
            )
            code, out, _ = run_cli(
                "migrate", "--source", "codex,cursor", "--target", "vscode", "--workspace", str(ws), "--home", str(home),
                "--scope", "project", "--strict-conflicts",
            )
            self.assertEqual(code, 3, out)
            reasons = [a.get("reason") for a in out.get("actions", [])]
            self.assertIn("conflicting_definitions_across_sources", reasons)
            self.assertFalse((ws / ".vscode" / "mcp.json").exists())

    def test_windsurf_manual_trigger_wins_over_description(self) -> None:
        # Explicit activation metadata (trigger: manual) takes precedence over
        # inference from a description (finding at migrate_context.py:1220).
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".windsurf" / "rules").mkdir(parents=True)
            (ws / ".windsurf" / "rules" / "manual-rule.md").write_text(
                "---\ntrigger: manual\ndescription: Run only when explicitly invoked\n---\nManual body.\n",
                encoding="utf-8",
            )
            code, out, _ = run_cli(
                "migrate", "--source", "windsurf", "--target", "claude-code", "--workspace", str(ws), "--home", str(home),
                "--scope", "project",
            )
            self.assertEqual(code, 0, out)
            sk = (ws / ".claude" / "skills" / "manual-rule" / "SKILL.md").read_text(encoding="utf-8")
            self.assertIn("disable-model-invocation: true", sk)

    def test_destination_symlink_escape_is_refused(self) -> None:
        # Destination writes must be containment-checked against the authorized
        # root, not just source discovery (finding at migrate_context.py:1439).
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            outside = base / "outside"
            outside.mkdir(parents=True)
            (outside / "secret.txt").write_text("DESTINATION_ESCAPE_CANARY_2233\n", encoding="utf-8")
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".cursor" / "rules").mkdir(parents=True)
            (ws / ".cursor" / "rules" / "glob-rule.mdc").write_text(
                "---\nglobs: src/**\n---\nGlob body.\n", encoding="utf-8",
            )
            os.symlink(outside, ws / ".claude")
            code, out, _ = run_cli(
                "migrate", "--source", "cursor", "--target", "claude-code", "--workspace", str(ws), "--home", str(home),
                "--scope", "project",
            )
            self.assertEqual(code, 2, out)
            self.assertEqual(out["error"], "symlink_escape")
            self.assertTrue((ws / ".claude").is_symlink())
            self.assertFalse((outside / "rules").exists())

    def test_skill_history_and_db_files_excluded_from_copy_and_export(self) -> None:
        # Skill copy/export/digest must honor exclusion names, suffixes and
        # ancestor directories (finding at migrate_context.py:1575).
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            sk = ws / ".cursor" / "skills" / "my-skill"
            sk.mkdir(parents=True)
            (sk / "SKILL.md").write_text("---\nname: my-skill\n---\nBody\n", encoding="utf-8")
            (sk / "history.jsonl").write_text('{"c": "SKILL_HISTORY_CANARY_1122"}\n', encoding="utf-8")
            (sk / "state.sqlite").write_bytes(b"SQLite format 3\x00")
            (sk / "scripts").mkdir()
            (sk / "scripts" / "tool.py").write_text("print('hi')\n", encoding="utf-8")
            code, out, _ = run_cli(
                "migrate", "--source", "cursor", "--target", "claude-code", "--workspace", str(ws), "--home", str(home),
                "--scope", "project",
            )
            self.assertEqual(code, 0, out)
            dst = ws / ".claude" / "skills" / "my-skill"
            self.assertTrue((dst / "SKILL.md").is_file())
            self.assertTrue((dst / "scripts" / "tool.py").is_file())
            self.assertFalse((dst / "history.jsonl").exists())
            self.assertFalse((dst / "state.sqlite").exists())
            code, out, _ = run_cli(
                "export-device", "--output", str(base / "bundle"), "--workspace", str(ws), "--home", str(home),
                "--scope", "project",
            )
            self.assertEqual(code, 0, out)
            self.assertFalse(list((base / "bundle").rglob("*.jsonl")))
            self.assertFalse(list((base / "bundle").rglob("*.sqlite")))

    def test_shared_settings_file_keeps_private_mode_with_other_doc_secret(self) -> None:
        # Rewriting a shared settings file must account for secrets elsewhere in
        # the document, not just the MCP map, before deciding the file is
        # non-sensitive (finding at migrate_context.py:1635).
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".gemini").mkdir(parents=True)
            settings = ws / ".gemini" / "settings.json"
            settings.write_text(
                json.dumps({"api_key": "sk-live-GEMINI_OTHER_CANARY_9900", "mcpServers": {}}, indent=2) + "\n",
                encoding="utf-8",
            )
            os.chmod(settings, 0o600)
            (ws / ".cursor").mkdir(parents=True)
            (ws / ".cursor" / "mcp.json").write_text(
                json.dumps({"mcpServers": {"weather": {"command": "node", "args": ["weather"]}}}),
                encoding="utf-8",
            )
            code, out, _ = run_cli(
                "migrate", "--source", "cursor", "--target", "gemini-cli", "--workspace", str(ws), "--home", str(home),
                "--scope", "project",
            )
            self.assertEqual(code, 0, out)
            mode = os.stat(settings).st_mode & 0o777
            self.assertEqual(mode, 0o600, f"settings.json downgraded to {oct(mode)}, exposing the retained credential")
            doc = json.loads(settings.read_text(encoding="utf-8"))
            self.assertEqual(doc["api_key"], "sk-live-GEMINI_OTHER_CANARY_9900")
            self.assertIn("weather", doc["mcpServers"])

    def test_vscode_command_and_agent_native_suffix_translation(self) -> None:
        # VS Code commands/agents must be stored under *.prompt.md/*.agent.md
        # native names (finding at migrate_context.py:1755).
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".cursor" / "commands").mkdir(parents=True)
            (ws / ".cursor" / "agents").mkdir(parents=True)
            (ws / ".cursor" / "commands" / "release.md").write_text("# Release\nbody\n", encoding="utf-8")
            (ws / ".cursor" / "agents" / "reviewer.md").write_text("# Reviewer\nbody\n", encoding="utf-8")
            code, out, _ = run_cli(
                "migrate", "--source", "cursor", "--target", "vscode", "--workspace", str(ws), "--home", str(home),
                "--scope", "project",
            )
            self.assertEqual(code, 0, out)
            self.assertTrue((ws / ".github" / "prompts" / "release.prompt.md").is_file())
            self.assertTrue((ws / ".github" / "agents" / "reviewer.agent.md").is_file())
            self.assertFalse((ws / ".github" / "prompts" / "release.md").exists())
            self.assertFalse((ws / ".github" / "agents" / "reviewer.md").exists())


    def test_mcp_argument_url_query_token_inspected_and_redacted(self) -> None:
        """MCP argument carrying a URL with query token must be inspected independent of SECRET_VALUE_RE."""
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".cursor").mkdir(parents=True)
            (ws / ".cursor" / "mcp.json").write_text(
                json.dumps({
                    "mcpServers": {
                        "canary-srv": {
                            "command": "node",
                            "args": ["srv.js", "https://example.test/mcp?token=CANARY_ARG_QUERY_TOKEN"],
                        }
                    }
                }),
                encoding="utf-8",
            )
            code, out, _ = run_cli(
                "migrate", "--source", "cursor", "--target", "claude-code",
                "--workspace", str(ws), "--home", str(home), "--scope", "project",
                "--redact-secrets",
            )
            self.assertEqual(code, 0, out)
            doc = json.loads((ws / ".mcp.json").read_text(encoding="utf-8"))
            args = doc["mcpServers"]["canary-srv"]["args"]
            self.assertIn("https://example.test/mcp?token=${TOKEN}", args)
            self.assertNotIn("CANARY_ARG_QUERY_TOKEN", json.dumps(doc))
            self.assertIn("url_query:token", json.dumps(out))

    def test_redact_secrets_clears_whole_quoted_multiline_dotenv_value(self) -> None:
        """--redact-secrets must clear continuation lines of a quoted multiline .env value."""
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".env").write_text(
                '# Production signing key\n'
                'PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n'
                'MIIEvQIBADANBgkqhkiG9w0BBQEwAS4=\n'
                '-----END PRIVATE KEY-----\n"\n',
                encoding="utf-8",
            )
            bundle = base / "bundle"
            code, out, _ = run_cli(
                "export-device", "--redact-secrets", "--output", str(bundle),
                "--workspace", str(ws), "--home", str(home), "--profiles", "cursor",
            )
            self.assertEqual(code, 0, out)
            staged = (bundle / "files" / "workspace" / "project" / "env" / ".env").read_text(encoding="utf-8")
            self.assertIn("# Production signing key\n", staged)
            self.assertIn("PRIVATE_KEY=", staged)
            self.assertNotIn("-----BEGIN", staged)
            self.assertNotIn("MIIEvQIBADANBgkqhkiG9w0BBQEwAS4=", staged)
            self.assertNotIn("-----END PRIVATE KEY-----", staged)

    def test_mcp_same_name_different_tool_deny_is_conflict_not_noop(self) -> None:
        """Same-name MCP definitions differing only in tool allow/deny lists must conflict."""
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".cursor").mkdir(parents=True)
            (ws / ".cursor" / "mcp.json").write_text(
                json.dumps({"mcpServers": {"dup": {"command": "node", "args": ["srv.js"], "disabled_tools": ["write"]}}}),
                encoding="utf-8",
            )
            (ws / ".mcp.json").write_text(
                '{"mcpServers": {"dup": {"command": "node", "args": ["srv.js"], "disabledTools": ["read"]}}}\n',
                encoding="utf-8",
            )
            code, out, _ = run_cli(
                "migrate", "--source", "cursor", "--target", "claude-code",
                "--workspace", str(ws), "--home", str(home), "--scope", "project",
                "--strict-conflicts",
            )
            self.assertEqual(code, 3, out)
            conflicts = [a for a in out.get("conflicts", []) if a.get("category") == "mcp"]
            self.assertTrue(any(c.get("id") == "dup" for c in conflicts), out)
            doc = json.loads((ws / ".mcp.json").read_text(encoding="utf-8"))
            self.assertEqual(doc["mcpServers"]["dup"]["disabledTools"], ["read"])

    def test_windsurf_manual_trigger_rule_beats_description_inference(self) -> None:
        """trigger: manual plus a description must classify manual, not model_selected."""
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".windsurf" / "rules").mkdir(parents=True)
            (ws / ".windsurf" / "rules" / "reviewer.md").write_text(
                "---\ntrigger: manual\ndescription: Review before release\n---\nCheck staging before tagging.\n",
                encoding="utf-8",
            )
            code, out, _ = run_cli(
                "migrate", "--source", "windsurf", "--target", "claude-code",
                "--workspace", str(ws), "--home", str(home), "--scope", "project",
            )
            self.assertEqual(code, 0, out)
            sk = ws / ".claude" / "skills" / "reviewer" / "SKILL.md"
            self.assertTrue(sk.is_file())
            body = sk.read_text(encoding="utf-8")
            self.assertIn("disable-model-invocation: true", body)
            self.assertIn("Check staging before tagging", body)

    def test_destination_symlink_escape_is_refused_before_write(self) -> None:
        """Write through a destination symlink outside the authorized root must be refused."""
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            external = base / "external"
            external.mkdir()
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".cursor" / "rules").mkdir(parents=True)
            (ws / ".cursor" / "rules" / "deploy.md").write_text(
                "---\nglobs: src/*.ts\n---\nDeploy rule.\n",
                encoding="utf-8",
            )
            (ws / ".claude").symlink_to(external)
            code, out, _ = run_cli(
                "migrate", "--source", "cursor", "--target", "claude-code",
                "--workspace", str(ws), "--home", str(home), "--scope", "project",
            )
            self.assertEqual(code, 2, out)
            self.assertEqual(out["error"], "symlink_escape", out)
            self.assertFalse((external / "rules").exists())

    def test_skill_runtime_artifacts_excluded_from_copy_and_export(self) -> None:
        """history.jsonl, state.sqlite and cache dirs must not travel as Skill resources."""
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            sk = ws / ".cursor" / "skills" / "leaky-skill"
            sk.mkdir(parents=True)
            (sk / "SKILL.md").write_text("---\nname: leaky-skill\ndescription: test\n---\nBody\n", encoding="utf-8")
            (sk / "scripts").mkdir()
            (sk / "scripts" / "deploy.py").write_text("print('hi')\n", encoding="utf-8")
            (sk / "history.jsonl").write_text('{"s": "secret-transcript"}\n', encoding="utf-8")
            (sk / "state.sqlite").write_bytes(b"SQLite format 3\x00")
            (sk / "cache").mkdir()
            (sk / "cache" / "thing.log").write_text("trace\n", encoding="utf-8")

            code, out, _ = run_cli("migrate", "--source", "cursor", "--target", "claude-code",
                                   "--workspace", str(ws), "--home", str(home))
            self.assertEqual(code, 0, out)
            dst_sk = ws / ".claude" / "skills" / "leaky-skill"
            self.assertTrue((dst_sk / "SKILL.md").is_file())
            self.assertTrue((dst_sk / "scripts" / "deploy.py").is_file())
            self.assertFalse((dst_sk / "history.jsonl").exists())
            self.assertFalse((dst_sk / "state.sqlite").exists())
            self.assertFalse((dst_sk / "cache").exists())

            bundle = base / "transfer"
            code_e, _, _ = run_cli("export-device", "--output", str(bundle), "--workspace", str(ws), "--home", str(home))
            self.assertEqual(code_e, 0)
            self.assertFalse(list(bundle.rglob("*.jsonl")))
            self.assertFalse(list(bundle.rglob("*.sqlite")))
            self.assertTrue(any(p.name == "SKILL.md" for p in bundle.rglob("*")))

    def test_shared_settings_file_keeps_0600_when_document_has_other_secret(self) -> None:
        """Rewriting a shared settings file must not downgrade 0600 due to unrelated top-level credentials."""
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".gemini").mkdir(parents=True)
            settings = ws / ".gemini" / "settings.json"
            settings.write_text('{"apiKey": "CRET-UNRELATED-TOP-LEVEL", "mcpServers": {}}\n', encoding="utf-8")
            if os.name != "nt":
                os.chmod(settings, 0o600)
            (ws / ".cursor").mkdir(parents=True)
            (ws / ".cursor" / "mcp.json").write_text(
                json.dumps({"mcpServers": {"web": {"command": "node", "args": ["srv.js"]}}}),
                encoding="utf-8",
            )
            code, out, _ = run_cli(
                "migrate", "--source", "cursor", "--target", "gemini-cli",
                "--workspace", str(ws), "--home", str(home), "--scope", "project",
            )
            self.assertEqual(code, 0, out)
            doc = json.loads(settings.read_text(encoding="utf-8"))
            self.assertEqual(doc["apiKey"], "CRET-UNRELATED-TOP-LEVEL")
            self.assertIn("web", doc["mcpServers"])
            if os.name != "nt":
                self.assertEqual(os.stat(settings).st_mode & 0o777, 0o600, oct(os.stat(settings).st_mode & 0o777))

    def test_vscode_command_and_agent_translated_to_native_suffixes(self) -> None:
        """VS Code commands/agents must land as *.prompt.md / *.agent.md, keeping source names is wrong."""
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()
            (ws / ".cursor" / "commands").mkdir(parents=True)
            (ws / ".cursor" / "agents").mkdir(parents=True)
            (ws / ".cursor" / "commands" / "release.md").write_text("# Release command\n", encoding="utf-8")
            (ws / ".cursor" / "agents" / "reviewer.md").write_text("# Reviewer agent\n", encoding="utf-8")
            code, out, _ = run_cli("migrate", "--source", "cursor", "--target", "vscode",
                                   "--workspace", str(ws), "--home", str(home))
            self.assertEqual(code, 0, out)
            self.assertTrue((ws / ".github" / "prompts" / "release.prompt.md").is_file())
            self.assertTrue((ws / ".github" / "agents" / "reviewer.agent.md").is_file())
            self.assertFalse((ws / ".github" / "prompts" / "release.md").exists())
            self.assertFalse((ws / ".github" / "agents" / "reviewer.md").exists())
            self.assertEqual((ws / ".github" / "prompts" / "release.prompt.md").read_text(encoding="utf-8"), "# Release command\n")


if __name__ == "__main__":
    unittest.main()
