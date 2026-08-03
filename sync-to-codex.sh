#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"

exec "$SCRIPT_DIR/install.sh" --target "$TARGET" "$@"
