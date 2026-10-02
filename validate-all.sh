#!/usr/bin/env bash
set -euo pipefail

# Force CPython UTF-8 mode for every child process. Windows runners
# default to cp1252 for both file reads (skills-ref validator) and
# stdout writes (argparse help text containing non-ASCII arrows), which
# aborts otherwise-passing suites.
export PYTHONUTF8=1

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

python3 - "$SCRIPT_DIR" <<'PY'
import ast
import sys
from pathlib import Path

root = Path(sys.argv[1])
paths = list((root / "scripts").glob("*.py"))
for skill in (root / "skills").iterdir():
    paths.extend((skill / "scripts").rglob("*.py"))
for path in sorted(paths):
    ast.parse(path.read_text(encoding="utf-8"), filename=str(path.relative_to(root)))
print(f"Python syntax checks passed ({len(paths)} files).")
PY

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
    # Legacy lookup tests are unsupported on Windows's MSYS shell.
    WINDOWS_SKIPPED="test-antigravity-migration.sh,test-conflict-strategies.sh,test-copilot-mapping.sh,test-ide-paths.sh,test-smart-ide-migration.sh"
    while IFS= read -r test_script; do
        base="$(basename "$test_script")"
        if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || "$(uname -s)" == CYGWIN* ]] \
            && [[ ","$WINDOWS_SKIPPED"," == *,"$base",* ]]; then
            echo "SKIP (windows): $base — legacy bash engine is unsupported on this host"
            continue
        fi
        echo "Running $base..."
        bash "$test_script"
    done < <(list_focused_tests)
fi
