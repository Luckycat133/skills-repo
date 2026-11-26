"""Offline catalog consistency, never an assertion of native IDE compatibility."""
from __future__ import annotations
from datetime import date
import json
from pathlib import Path
import re
import tomllib
import unittest
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills/agent-skills-setup"
ISO_DATE_RE = re.compile(r"\b\d{4}-\d{2}-\d{2}\b")


def latest_catalog_path() -> Path:
    candidates = sorted((ROOT / "docs/research").glob("catalog-*.json"))
    if not candidates:
        raise AssertionError("no docs/research/catalog-*.json found")
    return candidates[-1]


class CatalogContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ledger_path = latest_catalog_path()
        cls.ledger = json.loads(cls.ledger_path.read_text(encoding="utf-8"))
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
        self.assertIn(self.ledger["runtime_status"], {"not-run", "in-progress", "complete"})
        self.assertEqual(len({r["id"] for r in self.records}), len(self.records))
        self.assertEqual(len(self.records), 90)
        queue_by_id = {row["id"]: row for row in self.queue["rows"]}
        for r in self.records:
            date.fromisoformat(r["reviewed_at"])
            self.assertEqual(r["runtime"], queue_by_id[r["id"]]["status"])
            if r["runtime"] == "not-run":
                self.assertEqual(queue_by_id[r["id"]].get("evidence_paths", []), [])
            else:
                self.assertTrue(queue_by_id[r["id"]].get("evidence_paths") or queue_by_id[r["id"]].get("block_reason"))
            self.assertTrue(r["evidence"])
            path = r["reference"]
            self.assertTrue(path.startswith("references/products/") and path.endswith(".md"), path)
            text = (SKILL / path).read_text(encoding="utf-8")
            self.assertIn(f"# {r['id']}\n", text)
            sources = re.findall(r"\]\((https://[^)]+)\)", text)
            self.assertTrue(sources)
            for source in sources:
                parsed = urlparse(source)
                self.assertEqual(parsed.scheme, "https")
                self.assertTrue(parsed.netloc)

    def test_reference_anchors_and_index_routes_exist(self):
        index = (SKILL / "references/products.md").read_text(encoding="utf-8")
        for r in self.records:
            name = r["reference"]
            p = SKILL / name
            self.assertTrue(p.is_file(), name)
            text = p.read_text(encoding="utf-8")
            self.assertIn(f"# {r['id']}\n", text)
            self.assertIn(r["id"], index)
            self.assertIn(f"(products/{r['id']}.md)", index)
            for label in r["aliases"]:
                self.assertIn(label, index)
            m = ISO_DATE_RE.search(text)
            self.assertIsNotNone(m, f"{name} lacks an ISO review date")
            date.fromisoformat(m.group(0))
            if r["runtime"] == "not-run":
                self.assertIn("not run", text)

    def test_only_selected_family_documents_need_loading(self):
        entry = (SKILL / "SKILL.md").read_text(encoding="utf-8")
        index = (SKILL / "references/products.md").read_text(encoding="utf-8")
        products = {r["reference"] for r in self.records}
        actual = {p.relative_to(SKILL).as_posix() for p in (SKILL / "references/products").glob("*.md")}
        self.assertEqual(products, actual)
        self.assertEqual(len(actual), 90)
        self.assertIn("references/products.md", entry)
        for path in actual:
            self.assertIn("products/" + Path(path).name, index)

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

    def test_scenarios_are_parseable_and_reference_canonical_profiles(self):
        self.assertIn(self.scenarios["status"], {"behavior-not-run", "in-progress", "complete"})
        canonical_ids = {r["id"] for r in self.records}
        ids = set()
        for c in self.scenarios["cases"]:
            self.assertNotIn(c["id"], ids)
            ids.add(c["id"])
            self.assertIn(c["status"], {"not-run", "pass", "fail"})
            if self.scenarios["status"] == "behavior-not-run":
                self.assertEqual(c["status"], "not-run")
            self.assertTrue(c["profiles"], c["id"])
            for prof in c["profiles"]:
                self.assertIn(prof, canonical_ids, f"non-canonical profile {prof!r} in case {c['id']!r}")
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
