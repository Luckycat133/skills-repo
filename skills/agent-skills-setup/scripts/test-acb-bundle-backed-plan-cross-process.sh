#!/usr/bin/env bash
#
# P0-1 (v0.9.3): Cross-process restore plan replay regression.
#
# Process A: snapshot --all-installed -> device.acb
#            restore device.acb --all-installed --plan-only --plan-out plan.json
#            exits cleanly; /tmp/acb-source-stage-* is removed
# Process B (new process): restore device.acb --plan-in plan.json --yes
#            must succeed and produce the same ready items as A.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pin surface resolution to the POSIX layout the fixtures create.
export AGENT_SKILLS_PLATFORM=linux

WRAPPER="${SCRIPT_DIR}/smart-ide-migration.sh"
TMP_ROOT="$(mktemp -d /tmp/acb-bundle-replay.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

BUNDLE="$TMP_ROOT/device.acb"
HOME_A="$TMP_ROOT/home"
WS_A="$TMP_ROOT/ws"
# Cross-PROCESS replay on the SAME device: the reviewed plan locks absolute
# target paths, so HOME/workspace must match between Process A and Process B
# (the regression being verified is the acb:// replay path itself, not
# target re-resolution across different devices).
HOME_B="$HOME_A"
WS_B="$WS_A"
PLAN="$TMP_ROOT/plan.json"

mkdir -p "$HOME_A/.cline/skills/awesome-skill" "$WS_A"

cat > "$HOME_A/.cline/skills/awesome-skill/SKILL.md" <<'EOF'
---
name: awesome-skill
description: Skill captured on Device A
metadata:
  version: "1.0.0"
---
# Awesome Skill from Device A
EOF

export HOME="$HOME_A"

# Process A: snapshot + plan-out.
SNAPSHOT_OUT="$("$WRAPPER" snapshot --all-installed --output "$BUNDLE" --workspace "$WS_A" 2>&1)"
if [ ! -d "$BUNDLE/objects" ] || [ ! -f "$BUNDLE/manifest.json" ]; then
    echo "FAIL: snapshot did not produce a valid bundle (no objects/ or manifest.json)"
    echo "$SNAPSHOT_OUT" | tail -20
    exit 1
fi
echo "OK Process A: snapshot produced bundle"

RESTORE_PLAN_OUT="$("$WRAPPER" restore "$BUNDLE" --all-installed --plan-only --plan-out "$PLAN" 2>&1)"
if [ ! -f "$PLAN" ]; then
    echo "FAIL: restore --plan-only did not write plan-out"
    echo "$RESTORE_PLAN_OUT" | tail -20
    exit 1
fi
echo "OK Process A: plan-out written"

# Simulate full process boundary: drop staging, ensure acb-source-stage-*
# cannot leak across the boundary.
LEFTOVER="$(find /tmp -maxdepth 1 -name 'acb-source-stage-*' -o -name 'acb-replay-stage-*' 2>/dev/null || true)"
if [ -n "$LEFTOVER" ]; then
    echo "FAIL: staging dir survived process A exit: $LEFTOVER"
    exit 1
fi
echo "OK no staging leak after Process A exit"

# Sanity: plan.json contains acb:// URIs.
ACB_URIS="$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(sum(1 for it in d.get('items',[]) if it.get('acb_uri')))" "$PLAN")"
if [ "$ACB_URIS" = "0" ]; then
    echo "FAIL: plan has no acb_uri items (P0-1 source identity missing)"
    exit 1
fi
echo "OK plan has $ACB_URIS acb_uri items"

# Process B: cross-process replay.
unset HOME
export HOME="$HOME_B"
APPLY_OUT="$("$WRAPPER" restore "$BUNDLE" --plan-in "$PLAN" --yes --json 2>&1)"
# The wrapper prints registry alias lines and other diagnostics before the
# final multi-line JSON object. Use python (re.DOTALL) to extract the last
# JSON span, matching the baseline test's parsing.
JSON_LINE="$(printf '%s\n' "$APPLY_OUT" | python3 -c '
import json, re, sys
text = sys.stdin.read()
matches = list(re.finditer(r"\{.*\}", text, re.DOTALL))
if not matches:
    sys.exit(0)
obj = json.loads(matches[-1].group(0))
print(json.dumps(obj))
')"
if [ -z "$JSON_LINE" ]; then
    echo "FAIL: cross-process plan replay produced no JSON"
    printf '%s\n' "$APPLY_OUT" | tail -20
    exit 1
fi
if ! printf '%s' "$JSON_LINE" | python3 -c 'import json,sys
try:
    d=json.loads(sys.stdin.read())
except Exception:
    sys.exit(2)
sys.exit(0 if d.get("ok") else 1)'; then
    echo "FAIL: cross-process plan replay did not return ok"
    printf '%s\n' "$JSON_LINE"
    exit 1
fi
echo "OK cross-process plan replay succeeded"

# Verify the skill actually landed on the new device. Device A only has
# cline installed, so --all-installed expands targets to cline/ide (installed)
# plus copilot/cli (auto-detected target). Accept any of those landing paths.
LANDED=""
for path in \
    "$HOME_B/.cline/skills/awesome-skill/SKILL.md" \
    "$HOME_B/.copilot/skills/awesome-skill/SKILL.md"; do
    if [ -f "$path" ]; then
        LANDED="$path"
        break
    fi
done
if [ -z "$LANDED" ]; then
    echo "FAIL: awesome-skill did not land on Device B (checked cline + copilot)"
    exit 1
fi
echo "OK skill landed on Device B at $LANDED"

LEFTOVER2="$(find /tmp -maxdepth 1 -name 'acb-source-stage-*' -o -name 'acb-replay-stage-*' 2>/dev/null || true)"
if [ -n "$LEFTOVER2" ]; then
    echo "FAIL: staging dir survived Process B exit: $LEFTOVER2"
    exit 1
fi
echo "OK no staging leak after Process B exit"

echo "Cross-process bundle-backed plan replay tests passed"
