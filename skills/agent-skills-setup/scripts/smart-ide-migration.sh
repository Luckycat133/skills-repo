#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SOURCE_IDE=""
TARGET_IDE=""
WORKSPACE_ROOT="$(pwd)"
OBJECTS=""
STRATEGY="backup"
DRY_RUN=0
ASSUME_YES=0
REPORT_FILE=""
PRINT_PATH_IDE=""
PRINT_PATH_OBJECT=""

SUPPORTED_IDES="antigravity claude claude-desktop codex copilot cursor windsurf jetbrains openclaw trae trae-cn vscode zed neovim emacs continue aider roo-code cline amazon-q cody codeium tabnine replit pearai supermaven pieces blackbox gemini-cli goose-cli opencode kilocode kimiai workbuddy kiro augment-code void-editor baidu-comate tencent-codebuddy zcode"

MIGRATION_TOTAL=0
MIGRATION_SUCCESS=0
MIGRATION_FAILED=0
MIGRATION_SKIPPED=0

MIGRATION_STATUS_FILE=""
MIGRATION_MESSAGES_FILE=""
MIGRATION_MANUAL_FILE=""

get_ide_name() {
    local ide="$1"
    case "$ide" in
        antigravity) echo "Antigravity (Google)" ;;
        claude)      echo "Claude Code" ;;
        codex)       echo "OpenAI Codex CLI" ;;
        copilot)     echo "GitHub Copilot CLI" ;;
        cursor)      echo "Cursor" ;;
        windsurf)    echo "Windsurf" ;;
        jetbrains)   echo "JetBrains Junie" ;;
        openclaw)    echo "OpenClaw" ;;
        trae)        echo "Trae (International)" ;;
        trae-cn)     echo "Trae CN (China)" ;;
        vscode)      echo "VS Code" ;;
        zed)         echo "Zed Editor" ;;
        neovim)      echo "Neovim" ;;
        emacs)       echo "Emacs" ;;
        continue)    echo "Continue.dev" ;;
        aider)       echo "Aider" ;;
        roo-code)    echo "Roo Code" ;;
        cline)       echo "Cline" ;;
        amazon-q)    echo "Amazon Q Developer" ;;
        cody)        echo "Sourcegraph Cody" ;;
        codeium)     echo "Codeium" ;;
        tabnine)     echo "Tabnine" ;;
        replit)      echo "Replit AI" ;;
        pearai)      echo "PearAI" ;;
        supermaven)  echo "Supermaven" ;;
        pieces)      echo "Pieces" ;;
        blackbox)    echo "Blackbox AI" ;;
        gemini-cli)  echo "Gemini CLI" ;;
        goose-cli)   echo "Goose CLI" ;;
        opencode)    echo "OpenCode" ;;
        kilocode)    echo "Kilocode" ;;
        kimiai)      echo "Kimi AI" ;;
        workbuddy)   echo "WorkBuddy" ;;
        claude-desktop)    echo "Claude Desktop" ;;
        kiro)              echo "Kiro" ;;
        augment-code)      echo "Augment Code" ;;
        void-editor)       echo "Void Editor" ;;
        baidu-comate)      echo "Baidu Comate (文心快码)" ;;
        tencent-codebuddy) echo "Tencent CodeBuddy" ;;
        zcode)             echo "ZCode (智谱)" ;;
        *)           echo "$ide" ;;
    esac
}

# SOURCE OF TRUTH: skills/agent-skills-setup/references/ide-registry.md (and ide-paths.json).
# Keep these functions in sync with that file. Drift is caught by test-ide-paths.sh.
get_global_path() {
    local ide="$1"
    case "$ide" in
        antigravity) echo "${HOME}/.gemini/config/skills" ;;
        claude)      echo "${HOME}/.claude/skills" ;;
        codex)       echo "${HOME}/.agents/skills" ;;
        copilot)     echo "${HOME}/.copilot/skills" ;;
        cursor)      echo "${HOME}/.cursor/skills" ;;
        windsurf)    echo "${HOME}/.windsurf/skills" ;;
        # jetbrains (Junie): no documented global skills dir (~/.junie/ holds
        # mcp + guidelines only) — empty avoids creating a bogus ~/.idea dir.
        jetbrains)   echo "" ;;
        openclaw)    echo "${HOME}/.openclaw/skills" ;;
        trae)        echo "${HOME}/.trae/skills" ;;
        trae-cn)     echo "${HOME}/.trae-cn/skills" ;;
        vscode)      echo "${HOME}/.vscode" ;;
        zed)         echo "${HOME}/.config/zed" ;;
        neovim)      echo "${HOME}/.config/nvim" ;;
        emacs)       echo "${HOME}/.emacs.d" ;;
        continue)    echo "${HOME}/.continue" ;;
        aider)       echo "${HOME}/.aider" ;;
        roo-code)    echo "${HOME}/.roo" ;;
        cline)       echo "${HOME}/.cline" ;;
        amazon-q)    echo "${HOME}/.aws/amazonq" ;;
        # cody/codeium/tabnine/blackbox: no stable global skills directory.
        # Returning "" avoids emitting glob literals (e.g. sourcegraph.cody*)
        # that would otherwise be turned into illegal directory names by mkdir -p.
        cody)        echo "" ;;
        codeium)     echo "" ;;
        tabnine)     echo "" ;;
        replit)      echo "${HOME}/.replit" ;;
        pearai)      echo "${HOME}/.pearai" ;;
        supermaven)  echo "${HOME}/.supermaven" ;;
        pieces)      echo "${HOME}/.pieces" ;;
        blackbox)    echo "" ;;
        gemini-cli)  echo "${HOME}/.gemini" ;;
        goose-cli)   echo "${HOME}/.config/goose" ;;
        opencode)    echo "${HOME}/.config/opencode" ;;
        kilocode)    echo "${HOME}/.config/kilo" ;;
        kimiai)      echo "${HOME}/.kimi-code/skills" ;;
        workbuddy)   echo "${HOME}/.workbuddy/skills" ;;
        # claude-desktop is MCP-only (no skills dir).
        claude-desktop)    echo "" ;;
        kiro)              echo "${HOME}/.kiro/steering" ;;
        augment-code)      echo "${HOME}/.augment/skills" ;;
        void-editor)       echo "" ;;
        baidu-comate)      echo "${HOME}/.comate/skills" ;;
        tencent-codebuddy) echo "${HOME}/.codebuddy/skills" ;;
        zcode)             echo "${HOME}/.zcode/skills" ;;
        *)           echo "" ;;
    esac
}

get_project_path() {
    local ide="$1"
    # Returns the project-level path for an IDE. NOTE: this may be a DIRECTORY
    # (e.g. .vscode, skills, .cursor) OR a FILE (e.g. .dir-locals.el,
    # .aider.conf.yml, .github/copilot-instructions.md). Callers that create
    # paths must guard against file-type returns: use
    # `mkdir -p "$(dirname "$path")"` for files, never `mkdir -p "$path"` on a
    # file path.
    case "$ide" in
        antigravity) echo ".agents/skills" ;;
        claude)      echo ".claude" ;;
        codex)       echo ".codex" ;;
        copilot)     echo ".github/copilot-instructions.md" ;;
        cursor)      echo ".cursor" ;;
        windsurf)    echo ".windsurf" ;;
        jetbrains)   echo ".junie" ;;
        openclaw)    echo "skills" ;;
        trae)        echo ".trae" ;;
        trae-cn)     echo ".trae" ;;
        vscode)      echo ".vscode" ;;
        zed)         echo ".zed" ;;
        neovim)      echo ".nvim" ;;
        emacs)       echo ".dir-locals.el" ;;
        continue)    echo ".continue" ;;
        aider)       echo ".aider.conf.yml" ;;
        roo-code)    echo ".roo" ;;
        cline)       echo ".cline" ;;
        amazon-q)    echo ".amazon-q" ;;
        cody)        echo ".cody" ;;
        codeium)     echo ".codeium" ;;
        tabnine)     echo ".tabnine" ;;
        replit)      echo ".replit" ;;
        pearai)      echo ".pearai" ;;
        supermaven)  echo ".supermaven" ;;
        pieces)      echo ".pieces" ;;
        blackbox)    echo ".blackbox" ;;
        gemini-cli)  echo ".gemini" ;;
        goose-cli)   echo ".goose" ;;
        opencode)    echo ".opencode" ;;
        kilocode)    echo ".kilocode" ;;
        kimiai)      echo ".kimi-code/skills" ;;
        workbuddy)   echo ".workbuddy/skills" ;;
        claude-desktop)    echo "" ;;  # desktop app: no project-level config
        kiro)              echo ".kiro" ;;
        augment-code)      echo ".augment" ;;
        void-editor)       echo ".void" ;;
        baidu-comate)      echo ".comate" ;;
        tencent-codebuddy) echo ".codebuddy" ;;
        zcode)             echo ".zcode" ;;
        *)           echo "" ;;
    esac
}

get_rules_file() {
    local ide="$1"
    case "$ide" in
        cursor)      echo ".cursorrules" ;;
        windsurf)    echo ".windsurfrules" ;;
        copilot)     echo ".github/copilot-instructions.md" ;;
        openclaw)    echo "AGENT_RULES.md" ;;
        claude)      echo "CLAUDE.md" ;;
        aider)       echo "CONVENTIONS.md" ;;
        cline)       echo ".clinerules" ;;
        # continue: rules live in .continue/rules/*.md (directory) or a
        # single CONTINUE.md at project root — use the single-file form here.
        continue)    echo "CONTINUE.md" ;;
        roo-code)    echo ".roorules" ;;
        cody)        echo ".codyrules" ;;
        pearai)      echo ".pearairules" ;;
        codex)       echo "AGENTS.md" ;;
        gemini-cli)  echo "GEMINI.md" ;;
        goose-cli)   echo ".goosehints" ;;
        opencode)    echo "AGENTS.md" ;;
        kimiai)      echo "AGENTS.md" ;;
        zed)         echo "AGENTS.md" ;;
        zcode)       echo "AGENTS.md" ;;
        antigravity) echo "AGENTS.md" ;;
        jetbrains)   echo ".junie/guidelines.md" ;;
        void-editor) echo ".voidrules" ;;
        tencent-codebuddy) echo "CODEBUDDY.md" ;;
        # kilocode rules are DIRECTORIES (.kilocode/rules/ or .kilo/rules/),
        # not a single file — intentionally absent here (like kiro/augment).
        # kiro/augment-code/baidu-comate use rules DIRECTORIES
        # (.kiro/steering/, .augment/rules/, .comate/rules/*.mdr) — not a
        # single file, so they are intentionally absent here.
        *)           echo "" ;;
    esac
}

