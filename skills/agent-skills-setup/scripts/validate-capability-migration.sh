#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(pwd)"
STRICT=0

usage() {
    cat <<'EOF'
Usage: validate-capability-migration.sh [options]

Validate a migrated AI Assistant Capability layout in a workspace.

Options:
  --root <dir>      Workspace root to validate. Default: current directory.
  --strict          Treat warnings as errors.
  -h, --help        Show this help text.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)
            ROOT_DIR="$2"
            shift 2
            ;;
        --strict)
            STRICT=1
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

if [[ ! -d "$ROOT_DIR" ]]; then
    echo "ERROR: root directory not found: $ROOT_DIR" >&2
    exit 1
fi

HAS_JQ=0
if command -v jq >/dev/null 2>&1; then
    HAS_JQ=1
fi

HAS_PYTHON3=0
if command -v python3 >/dev/null 2>&1; then
    HAS_PYTHON3=1
fi

ERROR_COUNT=0
WARN_COUNT=0
CHECK_COUNT=0

fail() {
    local message="$1"
    echo "FAIL: $message" >&2
    ERROR_COUNT=$((ERROR_COUNT + 1))
}

warn() {
    local message="$1"
    echo "WARN: $message"
    WARN_COUNT=$((WARN_COUNT + 1))
}

pass() {
    local message="$1"
    echo "PASS: $message"
}

validate_skill_frontmatter() {
    local file_path="$1"
    local header

    CHECK_COUNT=$((CHECK_COUNT + 1))

    header="$(sed -n '1,40p' "$file_path")"
    if ! echo "$header" | grep -q '^---$'; then
        fail "Missing frontmatter fence in $file_path"
        return
    fi

    if ! echo "$header" | grep -q '^name:'; then
        fail "Missing 'name' in frontmatter: $file_path"
        return
    fi

    if ! echo "$header" | grep -q '^description:'; then
        fail "Missing 'description' in frontmatter: $file_path"
        return
    fi

    pass "Skill frontmatter valid: $file_path"
}

validate_prompt_frontmatter() {
    local file_path="$1"
    local header

    CHECK_COUNT=$((CHECK_COUNT + 1))
    header="$(sed -n '1,40p' "$file_path")"

    if ! echo "$header" | grep -q '^---$'; then
        warn "Prompt file has no frontmatter fence: $file_path"
        return
    fi

    if ! echo "$header" | grep -q '^description:'; then
        warn "Prompt file missing optional description: $file_path"
    else
        pass "Prompt metadata present: $file_path"
    fi
}

validate_markdown_rule() {
    local file_path="$1"

    CHECK_COUNT=$((CHECK_COUNT + 1))
    if [[ ! -s "$file_path" ]]; then
        fail "Rule file is empty: $file_path"
        return
    fi

    pass "Rule file non-empty: $file_path"
}

validate_json_file() {
    local file_path="$1"

    CHECK_COUNT=$((CHECK_COUNT + 1))
    if [[ $HAS_JQ -eq 1 ]]; then
        if jq empty "$file_path" >/dev/null 2>&1; then
            pass "JSON valid: $file_path"
        else
            fail "Invalid JSON: $file_path"
        fi
    else
        if grep -q '^[[:space:]]*{' "$file_path" || grep -q '^[[:space:]]*\[' "$file_path"; then
            warn "jq unavailable, JSON only lightly checked: $file_path"
        else
            fail "JSON file does not appear to be object/array: $file_path"
        fi
    fi
}

validate_toml_file() {
    local file_path="$1"

    CHECK_COUNT=$((CHECK_COUNT + 1))
    if [[ $HAS_PYTHON3 -eq 1 ]]; then
        if python3 - "$file_path" <<'PY' >/dev/null 2>&1
import sys
import tomllib

path = sys.argv[1]
with open(path, 'rb') as f:
    tomllib.load(f)
PY
        then
            pass "TOML valid: $file_path"
        else
            fail "Invalid TOML: $file_path"
        fi
    else
        warn "python3 unavailable, TOML not deeply validated: $file_path"
    fi
}

validate_json5_file() {
    local file_path="$1"

    CHECK_COUNT=$((CHECK_COUNT + 1))
    if grep -q '^[[:space:]]*{' "$file_path"; then
        pass "JSON5 structure looks valid: $file_path"
    else
        warn "JSON5 file does not start with object syntax: $file_path"
    fi
}

