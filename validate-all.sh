#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for script in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/scripts/*.sh; do
  [[ -f "$script" ]] || continue
  bash -n "$script"
done

python3 "$SCRIPT_DIR/scripts/validate_skills.py"