get_prompts_path() {
    local ide="$1"
    case "$ide" in
        cursor)      echo ".cursor/commands" ;;
        windsurf)    echo ".windsurf/workflows" ;;
        copilot)     echo ".github/prompts" ;;
        openclaw)    echo ".github/prompts" ;;
        continue)    echo ".continue/prompts" ;;
        cline)       echo ".cline/prompts" ;;
        claude)      echo ".claude/commands" ;;
        gemini-cli)  echo ".gemini/commands" ;;
        goose-cli)   echo ".goose/prompts" ;;
        *)           echo "" ;;
    esac
}

get_mcp_path() {
    local ide="$1"
    case "$ide" in
        # trae/trae-cn: global MCP lives under the editor's user-data dir
        # (NOT ~/.trae*/mcps — that path never existed in Trae docs).
        trae)
            if [[ "$(uname -s)" == "Darwin" ]]; then
                echo "${HOME}/Library/Application Support/Trae/User/mcp.json"
            else
                echo "${HOME}/.config/Trae/User/mcp.json"
            fi ;;
        trae-cn)
            if [[ "$(uname -s)" == "Darwin" ]]; then
                echo "${HOME}/Library/Application Support/Trae CN/User/mcp.json"
            else
                echo "${HOME}/.config/Trae CN/User/mcp.json"
            fi ;;
        openclaw)    echo "${HOME}/.openclaw/openclaw.json" ;;
        claude)      echo "${HOME}/.claude.json" ;;
        # continue: config.yaml replaced config.json (mcpServers is an ARRAY
        # of {name,type,command,args,env} — convert_mcp_file falls back to
        # copy+manual for YAML targets, so no array conversion is attempted).
        continue)    echo "${HOME}/.continue/config.yaml" ;;
        cline)       echo "${HOME}/.cline/mcp.json" ;;
        cursor)      echo "${HOME}/.cursor/mcp.json" ;;
        # roo-code: global MCP sits in the VS Code extension's globalStorage.
        roo-code)
            if [[ "$(uname -s)" == "Darwin" ]]; then
                echo "${HOME}/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json"
            else
                echo "${HOME}/.config/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json"
            fi ;;
        windsurf)    echo "${HOME}/.codeium/windsurf/mcp_config.json" ;;
        jetbrains)   echo "${HOME}/.junie/mcp/mcp.json" ;;
        antigravity) echo "${HOME}/.gemini/config/mcp_config.json" ;;
        # kilocode has NO global MCP file — project-level .kilocode/mcp.json
        # only (resolved against the workspace root by callers via -e check).
        kilocode)    echo ".kilocode/mcp.json" ;;
        gemini-cli)  echo "${HOME}/.gemini/settings.json" ;;
        goose-cli)   echo "${HOME}/.config/goose/config.yaml" ;;
        codex)       echo "${HOME}/.codex" ;;
        aider)       echo "${HOME}/.aider.conf.yml" ;;
        kimiai)      echo "${HOME}/.kimi-code/mcp.json" ;;
        workbuddy)   echo "${HOME}/.workbuddy/.mcp.json" ;;
        # copilot = GitHub Copilot CLI: ~/.copilot/mcp-config.json, root key
        # mcpServers (project .mcp.json ALSO uses mcpServers, unlike VS Code).
        copilot)     echo "${HOME}/.copilot/mcp-config.json" ;;
        # vscode = VS Code (v1.102+): user-level mcp.json, root key `servers`.
        vscode)
            if [[ "$(uname -s)" == "Darwin" ]]; then
                echo "${HOME}/Library/Application Support/Code/User/mcp.json"
            else
                echo "${HOME}/.config/Code/User/mcp.json"
            fi ;;
        zed)         echo "${HOME}/.config/zed/settings.json" ;;
        opencode)    echo "${HOME}/.config/opencode/opencode.json" ;;
        amazon-q)    echo "${HOME}/.aws/amazonq/default.json" ;;
        pearai)      echo "${HOME}/.pearai/config.json" ;;
        cody)        echo "${HOME}/.config/cody/mcp_servers.json" ;;
        tabnine)     echo "${HOME}/.tabnine/mcp_servers.json" ;;
        claude-desktop)
            if [[ "$(uname -s)" == "Darwin" ]]; then
                echo "${HOME}/Library/Application Support/Claude/claude_desktop_config.json"
            else
                echo "${HOME}/.config/Claude/claude_desktop_config.json"
            fi ;;
        kiro)              echo "${HOME}/.kiro/settings/mcp.json" ;;
        augment-code)      echo "${HOME}/.augment/settings.json" ;;
        void-editor)       echo "${HOME}/.config/void/mcp_servers.json" ;;
        baidu-comate)      echo "${HOME}/.comate/mcp.json" ;;
        tencent-codebuddy) echo "${HOME}/.codebuddy/.mcp.json" ;;
        zcode)             echo "${HOME}/.zcode/cli/config.json" ;;
        *)           echo "" ;;
    esac
}

get_config_file() {
    local ide="$1"
    case "$ide" in
        trae)        echo "${HOME}/.trae/argv.json" ;;
        trae-cn)     echo "${HOME}/.trae-cn/argv.json" ;;
        openclaw)    echo "${HOME}/.openclaw/openclaw.json" ;;
        # cursor: user settings live in the editor's user-data dir (VS Code
        # fork layout), NOT ~/.cursor/settings.json.
        cursor)
            if [[ "$(uname -s)" == "Darwin" ]]; then
                echo "${HOME}/Library/Application Support/Cursor/User/settings.json"
            else
                echo "${HOME}/.config/Cursor/User/settings.json"
            fi ;;
        # windsurf: no documented standalone settings file (config lives in
        # ~/.codeium/windsurf/) — empty prevents inventing one.
        windsurf)    echo "" ;;
        vscode)
            if [[ "$(uname -s)" == "Darwin" ]]; then
                echo "${HOME}/Library/Application Support/Code/User/settings.json"
            else
                echo "${HOME}/.config/Code/User/settings.json"
            fi ;;
        zed)         echo "${HOME}/.config/zed/settings.json" ;;
        neovim)      echo "${HOME}/.config/nvim/init.lua" ;;
        emacs)       echo "${HOME}/.emacs.d/init.el" ;;
        continue)    echo "${HOME}/.continue/config.yaml" ;;
        aider)       echo "${HOME}/.aider.conf.yml" ;;
        cline)       echo "${HOME}/.cline/config.json" ;;
        # roo-code: no standalone global config file documented (settings sit
        # in VS Code extension storage) — empty prevents inventing one.
        roo-code)    echo "" ;;
        claude)      echo "${HOME}/.claude/settings.json" ;;
        replit)      echo "${HOME}/.replit/replit.nix" ;;
        pearai)      echo "${HOME}/.pearai/config.json" ;;
        gemini-cli)  echo "${HOME}/.gemini/settings.json" ;;
        goose-cli)   echo "${HOME}/.config/goose/config.yaml" ;;
        codex)       echo "${HOME}/.codex" ;;
        opencode)    echo "${HOME}/.config/opencode/opencode.json" ;;
        kilocode)    echo "${HOME}/.config/kilo/kilo.jsonc" ;;
        kimiai)      echo "${HOME}/.kimi-code/config.toml" ;;
        workbuddy)   echo "${HOME}/.workbuddy/settings.json" ;;
        tencent-codebuddy) echo "${HOME}/.codebuddy/settings.json" ;;
        augment-code)      echo "${HOME}/.augment/settings.json" ;;
        zcode)             echo "${HOME}/.zcode/cli/config.json" ;;
        *)           echo "" ;;
    esac
}

# Returns the MCP server map root key used by an IDE's MCP config file.
# Mirrors the IDE Registry (mcpServers | servers | context_servers |
# mcp.servers | mcp | extensions). Used by convert_mcp_file to map between
# source and target formats.
get_mcp_root_key() {
    local ide="$1"
    case "$ide" in
        claude|cursor|windsurf|gemini-cli|trae|trae-cn|openclaw|continue|cline|roo-code|antigravity|amazon-q|kimiai|workbuddy|copilot|claude-desktop|kiro|augment-code|void-editor|baidu-comate|tencent-codebuddy|pearai|cody|tabnine|jetbrains|kilocode)
            echo "mcpServers" ;;
        codex)       echo "mcp_servers" ;;
        goose-cli)   echo "extensions" ;;
        zed)         echo "context_servers" ;;
        opencode)    echo "mcp" ;;
        # VS Code user-level mcp.json uses `servers` (NOT mcpServers).
        vscode)      echo "servers" ;;
        # zcode natively nests under mcp.servers (dot-path), but it also
        # accepts a flat mcpServers key (import-compat), which is what
        # convert_mcp_file can produce with a single top-level key.
        zcode)       echo "mcpServers" ;;
        *)           echo "" ;;
    esac
}

usage() {
    cat <<'EOF'
IDE Migration Tool - 在不同AI IDE之间迁移配置

用法: smart-ide-migration.sh [选项]

必选参数:
  --source <ide>         源IDE (从哪个IDE迁移)
  --target <ide>         目标IDE (迁移到哪个IDE)

可选参数:
  --workspace <dir>      工作区根目录 (默认: 当前目录)
  --objects <list>       要迁移的内容类型 (逗号分隔)
  --strategy <mode>      迁移策略: skip, overwrite, backup (默认: backup)
  --report <file>        保存迁移报告到文件
  --dry-run              预览模式，不实际修改文件
  --yes, -y              确认写入。非 dry-run 时必须显式确认：
                          交互式终端会提示 [y/N]；非交互环境（CI/agent）缺少
                          --yes 将直接中止且不写任何文件
  --print-path <ide> <object>
                          只读诊断：打印指定IDE/对象类型的解析路径并退出(无副作用)
                          object ∈ global|project|mcp|config|rules
  -h, --help             显示帮助信息

支持的IDE:
  antigravity  - Antigravity
  claude       - Claude Code
  codex        - OpenAI Codex CLI
  copilot      - VS Code Copilot
  cursor       - Cursor
  windsurf     - Windsurf
  jetbrains    - JetBrains IDEs
  openclaw     - OpenClaw
  trae         - Trae (国际版)
  trae-cn      - Trae CN (中国版)
  vscode       - VS Code
  zed          - Zed Editor
  neovim       - Neovim
  emacs        - Emacs
  continue     - Continue.dev
  aider        - Aider
  roo-code     - Roo Code
  cline        - Cline
  amazon-q     - Amazon Q Developer
  cody         - Sourcegraph Cody
  codeium      - Codeium
  tabnine      - Tabnine
  replit       - Replit AI
  pearai       - PearAI
  supermaven   - Supermaven
  pieces       - Pieces
  blackbox     - Blackbox AI

支持的CLI工具:
  gemini-cli   - Gemini CLI (Google)
  goose-cli    - Goose CLI (Block)
  opencode     - OpenCode
  kilocode     - Kilocode
  kimiai       - Kimi AI CLI
  workbuddy    - WorkBuddy

内容类型:
  skills       - 技能/Skills (SKILL.md)
  rules        - 规则文件 (.cursorrules, .windsurfrules等)
  prompts      - 提示词模板
  mcp          - MCP服务器配置
  config       - IDE配置文件
  project      - 项目级配置

示例 (推荐两段式: 先 --dry-run 预览, 确认后加 --yes 应用):
  smart-ide-migration.sh --source trae-cn --target claude --dry-run
  smart-ide-migration.sh --source trae-cn --target claude --yes
  smart-ide-migration.sh --source cursor --target windsurf --objects skills,rules --dry-run
  smart-ide-migration.sh --source cursor --target windsurf --objects skills,rules --yes
  smart-ide-migration.sh --source openclaw --target copilot --dry-run
EOF
}

