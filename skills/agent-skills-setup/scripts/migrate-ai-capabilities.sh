#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR=""
WORKSPACE_ROOT="$(pwd)"
PLATFORMS_RAW=""
OBJECTS_RAW="capabilities,prompts,configurations,rules,workflows,hooks,agents"
STRATEGY="backup"
WRITE_MODE="staging"
ALLOW_MISSING_OBJECTS=0
DRY_RUN=0

PLATFORMS=()
OBJECTS=()

usage() {
    cat <<'EOF'
Usage: migrate-ai-capabilities.sh --source <dir> --platforms <list> [options]

Migrate AI Assistant Capabilities between IDE project layouts.
This script is project-safe by default: it writes into a workspace root instead
of mutating user-global home config directories.

Options:
  --source <dir>          Canonical capability-pack source directory.
                          Expected folders: capabilities/ (or skills/), prompts/,
                          configurations/, rules/, workflows/, hooks/, agents/.
    --platforms <list>      Target platforms:
                                                    copilot,cursor,windsurf,jetbrains,claude,codex,openclaw,trae,trae-cn.
  --objects <list>        Objects to migrate. Default:
                          capabilities,prompts,configurations,rules,workflows,hooks,agents
  --workspace-root <dir>  Root path where platform layouts are materialized.
                          Default: current directory.
  --strategy <mode>       skip | overwrite | backup (default: backup)
    --write-mode <mode>     staging | direct (default: staging)
                                                    staging writes to .migration-targets/<platform>/...
                                                    direct writes to live workspace paths.
    --allow-missing-objects Continue when selected objects are missing in source.
                                                    Default behavior is fail-fast for correctness.
  --dry-run               Print actions only.
  -h, --help              Show this help text.

Examples:
  bash migrate-ai-capabilities.sh \
    --source ./capability-pack \
    --platforms copilot,cursor,windsurf,claude,codex \
    --workspace-root ./migration-out \
    --strategy backup \
    --write-mode staging

  bash migrate-ai-capabilities.sh \
    --source ./capability-pack \
    --platforms openclaw,jetbrains \
    --objects capabilities,configurations,rules \
    --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            SOURCE_DIR="$2"
            shift 2
            ;;
        --platforms)
            PLATFORMS_RAW="$2"
            shift 2
            ;;
        --objects)
            OBJECTS_RAW="$2"
            shift 2
            ;;
        --workspace-root)
            WORKSPACE_ROOT="$2"
            shift 2
            ;;
        --strategy)
            STRATEGY="$2"
            shift 2
            ;;
        --write-mode)
            WRITE_MODE="$2"
            shift 2
            ;;
        --allow-missing-objects)
            ALLOW_MISSING_OBJECTS=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
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

if [[ -z "$SOURCE_DIR" || -z "$PLATFORMS_RAW" ]]; then
    echo "ERROR: --source and --platforms are required" >&2
    usage >&2
    exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "ERROR: Source directory not found: $SOURCE_DIR" >&2
    exit 1
fi

case "$STRATEGY" in
    skip|overwrite|backup)
        ;;
    *)
        echo "ERROR: Unsupported strategy: $STRATEGY" >&2
        exit 1
        ;;
esac

case "$WRITE_MODE" in
    staging|direct)
        ;;
    *)
        echo "ERROR: Unsupported write mode: $WRITE_MODE" >&2
        exit 1
        ;;
esac

split_csv() {
    local raw="$1"
    local old_ifs="$IFS"

    IFS=',' read -r -a SPLIT_RESULT <<< "$raw"
    IFS="$old_ifs"
}

split_csv "$PLATFORMS_RAW"
PLATFORMS=("${SPLIT_RESULT[@]}")

split_csv "$OBJECTS_RAW"
OBJECTS=("${SPLIT_RESULT[@]}")

validate_platforms() {
    local item

    for item in "${PLATFORMS[@]}"; do
        case "$item" in
            copilot|cursor|windsurf|jetbrains|claude|codex|openclaw|trae|trae-cn)
                ;;
            *)
                echo "ERROR: Unsupported platform: $item" >&2
                exit 1
                ;;
        esac
    done
}

validate_objects() {
    local item

    for item in "${OBJECTS[@]}"; do
        case "$item" in
            capabilities|prompts|configurations|rules|workflows|hooks|agents)
                ;;
            *)
                echo "ERROR: Unsupported object type: $item" >&2
                exit 1
                ;;
        esac
    done
}

validate_platforms
validate_objects

