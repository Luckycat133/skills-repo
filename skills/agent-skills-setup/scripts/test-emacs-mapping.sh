#!/usr/bin/env bash

# Focused Emacs boundary test. Emacs itself has init files and directory-local
# variables, but no native skills/rules/MCP/config migration schema. All of
# those mappings must therefore be empty and fail closed in the generic tool.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_SCRIPT="$SCRIPT_DIR/smart-ide-migration.sh"

for object in global project project-skills rules mcp project-mcp project-config config; do
    if bash "$MIGRATION_SCRIPT" --print-path emacs "$object" >/dev/null 2>&1; then
        echo "FAIL: emacs/$object must be unsupported/manual" >&2
        exit 1
    fi
done

TMP_ROOT="$(mktemp -d /tmp/emacs-mapping-test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

if ! output=$(bash "$MIGRATION_SCRIPT" \
    --source codex --target emacs --workspace "$TMP_ROOT" \
    --objects skills,rules,mcp,config,project --dry-run 2>&1); then
    echo "FAIL: Emacs dry-run boundary exited non-zero" >&2
    exit 1
fi

grep -Fq 'target IDE has no global skills directory' <<<"$output"
grep -Fq 'target IDE does not support rules files' <<<"$output"
grep -Fq 'target IDE does not support MCP configuration' <<<"$output"
grep -Fq 'target IDE has no specific config file' <<<"$output"
grep -Fq 'target IDE does not support project-level configuration' <<<"$output"

echo "Emacs mapping boundary test passed"
