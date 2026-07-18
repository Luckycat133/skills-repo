#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_ROOT="$SCRIPT_DIR/skills"
TARGET_ROOT="${AGENT_SKILLS_DIR:-$HOME/.agents/skills}"
SKILL_NAME=""
FORCE=0

usage() {
  echo "Usage: ./install.sh [--target DIR] [--skill NAME] [--force]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_ROOT="$2"; shift 2 ;;
    --skill) SKILL_NAME="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

mkdir -p "$TARGET_ROOT"
timestamp="$(date +%Y%m%d%H%M%S)"

install_one() {
  local source_dir="$1"
  local name target_dir
  name="$(basename "$source_dir")"
  target_dir="$TARGET_ROOT/$name"

  [[ -f "$source_dir/SKILL.md" ]] || {
    echo "ERROR: missing $source_dir/SKILL.md" >&2
    return 1
  }

  if [[ -e "$target_dir" ]]; then
    if [[ "$FORCE" -ne 1 ]]; then
      echo "ERROR: $target_dir already exists; rerun with --force to back it up and replace it" >&2
      return 1
    fi
    mv "$target_dir" "$target_dir.bak.$timestamp"
  fi

  cp -R "$source_dir" "$target_dir"
  echo "Installed $name -> $target_dir"
}

if [[ -n "$SKILL_NAME" ]]; then
  [[ "$SKILL_NAME" =~ ^[a-z0-9-]+$ ]] || {
    echo "ERROR: invalid skill name: $SKILL_NAME" >&2
    exit 2
  }
  install_one "$SOURCE_ROOT/$SKILL_NAME"
else
  found=0
  for source_dir in "$SOURCE_ROOT"/*; do
    [[ -d "$source_dir" ]] || continue
    found=1
    install_one "$source_dir"
  done
  [[ "$found" -eq 1 ]] || {
    echo "ERROR: no skills found under $SOURCE_ROOT" >&2
    exit 1
  }
fi
