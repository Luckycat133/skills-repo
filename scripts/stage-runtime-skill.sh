#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 3 ]] || {
    echo "Usage: stage-runtime-skill.sh SOURCE_SKILL_DIR PACKAGE_DIR VERSION" >&2
    exit 2
}

SOURCE_SKILL_DIR="$1"
PACKAGE_DIR="$2"
VERSION="$3"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SKILL_DIR_ABS="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$SOURCE_SKILL_DIR")"
PACKAGE_DIR_ABS="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$PACKAGE_DIR")"

[[ -f "$SOURCE_SKILL_DIR/SKILL.md" ]] || {
    echo "ERROR: missing $SOURCE_SKILL_DIR/SKILL.md" >&2
    exit 1
}
[[ ! -e "$PACKAGE_DIR" ]] || {
    echo "ERROR: package directory already exists: $PACKAGE_DIR" >&2
    exit 1
}
case "$PACKAGE_DIR_ABS/" in
    "$SOURCE_SKILL_DIR_ABS/"*)
        echo "ERROR: package directory must be outside the source Skill: $PACKAGE_DIR" >&2
        exit 1
        ;;
esac

mkdir -p "$PACKAGE_DIR"
python3 "$SCRIPT_DIR/build-clawhub-skill.py" \
    "$SOURCE_SKILL_DIR/SKILL.md" "$PACKAGE_DIR/SKILL.md" --version "$VERSION"
[[ -f "$SOURCE_SKILL_DIR/assets/LICENSE.clawhub" ]] || {
    echo "ERROR: missing ClawHub MIT-0 license asset" >&2
    exit 1
}
cp "$SOURCE_SKILL_DIR/assets/LICENSE.clawhub" "$PACKAGE_DIR/LICENSE"

for directory in assets references; do
    if [[ -d "$SOURCE_SKILL_DIR/$directory" ]]; then
        cp -R "$SOURCE_SKILL_DIR/$directory" "$PACKAGE_DIR/$directory"
    fi
done

mkdir -p "$PACKAGE_DIR/scripts"
for runtime_script in \
    common.sh \
    context-migrator.py \
    ide-paths.tsv \
    legacy-smart-ide-migration.sh \
    migration_core.py \
    scan-skill-secrets.py \
    smart-ide-migration.sh; do
    [[ -f "$SOURCE_SKILL_DIR/scripts/$runtime_script" ]] || {
        echo "ERROR: missing runtime dependency: scripts/$runtime_script" >&2
        exit 1
    }
    cp "$SOURCE_SKILL_DIR/scripts/$runtime_script" "$PACKAGE_DIR/scripts/$runtime_script"
done
