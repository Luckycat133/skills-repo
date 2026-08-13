#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$SCRIPT_DIR/smart-ide-migration.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

WORKSPACE="$TMP_ROOT/workspace"
TEST_HOME="$TMP_ROOT/home"
mkdir -p \
    "$WORKSPACE/.cline/skills/demo" \
    "$WORKSPACE/.cline/rules" \
    "$TEST_HOME"

bash "$CLI" > "$TMP_ROOT/help.txt"
grep -F '{detect,inventory,plan,apply,verify,rollback}' "$TMP_ROOT/help.txt" >/dev/null

cp "$SKILL_DIR/evals/files/instruction-ir-source.mdc" \
    "$WORKSPACE/.cline/rules/source.mdc"
printf '%s\n' '---' 'name: demo' 'description: Test fixture.' '---' '# Demo' \
    > "$WORKSPACE/.cline/skills/demo/SKILL.md"
printf '%s\n' 'NON_SECRET_FIXTURE=kept-out-of-target' \
    > "$WORKSPACE/.cline/skills/demo/.env.local"
printf '%s\n' \
    '{' \
    '  "mcpServers": {' \
    '    "example": {' \
    '      "command": "example-server",' \
    '      "args": ["--token", "literal-arg-secret"],' \
    '      "env": {"API_TOKEN": "literal-secret", "MY_VALUE": "sk-ant-abcdefghijklmnopqrstuvw", "REDIRECT_URL": "https://nested:password@example.test/callback", "MODE": "safe"}' \
    '    },' \
    '    "remote": {"url": "https://user:pass@example.test/mcp?api_key=literal-query-secret", "headers": {"Authorization": "Bearer ${env:MCP_TOKEN}"}}' \
    '  }' \
    '}' > "$WORKSPACE/.cline/mcp.json"

HOME="$TEST_HOME" bash "$CLI" inventory \
    --workspace "$WORKSPACE" --product cline --json > "$TMP_ROOT/inventory.json"
python3 - "$TMP_ROOT/inventory.json" <<'PY'
import json
import sys
from pathlib import Path

rows = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert any(row.get("object_type") == "mcp" and row["exists"] for row in rows)
assert any(row.get("object_type") == "skills" and row["exists"] for row in rows)
PY

HOME="$TEST_HOME" bash "$CLI" detect \
    --workspace "$WORKSPACE" --product cline --json > "$TMP_ROOT/detect.json"
python3 - "$TMP_ROOT/detect.json" <<'PY'
import json
import sys
from pathlib import Path

rows = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert rows and all(row["exists"] for row in rows)
PY

HOME="$TEST_HOME" bash "$CLI" plan \
    --workspace "$WORKSPACE" \
    --source cline/ide \
    --target forge/cli \
    --objects skills,instructions,mcp \
    --scope project \
    --json > "$TMP_ROOT/plan.json"
python3 - "$TMP_ROOT/plan.json" <<'PY'
import json
import sys
from pathlib import Path

plan = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert [item["status"] for item in plan["items"]] == ["ready", "ready", "ready"]
assert {item["field"] for item in plan["loss_report"]["items"]} >= {
    "activation",
    "globs",
    "priority",
    "example.env.API_TOKEN",
    "example.args[1]",
    "remote.url",
}
PY

if HOME="$TEST_HOME" bash "$CLI" apply \
    --workspace "$WORKSPACE" \
    --source cline/ide \
    --target forge/cli \
    --objects skills \
    --scope project > "$TMP_ROOT/no-confirm.log" 2>&1; then
    echo "FAIL: apply succeeded without --yes" >&2
    exit 1
fi

MANIFEST="$TMP_ROOT/manifest.json"
HOME="$TEST_HOME" bash "$CLI" apply \
    --workspace "$WORKSPACE" \
    --source cline/ide \
    --target forge/cli \
    --objects skills,instructions,mcp \
    --scope project \
    --manifest "$MANIFEST" \
    --yes \
    --json > "$TMP_ROOT/apply.json"

[[ -f "$WORKSPACE/.forge/skills/demo/SKILL.md" ]]
[[ ! -e "$WORKSPACE/.forge/skills/demo/.env.local" ]]
[[ -f "$WORKSPACE/AGENTS.md" ]]
[[ -f "$WORKSPACE/.mcp.json" ]]
grep -F '"API_TOKEN": "${API_TOKEN}"' "$WORKSPACE/.mcp.json" >/dev/null
grep -F '"--token",' "$WORKSPACE/.mcp.json" >/dev/null
grep -F '"${TOKEN}"' "$WORKSPACE/.mcp.json" >/dev/null
grep -F '"Authorization": "Bearer ${env:MCP_TOKEN}"' "$WORKSPACE/.mcp.json" >/dev/null
if grep -E 'literal-(secret|arg-secret|query-secret)|sk-ant-abcdefghijklmnopqrstuvw|user:pass@|nested:password@' "$WORKSPACE/.mcp.json" >/dev/null; then
    echo "FAIL: literal MCP secret reached the target" >&2
    exit 1
