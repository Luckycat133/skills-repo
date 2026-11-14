#!/usr/bin/env bash
# Maintainer checks only. No user configuration is read or changed.
set -euo pipefail
cd "$(dirname "$0")"
PYTHON_BIN="${PYTHON:-}"
if [ -z "$PYTHON_BIN" ]; then
  if python3 -c 'import tomllib' >/dev/null 2>&1; then
    PYTHON_BIN="python3"
  elif command -v uv >/dev/null 2>&1; then
    PYTHON_BIN="uv run --python 3.12 python3"
  elif command -v python3.12 >/dev/null 2>&1; then
    PYTHON_BIN="python3.12"
  elif command -v python3.11 >/dev/null 2>&1; then
    PYTHON_BIN="python3.11"
  else
    PYTHON_BIN="python3"
  fi
fi
$PYTHON_BIN -m unittest discover -s tests -p 'test_*.py' -v
if command -v skills-ref >/dev/null 2>&1; then
  skills-ref validate skills/agent-skills-setup
  skills-ref validate dev/skills/maintain-agent-skills-setup
else
  printf '%s\n' 'NOT RUN: official skills-ref validator is not installed locally; CI requires it.'
fi
