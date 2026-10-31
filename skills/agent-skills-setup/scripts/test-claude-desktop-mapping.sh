#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_SCRIPT="${SCRIPT_DIR}/smart-ide-migration.sh"
PATHS_FILE="${SCRIPT_DIR}/../references/ide-paths.json"
IDE_REFERENCE="${SCRIPT_DIR}/../references/ides/claude-desktop.md"
SKILL_FILE="${SCRIPT_DIR}/../SKILL.md"
REGISTRY_FILE="${SCRIPT_DIR}/../references/registry-v2.json"

case "$(uname -s)" in
    Darwin|MINGW*|MSYS*|CYGWIN*)
        actual="$(bash "$MIGRATION_SCRIPT" legacy --print-path claude-desktop mcp 2>/dev/null)"
        [[ -n "$actual" && "$actual" == *claude_desktop_config.json ]] || {
            echo "FAIL: Claude Desktop documented platform path was not resolved: ${actual}" >&2
            exit 1
        }
        ;;
    *)
        if actual="$(bash "$MIGRATION_SCRIPT" legacy --print-path claude-desktop mcp 2>/dev/null)"; then
            echo "FAIL: Claude Desktop unexpectedly exposed an unconfirmed platform path: ${actual}" >&2
            exit 1
        fi
        [[ -z "$actual" ]] || {
            echo "FAIL: unsupported Claude Desktop MCP target printed: ${actual}" >&2
            exit 1
        }
        ;;
esac

python3 - "$PATHS_FILE" <<'PYEOF'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    entry = json.load(handle)["claude-desktop"]

assert entry["global_skills"] == ""
assert entry["project_skills"] == ""
assert entry["rules"] == ""
assert entry["config"] == ""
assert isinstance(entry["mcp"], dict)
assert entry["mcp"]["darwin"] == "~/Library/Application Support/Claude/claude_desktop_config.json"
assert entry["mcp"]["linux"] == ""
assert entry["mcp"]["windows"] == "%APPDATA%\\Claude\\claude_desktop_config.json"
PYEOF

section="$(<"$IDE_REFERENCE")"
for required in \
    'https://modelcontextprotocol.io/docs/develop/connect-local-servers' \
    'https://claude.com/docs/connectors/building/mcpb' \
    'https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop' \
    'https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp'; do
    if ! grep -Fq "$required" <<< "$section"; then
        echo "FAIL: Claude Desktop reference is missing source ${required}" >&2
        exit 1
    fi
done

if ! grep -Fq 'claude_desktop_config.json' <<< "$section"; then
    echo "FAIL: Claude Desktop reference is missing the documented legacy JSON path" >&2
    exit 1
fi

TMP_ROOT="$(mktemp -d /tmp/claude-desktop-mapping-test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT
mkdir -p "$TMP_ROOT/home" "$TMP_ROOT/workspace"

python3 - "$SKILL_FILE" "$IDE_REFERENCE" "$REGISTRY_FILE" "$SCRIPT_DIR" "$TMP_ROOT" <<'PYEOF'
import json
from pathlib import Path
import sys

skill_path = Path(sys.argv[1])
reference_path = Path(sys.argv[2])
registry_path = Path(sys.argv[3])
sys.path.insert(0, sys.argv[4])
fixture = Path(sys.argv[5])
from migration_core import Registry

skill = skill_path.read_text(encoding="utf-8")
reference = reference_path.read_text(encoding="utf-8")
index = (registry_path.parent / "ide-registry.md").read_text(encoding="utf-8")
for route in (
    "references/ide-registry.md",
    "references/registry-v2.json",
    "references/ides/<source>.md",
    "references/ides/<target>.md",
):
    assert route in skill, f"canonical Skill lost safe profile/reference routing: {route}"
