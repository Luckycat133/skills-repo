#!/usr/bin/env bash
#
# export-public-skill.sh — SINGLE RESPONSIBILITY: prepare the PUBLIC repository layout.
# Copies a source skill into a standalone public-repo structure (via rsync) and
# generates/updates the public README from `public-repo-readme-template.md`.
# This script does NOT publish the skill. Publishing is the job of
# prepare-clawhub-release.sh (see ./prepare-clawhub-release.sh), whose canonical
# publish command is `clawhub publish`.
# NOTE: the `npx skills add <owner/repo>` step printed at the end is for CONSUMERS to
# install the already-published skill — it is an install/test command, NOT a publish command.
#
set -euo pipefail

SOURCE_ROOT="${AGENT_SKILLS_SOURCE_DIR:-${HOME}/.gemini/antigravity/skills}"
TEMPLATE_PATH="${SOURCE_ROOT}/agent-skills-setup/assets/public-repo-readme-template.md"
SKILL_NAME=""
OUTPUT_DIR=""
REPO_NAME=""
DRY_RUN=0
FORCE=0

usage() {
    cat <<'EOF'
Usage: export-public-skill.sh --skill <skill-name> --output <directory> --repo <owner/repo>

Exports a skill from Antigravity's global skill store into a standalone public repository layout.

Options:
  --skill <name>        Skill folder name under ~/.gemini/antigravity/skills
  --output <dir>        Destination repository directory to create or update
  --repo <owner/repo>   Public repository name used in generated install docs
  --dry-run             Preview rsync --delete changes without writing
  --force               Allow rsync --delete into a non-empty existing target
  -h, --help            Show this help text
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skill)
            SKILL_NAME="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --repo)
            REPO_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$SKILL_NAME" || -z "$OUTPUT_DIR" || -z "$REPO_NAME" ]]; then
    echo "ERROR: --skill, --output, and --repo are required" >&2
    usage >&2
    exit 1
fi

SOURCE_SKILL_DIR="${SOURCE_ROOT}/${SKILL_NAME}"

if [[ ! -d "$SOURCE_SKILL_DIR" ]]; then
    echo "ERROR: Skill not found: $SOURCE_SKILL_DIR" >&2
    exit 1
fi

if [[ ! -f "$TEMPLATE_PATH" ]]; then
    echo "ERROR: README template not found: $TEMPLATE_PATH" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
if [[ -e "$OUTPUT_DIR/$SKILL_NAME" && -n "$(ls -A "$OUTPUT_DIR/$SKILL_NAME" 2>/dev/null)" && $FORCE -ne 1 ]]; then
    echo "ERROR: $OUTPUT_DIR/$SKILL_NAME already exists and is not empty; rsync --delete would remove extra files inside it." >&2
    echo "        Re-run with --force to confirm, or use --dry-run to preview what would be deleted/added." >&2
    exit 1
fi
# MED-P8: rsync is required for the --delete mirror semantics used here.
if ! command -v rsync >/dev/null 2>&1; then
    echo "ERROR: rsync not found. Install rsync (e.g. macOS: xcode-select --install; Debian/Ubuntu: apt install rsync) and retry." >&2
    exit 1
fi
if [[ $DRY_RUN -eq 1 ]]; then
    rsync -a --delete --dry-run "$SOURCE_SKILL_DIR/" "$OUTPUT_DIR/$SKILL_NAME/"
else
    rsync -a --delete "$SOURCE_SKILL_DIR/" "$OUTPUT_DIR/$SKILL_NAME/"
fi

# MED-P6: escape sed replacement metacharacters (\, &, delimiter) so names
# containing them cannot corrupt the generated README or inject expressions.
sed_escape_replacement() {
    printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}
SKILL_NAME_ESC="$(sed_escape_replacement "$SKILL_NAME")"
REPO_NAME_ESC="$(sed_escape_replacement "$REPO_NAME")"

sed \
    -e "s|{{SKILL_NAME}}|$SKILL_NAME_ESC|g" \
    -e "s|{{REPO_NAME}}|$REPO_NAME_ESC|g" \
    "$TEMPLATE_PATH" > "$OUTPUT_DIR/README.md"

echo "Exported $SKILL_NAME to $OUTPUT_DIR"
echo "Next steps:"
echo "1. Review README.md and replace placeholder sections"
echo "2. Add LICENSE and repository topics"
echo "3. Publish the directory as a public GitHub repository"
echo "4. Test install flow with: npx skills add $REPO_NAME"