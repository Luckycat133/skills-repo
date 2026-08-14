#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_ROOT="$(mktemp -d /tmp/agent-skills-default-scope.XXXXXX)"
TEST_HOME="$TMP_ROOT/home"
WORKSPACE="$TMP_ROOT/workspace"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$TEST_HOME" "$WORKSPACE"

DEFAULT_OUTPUT="$(
    cd "$WORKSPACE"
    HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" legacy \
        --source claude --target codex --dry-run 2>&1
)"
if ! grep -Fq 'migration content: skills' <<<"$DEFAULT_OUTPUT"; then
    echo "FAIL: a global migration without --objects must default to skills only" >&2
    exit 1
fi
if grep -Fq 'migration content: skills,rules' <<<"$DEFAULT_OUTPUT"; then
    echo "FAIL: a global migration unexpectedly included project objects" >&2
    exit 1
fi

if (
    cd "$WORKSPACE"
    HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" legacy \
        --source claude --target codex --objects rules --dry-run
) >"$TMP_ROOT/implicit-workspace.log" 2>&1; then
    echo "FAIL: project-backed objects must require an explicit --workspace" >&2
    exit 1
fi
grep -Fq 'explicit --workspace' "$TMP_ROOT/implicit-workspace.log" || {
    echo "FAIL: missing actionable error for an implicit project workspace" >&2
    exit 1
}

HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" legacy \
    --source claude --target codex --workspace "$WORKSPACE" \
    --objects rules --dry-run >/dev/null

echo "Migration default scope test passed"
