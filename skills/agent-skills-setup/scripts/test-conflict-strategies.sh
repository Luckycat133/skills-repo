#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_SCRIPT="$SCRIPT_DIR/smart-ide-migration.sh"
TMP_ROOT="$(mktemp -d /tmp/conflict-strategies-test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

TEST_HOME="$TMP_ROOT/home"
SOURCE_FILE="$TMP_ROOT/cursor-mcp.json"
mkdir -p "$TEST_HOME/.config/opencode"

printf '%s\n' '{"mcpServers":{"same":{"command":"new-server"}}}' > "$SOURCE_FILE"

SOURCE_SKILL="$TEST_HOME/.cursor/skills/demo"
TARGET_SKILL="$TEST_HOME/.claude/skills/demo"
mkdir -p "$SOURCE_SKILL" "$TARGET_SKILL"
printf '%s\n' 'source skill' > "$SOURCE_SKILL/SKILL.md"
printf '%s\n' 'existing target skill' > "$TARGET_SKILL/SKILL.md"
TARGET_HASH_BEFORE="$(shasum -a 256 "$TARGET_SKILL/SKILL.md" | awk '{print $1}')"

set +e
HOME="$TEST_HOME" bash "$MIGRATION_SCRIPT" \
    --source cursor --target claude --objects skills \
    --strategy typo --yes >"$TMP_ROOT/invalid-strategy.log" 2>&1
INVALID_STRATEGY_RC=$?
set -e

if [[ $INVALID_STRATEGY_RC -eq 0 ]]; then
    echo "FAIL: unknown strategy exited successfully" >&2
    exit 1
fi

TARGET_HASH_AFTER="$(shasum -a 256 "$TARGET_SKILL/SKILL.md" | awk '{print $1}')"
if [[ "$TARGET_HASH_AFTER" != "$TARGET_HASH_BEFORE" ]]; then
    echo "FAIL: unknown strategy modified the existing target" >&2
    exit 1
fi

if find "$TEST_HOME/.claude/skills" -maxdepth 1 -type d -name 'demo.bak.*' -print -quit | grep -q .; then
    echo "FAIL: unknown strategy created a backup before rejection" >&2
    exit 1
fi

if ! grep -q 'invalid strategy' "$TMP_ROOT/invalid-strategy.log"; then
    echo "FAIL: unknown strategy did not produce a clear validation error" >&2
    exit 1
fi

echo "PASS: unknown strategy fails before modifying an existing target"

write_existing_target() {
    printf '%s\n' '{"theme":"dark","mcp":{"keep":{"type":"local","command":["keep-server"]},"same":{"type":"local","command":["old-server"]}}}' \
        > "$TEST_HOME/.config/opencode/opencode.json"
}

write_existing_target
HOME="$TEST_HOME" bash "$MIGRATION_SCRIPT" \
    --source cursor --target opencode --objects mcp \
    --source-mcp-file "$SOURCE_FILE" --strategy backup --yes >/dev/null

python3 - "$TEST_HOME/.config/opencode/opencode.json" <<'PYEOF'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["theme"] == "dark"
assert data["mcp"]["keep"]["command"] == ["keep-server"]
assert data["mcp"]["same"]["command"] == ["new-server"]
PYEOF

BACKUP_FILE="$(find "$TEST_HOME/.config/opencode" -maxdepth 1 -name 'opencode.json.bak.*' -print -quit)"
python3 - "$BACKUP_FILE" <<'PYEOF'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["theme"] == "dark"
assert data["mcp"]["same"]["command"] == ["old-server"]
PYEOF

rm -f "$TEST_HOME/.config/opencode"/opencode.json.bak.*
write_existing_target
HOME="$TEST_HOME" bash "$MIGRATION_SCRIPT" \
    --source cursor --target opencode --objects mcp \
    --source-mcp-file "$SOURCE_FILE" --strategy overwrite --yes >/dev/null

python3 - "$TEST_HOME/.config/opencode/opencode.json" <<'PYEOF'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["theme"] == "dark", "overwrite removed an unrelated top-level setting"
assert set(data["mcp"]) == {"same"}, "overwrite did not replace only the selected MCP map"
assert data["mcp"]["same"]["command"] == ["new-server"]
PYEOF

if find "$TEST_HOME/.config/opencode" -maxdepth 1 -name 'opencode.json.bak.*' -print -quit | grep -q .; then
    echo "FAIL: overwrite unexpectedly created a backup" >&2
    exit 1
fi

echo "PASS: MCP backup/overwrite conflict strategies preserve their documented boundaries"
