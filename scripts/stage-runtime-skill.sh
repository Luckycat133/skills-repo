#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 2 ]] || {
    echo "Usage: stage-runtime-skill.sh SOURCE_SKILL_DIR PACKAGE_DIR" >&2
    exit 2
}

SOURCE_SKILL_DIR="$1"
PACKAGE_DIR="$2"
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
cp "$SOURCE_SKILL_DIR/SKILL.md" "$PACKAGE_DIR/SKILL.md"

for directory in assets references; do
    if [[ -d "$SOURCE_SKILL_DIR/$directory" ]]; then
        cp -R "$SOURCE_SKILL_DIR/$directory" "$PACKAGE_DIR/$directory"
    fi
done

mkdir -p "$PACKAGE_DIR/scripts"
for runtime_script in common.sh ide-paths.tsv smart-ide-migration.sh; do
    [[ -f "$SOURCE_SKILL_DIR/scripts/$runtime_script" ]] || {
        echo "ERROR: missing runtime dependency: scripts/$runtime_script" >&2
        exit 1
    }
    cp "$SOURCE_SKILL_DIR/scripts/$runtime_script" "$PACKAGE_DIR/scripts/$runtime_script"
done
