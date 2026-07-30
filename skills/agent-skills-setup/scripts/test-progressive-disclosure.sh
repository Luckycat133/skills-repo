#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_FILE="$SKILL_ROOT/SKILL.md"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

[[ $(wc -l < "$SKILL_FILE") -le 150 ]] || \
    fail "SKILL.md must keep its always-loaded workflow to 150 lines or fewer"

for reference in \
    references/migration-safety.md \
    references/mcp-migration.md \
    references/object-migration.md \
    references/verification.md; do
    [[ -f "$SKILL_ROOT/$reference" ]] || \
        fail "missing progressively loaded reference: $reference"
    rg -F "$reference" "$SKILL_FILE" >/dev/null || \
        fail "SKILL.md does not state when to load $reference"
done

rg -F 'references/ides/<source>.md' "$SKILL_FILE" >/dev/null || \
    fail "SKILL.md must route source reads to one IDE reference"
rg -F 'references/ides/<target>.md' "$SKILL_FILE" >/dev/null || \
    fail "SKILL.md must route target reads to one IDE reference"
rg -F -- '--dry-run' "$SKILL_FILE" >/dev/null || \
    fail "SKILL.md must retain the preview gate"
rg -F -- '--yes' "$SKILL_FILE" >/dev/null || \
    fail "SKILL.md must retain the explicit approval gate"

echo "Progressive disclosure test passed"