resolve_object_source() {
    local object_name="$1"

    case "$object_name" in
        capabilities)
            if [[ -d "$SOURCE_DIR/capabilities" ]]; then
                echo "$SOURCE_DIR/capabilities"
            elif [[ -d "$SOURCE_DIR/skills" ]]; then
                echo "$SOURCE_DIR/skills"
            else
                echo ""
            fi
            ;;
        prompts)
            [[ -d "$SOURCE_DIR/prompts" ]] && echo "$SOURCE_DIR/prompts" || echo ""
            ;;
        configurations)
            if [[ -d "$SOURCE_DIR/configurations" ]]; then
                echo "$SOURCE_DIR/configurations"
            elif [[ -d "$SOURCE_DIR/config" ]]; then
                echo "$SOURCE_DIR/config"
            else
                echo ""
            fi
            ;;
        rules)
            [[ -d "$SOURCE_DIR/rules" ]] && echo "$SOURCE_DIR/rules" || echo ""
            ;;
        workflows)
            [[ -d "$SOURCE_DIR/workflows" ]] && echo "$SOURCE_DIR/workflows" || echo ""
            ;;
        hooks)
            [[ -d "$SOURCE_DIR/hooks" ]] && echo "$SOURCE_DIR/hooks" || echo ""
            ;;
        agents)
            [[ -d "$SOURCE_DIR/agents" ]] && echo "$SOURCE_DIR/agents" || echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}

resolve_destination() {
    local platform="$1"
    local object_name="$2"

    case "$platform" in
        copilot)
            case "$object_name" in
                capabilities) echo ".github/skills" ;;
                prompts) echo ".github/prompts" ;;
                configurations) echo ".vscode/copilot-config" ;;
                rules) echo ".github/instructions" ;;
                workflows) echo ".github/workflows/ai" ;;
                hooks) echo ".github/hooks" ;;
                agents) echo ".github/agents" ;;
            esac
            ;;
        cursor)
            case "$object_name" in
                capabilities) echo ".cursor/skills" ;;
                prompts) echo ".cursor/prompts" ;;
                configurations) echo ".cursor/config" ;;
                rules) echo ".cursor/rules" ;;
                workflows) echo ".cursor/workflows" ;;
                hooks) echo ".cursor/hooks" ;;
                agents) echo ".cursor/agents" ;;
            esac
            ;;
        windsurf)
            case "$object_name" in
                capabilities) echo ".windsurf/skills" ;;
                prompts) echo ".windsurf/prompts" ;;
                configurations) echo ".windsurf/config" ;;
                rules) echo ".windsurf/rules" ;;
                workflows) echo ".windsurf/workflows" ;;
                hooks) echo ".windsurf/hooks" ;;
                agents) echo ".windsurf/agents" ;;
            esac
            ;;
        jetbrains)
            case "$object_name" in
                capabilities) echo ".idea/ai-capabilities/skills" ;;
                prompts) echo ".idea/ai-capabilities/prompts" ;;
                configurations) echo ".idea/ai-capabilities/config" ;;
                rules) echo ".idea/ai-capabilities/rules" ;;
                workflows) echo ".idea/ai-capabilities/workflows" ;;
                hooks) echo ".idea/ai-capabilities/hooks" ;;
                agents) echo ".idea/ai-capabilities/agents" ;;
            esac
            ;;
        claude)
            case "$object_name" in
                capabilities) echo ".claude/skills" ;;
                prompts) echo ".claude/prompts" ;;
                configurations) echo ".claude/config" ;;
                rules) echo ".claude/rules" ;;
                workflows) echo ".claude/workflows" ;;
                hooks) echo ".claude/hooks" ;;
                agents) echo ".claude/agents" ;;
            esac
            ;;
        codex)
            case "$object_name" in
                capabilities) echo ".agents/skills" ;;
                prompts) echo ".codex/prompts" ;;
                configurations) echo ".codex/config" ;;
                rules) echo ".codex/rules" ;;
                workflows) echo ".codex/workflows" ;;
                hooks) echo ".codex/hooks" ;;
                agents) echo ".codex/agents" ;;
            esac
            ;;
        openclaw)
            case "$object_name" in
                capabilities) echo "skills" ;;
                prompts) echo "openclaw/prompts" ;;
                configurations) echo "openclaw/config" ;;
                rules) echo "openclaw/rules" ;;
                workflows) echo "openclaw/workflows" ;;
                hooks) echo "openclaw/hooks" ;;
                agents) echo "openclaw/agents" ;;
            esac
            ;;
        trae)
            case "$object_name" in
                capabilities) echo ".trae/skills" ;;
                prompts) echo ".trae/prompts" ;;
                configurations) echo ".trae/config" ;;
                rules) echo ".trae/rules" ;;
                workflows) echo ".trae/workflows" ;;
                hooks) echo ".trae/hooks" ;;
                agents) echo ".trae/agents" ;;
            esac
            ;;
        trae-cn)
            case "$object_name" in
                capabilities) echo ".trae-cn/skills" ;;
                prompts) echo ".trae-cn/prompts" ;;
                configurations) echo ".trae-cn/config" ;;
                rules) echo ".trae-cn/rules" ;;
                workflows) echo ".trae-cn/workflows" ;;
                hooks) echo ".trae-cn/hooks" ;;
                agents) echo ".trae-cn/agents" ;;
            esac
            ;;
        *)
            echo ""
            ;;
    esac
}

