#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CANONICAL="$REPO_ROOT/skills/agent-skills-setup/SKILL.md"
ROOT_MIRROR="$REPO_ROOT/SKILL.md"
OUTPUT_PATH="$ROOT_MIRROR"
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      CHECK_ONLY=true
      ;;
    --output)
      [[ $# -ge 2 ]] || { echo "ERROR: --output requires a path" >&2; exit 2; }
      OUTPUT_PATH="$2"
      shift
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      exit 2
      ;;
  esac
  shift
done

if [[ "$CHECK_ONLY" == true && "$OUTPUT_PATH" != "$ROOT_MIRROR" ]]; then
  echo "ERROR: --check cannot be combined with --output" >&2
  exit 2
fi

if [[ ! -f "$CANONICAL" ]]; then
  echo "ERROR: canonical skill not found at $CANONICAL" >&2
  exit 1
fi

build_mirror() {
  cat <<'EOF'
<!--
  GENERATED REPOSITORY POINTER — not a publishable Agent Skill.
  The only canonical Skill package is skills/agent-skills-setup/.
  Regenerate this pointer with: bash scripts/sync-root-mirror.sh
-->

# agent-skills-setup

The repository root is not an Agent Skill package. Use the canonical
[`agent-skills-setup` Skill](skills/agent-skills-setup/SKILL.md), whose parent
directory matches its declared `name`.

- [Registry v2](skills/agent-skills-setup/references/registry-v2.json)
- [Product profile index](skills/agent-skills-setup/references/ide-registry.md)
- [Migration command](skills/agent-skills-setup/scripts/smart-ide-migration.sh)
EOF
}

if [[ "$CHECK_ONLY" == true ]]; then
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  build_mirror > "$tmp"
  if diff -q "$tmp" "$ROOT_MIRROR" >/dev/null 2>&1; then
    echo "root SKILL.md repository pointer is in sync."
    exit 0
  else
    echo "ERROR: root SKILL.md is OUT OF SYNC with skills/agent-skills-setup/SKILL.md" >&2
    echo "Run: bash scripts/sync-root-mirror.sh" >&2
    exit 1
  fi
fi

output_dir="$(cd "$(dirname "$OUTPUT_PATH")" && pwd)"
tmp_write="$(mktemp "${output_dir}/.$(basename "$OUTPUT_PATH").tmp.XXXXXX")"
trap 'rm -f "$tmp_write"' EXIT
build_mirror > "$tmp_write"
mv "$tmp_write" "$OUTPUT_PATH"
echo "Regenerated non-publishable repository pointer at $OUTPUT_PATH."
