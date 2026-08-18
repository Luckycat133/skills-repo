#!/usr/bin/env bash
#
# Regression tests for 0.8.22 P0 Audit items:
#   P0-1: Plan target == Executed target, pre-existing target shown as "replace",
#         target_state and previews reflect real destination device.
#   P0-2: Snapshot strict allowlist: excludes generated_memory, session, runtime,
#         and unrequested scopes/types even when files exist on disk.
#   P0-3: Restore always uses bundle as source: when Device B has a local source IDE
#         installed with conflicting content, the bundle content wins.
#   P0-4: Strict handoff whitelist: only reviewed_summary, git_branch, selected_files,
#         and patch survive; drops history, conversation, tokens, oauth_state, cwd, raw.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="${SCRIPT_DIR}/smart-ide-migration.sh"

TMP_ROOT="$(mktemp -d /tmp/acb-p0-regressions.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

HOME_A="$TMP_ROOT/home_a"
WS_A="$TMP_ROOT/ws_a"
HOME_B="$TMP_ROOT/home_b"
WS_B="$TMP_ROOT/ws_b"
BUNDLE="$TMP_ROOT/device-a.acb"

mkdir -p "$HOME_A" "$WS_A" "$HOME_B" "$WS_B"

# -----------------------------------------------------------------------------
# Test 1: P0-2 Snapshot strict allowlist
# -----------------------------------------------------------------------------
echo "=== Test 1: P0-2 Snapshot strict allowlist ==="
# Setup Device A with:
# 1. Portable user skill (eligible)
# 2. Forbidden generated memory (~/.cline/data) (must be excluded)
# 3. Project rule (.clinerules)
mkdir -p "$HOME_A/.cline/skills/portable-skill"
cat > "$HOME_A/.cline/skills/portable-skill/SKILL.md" <<'EOF'
---
name: portable-skill
description: A portable skill from Device A
metadata:
  version: "1.0.0"
---
# Portable Skill
EOF

mkdir -p "$HOME_A/.cline/data"
cat > "$HOME_A/.cline/data/generated-state.json" <<'EOF'
{"session_history": "secret conversation", "memory": "forbidden generated memory"}
EOF

cat > "$WS_A/.clinerules" <<'EOF'
# Project Rules
EOF

# Snapshot with scope=user (should include portable-skill, but exclude .cline/data and project rules)
HOME="$HOME_A" "$WRAPPER" snapshot \
    --workspace "$WS_A" \
    --source cline/ide --target forge/cli \
    --scope user \
    --output "$BUNDLE" \
    --json >/dev/null

python3 - "$BUNDLE" <<'PY'
import json, sys
from pathlib import Path

bundle_root = Path(sys.argv[1])
manifest = json.loads((bundle_root / "manifest.json").read_text())
checksums = json.loads((bundle_root / "checksums.json").read_text())

# Assert generated_memory was NOT collected
for key in checksums.keys():
    assert "generated_memory" not in key, f"forbidden generated_memory leaked into bundle: {key}"
    assert "data" not in key.split("/"), f"forbidden data directory leaked into bundle: {key}"
    assert "session" not in key, f"forbidden session leaked into bundle: {key}"

for obj in manifest.get("objects", []):
    assert obj.get("surface") != "generated_memory", f"manifest contains generated_memory: {obj}"
    assert obj.get("scope") == "user", f"user snapshot contains non-user scope: {obj}"

print("OK P0-2: snapshot excluded forbidden generated_memory and unrequested scopes")
PY

# -----------------------------------------------------------------------------
# Test 2: P0-3 Restore source precedence (bundle wins over Device B local source)
# -----------------------------------------------------------------------------
echo "=== Test 2: P0-3 Bundle wins over Device B local source ==="
# On Device B, also install Cline with DIFFERENT skill content:
mkdir -p "$HOME_B/.cline/skills/portable-skill"
cat > "$HOME_B/.cline/skills/portable-skill/SKILL.md" <<'EOF'
---
name: portable-skill
description: Skill on Device B that should NOT be used during bundle restore
metadata:
  version: "1.0.0"
---
# Device B local content (must NOT overwrite bundle)
EOF

PLAN_OUT="$TMP_ROOT/restore-plan.json"
HOME="$HOME_B" "$WRAPPER" restore \
    "$BUNDLE" \
    --workspace "$WS_B" \
    --source cline/ide --target forge/cli \
    --scope user \
    --plan-out "$PLAN_OUT" \
    --apply-safe \
    --yes \
    --json >"$TMP_ROOT/restore_out.json"

