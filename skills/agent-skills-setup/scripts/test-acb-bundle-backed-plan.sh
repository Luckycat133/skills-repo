#!/usr/bin/env bash
#
# Audit #1 / #4 regression tests:
#   #1  The reviewed plan document (--plan-out) must be backed by the SAME
#       source that produces the executed items. On a clean device the local
#       registry resolves nothing, so the plan must be rebuilt from the bundle;
#       its ready-item count must equal the number of items actually applied.
#   #4  Object extraction into .acb-restored is OPT-IN (--restore-root); when
#       omitted, nothing is written there, and we never imply a transaction
#       landed there.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="${SCRIPT_DIR}/smart-ide-migration.sh"

TMP_ROOT="$(mktemp -d /tmp/acb-bundle-backed.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

BUNDLE="$TMP_ROOT/device-a.acb"
HOME_A="$TMP_ROOT/home_device_a"
WS_A="$TMP_ROOT/ws_device_a"
HOME_B="$TMP_ROOT/home_device_b"
WS_B="$TMP_ROOT/ws_device_b"
PLAN="$TMP_ROOT/restore-plan.json"

mkdir -p "$HOME_A/.cline/skills/awesome-skill" "$WS_A"
mkdir -p "$HOME_B" "$WS_B"

cat > "$HOME_A/.cline/skills/awesome-skill/SKILL.md" <<'EOF'
---
name: awesome-skill
description: Skill captured on Device A
metadata:
  version: "1.0.0"
---
# Awesome Skill from Device A
EOF

# 1. Snapshot on Device A
HOME="$HOME_A" "$WRAPPER" snapshot \
    --workspace "$WS_A" \
    --source cline/ide --target forge/cli \
    --scope user \
    --output "$BUNDLE" \
    --json >/dev/null
echo "OK Device A snapshot generated"

# 2. Restore on clean Device B with a reviewed plan, but WITHOUT --restore-root.
HOME="$HOME_B" "$WRAPPER" restore \
    "$BUNDLE" \
    --workspace "$WS_B" \
    --source cline/ide --target forge/cli \
    --scope user \
    --plan-out "$PLAN" \
    --apply-safe \
    --yes \
    --json >"$TMP_ROOT/restore.json"

# Extract the JSON object from the (possibly noisy) output.
RESTORE_JSON="$(python3 - "$TMP_ROOT/restore.json" <<'PY'
import json, re, sys
text = open(sys.argv[1]).read()
obj = json.loads(re.search(r'\{.*\}', text, re.DOTALL).group(0))
print(json.dumps(obj))
PY
)"

echo "$RESTORE_JSON" | python3 -c "
import json, sys
out = json.load(sys.stdin)
assert out['ok'] is True, out
assert out['stage'] == 'verify', out
print('OK restore reported ok, stage=verify')
"

# 3. #1: reviewed plan == executed plan.
python3 - "$PLAN" "$RESTORE_JSON" <<'PY'
import json, sys
plan = json.load(open(sys.argv[1]))
restore = json.loads(sys.argv[2])

plan_ready = [it for it in plan.get('items', []) if it.get('status') == 'ready']
applied = restore.get('summary', {}).get('applied', 0)

assert plan_ready, f"reviewed plan has no ready items: {plan.get('items')}"
assert len(plan_ready) == applied, (
    f"reviewed plan ready count ({len(plan_ready)}) != applied ({applied}); "
    "reviewed plan diverged from executed plan"
)
print(f"OK #1 reviewed plan ready items ({len(plan_ready)}) == applied ({applied})")
PY

# 4. The target skill actually landed.
TARGET_SKILL="$HOME_B/forge/skills/awesome-skill/SKILL.md"
[[ -f "$TARGET_SKILL" ]] || { echo "FAIL: skill did not land on Device B"; exit 1; }
echo "OK restored skill landed on clean Device B"

# 5. #4: NO .acb-restored was written (extraction is opt-in).
if [[ -e "$WS_B/.acb-restored" ]]; then
    echo "FAIL #4: .acb-restored was created without --restore-root"
    exit 1
fi
echo "OK #4 no .acb-restored created without --restore-root (opt-in)"

# 6. #4: WITH --restore-root, extraction does happen.
HOME="$HOME_B" "$WRAPPER" restore \
    "$BUNDLE" \
    --workspace "$WS_B" \
    --source cline/ide --target forge/cli \
    --scope user \
    --restore-root "$WS_B/.acb-restored" \
    --apply-safe \
    --yes \
    --json >/dev/null
if [[ ! -d "$WS_B/.acb-restored" ]]; then
    echo "FAIL #4: .acb-restored not created even with --restore-root"
    exit 1
fi
echo "OK #4 --restore-root opts in to object extraction"

echo
echo "ACB bundle-backed plan + opt-in extraction tests passed"
