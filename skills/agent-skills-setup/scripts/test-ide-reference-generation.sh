#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

python3 "$SCRIPT_DIR/sync-ide-reference-summaries.py" --check \
    --paths "$SKILL_ROOT/references/ide-paths.json" \
    --references "$SKILL_ROOT/references/ides" \
    --resolver "$SCRIPT_DIR/ide-paths.tsv"

if rg -n '[[:blank:]]$' "$SCRIPT_DIR/ide-paths.tsv" >/dev/null; then
    echo "FAIL: generated resolver contains trailing whitespace" >&2
    exit 1
fi

TMP_HOME="$(mktemp -d /tmp/ide-path-resolver-test.XXXXXX)"
trap 'rm -rf "$TMP_HOME"' EXIT
ACTUAL_PATH="$(HOME="$TMP_HOME" bash -c 'source "$1"; get_global_path gemini-cli' _ "$SCRIPT_DIR/smart-ide-migration.sh")"
[[ "$ACTUAL_PATH" == "$TMP_HOME/.gemini/skills" ]] || {
    echo "FAIL: generated resolver did not expand ~/ against HOME" >&2
    exit 1
}

EMPTY_PATH="$(HOME="$TMP_HOME" bash -c 'source "$1"; get_global_path aider' _ "$SCRIPT_DIR/smart-ide-migration.sh")"
[[ -z "$EMPTY_PATH" ]] || {
    echo "FAIL: empty generated resolver path must stay unsupported" >&2
    exit 1
}

echo "IDE reference summary generation test passed"
