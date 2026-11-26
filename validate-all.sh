#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

export PYTHONUTF8=1
export PYTHONDONTWRITEBYTECODE=1

find_python311() {
  if [[ -n "${PYTHON:-}" ]]; then
    echo "$PYTHON"
    return 0
  fi
  local candidate
  for candidate in python3 python3.13 python3.12 python3.11 \
    /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3.11 \
    /usr/local/bin/python3.13 /usr/local/bin/python3.12 /usr/local/bin/python3.11 \
    "$HOME/.local/bin/python3.13" "$HOME/.local/bin/python3.12" "$HOME/.local/bin/python3.11"; do
    if command -v "$candidate" >/dev/null 2>&1; then
      if "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)' >/dev/null 2>&1; then
        echo "$candidate"
        return 0
      fi
    fi
  done
  return 1
}

if python_bin="$(find_python311)"; then
  run_py() { "$python_bin" -B "$@"; }
elif command -v uv >/dev/null 2>&1; then
  run_py() { uv run --no-project --python '>=3.11' python -B "$@"; }
else
  echo "ERROR: Python 3.11+ or uv is required (tomllib support)." >&2
  exit 1
fi

run_py -m unittest discover -s tests -p "test_*.py" -v
run_py skills/agent-skills-setup/scripts/migrate_context.py --help >/dev/null

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
run_py scripts/package_skill.py --output "$tmp_dir/agent-skills-setup.zip" >/dev/null

skills_ref_bin=""
if command -v skills-ref >/dev/null 2>&1; then
  skills_ref_bin="skills-ref"
elif [[ -x "/tmp/skills-ref-venv/bin/skills-ref" ]]; then
  skills_ref_bin="/tmp/skills-ref-venv/bin/skills-ref"
fi

if [[ -n "$skills_ref_bin" ]]; then
  "$skills_ref_bin" validate skills/agent-skills-setup
  "$skills_ref_bin" validate dev/skills/maintain-agent-skills-setup
elif [[ "${REQUIRE_SKILLS_REF:-0}" == "1" ]]; then
  echo "ERROR: skills-ref is required when REQUIRE_SKILLS_REF=1" >&2
  exit 1
fi
