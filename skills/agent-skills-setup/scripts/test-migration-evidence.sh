#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_SCRIPT="$SCRIPT_DIR/smart-ide-migration.sh"
TMP_ROOT="$(mktemp -d /tmp/migration-evidence-test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

TEST_HOME="$TMP_ROOT/home"
WORKSPACE="$TMP_ROOT/workspace"
SOURCE_FILE="$TMP_ROOT/cursor-mcp.json"
DRY_REPORT="$TMP_ROOT/dry-run.json"
APPLY_REPORT="$TMP_ROOT/apply.json"
mkdir -p "$TEST_HOME" "$WORKSPACE"

printf '%s\n' '{"mcpServers":{"fixture":{"command":"node","args":["server.js"]}}}' > "$SOURCE_FILE"

HOME="$TEST_HOME" bash "$MIGRATION_SCRIPT" \
    --source cursor --target opencode --workspace "$WORKSPACE" \
    --objects project-mcp --source-mcp-file "$SOURCE_FILE" \
    --strategy backup --dry-run --json > "$DRY_REPORT" 2>/dev/null

python3 - "$DRY_REPORT" "$SOURCE_FILE" "$WORKSPACE/opencode.json" <<'PYEOF'
import json
import pathlib
import sys

report = json.load(open(sys.argv[1]))
source = str(pathlib.Path(sys.argv[2]).resolve())
target = str(pathlib.Path(sys.argv[3]).resolve())
assert report["mode"] == "dry-run"
assert report["scope"] == "project"
assert report["objects"] == ["project-mcp"]
evidence = report["evidence"]["mcp"][0]
assert evidence["scope"] == "project"
assert evidence["source_path"] == source
assert evidence["target_path"] == target
assert evidence["source_unchanged"] is True
assert evidence["target_exists"] is False
assert evidence["target_validation"] == "absent"
assert len(evidence["source_sha256_before"]) == 64
assert evidence["source_sha256_before"] == evidence["source_sha256_after"]
PYEOF

HOME="$TEST_HOME" bash "$MIGRATION_SCRIPT" \
    --source cursor --target opencode --workspace "$WORKSPACE" \
    --objects project-mcp --source-mcp-file "$SOURCE_FILE" \
    --strategy backup --yes --json > "$APPLY_REPORT" 2>/dev/null

python3 - "$APPLY_REPORT" <<'PYEOF'
import json
import sys

report = json.load(open(sys.argv[1]))
assert report["mode"] == "apply"
evidence = report["evidence"]["mcp"][0]
assert evidence["source_unchanged"] is True
assert evidence["target_exists"] is True
assert evidence["target_validation"] == "valid-json"
assert len(evidence["target_sha256"]) == 64
PYEOF

echo "PASS: JSON report contains deterministic MCP migration evidence"
