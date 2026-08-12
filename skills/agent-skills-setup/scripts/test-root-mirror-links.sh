#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
MIRROR="$REPO_ROOT/SKILL.md"
TEMP_MIRROR="$(mktemp)"
trap 'rm -f "$TEMP_MIRROR"' EXIT
MIRROR_HASH_BEFORE="$(shasum -a 256 "$MIRROR" | awk '{print $1}')"

bash "$REPO_ROOT/scripts/sync-root-mirror.sh" --output "$TEMP_MIRROR"

[[ "$(head -n 1 "$TEMP_MIRROR")" == "<!--" ]] || {
    echo "FAIL: generated root pointer must begin with a generated-file comment" >&2
    exit 1
}

if grep -Eq '^name:|^---$' "$TEMP_MIRROR"; then
    echo "FAIL: root pointer must not look like a publishable Skill" >&2
    exit 1
fi

if ! grep -F '](skills/agent-skills-setup/SKILL.md)' "$TEMP_MIRROR" >/dev/null; then
    echo "FAIL: generated pointer does not link to the canonical Skill" >&2
    exit 1
fi

[[ "$MIRROR_HASH_BEFORE" == "$(shasum -a 256 "$MIRROR" | awk '{print $1}')" ]] || {
    echo "FAIL: pointer test changed the checked-in root file" >&2
    exit 1
}

echo "Root non-Skill pointer test passed"
