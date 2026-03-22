#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: bash scripts/import-agent-skill.sh <source-skill-dir> <skill-name>" >&2
    exit 1
fi

SOURCE_SKILL_DIR="$1"
SKILL_NAME="$2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="$REPO_ROOT/skills/$SKILL_NAME"

if [[ ! -d "$SOURCE_SKILL_DIR" ]]; then
    echo "ERROR: source skill directory not found: $SOURCE_SKILL_DIR" >&2
    exit 1
fi

mkdir -p "$REPO_ROOT/skills"
rsync -a --delete "$SOURCE_SKILL_DIR/" "$TARGET_DIR/"

echo "Imported $SKILL_NAME into $TARGET_DIR"