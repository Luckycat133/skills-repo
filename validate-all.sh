#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETUP_SCRIPTS="$SCRIPT_DIR/skills/agent-skills-setup/scripts"

list_focused_tests() {
    local test_script
    printf '%s\n' "$SCRIPT_DIR/scripts/test-import-agent-skill.sh"
    printf '%s\n' "$SCRIPT_DIR/scripts/test-runtime-package.sh"
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

bash "$SCRIPT_DIR/scripts/run-official-skill-validator.sh"
python3 "$SCRIPT_DIR/scripts/validate_skills.py"

if [[ -f "$SCRIPT_DIR/scripts/test-validate-skills.py" ]]; then
  python3 "$SCRIPT_DIR/scripts/test-validate-skills.py"
fi

if [[ -f "$SCRIPT_DIR/scripts/sync-root-mirror.sh" ]]; then
  bash "$SCRIPT_DIR/scripts/sync-root-mirror.sh" --check
fi

if [[ -f "$SCRIPT_DIR/scripts/test-validate-all-coverage.sh" ]]; then
  bash "$SCRIPT_DIR/scripts/test-validate-all-coverage.sh"
fi

if [[ -d "$SETUP_SCRIPTS" ]]; then
  while IFS= read -r test_script; do
    echo "Running $(basename "$test_script")..."
    bash "$test_script"
  done < <(list_focused_tests)
fi
