"""Exercise read-only Antigravity workflow enumeration with synthetic Markdown."""
from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "skills/agent-skills-setup/scripts/migrate_context.py"


class LegacyWorkflowDiscoveryTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.ws = Path(tmp.name) / "workspace"
        self.home = Path(tmp.name) / "home"
        self.ws.mkdir()
        self.home.mkdir()

    def add_project_doc(self, path):
        target = self.ws / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("# Review notes\n\nReview the documentation.\n", encoding="utf-8")

    def inspect(self, scope):
        result = subprocess.run(
            [sys.executable, "-B", str(SCRIPT), "inspect", "--workspace", str(self.ws),
             "--home", str(self.home), "--profiles", "antigravity",
             "--scope", scope, "--categories", "workflows"],
            check=True, capture_output=True, text=True,
        )
        return [(item["scope"], item["name"]) for item in
                json.loads(result.stdout)["profiles"][0]["other_items"]]

    def test_legacy_nested_workflow_is_discovered(self):
        self.add_project_doc(".agent/workflows/review/team.md")
        self.assertEqual(self.inspect("project"), [("project", "review/team.md")])

    def test_current_and_legacy_distinct_workflows_are_discovered(self):
        self.add_project_doc(".agent/workflows/legacy.md")
        self.add_project_doc(".agents/workflows/current.md")
        self.assertEqual(self.inspect("all"), [
            ("project", "current.md"), ("project", "legacy.md"),
        ])

    def test_user_scope_does_not_include_project_workflows(self):
        self.add_project_doc(".agent/workflows/legacy.md")
        self.add_project_doc(".agents/workflows/current.md")
        self.assertEqual(self.inspect("user"), [])
