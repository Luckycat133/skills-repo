#!/usr/bin/env bash
# Regression guard for Claude Desktop's documented local-MCP and connector
# boundaries. It only inspects mappings and never starts or configures Claude
# Desktop.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_SCRIPT="${SCRIPT_DIR}/smart-ide-migration.sh"
PATHS_FILE="${SCRIPT_DIR}/../references/ide-paths.json"
REGISTRY_FILE="${SCRIPT_DIR}/../references/ide-registry.md"
SKILL_FILE="${SCRIPT_DIR}/../SKILL.md"

if actual="$(bash "$MIGRATION_SCRIPT" --print-path claude-desktop mcp 2>/dev/null)"; then
    echo "FAIL: Claude Desktop unexpectedly has an automatic MCP-file target: ${actual}" >&2
    exit 1
fi

if [[ -n "$actual" ]]; then
    echo "FAIL: unsupported Claude Desktop MCP target printed: ${actual}" >&2
    exit 1
fi

python3 - "$PATHS_FILE" <<'PYEOF'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    entry = json.load(handle)["claude-desktop"]

assert entry == {
    "global_skills": "",
    "project_skills": "",
    "rules": "",
    "mcp": "",
    "config": "",
}
PYEOF

section="$(sed -n '/^### claude-desktop (Claude Desktop app)$/,/^### claude (Claude Code)$/p' "$REGISTRY_FILE")"
for required in \
    'https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop' \
    'https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp'; do
    if ! grep -Fq "$required" <<< "$section"; then
        echo "FAIL: Claude Desktop registry is missing source ${required}" >&2
        exit 1
    fi
done

if grep -Fq '~/.config/Claude/' <<< "$section" || grep -Fq '%APPDATA%\\Claude\\' <<< "$section"; then
    echo "FAIL: Claude Desktop registry still claims an undocumented platform path" >&2
    exit 1
fi

if ! grep -Fq 'Claude Desktop app' "$SKILL_FILE" || \
   ! grep -Fq 'Settings → Extensions' "$SKILL_FILE" || \
   ! grep -Fq 'Settings → Connectors' "$SKILL_FILE"; then
    echo "FAIL: canonical SKILL.md is missing Claude Desktop's manual MCP boundary" >&2
    exit 1
fi

TMP_ROOT="$(mktemp -d /tmp/claude-desktop-mapping-test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT
mkdir -p "$TMP_ROOT/home" "$TMP_ROOT/workspace"

target_output="$(HOME="$TMP_ROOT/home" bash "$MIGRATION_SCRIPT" \
    --source claude --target claude-desktop --workspace "$TMP_ROOT/workspace" \
    --objects mcp --dry-run 2>&1)"
if ! grep -Fq 'Claude Desktop local MCP configuration is manual' <<< "$target_output"; then
    echo "FAIL: Claude Desktop MCP target must provide its documented manual-only guidance" >&2
    exit 1
fi

source_output="$(HOME="$TMP_ROOT/home" bash "$MIGRATION_SCRIPT" \
    --source claude-desktop --target cursor --workspace "$TMP_ROOT/workspace" \
    --objects mcp --dry-run 2>&1)"
if ! grep -Fq 'Claude Desktop local MCP configuration is manual' <<< "$source_output"; then
    echo "FAIL: Claude Desktop MCP source must provide its documented manual-only guidance" >&2
    exit 1
fi

echo "Claude Desktop mapping test passed"