check_platform_layout() {
    local base_dir="$1"
    local platform="$2"

    local missing=0
    CHECK_COUNT=$((CHECK_COUNT + 1))

    case "$platform" in
        copilot)
            [[ -d "$base_dir/.github/skills" ]] || missing=1
            ;;
        cursor)
            [[ -d "$base_dir/.cursor/skills" ]] || missing=1
            ;;
        windsurf)
            [[ -d "$base_dir/.windsurf/skills" ]] || missing=1
            ;;
        jetbrains)
            [[ -d "$base_dir/.idea/ai-capabilities/skills" ]] || missing=1
            ;;
        claude)
            [[ -d "$base_dir/.claude/skills" ]] || missing=1
            ;;
        codex)
            [[ -d "$base_dir/.agents/skills" ]] || missing=1
            ;;
        openclaw)
            [[ -d "$base_dir/skills" ]] || missing=1
            ;;
        trae)
            [[ -d "$base_dir/.trae/skills" ]] || missing=1
            ;;
        trae-cn)
            [[ -d "$base_dir/.trae-cn/skills" ]] || missing=1
            ;;
        *)
            warn "Unknown platform directory in migration targets: $platform"
            return
            ;;
    esac

    if [[ $missing -eq 0 ]]; then
        pass "Platform layout detected: $platform"
    else
        warn "Platform layout incomplete: $platform"
    fi
}

validate_rules_file() {
    local file_path="$1"

    CHECK_COUNT=$((CHECK_COUNT + 1))
    if [[ ! -s "$file_path" ]]; then
        fail "Codex rules file empty: $file_path"
        return
    fi

    if ! grep -q 'prefix_rule' "$file_path"; then
        warn "Codex rules file has no prefix_rule entry: $file_path"
    else
        pass "Codex rules entry found: $file_path"
    fi
}

validate_workflow_markdown() {
    local file_path="$1"
    local header

    CHECK_COUNT=$((CHECK_COUNT + 1))
    header="$(sed -n '1,40p' "$file_path")"

    if ! echo "$header" | grep -q '^---$'; then
        warn "Workflow markdown has no frontmatter: $file_path"
        return
    fi

    if ! echo "$header" | grep -q '^name:'; then
        fail "Workflow missing name: $file_path"
        return
    fi

    if ! echo "$header" | grep -q '^description:'; then
        fail "Workflow missing description: $file_path"
        return
    fi

    pass "Workflow metadata valid: $file_path"
}

echo "Validating workspace: $ROOT_DIR"

while IFS= read -r file_path; do
    validate_skill_frontmatter "$file_path"
done < <(find "$ROOT_DIR" -type f -name 'SKILL.md' 2>/dev/null | sort)

while IFS= read -r file_path; do
    validate_prompt_frontmatter "$file_path"
done < <(find "$ROOT_DIR" -type f -name '*.prompt.md' 2>/dev/null | sort)

while IFS= read -r file_path; do
    validate_markdown_rule "$file_path"
done < <(find "$ROOT_DIR/.claude/rules" -type f -name '*.md' 2>/dev/null | sort)

while IFS= read -r file_path; do
    validate_json_file "$file_path"
done < <(find "$ROOT_DIR" -type f -name '*.json' 2>/dev/null | sort)

while IFS= read -r file_path; do
    validate_toml_file "$file_path"
done < <(find "$ROOT_DIR" -type f -name '*.toml' 2>/dev/null | sort)

while IFS= read -r file_path; do
    validate_json5_file "$file_path"
done < <(find "$ROOT_DIR" -type f -name '*.json5' 2>/dev/null | sort)

while IFS= read -r file_path; do
    validate_rules_file "$file_path"
done < <(find "$ROOT_DIR/.codex/rules" -type f -name '*.rules' 2>/dev/null | sort)

while IFS= read -r file_path; do
    validate_workflow_markdown "$file_path"
done < <(find "$ROOT_DIR/.github/workflows/ai" -type f -name '*.md' 2>/dev/null | sort)

if [[ -d "$ROOT_DIR/.migration-targets" ]]; then
    while IFS= read -r platform_dir; do
        platform_name="$(basename "$platform_dir")"
        check_platform_layout "$platform_dir" "$platform_name"
    done < <(find "$ROOT_DIR/.migration-targets" -mindepth 1 -maxdepth 1 -type d | sort)
fi

echo ""
echo "Checks executed: $CHECK_COUNT"
echo "Warnings: $WARN_COUNT"
echo "Errors: $ERROR_COUNT"

if [[ $STRICT -eq 1 && $WARN_COUNT -gt 0 ]]; then
    echo "STRICT MODE: warnings are treated as errors" >&2
    exit 1
fi

if [[ $ERROR_COUNT -gt 0 ]]; then
    exit 1
fi

echo "Validation complete: PASS"