fi

bash "$CLI" verify --manifest "$MANIFEST" --json > "$TMP_ROOT/verify.json"
python3 - "$TMP_ROOT/verify.json" <<'PY'
import json
import sys
from pathlib import Path

assert json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["ok"] is True
PY

cp "$WORKSPACE/AGENTS.md" "$TMP_ROOT/agents-before-tamper.md"
printf '%s\n' '# changed after apply' >> "$WORKSPACE/AGENTS.md"
if bash "$CLI" rollback --manifest "$MANIFEST" --yes \
    > "$TMP_ROOT/changed-rollback.log" 2>&1; then
    echo "FAIL: rollback overwrote a target changed after apply" >&2
    exit 1
fi
grep -Fq 'changed after apply' "$TMP_ROOT/changed-rollback.log"
cp "$TMP_ROOT/agents-before-tamper.md" "$WORKSPACE/AGENTS.md"

bash "$CLI" rollback --manifest "$MANIFEST" --yes --json > "$TMP_ROOT/rollback.json"
[[ ! -e "$WORKSPACE/.forge/skills/demo" ]]
[[ ! -e "$WORKSPACE/AGENTS.md" ]]
[[ ! -e "$WORKSPACE/.mcp.json" ]]

mkdir -p \
    "$WORKSPACE/.cline/skills/leaky" \
    "$WORKSPACE/.forge/skills/leaky"
cp "$SKILL_DIR/SKILL.md" "$WORKSPACE/.cline/skills/leaky/SKILL.md"
cp "$SCRIPT_DIR/test-migration-core.sh" \
    "$WORKSPACE/.cline/skills/leaky/payload.sh"
printf '%s\n' 'preserve-existing-target' \
    > "$WORKSPACE/.forge/skills/leaky/sentinel.txt"

HOME="$TEST_HOME" bash "$CLI" plan \
    --workspace "$WORKSPACE" \
    --source cline/ide \
    --target forge/cli \
    --objects skills \
    --scope project \
    --json > "$TMP_ROOT/secret-preflight-plan.json"
python3 - "$TMP_ROOT/secret-preflight-plan.json" <<'PY'
import json
import sys
from pathlib import Path

plan = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert plan["items"][0]["status"] == "blocked"
assert "source credential preflight failed" in plan["items"][0]["reason"]
assert "payload.sh: provider credential pattern" in plan["items"][0]["reason"]
PY

mv "$WORKSPACE/.cline/skills/leaky/payload.sh" \
    "$TMP_ROOT/leaky-payload.sh"
python3 - \
    "$SCRIPT_DIR" \
    "$SKILL_DIR/references/registry-v2.json" \
    "$WORKSPACE" \
    "$TEST_HOME" \
    "$TMP_ROOT/leaky-payload.sh" <<'PY'
import shutil
import sys
from pathlib import Path

sys.path.insert(0, sys.argv[1])
from migration_core import Registry, apply_plan, build_plan

registry = Registry(Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4]))
plan, _ = build_plan(
    registry,
    "cline/ide",
    "forge/cli",
    ["skills"],
    "project",
)
assert plan[0].status == "ready"
shutil.copy2(
    Path(sys.argv[5]),
    Path(sys.argv[3], ".cline/skills/leaky/payload.sh"),
)
try:
    apply_plan(plan, Path(sys.argv[3]))
except ValueError as error:
    assert "source credential preflight failed" in str(error)
else:
    raise AssertionError("apply did not rescan a changed Skill source")
PY

if HOME="$TEST_HOME" bash "$CLI" apply \
    --workspace "$WORKSPACE" \
    --source cline/ide \
    --target forge/cli \
    --objects skills \
    --scope project \
    --yes > "$TMP_ROOT/secret-preflight-apply.log" 2>&1; then
    echo "FAIL: profile-aware apply copied a Skill with a literal credential" >&2
    exit 1
fi
grep -Fq 'preserve-existing-target' \
    "$WORKSPACE/.forge/skills/leaky/sentinel.txt"
[[ ! -e "$WORKSPACE/.forge/skills/leaky/payload.sh" ]]
mv "$WORKSPACE/.cline/skills/leaky" "$TMP_ROOT/leaky-source"
mv "$WORKSPACE/.forge/skills/leaky" "$TMP_ROOT/leaky-target"

