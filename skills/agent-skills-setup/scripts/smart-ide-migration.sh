#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
    exec bash "$SCRIPT_DIR/legacy-smart-ide-migration.sh" "$@"
fi

exec python3 "$SCRIPT_DIR/context-migrator.py" "$@"
