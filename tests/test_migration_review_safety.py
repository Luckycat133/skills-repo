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
        self.run_cli("import-device", "--input", str(transfer), "--scope", "project", workspace=parked)
        self.assertFalse((parked / ".cline/hooks/TaskStart").exists())
        draft = parked / ".migration-review/hooks/cline/project/TaskStart"
        self.assertEqual(draft.read_bytes(), source.read_bytes())
        self.assertFalse(draft.stat().st_mode & stat.S_IXUSR)

        active = self.root / "explicit"
        active.mkdir()
        self.run_cli("import-device", "--input", str(transfer), "--scope", "project", "--activate-hooks",
                     "--strict-conflicts", workspace=active)
        live = active / ".cline/hooks/TaskStart"
        self.assertEqual(live.read_bytes(), source.read_bytes())
        self.assertTrue(live.stat().st_mode & stat.S_IXUSR)
