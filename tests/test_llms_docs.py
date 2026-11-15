"""Keep single-fetch context aligned with the current guidance-only package."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "skills/agent-skills-setup"


class LLMDocumentation(unittest.TestCase):
    def test_full_context_contains_current_sources_verbatim(self):
        full = (ROOT / "llms-full.txt").read_text(encoding="utf-8")
        sources = [PACKAGE / "SKILL.md", *sorted((PACKAGE / "references").rglob("*.md")),
                   *sorted((PACKAGE / "assets").glob("*.md"))]
        self.assertEqual(full.count("## Source: "), len(sources))
        for source in sources:
            section = ("## Source: " + source.relative_to(ROOT).as_posix() + "\n\n"
                       + source.read_text(encoding="utf-8").rstrip() + "\n")
            self.assertIn(section, full, f"Refresh full context from {source}")

    def test_entrypoints_do_not_advertise_retired_engine(self):
        for name in ("llms.txt", "llms-full.txt"):
            text = (ROOT / name).read_text(encoding="utf-8")
            self.assertIn("0.11.0-dev", text)
            self.assertNotIn("| Full |", text)
            self.assertNotIn("Gemini CLI / Antigravity", text)
            self.assertNotIn("automatically sanitized", text)
            self.assertNotIn("instant 1-click rollback", text)


if __name__ == "__main__":
    unittest.main()
