#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REFERENCES_DIR="$SKILL_DIR/references"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

python3 "$SCRIPT_DIR/validate-registry-v2.py" \
    --registry "$REFERENCES_DIR/registry-v2.json" \
    --index "$REFERENCES_DIR/ide-registry.md" \
    --references "$REFERENCES_DIR/ides" \
    --today 2026-08-17

python3 - "$REFERENCES_DIR/registry-v2.json" <<'PY'
import json
import sys
from pathlib import Path

registry = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
products = registry["products"]

assert products["cline"]["profiles"]["ide"]["surfaces"]["mcp"][0]["path"] == "~/.cline/data/settings/cline_mcp_settings.json"
assert products["cline"]["profiles"]["ide"]["surfaces"]["mcp"][0]["override_relative_path"] == "settings/cline_mcp_settings.json"
cline_rules = products["cline"]["profiles"]["ide"]["surfaces"]["instructions"]
assert cline_rules[0]["compatibility_paths"] == ["~/Documents/Cline/Rules"]
assert cline_rules[1]["compatibility_paths"] == [".clinerules"]
amazon_q_mcp = products["amazon-q"]["profiles"]["ide"]["surfaces"]["mcp"][0]
assert "~/.aws/amazonq/agents/default.json" in amazon_q_mcp["compatibility_paths"]
augment_mcp = products["augment-code"]["profiles"]["cli-ide"]["surfaces"]["mcp"]
assert {(entry["scope"], entry["path"]) for entry in augment_mcp} >= {
    ("project", ".augment/settings.json"),
    ("local", ".augment/settings.local.json"),
}
codex_surfaces = products["codex"]["profiles"]["cli"]["surfaces"]
assert codex_surfaces["instructions"][1]["path"] == "AGENTS.md"
assert codex_surfaces["instructions"][1]["compatibility_behavior"] == "precedence"
assert {(entry["scope"], entry["path"]) for entry in codex_surfaces["mcp"]} == {
    ("user", "~/.codex/config.toml"),
    ("project", ".codex/config.toml"),
}
factory_surfaces = products["factory-droid"]["profiles"]["cli"]["surfaces"]
assert {(entry["scope"], entry["path"]) for entry in factory_surfaces["agents"]} == {
    ("user", "~/.factory/droids"),
    ("project", ".factory/droids"),
}
assert {entry["scope"] for entry in factory_surfaces["hooks"]} >= {
    "user", "project"
}
assert {entry["scope"] for entry in products["qoder"]["profiles"]["cli"]["surfaces"]["hooks"]} == {
    "user", "project", "local"
}
assert {entry["scope"] for entry in products["mistral-vibe"]["profiles"]["cli"]["surfaces"]["mcp"]} == {
    "user", "project"
}
assert {entry["scope"] for entry in products["pi"]["profiles"]["cli"]["surfaces"]["config"]} == {
    "user", "project"
}
assert {entry["scope"] for entry in products["crush"]["profiles"]["cli"]["surfaces"]["mcp"]} == {
    "user", "project"
}
assert products["firebase-studio"]["profiles"]["legacy-workspace"]["migration_policy"] == "source-only"
assert products["forge"]["profiles"]["cli"]["surfaces"]["config"][0]["path"] == ".forge.toml"
assert products["qoder"]["default_profile"] == "cli"
assert registry["profile_templates"]["manual-reference"]["support_level"] == "unverified"
assert registry["support_contract"]["bidirectional-reviewed"]["support_level"] == "partial"
assert products["monkeycode"]["template"] == "cloud-ui"
assert ".windsurf/rules" in {
    entry["path"]
    for entry in products["windsurf"]["profiles"]["ide"]["surfaces"]["instructions"]
}
PY

if python3 "$SCRIPT_DIR/validate-registry-v2.py" \
    --registry "$REFERENCES_DIR/registry-v2.json" \
    --index "$REFERENCES_DIR/ide-registry.md" \
    --references "$REFERENCES_DIR/ides" \
    --today 2027-08-13 >"$TMP_ROOT/stale.log" 2>&1; then
    echo "FAIL: stale registry passed the freshness gate" >&2
    exit 1
fi
grep -Fq 'registry is stale' "$TMP_ROOT/stale.log" || {
    echo "FAIL: stale registry failure did not explain freshness" >&2
    exit 1
}

echo "Registry v2 test passed"
