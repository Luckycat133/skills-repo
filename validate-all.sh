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

# Validator regression tests (HI-004): pin the SECRET/PRIVATE_PATH regex and
# the per-branch detection so a future regex drift can't let a secret through.
if [[ -f "$SCRIPT_DIR/scripts/test-validate-skills.py" ]]; then
  python3 "$SCRIPT_DIR/scripts/test-validate-skills.py"
fi

# Ensure the repository-root SKILL.md mirror stays in sync with the canonical
# skill copy. Regenerate with: bash scripts/sync-root-mirror.sh
if [[ -f "$SCRIPT_DIR/scripts/sync-root-mirror.sh" ]]; then
  bash "$SCRIPT_DIR/scripts/sync-root-mirror.sh" --check
fi

# Core verification & regression test suites
SETUP_SCRIPTS="$SCRIPT_DIR/skills/agent-skills-setup/scripts"
if [[ -d "$SETUP_SCRIPTS" ]]; then
  echo "Running verify-ide-config.sh..."
  bash "$SETUP_SCRIPTS/verify-ide-config.sh"
  echo "Running test-ide-paths.sh..."
  bash "$SETUP_SCRIPTS/test-ide-paths.sh"
  echo "Running test-migration.sh..."
  bash "$SETUP_SCRIPTS/test-migration.sh"
  echo "Running test-smart-ide-migration.sh..."
  bash "$SETUP_SCRIPTS/test-smart-ide-migration.sh"
  echo "Running test-mcp-secret-redaction.sh..."
  bash "$SETUP_SCRIPTS/test-mcp-secret-redaction.sh"
fi
