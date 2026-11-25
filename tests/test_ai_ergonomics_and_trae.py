"""Tests for Trae CN built-in profile, composable sync-skills, and 16-profile smoke roundtrip."""
from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
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


def load_script_module():
    spec = importlib.util.spec_from_file_location("migrate_context_test", SCRIPT)
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules["migrate_context_test"] = mod
    spec.loader.exec_module(mod)
    return mod


class TraeCnAndSyncSkillsTests(unittest.TestCase):
    def test_claude_code_to_trae_cn_full_migration_and_exclusions(self) -> None:
        canary = "sk-ant-TRAE-CANARY-11223344"
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()

            # Claude Code project + user fixtures
            (ws / "CLAUDE.md").write_text("Project coding rules.\n", encoding="utf-8")
            (ws / ".claude" / "rules").mkdir(parents=True)
            (ws / ".claude" / "rules" / "py.md").write_text(
                '---\npaths:\n  - "*.py"\n  - "tests/**/*.py"\n---\nUse dataclasses.\n',
                encoding="utf-8",
            )
            (home / ".claude").mkdir(parents=True)
            (home / ".claude" / "CLAUDE.md").write_text("Global Claude guidelines.\n", encoding="utf-8")

            # Skills (project + user) including manual skill
            proj_sk = ws / ".claude" / "skills" / "deploy-check"
            (proj_sk / "scripts").mkdir(parents=True)
            (proj_sk / "SKILL.md").write_text(
                "---\nname: deploy-check\ndescription: Run deploy checks.\n---\nCheck build.\n",
                encoding="utf-8",
            )
            (proj_sk / "scripts" / "run.sh").write_text("#!/bin/sh\necho ok\n", encoding="utf-8")
            os.chmod(proj_sk / "scripts" / "run.sh", 0o755)

            user_sk = home / ".claude" / "skills" / "doc-helper"
            user_sk.mkdir(parents=True)
            (user_sk / "SKILL.md").write_text(
                "---\nname: doc-helper\ndescription: Format docs cleanly.\n---\nKeep headings concise.\n",
                encoding="utf-8",
            )

            # Commands & agents
            (home / ".claude" / "commands").mkdir(parents=True)
            (home / ".claude" / "commands" / "review.md").write_text("Review diff carefully.\n", encoding="utf-8")
            (home / ".claude" / "agents").mkdir(parents=True)
            (home / ".claude" / "agents" / "auditor.md").write_text(
                "---\nname: auditor\ndescription: Audit files.\ntools: Read, Grep\n---\nAudit cleanly.\n",
                encoding="utf-8",
            )

            # Hooks (must stay parked unless --activate-hooks)
            (ws / ".claude" / "settings.json").write_text(
                json.dumps({"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "echo hi"}]}]}}),
                encoding="utf-8",
            )

            # MCP (user) with secret
            (home / ".claude.json").write_text(
                json.dumps({
                    "mcpServers": {
                        "context7": {"command": "npx", "args": ["-y", "@upstash/context7"], "env": {"API_KEY": canary}},
                    }
                }),
                encoding="utf-8",
            )

            # Trae CN runtime/token/builtin files that must be excluded on inspect
            (home / ".trae-cn" / "builtin_skills" / "arkcli").mkdir(parents=True)
            (home / ".trae-cn" / "builtin_skills" / "arkcli" / "SKILL.md").write_text("---\nname: arkcli\n---\n", encoding="utf-8")
            (home / ".trae-cn" / "trae-jwt-token").write_text("jwt-secret-placeholder\n", encoding="utf-8")
            (home / ".trae-cn" / "hub_event_cache").mkdir(parents=True)

            code, mig, err = run_cli(
                "migrate", "--source", "claude-code", "--target", "trae-cn",
                "--workspace", str(ws), "--home", str(home), "--scope", "all",
            )
            self.assertEqual(code, 0, err)
            self.assertTrue(mig["ok"])
            self.assertNotIn(canary, json.dumps(mig) + err)

            # Skills migrated cleanly
            self.assertTrue((ws / ".trae" / "skills" / "deploy-check" / "SKILL.md").is_file())
            self.assertTrue((home / ".trae-cn" / "skills" / "doc-helper" / "SKILL.md").is_file())
            # Glob-scoped rule preserved (globs + alwaysApply: false)
            rule_txt = (ws / ".trae" / "rules" / "py.md").read_text(encoding="utf-8")
            self.assertIn("globs:", rule_txt)
            self.assertIn("alwaysApply: false", rule_txt)
            # User instruction mapped to ~/.trae-cn/user_rules.md
            self.assertIn("Global Claude guidelines.", (home / ".trae-cn" / "user_rules.md").read_text(encoding="utf-8"))
            # Hooks parked rather than activated
            self.assertFalse((ws / ".trae" / "hooks.json").exists())
            self.assertTrue((ws / ".migration-review" / "hooks" / "trae-cn" / "project" / "claude-hooks.json").is_file())
            # Commands & agents copied to Trae CN user dirs
            self.assertTrue((home / ".trae-cn" / "commands" / "review.md").is_file())
            self.assertTrue((home / ".trae-cn" / "agents" / "auditor.md").is_file())

            # Global MCP written to OS-specific Trae CN User mcp.json with 0600 permissions
            if sys.platform == "darwin":
                expected_mcp = home / "Library/Application Support/Trae CN/User/mcp.json"
            elif os.name == "nt":
                expected_mcp = home / "AppData/Roaming/Trae CN/User/mcp.json"
            else:
                expected_mcp = home / ".config/Trae CN/User/mcp.json"
            self.assertTrue(expected_mcp.is_file(), f"Missing Trae CN global MCP at {expected_mcp}")
            if os.name != "nt":
                self.assertEqual(stat.S_IMODE(expected_mcp.stat().st_mode), 0o600)
            mcp_doc = json.loads(expected_mcp.read_text(encoding="utf-8"))
            self.assertEqual(mcp_doc["mcpServers"]["context7"]["env"]["API_KEY"], canary)

            # Repeat run must be noop (no conflicts)
            code2, mig2, err2 = run_cli(
                "migrate", "--source", "claude-code", "--target", "trae-cn",
                "--workspace", str(ws), "--home", str(home), "--scope", "all",
            )
            self.assertEqual(code2, 0, err2)
            self.assertEqual(mig2["conflicts"], [])
            # Every action in repeat run must be noop or parked_draft (hooks stay parked)
            self.assertTrue(all(a["outcome"] in ("noop", "parked_draft") for a in mig2["actions"]))

            # Inspect trae-cn confirms excluded built-in & jwt token
            code3, insp, err3 = run_cli(
                "inspect", "--profiles", "trae-cn", "--workspace", str(ws), "--home", str(home), "--summary",
            )
            self.assertEqual(code3, 0, err3)
            self.assertGreaterEqual(insp["totals"]["by_category"]["skills"], 2)
            self.assertGreaterEqual(insp["profiles"][0]["counts"]["excluded"], 2)

    def test_sync_skills_composable_for_any_tool(self) -> None:
        canary = "sk-sync-CANARY-99112233"
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws, home = base / "ws", base / "home"
            ws.mkdir()
            home.mkdir()

            # Create two skills under ~/.claude/skills (one without frontmatter, one with secret in helper)
            sk1 = home / ".claude" / "skills" / "plain-skill"
            sk1.mkdir(parents=True)
            (sk1 / "SKILL.md").write_text("# Plain Title\nAnalyze logs quickly.\n", encoding="utf-8")

            sk2 = home / ".claude" / "skills" / "secret-skill"
            (sk2 / "scripts").mkdir(parents=True)
            (sk2 / "SKILL.md").write_text("---\nname: secret-skill\ndescription: Has helper.\n---\nRun.\n", encoding="utf-8")
            (sk2 / "scripts" / "run.py").write_text(f'TOKEN = "{canary}"\n', encoding="utf-8")
            os.chmod(sk2 / "scripts" / "run.py", 0o755)

            dst_dir = base / "custom-tool" / "skills"

            # 1) Dry-run writes nothing
            c0, r0, e0 = run_cli(
                "sync-skills", "--src-profile", "claude", "--scope", "user",
                "--dst-dir", str(dst_dir), "--workspace", str(ws), "--home", str(home), "--dry-run",
            )
            self.assertEqual(c0, 0, e0)
            self.assertEqual(r0["totals"]["by_outcome"]["migrated"], 2)
            self.assertFalse(dst_dir.exists())

            # 2) Sync plain-skill with --synthesize-frontmatter
            c1, r1, e1 = run_cli(
                "sync-skills", "--src-profile", "claude", "--scope", "user",
                "--dst-dir", str(dst_dir), "--skills", "plain-skill", "--synthesize-frontmatter",
                "--workspace", str(ws), "--home", str(home),
            )
            self.assertEqual(c1, 0, e1)
            self.assertTrue((dst_dir / "plain-skill" / "SKILL.md").is_file())
            plain_out = (dst_dir / "plain-skill" / "SKILL.md").read_text(encoding="utf-8")
            self.assertIn("name: plain-skill", plain_out)
            self.assertIn("Analyze logs quickly.", plain_out)

            # 3) Sync from --src-dir with --redact-secrets
            c2, r2, e2 = run_cli(
                "sync-skills", "--src-dir", str(home / ".claude" / "skills"),
                "--dst-dir", str(dst_dir), "--skills", "secret-skill,missing-skill", "--redact-secrets",
                "--workspace", str(ws), "--home", str(home),
            )
            self.assertEqual(c2, 0, e2)
            self.assertNotIn(canary, json.dumps(r2) + e2)
            run_py = (dst_dir / "secret-skill" / "scripts" / "run.py").read_text(encoding="utf-8")
            self.assertNotIn(canary, run_py)
            self.assertEqual(len(r2["deferred"]), 1)
            self.assertEqual(r2["deferred"][0]["id"], "missing-skill")

            # 4) Divergent target causes conflict (no overwrite); identical is noop
            (dst_dir / "plain-skill" / "SKILL.md").write_text("modified locally\n", encoding="utf-8")
            c3, r3, e3 = run_cli(
                "sync-skills", "--src-dir", str(home / ".claude" / "skills"),
                "--dst-dir", str(dst_dir), "--skills", "plain-skill", "--synthesize-frontmatter",
                "--workspace", str(ws), "--home", str(home), "--strict-conflicts",
            )
            self.assertEqual(c3, 3, e3)
            self.assertEqual(r3["conflicts"][0]["id"], "plain-skill")
            self.assertEqual((dst_dir / "plain-skill" / "SKILL.md").read_text(encoding="utf-8"), "modified locally\n")

    def test_all_16_builtin_profiles_smoke_roundtrip(self) -> None:
        mod = load_script_module()
        profiles = list(mod.CANONICAL_PROFILES)
        self.assertEqual(len(profiles), 16)
        self.assertIn("trae-cn", profiles)

        for prof in profiles:
            with self.subTest(profile=prof), tempfile.TemporaryDirectory() as tmp:
                base = Path(tmp)
                ws1, home1 = base / "ws1", base / "home1"
                ws2, home2 = base / "ws2", base / "home2"
                ws1.mkdir()
                home1.mkdir()
                ws2.mkdir()
                home2.mkdir()

                # Seed minimal Claude Code source project+user Skill, rule, MCP
                (ws1 / "CLAUDE.md").write_text("Shared root note.\n", encoding="utf-8")
                sk = ws1 / ".claude" / "skills" / "smoke-skill"
                sk.mkdir(parents=True)
                (sk / "SKILL.md").write_text(
                    "---\nname: smoke-skill\ndescription: Smoke test skill.\n---\nFollow instructions.\n",
                    encoding="utf-8",
                )
                (ws1 / ".mcp.json").write_text(
                    json.dumps({"mcpServers": {"smoke-mcp": {"command": "npx", "args": ["-y", "smoke"]}}}),
                    encoding="utf-8",
                )

                c_m, d_m, e_m = run_cli(
                    "migrate", "--source", "claude-code", "--target", prof,
                    "--workspace", str(ws1), "--home", str(home1),
                    "--scope", "project", "--categories", "instructions,skills,mcp",
                )
                self.assertEqual(c_m, 0, f"{prof} migrate failed: {e_m}")
                self.assertTrue(d_m["ok"])
                self.assertEqual(d_m["conflicts"], [])

                c_i, d_i, e_i = run_cli(
                    "inspect", "--profiles", prof, "--workspace", str(ws1), "--home", str(home1), "--summary",
                )
                self.assertEqual(c_i, 0, f"{prof} inspect failed: {e_i}")
                self.assertTrue(d_i["ok"])

                bundle = base / f"bundle-{prof}"
                c_ex, d_ex, e_ex = run_cli(
                    "export-device", "--profiles", prof, "--workspace", str(ws1), "--home", str(home1),
                    "--scope", "all", "--output", str(bundle),
                )
                self.assertEqual(c_ex, 0, f"{prof} export-device failed: {e_ex}")
                self.assertTrue((bundle / "MIGRATION.md").is_file())

                c_im, d_im, e_im = run_cli(
                    "import-device", "--input", str(bundle), "--target", "same",
                    "--workspace", str(ws2), "--home", str(home2),
                )
                self.assertEqual(c_im, 0, f"{prof} import-device failed: {e_im}")
                self.assertTrue(d_im["ok"])
                self.assertEqual(d_im["conflicts"], [])


if __name__ == "__main__":
    unittest.main()
