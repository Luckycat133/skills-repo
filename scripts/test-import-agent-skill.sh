#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_ROOT="$(mktemp -d /tmp/agent-skill-import.XXXXXX)"
FAKE_REPO="$TMP_ROOT/repo"
SOURCE_SKILL="$TMP_ROOT/source"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$FAKE_REPO/scripts" "$SOURCE_SKILL"
cp "$SCRIPT_DIR/import-agent-skill.sh" "$FAKE_REPO/scripts/import-agent-skill.sh"
cp "$SCRIPT_DIR/skill_package.py" "$SCRIPT_DIR/validate_skills.py" "$FAKE_REPO/scripts/"
mkdir -p "$FAKE_REPO/skills/agent-skills-setup/scripts"
cp "$SCRIPT_DIR/../skills/agent-skills-setup/scripts/skill_secret_scanner.py" \
    "$FAKE_REPO/skills/agent-skills-setup/scripts/"
printf '%s\n' '---' 'name: demo' 'description: Test fixture.' '---' > "$SOURCE_SKILL/SKILL.md"

if bash "$FAKE_REPO/scripts/import-agent-skill.sh" "$SOURCE_SKILL" ../escaped \
    >"$TMP_ROOT/invalid-name.log" 2>&1; then
    echo "FAIL: import accepted a skill name that escapes the skills directory" >&2
    exit 1
fi
[[ ! -e "$FAKE_REPO/escaped" ]] || {
    echo "FAIL: import wrote outside the skills directory" >&2
    exit 1
}

mkdir -p "$TMP_ROOT/not-a-skill"
if bash "$FAKE_REPO/scripts/import-agent-skill.sh" "$TMP_ROOT/not-a-skill" demo \
    >"$TMP_ROOT/missing-skill.log" 2>&1; then
    echo "FAIL: import accepted a directory without SKILL.md" >&2
    exit 1
fi

bash "$FAKE_REPO/scripts/import-agent-skill.sh" "$SOURCE_SKILL" demo >/dev/null
[[ -f "$FAKE_REPO/skills/demo/SKILL.md" ]] || {
    echo "FAIL: valid Skill was not imported" >&2
    exit 1
}

# Replacement must remove obsolete entries while retaining all source files.
printf '%s\n' 'obsolete' > "$FAKE_REPO/skills/demo/obsolete.txt"
mkdir -p "$SOURCE_SKILL/references" "$SOURCE_SKILL/scripts/__pycache__"
printf '%s\n' 'retained source' > "$SOURCE_SKILL/references/source.txt"
printf '%s\n' 'ignored cache' > "$SOURCE_SKILL/scripts/__pycache__/module.pyc"
printf '%s\n' 'API_KEY=your_api_key_placeholder' > "$SOURCE_SKILL/.env.example"
printf '%s\n' 'configuration fixture' > "$SOURCE_SKILL/.environment-profile"
printf '%s\n' '[configuration](../.environment-profile)' > "$SOURCE_SKILL/references/environment.md"
bash "$FAKE_REPO/scripts/import-agent-skill.sh" "$SOURCE_SKILL" demo >/dev/null
[[ ! -e "$FAKE_REPO/skills/demo/obsolete.txt" ]]
[[ -f "$FAKE_REPO/skills/demo/references/source.txt" ]]
[[ ! -e "$FAKE_REPO/skills/demo/scripts/__pycache__" ]]
[[ ! -e "$FAKE_REPO/skills/demo/.env.example" ]]
[[ -f "$SOURCE_SKILL/.env.example" ]]
[[ -f "$FAKE_REPO/skills/demo/.environment-profile" ]]
[[ -f "$FAKE_REPO/skills/demo/references/environment.md" ]]

