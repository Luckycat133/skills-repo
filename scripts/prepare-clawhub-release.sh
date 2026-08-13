#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

SKILL_DIR=""
SKILL_DIR_ABS=""
PACKAGE_DIR=""
PACKAGE_DIR_ABS=""
SLUG=""
DISPLAY_NAME=""
VERSION=""
TAGS="latest"
CHANGELOG_TEXT=""
CHANGELOG_FILE=""
SOURCE_REPO=""
SOURCE_COMMIT=""
SOURCE_REF=""
SOURCE_PATH=""
RUN_PUBLISH=0
MIT0_ACKNOWLEDGED=0

usage() {
    cat <<'EOF'
Usage: prepare-clawhub-release.sh [options]

Validate a Skill and print or run its ClawHub publish command.

Options:
  --skill-dir <dir>         Path to the skill folder to publish.
  --package-dir <dir>       Empty destination for the runtime-only package.
  --slug <slug>             Public ClawHub slug.
  --name <name>             Display name.
  --version <semver>        Release version, e.g. 1.0.0.
  --tags <csv>              Comma-separated tags. Default: latest.
  --changelog <text>        Inline changelog text.
  --changelog-file <file>   Read changelog text from a file.
  --source-repo <url>       Caller-supplied source repository URL.
  --source-commit <sha>     Caller-supplied full source commit SHA.
  --source-ref <ref>        Caller-supplied source branch or tag.
  --source-path <path>      Caller-supplied path within the repository.
  --publish                 Execute `clawhub publish` after validation.
  --acknowledge-mit0        Confirm contributor authorization for ClawHub MIT-0.
  -h, --help                Show this help text.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skill-dir)
            [[ $# -ge 2 ]] || die "--skill-dir requires a value"
            SKILL_DIR="$2"
            shift 2
            ;;
        --package-dir)
            [[ $# -ge 2 ]] || die "--package-dir requires a value"
            PACKAGE_DIR="$2"
            shift 2
            ;;
        --slug)
            [[ $# -ge 2 ]] || die "--slug requires a value"
            SLUG="$2"
            shift 2
            ;;
        --name)
            [[ $# -ge 2 ]] || die "--name requires a value"
            DISPLAY_NAME="$2"
            shift 2
            ;;
        --version)
            [[ $# -ge 2 ]] || die "--version requires a value"
            VERSION="$2"
            shift 2
            ;;
        --tags)
            [[ $# -ge 2 ]] || die "--tags requires a value"
            TAGS="$2"
            shift 2
            ;;
        --changelog)
            [[ $# -ge 2 ]] || die "--changelog requires a value"
            CHANGELOG_TEXT="$2"
            shift 2
            ;;
        --changelog-file)
            [[ $# -ge 2 ]] || die "--changelog-file requires a value"
            CHANGELOG_FILE="$2"
            shift 2
            ;;
        --source-repo)
            [[ $# -ge 2 ]] || die "--source-repo requires a value"
            SOURCE_REPO="$2"
            shift 2
            ;;
        --source-commit)
            [[ $# -ge 2 ]] || die "--source-commit requires a value"
            SOURCE_COMMIT="$2"
            shift 2
            ;;
        --source-ref)
            [[ $# -ge 2 ]] || die "--source-ref requires a value"
            SOURCE_REF="$2"
            shift 2
            ;;
        --source-path)
            [[ $# -ge 2 ]] || die "--source-path requires a value"
            SOURCE_PATH="$2"
            shift 2
            ;;
        --publish)
            RUN_PUBLISH=1
            shift
            ;;
        --acknowledge-mit0)
            MIT0_ACKNOWLEDGED=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

[[ -n "$SKILL_DIR" ]] || die "--skill-dir is required"
[[ -n "$PACKAGE_DIR" ]] || die "--package-dir is required"
[[ -n "$SLUG" ]] || die "--slug is required"
[[ -n "$DISPLAY_NAME" ]] || die "--name is required"
[[ -n "$VERSION" ]] || die "--version is required"
[[ -d "$SKILL_DIR" ]] || die "Skill directory not found: $SKILL_DIR"
[[ -f "$SKILL_DIR/SKILL.md" ]] || die "Missing SKILL.md in $SKILL_DIR"

if command_exists realpath; then
    SKILL_DIR_ABS="$(realpath "$SKILL_DIR")"
else
    SKILL_DIR_ABS="$(cd "$SKILL_DIR" && pwd)"
fi

if [[ -n "$CHANGELOG_FILE" ]]; then
    [[ -f "$CHANGELOG_FILE" ]] || die "Changelog file not found: $CHANGELOG_FILE"
    CHANGELOG_TEXT="$(cat "$CHANGELOG_FILE")"
fi

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9]+)?$ ]] || die "Version must look like semver: $VERSION"
[[ "$SLUG" =~ ^[a-z0-9-]+$ ]] || die "Slug must contain only lowercase letters, numbers, and hyphens"

SOURCE_PROVENANCE_COUNT=0
for value in "$SOURCE_REPO" "$SOURCE_COMMIT" "$SOURCE_REF" "$SOURCE_PATH"; do
    [[ -z "$value" ]] || SOURCE_PROVENANCE_COUNT=$((SOURCE_PROVENANCE_COUNT + 1))
done
if [[ $SOURCE_PROVENANCE_COUNT -ne 0 && $SOURCE_PROVENANCE_COUNT -ne 4 ]]; then
    die "Source attribution requires --source-repo, --source-commit, --source-ref, and --source-path together"
fi
if [[ -n "$SOURCE_COMMIT" && ! "$SOURCE_COMMIT" =~ ^[0-9a-fA-F]{40}$ ]]; then
    die "--source-commit must be a full 40-character Git commit SHA"
fi

command_exists clawhub || die "clawhub is not installed"

if ! clawhub whoami >/dev/null 2>&1; then
    if [[ $RUN_PUBLISH -eq 1 ]]; then
        die "Not logged in to ClawHub. Run: clawhub login"
    fi
    echo "WARN: Not logged in to ClawHub. Run 'clawhub login' before using --publish." >&2
fi

case "$PACKAGE_DIR" in
    /*) PACKAGE_DIR_ABS="$PACKAGE_DIR" ;;
    *) PACKAGE_DIR_ABS="$(pwd)/$PACKAGE_DIR" ;;
esac
[[ ! -e "$PACKAGE_DIR_ABS" ]] || die "Package directory already exists: $PACKAGE_DIR_ABS"
bash "$REPO_ROOT/scripts/stage-runtime-skill.sh" \
    "$SKILL_DIR_ABS" "$PACKAGE_DIR_ABS" "$VERSION"

if [[ $RUN_PUBLISH -eq 1 && $MIT0_ACKNOWLEDGED -ne 1 ]]; then
    die "ClawHub publishes under MIT-0; rerun with --acknowledge-mit0 only after contributor authorization is confirmed"
fi
if [[ $RUN_PUBLISH -eq 1 && $SOURCE_PROVENANCE_COUNT -ne 4 ]]; then
    die "ClawHub publish requires complete source attribution; pass --source-repo, --source-commit, --source-ref, and --source-path"
fi

PUBLISH_CMD=(clawhub publish "$PACKAGE_DIR_ABS" --slug "$SLUG" --name "$DISPLAY_NAME" --version "$VERSION" --tags "$TAGS")

if [[ -n "$CHANGELOG_TEXT" ]]; then
    PUBLISH_CMD+=(--changelog "$CHANGELOG_TEXT")
fi
if [[ $SOURCE_PROVENANCE_COUNT -eq 4 ]]; then
    PUBLISH_CMD+=(
        --source-repo "$SOURCE_REPO"
        --source-commit "$SOURCE_COMMIT"
        --source-ref "$SOURCE_REF"
        --source-path "$SOURCE_PATH"
    )
fi

echo "Validated source skill: $SKILL_DIR_ABS"
echo "Staged runtime package: $PACKAGE_DIR_ABS"
echo "Suggested publish command:"
printf '%q ' "${PUBLISH_CMD[@]}"
printf '\n'

if [[ $RUN_PUBLISH -eq 1 ]]; then
    "${PUBLISH_CMD[@]}"
fi
