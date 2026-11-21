"""Synthetic tests for instruction activation, identity, and deferral."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "skills/agent-skills-setup/scripts/migrate_context.py"


class BatchRulesTests(unittest.TestCase):
    def setUp(self):
        root = tempfile.TemporaryDirectory()
        self.addCleanup(root.cleanup)
        self.root = Path(root.name)
        self.workspace = self.root / "work"
        self.home = self.root / "home"
        self.workspace.mkdir()
        self.home.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), USERPROFILE=str(self.home), CODEX_HOME=str(self.home / ".codex"))

    def write(self, name, body):
        path = self.workspace / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")
        return path

    def run_cli(self, operation, *options, code=0):
        run = subprocess.run(
            [sys.executable, "-B", str(SCRIPT), operation, "--workspace", str(self.workspace),
             "--home", str(self.home), "--scope", "project", *options],
            env=self.env, capture_output=True, encoding="utf-8",
        )
        self.assertEqual(run.returncode, code, run.stderr)
        return json.loads(run.stdout)

    def rules(self, profile):
        return self.run_cli("inspect", "--profiles", profile, "--categories", "instructions")["profiles"][0]["instructions"]

    def test_claude_only_uses_paths_for_rule_activation(self):
        self.write(".claude/rules/default.md", "---\ndescription: Required\ntrigger: manual\n---\nAlways use fixtures.\n")
        self.write(".claude/rules/scoped.md", "---\npaths: [tests/**]\nalwaysApply: true\n---\nOnly scoped.\n")
        by_kind = {rule["kind"]: rule for rule in self.rules("claude-code")}
        self.assertEqual(set(by_kind), {"always_on", "glob_scoped"})
        self.assertEqual(by_kind["glob_scoped"]["globs"], ["tests/**"])
        self.run_cli("migrate", "--source", "claude-code", "--target", "cursor",
                     "--categories", "instructions", "--strict-conflicts")
        self.assertIn("Always use fixtures.", (self.workspace / "AGENTS.md").read_text(encoding="utf-8"))
        self.assertIn("alwaysApply: false", (self.workspace / ".cursor/rules/scoped.mdc").read_text(encoding="utf-8"))

    def test_nested_basename_rules_remain_distinct_and_idempotent(self):
        self.write(".cursor/rules/a/check.mdc", "---\nalwaysApply: true\n---\nFirst fixture.\n")
        self.write(".cursor/rules/b/check.mdc", "---\nalwaysApply: true\n---\nSecond fixture.\n")
        self.assertEqual(len({rule["id"] for rule in self.rules("cursor")}), 2)
        options = ("--source", "cursor", "--target", "codex", "--categories", "instructions", "--strict-conflicts")
        self.assertEqual(self.run_cli("migrate", *options)["summary"]["migrated"], 2)
        self.assertEqual(self.run_cli("migrate", *options)["summary"]["noop"], 2)
        migrated = (self.workspace / "AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("First fixture.", migrated)
        self.assertIn("Second fixture.", migrated)

    def test_directory_rules_are_reported_without_scope_widening(self):
        self.write("AGENTS.md", "Root fixture.\n")
        self.write("src/AGENTS.md", "Nested fixture.\n")
        self.write("node_modules/package/AGENTS.md", "Dependency fixture.\n")
        rules = self.rules("codex")
        self.assertEqual(len(rules), 2)
        report = self.run_cli("migrate", "--source", "codex", "--target", "claude-code",
                              "--categories", "instructions", "--strict-conflicts", code=3)
        self.assertEqual(report["parked_or_deferred"][0]["reason"], "directory_scope_requires_manual_mapping")
        migrated = (self.workspace / "CLAUDE.md").read_text(encoding="utf-8")
        self.assertIn("Root fixture.", migrated)
        self.assertNotIn("Nested fixture.", migrated)
        bundle = self.root / "transfer"
        exported = self.run_cli("export-device", "--profiles", "codex", "--categories", "instructions",
                                "--output", str(bundle))
        self.assertEqual(exported["exported_count"], 1)
        self.assertTrue(any(x["path"].endswith("src/AGENTS.md") and
                            x["reason"] == "directory_scope_requires_manual_mapping" for x in exported["excluded"]))

    def test_claude_imports_are_deferred_without_reading_dependencies(self):
        self.write("CLAUDE.md", "See @docs/policy.md for project conventions.\n")
        # Non-UTF-8 proves the import is not parsed or read into the transfer.
        self.write("docs/policy.md", "").write_bytes(b"\xfffixture")
        bundle = self.root / "transfer"
        report = self.run_cli("export-device", "--profiles", "claude-code", "--categories", "instructions",
                              "--output", str(bundle))
        self.assertEqual(report["exported_count"], 0)
        reason = "claude_import_dependencies_require_manual_mapping"
        self.assertTrue(any(x["reason"] == reason for x in report["excluded"]))
        self.assertIn(reason, (bundle / "MIGRATION.md").read_text(encoding="utf-8"))
        direct = self.run_cli("migrate", "--source", "claude-code", "--target", "cursor",
                              "--categories", "instructions", "--strict-conflicts", code=3)
        self.assertEqual(direct["parked_or_deferred"][0]["reason"], reason)
        self.assertFalse((self.workspace / "AGENTS.md").exists())
