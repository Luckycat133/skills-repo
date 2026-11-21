"""Offline evidence for preserving resource contents and filenames."""
import ast
from pathlib import Path
import unittest

import test_migration_review_safety as fixtures


class ResourceTest(unittest.TestCase):
    setUp = fixtures.MigrationReviewSafety.setUp
    run_cli = fixtures.MigrationReviewSafety.run_cli
    write = staticmethod(fixtures.MigrationReviewSafety.write)

    def test_redacted_python_skill_preserves_environment_lookups(self):
        body = 'import os\nAPI_KEY = os.environ["API_KEY"]\nTOKEN = os.getenv("TOKEN")\n'
        root = self.work / ".cursor/skills/resources"
        self.write(root / "SKILL.md", "---\nname: resources\ndescription: Test resource\n---\n# Resources\n")
        self.write(root / "scripts/options.py", body)
        transfer = self.root / "resource-transfer"
        self.run_cli("export-device", "--profiles", "cursor", "--scope", "project",
                     "--categories", "skills", "--redact-secrets", "--output", str(transfer))
        files = list(transfer.rglob("options.py"))
        self.assertEqual(len(files), 1)
        self.assertEqual(files[0].read_text(encoding="utf-8"), body)
        self.run_cli("migrate", "--source", "cursor", "--target", "claude-code", "--scope", "project",
                     "--categories", "skills", "--redact-secrets", "--strict-conflicts")
        installed = self.work / ".claude/skills/resources/scripts/options.py"
        result = installed.read_text(encoding="utf-8")
        self.assertEqual(result, body)
        ast.parse(result)

    def test_vscode_documents_preserve_adjacent_binary_resource_names(self):
        data = bytes([0, 255, 1, 2])
        for source, target, suffix in [
            ("commands", "prompts", ".prompt.md"), ("agents", "agents", ".agent.md"),
        ]:
            folder = self.work / ".cursor" / source / "team"
            self.write(folder / "review.md", "[Diagram](diagram.png)\n")
            (folder / "diagram.png").write_bytes(data)
            self.run_cli("migrate", "--source", "cursor", "--target", "vscode", "--scope", "project",
                         "--categories", source, "--strict-conflicts")
            installed = self.work / ".github" / target / "team"
            self.assertEqual(sorted(p.name for p in installed.iterdir()), ["diagram.png", "review" + suffix])
            self.assertEqual((installed / Path("diagram.png")).read_bytes(), data)
