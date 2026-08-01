#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR="${AGENT_SKILLS_SOURCE_DIR:-${HOME}/.gemini/config/skills}"
CLAUDE_DIR="${AGENT_SKILLS_CLAUDE_DIR:-${HOME}/.claude/skills}"
CODEX_DIR="${AGENT_SKILLS_CODEX_DIR:-${HOME}/.agents/skills}"
COPILOT_DIR="${AGENT_SKILLS_COPILOT_DIR:-${HOME}/.copilot/skills}"
OPENCLAW_DIR="${AGENT_SKILLS_OPENCLAW_DIR:-${HOME}/.openclaw/skills}"
TRAE_DIR="${AGENT_SKILLS_TRAE_DIR:-${HOME}/.trae/skills}"
TRAE_CN_DIR="${AGENT_SKILLS_TRAE_CN_DIR:-${HOME}/.trae-cn/skills}"

DRY_RUN=0
CONFIRM=0
TARGETS_RAW="claude,codex,copilot,openclaw,trae,trae-cn"

TMP_FILES=()
cleanup_tmp_files() {
    local f
    for f in "${TMP_FILES[@]:-}"; do
        [[ -n "$f" ]] && rm -f "$f" "$f.filtered" 2>/dev/null
    done
    return 0
}
trap cleanup_tmp_files EXIT

usage() {
    cat <<'EOF'
Usage: sync-global-skills.sh [--dry-run] [--targets claude,codex,copilot,openclaw,trae,trae-cn]

Mirror Antigravity global Skills into supported IDE directories. WorkBuddy is UI-managed and excluded.

Options:
  --dry-run              Preview without modifying files.
  --targets <list>       Comma-separated subset of targets to sync.
  --yes                  Apply the `rsync -a --delete` mirror.
  -h, --help             Show this help text.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --yes)
            CONFIRM=1
            shift
            ;;
        --targets)
            [[ $# -ge 2 ]] || {
                echo "ERROR: --targets requires a value" >&2
                exit 1
            }
            TARGETS_RAW="$2"
            shift 2
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

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "ERROR: Antigravity skills source not found: $SOURCE_DIR" >&2
    exit 1
fi

target_dir() {
    case "$1" in
        claude) printf '%s\n' "$CLAUDE_DIR" ;;
        codex) printf '%s\n' "$CODEX_DIR" ;;
        copilot) printf '%s\n' "$COPILOT_DIR" ;;
        openclaw) printf '%s\n' "$OPENCLAW_DIR" ;;
        trae) printf '%s\n' "$TRAE_DIR" ;;
        trae-cn) printf '%s\n' "$TRAE_CN_DIR" ;;
    esac
}

target_label() {
    case "$1" in
        claude) printf 'Claude' ;;
        codex) printf 'Codex' ;;
        copilot) printf 'Copilot' ;;
        openclaw) printf 'OpenClaw' ;;
        trae) printf 'Trae' ;;
        trae-cn) printf 'Trae CN' ;;
    esac
}

split_targets() {
    local raw="$1"
    local old_ifs="$IFS"

    IFS=',' read -r -a TARGETS <<< "$raw"
    IFS="$old_ifs"

    if [[ ${#TARGETS[@]} -eq 0 ]]; then
        echo "ERROR: No targets specified" >&2
        exit 1
    fi
}

ensure_targets_valid() {
    local item

    for item in "${TARGETS[@]}"; do
        case "$item" in
            claude|codex|copilot|openclaw|trae|trae-cn)
                ;;
            *)
                echo "ERROR: Unsupported target: $item" >&2
                exit 1
                ;;
        esac
    done
}

rsync_mirror() {
    local src="$1"
    local dest="$2"
    shift 2

    if ! command -v rsync >/dev/null 2>&1; then
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "DRY-RUN (no rsync): would mirror $src/ -> $dest/ via cp -R (preserving .system/)"
            return 0
        fi
        echo "WARN: rsync not found; using cp -R fallback mirror for $dest" >&2
        mkdir -p "$dest"
        local entry
        for entry in "$dest"/* "$dest"/.[!.]*; do
            [[ -e "$entry" ]] || continue
            [[ "$(basename "$entry")" == ".system" ]] && continue
            rm -rf "$entry"
        done
        cp -R "$src/." "$dest/"
        return 0
    fi

    local cmd=(rsync -a --delete)

    if [[ $DRY_RUN -eq 1 ]]; then
        cmd+=(--dry-run --itemize-changes)
    fi

    if [[ $# -gt 0 ]]; then
        cmd+=("$@")
    fi

    cmd+=("$src/" "$dest/")
    "${cmd[@]}"
}

verify_directory_inventory() {
    local left="$1"
    local right="$2"
    local label="$3"
    local left_list
    local right_list

    left_list="$(mktemp /tmp/skill-sync-left.XXXXXX)"
    right_list="$(mktemp /tmp/skill-sync-right.XXXXXX)"
    TMP_FILES+=("$left_list" "$right_list")

    find "$left" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort > "$left_list"
    find "$right" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort > "$right_list"

    if [[ "$label" == "Codex" ]]; then
        grep -v '^\.system$' "$right_list" > "$right_list.filtered"
        mv "$right_list.filtered" "$right_list"
    fi

    if ! diff -u "$left_list" "$right_list" >/dev/null; then
        echo "VERIFY FAIL: $label inventory differs from Antigravity" >&2
        return 1
    fi

    echo "VERIFY PASS: $label inventory matches Antigravity"
}

verify_shared_directories() {
    local target_root="$1"
    local label="$2"
    local skill

    while IFS= read -r skill; do
        diff -qr "$SOURCE_DIR/$skill" "$target_root/$skill" >/dev/null || {
            echo "VERIFY FAIL: $label content drift in $skill" >&2
            return 1
        }
    done < <(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)

    echo "VERIFY PASS: $label content matches Antigravity"
}

split_targets "$TARGETS_RAW"
ensure_targets_valid

VERIFY_FAILED=0

echo "Source of truth: $SOURCE_DIR"
echo "Targets: ${TARGETS[*]}"
[[ $DRY_RUN -eq 1 ]] && echo "Mode: dry-run"

if [[ $DRY_RUN -eq 0 && $CONFIRM -eq 0 ]]; then
    echo "REFUSING destructive sync: this mirrors with 'rsync -a --delete', which" >&2
    echo "removes skills in each target dir that are not present in the source." >&2
    echo "Review a plan first with --dry-run, then rerun with --yes to apply." >&2
    exit 1
fi

if [[ $DRY_RUN -eq 0 ]]; then
    echo "WARNING: applying destructive mirror (rsync -a --delete) to targets:" >&2
    echo "  ${TARGETS[*]}" >&2
    echo "Any skill present in a target but missing from the source will be deleted." >&2
fi

for target in "${TARGETS[@]}"; do
    destination="$(target_dir "$target")"
    mkdir -p "$destination"
    if [[ "$target" == "codex" ]]; then
        rsync_mirror "$SOURCE_DIR" "$destination" --filter='P .system/'
    else
        rsync_mirror "$SOURCE_DIR" "$destination"
    fi
done

if [[ $DRY_RUN -eq 0 ]]; then
    for target in "${TARGETS[@]}"; do
        destination="$(target_dir "$target")"
        label="$(target_label "$target")"
        verify_directory_inventory "$SOURCE_DIR" "$destination" "$label" \
            && verify_shared_directories "$destination" "$label" \
            || VERIFY_FAILED=1
    done

    if [[ $VERIFY_FAILED -ne 0 ]]; then
        echo "Sync finished with verification failures" >&2
        exit 1
    fi
fi

echo "Sync complete"
