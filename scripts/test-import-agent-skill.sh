#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_ROOT="$(mktemp -d /tmp/agent-skill-import.XXXXXX)"
FAKE_REPO="$TMP_ROOT/repo"
SOURCE_SKILL="$TMP_ROOT/source"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$FAKE_REPO/scripts" "$SOURCE_SKILL"
cp "$SCRIPT_DIR/import-agent-skill.sh" "$FAKE_REPO/scripts/import-agent-skill.sh"
printf '%s\n' '---' 'name: demo' 'description: Test fixture.' '---' > "$SOURCE_SKILL/SKILL.md"

if bash "$FAKE_REPO/scripts/import-agent-skill.sh" "$SOURCE_SKILL" ../escaped \
    >"$TMP_ROOT/invalid-name.log" 2>&1; then
    echo "FAIL: import accepted a skill name that escapes the skills directory" >&2
    exit 1
fi
[[ ! -e "$FAKE_REPO/escaped" ]] || {
    echo "FAIL: import wrote outside the skills directory" >&2
    exit 1
}

mkdir -p "$TMP_ROOT/not-a-skill"
if bash "$FAKE_REPO/scripts/import-agent-skill.sh" "$TMP_ROOT/not-a-skill" demo \
    >"$TMP_ROOT/missing-skill.log" 2>&1; then
    echo "FAIL: import accepted a directory without SKILL.md" >&2
    exit 1
fi

bash "$FAKE_REPO/scripts/import-agent-skill.sh" "$SOURCE_SKILL" demo >/dev/null
[[ -f "$FAKE_REPO/skills/demo/SKILL.md" ]] || {
    echo "FAIL: valid Skill was not imported" >&2
    exit 1
}

echo "Skill import test passed"
