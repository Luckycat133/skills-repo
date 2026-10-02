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

python3 "$SCRIPT_DIR/skill_package.py" stage "$SOURCE_SKILL_DIR" "$PACKAGE_DIR" "$VERSION"
