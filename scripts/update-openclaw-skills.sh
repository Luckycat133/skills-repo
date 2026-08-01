#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${AGENT_SKILLS_SOURCE_DIR:-${HOME}/.gemini/config/skills}"
STATE_DIR="${OPENCLAW_STATE_DIR:-${HOME}/.openclaw}"
MANAGED_DIR="${AGENT_SKILLS_OPENCLAW_DIR:-${STATE_DIR}/skills}"
DRY_RUN=0
CONFIRM=0
SKIP_RUNTIME=0
SKIP_CLAWHUB=0
SKIP_MIRROR=0
SKIP_DOCTOR=0

declare -a WORKSPACES=()
declare -a AGENTS=()
declare -a REQUESTED_SKILLS=()
source "${SCRIPT_DIR}/openclaw-common.sh"

usage() {
    cat <<'EOF'
Usage: update-openclaw-skills.sh [options]

Update OpenClaw, registry skills, and local mirrors.

Options:
  --source <dir>          Source skill root. Default: ~/.gemini/config/skills
  --managed-dir <dir>     Managed OpenClaw skill directory. Default: ~/.openclaw/skills
  --workspace <dir>       Update this workspace. Repeatable.
  --agent <id:workspace>  Add workspace by agent notation. Repeatable.
  --skills <list>         Comma-separated mirror subset.
  --skip-runtime          Do not run `openclaw update`.
  --skip-clawhub          Do not run `clawhub update --all`.
  --skip-mirror           Do not run local rsync mirror updates.
  --skip-doctor           Do not run `openclaw doctor` after updates.
  --dry-run               Preview commands and mirror changes.
  --yes                   Apply the local `rsync -a --delete` mirror; preview first.
  -h, --help              Show this help text.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            [[ $# -ge 2 ]] || die "--source requires a value"
            SOURCE_DIR="$2"
            shift 2
            ;;
        --managed-dir)
            [[ $# -ge 2 ]] || die "--managed-dir requires a value"
            MANAGED_DIR="$2"
            shift 2
            ;;
        --workspace)
            [[ $# -ge 2 ]] || die "--workspace requires a value"
            WORKSPACES+=("$2")
            shift 2
            ;;
        --agent)
            [[ $# -ge 2 ]] || die "--agent requires a value"
            AGENTS+=("$2")
            shift 2
            ;;
        --skills)
            [[ $# -ge 2 ]] || die "--skills requires a value"
            split_csv_into_array "$2" REQUESTED_SKILLS
            shift 2
            ;;
        --skip-runtime)
            SKIP_RUNTIME=1
            shift
            ;;
        --skip-clawhub)
            SKIP_CLAWHUB=1
            shift
            ;;
        --skip-mirror)
            SKIP_MIRROR=1
            shift
            ;;
        --skip-doctor)
            SKIP_DOCTOR=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --yes)
            CONFIRM=1
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

[[ -d "$SOURCE_DIR" ]] || die "Source skills directory not found: $SOURCE_DIR"

if [[ ${#REQUESTED_SKILLS[@]} -eq 0 ]]; then
    while IFS= read -r skill_name; do
        REQUESTED_SKILLS+=("$skill_name")
    done < <(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
fi

if [[ ${#AGENTS[@]} -gt 0 ]]; then
    for agent_spec in "${AGENTS[@]}"; do
        [[ "$agent_spec" == *:* ]] || die "--agent must be in id:workspace format"
        WORKSPACES+=("${agent_spec#*:}")
    done
fi

mirror_destinations() {
    printf '%s\n' "$MANAGED_DIR"
    local workspace
    for workspace in "${WORKSPACES[@]}"; do
        printf '%s/skills\n' "$workspace"
    done
}

mirror_selected_skills() {
    local destination_root="$1"
    local skill_name
    local -a rsync_cmd=(rsync -a --delete)

    if ! command -v rsync >/dev/null 2>&1; then
        die "rsync not found; the mirror step requires rsync (macOS: xcode-select --install, Debian/Ubuntu: apt install rsync). Re-run with --skip-mirror to update the runtime only."
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        rsync_cmd+=(--dry-run --itemize-changes)
    fi

    run_cmd mkdir -p "$destination_root"

    for skill_name in "${REQUESTED_SKILLS[@]}"; do
        [[ -d "$SOURCE_DIR/$skill_name" ]] || die "Requested skill not found: $SOURCE_DIR/$skill_name"
        run_cmd "${rsync_cmd[@]}" "$SOURCE_DIR/$skill_name/" "$destination_root/$skill_name/"
    done
}

if [[ $SKIP_RUNTIME -eq 0 ]]; then
    if command_exists openclaw; then
        if [[ $DRY_RUN -eq 1 ]]; then
            run_cmd openclaw update --dry-run
        else
            run_cmd openclaw update
        fi
    else
        echo "WARN: openclaw not found; skipping runtime update" >&2
    fi
fi

if [[ $SKIP_CLAWHUB -eq 0 ]]; then
    if command_exists clawhub; then
        if [[ ${#WORKSPACES[@]} -gt 0 ]]; then
            for workspace in "${WORKSPACES[@]}"; do
                if [[ -f "$workspace/.clawhub/lock.json" ]]; then
                    if [[ $DRY_RUN -eq 1 ]]; then
                        run_cmd clawhub update --all --workdir "$workspace" --no-input
                    else
                        run_cmd clawhub update --all --workdir "$workspace"
                    fi
                fi
            done
        fi
    else
        echo "WARN: clawhub not found; skipping registry skill updates" >&2
    fi
fi

if [[ $SKIP_MIRROR -eq 0 ]]; then
    if [[ $DRY_RUN -eq 0 && $CONFIRM -eq 0 ]]; then
        echo "REFUSING destructive mirror: this mirrors with 'rsync -a --delete', which" >&2
        echo "removes any file in a destination skill dir that is absent from the source." >&2
        echo "Affected destinations:" >&2
        mirror_destinations | sed 's/^/  /' >&2
        echo "Preview a plan first with --dry-run, then rerun with --yes to apply" >&2
        echo "(or pass --skip-mirror to skip local mirroring entirely)." >&2
        exit 1
    fi

    if [[ $DRY_RUN -eq 0 ]]; then
        echo "WARNING: applying destructive mirror (rsync -a --delete) to:" >&2
        mirror_destinations | sed 's/^/  /' >&2
        echo "Any file present in a destination but missing from the source will be deleted." >&2
    fi

    while IFS= read -r destination; do
        mirror_selected_skills "$destination"
    done < <(mirror_destinations)
fi

if [[ $DRY_RUN -eq 0 && $SKIP_DOCTOR -eq 0 ]] && command_exists openclaw; then
    run_cmd openclaw doctor
fi

echo "OpenClaw update workflow complete"