print_header() {
    echo ""
    echo "========================================"
    echo "       IDE Migration Tool"
    echo "========================================"
    echo ""
}

print_progress() {
    local step="$1"
    local message="$2"
    echo "[${step}] ${message}"
}

# Safely remove a single skill directory nested directly under a parent dir.
# Guards against the classic `rm -rf` foot-guns before deleting anything:
#   - both the parent dir and the skill name must be non-empty (an empty
#     variable would collapse the path and risk wiping the parent or "/");
#   - the skill name must be a single path component (no "/", no "." / "..",
#     no leading dash) so it cannot escape the parent via traversal;
#   - the resolved target must exist and be a directory before removal.
# On any violation it prints an error and returns non-zero WITHOUT deleting.
safe_remove_skill_dir() {
    local parent="$1"
    local name="$2"

    if [[ -z "$parent" || -z "$name" ]]; then
        echo "  [GUARD] 拒绝删除：目标目录或技能名为空 (parent='$parent', name='$name')" >&2
        return 1
    fi
    case "$name" in
        */*|.|..|.*/*|-*)
            echo "  [GUARD] 拒绝删除：非法技能名 '$name'（禁止路径分隔符/穿越/前导短横线）" >&2
            return 1
            ;;
    esac

    local target="$parent/$name"
    if [[ -L "$target" ]]; then
        # A symlink here could point outside the parent; unlink only the link.
        rm -f "$target"
        return 0
    fi
    if [[ ! -d "$target" ]]; then
        echo "  [GUARD] 跳过删除：目标不是目录或不存在 '$target'" >&2
        return 1
    fi

    rm -rf "$target"
}

validate_ide() {
    local ide="$1"
    local supported

    for supported in $SUPPORTED_IDES; do
        [[ "$ide" == "$supported" ]] && return 0
    done

    return 1
}

