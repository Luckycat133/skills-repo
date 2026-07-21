#!/usr/bin/env bash
set -euo pipefail

# Codex's effective global skill dir is ~/.agents/skills (one of its 4-layer skill scan locations).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${CODEX_SKILLS_DIR:-$HOME/.agents/skills}"

exec "$SCRIPT_DIR/install.sh" --target "$TARGET" "$@"
