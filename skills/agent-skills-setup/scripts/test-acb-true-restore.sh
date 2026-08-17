#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="${SCRIPT_DIR}/smart-ide-migration.sh"

TMP_ROOT="$(mktemp -d /tmp/acb-true-restore.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

BUNDLE="$TMP_ROOT/device-a.acb"
HOME_A="$TMP_ROOT/home_device_a"
WS_A="$TMP_ROOT/ws_device_a"

HOME_B="$TMP_ROOT/home_device_b"
WS_B="$TMP_ROOT/ws_device_b"

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

# Note: On Device B, .cline does NOT exist! (Clean new device)
[[ ! -e "$HOME_B/.cline" ]] || { echo "FAIL: .cline should not exist on Device B"; exit 1; }

# 2. Restore on Device B (where cline is NOT installed) into forge/cli
HOME="$HOME_B" "$WRAPPER" restore \
    "$BUNDLE" \
    --workspace "$WS_B" \
    --source cline/ide --target forge/cli \
    --scope user \
    --apply-safe \
    --yes \
    --json >"$TMP_ROOT/restore.json"

echo "OK Device B restore command finished"

# Verify that forge/skills/awesome-skill/SKILL.md was created on Device B
TARGET_SKILL="$HOME_B/forge/skills/awesome-skill/SKILL.md"
[[ -f "$TARGET_SKILL" ]] || {
    echo "FAIL: true restore failed to write target skill to $TARGET_SKILL"
    exit 1
}

grep -Fq "Awesome Skill from Device A" "$TARGET_SKILL" || {
    echo "FAIL: content mismatch in restored target skill"
    exit 1
}

echo "OK true bundle restore successfully migrated source from bundle into target IDE on clean destination"
echo
echo "True restore tests passed"
