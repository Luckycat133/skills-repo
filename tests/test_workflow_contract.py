"""Documentation/rubric contracts only, not model or native-client execution."""
from __future__ import annotations
import ast
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills/agent-skills-setup"
DEV = ROOT / "dev/skills/maintain-agent-skills-setup"

def text(path: Path) -> str:
    return path.read_text(encoding="utf-8")

class WorkflowContract(unittest.TestCase):
    def test_new_guidance_is_linked_from_entrypoint(self):
        entry = text(SKILL / "SKILL.md")
        for name in ("cli-workflow.md", "registry-v2.md", "verification.md"):
            self.assertIn("references/" + name, entry)
            self.assertTrue((SKILL / "references" / name).is_file())
        self.assertLess(len(entry.splitlines()), 150)

    def test_package_explicitly_admits_only_guidance(self):
        module = ast.parse(text(ROOT / "scripts/package_skill.py"))
        assignment = next(n for n in module.body if isinstance(n, ast.Assign)
                          and any(isinstance(t, ast.Name) and t.id == "ALLOWED" for t in n.targets))
        allowed = ast.literal_eval(assignment.value.args[0])
        self.assertEqual(len(allowed), 43)
        for name in ("references/cli-workflow.md", "references/registry-v2.md"):
            self.assertIn(name, allowed)
        self.assertTrue(all(p.endswith(".md") or p == "LICENSE" for p in allowed))
        self.assertFalse(any(p.startswith(("dev/", "evals/", "scripts/", "docs/history/")) for p in allowed))

    def test_cli_distinguishes_native_commands_from_retired_engine(self):
        guide = text(SKILL / "references/cli-workflow.md")
        for phrase in ("no bundled runtime", "Not presumed read-only", "Separate execution",
                       "preview", "re-read", "retired releases", "Maintainer-only"):
            self.assertIn(phrase, guide)
        self.assertIn("not an installation task", guide)

    def test_registry_does_not_promote_historical_claims(self):
        guide = text(SKILL / "references/registry-v2.md")
        for phrase in ("archived", "not a new runtime registry", "schema_version",
                       "migration_policy", "support_level", "not a successful client run",
                       "per surface", "unknown, not absent"):
            self.assertIn(phrase, guide)

    def test_delivery_accounts_for_every_object_outcome(self):
        outcomes = ("copied", "converted", "unchanged", "conflict", "draft",
                    "deferred", "excluded", "failed")
        for relative in ("references/verification.md", "assets/migration-report.md"):
            content = text(SKILL / relative)
            for outcome in outcomes:
                self.assertRegex(content, rf"\b{outcome}\b")
            self.assertIn("logical objects", content)

    def test_discovery_activation_and_runtime_are_separate(self):
        guide = text(SKILL / "references/verification.md")
        for level in ("Syntax", "Native discovery", "Activation", "Runtime/connection"):
            self.assertIn(level, guide)
        for status in ("pass", "fail", "not-run", "blocked"):
            self.assertIn(f"`{status}`", guide)
        self.assertIn("not runtime proof", text(SKILL / "references/cli-workflow.md"))

    def test_dev_run_template_records_revision_and_provenance(self):
        template = text(DEV / "references/result-template.md")
        for phrase in ("commit SHA", "dirty state", "digest", "user-reported",
                       "Exact command", "Exit code", "not client tests"):
            self.assertIn(phrase, template)
        self.assertIn("references/checkout-review.md", text(DEV / "SKILL.md"))

    def test_new_cases_remain_unrun(self):
        doc = json.loads(text(ROOT / "evals/workflow-cases.json"))
        self.assertEqual(doc["status"], "behavior-not-run")
        cases = doc["cases"]
        self.assertEqual(len(cases), 10)
        self.assertEqual(len({c["id"] for c in cases}), len(cases))
        for case in cases:
            self.assertEqual(case["status"], "not-run")
            self.assertTrue(case["prompt"])
            self.assertTrue(case["must"])
            self.assertTrue(case["must_not"])

    def test_portable_report_excludes_private_backup_paths(self):
        guide = text(SKILL / "references/verification.md")
        self.assertIn("portable/public report", guide)
        self.assertIn("credential-bearing backups", guide)
        self.assertIn("concurrent", guide)
        self.assertIn("No universal atomic rollback claim", text(SKILL / "assets/migration-report.md"))

    def test_review_contract_records_baseline_mismatch_without_reset(self):
        guide = text(DEV / "references/checkout-review.md")
        self.assertIn("4f7b343ac0e909119ecc07efe1e98ec219136b11", guide)
        self.assertIn("user-reported", guide)
        self.assertIn("Never reset or discard local changes", guide)
        self.assertIn("not a permanent expected test count", guide)

if __name__ == "__main__":
    unittest.main()
