"""Defensive migration and permission checks; all inputs are synthetic and inert."""
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

SCRIPT = Path(__file__).resolve().parents[1] / "skills/agent-skills-setup/scripts/migrate_context.py"
_SPEC = importlib.util.spec_from_file_location("review_migrate_context", SCRIPT)
assert _SPEC and _SPEC.loader
migrate = importlib.util.module_from_spec(_SPEC)
sys.modules[_SPEC.name] = migrate
_SPEC.loader.exec_module(migrate)


class MigrationReviewSafety(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name).resolve()
        self.home = self.root / "home"
        self.work = self.root / "work"
        self.home.mkdir()
        self.work.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), USERPROFILE=str(self.home), PYTHONUTF8="1")
        for name in ("CODEX_HOME", "KIMI_CODE_HOME", "ANTIGRAVITY_SKILLS_DIR"):
            self.env.pop(name, None)

    def run_cli(self, command, *args, workspace=None, code=0):
        result = subprocess.run([
            sys.executable, "-B", str(SCRIPT), command, "--home", str(self.home),
            "--workspace", str(workspace or self.work), *args,
        ], env=self.env, capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(result.returncode, code, result.stderr)
        return json.loads(result.stdout)

    @staticmethod
    def write(path, text):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def test_zed_discovers_only_the_first_native_project_instruction(self):
        native = self.write(self.work / ".rules", "---\ndescription: Plain native instruction\n---\nUse the fixture.\n")
        for supplied_fallbacks in (False, True):
            with self.subTest(supplied_fallbacks=supplied_fallbacks):
                if supplied_fallbacks:
                    self.write(self.work / "AGENTS.md", "Later instruction.\n")
                    self.write(self.work / ".github/copilot-instructions.md", "Another later instruction.\n")
                rules = migrate.discover_profile("zed", self.work, self.home, "project", {"instructions"}).rules
                self.assertEqual([(rule.source_path, rule.kind, rule.body) for rule in rules],
                                 [(native, "always_on", native.read_text(encoding="utf-8"))])
        native.unlink()
        fallbacks = migrate.discover_profile("zed", self.work, self.home, "project", {"instructions"}).rules
        self.assertEqual([rule.source_path for rule in fallbacks], [self.work / ".github/copilot-instructions.md"])

    def test_zed_destination_warns_only_for_real_higher_priority_files(self):
        for higher_priority in ((), ("AGENT.md",), (".github/copilot-instructions.md", "AGENT.md")):
            with self.subTest(higher_priority=higher_priority):
                work = self.root / f"zed-{len(higher_priority)}"
                work.mkdir()
                original = {
                    name: self.write(work / name, f"{name} fixture.\n").read_bytes()
                    for name in ("CLAUDE.md", "GEMINI.md", *higher_priority)
                }
                (work / ".rules").mkdir()  # A directory is not a native rule file.
                report = self.run_cli("migrate", "--source", "claude-code", "--target", "zed",
                                      "--scope", "project", "--categories", "instructions", workspace=work)
                warnings = [w for w in report["warnings"] if w.get("code") == "zed_first_match_shadow_check"]
                self.assertEqual([w["present_files"] for w in warnings],
                                 [list(higher_priority)] if higher_priority else [])
                self.assertIn("CLAUDE.md fixture.", (work / "AGENTS.md").read_text(encoding="utf-8"))
                self.assertEqual({name: (work / name).read_bytes() for name in original}, original)

    def test_zed_defers_restricted_mcp_and_preserves_existing_settings(self):
        source = self.write(self.work / ".cursor/mcp.json", json.dumps({"mcpServers": {
            "fixture-local": {"command": "fixture-only", "includeTools": ["read_fixture"]},
            "fixture-remote": {"url": "https://example.invalid/mcp", "excludeTools": ["edit_fixture"]},
        }}))
        target = self.write(self.work / ".zed/settings.json", '// Existing setting\n{"vim_mode": true,}\n')
        before = target.read_bytes()
        args = ("--source", "cursor", "--target", "zed", "--scope", "project", "--categories", "mcp")
        report = self.run_cli("migrate", *args, "--strict-conflicts", code=3)
        self.assertEqual(report["summary"]["deferred"], 2)
        self.assertEqual(target.read_bytes(), before)
        self.assertEqual(report["backups"], [])
        servers = json.loads(source.read_text(encoding="utf-8"))["mcpServers"]
        servers["plain-fixture"] = {"command": "plain-fixture-only"}
        source.write_text(json.dumps({"mcpServers": servers}), encoding="utf-8")
        report = self.run_cli("migrate", *args)
        self.assertEqual(report["summary"]["deferred"], 2)
        settings = json.loads(target.read_text(encoding="utf-8"))
        self.assertTrue(settings["vim_mode"])
        self.assertEqual(list(settings["context_servers"]), ["plain-fixture"])

    def test_project_dotenv_names_require_a_dotenv_basename(self):
        for name in (".env", ".env.local", ".env.production.local"):
            self.assertTrue(migrate.is_project_dotenv(name), name)
        for name in (".env.example", "notes.txt", "nested/.env.local", ".env.local/notes.txt"):
            self.assertFalse(migrate.is_project_dotenv(name), name)

    def test_import_rejects_non_dotenv_entry_id_before_writing(self):
        self.write(self.work / ".env.local", "FIXTURE_MODE=offline\n")
        transfer = self.root / "dotenv-transfer"
        self.run_cli("export-device", "--profiles", "cursor", "--scope", "project",
                     "--categories", "env_secrets", "--output", str(transfer))
        manifest = transfer / "manifest.json"
        doc = json.loads(manifest.read_text(encoding="utf-8"))
        self.assertEqual(len(doc["entries"]), 1)
        self.assertEqual(doc["entries"][0]["id"], ".env.local")
        doc["entries"][0]["id"] = "notes.txt"
        manifest.write_text(json.dumps(doc), encoding="utf-8")
        destination = self.root / "dotenv-target"
        destination.mkdir()
        existing = self.write(destination / "notes.txt", "Leave the fixture alone.\n")
        before = existing.read_bytes()
        report = self.run_cli("import-device", "--input", str(transfer), "--target", "cursor",
                              workspace=destination, code=2)
        self.assertEqual(report["error"], "invalid_env_entry")
        self.assertEqual(existing.read_bytes(), before)
        self.assertEqual(list(destination.iterdir()), [existing])

    def test_dotenv_metadata_only_contains_identifiers(self):
        benign = "not-an-assignment TOKEN=example-placeholder"
        sample = benign + "\nexport\tDEMO_TOKEN=fixture-value\n"
        redacted, names = migrate.parse_dotenv_secrets(sample, redact=True)
        self.assertEqual([item["name"] for item in names], ["DEMO_TOKEN"])
        self.assertIn(benign, redacted)
        self.assertNotIn("fixture-value", redacted)

    def test_document_name_only_allows_portable_relative_paths(self):
        self.assertEqual(migrate.checked_doc_name("team/TaskStart"), "team/TaskStart")
        for value in ("", "./note.md", "nested//note.md", str(self.work / "note.md")):
            with self.subTest(value=value), self.assertRaises(migrate.SafetyRefusalError):
                migrate.checked_doc_name(value)

    def test_external_product_root_used_for_selected_discovery_and_writes(self):
        codex = self.root / "codex-config"
        kimi = self.root / "kimi-config"
        antigravity = self.root / "antigravity-skills"
        self.env.update(CODEX_HOME=str(codex), KIMI_CODE_HOME=str(kimi),
                        ANTIGRAVITY_SKILLS_DIR=str(antigravity))
        self.write(codex / "config.toml", '[mcp_servers.demo]\ncommand = "fixture-command"\n')
        self.write(kimi / "AGENTS.md", "# Kimi notes\n")
        self.write(antigravity / "fixture-skill" / "SKILL.md",
                   "---\nname: fixture-skill\ndescription: Fixture only\n---\n# Notes\n")
        self.write(self.work / ".codex/config.toml",
                   '[mcp_servers.project_only]\ncommand = "fixture-project"\n')
        report = self.run_cli("inspect", "--profiles", "codex,kimi-code,antigravity", "--scope", "user",
                              "--categories", "mcp,instructions,skills")
        found = {p["profile"]: p for p in report["profiles"]}
        self.assertEqual([item["name"] for item in found["codex"]["mcp"]], ["demo"])
        self.assertEqual(len(found["kimi-code"]["instructions"]), 1)
        self.assertEqual([item["name"] for item in found["antigravity"]["skills"]], ["fixture-skill"])

        transfer = self.root / "transfer"
        self.run_cli("export-device", "--profiles", "codex,antigravity", "--scope", "user",
                     "--categories", "mcp,skills", "--output", str(transfer))
        self.assertTrue((transfer / "manifest.json").is_file())
        self.run_cli("migrate", "--source", "codex", "--target", "kimi-code",
                     "--scope", "user", "--categories", "mcp")
        self.assertIn('"demo"', (kimi / "mcp.json").read_text(encoding="utf-8"))
        self.assertFalse((self.home / ".kimi-code/mcp.json").exists())
        self.assertTrue((self.work / ".codex/config.toml").is_file())

    @unittest.skipIf(os.name == "nt", "POSIX owner execute bit is not available on Windows")
    def test_hook_permission_is_only_restored_on_explicit_same_profile_activation(self):
        source = self.write(self.work / ".cline/hooks/TaskStart", "# Inert hook fixture; never executed\n")
        source.chmod(0o700)
        transfer = self.root / "transfer"
        exported = self.run_cli("export-device", "--profiles", "cline", "--scope", "project",
                                "--categories", "hooks", "--output", str(transfer))
        self.assertEqual(exported["exported_count"], 1)
        entry = json.loads((transfer / "manifest.json").read_text(encoding="utf-8"))["entries"][0]
        self.assertTrue(entry["executable"])
        self.assertEqual(stat.S_IMODE((transfer / entry["bundle_path"]).stat().st_mode), 0o600)

        parked = self.root / "parked"
        parked.mkdir()
        res_handoff = self.run_cli("import-device", "--input", str(transfer), "--scope", "project", workspace=parked)
        self.assertFalse((parked / ".cline/hooks/TaskStart").exists())
        self.assertFalse((parked / ".migration-review").exists())
        self.assertTrue(any(a["id"] == "TaskStart" and a["outcome"] == "agent_handoff" for a in res_handoff["agent_handoff"]))

        active = self.root / "explicit"
        active.mkdir()
        self.run_cli("import-device", "--input", str(transfer), "--scope", "project", "--activate-hooks",
                     "--strict-conflicts", workspace=active)
        live = active / ".cline/hooks/TaskStart"
        self.assertEqual(live.read_bytes(), source.read_bytes())
        self.assertTrue(live.stat().st_mode & stat.S_IXUSR)

    def test_inline_comments_preserve_activation_and_quoted_hashes(self):
        path = self.write(self.work / ".cursor/rules/review.mdc",
                          '---\nalwaysApply: true # note\ndescription: "Keep # here" # note\n---\nReview.\n')
        meta, _ = migrate.parse_frontmatter(path.read_text(encoding="utf-8"))
        self.assertEqual(meta["description"], "Keep # here")
        self.assertEqual(migrate.parse_rule_files(path, "project", "cursor")[0].kind, "always_on")

    def test_project_mcp_routing_uses_actual_user_destination(self):
        self.write(self.work / ".cursor/mcp.json",
                   '{"mcpServers":{"demo":{"command":"fixture-command"}}}')
        output = self.run_cli("migrate", "--source", "cursor", "--target", "cline",
                              "--scope", "all", "--categories", "mcp")
        self.assertEqual(output["summary"]["migrated"], 1)
        destination = self.home / ".cline/data/settings/cline_mcp_settings.json"
        self.assertEqual(json.loads(destination.read_text(encoding="utf-8"))["mcpServers"]["demo"]["command"],
                         "fixture-command")

    def test_normalized_rule_export_and_restore_keep_each_body_once(self):
        content = "# Root notes\nRoot fixture.\n"
        source = self.work / "AGENTS.md"
        for id_, body in (("one", "First fixture."), ("two", "Second fixture.")):
            content, _ = migrate.merge_markdown_section(content, id_, body)
        self.write(source, content)
        transfer = self.root / "transfer"
        self.run_cli("export-device", "--profiles", "cursor", "--scope", "project",
                     "--categories", "instructions", "--output", str(transfer))
        entries = json.loads((transfer / "manifest.json").read_text(encoding="utf-8"))["entries"]
        bodies = {e["id"]: (transfer / e["bundle_path"]).read_text(encoding="utf-8") for e in entries}
        self.assertEqual(bodies["one"].strip(), "First fixture.")
        self.assertEqual(bodies["two"].strip(), "Second fixture.")
        target = self.root / "target"
        target.mkdir()
        self.run_cli("import-device", "--input", str(transfer), "--scope", "project", workspace=target)
        restored = (target / "AGENTS.md").read_text(encoding="utf-8")
        for marker in ("Root fixture.", "First fixture.", "Second fixture."):
            self.assertEqual(restored.count(marker), 1)

    def test_restore_skill_uses_only_checked_manifest_files(self):
        skill = self.work / ".cursor/skills/fixtures"
        self.write(skill / "SKILL.md", "---\nname: fixtures\ndescription: Fixture\n---\n# Fixture\n")
        self.write(skill / "included.txt", "included\n")
        transfer = self.root / "transfer"
        self.run_cli("export-device", "--profiles", "cursor", "--scope", "project",
                     "--categories", "skills", "--output", str(transfer))
        self.write(transfer / "files/cursor/project/skills/fixtures/unlisted.txt", "unlisted\n")
        target = self.root / "target"
        target.mkdir()
        self.run_cli("import-device", "--input", str(transfer), "--scope", "project", workspace=target)
        restored = target / ".cursor/skills/fixtures"
        self.assertEqual({p.name for p in restored.iterdir()}, {"SKILL.md", "included.txt"})

    def test_redacted_skill_repeat_compares_final_bytes(self):
        skill = self.work / ".cursor/skills/fixtures"
        self.write(skill / "SKILL.md", "---\nname: fixtures\ndescription: Fixture\n---\n# Fixture\n")
        self.write(skill / ".env", "FIXTURE_TOKEN=fixture-value\n")
        args = ("--source", "cursor", "--target", "claude-code", "--scope", "project",
                "--categories", "skills", "--redact-secrets", "--strict-conflicts")
        self.assertEqual(self.run_cli("migrate", *args)["summary"]["migrated"], 1)
        self.assertEqual(self.run_cli("migrate", *args)["summary"]["noop"], 1)

    def test_binary_document_bytes_survive_direct_migration(self):
        path = self.work / ".cursor/commands/asset.bin"
        path.parent.mkdir(parents=True)
        data = bytes([0, 255, 254, 65, 0, 128])
        path.write_bytes(data)
        self.run_cli("migrate", "--source", "cursor", "--target", "claude-code", "--scope", "project",
                     "--categories", "commands", "--redact-secrets", "--strict-conflicts")
        self.assertEqual((self.work / ".claude/commands/asset.bin").read_bytes(), data)

    def test_divergent_same_name_documents_report_conflict_without_winning_copy(self):
        for profile, body in ((".cursor", "one"), (".claude", "two")):
            self.write(self.work / profile / "commands/review.md", f"# Review\n{body}\n")
        self.write(self.work / ".cursor/commands/other.md", "# Other\n")
        output = self.run_cli("migrate", "--source", "cursor,claude-code", "--target", "vscode",
                              "--scope", "project", "--categories", "commands")
        self.assertEqual(output["summary"]["conflict"], 1)
        self.assertFalse((self.work / ".github/prompts/review.prompt.md").exists())
        self.assertTrue((self.work / ".github/prompts/other.prompt.md").is_file())

    def test_cline_existing_single_file_merges_always_on_rule_and_preserves_neighbor(self):
        self.write(self.work / "AGENTS.md", "# New rule\nUse review notes.\n")
        existing = self.write(self.work / ".clinerules", "# Existing rule\nKeep this.\n")
        args = ("--source", "cursor", "--target", "cline", "--scope", "project",
                "--categories", "instructions", "--strict-conflicts")
        self.assertEqual(self.run_cli("migrate", *args)["summary"]["migrated"], 1)
        self.assertEqual(self.run_cli("migrate", *args)["summary"]["noop"], 1)
        text = existing.read_text(encoding="utf-8")
        self.assertIn("Keep this.", text)
        self.assertEqual(text.count("Use review notes."), 1)

    def test_same_profile_restore_preserves_original_shared_backup(self):
        # Cursor and Kilocode both use AGENTS.md; hand-build two independent,
        # checksummed profile entries using ordinary exports of different fixtures.
        import shutil
        transfer = self.root / "transfer"
        source = self.write(self.work / "AGENTS.md", "# Cursor fixture\n")
        self.run_cli("export-device", "--profiles", "cursor", "--scope", "project",
                     "--categories", "instructions", "--output", str(transfer))
        other = self.root / "other"
        self.write(source, migrate.merge_markdown_section("", "kilo-notes", "# Kilo fixture\n")[0])
        self.run_cli("export-device", "--profiles", "kilocode", "--scope", "project",
                     "--categories", "instructions", "--output", str(other))
        shutil.copytree(other / "files/kilocode", transfer / "files/kilocode")
        manifest_path = transfer / "manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        second = json.loads((other / "manifest.json").read_text(encoding="utf-8"))
        manifest["entries"].extend(second["entries"])
        manifest["profiles"].extend(second["profiles"])
        self.write(manifest_path, json.dumps(manifest))
        target = self.root / "destination"
        existing = self.write(target / "AGENTS.md", "# Original fixture\n")
        backups = self.root / "backups"
        output = self.run_cli("import-device", "--input", str(transfer), "--scope", "project",
                              "--backup-dir", str(backups), workspace=target)
        self.assertEqual(output["summary"]["migrated"], 2)
        self.assertEqual(len(output["backups"]), 1)
        self.assertEqual(Path(output["backups"][0]).read_text(encoding="utf-8"), "# Original fixture\n")
        self.assertIn("# Cursor fixture", existing.read_text(encoding="utf-8"))
        self.assertIn("# Kilo fixture", existing.read_text(encoding="utf-8"))

    def test_backup_destination_is_validated_before_any_write(self):
        from unittest.mock import patch
        target = self.write(self.work / "AGENTS.md", "# Existing\n")
        manager = migrate.BackupManager(self.root / "backups", self.home, self.work, False)
        with patch.object(migrate, "validate_contained", side_effect=migrate.SafetyRefusalError(
                "test_refusal", "synthetic refusal")) as validate, patch.object(
                migrate, "atomic_write_bytes") as write:
            with self.assertRaises(migrate.SafetyRefusalError):
                manager.backup_if_exists(target)
            validate.assert_called_once_with(manager.root / "workspace/AGENTS.md", manager.root, "backup_file")
            write.assert_not_called()
        self.assertFalse(manager.root.exists())

    @unittest.skipIf(os.name == "nt", "POSIX permission bits")
    def test_merged_memory_keeps_destination_and_backup_private(self):
        target = self.write(self.home / ".codex/AGENTS.md",
                            "# Existing fixture\nAuthorization: Bearer test-fixture-not-a-credential\n")
        target.chmod(0o600)
        original = target.read_bytes()
        self.write(self.home / ".claude/memory/check.md", "# New fixture note\n")
        result = self.run_cli("migrate", "--source", "claude-code", "--target", "codex",
                              "--scope", "user", "--categories", "memory",
                              "--backup-dir", str(self.root / "backups"))
        self.assertEqual(result["summary"]["migrated"], 1)
        self.assertTrue(target.read_bytes().startswith(original))
        self.assertIn(b"New fixture note", target.read_bytes())
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)
        backup, = map(Path, result["backups"])
        self.assertEqual(backup.read_bytes(), original)
        self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o600)

    def test_qwen_tool_restricted_skill_defers_on_unverified_destination(self):
        self.write(self.work / ".qwen/skills/fixture/SKILL.md",
                   '---\nname: fixture\ndescription: Fixture\nallowedTools: [Read]\n---\n# Notes\n')
        report = self.run_cli("migrate", "--source", "qwen-code", "--target", "claude-code",
                              "--scope", "project", "--categories", "skills")
        self.assertEqual(report["summary"]["deferred"], 1)
        self.assertFalse((self.work / ".claude/skills/fixture").exists())

    def test_vscode_prompt_and_agent_suffixes_are_removed_on_other_clients(self):
        self.write(self.work / ".github/prompts/team/review.prompt.md", "# Prompt fixture\n")
        self.write(self.work / ".github/agents/check.agent.md", "# Agent fixture\n")
        self.run_cli("migrate", "--source", "vscode", "--target", "claude-code",
                     "--scope", "project", "--categories", "commands,agents", "--strict-conflicts")
        self.assertTrue((self.work / ".claude/commands/team/review.md").is_file())
        self.assertTrue((self.work / ".claude/agents/check.md").is_file())
        self.assertFalse((self.work / ".claude/commands/team/review.prompt.md").exists())
