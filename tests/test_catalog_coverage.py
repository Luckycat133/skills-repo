from __future__ import annotations

from datetime import date
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "agent-skills-setup"
CATALOG_DOC = SKILL / "references" / "products.md"
PRODUCTS_DIR = SKILL / "references" / "products"
LEDGER_PATH = sorted((ROOT / "docs" / "research").glob("catalog-*.json"))[-1]
CLIENT_MATRIX_PATH = ROOT / "evals" / "client-matrix.json"
CATALOG_EVALS_PATH = ROOT / "evals" / "catalog-cases.json"

ALLOWED_EVIDENCE = {
    "documented-subset",
    "version-sensitive",
    "discovery-required",
    "legacy-source",
    "host-only",
    "provider-or-installer",
}
URL_RE = re.compile(r"https://[^\s)>]+")


def parse_routing_rows(text: str) -> list[tuple[set[str], str, str]]:
    rows: list[tuple[set[str], str, str]] = []
    for line in text.splitlines():
        if not line.startswith("| `"):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        names = set(re.findall(r"`([^`]+)`", cells[0]))
        m = re.search(r"\((products/[^)]+)\)", cells[1])
        if not m:
            raise AssertionError(f"routing row lacks product link: {line}")
        rows.append((names, "references/" + m.group(1), cells[2]))
    return rows


def parse_sections(path: Path) -> dict[str, str]:
    sections: dict[str, list[str]] = {}
    current = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            current = line[3:].strip()
            sections[current] = []
        elif current is not None:
            sections[current].append(line)
    return {k: "\n".join(v).strip() for k, v in sections.items()}


class CatalogCoverageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.ledger = json.loads(LEDGER_PATH.read_text(encoding="utf-8"))
        self.catalog_text = CATALOG_DOC.read_text(encoding="utf-8")
        self.rows = parse_routing_rows(self.catalog_text)

    def test_canonical_and_historical_and_new_identifiers_all_route_in_column_one(self) -> None:
        self.assertEqual(len(self.ledger["historical_identifiers"]), 87)
        self.assertEqual(len(self.ledger["records"]), 90)
        routed: dict[str, str] = {}
        for names, target, evidence in self.rows:
            self.assertIn(evidence, ALLOWED_EVIDENCE)
            for name in names:
                self.assertNotIn(name, routed, f"ambiguous duplicate identifier in routing index: {name}")
                routed[name] = target

        for rec in self.ledger["records"]:
            self.assertIn(rec["id"], routed, f"canonical record ID missing from Column 1: {rec['id']}")
            self.assertEqual(routed[rec["id"]], rec["reference"])
        for hid in self.ledger["historical_identifiers"]:
            self.assertIn(hid, routed, f"historical ID missing from routing index: {hid}")
        for nid in self.ledger["new_identifiers"]:
            self.assertIn(nid, routed, f"new ID missing from routing index: {nid}")

    def test_every_ledger_record_points_to_concise_sourced_section(self) -> None:
        product_files = sorted(PRODUCTS_DIR.glob("*.md"))
        self.assertEqual(len(product_files), 90)
        for pf in product_files:
            self.assertLessEqual(len(pf.read_text(encoding="utf-8").splitlines()), 95, f"{pf} grew too large")

        seen_ids: set[str] = set()
        all_urls: set[str] = set()
        for rec in self.ledger["records"]:
            rid = rec["id"]
            self.assertNotIn(rid, seen_ids)
            seen_ids.add(rid)
            date.fromisoformat(rec["reviewed_at"])
            self.assertEqual(rec["runtime"], "not-run")
            self.assertIn(rec["evidence"], ALLOWED_EVIDENCE)

            rel_file = rec["reference"]
            self.assertEqual(rel_file, f"references/products/{rid}.md")
            doc_path = SKILL / rel_file
            self.assertTrue(doc_path.is_file(), f"missing {doc_path}")
            body = doc_path.read_text(encoding="utf-8")
            self.assertIn(f"# {rid}\n", body)
            self.assertIn(f"Evidence: `{rec['evidence']}`", body)
            self.assertIn("Runtime: `not-run`", body)
            self.assertIn("Official sources:", body)
            urls = URL_RE.findall(body)
            self.assertGreaterEqual(len(urls), 1, f"{rid} lacks official source URL")
            all_urls.update(urls)

        self.assertGreaterEqual(len(all_urls), 90)

    def test_known_high_risk_semantic_traps_remain_explicit(self) -> None:
        checks = {
            "claude-desktop.md": ["Chat, Projects, Cowork"],
            "claude-code.md": [".mcp.json"],
            "codex.md": ["AGENTS.override.md", "env_vars"],
            "copilot-cli.md": ["mcp-config.json"],
            "vscode.md": ["servers"],
            "copilot-other-hosts.md": ["Visual Studio"],
            "gemini-cli.md": [".gemini/settings.json"],
            "antigravity.md": [".agents/skills", "trigger: always_on"],
            "firebase-studio.md": [".idx/mcp.json"],
            "cline.md": ["cline_mcp_settings.json"],
            "kilocode.md": [".kilo/skills"],
            "roo-code.md": ["2026-05-15"],
            "devin.md": ["Devin", ".devin/mcp_config.json"],
            "continue.md": ["config.yaml"],
            "zed.md": ["context_servers"],
            "junie.md": ["~/.junie/mcp/mcp.json"],
            "xcode.md": ["CodingAssistant"],
            "kiro.md": ["fileMatchPattern", "CLI 3"],
            "amazon-q.md": ["agents/default.json"],
            "qwen-code.md": ["allowedTools"],
            "qoder-cn.md": [".lingma/skills"],
            "codebuddy.md": ["context: fork", "SKILL.md"],
            "trae-cn.md": ["docs.trae.cn"],
            "trae.md": ["docs.trae.ai"],
            "kimi-code.md": ["KIMI_CODE_HOME"],
            "zcode.md": [".zcode"],
            "minimax-code.md": ["MiniMax-AI/minimax-code"],
            "iflycode.md": ["iflycode_mcp.json"],
            "forge.md": ["~/forge"],
            "pi.md": ["~/.pi/agent/mcp.json"],
            "goose.md": ["goose-docs.ai"],
            "factory-droid.md": [".factory-plugin/plugin.json"],
            "augment-code.md": ["~/.augment/skills"],
            "opencode.md": ["V1", "V2", "opencode/autoinvoke"],
            "openclaw.md": ["nodeHost.mcp.servers"],
            "hermes.md": ["Nous Research"],
            "letta-code.md": [".af", "MEMORY_DIR"],
            "ibm-bob.md": ["alwaysAllow", "~/.bob/settings/mcp.json"],
            "rovodev.md": ["mcpConfigPath"],
            "gitlab-duo.md": ["GLAB_CONFIG_DIR"],
            "replit.md": ["replit.md", "Replit Secrets"],
            "monkeycode.md": ["MonkeyCode"],
            "editor-hosts.md": ["HelixML"],
            "mcphub-nvim.md": ["mcphub"],
            "gptel.md": ["gptel-agent"],
            "avante.md": ["avante.nvim"],
            "pearai.md": ["pearai-submodule"],
            "trae-work.md": [".trae/skills"],
            "codearts.md": ["CodeArts"],
            "t3-code.md": ["t3code"],
            "coder-xum.md": ["coder/xum"],
        }
        for filename, needles in checks.items():
            content = (PRODUCTS_DIR / filename).read_text(encoding="utf-8")
            for needle in needles:
                self.assertIn(needle, content, f"{filename} lost critical guidance: {needle}")

    def test_catalog_never_claims_runtime_pass_or_cartesian_matrix(self) -> None:
        all_docs = [CATALOG_DOC, *sorted(PRODUCTS_DIR.glob("*.md"))]
        for doc in all_docs:
            text = doc.read_text(encoding="utf-8")
            self.assertNotIn("Runtime: `pass`", text)
            self.assertNotIn("100% compatible", text.lower())
            self.assertIn("not-run", text)

    def test_client_acceptance_queue_and_new_evals_remain_repo_only(self) -> None:
        matrix = json.loads(CLIENT_MATRIX_PATH.read_text(encoding="utf-8"))
        self.assertEqual(len(matrix["rows"]), 90)
        self.assertEqual({r["id"] for r in matrix["rows"]}, {r["id"] for r in self.ledger["records"]})
        self.assertTrue(all(r["status"] == "not-run" for r in matrix["rows"]))

        extra = json.loads(CATALOG_EVALS_PATH.read_text(encoding="utf-8"))
        self.assertGreaterEqual(len(extra["cases"]), 20)
        ids = [c["id"] for c in extra["cases"]]
        self.assertEqual(len(ids), len(set(ids)))
        for case in extra["cases"]:
            self.assertEqual(case["status"], "not-run")
            self.assertGreaterEqual(len(case["must"]), 1)
            self.assertGreaterEqual(len(case["must_not"]), 1)


if __name__ == "__main__":
    unittest.main()