list_available_objects() {
    local source_ide="$1"
    local objects=""

    # Source-resolution rule (single coherent rule for every object type):
    #   - skills, mcp, config  -> user-GLOBAL location (HOME-based):
    #       get_global_path / get_mcp_path / get_config_file
    #   - rules, prompts, project -> workspace/PROJECT location (WORKSPACE_ROOT-based):
    #       get_rules_file / get_prompts_path / get_project_path
    # This keeps detection consistent: global objects are discovered from the
    # user home, project objects from the current workspace root.

    local global_path
    global_path=$(get_global_path "$source_ide")
    if [[ -d "$global_path" ]]; then
        objects+="skills,"
    fi

    local rules_file
    rules_file=$(get_rules_file "$source_ide")
    if [[ -n "$rules_file" ]] && [[ -f "$WORKSPACE_ROOT/$rules_file" ]]; then
        objects+="rules,"
    fi

    local prompts_path
    prompts_path=$(get_prompts_path "$source_ide")
    if [[ -n "$prompts_path" ]] && [[ -d "$WORKSPACE_ROOT/$prompts_path" ]]; then
        objects+="prompts,"
    fi

    local mcp_path
    mcp_path=$(get_mcp_path "$source_ide")
    # Project-relative MCP paths (e.g. kilocode .kilocode/mcp.json) resolve
    # against the workspace root, not the caller's cwd.
    if [[ -n "$mcp_path" && "$mcp_path" != /* ]]; then
        mcp_path="$WORKSPACE_ROOT/$mcp_path"
    fi
    if [[ -n "$mcp_path" ]] && [[ -e "$mcp_path" ]]; then
        objects+="mcp,"
    fi

    local config_file
    config_file=$(get_config_file "$source_ide")
    if [[ -n "$config_file" ]] && [[ -f "$config_file" ]]; then
        objects+="config,"
    fi

    local project_path
    project_path=$(get_project_path "$source_ide")
    if [[ -n "$project_path" ]] && [[ -e "$WORKSPACE_ROOT/$project_path" ]]; then
        objects+="project,"
    fi

    objects="${objects%,}"
    echo "$objects"
}

init_migration_files() {
    MIGRATION_STATUS_FILE=$(mktemp)
    MIGRATION_MESSAGES_FILE=$(mktemp)
    MIGRATION_MANUAL_FILE=$(mktemp)
}

cleanup_migration_files() {
    [[ -f "$MIGRATION_STATUS_FILE" ]] && rm -f "$MIGRATION_STATUS_FILE"
    [[ -f "$MIGRATION_MESSAGES_FILE" ]] && rm -f "$MIGRATION_MESSAGES_FILE"
    [[ -f "$MIGRATION_MANUAL_FILE" ]] && rm -f "$MIGRATION_MANUAL_FILE"
    # Always succeed: under `set -e` an EXIT-trap command that fails would
    # override an explicit `exit 0` (e.g. the read-only --print-path mode,
    # which never calls init_migration_files and leaves these vars empty).
    return 0
}

set_status() {
    local obj="$1"
    local status="$2"
    echo "$obj:$status" >> "$MIGRATION_STATUS_FILE"
}

set_message() {
    local obj="$1"
    local message="$2"
    echo "$obj:$message" >> "$MIGRATION_MESSAGES_FILE"
}

set_manual_step() {
    local obj="$1"
    local step="$2"
    echo "$obj:$step" >> "$MIGRATION_MANUAL_FILE"
}

get_status() {
    local obj="$1"
    if [[ -f "$MIGRATION_STATUS_FILE" ]]; then
        # awk with literal string compare — $obj is never treated as regex.
        awk -v o="$obj" -F: '$1 == o { sub(/^[^:]*:/, ""); print }' "$MIGRATION_STATUS_FILE" | tail -1
    fi
}

get_message() {
    local obj="$1"
    if [[ -f "$MIGRATION_MESSAGES_FILE" ]]; then
        # Parse only on the FIRST colon so values containing ':' (e.g.
        # file://... URLs or Windows C: paths) are preserved intact.
        awk -v o="$obj" -F: '$1 == o { sub(/^[^:]*:/, ""); print }' "$MIGRATION_MESSAGES_FILE" | tail -1
    fi
}

get_manual_steps() {
    local obj="$1"
    if [[ -f "$MIGRATION_MANUAL_FILE" ]]; then
        awk -v o="$obj" -F: '$1 == o { sub(/^[^:]*:/, ""); print }' "$MIGRATION_MANUAL_FILE"
    fi
}

migrate_skills() {
    local source_ide="$1"
    local target_ide="$2"
    local source_global
    source_global=$(get_global_path "$source_ide")
    local target_global
    target_global=$(get_global_path "$target_ide")

    # Guard against IDEs with no stable global skills directory (e.g.
    # cody/codeium/tabnine/blackbox return ""). Without this, `mkdir -p ""`
    # would fail under `set -e` and abort the whole script. This covers both
    # the copilot branch and the generic branch below.
    if [[ -z "$target_global" ]]; then
        set_status "skills" "skipped"
        set_message "skills" "目标IDE无全局技能目录，跳过"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    if [[ ! -d "$source_global" ]]; then
        set_status "skills" "skipped"
        set_message "skills" "源目录不存在: $source_global"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    print_progress "MIGRATE" "迁移技能 (Skills)..."

    local migrated_count=0
    local failed_count=0

    if [[ "$target_ide" == "copilot" ]]; then
        # Copilot (VS Code extension) loads skills from a directory per skill
        # name (registry: global ~/.copilot/skills/, project .github/skills/).
        # Copy the ENTIRE skill directory so scripts/ references/ assets/ are
        # preserved (consistent with CONVERT_SKILL and the non-copilot branch).
        # Never create the target directory in dry-run mode (zero writes).
        if [[ $DRY_RUN -eq 0 ]]; then
            mkdir -p "$target_global"
        fi

        local skill_dir skill_name
        for skill_dir in "$source_global"/*/; do
            [[ -d "$skill_dir" ]] || continue
            [[ -f "$skill_dir/SKILL.md" ]] || continue
            skill_name=$(basename "$skill_dir")

            if [[ -f "$skill_dir/SKILL.md" ]]; then
                if [[ $DRY_RUN -eq 1 ]]; then
                    echo "  DRY-RUN: cp -r $skill_dir $target_global/$skill_name"
                    ((migrated_count++))
                else
                    if [[ -d "$target_global/$skill_name" ]]; then
                        case "$STRATEGY" in
                            skip)
                                echo "  [SKIP] 技能已存在: $skill_name"
                                continue
                                ;;
                            backup)
                                local timestamp
                                timestamp=$(date +%Y%m%d%H%M%S)
                                mv "$target_global/$skill_name" "$target_global/$skill_name.bak.$timestamp"
                                echo "  [BACKUP] 备份已存在: $skill_name"
                                ;;
                            overwrite)
                                if ! safe_remove_skill_dir "$target_global" "$skill_name"; then
                                    echo "  [FAIL] 覆盖前安全删除失败，跳过: $skill_name"
                                    failed_count=$((failed_count + 1))
                                    continue
                                fi
                                ;;
                        esac
                    fi

                    if cp -r "$skill_dir" "$target_global/$skill_name" 2>/dev/null; then
                        echo "  [OK] 迁移技能: $skill_name"
                        ((migrated_count++))
                    else
                        echo "  [FAIL] 迁移失败: $skill_name"
                        ((failed_count++))
                    fi
                fi
            fi
        done

        set_manual_step "skills" "更新 VS Code settings.json 引用迁移的技能文件 (.github/skills/ 或 ~/.copilot/skills/)"

    else
        # Never create the target directory in dry-run mode (zero writes).
        if [[ $DRY_RUN -eq 0 ]]; then
            mkdir -p "$target_global"
        fi

        local skill_dir skill_name
        for skill_dir in "$source_global"/*/; do
            [[ -d "$skill_dir" ]] || continue
            [[ -f "$skill_dir/SKILL.md" ]] || continue
            skill_name=$(basename "$skill_dir")

            if [[ $DRY_RUN -eq 1 ]]; then
                echo "  DRY-RUN: cp -r $skill_dir $target_global/$skill_name"
                ((migrated_count++))
            else
                if [[ -d "$target_global/$skill_name" ]]; then
                    case "$STRATEGY" in
                        skip)
                            echo "  [SKIP] 技能已存在: $skill_name"
                            continue
                            ;;
                        backup)
                            local timestamp
                            timestamp=$(date +%Y%m%d%H%M%S)
                            mv "$target_global/$skill_name" "$target_global/$skill_name.bak.$timestamp"
                            echo "  [BACKUP] 备份已存在: $skill_name"
                            ;;
                        overwrite)
                            if ! safe_remove_skill_dir "$target_global" "$skill_name"; then
                                echo "  [FAIL] 覆盖前安全删除失败，跳过: $skill_name"
                                failed_count=$((failed_count + 1))
                                continue
                            fi
                            ;;
                    esac
                fi

                if cp -r "$skill_dir" "$target_global/$skill_name" 2>/dev/null; then
                    echo "  [OK] 迁移技能: $skill_name"
                    ((migrated_count++))
                else
                    echo "  [FAIL] 迁移失败: $skill_name"
                    ((failed_count++))
                fi
            fi
        done
    fi

    if [[ $failed_count -gt 0 ]]; then
        set_status "skills" "partial"
        set_message "skills" "成功 $migrated_count 个, 失败 $failed_count 个"
        MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
    else
        set_status "skills" "success"
        set_message "skills" "成功迁移 $migrated_count 个技能"
        MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
    fi
}

migrate_rules() {
    local source_ide="$1"
    local target_ide="$2"

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    local source_rules
    source_rules=$(get_rules_file "$source_ide")
    local target_rules
    target_rules=$(get_rules_file "$target_ide")

    if [[ -z "$source_rules" ]]; then
        set_status "rules" "skipped"
        set_message "rules" "源IDE不支持规则文件"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ -z "$target_rules" ]]; then
        set_status "rules" "skipped"
        set_message "rules" "目标IDE不支持规则文件"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    print_progress "MIGRATE" "迁移规则文件..."

    local source_path="$WORKSPACE_ROOT/$source_rules"
    local target_path="$WORKSPACE_ROOT/$target_rules"

    if [[ ! -f "$source_path" ]]; then
        set_status "rules" "skipped"
        set_message "rules" "源规则文件不存在: $source_rules"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  DRY-RUN: cp $source_path $target_path"
        set_status "rules" "success"
        set_message "rules" "规则文件准备迁移"
    else
        mkdir -p "$(dirname "$target_path")"
        if cp "$source_path" "$target_path" 2>/dev/null; then
            echo "  [OK] 迁移规则: $source_rules -> $target_rules"
            set_status "rules" "success"
            set_message "rules" "规则文件迁移成功"
            MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
        else
            set_status "rules" "failed"
            set_message "rules" "规则文件迁移失败"
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
        fi
    fi
}

migrate_prompts() {
    local source_ide="$1"
    local target_ide="$2"

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    local source_prompts
    source_prompts=$(get_prompts_path "$source_ide")
    local target_prompts
    target_prompts=$(get_prompts_path "$target_ide")

    if [[ -z "$source_prompts" ]]; then
        set_status "prompts" "skipped"
        set_message "prompts" "源IDE不支持提示词模板"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ -z "$target_prompts" ]]; then
        set_status "prompts" "skipped"
        set_message "prompts" "目标IDE不支持提示词模板"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    print_progress "MIGRATE" "迁移提示词模板..."

    local source_path="$WORKSPACE_ROOT/$source_prompts"
    local target_path="$WORKSPACE_ROOT/$target_prompts"

    if [[ ! -d "$source_path" ]]; then
        set_status "prompts" "skipped"
        set_message "prompts" "源提示词目录不存在: $source_prompts"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    local prompt_count
    prompt_count=$(find "$source_path" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$prompt_count" -eq 0 ]]; then
        set_status "prompts" "skipped"
        set_message "prompts" "源提示词目录为空"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  DRY-RUN: cp -r $source_path/* $target_path/"
        set_status "prompts" "success"
        set_message "prompts" "$prompt_count 个提示词模板准备迁移"
    else
        mkdir -p "$target_path"
        if cp -r "$source_path"/* "$target_path/" 2>/dev/null; then
            echo "  [OK] 迁移提示词: $prompt_count 个文件"
            set_status "prompts" "success"
            set_message "prompts" "成功迁移 $prompt_count 个提示词模板"
            MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
        else
            set_status "prompts" "failed"
            set_message "prompts" "提示词模板迁移失败"
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
        fi
    fi
}

# Reads a source MCP config, maps the server root key into the target IDE's
# format, and writes the result to the target file. Sets the global variables
# CONV_RESULT (success|copied|failed) and CONV_DETAIL (human message) for the
# caller. NEVER reports success when zero bytes were actually transferred.
convert_mcp_file() {
    local src="$1" src_key="$2" dst="$3" dst_key="$4"
    CONV_RESULT=""
    CONV_DETAIL=""
    MCP_REDACTED_COUNT=0

    if [[ ! -r "$src" ]]; then
        CONV_RESULT="failed"
        CONV_DETAIL="源MCP配置不可读: $src"
        return
    fi

    # Only perform a true root-key conversion when BOTH the source and target
    # are JSON files. If either side is TOML/YAML (or any other format) we
    # cannot truly convert, so we fall back to a verbatim copy and report
    # "copied" (never a false "success"). In EVERY path we strip secrets
    # (env values, bearer/API keys, URL-embedded credentials, auth headers)
    # before the result lands on disk — honouring the skill's safety promise
    # to never migrate live credentials.
    local src_ext dst_ext
    src_ext="${src##*.}"
    dst_ext="${dst##*.}"

    if [[ "$src_ext" == "json" && "$dst_ext" == "json" ]] && command -v python3 >/dev/null 2>&1; then
        if python3 - "$src" "$src_key" "$dst" "$dst_key" >/dev/null 2>&1 <<'PYEOF'
import json, os, re, sys
src, src_key, dst, dst_key = sys.argv[1], (sys.argv[2] or ""), sys.argv[3], (sys.argv[4] or "")
SECRET_KEY_RE = re.compile(r"(?i)(api[_-]?key|token|secret|password|passwd|authorization|auth|bearer|private[_-]?key|access[_-]?key|client[_-]?secret|session|cookie)", re.IGNORECASE)
# Broadened to catch credential-bearing DB/connection URIs (postgres://user:pass@,
# mysql://..., redis://..., etc.), not just http(s).
URL_CRED_RE = re.compile(r"^(?:https?|postgres|postgresql|mysql|mongodb|mongodb\+srv|redis|ftp|amqp|sqlserver)://[^:@/\s]+:[^@/\s]+@", re.IGNORECASE)
URL_TOKEN_RE = re.compile(r"^(https?://)[^/\s]*:(//)?[A-Za-z0-9_\-]{16,}", re.IGNORECASE)
# Query-string credentials: ?key=..., ?token=..., ?secret=..., ?access_token=...
QUERY_CRED_RE = re.compile(r"[?&](key|token|secret|access[_-]?token|api[_-]?key)=[A-Za-z0-9_\-]{12,}", re.IGNORECASE)

def redact_value(v):
    # Strings that look like a credential/secret get blanked (key name kept).
    if isinstance(v, str):
        # A secret keyword appearing inside a value (e.g. a bare bearer/token
        # string) — but only when the value has no spaces, so prose such as
        # "my password is secret" is never touched.
        if SECRET_KEY_RE.search(v) and ' ' not in v:
            return ""
        if URL_CRED_RE.match(v) or URL_TOKEN_RE.match(v):
            return ""
        if QUERY_CRED_RE.search(v):
            return ""
    return v

# CLI flag that names a secret (e.g. --token, --api-key). The flag itself is
# kept; only its VALUE (the next argv element, or the =-suffix) is blanked.
FLAG_RE = re.compile(r"^--?[A-Za-z0-9_\-]+$")
FLAG_EQ_RE = re.compile(r"^(--?[A-Za-z0-9_\-]+)=(.+)$")
# Conventional SHORT flags that carry credentials (mysql/psql -p, -t token,
# -k key). Their names don't contain a secret keyword, so SECRET_KEY_RE can't
# catch them. Deliberate over-redaction tradeoff: the blanked value is always
# recoverable from the untouched SOURCE config.
SHORT_SECRET_FLAGS = {"-p", "-t", "-k"}

def redact_node(node, key_ctx=""):
    if isinstance(node, dict):
        for k, v in list(node.items()):
            if isinstance(v, (dict, list)):
                redact_node(v, k)
            elif isinstance(v, str) and SECRET_KEY_RE.search(k):
                # key name itself signals a secret (e.g. "apiKey", "token")
                node[k] = ""
            else:
                node[k] = redact_value(v)
    elif isinstance(node, list):
        # Arrays leak secrets two ways: (a) the PARENT key is secret-like
        # ("API_KEYS": ["a","b"]) -> blank every string element; (b) argv-style
        # flag pairs ("args": ["--token","val"] or ["--token=val"]) -> keep the
        # flag, blank its value.
        parent_secret = bool(SECRET_KEY_RE.search(key_ctx or ""))
        blank_next = False
        for i, item in enumerate(node):
            if isinstance(item, (dict, list)):
                redact_node(item, key_ctx)
                blank_next = False
            elif isinstance(item, str):
                if parent_secret:
                    node[i] = ""
                elif blank_next:
                    node[i] = ""
                    blank_next = False
                else:
                    m_eq = FLAG_EQ_RE.match(item)
                    if m_eq and (SECRET_KEY_RE.search(m_eq.group(1)) or m_eq.group(1) in SHORT_SECRET_FLAGS):
                        node[i] = m_eq.group(1) + "="
                    elif item in SHORT_SECRET_FLAGS:
                        blank_next = True  # short secret flag (-p/-t/-k); value blanked
                    elif FLAG_RE.match(item) and SECRET_KEY_RE.search(item):
                        blank_next = True  # flag kept; next argv element blanked
                    else:
                        node[i] = redact_value(item)
            else:
                blank_next = False

try:
    with open(src) as f:
        data = json.load(f)
except Exception:
    sys.exit(2)  # not JSON -> caller falls back to a verbatim copy
if isinstance(data, dict):
    if src_key and src_key in data:
        servers = data[src_key]
    elif "mcpServers" in data:
        servers = data["mcpServers"]
    else:
        servers = {}
else:
    servers = {}
if not servers:
    # No servers were extracted (empty/absent root key). Never report a
    # "success" for a zero-server transfer; signal the caller to fall back
    # to a verbatim copy instead.
    sys.exit(3)
redact_node(servers)
existing = {}
if os.path.exists(dst):
    try:
        with open(dst) as f:
            existing = json.load(f)
    except Exception:
        existing = {}
if not isinstance(existing, dict):
    existing = {}
if dst_key:
    cur = existing.get(dst_key, {})
    if not isinstance(cur, dict):
        cur = {}
    if isinstance(servers, dict):
        cur.update(servers)
    existing[dst_key] = cur
else:
    if isinstance(servers, dict):
        existing.update(servers)
    else:
        existing = servers
with open(dst, "w") as f:
    json.dump(existing, f, indent=2)
sys.exit(0)
PYEOF
        then
            if MCP_REDACTED_COUNT=$(redact_secrets_in_file "$dst"); then
                CONV_RESULT="success"
                CONV_DETAIL="MCP配置已转换 (根键 ${src_key:-mcpServers} -> ${dst_key:-mcpServers})，密钥已清空"
            else
                MCP_REDACTED_COUNT=0
                CONV_RESULT="failed"
                CONV_DETAIL="MCP配置脱敏失败，目标文件已删除以防密钥泄漏 (源文件未动)"
            fi
            return
        fi
        # exit 2 (not JSON) or exit 3 (empty server map) -> fall through to a
        # verbatim copy so we never report a false "success"
    fi

    # Fallback: copy as-is, then strip secrets from the COPY (not the source).
    # Marked "copied" (not "success") because the format was not truly
    # converted and manual adjustment is expected.
    if cp "$src" "$dst" 2>/dev/null; then
        if [[ -s "$dst" ]]; then
            if MCP_REDACTED_COUNT=$(redact_secrets_in_file "$dst"); then
                CONV_RESULT="copied"
                CONV_DETAIL="MCP配置按原样复制 (源/目标格式不直接兼容，需手动调整根键 ${src_key:-?} -> ${dst_key:-?})，密钥已清空"
            else
                MCP_REDACTED_COUNT=0
                CONV_RESULT="failed"
                CONV_DETAIL="MCP配置脱敏失败，目标文件已删除以防密钥泄漏 (源文件未动)"
            fi
        else
            CONV_RESULT="failed"
            CONV_DETAIL="MCP配置复制后为空"
        fi
    else
        CONV_RESULT="failed"
        CONV_DETAIL="MCP配置复制失败"
    fi
}

# Strip likely secrets from a config file in place (env values, bearer/API
# keys, URL-embedded credentials, auth headers, query-string creds). Works on
# JSON/TOML/YAML by redacting quoted values whose key name is secret-like or
# whose value looks like a credential. Keys are preserved; values are blanked.
#
# IMPORTANT: this must only ever touch LEAF values. A line like `"secret-env": {`
# has a secret-looking KEY but its value is a container (`{`), NOT a secret — so
# we skip it. Otherwise the whole object would be replaced with `""` and the
# file (e.g. JSON) would be corrupted. Trailing commas (always present in
# json.dump output) are handled too.
#
# Returns, on stdout, the number of values actually redacted (0 when none).
redact_secrets_in_file() {
    local file="$1"
    [[ -f "$file" ]] || { echo 0; return 0; }
    command -v python3 >/dev/null 2>&1 || { echo 0; return 0; }
    local n rc=0 pyout
    pyout=$(mktemp "${TMPDIR:-/tmp}/redact-out.XXXXXX")
    # NOTE: the heredoc must NOT sit inside $(...) — bash 3.2 (macOS default)
    # mis-parses quotes in command-substituted heredocs. Redirect instead.
    python3 - "$file" >"$pyout" <<'PYEOF' || rc=$?
import os, re, sys
file = sys.argv[1]
TMP = file + ".redact.tmp"

def _fail_closed(exc_type=None, exc=None, tb=None):
    # FAIL CLOSED: the destination copy may still hold un-redacted secrets.
    # Never leave it (or a half-written temp) behind; the untouched SOURCE
    # config remains the recoverable source of truth.
    for p in (TMP, file):
        try:
            os.unlink(p)
        except OSError:
            pass
    try:
        # flush=True is REQUIRED: stdout is redirected to a file (block
        # buffered) and os._exit() skips buffer flushing.
        print(-1, flush=True)
    except Exception:
        pass
    os._exit(4)

# Any unhandled exception anywhere below (vector ②) -> fail closed instead of
# leaving a secret-bearing file on disk under bash `set -euo pipefail`.
sys.excepthook = _fail_closed
SECRET_KEY_RE = re.compile(r"(?i)(api[_-]?key|token|secret|password|passwd|authorization|auth|bearer|private[_-]?key|access[_-]?key|client[_-]?secret|session|cookie)")
URL_CRED_RE = re.compile(r"^(?:https?|postgres|postgresql|mysql|mongodb|mongodb\+srv|redis|ftp|amqp|sqlserver)://[^:@/\s]+:[^@/\s]+@", re.IGNORECASE)
URL_TOKEN_RE = re.compile(r"^(https?://)[^/\s]*:(//)?[A-Za-z0-9_\-]{16,}", re.IGNORECASE)
QUERY_CRED_RE = re.compile(r"[?&](key|token|secret|access[_-]?token|api[_-]?key)=[A-Za-z0-9_\-]{12,}", re.IGNORECASE)
# Conventional SHORT flags that carry credentials (mysql/psql -p, -t token,
# -k key). Their names don't contain a secret keyword, so SECRET_KEY_RE can't
# catch them. Deliberate over-redaction tradeoff: the blanked value is always
# recoverable from the untouched SOURCE config.
SHORT_SECRET_FLAGS = {"-p", "-t", "-k"}
FLAG_RE = re.compile(r"^--?[A-Za-z0-9_\-]+$")
FLAG_EQ_RE = re.compile(r"^(--?[A-Za-z0-9_\-]+)=(.+)$")

def is_secret_value(val):
    if not isinstance(val, str):
        return False
    if URL_CRED_RE.match(val) or URL_TOKEN_RE.match(val):
        return True
    if QUERY_CRED_RE.search(val):
        return True
    # A secret keyword appearing inside a value (e.g. a bare bearer/token
    # string) — but only when the value has no spaces, so prose such as
    # "my password is secret" is never touched.
    if SECRET_KEY_RE.search(val) and ' ' not in val:
        return True
    return False

def is_secret_key(key):
    return bool(SECRET_KEY_RE.search(key or ""))

def is_secret_flag(tok):
    # CLI flag that names a secret: --token, --api-key, or short -p/-t/-k.
    if tok in SHORT_SECRET_FLAGS:
        return True
    return bool(FLAG_RE.match(tok) and SECRET_KEY_RE.search(tok))

def blank_all_quoted(text):
    # Blank every nonempty quoted element; return (new_text, n_blanked).
    n = [0]
    def repl(m):
        n[0] += 1
        return '""'
    new = re.sub(r'["\']([^"\']+)["\']', repl, text)
    return new, n[0]

count = 0
out = []
# Depth of a multi-line array opened by a secret-like key (e.g.
# "API_KEYS": [ ...elements on following lines... ]). Every quoted string
# element inside such an array is blanked.
secret_array_depth = 0
# argv cross-line state: a secret CLI flag seen on a previous line whose value
# lives on the next line (e.g. JSON '"-p",' then '"MySecret"', or YAML
# "- --token" then "- sk-live-xxx", or an unclosed inline array).
flag_pending = False

def redact_kv(m):
    # Vector ⑤: blank the VALUE of EVERY secret-like keyed pair on a line,
    # not just the first. Only touches quoted leaf values ("v"), never
    # containers ("{") or arrays ("["). The key (and its quoting) is kept.
    global count
    k = m.group(1).strip().rstrip(":").strip('"\'')
    if is_secret_key(k):
        count += 1
        return '%s""' % m.group(1)
    return m.group(0)

try:
    with open(file) as f:
        raw_lines = f.readlines()
except Exception:
    # Unreadable destination: we cannot prove it holds no secrets -> fail
    # closed (delete it) rather than leaving an un-redacted copy behind.
    _fail_closed()

for raw in raw_lines:
    line = raw.rstrip("\n")
    # ---- inside a multi-line secret-keyed array: blank every string element
    if secret_array_depth > 0:
        secret_array_depth += line.count("[") - line.count("]")
        stripped = line.strip()
        if stripped and not stripped.startswith(("]", "}")):
            new_line, n = blank_all_quoted(line)
            if n:
                line = new_line
                count += n
        out.append(line + "\n")
        continue
    # ---- YAML/JSON list item: "- api_key: secret" / "- --token" / "- value"
    ym = re.match(r'^\s*-\s+(.*\S)\s*$', line)
    if ym:
        item = ym.group(1)
        # NOTE: flag_pending must survive into CASE B — a bare list element
        # may be the VALUE of a secret flag on the previous line (vector ④).
        # Only a KEYED pair (CASE A) ends a pending argv pair.
        km = re.match(r'["\']?([A-Za-z0-9_.\-]+)["\']?\s*[:=]\s*(.*)$', item)
        if km:
            flag_pending = False  # a keyed list line ends any pending pair
            key, rest = km.group(1), km.group(2).strip()
            if is_secret_key(key):
                if rest == "[":
                    secret_array_depth = 1
                elif rest.startswith("["):
                    new_rest, n = blank_all_quoted(rest)
                    line = line[:line.index("[")] + new_rest
                    count += n
                elif rest.startswith("{") or rest == "":
                    pass
                else:
                    # Key IS secret -> blank the value unconditionally; the
                    # value need not look secret itself (e.g. "tok-xyz-789").
                    qm = re.match(r'^["\'](.*)["\']\s*,?\s*$', rest)
                    if qm:
                        if qm.group(1):
                            line = re.sub(r'([:=]\s*)["\'].*?["\'](\s*,?\s*)$', r'\1""\2', line)
                            count += 1
                    elif not rest.startswith(('"', "'")):
                        line = re.sub(r'[:=]\s*\S.*?(\s*,?\s*)$', r': ""\1', line)
                        count += 1
            out.append(line + "\n")
            continue
        # CASE B: list item is a bare element (a flag or a value)
        if flag_pending:
            if FLAG_RE.match(item):
                # consecutive flags ('- -p' then '- -t'): the element is a
                # FLAG, not the pending value -> keep it, re-arm only if it
                # is itself a secret flag.
                flag_pending = is_secret_flag(item)
                out.append(line + "\n")
                continue
            # value of a preceding secret flag -> blank the whole element
            idx = line.rfind(item)
            if idx != -1:
                line = line[:idx] + '""'
                count += 1
            flag_pending = False
            out.append(line + "\n")
            continue
        # Arm pending when this element is a secret flag whose value is on the
        # next line; or blank an inline "--flag=value" immediately (vector ④).
        if "=" in item:
            eqm = FLAG_EQ_RE.match(item)
            if eqm and (SECRET_KEY_RE.search(eqm.group(1)) or eqm.group(1) in SHORT_SECRET_FLAGS):
                idx = line.rfind(item)
                if idx != -1:
                    line = line[:idx] + eqm.group(1) + "="
                    count += 1
                out.append(line + "\n")
                continue
        elif is_secret_flag(item):
            flag_pending = True
            out.append(line + "\n")
            continue
    # ---- Vector ⑤: blank every "secretKey":"value" pair on the line
    line = re.sub(r'("?[A-Za-z0-9_.\-]+"?\s*:\s*)"([^"]*)"', redact_kv, line)
    # ---- normal keyed-line handling (single key + arrays + argv)
    m = re.match(r'^\s*["\']?([A-Za-z0-9_.\-]+)["\']?\s*[:=]\s*(.*)$', line)
    if m:
        key, rest = m.group(1), m.group(2).strip()
        key_secret = bool(SECRET_KEY_RE.search(key))
        flag_pending = False  # a fresh keyed line ends any pending argv pair
        if rest == "[":
            if key_secret:
                secret_array_depth = 1
            out.append(line + "\n")
            continue
        if rest.startswith("["):
            if key_secret:
                new_rest, n = blank_all_quoted(rest)
                prefix = re.match(r'^(\s*["\']?[A-Za-z0-9_.\-]+["\']?\s*[:=]\s*)', raw.rstrip("\n")).group(1)
                line = prefix + new_rest
                count += n
            else:
                # argv-style: --token "val" / --token=val / -p "val" inside one
                # line. Operate on the bracketed REST only so the key (which may
                # itself be quoted, e.g. JSON "args") is never clobbered.
                elems = re.findall(r'["\'](.*?)["\']', rest)
                blank_next = False
                changed = False
                new_elems = []
                for e in elems:
                    if blank_next:
                        new_elems.append("")
                        count += 1
                        changed = True
                        blank_next = False
                    elif FLAG_EQ_RE.match(e) and (SECRET_KEY_RE.search(FLAG_EQ_RE.match(e).group(1)) or FLAG_EQ_RE.match(e).group(1) in SHORT_SECRET_FLAGS):
                        new_elems.append(FLAG_EQ_RE.match(e).group(1) + "=")
                        count += 1
                        changed = True
                    elif e in SHORT_SECRET_FLAGS:
                        new_elems.append(e)
                        blank_next = True
                    elif FLAG_RE.match(e) and SECRET_KEY_RE.search(e):
                        new_elems.append(e)
                        blank_next = True
                    else:
                        new_elems.append(e)
                if changed:
                    it = iter(new_elems)
                    # Vector ②: next() must NEVER raise StopIteration. Any extra
                    # quoted string on the line (e.g. the key itself) is kept
                    # verbatim instead of crashing the whole redaction pass.
                    new_rest = re.sub(r'["\'](.*?)["\']', lambda mm: '"%s"' % next(it, mm.group(0)), rest)
                    prefix = re.match(r'^(\s*["\']?[A-Za-z0-9_.\-]+["\']?\s*[:=]\s*)', raw.rstrip("\n")).group(1)
                    line = prefix + new_rest
                # A secret flag at the END of an unclosed inline array has its
                # value on the following line (vector ①/④ cross-line).
                if blank_next and not rest.rstrip().endswith("]"):
                    flag_pending = True
            out.append(line + "\n")
            continue
        # Skip container lines ("key": {) and empty values — never
        # redact an entire object just because its key looks secret.
        if rest in ("{", ""):
            out.append(line + "\n")
            continue
        # Quoted string value, possibly with a trailing comma: "value",
        # The trailing comma (present in JSON, absent in TOML/YAML) must be
        # PRESERVED or the file becomes invalid JSON. Capture it in group 2.
        qm = re.match(r'^["\'](.*)["\']\s*,?\s*$', rest)
        if qm:
            val = qm.group(1)
            # A secret KEY alone is sufficient (value need not look secret,
            # e.g. token: "tok-xyz-789"). redact_kv may have already blanked
            # double-quoted pairs -> val == "" -> skip (no double count).
            if val and (key_secret or is_secret_value(val)):
                line = re.sub(r'([:=]\s*)["\'].*?["\'](\s*,?\s*)$', r'\1""\2', line)
                count += 1
        else:
            # Bare value (TOML/YAML, no surrounding quotes). A rest that
            # STARTS with a quote but did not match the quoted-value regex
            # is NOT a bare value — it is an array element like
            # "--api-key=", (JSON) or an unterminated string; rewriting it
            # would corrupt the file, so leave it untouched.
            bare = rest.rstrip(',').strip()
            if bare and not bare.startswith(('"', "'")) and (key_secret or is_secret_value(bare)):
                line = re.sub(r'[:=]\s*\S.*?(\s*,?\s*)$', r': ""\1', line)
                count += 1
    # ---- argv element lines standing alone (e.g. JSON array continuation
    #      '"-p",' / '"MySecret"') — handle cross-line secret-flag pairs.
    if not line.strip().startswith("[") and not m:
        stripped = line.strip()
        if flag_pending:
            mnext = re.match(r'^["\']?(--?[A-Za-z0-9_\-]+)["\']?,?\s*$', stripped)
            if mnext and FLAG_RE.match(mnext.group(1)):
                # consecutive flags ('"-p",' then '"-t",'): keep the flag,
                # re-arm only if it is itself a secret flag.
                flag_pending = is_secret_flag(mnext.group(1))
            else:
                new_line, n = blank_all_quoted(line)
                if n:
                    line = new_line
                    count += n
                else:
                    # bare (unquoted) value after a secret flag -> blank it.
                    # Skip ALREADY-quoted tokens (e.g. an already-blanked "")
                    # so we never strip a neighbouring comma on valid JSON.
                    if stripped and not stripped.startswith(('"', "'")):
                        line = re.sub(r'\S.*$', '""', line)
                        count += 1
                flag_pending = False
        else:
            mflag = re.match(r'^["\'](--?[A-Za-z0-9_\-]+)["\']?,?\s*$', stripped)
            if mflag and is_secret_flag(mflag.group(1)) and "=" not in mflag.group(1):
                flag_pending = True
    out.append(line + "\n")

# Atomic replace: write the fully-redacted content to a temp file first, then
# swap it in. A crash mid-write can therefore never leave a half-redacted
# destination; any exception here is caught by _fail_closed via excepthook.
with open(TMP, "w") as f:
    f.writelines(out)
os.replace(TMP, file)
print(count)
PYEOF
    n=$(cat "$pyout" 2>/dev/null || echo "-1")
    rm -f "$pyout"
    if [[ $rc -ne 0 || "$n" == "-1" ]]; then
        # FAIL CLOSED (vector ②): python already removed the destination; make
        # doubly sure nothing secret-bearing survives, then signal failure.
        rm -f "$file" "${file}.redact.tmp" 2>/dev/null || true
        echo "  [SECURITY] 密钥脱敏失败，已删除目标文件以防泄漏 (源文件未动): $file" >&2
        echo "-1"
        return 1
    fi
    echo "$n"
    return 0
}

migrate_mcp() {
    local source_ide="$1"
    local target_ide="$2"

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    local source_mcp
    source_mcp=$(get_mcp_path "$source_ide")
    local target_mcp
    target_mcp=$(get_mcp_path "$target_ide")

    # Project-relative MCP paths (e.g. kilocode .kilocode/mcp.json) resolve
    # against the workspace root, not the caller's cwd.
    if [[ -n "$source_mcp" && "$source_mcp" != /* ]]; then
        source_mcp="$WORKSPACE_ROOT/$source_mcp"
    fi
    if [[ -n "$target_mcp" && "$target_mcp" != /* ]]; then
        target_mcp="$WORKSPACE_ROOT/$target_mcp"
    fi

    if [[ -z "$source_mcp" ]]; then
        set_status "mcp" "skipped"
        set_message "mcp" "源IDE不支持MCP配置"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ -z "$target_mcp" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "目标IDE不支持MCP配置，需手动迁移"
        set_manual_step "mcp" "目标IDE ($target_ide) 不支持自动MCP迁移，请参考 IDE Registry 手动配置"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    print_progress "MIGRATE" "迁移MCP服务器配置..."

    if [[ ! -e "$source_mcp" ]]; then
        set_status "mcp" "absent"
        set_message "mcp" "源MCP配置不存在: $source_mcp"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    local src_key dst_key
    src_key=$(get_mcp_root_key "$source_ide")
    dst_key=$(get_mcp_root_key "$target_ide")

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  DRY-RUN: 转换MCP配置"
        echo "    源:   $source_mcp (根键: ${src_key:-无})"
        echo "    目标: $target_mcp (根键: ${dst_key:-无})"
        # Dry-run only prints the plan; never mark success.
        set_status "mcp" "skipped"
        set_message "mcp" "DRY-RUN: 计划转换MCP配置 (${src_key:-?} -> ${dst_key:-?})"
        return 0
    fi

    mkdir -p "$(dirname "$target_mcp")"

    if [[ -e "$target_mcp" ]]; then
        case "$STRATEGY" in
            skip)
                echo "  [SKIP] 目标MCP配置已存在: $target_mcp"
                set_status "mcp" "skipped"
                set_message "mcp" "目标MCP配置已存在，跳过 (策略: skip)"
                MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                return 0
                ;;
            backup)
                local ts
                ts=$(date +%Y%m%d%H%M%S)
                cp -r "$target_mcp" "$target_mcp.bak.$ts"
                echo "  [BACKUP] 备份已有MCP配置: $target_mcp.bak.$ts"
                ;;
            overwrite)
                rm -f "$target_mcp"
                ;;
        esac
    fi

    convert_mcp_file "$source_mcp" "$src_key" "$target_mcp" "$dst_key"

    case "$CONV_RESULT" in
        success)
            echo "  [OK] 转换MCP配置: ${src_key:-mcpServers} -> ${dst_key:-mcpServers}"
            if [[ ${MCP_REDACTED_COUNT:-0} -ne 0 ]]; then
                echo "  [SECURITY] MCP 配置中的密钥/令牌/凭据已在写入目标前被清空 (仅保留键名)。请确认目标 IDE 的密钥来源 (如环境变量/密钥管理器) 后再启用。"
            fi
            set_status "mcp" "success"
            set_message "mcp" "$CONV_DETAIL"
            MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
            ;;
        copied)
            echo "  [COPY] 按原样复制MCP配置: $target_mcp"
            if [[ ${MCP_REDACTED_COUNT:-0} -ne 0 ]]; then
                echo "  [SECURITY] MCP 配置中的密钥/令牌/凭据已在写入目标前被清空 (仅保留键名)。请确认目标 IDE 的密钥来源 (如环境变量/密钥管理器) 后再启用。"
            fi
            set_status "mcp" "copied"
            set_message "mcp" "$CONV_DETAIL"
            set_manual_step "mcp" "检查MCP根键兼容性: ${src_key:-?} -> ${dst_key:-?}"
            MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
            ;;
        failed)
            echo "  [FAIL] MCP配置迁移失败"
            set_status "mcp" "failed"
            set_message "mcp" "$CONV_DETAIL"
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            ;;
        *)
            echo "  [FAIL] MCP配置迁移未知状态"
            set_status "mcp" "failed"
            set_message "mcp" "MCP配置迁移失败 (未知状态)"
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            ;;
    esac
}

migrate_config() {
    local source_ide="$1"
    local target_ide="$2"

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    local source_config
    source_config=$(get_config_file "$source_ide")
    local target_config
    target_config=$(get_config_file "$target_ide")

    if [[ -z "$source_config" ]]; then
        set_status "config" "skipped"
        set_message "config" "源IDE无特定配置文件"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ -z "$target_config" ]]; then
        set_status "config" "manual"
        set_message "config" "目标IDE无特定配置文件，需手动迁移"
        set_manual_step "config" "目标IDE ($target_ide) 不支持自动配置迁移，请手动处理"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    print_progress "MIGRATE" "迁移IDE配置..."

    if [[ ! -f "$source_config" ]]; then
        set_status "config" "absent"
        set_message "config" "源配置文件不存在: $source_config"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  DRY-RUN: 复制配置文件"
        echo "    源:   $source_config"
        echo "    目标: $target_config"
        # Dry-run only prints the plan; never mark success.
        set_status "config" "skipped"
        set_message "config" "DRY-RUN: 计划复制配置文件"
        return 0
    fi

    mkdir -p "$(dirname "$target_config")"

    if [[ -e "$target_config" ]]; then
        case "$STRATEGY" in
            skip)
                echo "  [SKIP] 目标配置文件已存在: $target_config"
                set_status "config" "skipped"
                set_message "config" "目标配置文件已存在，跳过 (策略: skip)"
                MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                return 0
                ;;
            backup)
                local ts
                ts=$(date +%Y%m%d%H%M%S)
                cp -r "$target_config" "$target_config.bak.$ts"
                echo "  [BACKUP] 备份已有配置文件: $target_config.bak.$ts"
                ;;
            overwrite)
                rm -f "$target_config"
                ;;
        esac
    fi

    # A true cross-IDE config conversion is rarely meaningful (schemas differ
    # per IDE). We perform a real transfer (read + copy) and mark it "copied"
    # with a manual step, NEVER "success" implying full conversion, and never
    # a no-op.
    if cp "$source_config" "$target_config" 2>/dev/null; then
        if [[ -s "$target_config" ]]; then
            echo "  [COPY] 复制配置文件: $target_config"
            # SECURITY: settings/config files routinely embed API keys and
            # tokens. Strip them from the COPY (never the source) — same
            # policy as MCP migration.
            local config_redacted
            if config_redacted=$(redact_secrets_in_file "$target_config"); then
                if [[ "${config_redacted:-0}" -gt 0 ]]; then
                    echo "  [SECURITY] 已清空 $config_redacted 处疑似密钥值，请在目标IDE中重新配置凭据"
                    set_manual_step "config" "配置文件中 $config_redacted 处密钥已被清空，需在目标IDE重新填写"
                fi
                set_status "config" "copied"
                set_message "config" "配置文件已复制 (可能需要手动调整格式，密钥已清空): $target_config"
                set_manual_step "config" "检查并调整IDE配置文件格式 ($source_ide -> $target_ide)"
                MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
            else
                echo "  [FAIL] 配置文件脱敏失败，目标副本已删除以防密钥泄漏"
                set_status "config" "failed"
                set_message "config" "配置文件脱敏失败，目标副本已删除以防密钥泄漏 (源文件未动)"
                MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            fi
        else
            echo "  [FAIL] 配置文件复制后为空"
            set_status "config" "failed"
            set_message "config" "配置文件复制后为空"
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
        fi
    else
        echo "  [FAIL] 配置文件复制失败"
        set_status "config" "failed"
        set_message "config" "配置文件复制失败"
        MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
    fi
}

# Redact secrets in every config-like text file under a migrated project
# tree (the COPY, never the source). Prints the total number of blanked
# values. Fail-closed: redact_secrets_in_file already deletes a copy it
# cannot redact; this helper then reports partial failure via rc=1.
redact_project_copy() {
    local root="$1"
    local total=0 n had_fail=0 f
    while IFS= read -r -d '' f; do
        if n=$(redact_secrets_in_file "$f") && [[ "${n:--1}" != "-1" ]]; then
            [[ "${n:-0}" -gt 0 ]] && total=$((total + n))
        else
            # Copy already removed by the fail-closed redactor; make sure.
            rm -f "$f" 2>/dev/null || true
            had_fail=1
        fi
    done < <(find "$root" -name '*.bak.*' -prune -o -type f \( \
        -name '*.json' -o -name '*.jsonc' -o -name '*.yaml' -o -name '*.yml' \
        -o -name '*.toml' -o -name '*.env' -o -name '.env*' \) -print0 2>/dev/null)
    echo "$total"
    return $had_fail
}

migrate_project() {
    local source_ide="$1"
    local target_ide="$2"

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    local source_project
    source_project=$(get_project_path "$source_ide")
    local target_project
    target_project=$(get_project_path "$target_ide")

    if [[ -z "$source_project" ]]; then
        set_status "project" "skipped"
        set_message "project" "源IDE不支持项目级配置"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ -z "$target_project" ]]; then
        set_status "project" "skipped"
        set_message "project" "目标IDE不支持项目级配置"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    print_progress "MIGRATE" "迁移项目级配置..."

    local source_path="$WORKSPACE_ROOT/$source_project"
    local target_path="$WORKSPACE_ROOT/$target_project"

    if [[ ! -e "$source_path" ]]; then
        set_status "project" "skipped"
        set_message "project" "源项目配置不存在: $source_project"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        if [[ -d "$source_path" ]]; then
            echo "  DRY-RUN: cp -r $source_path $target_path"
        else
            echo "  DRY-RUN: cp $source_path $target_path"
        fi
        set_status "project" "success"
        set_message "project" "项目配置准备迁移"
    else
        if [[ -d "$source_path" ]]; then
            # Apply the migration strategy to an EXISTING target (dir or file).
            if [[ -e "$target_path" ]]; then
                case "$STRATEGY" in
                    skip)
                        echo "  [SKIP] 目标项目配置已存在: $target_project"
                        set_status "project" "skipped"
                        set_message "project" "目标项目配置已存在，跳过 (策略: skip)"
                        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                        return 0
                        ;;
                    backup)
                        local ts
                        ts=$(date +%Y%m%d%H%M%S)
                        cp -r "$target_path" "$target_path.bak.$ts"
                        echo "  [BACKUP] 备份已有项目配置: $target_project.bak.$ts"
                        ;;
                    overwrite)
                        rm -rf "$target_path"
                        ;;
                esac
            fi
            mkdir -p "$target_path"
            # Guard: refuse to report success if the source tree is empty
            # (e.g. only non-tracked dotfiles), so we never claim a
            # zero-byte transfer as "success".
            local src_files
            src_files=$(find "$source_path" -type f 2>/dev/null | wc -l | tr -d ' ')
            if [[ "${src_files:-0}" -eq 0 ]]; then
                set_status "project" "skipped"
                set_message "project" "源项目配置目录为空: $source_project"
                MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                return 0
            fi
            if cp -r "$source_path"/. "$target_path"/ 2>/dev/null; then
                if [[ $(find "$target_path" -type f 2>/dev/null | wc -l | tr -d ' ') -eq 0 ]]; then
                    set_status "project" "failed"
                    set_message "project" "项目配置复制后为空"
                    MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
                else
                    echo "  [OK] 迁移项目配置目录"
                    # SECURITY: project trees routinely bundle .env / .toml /
                    # json credentials (local service configs, etc.). Strip
                    # them from the COPY (never the source) — same policy as
                    # the mcp and config migrations. Fail-closed: if any file
                    # cannot be redacted, the whole copy is removed so no
                    # secret-bearing file is left on disk.
                    local proj_redacted proj_rc=0
                    proj_redacted=$(redact_project_copy "$target_path") || proj_rc=$?
                    if [[ "$proj_rc" -ne 0 ]]; then
                        echo "  [FAIL] 项目配置脱敏失败，目标副本已删除以防密钥泄漏"
                        rm -rf "$target_path"
                        set_status "project" "failed"
                        set_message "project" "项目配置脱敏失败，目标副本已删除以防密钥泄漏 (源文件未动)"
                        MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
                    else
                        if [[ "${proj_redacted:-0}" -gt 0 ]]; then
                            echo "  [SECURITY] 已清空 $proj_redacted 处疑似密钥值，请检查目标项目中的凭据并重新配置"
                            set_manual_step "project" "项目配置中 $proj_redacted 处密钥已被清空，请在目标IDE重新填写 (如 .env / 配置文件)"
                        fi
                        set_status "project" "success"
                        set_message "project" "项目配置目录已迁移，密钥已清空: $target_project"
                        MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
                    fi
                fi
            else
                set_status "project" "failed"
                set_message "project" "项目配置迁移失败"
                MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            fi
        else
            # Single project-level config FILE case (e.g. .dir-locals.el,
            # .aider.conf.yml, .github/copilot-instructions.md).
            if [[ -e "$target_path" ]]; then
                case "$STRATEGY" in
                    skip)
                        echo "  [SKIP] 目标项目配置文件已存在: $target_project"
                        set_status "project" "skipped"
                        set_message "project" "目标项目配置文件已存在，跳过 (策略: skip)"
                        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                        return 0
                        ;;
                    backup)
                        local ts
                        ts=$(date +%Y%m%d%H%M%S)
                        cp "$target_path" "$target_path.bak.$ts"
                        echo "  [BACKUP] 备份已有项目配置文件: $target_project.bak.$ts"
                        ;;
                    overwrite)
                        rm -f "$target_path"
                        ;;
                esac
            fi
            mkdir -p "$(dirname "$target_path")"
            if cp "$source_path" "$target_path" 2>/dev/null; then
                if [[ ! -s "$target_path" ]]; then
                    set_status "project" "failed"
                    set_message "project" "项目配置文件复制后为空"
                    MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
                else
                    echo "  [OK] 迁移项目配置文件"
                    local proj_redacted proj_rc=0
                    proj_redacted=$(redact_project_copy "$target_path") || proj_rc=$?
                    if [[ "$proj_rc" -ne 0 ]]; then
                        echo "  [FAIL] 项目配置脱敏失败，目标副本已删除以防密钥泄漏"
                        rm -f "$target_path"
                        set_status "project" "failed"
                        set_message "project" "项目配置脱敏失败，目标副本已删除以防密钥泄漏 (源文件未动)"
                        MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
                    else
                        if [[ "${proj_redacted:-0}" -gt 0 ]]; then
                            echo "  [SECURITY] 已清空 $proj_redacted 处疑似密钥值，请检查目标项目中的凭据并重新配置"
                            set_manual_step "project" "项目配置中 $proj_redacted 处密钥已被清空，请在目标IDE重新填写"
                        fi
                        set_status "project" "success"
                        set_message "project" "项目配置文件已迁移，密钥已清空: $target_project"
                        MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
                    fi
                fi
            else
                set_status "project" "failed"
                set_message "project" "项目配置文件迁移失败"
                MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            fi
        fi
    fi
}

run_migration() {
    local source_ide="$1"
    local target_ide="$2"

    local OLD_IFS="$IFS"
    IFS=',' read -ra OBJECT_LIST <<< "$OBJECTS"
    IFS="$OLD_IFS"

    for obj in "${OBJECT_LIST[@]}"; do
        case "$obj" in
            skills)
                migrate_skills "$source_ide" "$target_ide"
                ;;
            rules)
                migrate_rules "$source_ide" "$target_ide"
                ;;
            prompts)
                migrate_prompts "$source_ide" "$target_ide"
                ;;
            mcp)
                migrate_mcp "$source_ide" "$target_ide"
                ;;
            config)
                migrate_config "$source_ide" "$target_ide"
                ;;
            project)
                migrate_project "$source_ide" "$target_ide"
                ;;
            *)
                echo "[WARN] 未知的内容类型: $obj"
                ;;
        esac
    done
}

generate_report() {
    local source_ide="$1"
    local target_ide="$2"
    local report=""

    report+="========================================\n"
    report+="       IDE 迁移报告\n"
    report+="========================================\n"
    report+="\n"
    report+="迁移详情:\n"
    report+="  源IDE: $(get_ide_name "$source_ide") ($source_ide)\n"
    report+="  目标IDE: $(get_ide_name "$target_ide") ($target_ide)\n"
    report+="  工作区: $WORKSPACE_ROOT\n"
    report+="  策略: $STRATEGY\n"
    report+="  时间: $(date '+%Y-%m-%dT%H:%M:%S%z')\n"  # portable (BSD date lacks -Iseconds)
    report+="\n"
    report+="统计:\n"
    report+="  总操作数: $MIGRATION_TOTAL\n"
    report+="  成功: $MIGRATION_SUCCESS\n"
    report+="  失败: $MIGRATION_FAILED\n"
    report+="  跳过: $MIGRATION_SKIPPED\n"
    report+="\n"
    report+="详细结果:\n"

    for obj in skills rules prompts mcp config project; do
        local status
        status=$(get_status "$obj")
        if [[ -n "$status" ]]; then
            local message
            message=$(get_message "$obj")
            local status_icon

            case "$status" in
                success) status_icon="✓" ;;
                copied)  status_icon="✓" ;;
                manual)  status_icon="⚠" ;;
                partial) status_icon="⚠" ;;
                failed)  status_icon="✗" ;;
                absent)  status_icon="○" ;;
                skipped) status_icon="○" ;;
                *)       status_icon="?" ;;
            esac

            report+="  [$status_icon] $obj: $message\n"
        fi
    done

    report+="\n"
    report+="需要手动处理的步骤:\n"

    local has_manual=0
    for obj in skills rules prompts mcp config project; do
        local steps
        steps=$(get_manual_steps "$obj")
        if [[ -n "$steps" ]]; then
            has_manual=1
            report+="\n  [$obj]\n"
            report+="    $steps\n"
        fi
    done

    if [[ $has_manual -eq 0 ]]; then
        report+="  无 - 所有迁移已自动完成\n"
    fi

    report+="\n"
    report+="========================================\n"

    echo -e "$report"
}

trap cleanup_migration_files EXIT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            SOURCE_IDE="$2"
            shift 2
            ;;
        --target)
            TARGET_IDE="$2"
            shift 2
            ;;
        --workspace)
            WORKSPACE_ROOT="$2"
            shift 2
            ;;
        --objects)
            OBJECTS="$2"
            shift 2
            ;;
        --strategy)
            STRATEGY="$2"
            shift 2
            ;;
        --report)
            REPORT_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --yes|-y)
            ASSUME_YES=1
            shift
            ;;
        --print-path)
            PRINT_PATH_IDE="$2"
            PRINT_PATH_OBJECT="$3"
            shift 3
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "错误: 未知参数: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# Suppress the banner in read-only diagnostic mode so --print-path emits only
# the resolved path on stdout (keeps verify-ide-config.sh comparisons exact).
if [[ -z "$PRINT_PATH_IDE" ]]; then
    print_header
fi

# ---------------------------------------------------------------------------
# Read-only diagnostic mode: --print-path <ide> <object>
# Resolves and prints the path for the requested object using the same
# get_*_path functions the migration logic uses, then exits. This performs NO
# migration and NO filesystem writes (side-effect-free). For an unknown IDE or
# an unsupported object the script prints an error to stderr and exits non-zero.
# ---------------------------------------------------------------------------
if [[ -n "$PRINT_PATH_IDE" ]]; then
    if ! validate_ide "$PRINT_PATH_IDE"; then
        echo "错误: 无效的IDE: $PRINT_PATH_IDE" >&2
        echo "支持的IDE: $SUPPORTED_IDES" >&2
        exit 1
    fi

    resolved=""
    case "$PRINT_PATH_OBJECT" in
        global)  resolved=$(get_global_path "$PRINT_PATH_IDE") ;;
        project) resolved=$(get_project_path "$PRINT_PATH_IDE") ;;
        mcp)     resolved=$(get_mcp_path "$PRINT_PATH_IDE") ;;
        config)  resolved=$(get_config_file "$PRINT_PATH_IDE") ;;
        rules)   resolved=$(get_rules_file "$PRINT_PATH_IDE") ;;
        *)
            echo "错误: 不支持的对象: $PRINT_PATH_OBJECT (可选: global, project, mcp, config, rules)" >&2
            exit 1
            ;;
    esac

    if [[ -z "$resolved" ]]; then
        # IDE exists but does not support this object type.
        echo "错误: $PRINT_PATH_IDE 不支持对象: $PRINT_PATH_OBJECT" >&2
        exit 1
    fi

    # Normalize the user-global HOME prefix to a literal "~" so the output is
    # comparable against registry-canonical "~"-prefixed expected values.
    if [[ "$resolved" == "${HOME}/"* ]]; then
        resolved="~${resolved#"${HOME}"}"
    fi

    echo "$resolved"
    exit 0
fi

if [[ -z "$SOURCE_IDE" ]]; then
    echo "错误: 必须指定源IDE (--source)" >&2
    echo "" >&2
    echo "支持的IDE:" >&2
    for ide in $SUPPORTED_IDES; do
        printf "  - %-12s %s\n" "$ide" "$(get_ide_name "$ide")" >&2
    done
    exit 1
fi

if [[ -z "$TARGET_IDE" ]]; then
    echo "错误: 必须指定目标IDE (--target)" >&2
    echo "" >&2
    echo "支持的IDE:" >&2
    for ide in $SUPPORTED_IDES; do
        printf "  - %-12s %s\n" "$ide" "$(get_ide_name "$ide")" >&2
    done
    exit 1
fi

if ! validate_ide "$SOURCE_IDE"; then
    echo "错误: 无效的源IDE: $SOURCE_IDE" >&2
    echo "支持的IDE: $SUPPORTED_IDES" >&2
    exit 1
fi

if ! validate_ide "$TARGET_IDE"; then
    echo "错误: 无效的目标IDE: $TARGET_IDE" >&2
    echo "支持的IDE: $SUPPORTED_IDES" >&2
    exit 1
fi

if [[ "$SOURCE_IDE" == "$TARGET_IDE" ]]; then
    echo "错误: 源IDE和目标IDE不能相同" >&2
    exit 1
fi

if [[ -z "$OBJECTS" ]]; then
    # Default to LOW-RISK object types only. mcp/config/project can carry live
    # credentials (API keys, tokens, bearer auth); they are NEVER migrated by
    # default — the user must opt in explicitly via --objects. This prevents
    # accidental bulk copying of secret-bearing config (see security audit).
    OBJECTS=$(list_available_objects "$SOURCE_IDE" | tr ',' '\n' | grep -E '^(skills|rules|prompts)$' | paste -sd, -)
    if [[ -z "$OBJECTS" ]]; then
        OBJECTS="skills,rules,prompts"
    fi
    echo "未指定 --objects：默认仅迁移低风险类型 (skills,rules,prompts)。" >&2
    echo "如需迁移 mcp/config/project（可能含密钥），请显式指定 --objects 并确认已审查。" >&2
fi

# Security reminder when sensitive (credential-bearing) object types are in scope.
if [[ "$OBJECTS" == *mcp* || "$OBJECTS" == *config* || "$OBJECTS" == *project* ]]; then
    echo "" >&2
    echo "⚠️  SECURITY: 本次迁移包含 mcp/config/project，这些配置可能含有 API 密钥、令牌、" >&2
    echo "    bearer 凭据或内嵌 URL 凭据。迁移时密钥会被自动清空 (仅保留键名)，目标 IDE" >&2
    echo "    需另行配置密钥来源 (环境变量/密钥管理器)。请仅在你信任的源与目标间执行。" >&2
    echo "" >&2
fi

echo "========================================"
echo "迁移摘要"
echo "========================================"
echo ""
echo "  源IDE: $(get_ide_name "$SOURCE_IDE")"
echo "  目标IDE: $(get_ide_name "$TARGET_IDE")"
echo "  工作区: $WORKSPACE_ROOT"
echo "  迁移内容: $OBJECTS"
echo "  策略: $STRATEGY"
echo ""

if [[ $DRY_RUN -eq 1 ]]; then
    echo "  模式: DRY-RUN (不会修改任何文件)"
fi

echo ""

# ---------------------------------------------------------------------------
# Confirmation gate: the script NEVER writes files without explicit approval.
# - --dry-run       : preview only, no gate needed (no writes happen at all)
# - --yes / -y      : explicit approval, proceed
# - interactive TTY : ask [y/N] before touching anything
# - non-interactive : abort with guidance (CI/agent must pass --yes)
# ---------------------------------------------------------------------------
if [[ $DRY_RUN -eq 0 && $ASSUME_YES -eq 0 ]]; then
    if [[ -t 0 ]]; then
        printf '即将按上述摘要写入目标 IDE 配置。继续? [y/N] ' >&2
        read -r _confirm_reply
        case "$_confirm_reply" in
            y|Y|yes|YES)
                ;;
            *)
                echo "已取消：未修改任何文件。可先用 --dry-run 预览。" >&2
                exit 2
                ;;
        esac
    else
        echo "错误: 非交互环境且未指定 --yes，为安全起见拒绝写入。" >&2
        echo "请先用 --dry-run 预览变更，确认后追加 --yes 执行。未修改任何文件。" >&2
        exit 2
    fi
fi

init_migration_files

echo "[START] 开始迁移: $(get_ide_name "$SOURCE_IDE") -> $(get_ide_name "$TARGET_IDE")"
echo ""

run_migration "$SOURCE_IDE" "$TARGET_IDE"

echo ""
echo "========================================"
echo "       迁移完成"
echo "========================================"
echo ""

report=$(generate_report "$SOURCE_IDE" "$TARGET_IDE")
echo "$report"

if [[ -n "$REPORT_FILE" ]]; then
    echo "$report" > "$REPORT_FILE"
    echo "报告已保存到: $REPORT_FILE"
fi
