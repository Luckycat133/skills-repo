#!/usr/bin/env bash

# Focused VS Code fixture test. It validates documented workspace mappings and
# proves that workspace MCP conversion is schema-aware while user-scope MCP
# migration fails closed without writing a guessed platform path. No VS Code
# process or real user configuration is touched.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_SCRIPT="$SCRIPT_DIR/smart-ide-migration.sh"
TMP_ROOT="$(mktemp -d /tmp/vscode-mapping-test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

assert_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(bash "$MIGRATION_SCRIPT" --print-path vscode "$object" 2>/dev/null || true)"
    if [[ "$expected" == "" ]]; then
        [[ -z "$actual" ]] || { echo "FAIL: vscode/$object expected unsupported/empty, got '$actual'" >&2; exit 1; }
    else
        [[ "$actual" == "$expected" ]] || { echo "FAIL: vscode/$object expected '$expected', got '$actual'" >&2; exit 1; }
    fi
}

assert_path global "~/.copilot/skills"
assert_path project-skills ".github/skills"
assert_path rules ".github/copilot-instructions.md"
assert_path project-mcp ".vscode/mcp.json"
assert_path mcp ""
assert_path config ""

TEST_HOME="$TMP_ROOT/home"
mkdir -p "$TEST_HOME"
printf '%s\n' '{"mcpServers":{"fixture":{"command":"node","args":["server.js"]}}}' > "$TEST_HOME/.claude.json"

OUTPUT="$TMP_ROOT/migration.txt"
HOME="$TEST_HOME" bash "$MIGRATION_SCRIPT" \
    --source claude --target vscode --objects mcp --yes --strategy backup \
    --workspace "$TMP_ROOT/workspace" > "$OUTPUT" 2>&1

python3 - "$TMP_ROOT/workspace/.vscode/mcp.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
assert list(data) == ["servers"]
assert data["servers"]["fixture"]["command"] == "node"
PYEOF

printf '%s\n' '{"mcpServers":{"ambiguous":{"url":"https://example.invalid/mcp"}}}' > "$TEST_HOME/.claude.json"
HOME="$TEST_HOME" bash "$MIGRATION_SCRIPT" \
    --source claude --target vscode --objects mcp --yes --strategy backup \
    --workspace "$TMP_ROOT/workspace" > "$TMP_ROOT/ambiguous.txt" 2>&1
grep -Fq 'VS Code MCP server schema/transport is ambiguous or unsupported' "$TMP_ROOT/ambiguous.txt"

python3 - "$TMP_ROOT/workspace/.vscode/mcp.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
assert "fixture" in data["servers"]
assert "ambiguous" not in data["servers"]
PYEOF

INVALID_WORKSPACE="$TMP_ROOT/invalid-workspace"
printf '%s' 'not-json' > "$TEST_HOME/.claude.json"
HOME="$TEST_HOME" bash "$MIGRATION_SCRIPT" \
    --source claude --target vscode --objects mcp --yes --strategy overwrite \
    --workspace "$INVALID_WORKSPACE" > "$TMP_ROOT/invalid-source.txt" 2>&1 || true
grep -Fq 'VS Code MCP requires a JSON `servers` conversion' "$TMP_ROOT/invalid-source.txt"
[[ ! -e "$INVALID_WORKSPACE/.vscode/mcp.json" ]] || {
    echo "FAIL: invalid non-JSON source was written to VS Code MCP path" >&2
    exit 1
}

PROMPT_WORKSPACE="$TMP_ROOT/prompt-workspace"
mkdir -p "$PROMPT_WORKSPACE/.github/prompts"
printf '%s\n' '---' 'description: valid prompt' '---' 'Use the fixture.' > "$PROMPT_WORKSPACE/.github/prompts/valid.prompt.md"
printf '%s' '# not a VS Code prompt file' > "$PROMPT_WORKSPACE/.github/prompts/ignored.md"
HOME="$TEST_HOME" bash "$MIGRATION_SCRIPT" \
    --source vscode --target claude --workspace "$PROMPT_WORKSPACE" \
    --objects prompts --yes --strategy overwrite > "$TMP_ROOT/prompts.txt" 2>&1
[[ -f "$PROMPT_WORKSPACE/.claude/commands/valid.prompt.md" ]] || {
    echo "FAIL: VS Code prompt file was not copied" >&2
    exit 1
}
[[ ! -e "$PROMPT_WORKSPACE/.claude/commands/ignored.md" ]] || {
    echo "FAIL: non-prompt Markdown file was copied from VS Code prompts" >&2
    exit 1
}

echo "VS Code mapping fixture test passed"