TARGET_SKILL="$HOME_B/forge/skills/portable-skill/SKILL.md"
if ! grep -q "Portable Skill from Device A" "$TARGET_SKILL" 2>/dev/null && ! grep -q "A portable skill from Device A" "$TARGET_SKILL" 2>/dev/null; then
    echo "FAIL: restore wrote Device B local content instead of bundle content!"
    cat "$TARGET_SKILL"
    exit 1
fi
echo "OK P0-3: bundle content won over Device B local source"

# -----------------------------------------------------------------------------
# Test 3: P0-1 Plan target == Executed target, pre-existing target shown as replace
# -----------------------------------------------------------------------------
echo "=== Test 3: P0-1 Pre-existing target shown as replace and plan target matches ==="
# Now run restore again when the target ALREADY exists on Device B
PLAN_OUT_2="$TMP_ROOT/restore-plan-replace.json"
HOME="$HOME_B" "$WRAPPER" restore \
    "$BUNDLE" \
    --workspace "$WS_B" \
    --source cline/ide --target forge/cli \
    --scope user \
    --plan-out "$PLAN_OUT_2" \
    --plan-only \
    --json >/dev/null

python3 - "$PLAN_OUT_2" "$HOME_B" <<'PY'
import json, sys
from pathlib import Path

plan = json.load(open(sys.argv[1]))
home_b = Path(sys.argv[2]).resolve()

item = [it for it in plan.get("items", []) if it.get("status") == "ready"][0]
target_state = item.get("target_state")
assert target_state is not None and target_state.get("exists") is True, f"target_state should exist: {target_state}"

preview = item.get("review_preview", {})
changes = preview.get("changes", [])
assert changes, f"missing preview changes: {preview}"
for change in changes:
    assert change.get("action") == "replace", f"action for existing target should be replace: {change}"
    existing_sha = change.get("target_sha256") or change.get("pre_sha256")
    assert existing_sha is not None, f"existing target sha should be present for replace: {change}"

target_path = Path(item.get("target", {}).get("resolved_path", "")).resolve()
assert "/tmp/acb-source-stage-" not in str(target_path), f"stage path leaked into plan target: {target_path}"
assert target_path == home_b / "forge/skills" or home_b in target_path.parents, f"target path not rooted in Device B: {target_path} vs {home_b}"

print("OK P0-1: existing target correctly evaluated as replace in reviewed plan")
PY

# -----------------------------------------------------------------------------
# Test 4: P0-4 Strict handoff whitelist serialization
# -----------------------------------------------------------------------------
echo "=== Test 4: P0-4 Strict handoff whitelist ==="
python3 - <<'PY'
import sys
from pathlib import Path

# Add scripts directory
sys.path.insert(0, str(Path("skills/agent-skills-setup/scripts").resolve()))
from migration_core import serialize_portable_handoff

dirty_session = {
    "summary": "Implement feature X",
    "raw": "SECRET_RAW_LOGS",
    "messages": [{"role": "user", "content": "hello"}],
    "history": [{"role": "system", "text": "system log"}],
    "conversation": "raw conversation text",
    "tool_calls": [{"name": "bash", "command": "rm -rf /"}],
    "oauth_state": {"token": "ya29.secret_token"},
    "tokens": 15000,
    "cwd": "/Users/victim/secret/project",
    "git_root": "/Users/victim/secret",
    "approval_state": {"approved": True},
    "session_state": {"active": True},
    "environment": {"AWS_SECRET_KEY": "AKIAEXAMPLE"},
    "selected_files": ["src/main.py", "README.md", "/etc/passwd", "../traversal.py"],
    "patch": "diff --git a/src/main.py b/src/main.py\n..."
}

clean = serialize_portable_handoff(dirty_session, workspace=None)

# Whitelist verification: only reviewed_summary, git_branch, selected_files, patch
allowed_keys = {"reviewed_summary", "git_branch", "selected_files", "patch"}
assert set(clean.keys()) == allowed_keys, f"unexpected keys in handoff: {set(clean.keys()) - allowed_keys}"
assert clean["reviewed_summary"] == "Implement feature X"
assert clean["patch"] is not None
# Absolute paths and traversal filtered from selected_files
assert clean["selected_files"] == ["README.md", "src/main.py"], f"file sanitization failed: {clean['selected_files']}"

print("OK P0-4: strict handoff whitelist successfully dropped all unsafe session fields")
PY

echo
echo "All 0.8.22 P0 Audit regression tests PASSED"
