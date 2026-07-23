#!/usr/bin/env bash
#
# sync-root-mirror.sh — regenerate the repository-root SKILL.md from the
# canonical skill copy.
#
# Why this exists:
#   Some platforms (e.g. smithery.ai) only scan the repository ROOT for SKILL.md.
#   The maintained copy lives at skills/agent-skills-setup/SKILL.md. The root
#   file is a generated MIRROR of it. Keeping it as a hand-edited copy caused
#   drift (stale version, broken relative links, inconsistent wording).
#
# What it does:
#   1. Takes skills/agent-skills-setup/SKILL.md as the source of truth.
#   2. Prepends a MIRROR comment.
#   3. Rewrites repo-relative links so they resolve from the repository root:
#        references/...   -> skills/agent-skills-setup/references/...
#        scripts/...      -> skills/agent-skills-setup/scripts/...
#      (Descriptive text such as "scripts/ + references/ + assets/" is left
#       untouched — only the specific skill-file references are rewritten.)
#
# Usage:
#   bash scripts/sync-root-mirror.sh            # write root SKILL.md
#   bash scripts/sync-root-mirror.sh --check    # exit 1 if root is out of sync
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CANONICAL="$REPO_ROOT/skills/agent-skills-setup/SKILL.md"
ROOT_MIRROR="$REPO_ROOT/SKILL.md"

if [[ ! -f "$CANONICAL" ]]; then
  echo "ERROR: canonical skill not found at $CANONICAL" >&2
  exit 1
fi

MIRROR_COMMENT='<!--
  MIRROR FILE — not the source of truth.
  Some platforms (e.g. smithery.ai) only scan the repository ROOT for SKILL.md.
  The canonical, maintained copy lives at: skills/agent-skills-setup/SKILL.md
  Regenerate this mirror after editing the canonical with:
    bash scripts/sync-root-mirror.sh
  Repo-relative links (references/, scripts/) are rewritten to
  skills/agent-skills-setup/... so they resolve correctly from the repository root.
-->'

# Build the mirror content: MIRROR comment + link-rewritten canonical.
build_mirror() {
  printf '%s\n\n' "$MIRROR_COMMENT"
  sed -e 's#references/ide-registry.md#skills/agent-skills-setup/references/ide-registry.md#g' \
      -e 's#`scripts/auto-configure-openclaw-skills.sh`#`skills/agent-skills-setup/scripts/auto-configure-openclaw-skills.sh`#g' \
      -e 's#`scripts/smart-ide-migration.sh`#`skills/agent-skills-setup/scripts/smart-ide-migration.sh`#g' \
      -e 's#bash scripts/smart-ide-migration.sh#bash skills/agent-skills-setup/scripts/smart-ide-migration.sh#g' \
      "$CANONICAL"
}

if [[ "${1:-}" == "--check" ]]; then
  tmp="$(mktemp)"
  build_mirror > "$tmp"
  if diff -q "$tmp" "$ROOT_MIRROR" >/dev/null 2>&1; then
    echo "root SKILL.md is in sync with the canonical copy."
    rm -f "$tmp"
    exit 0
  else
    echo "ERROR: root SKILL.md is OUT OF SYNC with skills/agent-skills-setup/SKILL.md" >&2
    echo "Run: bash scripts/sync-root-mirror.sh" >&2
    rm -f "$tmp"
    exit 1
  fi
fi

build_mirror > "$ROOT_MIRROR"
echo "Regenerated $ROOT_MIRROR from canonical ($(wc -l < "$CANONICAL") lines)."