mkdir -p \
    "$WORKSPACE/.cline/skills/symlink-race" \
    "$WORKSPACE/.forge/skills/symlink-race"
cp "$SKILL_DIR/SKILL.md" \
    "$WORKSPACE/.cline/skills/symlink-race/SKILL.md"
printf '%s\n' 'safe-before-copy' \
    > "$WORKSPACE/.cline/skills/symlink-race/payload.txt"
printf '%s\n' 'outside-source-boundary' \
    > "$TMP_ROOT/symlink-race-external.txt"
printf '%s\n' 'preserve-symlink-race-target' \
    > "$WORKSPACE/.forge/skills/symlink-race/sentinel.txt"
python3 - \
    "$SCRIPT_DIR" \
    "$SKILL_DIR/references/registry-v2.json" \
    "$WORKSPACE" \
    "$TEST_HOME" \
    "$TMP_ROOT/symlink-race-external.txt" <<'PY'
import shutil
import sys
from pathlib import Path

sys.path.insert(0, sys.argv[1])
from migration_core import Registry, apply_plan, build_plan

workspace = Path(sys.argv[3]).resolve()
source_skill = workspace / ".cline/skills/symlink-race"
payload = source_skill / "payload.txt"
external = Path(sys.argv[5])
registry = Registry(Path(sys.argv[2]), workspace, Path(sys.argv[4]))
plan, _ = build_plan(
    registry,
    "cline/ide",
    "forge/cli",
    ["skills"],
    "project",
)
assert plan[0].status == "ready"
original_copytree = shutil.copytree


def injecting_copytree(src, dst, *args, **kwargs):
    if Path(src) == source_skill:
        payload.unlink()
        payload.symlink_to(external)
    return original_copytree(src, dst, *args, **kwargs)


shutil.copytree = injecting_copytree
try:
    apply_plan(plan, workspace)
except ValueError as error:
    assert "symbolic links are not allowed" in str(error)
else:
    raise AssertionError("apply followed a Skill symlink introduced during copy")
PY
grep -Fq 'preserve-symlink-race-target' \
    "$WORKSPACE/.forge/skills/symlink-race/sentinel.txt"
[[ ! -e "$WORKSPACE/.forge/skills/symlink-race/payload.txt" ]]
mv "$WORKSPACE/.cline/skills/symlink-race" \
    "$TMP_ROOT/symlink-race-source"
mv "$WORKSPACE/.forge/skills/symlink-race" \
    "$TMP_ROOT/symlink-race-target"

mkdir -p "$TMP_ROOT/external-qwen"
ln -s "$TMP_ROOT/external-qwen" "$WORKSPACE/.qwen"
HOME="$TEST_HOME" bash "$CLI" plan \
    --workspace "$WORKSPACE" \
    --source cline/ide \
    --target qwen-code/cli \
    --objects skills \
    --scope project \
    --json > "$TMP_ROOT/symlink-plan.json"
python3 - "$TMP_ROOT/symlink-plan.json" <<'PY'
import json
import sys
from pathlib import Path

plan = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert plan["items"][0]["status"] == "blocked"
assert "symbolic links are not allowed" in plan["items"][0]["reason"]
PY

HOME="$TEST_HOME" bash "$CLI" plan \
    --workspace "$WORKSPACE" \
    --source cline/ide \
    --target firebase-studio/legacy-workspace \
    --objects instructions \
    --scope project \
    --json > "$TMP_ROOT/source-only.json"
python3 - "$TMP_ROOT/source-only.json" <<'PY'
import json
import sys
from pathlib import Path

plan = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert plan["items"][0]["status"] == "blocked"
assert "source-only" in plan["items"][0]["reason"]
PY

HOME="$TEST_HOME" bash "$CLI" --print-path cline mcp \
    | grep -F '~/.cline/data/settings/cline_mcp_settings.json' >/dev/null

python3 - "$SCRIPT_DIR" "$SKILL_DIR/evals/files" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, sys.argv[1])
from migration_core import emit_instruction, parse_instruction

fixtures = Path(sys.argv[2])
source = (fixtures / "instruction-ir-source.mdc").read_text(encoding="utf-8")
golden = (fixtures / "instruction-ir-cursor.golden.mdc").read_text(encoding="utf-8")
instruction = parse_instruction(source, "cursor-mdc")
rendered, loss = emit_instruction(instruction, "cursor-mdc")
assert rendered == golden
assert {item.field for item in loss.items} == {"hierarchy", "imports"}
PY

echo "Migration core test passed"