printf '%s\n' 'existing destination must survive failures' > "$FAKE_REPO/skills/demo/sentinel.txt"
cp "$FAKE_REPO/skills/demo/SKILL.md" "$TMP_ROOT/original-skill.md"
for source in "$FAKE_REPO/skills/demo" "$FAKE_REPO/skills/demo/nested"; do
    if [[ "$source" == */nested ]]; then
        mkdir -p "$source"
        cp "$TMP_ROOT/original-skill.md" "$source/SKILL.md"
    fi
    if bash "$FAKE_REPO/scripts/import-agent-skill.sh" "$source" demo >"$TMP_ROOT/overlap.log" 2>&1; then
        echo "FAIL: import accepted overlapping source and destination trees" >&2
        exit 1
    fi
    cmp "$TMP_ROOT/original-skill.md" "$FAKE_REPO/skills/demo/SKILL.md"
    [[ -f "$FAKE_REPO/skills/demo/sentinel.txt" ]]
done

printf '%s\n' '---' 'name: demo' 'description: ' '---' > "$SOURCE_SKILL/SKILL.md"
if bash "$FAKE_REPO/scripts/import-agent-skill.sh" "$SOURCE_SKILL" demo >"$TMP_ROOT/invalid-skill.log" 2>&1; then
    echo "FAIL: import accepted invalid source metadata" >&2
    exit 1
fi
cmp "$TMP_ROOT/original-skill.md" "$FAKE_REPO/skills/demo/SKILL.md"
[[ -f "$FAKE_REPO/skills/demo/sentinel.txt" ]]

cp "$TMP_ROOT/original-skill.md" "$SOURCE_SKILL/SKILL.md"
printf '%s\n' 'PASSWORD=literalCredential123456' > "$SOURCE_SKILL/.env"
if bash "$FAKE_REPO/scripts/import-agent-skill.sh" "$SOURCE_SKILL" demo >"$TMP_ROOT/dotenv.log" 2>&1; then
    echo "FAIL: import accepted literal credentials in the source dotenv file" >&2
    exit 1
fi
cmp "$TMP_ROOT/original-skill.md" "$FAKE_REPO/skills/demo/SKILL.md"
[[ -f "$FAKE_REPO/skills/demo/sentinel.txt" ]]

# Inject failure at the final rename, after the old destination was moved.
# The original tree must be restored and the staging tree remain recoverable.
python3 - "$FAKE_REPO/scripts" "$TMP_ROOT" <<'PY'
import os
from pathlib import Path
import sys
from unittest.mock import patch

sys.path.insert(0, sys.argv[1])
import skill_package

root = Path(sys.argv[2])
destination = root / "transaction-target"
staging = root / "transaction-staging"
destination.mkdir()
staging.mkdir()
(destination / "sentinel").write_text("original", encoding="utf-8")
(staging / "new").write_text("replacement", encoding="utf-8")
original_replace = os.replace

def fail_commit(source, target):
    if Path(source) == staging:
        raise OSError("injected commit failure")
    original_replace(source, target)

with patch.object(skill_package.os, "replace", side_effect=fail_commit):
    try:
        skill_package.install_staging(staging, destination, replace=True)
    except OSError:
        pass
    else:
        raise SystemExit("FAIL: injected commit failure was ignored")
assert (destination / "sentinel").read_text(encoding="utf-8") == "original"
assert not (destination / "new").exists()
assert not list(root.glob(".transaction-target.backup-*"))

ancestor = root / "linked-ancestor"
try:
    ancestor.symlink_to(root, target_is_directory=True)
except (OSError, NotImplementedError):
    print("SKIP: host cannot create symbolic links")
else:
    original = root / "source"
    for source, target in (
        (original, ancestor / "new-parent/demo"),
        (ancestor / "source", root / "new-parent/demo"),
    ):
        try:
            skill_package.checked_paths(source, target, replace=True)
        except ValueError as error:
            assert "symbolic link" in str(error)
        else:
            raise SystemExit("FAIL: packaging accepted a symbolic ancestor")
PY

echo "Skill import test passed"
