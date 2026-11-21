#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

export PYTHONUTF8=1
export PYTHONDONTWRITEBYTECODE=1
python_bin="${PYTHON:-python3}"

"$python_bin" -B -m unittest discover -s tests -p "test_*.py" -v
"$python_bin" -B skills/agent-skills-setup/scripts/migrate_context.py --help >/dev/null

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
"$python_bin" -B scripts/package_skill.py --output "$tmp_dir/agent-skills-setup.zip" >/dev/null

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
  echo "ERROR: skills-ref is required in CI" >&2
  exit 1
else
  echo "NOTE: skills-ref not installed locally; CI runs REQUIRE_SKILLS_REF=1." >&2
fi
