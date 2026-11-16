"""Structural and fixture checks only; these do NOT simulate a real agent/IDE."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import re
import shutil
import tempfile
import tomllib
import unittest
from urllib.parse import unquote
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "agent-skills-setup"
DEV = ROOT / "dev" / "skills" / "maintain-agent-skills-setup"
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)]+)\)")

spec = importlib.util.spec_from_file_location("package_skill", ROOT / "scripts/package_skill.py")
assert spec is not None and spec.loader is not None
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)


def heading_slugs(path: Path) -> set[str]:
    slugs: set[str] = set()
    in_fence = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence or not line.startswith("#"):
            continue
        title = line.lstrip("#").strip().lower()
        slug = re.sub(r"[^a-z0-9 -]", "", title)
        slug = re.sub(r"\s+", "-", slug).strip("-")
        slugs.add(slug)
    return slugs


class SkillContract(unittest.TestCase):
    def test_package_allowlist_and_authorized_script_only(self) -> None:
        files = package.package_files()
        self.assertEqual(len(files), len(package.ALLOWED))
        rels = {p.relative_to(SKILL).as_posix() for p in files}
        self.assertEqual(rels, set(package.ALLOWED))
        py_files = [r for r in rels if r.endswith(".py")]
        self.assertEqual(py_files, ["scripts/migrate_context.py"])
        helper_text = (SKILL / "scripts/migrate_context.py").read_text(encoding="utf-8")
        self.assertIn("# /// script", helper_text)
        self.assertIn('requires-python = ">=3.11"', helper_text)
        self.assertIn("dependencies = []", helper_text)
        for retired in ("acb_bundle", "ed25519", "import sqlite3"):
            self.assertNotIn(retired, helper_text.lower())

    def test_small_entrypoints(self) -> None:
        for directory in (SKILL, DEV):
            text = (directory / "SKILL.md").read_text(encoding="utf-8")
            self.assertTrue(text.startswith("---\n"))
            frontmatter = text.split("---", 2)[1]
            self.assertIn(f"name: {directory.name}", frontmatter)
            self.assertIn("description:", frontmatter)
            self.assertLess(len(text.splitlines()), 140)
            self.assertNotIn("allowed-tools:", frontmatter)

    def test_all_local_package_links_and_anchors_resolve(self) -> None:
        for base in (SKILL, DEV):
            for path in sorted(base.rglob("*.md")):
                in_fence = False
                for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                    if line.startswith("```"):
                        in_fence = not in_fence
                        continue
                    if in_fence:
                        continue
                    for raw_link in LINK_RE.findall(line):
                        link = raw_link.split()[0]
                        if "://" in link or link.startswith("mailto:"):
                            continue
                        self.assertFalse(link.startswith("/"), (path, lineno, link))
                        rel_part, _, fragment = link.partition("#")
                        target = (path.parent / unquote(rel_part)).resolve() if rel_part else path.resolve()
                        self.assertTrue(target.is_relative_to(base.resolve()), (path, lineno, link))
                        self.assertTrue(target.is_file(), (path, lineno, link))
                        if fragment and target.suffix == ".md":
                            self.assertIn(fragment.lower(), heading_slugs(target), (path, lineno, link))

    def test_references_are_directly_discoverable(self) -> None:
        entry = (SKILL / "SKILL.md").read_text(encoding="utf-8")
        for path in (SKILL / "references").glob("*.md"):
            self.assertIn("references/" + path.name, entry)

    def test_workflow_keeps_non_engine_categories_and_zero_leak_rules(self) -> None:
        entry = (SKILL / "SKILL.md").read_text(encoding="utf-8").lower()
        for word in ("prompts", "commands", "agents", "hooks", "memory", "migrate_context.py"):
            self.assertIn(word, entry)
        self.assertIn("user-authored memory", entry)
        self.assertIn("preview requests make no target changes", entry)

    def test_publication_excludes_development_and_preserves_script_exec_bit(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "skill.zip"
            digest = package.build(out)
            self.assertEqual(len(digest), 64)
            with zipfile.ZipFile(out) as z:
                self.assertEqual(set(z.namelist()), {"agent-skills-setup/" + x for x in package.ALLOWED})
                self.assertFalse(any("dev/" in p or "evals/" in p or "/docs/" in p or "__pycache__" in p or p.endswith(".pyc") for p in z.namelist()))
                script_info = z.getinfo("agent-skills-setup/scripts/migrate_context.py")
                doc_info = z.getinfo("agent-skills-setup/SKILL.md")
                self.assertEqual((script_info.external_attr >> 16) & 0o777, 0o755)
                self.assertEqual((doc_info.external_attr >> 16) & 0o777, 0o644)

    def test_packaging_refuses_overwrite(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "existing.zip"
            out.write_bytes(b"preserve me")
            with self.assertRaises(ValueError):
                package.build(out)
            self.assertEqual(out.read_bytes(), b"preserve me")

    def test_packaging_rejects_extra_runtime_and_pycache(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "agent-skills-setup"
            shutil.copytree(SKILL, root)
            (root / "engine.py").write_text("raise RuntimeError('not shipped')", encoding="utf-8")
            with self.assertRaises(ValueError):
                package.package_files(root)
            (root / "engine.py").unlink()
            pycache = root / "scripts" / "__pycache__"
            pycache.mkdir()
            (pycache / "migrate_context.cpython-311.pyc").write_bytes(b"pyc")
            with self.assertRaises(ValueError):
                package.package_files(root)

    def test_packaging_rejects_missing_reference(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "agent-skills-setup"
            shutil.copytree(SKILL, root)
            (root / "references/mcp.md").unlink()
            with self.assertRaises(ValueError):
                package.package_files(root)

    def test_archive_is_reproducible(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(
                hashlib.sha256((Path(tmp) / "a.zip").read_bytes()).hexdigest()
                if not package.build(Path(tmp) / "a.zip")
                else package.build(Path(tmp) / "b.zip"),
                hashlib.sha256((Path(tmp) / "a.zip").read_bytes()).hexdigest(),
            )


class Examples(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = json.loads((ROOT / "evals/cases.json").read_text(encoding="utf-8"))
        cls.cases = {c["id"]: c for c in cls.document["cases"]}

    def test_rubrics_are_not_reported_as_completed_runs(self) -> None:
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

    def test_json_and_toml_examples_parse(self) -> None:
        for c in self.cases.values():
            for group in ("input_files", "expected_files"):
                for p, content in c.get(group, {}).items():
                    if p.endswith(".json"):
                        json.loads(content)
                    if p.endswith(".toml"):
                        tomllib.loads(content)

    def test_scoped_rule_expected_preserves_body_and_target_neighbor(self) -> None:
        c = self.cases["scoped-rule"]
        source = c["input_files"][".cursor/rules/python-tests.mdc"]
        target = c["expected_files"][".claude/rules/python-tests.md"]
        self.assertEqual(source.split("---", 2)[2].strip(), target.split("---", 2)[2].strip())
        self.assertIn('"tests/**/*.py"', target)
        self.assertIn("paths:", target)
        self.assertNotIn("alwaysApply", target)
        self.assertEqual(c["input_files"]["CLAUDE.md"], c["expected_files"]["CLAUDE.md"])

    def test_mcp_expected_preserves_target_and_uses_env_forwarding(self) -> None:
        c = self.cases["mcp-toml"]
        source = json.loads(c["input_files"]["selected-mcp.json"])["mcpServers"]["project-tools"]
        target = tomllib.loads(c["expected_files"][".codex/config.toml"])
        self.assertEqual(target["approval_policy"], "on-request")
        server = target["mcp_servers"]["project-tools"]
        self.assertEqual(server["command"], source["command"])
        self.assertEqual(server["args"], source["args"])
        self.assertEqual(server["env_vars"], ["PROJECT_TOKEN"])
        self.assertNotIn("env", server)

    def test_shared_settings_expected_excludes_siblings(self) -> None:
        c = self.cases["shared-settings"]
        expected = json.loads(c["expected_files"]["selected-mcp.json"])
        source = json.loads(c["input_files"][".gemini/settings.json"])
        self.assertEqual(expected, {"mcpServers": source["mcpServers"]})
        self.assertNotIn("trust", expected)
        self.assertNotIn("theme", expected)


if __name__ == "__main__":
    unittest.main()
