#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETUP_SCRIPTS="$SCRIPT_DIR/skills/agent-skills-setup/scripts"

list_focused_tests() {
    local test_script
    for test_script in "$SETUP_SCRIPTS"/test-*.sh; do
        [[ -f "$test_script" ]] || continue
        printf '%s\n' "$test_script"
    done
}

case "${1:-}" in
    --list-tests)
        list_focused_tests
        exit 0
        ;;
    "")
        ;;
    *)
        echo "Unknown argument: $1" >&2
        exit 2
        ;;
esac

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

# Keep the validation entry point honest: every focused test colocated with
# the Skill must be discoverable through --list-tests and executed below.
if [[ -f "$SCRIPT_DIR/scripts/test-validate-all-coverage.sh" ]]; then
  bash "$SCRIPT_DIR/scripts/test-validate-all-coverage.sh"
fi

# Registry verification plus every focused regression test. Test discovery is
# deliberate here so adding test-<feature>.sh automatically extends local/CI
# validation instead of requiring a second hand-maintained list.
if [[ -d "$SETUP_SCRIPTS" ]]; then
  echo "Running verify-ide-config.sh..."
  bash "$SETUP_SCRIPTS/verify-ide-config.sh"
  while IFS= read -r test_script; do
    echo "Running $(basename "$test_script")..."
    bash "$test_script"
  done < <(list_focused_tests)
fi
