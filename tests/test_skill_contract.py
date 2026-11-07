"""Structural and fixture checks only; these do NOT simulate a real agent/IDE."""
from __future__ import annotations
import importlib.util
import json
import re
import shutil
import tempfile
import tomllib
import unittest
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "agent-skills-setup"
DEV = ROOT / "dev" / "skills" / "maintain-agent-skills-setup"
spec = importlib.util.spec_from_file_location("package_skill", ROOT / "scripts/package_skill.py")
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)

class SkillContract(unittest.TestCase):
    def test_package_is_guidance_only(self):
        files = package.package_files()
        self.assertEqual(len(files), 10)
        self.assertTrue(all(p.suffix == ".md" or p.name == "LICENSE" for p in files))
        self.assertFalse((SKILL / "scripts").exists())

    def test_small_entrypoints(self):
        for directory in (SKILL, DEV):
            text = (directory / "SKILL.md").read_text(encoding="utf-8")
            self.assertTrue(text.startswith("---\n"))
            frontmatter = text.split("---", 2)[1]
            self.assertIn(f"name: {directory.name}", frontmatter)
            self.assertIn("description:", frontmatter)
            self.assertLess(len(text.splitlines()), 150)
            self.assertNotIn("allowed-tools:", frontmatter)

    def test_all_local_package_links_resolve(self):
        for base in (SKILL, DEV):
            for path in base.rglob("*.md"):
                text = path.read_text(encoding="utf-8")
                for link in re.findall(r"\[[^\]]*\]\(([^)]+)\)", text):
                    if "://" in link or link.startswith("#"):
                        continue
                    target = (path.parent / link.split("#")[0]).resolve()
                    self.assertTrue(target.is_relative_to(base.resolve()), (path, link))
                    self.assertTrue(target.is_file(), (path, link))

    def test_references_are_directly_discoverable(self):
        entry = (SKILL / "SKILL.md").read_text(encoding="utf-8")
        for path in (SKILL / "references").glob("*.md"):
            self.assertIn("references/" + path.name, entry)

    def test_workflow_keeps_non_engine_categories(self):
        entry = (SKILL / "SKILL.md").read_text(encoding="utf-8").lower()
        for word in ("prompts", "commands", "agents", "hooks", "memory"):
            self.assertIn(word, entry)
        self.assertIn("user-authored memory", entry)
        self.assertIn("preview requests make no target changes", entry)
        self.assertIn("no bundled runtime", entry)

    def test_publication_excludes_development_and_code(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "skill.zip"
            digest = package.build(out)
            self.assertEqual(len(digest), 64)
            with zipfile.ZipFile(out) as z:
                self.assertEqual(set(z.namelist()), {"agent-skills-setup/" + x for x in package.ALLOWED})
                self.assertFalse(any("dev/" in p or "evals/" in p or ".py" in p for p in z.namelist()))

    def test_packaging_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "existing.zip"
            out.write_bytes(b"preserve me")
            with self.assertRaises(ValueError):
                package.build(out)
            self.assertEqual(out.read_bytes(), b"preserve me")

    def test_packaging_rejects_extra_runtime(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "agent-skills-setup"
            shutil.copytree(SKILL, root)
            (root / "engine.py").write_text("raise RuntimeError('not shipped')", encoding="utf-8")
            with self.assertRaises(ValueError):
                package.package_files(root)

    def test_packaging_rejects_missing_reference(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "agent-skills-setup"
            shutil.copytree(SKILL, root)
            (root / "references/mcp.md").unlink()
            with self.assertRaises(ValueError):
                package.package_files(root)

    def test_archive_is_reproducible(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(package.build(Path(tmp)/"a.zip"), package.build(Path(tmp)/"b.zip"))

class Examples(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document = json.loads((ROOT / "evals/cases.json").read_text(encoding="utf-8"))
        cls.cases = {c["id"]: c for c in cls.document["cases"]}

    def test_rubrics_are_not_reported_as_completed_runs(self):
        self.assertEqual(self.document["status"], "behavior-not-run")
        self.assertEqual(len(self.cases), len(self.document["cases"]))
        self.assertGreaterEqual(len(self.cases), 15)
        for c in self.cases.values():
            self.assertTrue(c["must"])
            self.assertTrue(c["must_not"])
            for group in ("input_files", "expected_files"):
                for p in c.get(group, {}):
                    self.assertFalse(Path(p).is_absolute())
                    self.assertNotIn("..", Path(p).parts)

    def test_json_and_toml_examples_parse(self):
        for c in self.cases.values():
            for group in ("input_files", "expected_files"):
                for p, content in c.get(group, {}).items():
                    if p.endswith(".json"):
                        json.loads(content)
                    if p.endswith(".toml"):
                        tomllib.loads(content)

    def test_scoped_rule_expected_preserves_body_and_target_neighbor(self):
        c = self.cases["scoped-rule"]
        source = c["input_files"][".cursor/rules/python-tests.mdc"]
        target = c["expected_files"][".claude/rules/python-tests.md"]
        self.assertEqual(source.split("---",2)[2].strip(), target.split("---",2)[2].strip())
        self.assertIn('\"tests/**/*.py\"', target)
        self.assertIn("paths:", target)
        self.assertNotIn("alwaysApply", target)
        self.assertEqual(c["input_files"]["CLAUDE.md"], c["expected_files"]["CLAUDE.md"])

    def test_mcp_expected_preserves_target_and_uses_env_forwarding(self):
        c = self.cases["mcp-toml"]
        source = json.loads(c["input_files"]["selected-mcp.json"])["mcpServers"]["project-tools"]
        target = tomllib.loads(c["expected_files"][".codex/config.toml"])
        self.assertEqual(target["approval_policy"], "on-request")
        server = target["mcp_servers"]["project-tools"]
        self.assertEqual(server["command"], source["command"])
        self.assertEqual(server["args"], source["args"])
        self.assertEqual(server["env_vars"], ["PROJECT_TOKEN"])
        self.assertNotIn("env", server)

    def test_shared_settings_expected_excludes_siblings(self):
        c = self.cases["shared-settings"]
        expected = json.loads(c["expected_files"]["selected-mcp.json"])
        source = json.loads(c["input_files"][".gemini/settings.json"])
        self.assertEqual(expected, {"mcpServers":source["mcpServers"]})
        self.assertNotIn("trust", expected)
        self.assertNotIn("theme", expected)

if __name__ == "__main__":
    unittest.main()
