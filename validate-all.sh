#!/usr/bin/env bash
# Maintainer checks only. No user configuration is read or changed.
set -euo pipefail
cd "$(dirname "$0")"
python3 -m unittest discover -s tests -p 'test_*.py' -v
if command -v skills-ref >/dev/null 2>&1; then
  skills-ref validate skills/agent-skills-setup
  skills-ref validate dev/skills/maintain-agent-skills-setup
else
  printf '%s\n' 'NOT RUN: official skills-ref validator is not installed locally; CI requires it.'
fi
