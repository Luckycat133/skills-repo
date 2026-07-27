#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_ROOT="$(mktemp -d /tmp/codex-migration-test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

TEST_HOME="$TMP_ROOT/home"
SOURCE_MCP="$TEST_HOME/.claude.json"
TARGET_MCP="$TEST_HOME/.codex/config.toml"
SOURCE_CONFIG="$TEST_HOME/.codex/config.toml"
TARGET_CONFIG="$TEST_HOME/.openclaw/openclaw.json"
OUTPUT="$TMP_ROOT/mcp.txt"
CONFIG_OUTPUT="$TMP_ROOT/config.txt"

assert_path() {
    local object="$1"
    local expected="$2"
    local actual

    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path codex "$object")"
    [[ "$actual" == "$expected" ]] || {
        echo "FAIL: codex/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    }
}

assert_path global "~/.agents/skills"
assert_path project ".agents"
assert_path project-skills ".agents/skills"
assert_path project-config ".codex/config.toml"
assert_path mcp "~/.codex/config.toml"
assert_path config "~/.codex/config.toml"

mkdir -p "$TEST_HOME"
printf '%s\n' \
    '{' \
    '  "mcpServers": {' \
    '    "example": {"url": "https://example.invalid/mcp"}' \
    '  }' \
    '}' > "$SOURCE_MCP"

HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude \
    --target codex \
    --objects mcp \
    --strategy overwrite \
    --yes > "$OUTPUT"

if [[ -e "$TARGET_MCP" ]]; then
    echo "FAIL: JSON MCP configuration was written to Codex TOML config" >&2
    exit 1
fi

grep -Fq 'manual migration required' "$OUTPUT"

mkdir -p "$(dirname "$SOURCE_CONFIG")"
printf '%s\n' \
    '[mcp_servers.example]' \
    'url = "https://example.invalid/mcp"' \
    '' \
    '[hooks]' \
    'enabled = true' > "$SOURCE_CONFIG"

HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source codex \
    --target openclaw \
    --objects config \
    --strategy overwrite \
    --yes > "$CONFIG_OUTPUT"

if [[ -e "$TARGET_CONFIG" ]]; then
    echo "FAIL: Codex config.toml was copied to a non-Codex configuration target" >&2
    exit 1
fi

grep -Fq 'manual migration required' "$CONFIG_OUTPUT"
echo "Codex migration mapping test passed"