materialize_destination() {
    local platform="$1"
    local relative_path="$2"

    if [[ "$WRITE_MODE" == "direct" ]]; then
        echo "$WORKSPACE_ROOT/$relative_path"
    else
        echo "$WORKSPACE_ROOT/.migration-targets/$platform/$relative_path"
    fi
}

copy_tree() {
    local source_path="$1"
    local destination_path="$2"

    if [[ -e "$destination_path" ]]; then
        case "$STRATEGY" in
            skip)
                echo "SKIP: $destination_path (already exists)"
                return 0
                ;;
            overwrite)
                if [[ $DRY_RUN -eq 1 ]]; then
                    echo "DRY-RUN: rm -rf $destination_path"
                else
                    rm -rf "$destination_path"
                fi
                ;;
            backup)
                local timestamp
                timestamp="$(date +%Y%m%d%H%M%S)"
                if [[ $DRY_RUN -eq 1 ]]; then
                    echo "DRY-RUN: mv $destination_path ${destination_path}.bak.${timestamp}"
                else
                    mv "$destination_path" "${destination_path}.bak.${timestamp}"
                fi
                ;;
        esac
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "DRY-RUN: mkdir -p $destination_path"
        echo "DRY-RUN: rsync -a --delete $source_path/ $destination_path/"
    else
        mkdir -p "$destination_path"
        rsync -a --delete "$source_path/" "$destination_path/"
    fi
}

MIGRATED_COUNT=0
SKIPPED_COUNT=0
ERROR_COUNT=0

echo "Source: $SOURCE_DIR"
echo "Workspace root: $WORKSPACE_ROOT"
echo "Platforms: ${PLATFORMS[*]}"
echo "Objects: ${OBJECTS[*]}"
echo "Strategy: $STRATEGY"
echo "Write mode: $WRITE_MODE"
[[ $ALLOW_MISSING_OBJECTS -eq 1 ]] && echo "Missing objects: allowed"
[[ $DRY_RUN -eq 1 ]] && echo "Mode: dry-run"

for platform in "${PLATFORMS[@]}"; do
    echo ""
    echo "==> Platform: $platform"

    for object_name in "${OBJECTS[@]}"; do
        source_path="$(resolve_object_source "$object_name")"
        destination_relative="$(resolve_destination "$platform" "$object_name")"

        if [[ -z "$source_path" ]]; then
            if [[ $ALLOW_MISSING_OBJECTS -eq 1 ]]; then
                echo "WARN: missing source object '$object_name' in $SOURCE_DIR"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            else
                echo "ERROR: missing source object '$object_name' in $SOURCE_DIR" >&2
                ERROR_COUNT=$((ERROR_COUNT + 1))
            fi
            continue
        fi

        if [[ -z "$destination_relative" ]]; then
            echo "ERROR: no destination mapping for $platform/$object_name" >&2
            ERROR_COUNT=$((ERROR_COUNT + 1))
            continue
        fi

        destination_path="$(materialize_destination "$platform" "$destination_relative")"

        echo "MIGRATE: $object_name -> $destination_path"
        copy_tree "$source_path" "$destination_path"
        MIGRATED_COUNT=$((MIGRATED_COUNT + 1))
    done

done

echo ""
echo "Completed migration operations: $MIGRATED_COUNT"
echo "Skipped operations: $SKIPPED_COUNT"
echo "Errors: $ERROR_COUNT"

if [[ $ERROR_COUNT -gt 0 ]]; then
    exit 1
fi

echo ""
echo "Next steps:"
echo "1. Run validate-capability-migration.sh against the workspace root"
echo "2. Manually review configuration and hook files for each target IDE"
echo "3. Execute platform-specific smoke tests before publishing"
