#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_ROOT="$(mktemp -d /tmp/agent-skills-antigravity-test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

TEST_HOME="$TMP_ROOT/home"
WORKSPACE="$TMP_ROOT/workspace"
CURSOR_MCP="$TEST_HOME/.cursor/mcp.json"
ANTIGRAVITY_MCP="$TEST_HOME/.gemini/config/mcp_config.json"

assert_path() {
    local object="$1"
    local expected="$2"
    local actual

    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path antigravity "$object")"
    [[ "$actual" == "$expected" ]]
}

assert_path global "~/.gemini/antigravity/skills"
assert_path project ".agents"
assert_path project-skills ".agents/skills"
assert_path rules ".agents/rules"
assert_path mcp "~/.gemini/config/mcp_config.json"

if HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path antigravity config >/dev/null 2>&1; then
    echo "FAIL: Antigravity IDE unexpectedly exposes a standalone config migration target" >&2
    exit 1
fi

# Antigravity workspace rules are a directory, not an AGENTS.md-like single
# file. The generic single-file migration handler must leave this documented
# directory scope for manual migration rather than claiming it copied rules.
mkdir -p "$WORKSPACE/.agents/rules"
printf '%s\n' 'Use the documented workspace rules directory.' > "$WORKSPACE/.agents/rules/style.md"
RULES_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source antigravity \
    --target cursor \
    --workspace "$WORKSPACE" \
    --objects rules \
    --dry-run 2>&1)"
grep -Fq "Antigravity IDE rules use a directory; manual migration required" <<< "$RULES_OUTPUT"

mkdir -p "$(dirname "$CURSOR_MCP")"
printf '%s\n' \
    '{' \
    '  "mcpServers": {' \
    '    "official-remote": {"url": "https://example.invalid/mcp"}' \
    '  }' \
    '}' > "$CURSOR_MCP"

HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source cursor \
    --target antigravity \
    --objects mcp \
    --strategy overwrite \
    --yes >/dev/null

python3 - "$ANTIGRAVITY_MCP" <<'PYEOF'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    server = json.load(handle)["mcpServers"]["official-remote"]

assert server["serverUrl"] == "https://example.invalid/mcp"
assert "url" not in server
PYEOF

echo "Antigravity IDE migration test passed"
