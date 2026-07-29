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
