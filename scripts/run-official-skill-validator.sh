#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v skills-ref >/dev/null 2>&1; then
    if [[ "${CI:-}" == "true" ]]; then
        echo "ERROR: official skills-ref validator is required in CI" >&2
        exit 1
    fi
    echo "SKIP: skills-ref is not installed; CI installs and requires the pinned official validator."
    exit 0
fi

skills-ref validate "$REPO_ROOT/skills/agent-skills-setup"
