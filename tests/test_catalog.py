"""Offline catalog consistency, never an assertion of native IDE compatibility."""
from __future__ import annotations
import json
from pathlib import Path
import re
import tomllib
import unittest
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills/agent-skills-setup"
DATE = "2026-11-07"

class CatalogContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ledger = json.loads((ROOT / f"docs/research/catalog-{DATE}.json").read_text(encoding="utf-8"))
        cls.records = cls.ledger["records"]
        cls.queue = json.loads((ROOT / "evals/client-matrix.json").read_text(encoding="utf-8"))
        cls.scenarios = json.loads((ROOT / "evals/catalog-cases.json").read_text(encoding="utf-8"))

    def test_historical_identifiers_have_explicit_routes(self):
        seen = {}
        for r in self.records:
            for label in {r["id"], *r["aliases"]}:
                self.assertNotIn(label, seen, (label, seen.get(label), r["id"]))
                seen[label] = r["id"]
        self.assertEqual(len(self.ledger["historical_identifiers"]), 87)
        self.assertFalse(set(self.ledger["historical_identifiers"]) - seen.keys())
        self.assertFalse(set(self.ledger["new_identifiers"]) - seen.keys())

    def test_documentation_evidence_is_not_runtime_evidence(self):
        self.assertEqual(self.ledger["runtime_status"], "not-run")
        self.assertEqual(len({r["id"] for r in self.records}), len(self.records))
        self.assertEqual(len(self.records), 90)
        for r in self.records:
            self.assertEqual(r["reviewed_at"], DATE)
            self.assertEqual(r["runtime"], "not-run")
            self.assertTrue(r["evidence"])
            path, anchor = r["reference"].split("#", 1)
            text = (SKILL / path).read_text(encoding="utf-8")
            section = text.split("## " + anchor + "\n", 1)[1].split("\n## ", 1)[0]
            sources = re.findall(r"\]\((https://[^)]+)\)", section)
            self.assertTrue(sources)
            for source in sources:
                parsed = urlparse(source)
                self.assertEqual(parsed.scheme, "https")
                self.assertTrue(parsed.netloc)

    def test_reference_anchors_and_index_routes_exist(self):
        index = (SKILL / "references/products.md").read_text(encoding="utf-8")
        for r in self.records:
            name, anchor = r["reference"].split("#", 1)
            p = SKILL / name
            self.assertTrue(p.is_file(), name)
            text = p.read_text(encoding="utf-8")
            self.assertIn("## " + anchor + "\n", text)
            self.assertIn(r["id"], index)
            for label in r["aliases"]:
                self.assertIn(label, index)
            self.assertIn(DATE, text)
            self.assertIn("not run", text)

    def test_only_selected_family_documents_need_loading(self):
        entry = (SKILL / "SKILL.md").read_text(encoding="utf-8")
        families = {r["reference"].split("#")[0] for r in self.records}
        actual = {p.relative_to(SKILL).as_posix() for p in (SKILL / "references/products").glob("*.md")}
        self.assertEqual(families, actual)
        self.assertEqual(len(actual), 30)
        for path in actual:
            self.assertIn(path, entry)

    def test_client_queue_covers_every_record_without_fabricated_results(self):
        rows = self.queue["rows"]
        self.assertIn(self.queue["status"], {"not-run", "in-progress", "complete"})
        self.assertEqual({r["id"] for r in rows}, {r["id"] for r in self.records})
        self.assertEqual(len(rows), len(self.records))
        self.assertEqual(len(self.queue["required_categories"]), 11)
        self.assertEqual(len(self.queue["required_checks"]), 7)
        for r in rows:
            self.assertIn(r["status"], {"not-run", "pass", "fail", "blocked-environment", "blocked-documentation", "not-applicable"})
            if r["status"] in {"pass", "fail"}:
                self.assertTrue(r.get("installed_version"), r["id"])
                self.assertTrue(r.get("harness"), r["id"])
                self.assertTrue(r.get("os"), r["id"])
                self.assertTrue(r.get("evidence_paths"), r["id"])
                self.assertTrue(r.get("category_results"), r["id"])
            elif r["status"] != "not-run":
                self.assertTrue(r.get("block_reason"), r["id"])
            for evidence_path in r.get("evidence_paths", []):
                evidence = Path(evidence_path)
                self.assertFalse(evidence.is_absolute())
                self.assertNotIn("..", evidence.parts)
                self.assertTrue((ROOT / evidence).is_file(), evidence_path)

    def test_scenarios_are_unrun_and_parseable(self):
        self.assertEqual(self.scenarios["status"], "behavior-not-run")
        ids = set()
        for c in self.scenarios["cases"]:
            self.assertNotIn(c["id"], ids)
            ids.add(c["id"])
            self.assertEqual(c["status"], "not-run")
            self.assertTrue(c["must"])
            self.assertTrue(c["must_not"])
            for group in ("input_files", "expected_files"):
                for path, content in c.get(group, {}).items():
                    self.assertFalse(Path(path).is_absolute())
                    self.assertNotIn("..", Path(path).parts)
                    if path.endswith(".json"):
                        json.loads(content)
                    elif path.endswith(".toml"):
                        tomllib.loads(content)
        self.assertGreaterEqual(len(ids), 20)

    def test_catalog_never_calls_pending_tests_passed(self):
        index = (SKILL / "references/products.md").read_text(encoding="utf-8")
        self.assertIn("not-run", index)
        self.assertIn("discovery-required", index)
        self.assertNotIn("fully supported", index.lower())

if __name__ == "__main__":
    unittest.main()
