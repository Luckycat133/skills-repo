#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

python3 "$SCRIPT_DIR/sync-ide-reference-summaries.py" --check \
    --paths "$SKILL_ROOT/references/ide-paths.json" \
    --references "$SKILL_ROOT/references/ides"

echo "IDE reference summary generation test passed"
