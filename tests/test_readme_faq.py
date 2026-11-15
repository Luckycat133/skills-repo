"""README must not override the canonical guidance-only migration boundary."""
from pathlib import Path
import unittest

README = Path(__file__).resolve().parents[1] / 'README.md'


class ReadmeFAQ(unittest.TestCase):
    def test_faq_does_not_claim_universal_product_equivalence(self):
        faq = README.read_text(encoding='utf-8').split('## Frequently Asked Questions', 1)[1].split('## Contribute', 1)[0]
        self.assertNotIn('supports bidirectional migration between', faq)
        self.assertNotIn('Gemini CLI / Antigravity', faq)
        self.assertIn('distinct profiles', faq)
        self.assertIn('does not certify universal', faq)
        self.assertIn('references/products.md', faq)

    def test_mcp_faq_preserves_execution_and_secret_boundaries(self):
        faq = README.read_text(encoding='utf-8').split('### Q: Does it migrate MCP servers?', 1)[1].split('### Q:', 1)[0]
        self.assertNotIn('`settings.json` (Claude Code)', faq)
        for expected in ('does not install, start or connect', 'credential values and grants',
                         'separate evidence', 'references/mcp.md', 'products/anthropic.md'):
            self.assertIn(expected, faq)


if __name__ == '__main__': unittest.main()
