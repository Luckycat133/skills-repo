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

MIRROR_COMMENT='<!--
  MIRROR FILE — not the source of truth.
  Some platforms (e.g. smithery.ai) only scan the repository ROOT for SKILL.md.
  The canonical, maintained copy lives at: skills/agent-skills-setup/SKILL.md
  Regenerate this mirror after editing the canonical with:
    bash scripts/sync-root-mirror.sh
  Repo-relative links (references/, scripts/) are rewritten to
  skills/agent-skills-setup/... so they resolve correctly from the repository root.
-->'

build_mirror() {
  python3 -c '
import re, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    text = f.read()
rewritten = re.sub(r"(?<!skills/agent-skills-setup/)\b(references|scripts|assets)/([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)", r"skills/agent-skills-setup/\1/\2", text)
rewritten = re.sub(r"(?<=\]\()(?<!skills/agent-skills-setup/)\b(references|scripts|assets)/", r"skills/agent-skills-setup/\1/", rewritten)
frontmatter_end = rewritten.find("\n---\n", 4)
if not rewritten.startswith("---\n") or frontmatter_end < 0:
    raise SystemExit("canonical SKILL.md has invalid frontmatter")
frontmatter_end += len("\n---\n")
sys.stdout.write(rewritten[:frontmatter_end])
sys.stdout.write("\n" + sys.argv[2] + "\n\n")
sys.stdout.write(rewritten[frontmatter_end:].lstrip("\n"))
' "$CANONICAL" "$MIRROR_COMMENT"
}

if [[ "$CHECK_ONLY" == true ]]; then
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  build_mirror > "$tmp"
  if diff -q "$tmp" "$ROOT_MIRROR" >/dev/null 2>&1; then
    echo "root SKILL.md is in sync with the canonical copy."
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
echo "Regenerated $OUTPUT_PATH from canonical ($(wc -l < "$CANONICAL") lines)."
