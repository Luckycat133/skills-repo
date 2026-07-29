#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETUP_SCRIPTS="$REPO_ROOT/skills/agent-skills-setup/scripts"
EXPECTED_FILE="$(mktemp /tmp/validate-all-expected.XXXXXX)"
ACTUAL_FILE="$(mktemp /tmp/validate-all-actual.XXXXXX)"
trap 'rm -f "$EXPECTED_FILE" "$ACTUAL_FILE"' EXIT

find "$SETUP_SCRIPTS" -maxdepth 1 -type f -name 'test-*.sh' -exec basename {} \; \
    | LC_ALL=C sort > "$EXPECTED_FILE"

bash "$REPO_ROOT/validate-all.sh" --list-tests \
    | sed 's#^.*/##' \
    | LC_ALL=C sort > "$ACTUAL_FILE"

if ! diff -u "$EXPECTED_FILE" "$ACTUAL_FILE"; then
    echo "FAIL: validate-all.sh does not enumerate every focused test" >&2
    exit 1
fi

echo "PASS: validate-all.sh enumerates every focused test"
