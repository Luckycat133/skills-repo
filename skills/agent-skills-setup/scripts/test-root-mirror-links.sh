#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
MIRROR="$REPO_ROOT/SKILL.md"
TEMP_MIRROR="$(mktemp)"
trap 'rm -f "$TEMP_MIRROR"' EXIT
MIRROR_HASH_BEFORE="$(shasum -a 256 "$MIRROR" | awk '{print $1}')"

bash "$REPO_ROOT/scripts/sync-root-mirror.sh" --output "$TEMP_MIRROR"

if ! rg -F '](skills/agent-skills-setup/references/ides/)' "$TEMP_MIRROR" >/dev/null; then
    echo "FAIL: generated mirror does not rewrite nested IDE-reference links" >&2
    exit 1
fi

[[ "$MIRROR_HASH_BEFORE" == "$(shasum -a 256 "$MIRROR" | awk '{print $1}')" ]] || {
    echo "FAIL: nested-link test changed the checked-in root mirror" >&2
    exit 1
}

echo "Root mirror nested-link test passed"
