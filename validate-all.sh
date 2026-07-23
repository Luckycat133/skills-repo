#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

shopt -s nullglob
for script in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/scripts/*.sh "$SCRIPT_DIR"/skills/*/scripts/*.sh; do
  [[ -f "$script" ]] || continue
  bash -n "$script"
done
shopt -u nullglob

python3 "$SCRIPT_DIR/scripts/validate_skills.py"

# Ensure the repository-root SKILL.md mirror stays in sync with the canonical
# skill copy. Regenerate with: bash scripts/sync-root-mirror.sh
if [[ -f "$SCRIPT_DIR/scripts/sync-root-mirror.sh" ]]; then
  bash "$SCRIPT_DIR/scripts/sync-root-mirror.sh" --check
fi