assert "Cloud/UI and remote MCP remain manual" in skill
assert "(ides/claude-desktop.md)" in index
for boundary in (
    "Settings → Extensions",
    "Customize → Connectors",
    "no portable mapper path",
    "Code tab uses Claude Code's own",
):
    assert boundary in reference, f"conditional Claude Desktop reference lost boundary: {boundary}"

data = json.loads(registry_path.read_text(encoding="utf-8"))
alias = data["products"]["claude-desktop"]
assert alias["alias_of"] == {"product": "claude", "profile": "desktop-chat"}
assert alias["reference"] == "ides/claude-desktop.md"
assert data["aliases"]["claude-desktop"] == "claude/desktop-chat"
registry = Registry(registry_path, fixture / "workspace", home=fixture / "home")
product, profile, resolved = registry.profile("claude-desktop")
assert (product, profile) == ("claude", "desktop-chat")
assert resolved["migration_policy"] == "official-api-or-rebuild-checklist"
assert not resolved.get("surfaces"), "Desktop Chat must not expose guessed automatic filesystem surfaces"
for object_type in ("mcp", "skills", "instructions"):
    assert registry.surfaces("claude-desktop", object_type) == []
print("Claude Desktop conditional routing and UI-managed boundaries verified")
PYEOF

target_output="$(HOME="$TMP_ROOT/home" bash "$MIGRATION_SCRIPT" legacy \
    --source claude --target claude-desktop --workspace "$TMP_ROOT/workspace" \
    --objects mcp --dry-run 2>&1)"
source_output="$(HOME="$TMP_ROOT/home" bash "$MIGRATION_SCRIPT" legacy \
    --source claude-desktop --target cursor --workspace "$TMP_ROOT/workspace" \
    --objects mcp --dry-run 2>&1)"
case "$(uname -s)" in
    Darwin|MINGW*|MSYS*|CYGWIN*)
        grep -Fq 'legacy local MCP JSON' <<< "$target_output"
        grep -Fq 'legacy local MCP JSON' <<< "$source_output"
        ;;
    *)
        grep -Fq 'no confirmed legacy JSON path' <<< "$target_output"
        grep -Fq 'no confirmed legacy JSON path' <<< "$source_output"
        ;;
esac

if [[ "$(uname -s)" == "Darwin" ]]; then
    DESKTOP_CONFIG="$TMP_ROOT/home/Library/Application Support/Claude/claude_desktop_config.json"
    mkdir -p "$(dirname "$DESKTOP_CONFIG")"
    printf '%s\n' '{"mcpServers":{"desktop-local":{"command":"node","args":["server.js"],"env":{"API_KEY":"__desktop_inert_fixture__"}}}}' > "$DESKTOP_CONFIG"
    if HOME="$TMP_ROOT/home" bash "$MIGRATION_SCRIPT" legacy \
        --source claude-desktop --target cursor --workspace "$TMP_ROOT/workspace" \
        --objects mcp --yes --strategy overwrite \
        >"$TMP_ROOT/canonical.out" 2>"$TMP_ROOT/canonical.err"; then
        echo "FAIL: canonical entry point wrote from the legacy Claude Desktop alias" >&2
        exit 1
    fi
    grep -Fq 'legacy writes are disabled' "$TMP_ROOT/canonical.err"
    [[ ! -e "$TMP_ROOT/home/.cursor/mcp.json" ]]

    AGENT_SKILLS_SETUP_INTERNAL_LEGACY=1 HOME="$TMP_ROOT/home" \
        bash "${SCRIPT_DIR}/legacy-smart-ide-migration.sh" \
            --source claude-desktop --target cursor --workspace "$TMP_ROOT/workspace" \
            --objects mcp --yes --strategy overwrite >/dev/null 2>&1
    python3 - "$TMP_ROOT/home/.cursor/mcp.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
assert data["mcpServers"]["desktop-local"]["command"] == "node"
assert data["mcpServers"]["desktop-local"]["env"]["API_KEY"] == ""
PYEOF
fi

echo "Claude Desktop mapping test passed"
