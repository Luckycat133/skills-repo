#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Unified, agent-readable output helpers (logging, status tokens, JSON).
source "${SCRIPT_DIR}/common.sh"

SOURCE_IDE=""
TARGET_IDE=""
WORKSPACE_ROOT="$(pwd)"
OBJECTS=""
SOURCE_MCP_FILE=""
SCOPE="global"
STRATEGY="backup"
DRY_RUN=0
ASSUME_YES=0
REPORT_FILE=""
PRINT_PATH_IDE=""
PRINT_PATH_OBJECT=""
OPENCODE_VERSION="v1"
OPENCODE_VERSION_EXPLICIT=0

SUPPORTED_IDES="antigravity claude claude-desktop codex copilot cursor windsurf jetbrains openclaw trae trae-cn vscode zed neovim emacs continue aider roo-code cline amazon-q cody codeium tabnine replit pearai supermaven pieces blackbox gemini-cli goose-cli opencode kilocode kimiai workbuddy kiro augment-code void-editor baidu-comate tencent-codebuddy zcode"

MIGRATION_TOTAL=0
MIGRATION_SUCCESS=0
MIGRATION_FAILED=0
MIGRATION_SKIPPED=0

MIGRATION_STATUS_FILE=""
MIGRATION_MESSAGES_FILE=""
MIGRATION_MANUAL_FILE=""
MIGRATION_EVIDENCE_FILE=""

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
        kilocode)    echo "Kilo Code" ;;
        kimiai)      echo "Kimi AI" ;;
        workbuddy)   echo "WorkBuddy" ;;
        claude-desktop)    echo "Claude Desktop" ;;
        kiro)              echo "Kiro" ;;
        augment-code)      echo "Augment Code" ;;
        void-editor)       echo "Void Editor" ;;
        baidu-comate)      echo "Baidu Comate (ERNIE Code)" ;;
        tencent-codebuddy) echo "Tencent CodeBuddy" ;;
        zcode)             echo "ZCode (Zhipu)" ;;
        *)           echo "$ide" ;;
    esac
}

# SOURCE OF TRUTH: skills/agent-skills-setup/references/ide-registry.md (and ide-paths.json).
# Keep these functions in sync with that file. Drift is caught by test-ide-paths.sh.
get_global_path() {
    local ide="$1"
    case "$ide" in
        # Antigravity publishes two product/version surfaces with different
        # global Skills paths: the IDE Skills page names
        # ~/.gemini/antigravity/skills, while the current shared 2.0 Skills
        # page names ~/.gemini/config/skills. Prefer an explicit override;
        # otherwise preserve an existing legacy IDE tree and use the current
        # shared path for a fresh install. Never merge both trees implicitly.
        antigravity)
            if [[ -n "${ANTIGRAVITY_SKILLS_DIR:-}" ]]; then
                echo "${ANTIGRAVITY_SKILLS_DIR}"
            elif [[ -d "${HOME}/.gemini/antigravity/skills" && ! -d "${HOME}/.gemini/config/skills" ]]; then
                echo "${HOME}/.gemini/antigravity/skills"
            else
                echo "${HOME}/.gemini/config/skills"
            fi
            ;;
        claude)      echo "${HOME}/.claude/skills" ;;
        codex)       echo "${HOME}/.agents/skills" ;;
        copilot)     echo "${HOME}/.copilot/skills" ;;
        cursor)      echo "${HOME}/.cursor/skills" ;;
        # Current Devin Desktop/Windsurf docs use the ~/.codeium/windsurf
        # application namespace for global skills. This is not a separate
        # legacy Codeium target; the current app still stores data there.
        windsurf)    echo "${HOME}/.codeium/windsurf/skills" ;;
        # Junie documents user skills under ~/.junie/skills. This is Junie,
        # not JetBrains AI Assistant's GUI-managed settings.
        jetbrains)   echo "${HOME}/.junie/skills" ;;
        openclaw)    echo "${HOME}/.openclaw/skills" ;;
        trae)        echo "${HOME}/.trae/skills" ;;
        trae-cn)     echo "${HOME}/.trae-cn/skills" ;;
        # VS Code documents personal skills under ~/.copilot/skills (or
        # ~/.agents/skills). Use the VS Code-documented Copilot location;
        # ~/.vscode is application data, not a skills directory.
        vscode)      echo "${HOME}/.copilot/skills" ;;
        zed)         echo "${HOME}/.agents/skills" ;;
        # Neovim is an editor, not an AI IDE. Its config directory is not a
        # skills store; do not invent a global skills mapping.
        neovim)      echo "" ;;
        # GNU Emacs has no native SKILL.md/skills directory. Third-party
        # packages must not be represented as native Emacs support.
        emacs)       echo "" ;;
        # Continue's .continue directory contains YAML config blocks, not
        # SKILL.md directories. Do not invent a skills mapping.
        continue)    echo "" ;;
        # Aider has no documented native skills directory. Its ~/.aider.conf.yml
        # is configuration, not a Skills store.
        aider)       echo "" ;;
        roo-code)    echo "${HOME}/.roo/skills" ;;
        cline)       echo "${HOME}/.cline/skills" ;;
        # Amazon Q has no documented Agent Skills directory. Its ~/.aws/amazonq
        # tree contains IDE/CLI state, prompts, and agent/MCP files with
        # different scopes; never treat the whole tree as portable skills.
        amazon-q)    echo "" ;;
        # cody/codeium/tabnine/blackbox: no official Agent Skills directory.
        # Returning "" avoids emitting glob literals (e.g. sourcegraph.cody*)
        # that would otherwise be turned into illegal directory names by mkdir -p.
        cody)        echo "" ;;
        # Codeium is a legacy product name for Windsurf. Its generic
        # ~/.codeium namespace is shared/current state, not a Skills store.
        codeium)     echo "" ;;
        tabnine)     echo "" ;;
        # Replit's documented user-level skills are cloud/account managed;
        # only the project Agent Skills directory has a published filesystem
        # path (.agents/skills). Never treat ~/.replit as a skills tree.
        replit)      echo "" ;;
        # PearAI's official repositories document its VS Code/Continue
        # provenance, but no portable skills directory. Do not infer the
        # application namespace as a skills store.
        pearai)      echo "" ;;
        # Supermaven's official surfaces are host-editor extensions. The
        # maintainer-described ~/.supermaven tree contains sm-agent runtime
        # binaries/cache, not portable Agent Skills.
        supermaven)  echo "" ;;
        # Pieces is a PiecesOS-backed MCP server/desktop integration, not a
        # file-backed Agent Skills host. The official docs do not define a
        # ~/.pieces Skills directory; keep the object unsupported.
        pieces)      echo "" ;;
        blackbox)    echo "" ;;
        # Gemini CLI's user Skills root is the documented ~/.gemini/skills
        # directory; ~/.gemini also contains settings, commands, agents, and
        # private state and must never be copied as a Skills tree.
        gemini-cli)  echo "${HOME}/.gemini/skills" ;;
        # Current Goose Agent Skills use the cross-agent standard locations.
        # ~/.config/goose is the application/config namespace, not a Skills
        # directory; legacy ~/.config/goose/skills is not the canonical path.
        goose-cli)   echo "${HOME}/.agents/skills" ;;
        # OpenCode's global Skills root is the plural skills directory. The
        # parent also contains config, agents, commands, plugins, and other
        # application data, so never expose ~/.config/opencode as a Skills
        # target.
        opencode)    echo "${HOME}/.config/opencode/skills" ;;
        kilocode)    echo "${HOME}/.kilo/skills" ;;
        kimiai)      echo "${HOME}/.kimi-code/skills" ;;
        # WorkBuddy's official docs expose Skills through the marketplace/UI,
        # but do not publish a portable filesystem Skills directory. Keep this
        # empty rather than inferring one from its application namespace.
        workbuddy)   echo "" ;;
        # claude-desktop is MCP-only (no skills dir).
        claude-desktop)    echo "" ;;
        kiro)              echo "${HOME}/.kiro/skills" ;;
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
        antigravity) echo ".agents" ;;
        claude)      echo ".claude" ;;
        # Codex project config lives under .agents (agent defs + skills);
        # .codex is the CLI's own config dir (may hold config.toml with
        # credentials) and must NOT be copied as an opaque project tree.
        codex)       echo ".agents" ;;
        # GitHub Copilot CLI project configuration root. Skills and
        # instructions have their own migration paths below.
        copilot)     echo ".github" ;;
        cursor)      echo ".cursor" ;;
        # `.windsurf` mixes Skills, rules, workflows, memories, and app state;
        # expose only the dedicated object paths and keep whole-project copy
        # fail-closed/manual.
        windsurf)    echo "" ;;
        jetbrains)   echo ".junie" ;;
        # No fixed repository-relative OpenClaw project config root; the
        # active workspace is selected by agents.defaults.workspace.
        openclaw)    echo "" ;;
        trae)        echo ".trae" ;;
        trae-cn)     echo ".trae" ;;
        vscode)      echo ".vscode" ;;
        # .zed contains native settings/tasks/debug files, not a portable
        # project-config target for this generic migrator.
        zed)         echo "" ;;
        # Neovim has no documented project skills/config root.
        neovim)      echo "" ;;
        # .dir-locals.el is native directory-local variables, not a generic
        # project context format; keep cross-IDE project copying manual.
        emacs)       echo "" ;;
        # Continue's workspace configuration blocks live under .continue.
        continue)    echo ".continue" ;;
        # Aider does not document project Skills; .aider.conf.yml is YAML
        # configuration and must not be exposed as a skills path.
        aider)       echo ".aider.conf.yml" ;;
        roo-code)    echo ".roo" ;;
        # .cline contains several object-specific stores (skills/rules,
        # hooks/plugins, and project state). Do not expose it as a generic
        # project-config copy target; use the dedicated object mappings.
        cline)       echo "" ;;
        # .amazonq contains multiple Q-specific scopes (rules and MCP). It is
        # diagnostic-only here; migrate_project refuses to copy the whole
        # directory because that would mix formats and scopes.
        amazon-q)    echo ".amazonq" ;;
        # Cody has no documented portable project configuration namespace.
        # Do not infer the historical .cody directory.
        cody)        echo "" ;;
        # No standalone Codeium project configuration path is documented.
        # Do not treat generic .codeium state as portable project config.
        codeium)     echo "" ;;
        # Tabnine documents guidelines, not Agent Skills, under .tabnine.
        tabnine)     echo "" ;;
        # Replit project app configuration is .replit; skills use the
        # separate get_project_skills_path resolver below.
        replit)      echo ".replit" ;;
        # PearAI has no documented repository-relative project namespace.
        pearai)      echo "" ;;
        # Supermaven has no documented repository-relative project namespace.
        # .supermavenignore is an indexing-exclusion file, not project config.
        supermaven)  echo "" ;;
        # Pieces has no documented repository-relative project namespace for
        # portable AI configuration. Do not infer .pieces from old heuristics.
        pieces)      echo "" ;;
        # .gemini is the project settings namespace. Skills have their own
        # dedicated path below and the whole namespace is not portable.
        gemini-cli)  echo ".gemini" ;;
        # Blackbox documents .blackbox as the project workspace namespace for
        # Skills. It is not a portable whole-project configuration target;
        # migrate_project has a fail-closed guard for this mixed namespace.
        blackbox)    echo ".blackbox" ;;
        # .goose is a mixed local namespace for recipes and Memory files, not
        # a generic project configuration tree. migrate_project() handles it
        # manually; this diagnostic path is retained for object discovery.
        goose-cli)   echo ".goose" ;;
        # .opencode is a mixed project namespace (skills, agents, commands,
        # plugins, etc.); project Skills have a dedicated resolver below.
        opencode)    echo ".opencode" ;;
        kilocode)    echo ".kilo" ;;
        kimiai)      echo ".kimi-code" ;;
        workbuddy)   echo ".workbuddy" ;;
        claude-desktop)    echo "" ;;  # desktop app: no project-level config
        kiro)              echo ".kiro" ;;
        augment-code)      echo ".augment" ;;
        # Void's repository contains .voidrules, but no verified portable
        # whole-project namespace. Keep project migration fail-closed/manual.
        void-editor)       echo "" ;;
        baidu-comate)      echo ".comate" ;;
        tencent-codebuddy) echo ".codebuddy" ;;
        zcode)             echo ".zcode" ;;
        *)           echo "" ;;
    esac
}

# Project skills are separate from an IDE's project configuration directory.
# Codex documents .agents/skills as its project skill location while reserving
# .codex for trusted project configuration such as config.toml and hooks.json.
get_project_skills_path() {
    local ide="$1"
    case "$ide" in
        antigravity) echo ".agents/skills" ;;
        claude)      echo ".claude/skills" ;;
        codex)       echo ".agents/skills" ;;
        copilot)     echo ".github/skills" ;;
        cursor)      echo ".cursor/skills" ;;
        windsurf)    echo ".windsurf/skills" ;;
        jetbrains)   echo ".junie/skills" ;;
        openclaw)    echo "skills" ;;
        trae)        echo ".trae/skills" ;;
        trae-cn)     echo ".trae/skills" ;;
        vscode)      echo ".github/skills" ;;
        zed)         echo ".agents/skills" ;;
        # Neovim has no documented project skills format.
        neovim)      echo "" ;;
        # .dir-locals.el is Emacs Lisp data, not a portable skills format.
        emacs)       echo "" ;;
        # Continue has no documented SKILL.md project format.
        continue)    echo "" ;;
        aider)       echo "" ;;
        roo-code)    echo ".roo/skills" ;;
        cline)       echo ".cline/skills" ;;
        # No official Amazon Q Agent Skills path is documented.
        amazon-q)    echo "" ;;
        # Cody has no documented Agent Skills directory.
        cody)        echo "" ;;
        # Codeium was rebranded as Windsurf; current project Skills belong
        # to .windsurf/skills and are intentionally not duplicated here.
        codeium)     echo "" ;;
        # Tabnine has no documented Agent Skills directory.
        tabnine)     echo "" ;;
        # Replit project skills use the Agent Skills standard, not .replit.
        replit)      echo ".agents/skills" ;;
        # PearAI has no documented project Skills directory.
        pearai)      echo "" ;;
        # Supermaven has no Agent Skills format or project Skills directory.
        supermaven)  echo "" ;;
        # PiecesOS stores workflow memory in its own platform data store; it
        # does not document a project SKILL.md directory.
        pieces)      echo "" ;;
        # Blackbox CLI documents project skills below .blackbox/skills.
        # There is no documented global Skills directory.
        blackbox)    echo ".blackbox/skills" ;;
        gemini-cli)  echo ".gemini/skills" ;;
        # Goose uses the universal Agent Skills project location. The .goose
        # namespace is only a backward-compatible Skills location and is not
        # the canonical project target.
        goose-cli)   echo ".agents/skills" ;;
        opencode)    echo ".opencode/skills" ;;
        kilocode)    echo ".kilo/skills" ;;
        kimiai)      echo ".kimi-code/skills" ;;
        workbuddy)   echo "" ;;
        claude-desktop) echo "" ;;
        kiro)        echo ".kiro/skills" ;;
        augment-code) echo ".augment/skills" ;;
        void-editor) echo "" ;;
        baidu-comate) echo ".comate/skills" ;;
        tencent-codebuddy) echo ".codebuddy/skills" ;;
        zcode)       echo "" ;;
        *)           echo "" ;;
    esac
}

# Project-scoped MCP configuration is separate from both the project
# configuration directory and the user/local MCP store. This resolver is used
# by the explicit `--scope project` / `--objects project-mcp` path; entries whose
# schema or precedence is not safe remain guarded as manual in migrate_mcp().
get_amazon_q_project_mcp_path() {
    local project_root="${WORKSPACE_ROOT:-$(pwd)}"
    local default_path="${project_root}/.amazonq/default.json"
    local legacy_path="${project_root}/.amazonq/mcp.json"

    # The current IDE guide names .amazonq/default.json. Preserve an existing
    # legacy file when a workspace was already configured. The separate
    # .amazonq/agents/default.json path is documented by another Q surface but
    # AWS does not publish a version/implementation discriminator; it is
    # handled as an explicit manual boundary below rather than guessed here.
    if [[ -f "$default_path" ]]; then
        echo ".amazonq/default.json"
    elif [[ -f "$legacy_path" ]]; then
        echo ".amazonq/mcp.json"
    else
        echo ".amazonq/default.json"
    fi
}

get_project_mcp_path() {
    local ide="$1"
    case "$ide" in
        antigravity) echo ".agents/mcp_config.json" ;;
        claude) echo ".mcp.json" ;;
        codex) echo ".codex/config.toml" ;;
        # GitHub Copilot CLI also discovers .github/mcp.json.  This resolver
        # exposes the root-level canonical path only; migration never picks
        # between the two project files automatically.
        copilot) echo ".mcp.json" ;;
        cursor) echo ".cursor/mcp.json" ;;
        zed) echo ".zed/settings.json" ;;
        # VS Code's documented workspace MCP file is portable. User MCP is
        # intentionally absent from get_mcp_path because its official path is
        # exposed through the active profile/UI rather than a portable path.
        vscode) echo ".vscode/mcp.json" ;;
        jetbrains) echo ".junie/mcp/mcp.json" ;;
        # Trae documents project MCP in the project .trae directory. The
        # generic workflow only exposes this as a diagnostic/manual path.
        trae) echo ".trae/mcp.json" ;;
        trae-cn) echo ".trae/mcp.json" ;;
        # Roo documents project MCP at .roo/mcp.json. Its global MCP is still
        # extension-settings/UI managed, so this project path remains manual.
        roo-code) echo ".roo/mcp.json" ;;
        # Cline's CLI reference documents a project .cline/mcp.json file with
        # the mcpServers root. It is separate from the global MCP stores.
        cline) echo ".cline/mcp.json" ;;
        # Current Amazon Q IDE workspaces use .amazonq/default.json. If an
        # existing agents/default.json or legacy mcp.json is present, retain
        # that configured store; see get_amazon_q_project_mcp_path().
        amazon-q) echo "$(get_amazon_q_project_mcp_path)" ;;
        # Continue's project MCP path is a directory of standalone YAML/JSON
        # blocks, not one MCP file. This is diagnostic/manual only.
        continue) echo ".continue/mcpServers" ;;
        # Tabnine documents this project-scoped JSON file; permissions and
        # project precedence remain manual even when the file is selected.
        tabnine) echo ".tabnine/mcp_servers.json" ;;
        # Gemini CLI uses the same JSON settings file at user and project
        # scope. Project settings remain subject to trust/precedence review.
        gemini-cli) echo ".gemini/settings.json" ;;
        # OpenCode stores project MCP in the project-root opencode.json;
        # precedence and merge semantics stay explicit in the report.
        opencode) echo "opencode.json" ;;
        kilocode) echo ".kilo/kilo.jsonc" ;;
        kimiai) echo ".kimi-code/mcp.json" ;;
        workbuddy) echo ".workbuddy/mcp.json" ;;
        kiro) echo ".kiro/settings/mcp.json" ;;
        augment-code) echo ".augment/settings.json" ;;
        baidu-comate) echo ".comate/mcp.json" ;;
        # Void's inherited VS Code MCP contribution discovers this workspace
        # file with root `servers`; the Void-specific writer never targets it.
        void-editor) echo ".vscode/mcp.json" ;;
        # CodeBuddy's documented project MCP file is root-level .mcp.json;
        # the .codebuddy directory contains settings/agents/skills instead.
        tencent-codebuddy) echo ".mcp.json" ;;
        zcode) echo ".zcode/config.json" ;;
        # Pieces has no client-side project MCP file; its MCP endpoint is
        # configured in the consuming IDE.
        pieces) echo "" ;;
        # Supermaven has no documented project MCP file or server schema.
        supermaven) echo "" ;;
        *)      echo "" ;;
    esac
}

# Project configuration is also diagnostic-only. Codex loads this file only
# for trusted projects, and it can contain MCP and hook settings; it must not
# be conflated with the .agents project-skill directory or copied by the
# generic global-config migration.
get_project_config_file() {
    local ide="$1"
    case "$ide" in
        claude) echo ".claude/settings.json" ;;
        codex) echo ".codex/config.toml" ;;
        # Gemini CLI project settings are JSON and share the exact path with
        # project MCP. This is diagnostic-only; migrate_config refuses to
        # copy a foreign IDE schema into settings.json.
        gemini-cli) echo ".gemini/settings.json" ;;
        # OpenCode's project config is the root opencode.json file. It is a
        # merged, target-specific schema and is diagnostic/manual here.
        opencode) echo "opencode.json" ;;
        kilocode) echo ".kilo/kilo.jsonc" ;;
        augment-code) echo ".augment/settings.json" ;;
        tencent-codebuddy) echo ".codebuddy/settings.json" ;;
        zcode) echo ".zcode/config.json" ;;
        # Diagnostic only: .replit is app/runtime configuration, never an AI
        # skills or generic project-context copy target.
        replit) echo ".replit" ;;
        # PiecesOS data and settings are application-managed, not a portable
        # project config file.
        pieces) echo "" ;;
        # Supermaven has no documented project config file.
        supermaven) echo "" ;;
        *)     echo "" ;;
    esac
}

get_rules_file() {
    local ide="$1"
    case "$ide" in
        # Cursor rules are a directory of MDC files; migration handles this
        # as manual because the generic rules copier only supports one file.
        cursor)      echo ".cursor/rules" ;;
        # Current Devin Desktop prefers .devin/rules/*.md and keeps
        # .windsurf/rules/*.md/.windsurfrules for compatibility. The generic
        # single-file migrator must treat the directory form as manual.
        windsurf)    echo ".devin/rules" ;;
        copilot)     echo ".github/copilot-instructions.md" ;;
        vscode)      echo ".github/copilot-instructions.md" ;;
        openclaw)    echo "AGENTS.md" ;;
        claude)      echo "CLAUDE.md" ;;
        aider)       echo "CONVENTIONS.md" ;;
        cline)       echo ".clinerules" ;;
        # Continue rules are a directory of Markdown/YAML rule blocks. The
        # single-file rules copier cannot flatten or reinterpret the block
        # directory safely.
        continue)    echo ".continue/rules" ;;
        # Tabnine guidelines are a directory of Markdown files. The generic
        # rules copier only supports one file, so migrate_rules fails closed.
        tabnine)     echo ".tabnine/guidelines" ;;
        # Supermaven's .supermavenignore controls repository indexing only; it
        # is not an instruction/rules file and must not be copied as one.
        supermaven)  echo "" ;;
        roo-code)    echo ".roorules" ;;
        # Cody has no documented project-instructions file.
        cody)        echo "" ;;
        # PearAI has no documented portable rules file or directory.
        pearai)      echo "" ;;
        # Blackbox's first-party docs do not define a portable rules file or
        # directory. Do not infer .blackbox/rules or a root instruction file.
        blackbox)    echo "" ;;
        # Pieces rules/context are managed by PiecesOS and the host
        # integration; no portable project rules file is documented.
        pieces)       echo "" ;;
        codex)       echo "AGENTS.md" ;;
        gemini-cli)  echo "GEMINI.md" ;;
        goose-cli)   echo ".goosehints" ;;
        opencode)    echo "AGENTS.md" ;;
        kilocode)    echo "AGENTS.md" ;;
        kimiai)      echo "AGENTS.md" ;;
        zed)         echo "AGENTS.md" ;;
        zcode)       echo "AGENTS.md" ;;
        # Antigravity IDE workspace rules are a directory. The global
        # ~/.gemini/GEMINI.md rule is outside this project resolver.
        antigravity) echo ".agents/rules" ;;
        # Amazon Q project rules are a directory of Markdown files.
        amazon-q)    echo ".amazonq/rules" ;;
        # Junie in JetBrains IDEs reads repository-root AGENTS.md. The
        # .junie/guidelines.md location belongs to Junie CLI documentation.
        # Junie now prefers .junie/AGENTS.md; root AGENTS.md and legacy
        # .junie/guidelines.md remain compatibility inputs handled manually
        # by migrate_rules when the canonical file is absent.
        jetbrains)   echo ".junie/AGENTS.md" ;;
        # Replit Agent reads project instructions from the root replit.md.
        replit)      echo "replit.md" ;;
        void-editor) echo ".voidrules" ;;
        tencent-codebuddy) echo "CODEBUDDY.md" ;;
        # Kilo/Kiro/Augment/Comate rules are directory-scoped, not a single
        # file. Their dedicated migration objects remain manual below.
        # Kiro/Augment/Comate rules are directory-scoped and handled by
        # explicit manual guards below rather than flattened by this
        # single-file resolver.
        kiro|augment-code|baidu-comate) echo "" ;;
        trae|trae-cn) echo ".trae/rules" ;;
        # Pieces does not provide a portable project rules file.
        pieces)       echo "" ;;
        *)           echo "" ;;
    esac
}

get_prompts_path() {
    local ide="$1"
    case "$ide" in
        # VS Code workspace prompt files are documented here. The user-level
        # location is UI/profile-managed and has no portable official path.
        vscode)      echo ".github/prompts" ;;
        cursor)      echo ".cursor/commands" ;;
        windsurf)    echo ".windsurf/workflows" ;;
        # Copilot prompt files are supported by IDE surfaces, not the CLI.
        # The canonical copilot target is GitHub Copilot CLI, so do not
        # offer an unsupported prompt-file migration target here.
        # OpenClaw documents skills and workspace bootstrap files, not a
        # standalone prompt-template directory.
        openclaw)    echo "" ;;
        continue)    echo ".continue/prompts" ;;
        # Cline calls reusable prompt-like files workflows. The documented
        # workflow locations are not a prompt-template contract, so keep the
        # generic prompts object manual rather than copying into a guessed
        # directory.
        cline)       echo "" ;;
        # Blackbox documents /skill commands, not a prompt-template directory.
        blackbox)    echo "" ;;
        # Claude Code still loads this legacy compatibility location. New
        # commands should be skills under .claude/skills instead.
        claude)      echo ".claude/commands" ;;
        gemini-cli)  echo ".gemini/commands" ;;
        # Goose prompt templates are global files under ~/.config/goose and
        # slash commands are YAML entries in config.yaml. The generic prompt
        # copier is project-relative and cannot safely migrate either form.
        goose-cli)   echo "" ;;
        # OpenCode custom command files are Markdown under the project
        # .opencode namespace. Global commands live under
        # ~/.config/opencode/commands and are outside this project-relative
        # object; migrate_prompts handles only the documented project files.
        opencode)    echo ".opencode/commands" ;;
        # Roo Code slash commands are documented Markdown files. They are
        # exposed through the prompts object with a manual semantic review;
        # this does not claim that Roo modes or command permissions convert.
        roo-code)    echo ".roo/commands" ;;
        trae|trae-cn) echo ".trae/commands" ;;
        # Pieces prompt and memory workflows are handled by PiecesOS/host UI,
        # not a portable prompt-template directory.
        pieces)      echo "" ;;
        *)           echo "" ;;
    esac
}

get_mcp_path() {
    local ide="$1"
    case "$ide" in
        # The official international docs do not publish a stable user-scope
        # MCP file path, so global MCP is UI/manual only.
        trae) echo "" ;;
        # TRAE CN's official docs document project .trae/mcp.json and the
        # Settings/raw-JSON workflow, but do not publish a stable user MCP
        # filesystem path. Do not promote community/forum paths to an
        # automatic target.
        trae-cn)     echo "" ;;
        openclaw)    echo "${HOME}/.openclaw/openclaw.json" ;;
        # User-scope MCP mapping. Claude Code stores both user and local MCP
        # scope in this file; this mapper only handles the user-level server
        # map. Shared project scope is .mcp.json (get_project_mcp_path) and
        # local per-project entries require manual review.
        claude)      echo "${HOME}/.claude.json" ;;
        # Continue's global file is YAML and its mcpServers value is an
        # array. The generic mapper exposes this path for diagnosis only.
        continue)    echo "${HOME}/.continue/config.yaml" ;;
        # Cline's MCP settings live in the VS Code extension globalStorage
        # (confirmed by docs.cline.bot/mcp and multiple independent sources,
        # 2026-07: the file is cline_mcp_settings.json under
        # saoudrizwan.claude-dev/settings/ in the VS Code user-data dir). The
        # legacy ~/.cline/mcp.json CLI alternative is detected by migrate_mcp()
        # and reported for manual selection when both files exist; --print-path
        # returns the authoritative globalStorage path. CLINE_MCP_PATH overrides
        # everything for non-standard installs (e.g. VS Code Insiders, VSCodium,
        # or a relocated --user-data-dir).
        cline)
            if [[ -n "${CLINE_MCP_PATH:-}" ]]; then
                echo "${CLINE_MCP_PATH}"
            else
                case "$(uname -s)" in
                    Darwin) echo "${HOME}/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json" ;;
                    Linux)  echo "${HOME}/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json" ;;
                    *)      echo "${HOME}/AppData/Roaming/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json" ;;
                esac
            fi ;;
        cursor)      echo "${HOME}/.cursor/mcp.json" ;;
        # Roo's official docs identify the global extension settings directory
        # but do not publish a stable literal filesystem path. Do not guess
        # VS Code globalStorage or Cline's similarly named file.
        roo-code)    echo "" ;;
        windsurf)    echo "${HOME}/.codeium/windsurf/mcp_config.json" ;;
        jetbrains)   echo "${HOME}/.junie/mcp/mcp.json" ;;
        antigravity) echo "${HOME}/.gemini/config/mcp_config.json" ;;
        # Kilo Code's global config is ~/.config/kilo/kilo.jsonc; its project
        # files are exposed separately through project-mcp/project-config.
        kilocode)    echo "${HOME}/.config/kilo/kilo.jsonc" ;;
        gemini-cli)  echo "${HOME}/.gemini/settings.json" ;;
        goose-cli)   echo "${HOME}/.config/goose/config.yaml" ;;
        codex)       echo "${HOME}/.codex/config.toml" ;;
        # Aider has no native MCP configuration; .aider.conf.yml is not MCP.
        aider)       echo "" ;;
        kimiai)      echo "${HOME}/.kimi-code/mcp.json" ;;
        workbuddy)   echo "${HOME}/.workbuddy/mcp.json" ;;
        # copilot = GitHub Copilot CLI: ~/.copilot/mcp-config.json, root key
        # mcpServers (project .mcp.json ALSO uses mcpServers, unlike VS Code).
        copilot)     echo "${HOME}/.copilot/mcp-config.json" ;;
        # VS Code user MCP belongs to the active Profile. Default, named,
        # Insiders/VSCodium, and relocated --user-data-dir installations do
        # not share one safely inferable path. Resolve it through
        # "MCP: Open User Configuration" instead of guessing a profile.
        vscode)      echo "" ;;
        zed)         echo "${HOME}/.config/zed/settings.json" ;;
        opencode)    echo "${HOME}/.config/opencode/opencode.json" ;;
        # The current IDE guide names default.json; the overview page and
        # language-server source also expose agents/default.json, while
        # mcp.json is a documented legacy store. Prefer the current file for a
        # fresh install, but preserve whichever configured file already exists.
        amazon-q)
            local q_default="${HOME}/.aws/amazonq/default.json"
            local q_legacy="${HOME}/.aws/amazonq/mcp.json"
            if [[ -f "$q_default" ]]; then
                echo "$q_default"
            elif [[ -f "$q_legacy" ]]; then
                echo "$q_legacy"
            else
                echo "$q_default"
            fi
            ;;
        # PearAI MCP storage/schema is not published by its official
        # repositories; UI/extension-managed settings are manual only.
        pearai)      echo "" ;;
        # Blackbox documents only the bundled `blackbox mcp` command, not a
        # portable user/project MCP file or server-map schema.
        blackbox)    echo "" ;;
        # Pieces exposes MCP as a server from PiecesOS. MCP client files are
        # configured in the host IDE, not in a Pieces-owned file path.
        pieces)      echo "" ;;
        # Supermaven is a completion extension with no documented MCP file or
        # portable server schema. Do not infer one from the host editor.
        supermaven)  echo "" ;;
        # Cody MCP is a cody.mcpServers extension setting/UI surface, not a
        # documented standalone file. Keep automatic file migration empty.
        cody)        echo "" ;;
        tabnine)     echo "${HOME}/.tabnine/mcp_servers.json" ;;
        # Claude Desktop's legacy local MCP JSON path is officially documented
        # for macOS and Windows. Linux Desktop has no equivalently documented
        # path in the current local-MCP guide, so it remains UI/manual there.
        claude-desktop)
            case "$(uname -s)" in
                Darwin)
                    echo "${HOME}/Library/Application Support/Claude/claude_desktop_config.json"
                    ;;
                MINGW*|MSYS*|CYGWIN*)
                    echo "${APPDATA:-${HOME}/AppData/Roaming}/Claude/claude_desktop_config.json"
                    ;;
                *)
                    echo ""
                    ;;
            esac
            ;;
        kiro)              echo "${HOME}/.kiro/settings/mcp.json" ;;
        augment-code)      echo "${HOME}/.augment/settings.json" ;;
        # Void's first-party source resolves MCP to userHome/dataFolderName/
        # mcp.json; product.json sets dataFolderName to .void-editor.
        void-editor)       echo "${HOME}/.void-editor/mcp.json" ;;
        baidu-comate)      echo "${HOME}/.comate/mcp.json" ;;
        # CodeBuddy Code's official MCP docs define the user file and its
        # precedence: ~/.codebuddy/.mcp.json, then legacy alternatives.
        tencent-codebuddy) echo "${HOME}/.codebuddy/.mcp.json" ;;
        zcode)             echo "${HOME}/.zcode/cli/config.json" ;;
        *)           echo "" ;;
    esac
}

get_config_file() {
    local ide="$1"
    case "$ide" in
        # Do not infer argv.json or another undocumented global config path.
        trae) echo "" ;;
        trae-cn)     echo "" ;;
        openclaw)    echo "${HOME}/.openclaw/openclaw.json" ;;
        # Cursor's settings database path is not a documented migration
        # contract for this tool; do not infer a platform-specific target.
        cursor)      echo "" ;;
        # windsurf: no documented standalone settings file (config lives in
        # ~/.codeium/windsurf/) — empty prevents inventing one.
        windsurf)    echo "" ;;
        # VS Code settings have platform-specific documented paths, but this
        # generic mapper has no portable platform selector and settings are
        # outside the supported migration objects. Keep it manual/empty.
        vscode)      echo "" ;;
        # Zed settings are native editor configuration, not a portable
        # whole-IDE config target for this mapper.
        zed)         echo "" ;;
        neovim)      echo "${HOME}/.config/nvim/init.lua" ;;
        # Emacs supports several init-file locations (including ~/.emacs,
        # ~/.emacs.el, ~/.emacs.d/init.el, and XDG init.el). A single guessed
        # path and generic copy would be unsafe; handle init.el manually.
        emacs)       echo "" ;;
        continue)    echo "${HOME}/.continue/config.yaml" ;;
        aider)       echo "${HOME}/.aider.conf.yml" ;;
        # Cline's config directory contains provider credentials and mutable
        # application state. There is no safe portable whole-config target;
        # never copy the obsolete/undocumented ~/.cline/config.json.
        cline)       echo "" ;;
        # roo-code: no standalone global config file documented (settings sit
        # in VS Code extension storage) — empty prevents inventing one.
        roo-code)    echo "" ;;
        # User settings mapping. Project and local settings have separate
        # documented scopes and are not collapsed into this single file path.
        claude)      echo "${HOME}/.claude/settings.json" ;;
        # .replit and replit.nix are project app/runtime files, not a global
        # AI config path. Keep the global config resolver empty.
        replit)      echo "" ;;
        # PearAI has no documented portable whole-config file.
        pearai)      echo "" ;;
        # `blackbox configure` is interactive and its storage path/schema is
        # not published in the current first-party CLI docs.
        blackbox)    echo "" ;;
        # PiecesOS/Desktop settings and its local database are not a portable
        # whole-IDE config file and must never be copied as one.
        pieces)      echo "" ;;
        # Supermaven settings live in the host editor/Neovim configuration;
        # no standalone portable config file is documented.
        supermaven)  echo "" ;;
        gemini-cli)  echo "${HOME}/.gemini/settings.json" ;;
        goose-cli)   echo "${HOME}/.config/goose/config.yaml" ;;
        codex)       echo "${HOME}/.codex/config.toml" ;;
        opencode)    echo "${HOME}/.config/opencode/opencode.json" ;;
        kilocode)    echo "${HOME}/.config/kilo/kilo.jsonc" ;;
        kimiai)      echo "${HOME}/.kimi-code/config.toml" ;;
        tencent-codebuddy) echo "${HOME}/.codebuddy/settings.json" ;;
        augment-code)      echo "${HOME}/.augment/settings.json" ;;
        zcode)             echo "${HOME}/.zcode/cli/config.json" ;;
        # Claude Desktop settings and extension state are UI-managed; do not
        # treat the legacy local MCP JSON as a portable whole-config file.
        claude-desktop) echo "" ;;
        *)           echo "" ;;
    esac
}

# Returns the MCP server map root key used by an IDE's MCP config file.
# Mirrors the IDE Registry (mcpServers | servers | context_servers |
# mcp.servers | mcp | extensions). Used by convert_mcp_file to map between
# source and target formats.
get_mcp_root_key() {
    local ide="$1"
    local scope="${2:-global}"
    # Void's project MCP path is the inherited VS Code `.vscode/mcp.json`
    # (see `get_project_mcp_path`), which uses the VS Code `servers` root
    # key — NOT the legacy Void-global `mcpServers` schema. At user/global
    # scope, Void uses its own `~/.void-editor/mcp.json` with `mcpServers`.
    if [[ "$ide" == "void-editor" && "$scope" == "project" ]]; then
        echo "servers"
        return 0
    fi
    case "$ide" in
        claude|claude-desktop|cursor|windsurf|gemini-cli|trae|trae-cn|continue|cline|roo-code|antigravity|amazon-q|kimiai|workbuddy|copilot|kiro|augment-code|void-editor|baidu-comate|tencent-codebuddy|cody|tabnine|jetbrains)
            echo "mcpServers" ;;
        codex)       echo "mcp_servers" ;;
        goose-cli)   echo "extensions" ;;
        zed)         echo "context_servers" ;;
        openclaw)    echo "mcp.servers" ;;
        opencode)
            if [[ "$OPENCODE_VERSION" == "v2" ]]; then
                echo "mcp.servers"
            else
                echo "mcp"
            fi
            ;;
        kilocode)    echo "mcp" ;;
        # VS Code user-level mcp.json uses `servers` (NOT mcpServers).
        vscode)      echo "servers" ;;
        # zcode natively nests under mcp.servers (dot-path), but it also
        # accepts a flat mcpServers key (import-compat), which is what
        # convert_mcp_file can produce with a single top-level key.
        zcode)       echo "mcp.servers" ;;
        # Aider has no native MCP root key; keep MCP conversion fail-closed.
        aider)       echo "" ;;
        # Blackbox has no documented portable MCP root key.
        blackbox)    echo "" ;;
        # Pieces is the MCP provider/server, not a client-side MCP schema.
        pieces)      echo "" ;;
        # Supermaven has no documented MCP file or root key.
        supermaven)  echo "" ;;
        *)           echo "" ;;
    esac
}

usage() {
    cat <<'EOF'
IDE Migration Tool - Migrate configuration between different AI IDEs

Usage: smart-ide-migration.sh [options]

Required arguments:
  --source <ide>         source IDE (which IDE to migrate from)
  --target <ide>         target IDE (which IDE to migrate to)

Optional arguments:
  --workspace <dir>      workspace root directory (default: current directory)
  --objects <list>       content types to migrate (comma-separated)
  --source-mcp-file <file>
                          explicit MCP source file; --source still defines its schema
  --opencode-version <v1|v2>
                          OpenCode target MCP schema (default: v1 legacy-compatible)
  --scope <scope>        Skills/MCP scope: global, project, both (default: global)
  --strategy <mode>      migration strategy: skip, overwrite, backup (default: backup)
                          skip preserves an existing object; backup snapshots then merges;
                          overwrite replaces only the selected object without a backup
  --report <file>        save migration report to file
  --dry-run              preview mode, does not actually modify files
  --yes, -y              confirm writing. Explicit confirmation required when not in dry-run:
                          interactive terminal will prompt [y/N]; non-interactive environment (CI/agent) lacking
                          --yes will abort immediately and write no files
  --print-path <ide> <object>
                          read-only diagnosis: print resolved paths for the specified IDE/object type and exit (no side effects)
                          object ∈ global|project|project-skills|mcp|project-mcp|project-config|config|rules|prompts|commands
  -h, --help             show help information

Supported IDEs:
  antigravity  - Antigravity
  claude       - Claude Code
  codex        - OpenAI Codex CLI
  copilot      - GitHub Copilot CLI
  cursor       - Cursor
  windsurf     - Windsurf
  jetbrains    - JetBrains IDEs
  openclaw     - OpenClaw
  trae         - Trae (International version)
  trae-cn      - Trae CN (China version)
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
  kiro         - Kiro
  augment-code - Augment Code
  void-editor  - Void Editor
  baidu-comate - Baidu Comate (ERNIE Code)
  tencent-codebuddy - Tencent CodeBuddy
  zcode        - ZCode (Zhipu)

Supported CLI tools:
  gemini-cli   - Gemini CLI (Google)
  goose-cli    - Goose CLI (Block)
  opencode     - OpenCode
  kilocode     - Kilo Code
  kimiai       - Kimi AI CLI
  workbuddy    - WorkBuddy

Content types:
  skills       - skills/Skills (SKILL.md)
  rules        - rules files (.cursorrules, .windsurfrules, etc.)
  prompts      - prompt templates
  mcp          - MCP server configuration
  project-mcp  - explicitly migrate project MCP files (equivalent to --objects mcp --scope project)
  config       - IDE configuration file
  project      - project-level configuration
  agents       - Agents/Subagents diagnosis (manual handling only, not auto-converted)
  hooks        - lifecycle Hooks diagnosis (manual handling only, not copied or executed)
  memory       - Memory/Memory Bank diagnosis (manual handling only, not copying generated state)

Example (recommended two-stage: first --dry-run to preview, then add --yes to apply):
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

# Remove one verified tree without following symlinks. `find -depth -delete`
# avoids passing a computed path to recursive force removal while still making
# fail-closed cleanup deterministic on both BSD and GNU find.
remove_verified_tree() {
    local target="$1"

    if [[ -L "$target" ]]; then
        rm -f -- "$target"
    elif [[ -d "$target" ]]; then
        find "$target" -xdev -depth -delete
    elif [[ -e "$target" ]]; then
        rm -f -- "$target"
    else
        return 1
    fi
}

# Safely remove a single skill directory nested directly under a parent dir.
# Guards against recursive-deletion foot-guns before deleting anything:
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
        echo "  [GUARD] refused to delete: target directory or skill name is empty (parent='$parent', name='$name')" >&2
        return 1
    fi
    case "$name" in
        */*|.|..|.*/*|-*)
            echo "  [GUARD] refused to delete: illegal skill name '$name' (path separators/traversal/leading dash forbidden)" >&2
            return 1
            ;;
    esac

    local target="$parent/$name"
    if [[ -L "$target" ]]; then
        # A symlink here could point outside the parent; unlink only the link.
        remove_verified_tree "$target"
        return $?
    fi
    if [[ ! -d "$target" ]]; then
        echo "  [GUARD] skipped deletion: target is not a directory or does not exist '$target'" >&2
        return 1
    fi

    remove_verified_tree "$target"
}

# Remove one existing file or directory only when its resolved parent remains
# inside the approved workspace root. The final component is handled without
# following symlinks, preventing an overwrite or fail-closed cleanup from
# escaping through a workspace-controlled link.
safe_remove_path_within() {
    local allowed_root="$1"
    local target="$2"
    local allowed_real target_parent_real target_name

    if [[ -z "$allowed_root" || -z "$target" || ! -d "$allowed_root" ]]; then
        echo "  [GUARD] refused to delete: invalid containment root or target" >&2
        return 1
    fi

    allowed_real="$(cd "$allowed_root" 2>/dev/null && pwd -P)" || return 1
    target_parent_real="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)" || {
        echo "  [GUARD] refused to delete: target parent cannot be resolved '$target'" >&2
        return 1
    }
    target_name="$(basename "$target")"

    if [[ -z "$target_name" || "$target_name" == "." || "$target_name" == ".." ]]; then
        echo "  [GUARD] refused to delete: invalid target name '$target_name'" >&2
        return 1
    fi
    case "$target_parent_real" in
        "$allowed_real"|"$allowed_real"/*) ;;
        *)
            echo "  [GUARD] refused to delete path outside workspace: $target" >&2
            return 1
            ;;
    esac

    if [[ ! -L "$target" && ! -e "$target" ]]; then
        echo "  [GUARD] skipped deletion: target does not exist '$target'" >&2
        return 1
    fi
    remove_verified_tree "$target"
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
    # Some supported IDEs store rules in a directory (for example
    # .cursor/rules, .devin/rules, or .agents/rules), while the generic
    # single-file migrator will later route those through manual handling.
    # Detect both files and directories here so the default object list does
    # not silently hide an available rules directory.
    if [[ -n "$rules_file" ]] && [[ -e "$WORKSPACE_ROOT/$rules_file" ]]; then
        objects+="rules,"
    fi

    local prompts_path
    prompts_path=$(get_prompts_path "$source_ide")
    if [[ -n "$prompts_path" ]] && [[ -d "$WORKSPACE_ROOT/$prompts_path" ]]; then
        objects+="prompts,"
    fi

    local mcp_path
    mcp_path=$(get_mcp_path "$source_ide")
    # Project-relative MCP paths (e.g. Kilo's .kilo/kilo.jsonc) resolve
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
    MIGRATION_EVIDENCE_FILE=$(mktemp)
}

cleanup_migration_files() {
    [[ -f "$MIGRATION_STATUS_FILE" ]] && rm -f "$MIGRATION_STATUS_FILE"
    [[ -f "$MIGRATION_MESSAGES_FILE" ]] && rm -f "$MIGRATION_MESSAGES_FILE"
    [[ -f "$MIGRATION_MANUAL_FILE" ]] && rm -f "$MIGRATION_MANUAL_FILE"
    [[ -f "$MIGRATION_EVIDENCE_FILE" ]] && rm -f "$MIGRATION_EVIDENCE_FILE"
    [[ -n "${REDACTOR_PY:-}" && -f "${REDACTOR_PY:-}" ]] && rm -f "$REDACTOR_PY"
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

sha256_file() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())' "$file"
    else
        return 1
    fi
}

validate_evidence_target() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "absent"
        return 0
    fi
    case "$file" in
        *.json|*.jsonc)
            if command -v python3 >/dev/null 2>&1 && \
               python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$file" >/dev/null 2>&1; then
                echo "valid-json"
            else
                echo "invalid-json"
            fi
            ;;
        *)
            echo "unverified-format"
            ;;
    esac
}

json_string_or_null() {
    local value="$1"
    if [[ -n "$value" ]]; then
        printf '"%s"' "$(json_escape "$value")"
    else
        printf 'null'
    fi
}

record_mcp_evidence() {
    local scope="$1"
    local source_path="$2"
    local target_path="$3"
    local source_sha256_before="$4"
    local backup_path="${5:-}"
    local source_sha256_after=""
    local target_sha256=""
    local source_unchanged="null"
    local target_exists="false"
    local target_validation
    local status

    source_sha256_after="$(sha256_file "$source_path" 2>/dev/null || true)"
    if [[ -n "$source_sha256_before" && -n "$source_sha256_after" ]]; then
        if [[ "$source_sha256_before" == "$source_sha256_after" ]]; then
            source_unchanged="true"
        else
            source_unchanged="false"
        fi
    fi
    if [[ -f "$target_path" ]]; then
        target_exists="true"
        target_sha256="$(sha256_file "$target_path" 2>/dev/null || true)"
    fi
    target_validation="$(validate_evidence_target "$target_path")"
    status="$(get_status mcp)"

    printf '{"scope":"%s","status":"%s","source_path":"%s","target_path":"%s","source_sha256_before":%s,"source_sha256_after":%s,"source_unchanged":%s,"target_exists":%s,"target_sha256":%s,"target_validation":"%s","backup_path":%s}\n' \
        "$(json_escape "$scope")" \
        "$(json_escape "$status")" \
        "$(json_escape "$source_path")" \
        "$(json_escape "$target_path")" \
        "$(json_string_or_null "$source_sha256_before")" \
        "$(json_string_or_null "$source_sha256_after")" \
        "$source_unchanged" \
        "$target_exists" \
        "$(json_string_or_null "$target_sha256")" \
        "$(json_escape "$target_validation")" \
        "$(json_string_or_null "$backup_path")" \
        >> "$MIGRATION_EVIDENCE_FILE"
}

# MED-A1: shared existing-target strategy handling for skill migration.
# Returns 0 = proceed with copy, 1 = skip this skill, 2 = hard failure.
apply_skill_strategy() {
    local target_global="$1"
    local skill_name="$2"
    [[ -d "$target_global/$skill_name" ]] || return 0
    case "$STRATEGY" in
        skip)
            echo "  [SKIP] skill already exists: $skill_name" 
            return 1
            ;;
        backup)
            local timestamp
            timestamp="$(date +%Y%m%d%H%M%S).$$"
            mv "$target_global/$skill_name" "$target_global/$skill_name.bak.$timestamp"
            echo "  [BACKUP] backup already exists: $skill_name" 
            ;;
        overwrite)
            if ! safe_remove_skill_dir "$target_global" "$skill_name"; then
                echo "  [FAIL] safe delete before overwrite failed, skipped: $skill_name" 
                return 2
            fi
            ;;
    esac
    return 0
}

migrate_global_skills() {
    local source_ide="$1"
    local target_ide="$2"
    local strategy_rc

    if [[ "$source_ide" == "pieces" || "$target_ide" == "pieces" ]]; then
        set_status "skills" "manual"
        set_message "skills" "Pieces uses PiecesOS/host integrations, not a file-backed Agent Skills directory"
        set_manual_step "skills" "Pieces: do not use ~/.pieces or .pieces as a Skills path; install/configure Pieces MCP in the consuming IDE through PiecesOS/Desktop MCP settings or pieces mcp setup"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Blackbox's documented Skills location is project-scoped
    # .blackbox/skills. This generic operation migrates global skill
    # directories and has no project-scope selector, so review it manually.
    if [[ "$source_ide" == "blackbox" || "$target_ide" == "blackbox" ]]; then
        MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))
        set_status "skills" "manual"
        set_message "skills" "Blackbox only documents project .blackbox/skills; this migrator has no automatic project Skills migration" 
        set_manual_step "skills" "Blackbox AI CLI: manually review and migrate project .blackbox/skills/<name>/SKILL.md; do not infer ~/.blackbox or treat .blackbox as a global skills directory" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "replit" || "$target_ide" == "replit" ]]; then
        set_status "skills" "manual"
        set_message "skills" "Replit project Skills use .agents/skills; .local/secondary_skills is a separate compatibility directory and no user-global filesystem path is documented"
        set_manual_step "skills" "Replit: review .agents/skills/<name>/SKILL.md and .local/secondary_skills/ separately; validate name/description frontmatter and preserve scripts/references/assets; do not infer a global Skills path"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Supermaven is a host-editor completion extension. Its official
    # surfaces document editor/Neovim configuration, not an Agent Skills
    # directory; ~/.supermaven is runtime/binary storage, not a skill store.
    if [[ "$source_ide" == "supermaven" || "$target_ide" == "supermaven" ]]; then
        set_status "skills" "manual"
        set_message "skills" "Supermaven has no documented portable Agent Skills directory; automatic migration is unsupported"
        set_manual_step "skills" "Supermaven: review the host editor extension or Neovim configuration manually; do not treat ~/.supermaven runtime storage or .supermaven as a Skills directory"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "goose-cli" || "$target_ide" == "goose-cli" ]]; then
        set_manual_step "skills" "Goose: this global operation uses ~/.agents/skills; review project .agents/skills and legacy .goose/skills separately, and do not treat ~/.config/goose as a Skills directory"
    fi

    if [[ "$source_ide" == "opencode" || "$target_ide" == "opencode" ]]; then
        set_manual_step "skills" "OpenCode: this operation handles only global ~/.config/opencode/skills; review project .opencode/skills plus .claude/skills/.agents/skills compatibility roots manually"
    fi

    if [[ "$source_ide" == "workbuddy" || "$target_ide" == "workbuddy" ]]; then
        set_status "skills" "manual"
        set_message "skills" "WorkBuddy has an official local-package/UI import, but no stable installed Skills directory or complete package schema"
        set_manual_step "skills" "WorkBuddy: open the left 技能 panel → 添加技能 → 上传技能, then choose the local package and verify it in the Skills list. WorkBuddy also documents OpenClaw community-skill import through this Skills entry point. Its custom package examples use skill.yml + implementation files + README, but the package extension/root and full schema are not published; do not treat SKILL.md as a guaranteed WorkBuddy package and do not infer ~/.workbuddy/skills or .workbuddy/skills"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "void-editor" || "$target_ide" == "void-editor" ]]; then
        set_status "skills" "manual"
        set_message "skills" "Void official source and docs have no Agent Skills directory" 
        set_manual_step "skills" 'Void: `.voidrules` is a rules file, not Agent Skills; do not treat .void-editor or VS Code storage directory as a Skills directory' 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "cody" || "$target_ide" == "cody" ]]; then
        set_status "skills" "manual"
        set_message "skills" "Sourcegraph Cody has no documented Agent Skills directory; automatic migration is unsupported"
        set_manual_step "skills" "Cody: do not use .cody or another inferred skills path; review the current Enterprise extension surface manually and use Amp or another documented Agent Skills target"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi
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
        set_message "skills" "target IDE has no global skills directory, skip" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    if [[ ! -d "$source_global" ]]; then
        set_status "skills" "skipped"
        set_message "skills" "source directory does not exist: $source_global" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    print_progress "MIGRATE" "Migrating skills (Skills)..." 

    local migrated_count=0
    local failed_count=0

    if [[ "$target_ide" == "copilot" ]]; then
        # The canonical copilot target is GitHub Copilot CLI. Its global skill
        # directory is ~/.copilot/skills; .github/skills is a separate,
        # project-scoped discovery location and is not a destination for this
        # global-skills operation.
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
                    ((migrated_count++)) || true
                else
                    strategy_rc=0
                    apply_skill_strategy "$target_global" "$skill_name" || strategy_rc=$?
                    if [[ $strategy_rc -eq 1 ]]; then
                        continue
                    elif [[ $strategy_rc -eq 2 ]]; then
                        failed_count=$((failed_count + 1))
                        continue
                    fi

                    if cp -r "$skill_dir" "$target_global/$skill_name"; then
                        # MED-S3: skill bundles may carry config/env files with
                        # embedded credentials; redact the COPY (never the
                        # source). Fail-closed: on redaction failure remove
                        # the whole copied skill so no secret survives.
                        if redact_project_copy "$target_global/$skill_name" >/dev/null; then
                            echo "  [OK] migrated skill: $skill_name"
                            ((migrated_count++)) || true
                        else
                            # SECURITY: fail-closed — remove only the direct
                            # child copy through the same containment and
                            # symlink guard used by overwrite handling.
                            safe_remove_skill_dir "$target_global" "$skill_name" || true
                            echo "  [FAIL] skill copy redaction failed, deleted copy to prevent key leak: $skill_name"
                            ((failed_count++)) || true
                        fi
                    else
                        echo "  [FAIL] migration failed: $skill_name" 
                        ((failed_count++)) || true
                    fi
                fi
            fi
        done

        set_manual_step "skills" "GitHub Copilot CLI: this operation only migrates global ~/.copilot/skills; for project skills, review .github/skills, .claude/skills or .agents/skills separately" 

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
                ((migrated_count++)) || true
            else
                strategy_rc=0
                apply_skill_strategy "$target_global" "$skill_name" || strategy_rc=$?
                if [[ $strategy_rc -eq 1 ]]; then
                    continue
                elif [[ $strategy_rc -eq 2 ]]; then
                    failed_count=$((failed_count + 1))
                    continue
                fi

                if cp -r "$skill_dir" "$target_global/$skill_name"; then
                    # MED-S3: redact the copied skill bundle (fail-closed).
                    if redact_project_copy "$target_global/$skill_name" >/dev/null; then
                        echo "  [OK] migrated skill: $skill_name"
                        ((migrated_count++)) || true
                    else
                        # SECURITY: fail-closed — see fail-closed note above.
                        safe_remove_skill_dir "$target_global" "$skill_name" || true
                        echo "  [FAIL] skill copy redaction failed, deleted copy to prevent key leak: $skill_name"
                        ((failed_count++)) || true
                    fi
                else
                    echo "  [FAIL] migration failed: $skill_name" 
                    ((failed_count++)) || true
                fi
            fi
        done
    fi

    if [[ "$source_ide" == "vscode" || "$target_ide" == "vscode" ]]; then
        set_manual_step "skills" "VS Code: this operation migrates only personal ~/.copilot/skills; review project .claude/skills and .agents/skills plus alternate personal skill locations manually"
    fi

    if [[ "$source_ide" == "windsurf" || "$target_ide" == "windsurf" ]]; then
        set_manual_step "skills" "Windsurf/Devin: this operation handles only global ~/.codeium/windsurf/skills; review project .windsurf/skills, ~/.agents/skills, .agents/skills, and optional .claude/skills compatibility locations manually"
    fi

    if [[ $failed_count -gt 0 ]]; then
        set_status "skills" "partial"
        set_message "skills" "succeeded $migrated_count, failed $failed_count" 
        MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
    else
        set_status "skills" "success"
        set_message "skills" "successfully migrated $migrated_count skills" 
        MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
    fi
}

project_skills_manual_only() {
    local ide="$1"
    case "$ide" in
        amazon-q|blackbox|claude-desktop|codeium|cody|continue|emacs|neovim|pearai|pieces|replit|supermaven|tabnine|void-editor|workbuddy|zcode)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

migrate_project_skills() {
    local source_ide="$1"
    local target_ide="$2"
    local source_skills target_skills source_path target_path

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    if project_skills_manual_only "$source_ide" || project_skills_manual_only "$target_ide"; then
        set_status "skills" "manual"
        set_message "skills" "project Skills compatibility directory/priority or official path still needs manual review" 
        set_manual_step "skills" "project Skills: only review native project path; do not blindly merge between compatibility directories, unclear-version or UI-only IDEs; preserve SKILL.md, scripts, references, assets and symlink boundaries" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "zcode" || "$target_ide" == "zcode" ]]; then
        set_status "skills" "manual"
        set_message "skills" "ZCode project Skills use an official UI import target without a published stable project directory"
        set_manual_step "skills" "ZCode: open Settings → Skills → Import, select the external skill, choose Copy or Symlink, then choose Project for the current workspace (or Global for all workspaces). Do not infer .zcode/skills as a project path; the documented filesystem path is user-level ~/.zcode/skills"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "workbuddy" || "$target_ide" == "workbuddy" ]]; then
        set_status "skills" "manual"
        set_message "skills" "WorkBuddy project Skills are imported through the Skills UI; no stable project directory or complete package schema is published"
        set_manual_step "skills" "WorkBuddy: left 技能 → 添加技能 → 上传技能, select the reviewed local package, then verify/enable it in the Skills list; OpenClaw community skills use the same import surface. Do not infer a project Skills directory"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    source_skills=$(get_project_skills_path "$source_ide")
    target_skills=$(get_project_skills_path "$target_ide")
    if [[ -z "$source_skills" || -z "$target_skills" ]]; then
        set_status "skills" "manual"
        set_message "skills" "source/target IDE has no confirmable project Skills directory" 
        set_manual_step "skills" "project Skills: source='$source_skills' target='$target_skills'; please select native directory manually according to IDE Registry, do not infer paths" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    source_path="$WORKSPACE_ROOT/$source_skills"
    target_path="$WORKSPACE_ROOT/$target_skills"
    if [[ ! -d "$source_path" ]]; then
        set_status "skills" "skipped"
        set_message "skills" "project Skills source directory does not exist: $source_skills"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Refuse to operate when source and target resolve to the same path.
    # antigravity/codex/zed (and several others) all share `.agents/skills`,
    # and `claude → copilot` / `tencent-codebuddy` share `.mcp.json`. Without
    # this guard, the backup strategy's `mv` would rename the source in
    # place and the subsequent `cp -R` would fail; the overwrite strategy
    # would recursively remove the source with no backup. Either path destroys data.
    if [[ "$(cd "$source_path" 2>/dev/null && pwd -P)" == "$(cd "$target_path" 2>/dev/null && pwd -P)" ]]; then
        set_status "skills" "manual"
        set_message "skills" "project Skills source and target resolve to the same path; refusing to self-overwrite"
        set_manual_step "skills" "project Skills: source and target IDEs share '$source_skills' on this workspace; pick a different target or relocate the source manually before retrying"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    print_progress "MIGRATE" "Migrating project Skills..."
    local migrated_count=0 failed_count=0 skill_dir skill_name timestamp
    if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$target_path"
    fi

    for skill_dir in "$source_path"/*/; do
        [[ -d "$skill_dir" ]] || continue
        [[ -f "$skill_dir/SKILL.md" ]] || continue
        skill_name=$(basename "$skill_dir")

        if [[ $DRY_RUN -eq 1 ]]; then
            echo "  DRY-RUN: cp -r $skill_dir $target_path/$skill_name"
            migrated_count=$((migrated_count + 1))
            continue
        fi

        if [[ -d "$target_path/$skill_name" ]]; then
            case "$STRATEGY" in
                skip)
                    echo "  [SKIP] project skill already exists: $skill_name"
                    continue
                    ;;
                backup)
                    timestamp=$(date +%Y%m%d%H%M%S).$$
                    mv "$target_path/$skill_name" "$target_path/$skill_name.bak.$timestamp"
                    echo "  [BACKUP] backed up existing project skill: $skill_name"
                    ;;
                overwrite)
                    if ! safe_remove_skill_dir "$target_path" "$skill_name"; then
                        echo "  [FAIL] safe delete of project skill before overwrite failed: $skill_name"
                        failed_count=$((failed_count + 1))
                        continue
                    fi
                    ;;
            esac
        fi

        # MED-S3 / MED-P3: skill bundles may carry config/env files with
        # embedded credentials; redact the COPY (never the source).
        # Fail-closed: on redaction failure remove the whole copied skill
        # so no secret survives.
        if cp -R "$skill_dir" "$target_path/$skill_name" 2>/dev/null; then
            if redact_project_copy "$target_path/$skill_name" >/dev/null; then
                echo "  [OK] migrated project skill: $skill_name"
                migrated_count=$((migrated_count + 1))
            else
                # SECURITY: fail-closed — remove only the direct child copy
                # through the same containment and symlink guard used by
                # overwrite handling.
                safe_remove_skill_dir "$target_path" "$skill_name" || true
                echo "  [FAIL] project skill redaction failed, deleted copy to prevent key leak: $skill_name"
                failed_count=$((failed_count + 1))
            fi
        else
            echo "  [FAIL] project skill migration failed: $skill_name"
            failed_count=$((failed_count + 1))
        fi
    done

        set_manual_step "skills" "project Skills: this run only writes target native directory $target_skills; compatibility directories, same-name priority, trust settings and external symlinks still need manual review" 
    if [[ $failed_count -gt 0 ]]; then
        set_status "skills" "partial"
        set_message "skills" "project Skills succeeded $migrated_count, failed $failed_count" 
        MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
    else
        set_status "skills" "success"
        set_message "skills" "project Skills successfully migrated $migrated_count" 
        MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
    fi
}

migrate_skills() {
    local source_ide="$1"
    local target_ide="$2"
    local scope="${3:-global}"

    case "$scope" in
        global)
            migrate_global_skills "$source_ide" "$target_ide"
            ;;
        project)
            migrate_project_skills "$source_ide" "$target_ide"
            ;;
        both)
            migrate_global_skills "$source_ide" "$target_ide"
            migrate_project_skills "$source_ide" "$target_ide"
            ;;
        *)
            set_status "skills" "failed"
        set_message "skills" "unsupported Skills scope: $scope" 
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            ;;
    esac
}

migrate_rules() {
    local source_ide="$1"
    local target_ide="$2"

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    if [[ "$source_ide" == "pieces" || "$target_ide" == "pieces" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Pieces has no documented portable rules file; context is managed by PiecesOS and the host integration"
        set_manual_step "rules" "Pieces: do not copy .pieces or infer a rules file; configure host-IDE instructions separately and use PiecesOS MCP for workflow memory"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "blackbox" || "$target_ide" == "blackbox" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Blackbox official docs do not define portable rules file or directory; auto migration unsupported" 
        set_manual_step "rules" "Blackbox: do not infer .blackbox/rules, .blackbox/instructions or root rules file; only review .blackbox/skills/ per official project Skills docs" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Supermaven's documented .supermavenignore is an indexing-exclusion
    # file, not an instruction/rules format. Never flatten or copy it as AI
    # rules; host-editor/Neovim settings require manual review.
    if [[ "$source_ide" == "supermaven" || "$target_ide" == "supermaven" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Supermaven has no documented portable instruction/rules file; .supermavenignore only excludes indexed files"
        set_manual_step "rules" "Supermaven: review host-editor/Neovim settings manually; preserve .supermavenignore only as an indexing exclusion file, never as instruction rules"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "goose-cli" || "$target_ide" == "goose-cli" ]]; then
        set_manual_step "rules" "Goose: local .goosehints is copied as a project hint only; review global ~/.config/goose/.goosehints, AGENTS.md, nested hints, and CONTEXT_FILE_NAMES manually"
    fi

    if [[ "$source_ide" == "opencode" || "$target_ide" == "opencode" ]]; then
        set_manual_step "rules" "OpenCode: this operation handles project AGENTS.md; review global ~/.config/opencode/AGENTS.md, Claude-compatible CLAUDE.md fallbacks, and opencode.json instructions globs manually"
    fi

    if [[ "$source_ide" == "cody" || "$target_ide" == "cody" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Sourcegraph Cody has no documented .codyrules or portable project-instructions file"
        set_manual_step "rules" "Cody: do not copy .codyrules; review project instructions manually in the target IDE's documented instruction surface"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Current Devin Desktop/Windsurf rules are a directory of independently
    # activated files (.devin/rules/*.md, with .windsurf/rules/*.md as the
    # compatibility location). The legacy .windsurfrules file is also still
    # read, but this generic single-file mapper cannot safely choose a scope,
    # activation mode, or merge strategy. Keep all Windsurf rule transfers
    # manual rather than flattening a directory or guessing schema.
    if [[ "$source_ide" == "windsurf" || "$target_ide" == "windsurf" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Windsurf/Devin rules use scoped files; automatic migration is unsupported"
        set_manual_step "rules" "Review .devin/rules/*.md (preferred), .windsurf/rules/*.md (legacy), or .windsurfrules manually; preserve each file's trigger and scope"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "continue" || "$target_ide" == "continue" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Continue rules use .continue/rules/* blocks; automatic migration is unsupported"
        set_manual_step "rules" "Review .continue/rules/*.md manually; preserve YAML frontmatter fields name, globs, regex, alwaysApply, and description"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Tabnine guidelines are a directory of Markdown files at global or
    # project scope. The generic rules copier only supports one file and must
    # not flatten or silently choose a guideline scope.
    if [[ "$source_ide" == "tabnine" || "$target_ide" == "tabnine" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Tabnine guidelines use scoped .tabnine/guidelines/*.md files; automatic migration is unsupported"
        set_manual_step "rules" "Review ~/.tabnine/guidelines/*.md or project .tabnine/guidelines/*.md manually; preserve each guideline file and scope"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Antigravity IDE rules are a directory of independently activated files.
    # This generic handler only has safe single-file copy semantics, so do not
    # flatten, overwrite, or claim to migrate the documented directory.
    if [[ "$source_ide" == "antigravity" || "$target_ide" == "antigravity" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Antigravity IDE rules use a directory; manual migration required"
        set_manual_step "rules" "Review and merge .agents/rules/ manually; do not convert it to .agents/AGENTS.md"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Amazon Q rules are a directory of Markdown files with Q-specific
    # activation through the IDE. The generic single-file mapper cannot
    # flatten or select files safely.
    if [[ "$source_ide" == "amazon-q" || "$target_ide" == "amazon-q" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Amazon Q rules use .amazonq/rules/*.md; manual migration required"
        set_manual_step "rules" "Review .amazonq/rules/*.md manually; preserve the project scope and Markdown format"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "kiro" || "$target_ide" == "kiro" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Kiro steering is a directory with inclusion/frontmatter semantics; auto single-file migration unsupported" 
        set_manual_step "rules" "Kiro: review ~/.kiro/steering/*.md and .kiro/steering/*.md; preserve inclusion (always/fileMatch/auto/manual) and file scope"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "augment-code" || "$target_ide" == "augment-code" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Augment rules use a directory and frontmatter; auto single-file migration unsupported" 
        set_manual_step "rules" "Augment: review ~/.augment/rules/ and .augment/rules/*.md plus .augment-guidelines; preserve always_apply/agent_requested/manual semantics"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "baidu-comate" || "$target_ide" == "baidu-comate" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Comate rules use .mdr directory and activation mode; auto single-file migration unsupported" 
        set_manual_step "rules" "Comate: review .comate/rules/*.mdr manually; preserve its Cursor-compatible frontmatter and activation mode"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "trae-cn" || "$target_ide" == "trae-cn" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Trae CN rules use .trae/rules directory; auto single-file migration unsupported" 
        set_manual_step "rules" "Trae CN: review .trae/rules/ manually; preserve frontmatter alwaysApply, globs, description, and scene"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "trae" || "$target_ide" == "trae" ]]; then
        set_status "rules" "manual"
        set_message "rules" "TRAE rules use the project .trae/rules directory; automatic directory migration is unsupported"
        set_manual_step "rules" "TRAE: review .trae/rules/ manually; preserve alwaysApply, globs, description, optional scene, and nested directory scope"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "replit" || "$target_ide" == "replit" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Replit replit.md is a project-root living document maintained by Agent; automatic overwrite is disabled"
        set_manual_step "rules" "Replit: manually merge source instructions into replit.md and preserve existing Agent-maintained context; review custom_instruction/instructions.md separately as static template instructions"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    local source_rules
    source_rules=$(get_rules_file "$source_ide")
    local target_rules
    target_rules=$(get_rules_file "$target_ide")

    if [[ "$source_ide" == "jetbrains" && ! -f "$WORKSPACE_ROOT/$source_rules" ]]; then
        # Junie falls back from its preferred .junie/AGENTS.md to a root
        # AGENTS.md, then legacy .junie/guidelines.md. Preserve the source
        # file instead of treating the legacy locations as CLI-only.
        if [[ -f "$WORKSPACE_ROOT/AGENTS.md" ]]; then
            source_rules="AGENTS.md"
        elif [[ -f "$WORKSPACE_ROOT/.junie/guidelines.md" ]]; then
            source_rules=".junie/guidelines.md"
        fi
    fi

    if [[ -z "$source_rules" ]]; then
        set_status "rules" "skipped"
        set_message "rules" "source IDE does not support rules files" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ -z "$target_rules" ]]; then
        set_status "rules" "skipped"
        set_message "rules" "target IDE does not support rules files" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "vscode" || "$target_ide" == "vscode" ]]; then
        set_manual_step "rules" "VS Code: the single-file mapper handles .github/copilot-instructions.md only; review AGENTS.md and .github/instructions/**/*.instructions.md with their applyTo frontmatter manually"
    fi

    # Cline rules are a directory of independently loaded Markdown/TXT files
    # in .clinerules/ (and the CLI also uses .cline/rules/). The generic
    # single-file copier cannot preserve that directory semantics or safely
    # choose between the extension and CLI rule scopes.
    if [[ "$source_ide" == "cline" || "$target_ide" == "cline" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Cline rules use directory-scoped files; manual migration required"
        set_manual_step "rules" "Review and merge .clinerules/*.md|*.txt for the VS Code extension, or .cline/rules/ for the CLI; preserve conditional frontmatter and do not flatten scopes"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$target_ide" == "aider" ]]; then
        echo "  MANUAL: add read: CONVENTIONS.md to the target .aider.conf.yml (YAML); no config rewrite is performed"
        set_manual_step "rules" "Aider: review CONVENTIONS.md and add read: CONVENTIONS.md to the appropriate .aider.conf.yml manually; do not treat Aider config as a skills or MCP file"
    fi

    # Cursor rules are a directory of MDC files, not a single portable rule
    # file. Do not flatten, overwrite, or guess a frontmatter conversion.
    if [[ "$source_ide" == "cursor" || "$target_ide" == "cursor" ]]; then
        set_status "rules" "manual"
        set_message "rules" "Cursor rules use .cursor/rules/*.mdc; manual migration required"
        set_manual_step "rules" "Review .cursor/rules/*.mdc manually; do not flatten into .cursorrules or guess frontmatter conversion"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "void-editor" || "$target_ide" == "void-editor" ]]; then
        # The first-party consumer reads plain-text `.voidrules` only from
        # each workspace-folder root. The generic operation can therefore
        # copy one project-root file safely; global AI Instructions and
        # multi-root merge behavior remain manual.
        set_manual_step "rules" "Void: .voidrules is a workspace-root plaintext instruction file; automatic copy is limited to the selected project root, while global AI Instructions and multi-root ordering require manual review"
    fi

    print_progress "MIGRATE" "Migrating rules files..." 

    local source_path="$WORKSPACE_ROOT/$source_rules"
    local target_path="$WORKSPACE_ROOT/$target_rules"

    if [[ ! -f "$source_path" ]]; then
        set_status "rules" "skipped"
        set_message "rules" "source rules file does not exist: $source_rules" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  DRY-RUN: cp $source_path $target_path"
        set_status "rules" "success"
        set_message "rules" "rules file ready to migrate" 
    else
        mkdir -p "$(dirname "$target_path")"
        if cp "$source_path" "$target_path"; then
            echo "  [OK] migrated rule: $source_rules -> $target_rules" 
            set_status "rules" "success"
        set_message "rules" "rules file migration succeeded" 
            MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
        else
            set_status "rules" "failed"
        set_message "rules" "rules file migration failed" 
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
        fi
    fi
}

migrate_prompts() {
    local source_ide="$1"
    local target_ide="$2"

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    if [[ "$source_ide" == "amazon-q" || "$target_ide" == "amazon-q" ]]; then
        set_status "prompts" "manual"
        set_message "prompts" "Amazon Q saved prompts have an official global library path but no cross-IDE prompt converter"
        set_manual_step "prompts" "Amazon Q: global prompts are ~/.aws/amazonq/prompts/*.md and are created from the IDE with @ → Prompts → Create a new prompt; project prompt scope is not documented as a portable path. Recreate or review prompt frontmatter/aliases manually"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "pieces" || "$target_ide" == "pieces" ]]; then
        set_status "prompts" "manual"
        set_message "prompts" "Pieces has no documented portable prompt-template directory"
        set_manual_step "prompts" "Pieces: review prompt and memory workflows in PiecesOS/Desktop or the consuming host; do not copy .pieces as prompt files"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "blackbox" || "$target_ide" == "blackbox" ]]; then
        set_status "prompts" "manual"
        set_message "prompts" "Blackbox official docs do not define portable prompt template directory; auto migration unsupported" 
        set_manual_step "prompts" "Blackbox: /skill is a CLI session command, not a prompt file directory; do not infer .blackbox/prompts or commands path" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Gemini CLI commands are TOML files with a required `prompt` field, not
    # Markdown prompt templates. The generic prompts copier cannot translate
    # this schema safely.
    if [[ "$source_ide" == "gemini-cli" || "$target_ide" == "gemini-cli" ]]; then
        set_status "prompts" "manual"
        set_message "prompts" "Gemini CLI commands use TOML; automatic prompt migration is unsupported"
        set_manual_step "prompts" "Gemini CLI: review .gemini/commands/*.toml or ~/.gemini/commands/*.toml manually; preserve required prompt/optional description fields, {{args}}, and !{...} shell blocks instead of copying Markdown files"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Supermaven's official docs describe inline completion/chat in the host
    # editor, not a portable prompt-template directory or file schema.
    if [[ "$source_ide" == "supermaven" || "$target_ide" == "supermaven" ]]; then
        set_status "prompts" "manual"
        set_message "prompts" "Supermaven has no documented portable prompt-template directory; automatic migration is unsupported"
        set_manual_step "prompts" "Supermaven: review prompts/chat settings in the host editor or Neovim configuration manually"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "cody" || "$target_ide" == "cody" ]]; then
        set_status "prompts" "manual"
        set_message "prompts" "Cody prompts are managed in the Enterprise Prompt Library; portable file migration is unsupported"
        set_manual_step "prompts" "Cody: use the Enterprise Prompt Library and its documented custom-command migration; do not copy legacy cody.json or infer a workspace command directory"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Goose prompt templates are global files under ~/.config/goose/prompts/;
    # project slash commands are YAML entries in config.yaml, not a portable
    # prompt directory. This project-relative copier cannot safely migrate
    # either scope or schema, so keep every Goose prompt transfer manual.
    if [[ "$source_ide" == "goose-cli" || "$target_ide" == "goose-cli" ]]; then
        set_status "prompts" "manual"
        set_message "prompts" "Goose prompt templates are global files and slash commands are config.yaml entries; automatic migration is unsupported"
        set_manual_step "prompts" "Goose: review ~/.config/goose/prompts/ and slash_commands in ~/.config/goose/config.yaml manually; local .goose/recipes/*.yaml are recipes, not prompt templates"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # TRAE Commands are Markdown files with product-specific frontmatter and
    # nesting rules. They are not generic prompt templates; keep the exact
    # project path visible for manual review rather than converting bodies.
    if [[ "$source_ide" == "trae" || "$target_ide" == "trae" ||
          "$source_ide" == "trae-cn" || "$target_ide" == "trae-cn" ]]; then
        set_status "prompts" "manual"
        set_message "prompts" "TRAE commands use .trae/commands/*.md; automatic prompt conversion is unsupported"
        set_manual_step "prompts" "TRAE: review project .trae/commands/ manually; preserve filename, description, nesting, and Markdown instruction body"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Windsurf/Devin workflows are independently invoked slash commands with
    # their own frontmatter and length limits. They are not generic prompt
    # templates, so do not flatten or copy them into another IDE's command dir.
    if [[ "$source_ide" == "windsurf" || "$target_ide" == "windsurf" ]]; then
        set_status "prompts" "manual"
        set_message "prompts" "Windsurf/Devin workflows use a product-specific directory and invocation model"
        set_manual_step "prompts" "Windsurf/Devin: review .windsurf/workflows/*.md and ~/.codeium/windsurf/global_workflows/*.md manually; preserve frontmatter, slash names, nesting, and documented length limits"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "opencode" || "$target_ide" == "opencode" ]]; then
        set_manual_step "prompts" 'OpenCode: project .opencode/commands/*.md is copied as Markdown only; review global ~/.config/opencode/commands/, command entries in opencode.json, frontmatter, and $ARGUMENTS/!`cmd`/@file templates manually'
    fi

    if [[ "$source_ide" == "roo-code" || "$target_ide" == "roo-code" ]]; then
        set_manual_step "prompts" "Roo Code: project slash commands are .roo/commands/*.md; review command names, mode permissions, and invocation semantics manually after copying. Do not treat .roomodes or global custom_modes.yaml/json as prompt files"
    fi

    local source_prompts
    source_prompts=$(get_prompts_path "$source_ide")
    local target_prompts
    target_prompts=$(get_prompts_path "$target_ide")

    if [[ -z "$source_prompts" ]]; then
        set_status "prompts" "skipped"
        set_message "prompts" "source IDE does not support prompt templates" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ -z "$target_prompts" ]]; then
        set_status "prompts" "skipped"
        set_message "prompts" "target IDE does not support prompt templates" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "vscode" || "$target_ide" == "vscode" ]]; then
        set_manual_step "prompts" "VS Code: workspace .github/prompts/*.prompt.md is migrated; user prompts live in the active Profile's user-data and must be created/reviewed with Chat: New Prompt File, /prompts, or Chat: Run Prompt. Do not guess a cross-platform user path"
    fi

    local prompt_pattern="*.md"
    if [[ "$source_ide" == "vscode" || "$target_ide" == "vscode" ]]; then
        prompt_pattern="*.prompt.md"
    fi

    print_progress "MIGRATE" "Migrating prompt templates..." 

    local source_path="$WORKSPACE_ROOT/$source_prompts"
    local target_path="$WORKSPACE_ROOT/$target_prompts"

    if [[ ! -d "$source_path" ]]; then
        set_status "prompts" "skipped"
        set_message "prompts" "source prompt directory does not exist: $source_prompts" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    local prompt_count
    prompt_count=$(find "$source_path" -name "$prompt_pattern" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$prompt_count" -eq 0 ]]; then
        set_status "prompts" "skipped"
        set_message "prompts" "source prompt directory is empty" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  DRY-RUN: copy $prompt_pattern files from $source_path to $target_path/"
        set_status "prompts" "success"
        set_message "prompts" "$prompt_count prompt templates ready to migrate" 
    else
        mkdir -p "$target_path"
        local prompt_file relative_prompt target_prompt
        local prompt_copy_failed=0
        while IFS= read -r -d '' prompt_file; do
            relative_prompt="${prompt_file#"$source_path"/}"
            target_prompt="$target_path/$relative_prompt"
            mkdir -p "$(dirname "$target_prompt")"
            if ! cp "$prompt_file" "$target_prompt"; then
                prompt_copy_failed=1
                break
            fi
        done < <(find "$source_path" -name "$prompt_pattern" -type f -print0 2>/dev/null)
        if [[ "$prompt_copy_failed" -eq 0 ]]; then
            echo "  [OK] migrated prompts: $prompt_count files" 
            set_status "prompts" "success"
        set_message "prompts" "successfully migrated $prompt_count prompt templates" 
            MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
        else
            set_status "prompts" "failed"
        set_message "prompts" "prompt template migration failed" 
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
        fi
    fi
}

# Reads a source MCP config, maps the server root key into the target IDE's
# format, and writes the result to the target file. Sets the global variables
# CONV_RESULT (success|copied|failed) and CONV_DETAIL (human message) for the
# caller. NEVER reports success when zero bytes were actually transferred.
convert_mcp_file() {
    local src="$1" src_key="$2" dst="$3" dst_key="$4" target_ide="$5" strategy="$6" target_version="$7"
    CONV_RESULT=""
    CONV_DETAIL=""
    MCP_REDACTED_COUNT=0

    if [[ ! -r "$src" ]]; then
        CONV_RESULT="failed"
        CONV_DETAIL="source MCP config unreadable: $src" 
        return
    fi

    # Only perform a true root-key conversion when BOTH the source and target
    # are JSON files. If either side is TOML/YAML (or any other format) we
    # cannot truly convert, so we fall back to a verbatim copy and report
    # "copied" (never a false "success"). In every path we strip literal or
    # ambiguous credentials before target write. Exact supported environment
    # references contain no live value and may be preserved or translated.
    local src_ext dst_ext
    src_ext="${src##*.}"
    dst_ext="${dst##*.}"

    if [[ "$src_ext" =~ ^jsonc?$ && "$dst_ext" =~ ^jsonc?$ ]] && command -v python3 >/dev/null 2>&1; then
        local json_conversion_rc=0
        python3 - "$src" "$src_key" "$dst" "$dst_key" "$target_ide" "$strategy" "$target_version" >/dev/null 2>&1 <<'PYEOF' || json_conversion_rc=$?
import json, os, re, sys
from urllib.parse import parse_qsl, urlsplit
src, src_key, dst, dst_key, target_ide, strategy, target_version = sys.argv[1], (sys.argv[2] or ""), sys.argv[3], (sys.argv[4] or ""), sys.argv[5], sys.argv[6], sys.argv[7]
SECRET_KEY_RE = re.compile(r"(?i)(api[_-]?key|token|secret|password|passwd|authorization|auth|bearer|private[_-]?key|access[_-]?key|client[_-]?secret|session|cookie)", re.IGNORECASE)
# Broadened to catch credential-bearing DB/connection URIs (postgres://user:pass@,
# mysql://..., redis://..., etc.), not just http(s).
URL_CRED_RE = re.compile(r"^(?:https?|postgres|postgresql|mysql|mongodb|mongodb\+srv|redis|ftp|amqp|sqlserver)://[^:@/\s]+:[^@/\s]+@", re.IGNORECASE)
URL_TOKEN_RE = re.compile(r"^(https?://)[^/\s]*:(//)?[A-Za-z0-9_\-]{16,}", re.IGNORECASE)
# Query-string credentials: ?key=..., ?token=..., ?secret=..., ?access_token=...
QUERY_CRED_RE = re.compile(r"[?&](key|token|secret|access[_-]?token|api[_-]?key)=[A-Za-z0-9_\-]{12,}", re.IGNORECASE)
# Provider-key value formats (CR-001 fix). These never carry a secret-like KEY
# name, so the key-name heuristics above miss them entirely. Explicitly match
# well-known credential shapes so e.g. `sk-ant-...`/`ghp_...`/`AKIA...` are
# blanked even when the surrounding key is innocuous (MY_KEY, WEBHOOK_URL...).
# Kept in sync with validate_skills.py::SECRET and the config/project redactor.
PROVIDER_SECRET_RE = re.compile(r"(?:sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|tvly-[A-Za-z0-9_-]{16,}|AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|ya29\.[A-Za-z0-9_-]+|AIza[0-9A-Za-z_-]{35}|sk_live_[A-Za-z0-9]{16,})")
SAFE_ENV_REF_TOKEN = r"(?:\$\{env:[A-Za-z_][A-Za-z0-9_]*\}|\$\{[A-Za-z_][A-Za-z0-9_]*\}|\{env:[A-Za-z_][A-Za-z0-9_]*\})"
SAFE_ENV_REF_RE = re.compile(SAFE_ENV_REF_TOKEN)
SAFE_ENV_REF_FULL_RE = re.compile(r"^" + SAFE_ENV_REF_TOKEN + r"$")
SAFE_BEARER_REF_RE = re.compile(r"^Bearer\s+" + SAFE_ENV_REF_TOKEN + r"$", re.IGNORECASE)

def is_safe_reference_value(value):
    """Return true only when every credential payload is a symbolic env ref."""
    if not isinstance(value, str):
        return False
    if target_ide == "opencode":
        exact_ref = re.fullmatch(r"\{env:[A-Za-z_][A-Za-z0-9_]*\}", value)
        bearer_ref = re.fullmatch(r"Bearer\s+\{env:[A-Za-z_][A-Za-z0-9_]*\}", value, re.IGNORECASE)
    else:
        exact_ref = SAFE_ENV_REF_FULL_RE.fullmatch(value)
        bearer_ref = SAFE_BEARER_REF_RE.fullmatch(value)
    if exact_ref or bearer_ref:
        return True
    if not value.lower().startswith(("http://", "https://")) or not SAFE_ENV_REF_RE.search(value):
        return False
    if PROVIDER_SECRET_RE.search(value) or URL_CRED_RE.match(value) or URL_TOKEN_RE.match(value):
        return False
    try:
        parsed = urlsplit(value)
    except ValueError:
        return False
    if parsed.username or parsed.password:
        return False
    credential_params = [
        param_value
        for key, param_value in parse_qsl(parsed.query, keep_blank_values=True)
        if SECRET_KEY_RE.search(key)
    ]
    if target_ide == "opencode":
        return bool(credential_params) and all(
            re.fullmatch(r"\{env:[A-Za-z_][A-Za-z0-9_]*\}", item)
            for item in credential_params
        )
    return bool(credential_params) and all(SAFE_ENV_REF_FULL_RE.fullmatch(item) for item in credential_params)

def normalize_environment_references(node):
    """Translate documented Cursor refs into OpenCode's documented syntax."""
    if isinstance(node, dict):
        for key, value in list(node.items()):
            node[key] = normalize_environment_references(value)
    elif isinstance(node, list):
        for index, value in enumerate(node):
            node[index] = normalize_environment_references(value)
    elif isinstance(node, str) and target_ide == "opencode":
        return re.sub(
            r"\$\{env:([A-Za-z_][A-Za-z0-9_]*)\}",
            r"{env:\1}",
            node,
        )
    return node

def redact_value(v):
    # Strings that look like a credential/secret get blanked (key name kept).
    if isinstance(v, str):
        if is_safe_reference_value(v):
            return v
        if PROVIDER_SECRET_RE.search(v):
            return ""
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
            elif isinstance(v, str) and SECRET_KEY_RE.search(k) and not is_safe_reference_value(v):
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
                if parent_secret and not is_safe_reference_value(item):
                    node[i] = ""
                elif blank_next:
                    node[i] = item if is_safe_reference_value(item) else ""
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

def _strip_jsonc(text):
    # JSONC is JSON plus comments/trailing commas. Strip only comment markers
    # outside quoted strings so URLs such as https://... remain untouched.
    out = []
    i = 0
    in_string = False
    escaped = False
    line_comment = False
    block_comment = False
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if line_comment:
            if ch in "\r\n":
                line_comment = False
                out.append(ch)
            i += 1
            continue
        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                i += 2
                continue
            if ch in "\r\n":
                out.append(ch)
            i += 1
            continue
        if in_string:
            out.append(ch)
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
        elif ch == "/" and nxt == "/":
            line_comment = True
            i += 2
        elif ch == "/" and nxt == "*":
            block_comment = True
            i += 2
        else:
            out.append(ch)
            i += 1
    text = "".join(out)
    out = []
    in_string = False
    escaped = False
    i = 0
    while i < len(text):
        ch = text[i]
        if in_string:
            out.append(ch)
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
            continue
        if ch == ",":
            j = i + 1
            while j < len(text) and text[j].isspace():
                j += 1
            if j < len(text) and text[j] in "]}":
                i += 1
                continue
        out.append(ch)
        i += 1
    return "".join(out)

def _load_json_document(path):
    with open(path) as f:
        raw = f.read()
    if path.lower().endswith(".jsonc"):
        raw = _strip_jsonc(raw)
    return json.loads(raw)

try:
    data = _load_json_document(src)
except Exception:
    sys.exit(2)  # not JSON/JSONC -> caller handles it explicitly
def read_path(obj, key):
    for part in key.split('.') if key else []:
        if not isinstance(obj, dict):
            return {}
        obj = obj.get(part, {})
    return obj

def write_path(obj, key, value):
    parts = key.split('.') if key else []
    for part in parts[:-1]:
        if not isinstance(obj.get(part), dict):
            obj[part] = {}
        obj = obj[part]
    if parts:
        obj[parts[-1]] = value

if isinstance(data, dict):
    if src_key and ('.' in src_key or src_key in data):
        servers = read_path(data, src_key)
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
normalize_environment_references(servers)
redact_node(servers)
# GitHub Copilot CLI accepts only these documented transports. Do not write
# a configuration which needs a guessed transport or looks like an IDE-only
# schema: report it as manual instead. A local entry may omit `type` because
# the CLI documents `local` as its default, but still needs command, args, and
# tools. Remote entries must state http or sse and provide a URL.
if target_ide == "copilot":
    supported_types = {"local", "stdio", "http", "sse"}
    if not isinstance(servers, dict):
        sys.exit(4)
    for server in servers.values():
        if not isinstance(server, dict):
            sys.exit(4)
        transport = server.get("type")
        tools = server.get("tools")
        if not isinstance(tools, list):
            sys.exit(4)
        if transport is None:
            if not isinstance(server.get("command"), str) or not isinstance(server.get("args"), list):
                sys.exit(4)
        elif transport not in supported_types:
            sys.exit(4)
        elif transport in {"local", "stdio"}:
            if not isinstance(server.get("command"), str) or not isinstance(server.get("args"), list):
                sys.exit(4)
        elif not isinstance(server.get("url"), str):
            sys.exit(4)
# Cline's extension and CLI MCP files both use an object rooted at
# `mcpServers`. Validate the minimum server shape before writing; preserve
# documented optional fields such as disabled, autoApprove, timeout, and
# transportType without guessing their values.
if target_ide == "cline":
    if not isinstance(servers, dict):
        sys.exit(7)
    for server in servers.values():
        if not isinstance(server, dict):
            sys.exit(7)
        has_command = isinstance(server.get("command"), str)
        has_url = isinstance(server.get("url"), str)
        if has_command == has_url:
            sys.exit(7)
        if has_command and "args" in server and not isinstance(server["args"], list):
            sys.exit(7)
        if "env" in server and not isinstance(server["env"], dict):
            sys.exit(7)
        if "autoApprove" in server and not isinstance(server["autoApprove"], list):
            sys.exit(7)
        if "disabled" in server and not isinstance(server["disabled"], bool):
            sys.exit(7)
        if "timeout" in server and not isinstance(server["timeout"], (int, float)):
            sys.exit(7)
# Void's custom first-party MCP implementation reads a JSON `mcpServers` map.
# Its local shape is command/args/env. The archived runtime recognizes a URL
# for remote entries, but its declared headers are not reliably passed to the
# transport; reject headers and all other extra fields rather than claiming
# authenticated remote conversion is safe. `type`/`transport` are accepted
# only as validated source discriminators and are removed from the target.
if target_ide == "void-editor":
    if not isinstance(servers, dict):
        sys.exit(15)
    for server in servers.values():
        if not isinstance(server, dict):
            sys.exit(15)
        has_command = "command" in server
        has_url = "url" in server
        if has_command == has_url:
            sys.exit(15)
        source_type = server.pop("type", None)
        server.pop("transport", None)
        if has_command:
            if source_type not in (None, "local", "stdio"):
                sys.exit(15)
            if not isinstance(server.get("command"), str) or not server.get("command"):
                sys.exit(15)
            if "args" in server and (not isinstance(server["args"], list) or not all(isinstance(item, str) for item in server["args"])):
                sys.exit(15)
            if "env" in server and (not isinstance(server["env"], dict) or not all(isinstance(key, str) and isinstance(value, str) for key, value in server["env"].items())):
                sys.exit(15)
            if set(server) - {"command", "args", "env"}:
                sys.exit(15)
        else:
            if source_type not in (None, "remote", "http", "sse", "streamable-http"):
                sys.exit(15)
            if not isinstance(server.get("url"), str) or not server.get("url"):
                sys.exit(15)
            if set(server) - {"url"}:
                sys.exit(15)
# Gemini CLI settings.json has a documented mcpServers object whose entries
# must expose command (stdio), url (SSE), or httpUrl (Streamable HTTP). The
# official docs warn against underscores in server aliases because policy FQN
# parsing splits on underscores. Reject ambiguous aliases/shapes instead of
# silently renaming an alias that may also be referenced by policies or
# mcp.allowed/mcp.excluded settings.
if target_ide == "gemini-cli":
    if not isinstance(servers, dict):
        sys.exit(8)
    for name, server in servers.items():
        if "_" in name or not isinstance(server, dict):
            sys.exit(8)
        endpoint_keys = ("command", "url", "httpUrl")
        if not any(isinstance(server.get(key), str) and server.get(key) for key in endpoint_keys):
            sys.exit(8)
        for key in endpoint_keys:
            if key in server and not isinstance(server[key], str):
                sys.exit(8)
        if "args" in server and (not isinstance(server["args"], list) or not all(isinstance(item, str) for item in server["args"])):
            sys.exit(8)
        if "headers" in server and (not isinstance(server["headers"], dict) or not all(isinstance(key, str) and isinstance(value, str) for key, value in server["headers"].items())):
            sys.exit(8)
        if "env" in server and (not isinstance(server["env"], dict) or not all(isinstance(key, str) and isinstance(value, str) for key, value in server["env"].items())):
            sys.exit(8)
        if "cwd" in server and not isinstance(server["cwd"], str):
            sys.exit(8)
        if "timeout" in server and (not isinstance(server["timeout"], (int, float)) or isinstance(server["timeout"], bool)):
            sys.exit(8)
        if "trust" in server and not isinstance(server["trust"], bool):
            sys.exit(8)
        for key in ("includeTools", "excludeTools"):
            if key in server and (not isinstance(server[key], list) or not all(isinstance(item, str) for item in server[key])):
                sys.exit(8)
# Kilo Code's JSONC config uses `mcp` with an explicit type discriminator.
# Normalize the common command/args/env shape into Kilo's documented
# type=local + command-array + environment form, or type=remote + url.
if target_ide == "kilocode":
    if not isinstance(servers, dict):
        sys.exit(10)
    for server in servers.values():
        if not isinstance(server, dict) or "transport" in server:
            sys.exit(10)
        has_command = "command" in server
        has_url = "url" in server
        if has_command == has_url:
            sys.exit(10)
        source_type = server.get("type")
        if has_command:
            if source_type not in (None, "local", "stdio"):
                sys.exit(10)
            command = server.get("command")
            args = server.get("args", [])
            if isinstance(command, str):
                command = [command]
            if not isinstance(command, list) or not command or not all(isinstance(item, str) for item in command):
                sys.exit(10)
            if not isinstance(args, list) or not all(isinstance(item, str) for item in args):
                sys.exit(10)
            server["command"] = command + args
            server.pop("args", None)
            server["type"] = "local"
            if "env" in server:
                if "environment" in server or not isinstance(server["env"], dict):
                    sys.exit(10)
                server["environment"] = server.pop("env")
            if "environment" in server and (not isinstance(server["environment"], dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in server["environment"].items())):
                sys.exit(10)
            if any(key in server for key in ("headers", "oauth", "url")):
                sys.exit(10)
        else:
            if source_type not in (None, "remote", "http", "sse", "streamable-http"):
                sys.exit(10)
            if not isinstance(server.get("url"), str) or not server.get("url"):
                sys.exit(10)
            server["type"] = "remote"
            if "headers" in server and (not isinstance(server["headers"], dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in server["headers"].items())):
                sys.exit(10)
            if any(key in server for key in ("args", "env", "environment", "cwd", "command")):
                sys.exit(10)
        if "enabled" in server and not isinstance(server["enabled"], bool):
            sys.exit(10)
        if "timeout" in server and (not isinstance(server["timeout"], (int, float)) or isinstance(server["timeout"], bool)):
            sys.exit(10)
        if "oauth" in server and not isinstance(server["oauth"], (bool, dict)):
            sys.exit(10)
# Kimi Code, Kiro, and ZCode use an mcpServers-like map with a scalar command
# plus args for stdio and url/headers for remote servers. A command array from
# OpenCode is unambiguous: its first element is the command and the remainder
# are args. Remove foreign type discriminators after that endpoint
# normalization; Kimi retains an explicit `transport=sse` only when the
# source explicitly supplied SSE.
if target_ide in {"kimiai", "kiro", "zcode"}:
    if not isinstance(servers, dict):
        sys.exit(12)
    for server in servers.values():
        if not isinstance(server, dict):
            sys.exit(12)
        has_command = "command" in server
        has_url = "url" in server
        if has_command == has_url:
            sys.exit(12)
        source_type = server.pop("type", None)
        if has_command:
            if source_type not in (None, "local", "stdio"):
                sys.exit(12)
            command = server.get("command")
            args = server.get("args", [])
            if not isinstance(args, list) or not all(isinstance(item, str) for item in args):
                sys.exit(12)
            if isinstance(command, list):
                if not command or not all(isinstance(item, str) for item in command):
                    sys.exit(12)
                command, args = command[0], command[1:] + args
            if not isinstance(command, str) or not command:
                sys.exit(12)
            server["command"] = command
            server["args"] = args
            if "environment" in server:
                if "env" in server or not isinstance(server["environment"], dict):
                    sys.exit(12)
                server["env"] = server.pop("environment")
            if "env" in server and (not isinstance(server["env"], dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in server["env"].items())):
                sys.exit(12)
            if "headers" in server:
                sys.exit(12)
        else:
            if source_type not in (None, "remote", "http", "sse", "streamable-http"):
                sys.exit(12)
            if not isinstance(server.get("url"), str) or not server.get("url"):
                sys.exit(12)
            if source_type == "sse" and target_ide == "kimiai":
                server["transport"] = "sse"
            if "headers" in server and (not isinstance(server["headers"], dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in server["headers"].items())):
                sys.exit(12)
            if any(key in server for key in ("args", "env", "environment", "cwd", "command")):
                sys.exit(12)
        if "transport" in server:
            if target_ide != "kimiai" or server["transport"] != "sse":
                sys.exit(12)
        for key in ("enabled", "disabled"):
            if key in server and not isinstance(server[key], bool):
                sys.exit(12)
        for key in ("startupTimeoutMs", "toolTimeoutMs", "timeout"):
            if key in server and (not isinstance(server[key], (int, float)) or isinstance(server[key], bool)):
                sys.exit(12)
        for key in ("enabledTools", "disabledTools", "autoApprove"):
            if key in server and (not isinstance(server[key], list) or not all(isinstance(item, str) for item in server[key])):
                sys.exit(12)
# WorkBuddy desktop's official MCP guide only documents a local command-based
# mcpServers shape: command (string), optional args (string array), and
# optional env (string map). The desktop docs do not establish remote URL,
# headers, type, transport, or arbitrary metadata as a portable file format.
# Reject those entries instead of silently emitting an unsupported desktop
# configuration. This intentionally differs from CodeBuddy Code CLI.
if target_ide == "workbuddy":
    if not isinstance(servers, dict):
        sys.exit(16)
    allowed_keys = {"command", "args", "env"}
    for server in servers.values():
        if not isinstance(server, dict) or set(server) - allowed_keys:
            sys.exit(16)
        if not isinstance(server.get("command"), str) or not server.get("command"):
            sys.exit(16)
        if "args" in server and (not isinstance(server["args"], list) or not all(isinstance(item, str) for item in server["args"])):
            sys.exit(16)
        if "env" in server and (not isinstance(server["env"], dict) or not all(isinstance(key, str) and isinstance(value, str) for key, value in server["env"].items())):
            sys.exit(16)
# Junie in JetBrains documents a local mcpServers shape with command/args/env.
# Keep remote/type/transport/unknown fields manual until the IDE docs establish
# a portable target schema for them; this prevents a foreign IDE's remote
# discriminator from being written into Junie's mcp.json.
if target_ide == "jetbrains":
    if not isinstance(servers, dict):
        sys.exit(17)
    for server in servers.values():
        if not isinstance(server, dict) or set(server) - {"command", "args", "env"}:
            sys.exit(17)
        if not isinstance(server.get("command"), str) or not server.get("command"):
            sys.exit(17)
        if "args" in server and (not isinstance(server["args"], list) or not all(isinstance(item, str) for item in server["args"])):
            sys.exit(17)
        if "env" in server and (not isinstance(server["env"], dict) or not all(isinstance(key, str) and isinstance(value, str) for key, value in server["env"].items())):
            sys.exit(17)
# Augment uses mcpServers. Local servers use command/args/env; remote servers
# must retain an explicit documented http or sse type because a bare URL does
# not identify the transport. OpenCode's command array is normalized to the
# scalar command plus args shape.
if target_ide == "augment-code":
    if not isinstance(servers, dict):
        sys.exit(13)
    for server in servers.values():
        if not isinstance(server, dict):
            sys.exit(13)
        has_command = "command" in server
        has_url = "url" in server
        if has_command == has_url:
            sys.exit(13)
        source_type = server.get("type")
        if has_command:
            if source_type not in (None, "local", "stdio"):
                sys.exit(13)
            command = server.get("command")
            args = server.get("args", [])
            if not isinstance(args, list) or not all(isinstance(item, str) for item in args):
                sys.exit(13)
            if isinstance(command, list):
                if not command or not all(isinstance(item, str) for item in command):
                    sys.exit(13)
                command, args = command[0], command[1:] + args
            if not isinstance(command, str) or not command or not isinstance(args, list) or not all(isinstance(item, str) for item in args):
                sys.exit(13)
            server["command"], server["args"] = command, args
            server.pop("type", None)
            if "env" in server and (not isinstance(server["env"], dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in server["env"].items())):
                sys.exit(13)
        else:
            if source_type not in {"http", "sse"} or not isinstance(server.get("url"), str) or not server.get("url"):
                sys.exit(13)
            if "headers" in server and (not isinstance(server["headers"], dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in server["headers"].items())):
                sys.exit(13)
        if "enabled" in server and not isinstance(server["enabled"], bool):
            sys.exit(13)
# Comate's first-party MCP guide requires type (stdio/sse/streamableHttp),
# command for stdio, and url for remote entries. Accept the guide's older
# transportType spelling as an input alias, but write the canonical `type`.
if target_ide == "baidu-comate":
    if not isinstance(servers, dict):
        sys.exit(14)
    for server in servers.values():
        if not isinstance(server, dict):
            sys.exit(14)
        transport = server.get("type", server.get("transportType"))
        if transport not in {"stdio", "sse", "streamableHttp", "streamable-http", "http"}:
            sys.exit(14)
        server["type"] = transport
        server.pop("transportType", None)
        if transport == "stdio":
            if not isinstance(server.get("command"), str) or not server.get("command"):
                sys.exit(14)
            if "url" in server or ("args" in server and (not isinstance(server["args"], list) or not all(isinstance(item, str) for item in server["args"]))):
                sys.exit(14)
        else:
            if not isinstance(server.get("url"), str) or not server.get("url"):
                sys.exit(14)
            if "command" in server or "args" in server:
                sys.exit(14)
        for key in ("env", "headers", "requestInit"):
            if key in server and not isinstance(server[key], dict):
                sys.exit(14)
        if "cwd" in server and not isinstance(server["cwd"], str):
            sys.exit(14)
        for key in ("timeout",):
            if key in server and (not isinstance(server[key], (int, float)) or isinstance(server[key], bool)):
                sys.exit(14)
        if "disabled" in server and not isinstance(server["disabled"], bool):
            sys.exit(14)
# OpenCode's documented `mcp` entries are discriminated by type. Local
# servers require a command ARRAY and use `environment`; remote servers
# require a URL and use `headers`/`oauth`. Convert common mcpServers shapes
# deliberately instead of copying a foreign `env`, scalar command, or
# transport discriminator into opencode.json. Reject ambiguous entries and
# invalid target JSON rather than guessing.
if target_ide == "opencode":
    if not isinstance(servers, dict):
        sys.exit(10)
    for server in servers.values():
        if not isinstance(server, dict):
            sys.exit(10)
        has_command = "command" in server
        has_url = "url" in server
        if has_command == has_url:
            sys.exit(10)
        source_type = server.get("type")
        if "transport" in server:
            # OpenCode does not use a transport key; accepting one would
            # silently carry an IDE/CLI-specific discriminator.
            sys.exit(10)
        if has_command:
            if source_type not in (None, "local", "stdio"):
                sys.exit(10)
            command = server.get("command")
            args = server.get("args", [])
            if isinstance(command, str):
                command_array = [command]
            elif isinstance(command, list) and all(isinstance(item, str) for item in command):
                command_array = list(command)
            else:
                sys.exit(10)
            if not isinstance(args, list) or not all(isinstance(item, str) for item in args):
                sys.exit(10)
            server["command"] = command_array + args
            server.pop("args", None)
            server["type"] = "local"
            if "env" in server:
                if "environment" in server or not isinstance(server["env"], dict):
                    sys.exit(10)
                server["environment"] = server.pop("env")
            if "environment" in server and (
                not isinstance(server["environment"], dict)
                or not all(isinstance(key, str) and isinstance(value, str) for key, value in server["environment"].items())
            ):
                sys.exit(10)
            if "cwd" in server and not isinstance(server["cwd"], str):
                sys.exit(10)
            if "enabled" in server and not isinstance(server["enabled"], bool):
                sys.exit(10)
            if "timeout" in server and (not isinstance(server["timeout"], (int, float)) or isinstance(server["timeout"], bool)):
                sys.exit(10)
            if any(key in server for key in ("headers", "oauth")):
                sys.exit(10)
        else:
            if source_type not in (None, "remote", "http", "sse", "streamable-http"):
                sys.exit(10)
            if not isinstance(server.get("url"), str) or not server.get("url"):
                sys.exit(10)
            server["type"] = "remote"
            if "headers" in server and (
                not isinstance(server["headers"], dict)
                or not all(isinstance(key, str) and isinstance(value, str) for key, value in server["headers"].items())
            ):
                sys.exit(10)
            if "oauth" in server and server["oauth"] is not False and not isinstance(server["oauth"], dict):
                sys.exit(10)
            if "enabled" in server and not isinstance(server["enabled"], bool):
                sys.exit(10)
            if "timeout" in server and (not isinstance(server["timeout"], (int, float)) or isinstance(server["timeout"], bool)):
                sys.exit(10)
            if any(key in server for key in ("args", "env", "environment", "cwd")):
                sys.exit(10)
        if target_version == "v2":
            if "enabled" in server and "disabled" in server:
                sys.exit(10)
            if "enabled" in server:
                server["disabled"] = not server.pop("enabled")
            if "timeout" in server:
                timeout = server["timeout"]
                if not isinstance(timeout, (int, float)) or isinstance(timeout, bool):
                    sys.exit(10)
                server["timeout"] = {
                    "catalog": timeout,
                    "execution": timeout,
                }
            if isinstance(server.get("oauth"), dict):
                oauth = server["oauth"]
                for old_key, new_key in {
                    "clientId": "client_id",
                    "clientSecret": "client_secret",
                    "callbackPort": "callback_port",
                    "redirectUri": "redirect_uri",
                }.items():
                    if old_key in oauth and new_key in oauth:
                        sys.exit(10)
                    if old_key in oauth:
                        oauth[new_key] = oauth.pop(old_key)
# VS Code's `servers` schema is not interchangeable with a generic
# `mcpServers` object. Local stdio entries may omit `type`; remote entries
# require the documented `http`/`sse` discriminator. Reject foreign fields
# such as Windsurf's `serverUrl` or a generic `transport` instead of silently
# emitting an invalid `.vscode/mcp.json`.
if target_ide == "vscode":
    if not isinstance(servers, dict):
        sys.exit(6)
    for server in servers.values():
        if not isinstance(server, dict):
            sys.exit(6)
        if any(key in server for key in ("transport", "serverUrl")):
            sys.exit(6)
        has_command = "command" in server
        has_url = "url" in server
        if has_command == has_url:
            sys.exit(6)
        transport = server.get("type")
        if transport is not None and transport not in {"stdio", "http", "sse"}:
            sys.exit(6)
        if has_command:
            if transport not in (None, "stdio"):
                sys.exit(6)
            if not isinstance(server.get("command"), str) or not server.get("command"):
                sys.exit(6)
            if "args" in server and (
                not isinstance(server["args"], list)
                or not all(isinstance(item, str) for item in server["args"])
            ):
                sys.exit(6)
            if "env" in server and (
                not isinstance(server["env"], dict)
                or not all(isinstance(key, str) and isinstance(value, str) for key, value in server["env"].items())
            ):
                sys.exit(6)
            for key in ("cwd", "envFile"):
                if key in server and not isinstance(server[key], str):
                    sys.exit(6)
            if "sandboxEnabled" in server and not isinstance(server["sandboxEnabled"], bool):
                sys.exit(6)
            if any(key in server for key in ("url", "headers", "oauth")):
                sys.exit(6)
        else:
            if not isinstance(server.get("url"), str) or not server.get("url"):
                sys.exit(6)
            if transport not in {"http", "sse"}:
                sys.exit(6)
            if any(key in server for key in ("command", "args", "env", "cwd", "envFile", "sandboxEnabled")):
                sys.exit(6)
            if "headers" in server and (
                not isinstance(server["headers"], dict)
                or not all(isinstance(key, str) and isinstance(value, str) for key, value in server["headers"].items())
            ):
                sys.exit(6)
            if "oauth" in server and not isinstance(server["oauth"], dict):
                sys.exit(6)
# Windsurf/Devin Desktop uses a plain `mcpServers` map. Its documented local
# shape is command/args/env; remote HTTP uses exactly one of serverUrl or url,
# with optional string headers. It does not use VS Code's `type` or a generic
# `transport` discriminator. Keep only this documented intersection so a
# foreign schema cannot be written to ~/.codeium/windsurf/mcp_config.json.
if target_ide == "windsurf":
    if not isinstance(servers, dict):
        sys.exit(18)
    for server in servers.values():
        if not isinstance(server, dict) or any(key in server for key in ("type", "transport")):
            sys.exit(18)
        has_command = "command" in server
        remote_keys = [key for key in ("serverUrl", "url") if key in server]
        if has_command and remote_keys:
            sys.exit(18)
        if has_command:
            if set(server) - {"command", "args", "env"}:
                sys.exit(18)
            if not isinstance(server.get("command"), str) or not server.get("command"):
                sys.exit(18)
            if "args" in server and (
                not isinstance(server["args"], list)
                or not all(isinstance(item, str) for item in server["args"])
            ):
                sys.exit(18)
            if "env" in server and (
                not isinstance(server["env"], dict)
                or not all(isinstance(key, str) and isinstance(value, str) for key, value in server["env"].items())
            ):
                sys.exit(18)
        else:
            if len(remote_keys) != 1:
                sys.exit(18)
            remote_key = remote_keys[0]
            if not isinstance(server.get(remote_key), str) or not server.get(remote_key):
                sys.exit(18)
            if set(server) - {remote_key, "headers"}:
                sys.exit(18)
            if "headers" in server and (
                not isinstance(server["headers"], dict)
                or not all(isinstance(key, str) and isinstance(value, str) for key, value in server["headers"].items())
            ):
                sys.exit(18)
# OpenClaw's managed registry is nested at mcp.servers. Do not guess a
# transport for a remote URL: only the documented canonical transport, or the
# documented CLI compatibility type `http`, is safe to normalize.
if target_ide == "openclaw":
    if not isinstance(servers, dict):
        sys.exit(5)
    for server in servers.values():
        if not isinstance(server, dict):
            sys.exit(5)
        if "url" in server:
            transport = server.get("transport")
            if transport == "http":
                server["transport"] = "streamable-http"
            elif transport != "streamable-http":
                sys.exit(5)
# Zed's documented context_servers entries use command/args/env for local
# servers or url/headers for remote servers. Do not copy another IDE's
# transport/type discriminator into settings.json or infer its meaning.
if target_ide == "zed":
    if not isinstance(servers, dict):
        sys.exit(6)
    for server in servers.values():
        if not isinstance(server, dict) or "type" in server:
            sys.exit(6)
        has_command = "command" in server
        has_url = "url" in server
        if has_command == has_url:
            sys.exit(6)
        if has_command:
            if not isinstance(server.get("command"), str):
                sys.exit(6)
            if "args" in server and not isinstance(server["args"], list):
                sys.exit(6)
            if "env" in server and not isinstance(server["env"], dict):
                sys.exit(6)
        else:
            if not isinstance(server.get("url"), str):
                sys.exit(6)
            if "headers" in server and not isinstance(server["headers"], dict):
                sys.exit(6)
# Antigravity IDE's documented remote-MCP schema uses serverUrl. Preserve
# local stdio entries unchanged, but canonicalize an imported remote `url`
# field before writing the shared Antigravity config.
if target_ide == "antigravity" and isinstance(servers, dict):
    for server in servers.values():
        if isinstance(server, dict) and "url" in server:
            server.setdefault("serverUrl", server["url"])
            del server["url"]
existing = {}
if os.path.exists(dst):
    try:
        existing = _load_json_document(dst)
    except Exception:
        if target_ide in {"gemini-cli", "opencode", "kilocode", "kimiai", "kiro", "workbuddy", "jetbrains", "vscode", "windsurf", "void-editor", "augment-code", "baidu-comate", "zcode"}:
            sys.exit(9)
        existing = {}
if not isinstance(existing, dict):
    if target_ide in {"gemini-cli", "opencode", "kilocode", "kimiai", "kiro", "workbuddy", "jetbrains", "vscode", "windsurf", "void-editor", "augment-code", "baidu-comate", "zcode"}:
        sys.exit(9)
    existing = {}
if target_ide == "opencode" and isinstance(existing.get("mcp"), dict):
    existing_mcp = existing["mcp"]
    if target_version == "v2":
        # V1 stores server names directly under mcp. Never leave those beside
        # native V2 mcp.servers; the whole selected MCP object is replaced
        # while unrelated top-level settings and the strategy backup remain.
        if any(key not in {"servers", "timeout"} for key in existing_mcp):
            existing["mcp"] = {}
    elif "servers" in existing_mcp:
        # The inverse migration follows the same rule: do not mix a native V2
        # container with direct V1 server names.
        existing["mcp"] = {}
if strategy == "overwrite":
    # Replace only the selected MCP map. Shared target files such as
    # opencode.json/settings.json may hold unrelated user settings that an MCP
    # migration must not delete.
    if dst_key:
        write_path(existing, dst_key, {})
    else:
        existing = {}
if dst_key:
    cur = read_path(existing, dst_key)
    if not isinstance(cur, dict):
        cur = {}
    if isinstance(servers, dict):
        cur.update(servers)
    write_path(existing, dst_key, cur)
else:
    if isinstance(servers, dict):
        existing.update(servers)
    else:
        existing = servers
with open(dst, "w") as f:
    json.dump(existing, f, indent=2)
sys.exit(0)
PYEOF
        if [[ "$json_conversion_rc" -eq 0 ]]; then
            if MCP_REDACTED_COUNT=$(redact_secrets_in_file "$dst"); then
                CONV_RESULT="success"
                CONV_DETAIL="MCP config converted (root key ${src_key:-mcpServers} -> ${dst_key:-mcpServers}); literal credentials cleared and supported environment references preserved/converted"
            else
                MCP_REDACTED_COUNT=0
                CONV_RESULT="failed"
                CONV_DETAIL="MCP config redaction failed, target file deleted to prevent secret leak (source file untouched)" 
            fi
            return
        fi
        # Exit 4 is reserved for a GitHub Copilot CLI schema/transport that
        # the official documentation does not support. Do not fall back to a
        # verbatim copy: that would write an invalid CLI configuration.
        if [[ "$target_ide" == "copilot" && "$json_conversion_rc" -eq 4 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="GitHub Copilot CLI MCP transport/schema is unsupported; review manually (supported: local, stdio, http, sse)"
            return
        fi
        if [[ "$target_ide" == "vscode" && "$json_conversion_rc" -eq 6 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="VS Code MCP server schema/transport is ambiguous or unsupported; review manually (workspace .vscode/mcp.json uses servers with stdio/http/sse)"
            return
        fi
        if [[ "$target_ide" == "vscode" && "$json_conversion_rc" -eq 9 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="VS Code target .vscode/mcp.json is not a valid JSON object; existing target was not overwritten"
            return
        fi
        if [[ "$target_ide" == "windsurf" && "$json_conversion_rc" -eq 18 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Windsurf/Devin MCP schema is invalid or ambiguous; review documented command/args/env or serverUrl|url/headers shapes"
            return
        fi
        if [[ "$target_ide" == "windsurf" && "$json_conversion_rc" -eq 9 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Windsurf/Devin target mcp_config.json is not a valid JSON object; existing target was not overwritten"
            return
        fi
        if [[ "$target_ide" == "openclaw" && "$json_conversion_rc" -eq 5 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="OpenClaw MCP transport/schema is unsupported; remote entries require url plus transport=streamable-http (no transport is not inferred)"
            return
        fi
        if [[ "$target_ide" == "zed" && "$json_conversion_rc" -eq 6 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Zed context_servers schema is unsupported; review manually (use local command/args/env or remote url/headers; do not infer transport/type)"
            return
        fi
        if [[ "$target_ide" == "cline" && "$json_conversion_rc" -eq 7 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Cline MCP mcpServers schema is invalid or ambiguous; review manually (each server needs exactly one command or url, with args/env/autoApprove/disabled/timeout types validated)"
            return
        fi
        if [[ "$target_ide" == "gemini-cli" && "$json_conversion_rc" -eq 8 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Gemini CLI MCP schema is invalid or ambiguous; review manually (each server needs command, url, or httpUrl, and aliases must not contain underscores)"
            return
        fi
        if [[ "$target_ide" == "gemini-cli" && "$json_conversion_rc" -eq 9 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Gemini CLI target settings.json is not a valid JSON object; existing target was not overwritten"
            return
        fi
        if [[ "$target_ide" == "kilocode" && "$json_conversion_rc" -eq 10 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Kilo Code MCP JSONC schema is invalid or ambiguous; review mcp entries manually (local type=local with command array/environment, remote type=remote with url/headers)"
            return
        fi
        if [[ "$json_conversion_rc" -eq 12 && ("$target_ide" == "kimiai" || "$target_ide" == "kiro" || "$target_ide" == "zcode") ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="target IDE's MCP mcpServers/schema is invalid or ambiguous; please review manually per official command/args or url/headers format" 
            return
        fi
        if [[ "$target_ide" == "workbuddy" && "$json_conversion_rc" -eq 16 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="WorkBuddy desktop MCP schema is unsupported or contains an undocumented remote/metadata field; review manually (documented local shape: command, optional args, optional env)"
            return
        fi
        if [[ "$target_ide" == "jetbrains" && "$json_conversion_rc" -eq 17 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Junie MCP schema is unsupported or contains an undocumented remote/metadata field; review manually (documented local shape: command, optional args, optional env)"
            return
        fi
        if [[ "$target_ide" == "void-editor" && "$json_conversion_rc" -eq 15 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Void MCP schema is invalid or ambiguous; review the custom mcpServers format (command/args/env or URL-only remote; headers/auth require manual review)"
            return
        fi
        if [[ "$target_ide" == "augment-code" && "$json_conversion_rc" -eq 13 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Augment MCP schema is invalid or remote transport is ambiguous; review manually (local command/args/env, remote type=http|sse with url/headers)"
            return
        fi
        if [[ "$target_ide" == "baidu-comate" && "$json_conversion_rc" -eq 14 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Comate MCP schema is invalid; review manually (required type=stdio|sse|streamableHttp with command or url)"
            return
        fi
        if [[ "$target_ide" == "opencode" && "$json_conversion_rc" -eq 10 ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="OpenCode MCP schema is invalid or ambiguous; review manually (local requires type=local plus command array/environment, remote requires type=remote plus url/headers/oauth)"
            return
        fi
        # Gemini's target is always JSON settings.json. An invalid source
        # document or a document without an MCP server map must not fall back
        # to an opaque copy that would overwrite settings.json with YAML,
        # TOML, or another IDE's unrelated configuration.
        if [[ "$target_ide" == "gemini-cli" ]]; then
            CONV_RESULT="failed"
            CONV_DETAIL="Gemini CLI MCP source is not a valid non-empty JSON mcpServers map; manual conversion required"
            return
        fi
        # exit 2 (not JSON) or exit 3 (empty server map) -> fall through to a
        # verbatim copy so we never report a false "success"
    fi

    # Gemini CLI's target settings.json is never a verbatim-copy fallback.
    # Without JSON-aware conversion there is no safe way to produce a valid
    # target, so fail closed for non-JSON sources as well.
    if [[ "$target_ide" == "gemini-cli" ]]; then
        CONV_RESULT="failed"
        CONV_DETAIL="Gemini CLI MCP requires a JSON mcpServers conversion; source format is unsupported for automatic migration"
        return
    fi

    if [[ "$target_ide" == "opencode" ]]; then
        CONV_RESULT="failed"
        CONV_DETAIL="OpenCode MCP requires a JSON mcp conversion; source format is unsupported for automatic migration"
        return
    fi

    if [[ "$target_ide" == "vscode" ]]; then
        CONV_RESULT="failed"
        CONV_DETAIL='VS Code MCP requires a JSON `servers` conversion; source format is unsupported for automatic migration'
        return
    fi

    if [[ "$target_ide" == "windsurf" ]]; then
        CONV_RESULT="failed"
        CONV_DETAIL="Windsurf/Devin MCP requires a JSON mcpServers conversion; source format is unsupported for automatic migration"
        return
    fi

    if [[ "$target_ide" == "kilocode" || "$target_ide" == "kimiai" || "$target_ide" == "kiro" || "$target_ide" == "workbuddy" || "$target_ide" == "jetbrains" || "$target_ide" == "void-editor" || "$target_ide" == "augment-code" || "$target_ide" == "baidu-comate" || "$target_ide" == "zcode" ]]; then
        CONV_RESULT="failed"
        CONV_DETAIL="target IDE's MCP file needs JSON/JSONC Schema conversion; current source format not supported for auto migration" 
        return
    fi

    # An explicit source override is a strict import contract. It changes only
    # the file location; it must still match the declared source IDE's schema.
    # Never copy an arbitrary override file as-is into a target config.
    if [[ -n "${SOURCE_MCP_FILE:-}" ]]; then
        CONV_RESULT="failed"
        CONV_DETAIL="explicit MCP source did not pass schema conversion; copy-as-is fallback is disabled"
        return
    fi

    # Fallback: copy as-is, then strip secrets from the COPY (not the source).
    # Marked "copied" (not "success") because the format was not truly
    # converted and manual adjustment is expected.
    #
    # MED-A2: the fallback is now an EXPLICIT policy, not an implicit code
    # path. Set MCP_ALLOW_COPY_FALLBACK=0 to run strictly fail-closed: any
    # combination that cannot be truly converted is failed instead of copied.
    if [[ "${MCP_ALLOW_COPY_FALLBACK:-1}" -ne 1 ]]; then
        CONV_RESULT="failed"
        CONV_DETAIL="source/target MCP format not directly compatible, and copy-as-is fallback is disabled (MCP_ALLOW_COPY_FALLBACK=0)" 
        return
    fi
    if cp "$src" "$dst"; then
        if [[ -s "$dst" ]]; then
            if MCP_REDACTED_COUNT=$(redact_secrets_in_file "$dst"); then
                CONV_RESULT="copied"
                CONV_DETAIL="MCP config copied as-is (source/target format not directly compatible, manual root key adjustment ${src_key:-?} -> ${dst_key:-?} needed); literal credentials cleared and supported environment references preserved"
            else
                MCP_REDACTED_COUNT=0
                CONV_RESULT="failed"
                CONV_DETAIL="MCP config redaction failed, target file deleted to prevent secret leak (source file untouched)" 
            fi
        else
            CONV_RESULT="failed"
            CONV_DETAIL="MCP config empty after copy" 
        fi
    else
        CONV_RESULT="failed"
        CONV_DETAIL="MCP config copy failed" 
    fi
}

# Read and validate a JSON/JSONC MCP source without creating a target or
# echoing any configuration values. This makes dry-run a real source check,
# including for --source-mcp-file, while keeping preview strictly zero-write.
inspect_mcp_source_file() {
    local src="$1" src_key="$2"

    if ! command -v python3 >/dev/null 2>&1; then
        echo "  [FAIL] cannot validate MCP source without python3: $src" >&2
        return 1
    fi

    python3 - "$src" "$src_key" <<'PYEOF'
import json, re, sys

src, root_key = sys.argv[1], sys.argv[2]

def strip_jsonc(text):
    out = []
    i = 0
    in_string = escaped = line_comment = block_comment = False
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if line_comment:
            if ch in "\r\n":
                line_comment = False
                out.append(ch)
            i += 1
            continue
        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                i += 2
                continue
            if ch in "\r\n":
                out.append(ch)
            i += 1
            continue
        if in_string:
            out.append(ch)
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
        elif ch == "/" and nxt == "/":
            line_comment = True
            i += 2
        elif ch == "/" and nxt == "*":
            block_comment = True
            i += 2
        else:
            out.append(ch)
            i += 1
    text = "".join(out)
    out = []
    i = 0
    in_string = escaped = False
    while i < len(text):
        ch = text[i]
        if in_string:
            out.append(ch)
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
            continue
        if ch == ",":
            j = i + 1
            while j < len(text) and text[j].isspace():
                j += 1
            if j < len(text) and text[j] in "]}":
                i += 1
                continue
        out.append(ch)
        i += 1
    return "".join(out)

def read_path(node, dotted):
    for part in filter(None, dotted.split(".")):
        if not isinstance(node, dict):
            return None
        node = node.get(part)
    return node

try:
    with open(src, encoding="utf-8") as handle:
        document = json.loads(strip_jsonc(handle.read()))
except (OSError, UnicodeError, json.JSONDecodeError) as exc:
    print(f"  [FAIL] MCP source is not readable JSON/JSONC: {exc}", file=sys.stderr)
    sys.exit(1)

servers = read_path(document, root_key)
if not isinstance(servers, dict) or not servers:
    print(
        f"  [FAIL] MCP source has no non-empty object at root key {root_key or '<document>'}",
        file=sys.stderr,
    )
    sys.exit(1)

if not all(isinstance(name, str) and name and isinstance(server, dict) for name, server in servers.items()):
    print("  [FAIL] MCP source server map contains an invalid name or entry", file=sys.stderr)
    sys.exit(1)

for name, server in servers.items():
    has_command = isinstance(server.get("command"), (str, list)) and bool(server.get("command"))
    url_endpoints = [
        key for key in ("url", "serverUrl", "httpUrl")
        if isinstance(server.get(key), str) and bool(server.get(key))
    ]
    if int(has_command) + len(url_endpoints) != 1:
        print(
            f"  [FAIL] MCP source entry {name!r} must declare exactly one command or url endpoint",
            file=sys.stderr,
        )
        sys.exit(1)

print(f"  validated MCP source: {len(servers)} server entries at root key {root_key or '<document>'}")
PYEOF
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
# Shared redaction engine (HI-003 / MED-P7): the Python redactor is written
# ONCE to a temp .py file and reused by BOTH redact_secrets_in_file (single
# file) and redact_project_copy (whole tree in ONE python process instead of
# one fork per file). Regex constants are kept in sync with
# scripts/validate_skills.py::SECRET and the MCP redactor above; drift is
# guarded by the pattern-sync regression test.
REDACTOR_PY=""
ensure_redactor_script() {
    if [[ -n "${REDACTOR_PY:-}" && -f "${REDACTOR_PY:-}" ]]; then
        return 0
    fi
    # NOTE: BSD/macOS mktemp requires the XXXXXX to be the FINAL component —
    # a trailing ".py" suffix would make mktemp fail outright. python3 does
    # not need the extension when the script is passed by path.
    REDACTOR_PY=$(mktemp "${TMPDIR:-/tmp}/redact-engine.XXXXXX") || return 1
    # NOTE: plain redirect (NOT $(...) command substitution) — bash 3.2
    # (macOS default) mis-parses quotes in command-substituted heredocs.
    cat >"$REDACTOR_PY" <<'PYEOF'
import os, re, sys
from urllib.parse import parse_qsl, urlsplit

SECRET_KEY_RE = re.compile(r"(?i)(api[_-]?key|token|secret|password|passwd|authorization|auth|bearer|private[_-]?key|access[_-]?key|client[_-]?secret|session|cookie)")
URL_CRED_RE = re.compile(r"^(?:https?|postgres|postgresql|mysql|mongodb|mongodb\+srv|redis|ftp|amqp|sqlserver)://[^:@/\s]+:[^@/\s]+@", re.IGNORECASE)
URL_TOKEN_RE = re.compile(r"^(https?://)[^/\s]*:(//)?[A-Za-z0-9_\-]{16,}", re.IGNORECASE)
QUERY_CRED_RE = re.compile(r"[?&](key|token|secret|access[_-]?token|api[_-]?key)=[A-Za-z0-9_\-]{12,}", re.IGNORECASE)
# Provider-key value formats (CR-001 fix). See the identical definition in the
# MCP redactor above — kept in sync with validate_skills.py::SECRET.
PROVIDER_SECRET_RE = re.compile(r"(?:sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|tvly-[A-Za-z0-9_-]{16,}|AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|ya29\.[A-Za-z0-9_-]+|AIza[0-9A-Za-z_-]{35}|sk_live_[A-Za-z0-9]{16,})")
SAFE_ENV_REF_TOKEN = r"(?:\$\{env:[A-Za-z_][A-Za-z0-9_]*\}|\$\{[A-Za-z_][A-Za-z0-9_]*\}|\{env:[A-Za-z_][A-Za-z0-9_]*\})"
SAFE_ENV_REF_RE = re.compile(SAFE_ENV_REF_TOKEN)
SAFE_ENV_REF_FULL_RE = re.compile(r"^" + SAFE_ENV_REF_TOKEN + r"$")
SAFE_BEARER_REF_RE = re.compile(r"^Bearer\s+" + SAFE_ENV_REF_TOKEN + r"$", re.IGNORECASE)
# Conventional SHORT flags that carry credentials (mysql/psql -p, -t token,
# -k key). Their names don't contain a secret keyword, so SECRET_KEY_RE can't
# catch them. Deliberate over-redaction tradeoff: the blanked value is always
# recoverable from the untouched SOURCE config.
SHORT_SECRET_FLAGS = {"-p", "-t", "-k"}
FLAG_RE = re.compile(r"^--?[A-Za-z0-9_\-]+$")
FLAG_EQ_RE = re.compile(r"^(--?[A-Za-z0-9_\-]+)=(.+)$")

def is_safe_reference_value(value):
    if not isinstance(value, str):
        return False
    if SAFE_ENV_REF_FULL_RE.fullmatch(value) or SAFE_BEARER_REF_RE.fullmatch(value):
        return True
    if not value.lower().startswith(("http://", "https://")) or not SAFE_ENV_REF_RE.search(value):
        return False
    if PROVIDER_SECRET_RE.search(value) or URL_CRED_RE.match(value) or URL_TOKEN_RE.match(value):
        return False
    try:
        parsed = urlsplit(value)
    except ValueError:
        return False
    if parsed.username or parsed.password:
        return False
    credential_params = [
        param_value
        for key, param_value in parse_qsl(parsed.query, keep_blank_values=True)
        if SECRET_KEY_RE.search(key)
    ]
    return bool(credential_params) and all(SAFE_ENV_REF_FULL_RE.fullmatch(item) for item in credential_params)

def is_secret_value(val):
    if not isinstance(val, str):
        return False
    if is_safe_reference_value(val):
        return False
    if PROVIDER_SECRET_RE.search(val):
        return True
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

def blank_all_quoted(text, preserve_safe_refs=False):
    # Blank every nonempty quoted element; return (new_text, n_blanked).
    n = [0]
    def repl(m):
        if preserve_safe_refs and is_safe_reference_value(m.group(1)):
            return m.group(0)
        n[0] += 1
        return '""'
    new = re.sub(r'["\']([^"\']+)["\']', repl, text)
    return new, n[0]

def redact_one(file):
    TMP = file + ".redact.tmp"
    count = 0
    out = []
    # Depth of a multi-line array opened by a secret-like key (e.g.
    # "API_KEYS": [ ...elements on following lines... ]). Every quoted string
    # element inside such an array is blanked.
    secret_array_depth = 0
    # argv cross-line state: a secret CLI flag seen on a previous line whose
    # value lives on the next line (e.g. JSON '"-p",' then '"MySecret"', or
    # YAML "- --token" then "- sk-live-xxx", or an unclosed inline array).
    flag_pending = False

    def redact_kv(m):
        # Vector ⑤: blank the VALUE of EVERY secret-like keyed pair on a line,
        # not just the first. Only touches quoted leaf values ("v"), never
        # containers ("{") or arrays ("["). The key (and its quoting) is kept.
        nonlocal count
        k = m.group(1).strip().rstrip(":").strip('"\'')
        value = m.group(2)
        if (is_secret_key(k) and not is_safe_reference_value(value)) or is_secret_value(value):
            count += 1
            return '%s""' % m.group(1)
        return m.group(0)

    with open(file) as f:
        raw_lines = f.readlines()

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
                        new_rest, n = blank_all_quoted(rest, preserve_safe_refs=True)
                        line = line[:line.index("[")] + new_rest
                        count += n
                    elif rest.startswith("{") or rest == "":
                        pass
                    else:
                        # Key IS secret -> blank the value unconditionally; the
                        # value need not look secret itself (e.g. "tok-xyz-789").
                        qm = re.match(r'^["\'](.*)["\']\s*,?\s*$', rest)
                        if qm:
                            if qm.group(1) and not is_safe_reference_value(qm.group(1)):
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
                if not is_safe_reference_value(item):
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
        # ---- normal keyed-line handling (single key + arrays + argv).
        # Allow an optional `export ` prefix so POSIX-shell assignments like
        # `export OPENAI_API_KEY="sk-..."` and `KEY="value"` match the same
        # keyed-pair logic as JSON/TOML/YAML entries.
        m = re.match(r'^\s*(?:export\s+)?["\']?([A-Za-z0-9_.\-]+)["\']?\s*[:=]\s*(.*)$', line)
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
                    new_rest, n = blank_all_quoted(rest, preserve_safe_refs=True)
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
                            if is_safe_reference_value(e):
                                new_elems.append(e)
                            else:
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
                if val and ((key_secret and not is_safe_reference_value(val)) or is_secret_value(val)):
                    line = re.sub(r'([:=]\s*)["\'].*?["\'](\s*,?\s*)$', r'\1""\2', line)
                    count += 1
            else:
                # Bare value (TOML/YAML, no surrounding quotes). A rest that
                # STARTS with a quote but did not match the quoted-value regex
                # is NOT a bare value — it is an array element like
                # "--api-key=", (JSON) or an unterminated string; rewriting it
                # would corrupt the file, so leave it untouched.
                bare = rest.rstrip(',').strip()
                if bare and not bare.startswith(('"', "'")) and ((key_secret and not is_safe_reference_value(bare)) or is_secret_value(bare)):
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
                    new_line, n = blank_all_quoted(line, preserve_safe_refs=True)
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

    # Atomic replace: write the fully-redacted content to a temp file first,
    # then swap it in. A crash mid-write can therefore never leave a
    # half-redacted destination; exceptions bubble to the per-file handler.
    with open(TMP, "w") as f:
        f.writelines(out)
    os.replace(TMP, file)
    return count

# Driver: process every file given on argv in ONE interpreter (MED-P7).
# Per-file FAIL CLOSED: on any error the destination copy (and its temp) is
# deleted — the untouched SOURCE config remains the recoverable source of
# truth — and the run exits non-zero after finishing the remaining files.
total = 0
failed = 0
for _f in sys.argv[1:]:
    try:
        total += redact_one(_f)
    except BaseException:
        for _p in (_f + ".redact.tmp", _f):
            try:
                os.unlink(_p)
            except OSError:
                pass
        failed += 1
# flush=True is REQUIRED: stdout is redirected to a file (block buffered).
print(total, flush=True)
sys.exit(4 if failed else 0)
PYEOF
}

# SECURITY: CR-002 fail-closed deletion helper.
# Removes freshly-made MIGRATION COPIES / temp files ONLY — never the source
# config. The `--` terminator stops a copied filename that begins with `-`
# (e.g. a malicious "-rf" entry inside a migrated project tree) from being
# parsed as rm(1) options. Every caller passes a path it just `cp`'d into the
# target IDE; source paths are never handed here.
delete_copy_only() {
    rm -f -- "$@" 2>/dev/null || true
}

redact_secrets_in_file() {
    local file="$1"
    [[ -f "$file" ]] || { echo 0; return 0; }
    # CR-002: fail-closed when python3 is unavailable. Without the redactor we
    # cannot prove the COPY holds no secrets, so we must NOT leave it on disk
    # (and must NOT report "success"). Delete the copy and return non-zero;
    # every caller already treats a non-zero return as "secret-bearing copy
    # removed, migration failed" (e.g. CONV_RESULT="failed" + "target file deleted").
    if ! command -v python3 >/dev/null 2>&1; then
        echo "  [SECURITY] python3 missing, cannot redact $file; target copy deleted to prevent secret leak (source file untouched)" >&2
        delete_copy_only "$file"
        echo 0
        return 1
    fi
    if ! ensure_redactor_script; then
        echo "  [SECURITY] cannot generate redaction engine, target copy deleted to prevent secret leak (source file untouched): $file" >&2
        delete_copy_only "$file"
        echo 0
        return 1
    fi
    local n rc=0 pyout
    pyout=$(mktemp "${TMPDIR:-/tmp}/redact-out.XXXXXX")
    python3 "$REDACTOR_PY" "$file" >"$pyout" || rc=$?
    n=$(cat "$pyout" 2>/dev/null || echo "-1")
    rm -f "$pyout"
    if [[ $rc -ne 0 || -z "$n" || "$n" == "-1" ]]; then
        # FAIL CLOSED (vector ②): python already removed the destination; make
        # doubly sure nothing secret-bearing survives, then signal failure.
        delete_copy_only "$file" "${file}.redact.tmp"
        echo "  [SECURITY] secret redaction failed, target file deleted to prevent leak (source file untouched): $file" >&2
        echo "-1"
        return 1
    fi
    echo "$n"
    return 0
}

migrate_mcp() {
    local source_ide="$1"
    local target_ide="$2"
    local scope="${3:-global}"
    local scope_label="global/user"
    local source_sha256_before=""
    local evidence_backup_path=""
    [[ "$scope" == "project" ]] && scope_label="project"

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    # Goose stores extensions in YAML config.yaml under the `extensions` map.
    # The generic MCP converter is JSON-root based and cannot safely translate
    # Goose's type-specific fields (cmd/args/envs/uri/headers/enabled) or
    # preserve the separate secret/config scopes. Never copy JSON into
    # config.yaml or YAML out as another IDE's MCP file.
    if [[ "$source_ide" == "goose-cli" || "$target_ide" == "goose-cli" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "Goose config.yaml uses YAML extensions; automatic MCP migration is unsupported"
        set_manual_step "mcp" "Goose: manually rebuild each extension under ~/.config/goose/config.yaml/extensions; preserve type (builtin/platform/stdio/streamable_http), cmd/args or uri/headers, enabled, and envs without copying secrets.yaml"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Gemini CLI's settings.json has a documented mcpServers object, but the
    # generic MCP workflow must validate its target schema and keep project
    # scope manual.
    if [[ "$source_ide" == "gemini-cli" || "$target_ide" == "gemini-cli" ]]; then
        set_manual_step "mcp" "Gemini CLI: selected ${scope_label} scope; review ~/.gemini/settings.json versus project .gemini/settings.json, preserve the mcpServers endpoint schema, and review project settings precedence"
    fi

    if [[ "$source_ide" == "opencode" || "$target_ide" == "opencode" ]]; then
        set_manual_step "mcp" "OpenCode: selected ${scope_label} scope and ${OPENCODE_VERSION} target schema; review ~/.config/opencode/opencode.json versus project opencode.json, JSONC files, merged precedence, OAuth/keychain state, and agent-specific MCP permissions manually"
    fi

    if [[ "$source_ide" == "kimiai" || "$target_ide" == "kimiai" ]]; then
        set_manual_step "mcp" "Kimi Code: selected ${scope_label} scope; review ~/.kimi-code/mcp.json versus project .kimi-code/mcp.json and KIMI_CODE_HOME precedence manually"
    fi

    if [[ "$source_ide" == "workbuddy" || "$target_ide" == "workbuddy" ]]; then
        set_manual_step "mcp" "WorkBuddy: selected ${scope_label} scope; the official files are ~/.workbuddy/mcp.json and project .workbuddy/mcp.json. Review the merged mcpServers map in 插件 → MCP 服务器 → 配置 MCP, keep only local command/args/env for automatic conversion, and configure remote URL/OAuth/headers plus enablement in the UI"
    fi

    if [[ "$source_ide" == "kiro" || "$target_ide" == "kiro" ]]; then
        set_manual_step "mcp" "Kiro: selected ${scope_label} scope; review ~/.kiro/settings/mcp.json versus workspace .kiro/settings/mcp.json and Kiro CLI/IDE scope manually"
    fi

    if [[ "$source_ide" == "augment-code" || "$target_ide" == "augment-code" ]]; then
        set_manual_step "mcp" "Augment: selected ${scope_label} scope; review ~/.augment/settings.json, .augment/settings.json/.augment/settings.local.json precedence, and credentials manually"
    fi

    if [[ "$source_ide" == "baidu-comate" || "$target_ide" == "baidu-comate" ]]; then
        set_manual_step "mcp" "Comate: selected ${scope_label} scope; review ~/.comate/mcp.json, .comate/mcp.json, and experimental .comate/mcp.local.json precedence manually"
    fi

    if [[ "$source_ide" == "zcode" || "$target_ide" == "zcode" ]]; then
        set_manual_step "mcp" "ZCode: selected ${scope_label} scope; review ~/.zcode/cli/config.json or workspace .zcode/config.json (root mcp.servers), or use Settings → MCP Servers → Import to select external Claude/Codex/OpenCode/.agents servers. The mapper leaves source files untouched and does not guess .agents precedence"
    fi

    if [[ "$source_ide" == "trae" || "$target_ide" == "trae" ||
          "$source_ide" == "trae-cn" || "$target_ide" == "trae-cn" ]]; then
        if [[ "$scope" == "project" ]]; then
            set_manual_step "mcp" "TRAE: project MCP is .trae/mcp.json with root mcpServers; review command/args/env, URL/headers, workspace variables, and enablement after the narrow merge. Global MCP is configured through the IDE Settings → MCP Servers/raw JSON UI"
        else
            set_status "mcp" "manual"
            set_message "mcp" "TRAE global MCP has an official settings/raw-JSON method but no stable published filesystem path"
            set_manual_step "mcp" "TRAE: open Settings → MCP Servers (or the MCP settings/raw JSON editor), recreate or import the global mcpServers entries there, and review enablement/credentials. Project scope is the documented .trae/mcp.json file; do not infer ~/.trae/mcp.json or ~/.trae-cn/mcp.json"
            MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
            return 0
        fi
    fi

    if [[ "$source_ide" == "void-editor" || "$target_ide" == "void-editor" ]]; then
        set_manual_step "mcp" "Void is deprecated/archived: selected ${scope_label} scope uses legacy ~/.void-editor/mcp.json for the custom store, while inherited VS Code project .vscode/mcp.json uses servers. Automatic conversion is limited to local command/args/env or URL-only remote; headers/auth and migration to Kilo Code require manual review"
    fi

    if [[ "$source_ide" == "jetbrains" || "$target_ide" == "jetbrains" ]]; then
        set_manual_step "mcp" "Junie: selected ${scope_label} scope; review ~/.junie/mcp/mcp.json versus project .junie/mcp/mcp.json; automatic conversion accepts only the documented local command/args/env shape and leaves remote/unknown fields for review"
    fi

    if [[ "$source_ide" == "amazon-q" || "$target_ide" == "amazon-q" ]]; then
        local q_global_default="${HOME}/.aws/amazonq/default.json"
        local q_global_legacy="${HOME}/.aws/amazonq/mcp.json"
        local q_global_agent="${HOME}/.aws/amazonq/agents/default.json"
        local q_project_default="${WORKSPACE_ROOT}/.amazonq/default.json"
        local q_project_legacy="${WORKSPACE_ROOT}/.amazonq/mcp.json"
        local q_project_agent="${WORKSPACE_ROOT}/.amazonq/agents/default.json"

        # The dedicated IDE guide documents default.json/mcp.json, while an
        # overview page and another Q surface mention agents/default.json.
        # AWS publishes no version discriminator. Never guess that the latter
        # is the same standard IDE store; require the user to choose it.
        if [[ "$scope" == "project" ]]; then
            if [[ -f "$q_project_agent" && ! -f "$q_project_default" && ! -f "$q_project_legacy" ]]; then
                set_status "mcp" "manual"
                set_message "mcp" "Amazon Q project agents/default.json exists but its IDE/CLI surface is ambiguous"
                set_manual_step "mcp" "Amazon Q: .amazonq/agents/default.json is documented by another Q surface but is not version-mapped to the IDE .amazonq/default.json file. Choose the active Q product manually, then use the Q panel tools icon or edit the selected mcpServers file; do not overwrite it automatically"
                MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                return 0
            fi
        elif [[ -f "$q_global_agent" && ! -f "$q_global_default" && ! -f "$q_global_legacy" ]]; then
            set_status "mcp" "manual"
            set_message "mcp" "Amazon Q agents/default.json exists but its IDE/CLI surface is ambiguous"
            set_manual_step "mcp" "Amazon Q: ~/.aws/amazonq/agents/default.json is documented by another Q surface but is not version-mapped to the IDE ~/.aws/amazonq/default.json file. Choose the active Q product manually, then use the Q panel tools icon or edit the selected mcpServers file; do not overwrite it automatically"
            MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
            return 0
        fi

        set_manual_step "mcp" "Amazon Q: standard IDE MCP uses ~/.aws/amazonq/default.json and .amazonq/default.json; existing legacy mcp.json is retained only as a legacy source/target. Workspace configuration takes precedence. Review useLegacyMcpJson, permissions, OAuth, CLI agent files, and the Q panel tools icon after this narrow mcpServers merge"
    fi

    # The first-party Blackbox CLI docs describe `blackbox mcp` as running
    # bundled servers, but publish no user/project config file or portable
    # server-root schema. Keep both directions manual.
    if [[ "$source_ide" == "blackbox" || "$target_ide" == "blackbox" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "Blackbox only documents built-in blackbox mcp command; no portable MCP file or server Schema" 
        set_manual_step "mcp" "Blackbox: use official CLI/UI to configure manually; do not infer ~/.blackbox, .blackbox/mcp.json or mcpServers root key" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "pieces" || "$target_ide" == "pieces" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "Pieces is a PiecesOS-backed MCP server, not a file-backed MCP client"
        set_manual_step "mcp" "Pieces: keep PiecesOS running and enable LTM, then configure the consuming IDE with the current endpoint from PiecesOS/Desktop Settings → MCP or use pieces mcp setup; do not invent ~/.pieces/.pieces or copy a client MCP file into Pieces"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Replit MCP connections are managed by the cloud Integrations surface;
    # there is no documented local MCP file or portable server-root schema.
    # Never infer one from .replit, replit.nix, or another IDE's config.
    if [[ "$source_ide" == "replit" || "$target_ide" == "replit" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "Replit MCP connections are cloud/UI-managed through Integrations; no local MCP file is migrated"
        set_manual_step "mcp" "Replit: manage MCP connections at replit.com/integrations or the Agent MCP settings pane; do not copy .replit/replit.nix or infer a local MCP file"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "cody" || "$target_ide" == "cody" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "Cody MCP is configured through the cody.mcpServers extension setting/UI; standalone file migration is unsupported"
        set_manual_step "mcp" "Cody: enable the Enterprise agentic-context MCP feature, then review VS Code settings.json or JetBrains cody_settings.json and the Cody MCP Settings UI; only local MCP tools are supported"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Supermaven is a completion plugin, not a documented MCP client. The
    # official Supermaven surfaces publish no MCP file or server schema, so do
    # not reinterpret a host editor's MCP settings as Supermaven config.
    if [[ "$source_ide" == "supermaven" || "$target_ide" == "supermaven" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "Supermaven has no documented portable MCP file or server schema; automatic migration is unsupported"
        set_manual_step "mcp" "Supermaven: configure MCP, if needed, in the host editor's documented MCP surface; do not infer ~/.supermaven or .supermaven as an MCP file"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Continue's current config is YAML and mcpServers is an array of named
    # entries. The generic converter only understands JSON object roots; a
    # verbatim fallback would write invalid JSON/YAML or the wrong schema.
    if [[ "$source_ide" == "continue" || "$target_ide" == "continue" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "Continue uses YAML/array configuration; automatic MCP/config migration is unsupported"
        set_manual_step "mcp" "Review ~/.continue/config.yaml or .continue/mcpServers/*.yaml manually; preserve mcpServers as an array of named entries and migrate secrets through Continue's documented environment/secret references"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Roo has a documented project file (.roo/mcp.json), but its global MCP
    # file lives in an extension-managed settings directory whose exact path
    # is not published by Roo's official docs. Project scope is safe to
    # convert through the documented mcpServers JSON file; global scope stays
    # manual and must never be confused with Cline or VS Code storage.
    if [[ "$source_ide" == "roo-code" || "$target_ide" == "roo-code" ]]; then
        if [[ "$scope" != "project" ]]; then
            set_status "mcp" "manual"
            set_message "mcp" "Roo Code global MCP is extension-storage/UI managed; no stable official filesystem path is published"
            set_manual_step "mcp" "Roo Code: configure global MCP through the Roo MCP settings UI; do not infer a VS Code globalStorage or Cline path. Project MCP is separately documented at .roo/mcp.json"
            MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
            return 0
        fi
        set_manual_step "mcp" "Roo Code: project scope uses .roo/mcp.json with root mcpServers; review mode permissions, remote headers/auth, and extension behavior after the narrow JSON merge. Global MCP remains UI-managed"
    fi

    # Cline's MCP settings live in the VS Code extension globalStorage
    # (cline_mcp_settings.json under saoudrizwan.claude-dev/settings/). A
    # legacy ~/.cline/mcp.json CLI alternative may also exist; when both are
    # present without an explicit CLINE_MCP_PATH override, refuse an ambiguous
    # global migration and ask the user to choose. Project scope is separate.
    if [[ "$source_ide" == "cline" || "$target_ide" == "cline" ]]; then
        if [[ "$scope" != "project" ]]; then
            local cline_primary
            cline_primary="$(get_mcp_path cline)"
            local cline_alternative="${HOME}/.cline/mcp.json"
            if [[ -z "${CLINE_MCP_PATH:-}" && -f "$cline_primary" && -f "$cline_alternative" ]]; then
                set_status "mcp" "manual"
                set_message "mcp" "Cline has both the globalStorage MCP settings and the ~/.cline/mcp.json CLI alternative; the active store is ambiguous"
                set_manual_step "mcp" "Cline: choose one global MCP store — the VS Code globalStorage cline_mcp_settings.json (resolve with --print-path cline mcp) or the ~/.cline/mcp.json CLI file — or set CLINE_MCP_PATH explicitly. VS Code Insiders/VSCodium/relocated --user-data-dir change the globalStorage base. The project file is .cline/mcp.json"
                MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                return 0
            fi
            set_manual_step "mcp" "Cline: global MCP writes to the VS Code globalStorage cline_mcp_settings.json (saoudrizwan.claude-dev/settings/). A legacy ~/.cline/mcp.json CLI alternative may exist; CLINE_MCP_PATH overrides the target for non-standard installs. Verify with the Cline MCP panel or 'cline mcp'. Project MCP is .cline/mcp.json"
        else
            set_manual_step "mcp" "Cline: project MCP is .cline/mcp.json with mcpServers; review IDE/CLI precedence and validate with the Cline MCP panel or cline mcp after the narrow merge"
        fi
    fi

    if [[ "$source_ide" == "claude-desktop" || "$target_ide" == "claude-desktop" ]]; then
        if [[ -z "$(get_mcp_path claude-desktop)" ]]; then
            set_status "mcp" "manual"
            set_message "mcp" "Claude Desktop has no confirmed legacy JSON path on this platform"
            set_manual_step "mcp" "Claude Desktop: on macOS use ~/Library/Application Support/Claude/claude_desktop_config.json; on native Windows use %APPDATA%\\Claude\\claude_desktop_config.json but do not guess MSIX virtualized paths; on Linux use Settings → Extensions or verify the current Developer path manually. For all platforms, install .mcpb through Settings → Extensions → Advanced settings → Install Extension; configure remote MCP through Settings → Connectors. Claude Code can import supported Desktop entries with claude mcp add-from-claude-desktop on macOS/WSL."
            MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
            return 0
        fi
        set_manual_step "mcp" "Claude Desktop legacy local MCP JSON is migrated only at the documented platform path; install modern local servers as .mcpb via Settings → Extensions → Advanced settings → Install Extension, and configure remote MCP via Settings → Connectors. Claude Code's official claude mcp add-from-claude-desktop remains the supported interactive import on macOS/WSL."
    fi

    local source_mcp
    local target_mcp
    if [[ "$scope" == "project" ]]; then
        source_mcp=$(get_project_mcp_path "$source_ide")
        target_mcp=$(get_project_mcp_path "$target_ide")
    else
        source_mcp=$(get_mcp_path "$source_ide")
        target_mcp=$(get_mcp_path "$target_ide")
    fi

    if [[ -n "${SOURCE_MCP_FILE:-}" ]]; then
        source_mcp="$SOURCE_MCP_FILE"
        set_manual_step "mcp" "explicit MCP source override: validate '$source_mcp' against the declared $source_ide schema; only the source location is overridden, while the target remains registry-resolved"
    fi

    # VS Code's user MCP file is profile/UI-managed and intentionally has no
    # portable path in this mapper. A workspace target is portable and is
    # safe to write under the explicitly selected workspace root.
    if [[ "$scope" != "project" && -z "$source_mcp" && "$source_ide" == "vscode" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "VS Code user MCP is profile-managed; no absolute path was guessed"
        set_manual_step "mcp" "VS Code: use MCP: Open User Configuration or MCP: Add Server in the active Profile; code --add-mcp is also documented. For a workspace use .vscode/mcp.json with root servers. Do not use GitHub Copilot CLI ~/.copilot/mcp-config.json or its mcpServers root as a VS Code file"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi
    # VS Code's user MCP file is profile/UI-managed and intentionally has no
    # portable path in this mapper. A workspace target is portable and is
    # safe to write under the explicitly selected workspace root — but ONLY
    # when the user actually requested project scope, otherwise `--scope
    # global` to vscode would still write the workspace path.
    if [[ "$target_ide" == "vscode" && "$scope" == "project" ]]; then
        target_mcp="$WORKSPACE_ROOT/.vscode/mcp.json"
    fi

    # Project-relative MCP paths (e.g. Kilo's .kilo/kilo.jsonc) resolve
    # against the workspace root, not the caller's cwd.
    if [[ -n "$source_mcp" && "$source_mcp" != /* ]]; then
        source_mcp="$WORKSPACE_ROOT/$source_mcp"
    fi
    if [[ -n "$target_mcp" && "$target_mcp" != /* ]]; then
        target_mcp="$WORKSPACE_ROOT/$target_mcp"
    fi

    if [[ -z "$source_mcp" ]]; then
        set_status "mcp" "skipped"
        set_message "mcp" "source IDE does not support MCP configuration" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ -z "$target_mcp" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "target IDE does not support MCP configuration, manual migration required"
        set_manual_step "mcp" "target IDE ($target_ide) does not support automatic MCP migration, please refer to IDE Registry to configure manually"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Refuse to operate when source and target resolve to the same file.
    # Several IDEs share project-MCP paths: claude/copilot/tencent-codebuddy
    # all map to `.mcp.json`; trae/trae-cn both map to `.trae/mcp.json`.
    # Without this guard, either merge strategy would write the converted
    # target map back into the only source file. Refuse the operation before
    # a backup or conversion can mutate that source.
    local source_identity target_identity
    if command -v python3 >/dev/null 2>&1; then
        source_identity="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$source_mcp")"
        target_identity="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$target_mcp")"
    else
        source_identity="$(cd "$(dirname "$source_mcp")" 2>/dev/null && pwd -P)/$(basename "$source_mcp")"
        target_identity="$(cd "$(dirname "$target_mcp")" 2>/dev/null && pwd -P)/$(basename "$target_mcp")"
    fi
    if [[ "$source_identity" == "$target_identity" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "MCP source and target resolve to the same file; refusing to self-overwrite"
        set_manual_step "mcp" "MCP: source and target IDEs share '$source_mcp' on this workspace; pick a different target or relocate the source manually before retrying"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$scope" == "project" ]]; then
        set_manual_step "mcp" "project MCP: this run only processes explicit workspace file ${source_mcp} -> ${target_mcp}; review project priority, Workspace Trust, approval, OAuth/headers and same-name server conflicts" 
    else
        set_manual_step "mcp" "user MCP: this run only processes user-level file; project MCP, local scope, Workspace Trust and UI/profile state still need manual review" 
    fi

    # Claude Code exposes project MCP through .mcp.json and keeps local MCP
    # entries inside ~/.claude.json. This generic mapper has only one MCP
    # object and therefore migrates a Claude endpoint at user scope only.
    # Preserve the other documented scopes as an explicit manual review step
    # instead of pretending that settings.local.json or a project directory is
    # an interchangeable MCP target.
    if [[ "$source_ide" == "claude" || "$target_ide" == "claude" ]]; then
        set_manual_step "mcp" "Claude Code: selected ${scope_label} scope; review ~/.claude.json user/local entries, project .mcp.json, and local per-project entries manually"
    fi

    if [[ "$source_ide" == "tabnine" || "$target_ide" == "tabnine" ]]; then
        set_manual_step "mcp" "Tabnine: selected ${scope_label} scope; review ~/.tabnine/mcp_servers.json versus project .tabnine/mcp_servers.json and configure extension-managed permissions in Tabnine Settings manually"
    fi

    if [[ "$source_ide" == "tencent-codebuddy" || "$target_ide" == "tencent-codebuddy" ]]; then
        set_manual_step "mcp" "CodeBuddy Code: selected ${scope_label} scope; review ~/.codebuddy/.mcp.json, project .mcp.json, legacy ~/.codebuddy/mcp.json/~/.codebuddy.json, --mcp-config overrides, and .codebuddy/settings.json approval keys manually"
    fi

    # Copilot CLI has two project-level files with the same mcpServers root.
    # This generic mapper intentionally works only on the documented user
    # file, because choosing .mcp.json versus .github/mcp.json would alter
    # repository scope and precedence without user direction.
    if [[ "$source_ide" == "copilot" || "$target_ide" == "copilot" ]]; then
        set_manual_step "mcp" "GitHub Copilot CLI: selected ${scope_label} scope; review ~/.copilot/mcp-config.json and project .mcp.json/.github/mcp.json (both mcpServers) manually"
    fi

    print_progress "MIGRATE" "Migrating MCP server configuration..." 

    if [[ ! -e "$source_mcp" ]]; then
        set_status "mcp" "absent"
        set_message "mcp" "source MCP config does not exist: $source_mcp" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    source_sha256_before="$(sha256_file "$source_identity" 2>/dev/null || true)"

    # Codex stores MCP servers as TOML tables in config.toml. This script has
    # no TOML-aware MCP converter, so it must never copy JSON mcpServers into
    # that file (nor claim a same-format Codex transfer is safe). Rebuild the
    # server manually in the correct trusted user/project config scope.
    if [[ "$source_ide" == "codex" || "$target_ide" == "codex" ]]; then
        set_status "mcp" "manual"
        set_message "mcp" "Codex MCP config uses TOML; auto migration unsupported, manual migration required" 
        set_manual_step "mcp" "rebuild servers using [mcp_servers.<server-name>] TOML table in Codex user ~/.codex/config.toml or trusted project .codex/config.toml; stdio uses command, Streamable HTTP uses url" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        record_mcp_evidence "$scope" "$source_identity" "$target_identity" "$source_sha256_before"
        return 0
    fi

    local src_key dst_key
    src_key=$(get_mcp_root_key "$source_ide" "$scope")
    dst_key=$(get_mcp_root_key "$target_ide" "$scope")

    if [[ -n "${SOURCE_MCP_FILE:-}" ]]; then
        if ! inspect_mcp_source_file "$source_mcp" "$src_key"; then
            set_status "mcp" "failed"
            set_message "mcp" "explicit MCP source failed strict schema validation"
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            record_mcp_evidence "$scope" "$source_identity" "$target_identity" "$source_sha256_before"
            return 0
        fi
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  DRY-RUN: converting MCP config" 
        echo "    source: $source_mcp (root key: ${src_key:-none})" 
        echo "    target: $target_mcp (root key: ${dst_key:-none})" 
        # Dry-run only prints the plan; never mark success.
        set_status "mcp" "skipped"
        set_message "mcp" "DRY-RUN: planned MCP config conversion (${src_key:-?} -> ${dst_key:-?})" 
        record_mcp_evidence "$scope" "$source_identity" "$target_identity" "$source_sha256_before"
        return 0
    fi

    mkdir -p "$(dirname "$target_mcp")"

    if [[ -e "$target_mcp" ]]; then
        case "$STRATEGY" in
            skip)
                echo "  [SKIP] target MCP config already exists: $target_mcp" 
                set_status "mcp" "skipped"
                set_message "mcp" "target MCP config already exists, skip (strategy: skip)" 
                MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                record_mcp_evidence "$scope" "$source_identity" "$target_identity" "$source_sha256_before"
                return 0
                ;;
            backup)
                local ts
                ts="$(date +%Y%m%d%H%M%S).$$"
                cp -r "$target_mcp" "$target_mcp.bak.$ts"
                evidence_backup_path="$target_identity.bak.$ts"
                echo "  [BACKUP] backed up existing MCP config: $target_mcp.bak.$ts" 
                ;;
            overwrite)
                # `convert_mcp_file` replaces only the selected server map so
                # unrelated keys in a shared config file remain intact.
                ;;
        esac
    fi

    convert_mcp_file "$source_mcp" "$src_key" "$target_mcp" "$dst_key" "$target_ide" "$STRATEGY" "$OPENCODE_VERSION"

    case "$CONV_RESULT" in
        success)
            echo "  [OK] converted MCP config: ${src_key:-mcpServers} -> ${dst_key:-mcpServers}" 
            if [[ ${MCP_REDACTED_COUNT:-0} -ne 0 ]]; then
            echo "  [SECURITY] literal credentials in MCP config were cleared; exact supported environment references were preserved or converted. Review target environment/secret-manager bindings before enabling."
            fi
            set_status "mcp" "success"
            set_message "mcp" "$CONV_DETAIL"
            MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
            ;;
        copied)
            echo "  [COPY] copied MCP config as-is: $target_mcp" 
            if [[ ${MCP_REDACTED_COUNT:-0} -ne 0 ]]; then
            echo "  [SECURITY] literal credentials in MCP config were cleared; exact supported environment references were preserved. Review target environment/secret-manager bindings before enabling."
            fi
            set_status "mcp" "copied"
            set_message "mcp" "$CONV_DETAIL"
            set_manual_step "mcp" "check MCP root key compatibility: ${src_key:-?} -> ${dst_key:-?}" 
            MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
            ;;
        failed)
            echo "  [FAIL] MCP config migration failed" 
            set_status "mcp" "failed"
            set_message "mcp" "$CONV_DETAIL"
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            ;;
        *)
            echo "  [FAIL] MCP config migration unknown state" 
            set_status "mcp" "failed"
        set_message "mcp" "MCP config migration failed (unknown state)" 
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            ;;
    esac

    record_mcp_evidence "$scope" "$source_identity" "$target_identity" "$source_sha256_before" "$evidence_backup_path"
}

migrate_config() {
    local source_ide="$1"
    local target_ide="$2"

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    # Goose config.yaml is YAML and combines provider/model settings,
    # extensions, permissions, and slash_commands. It is not a portable
    # whole-IDE schema and can refer to secrets stored separately in
    # secrets.yaml/keyring; fail closed instead of byte-copying it into a
    # different IDE or overwriting it from a different format.
    if [[ "$source_ide" == "goose-cli" || "$target_ide" == "goose-cli" ]]; then
        set_status "config" "manual"
        set_message "config" "Goose config.yaml is YAML and combines provider/extensions/settings; automatic config migration is unsupported"
        set_manual_step "config" "Goose: review ~/.config/goose/config.yaml, permission.yaml, secrets.yaml/keyring, prompts/, and slash_commands separately; do not copy another IDE config into Goose YAML"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Gemini CLI whole settings.json is a target-specific schema; copying
    # another IDE's config into it would silently alter unrelated settings.
    if [[ "$source_ide" == "gemini-cli" || "$target_ide" == "gemini-cli" ]]; then
        set_status "config" "manual"
        set_message "config" "Gemini CLI settings.json schema requires manual review; automatic whole-config migration is unsupported"
        set_manual_step "config" "Gemini CLI: review ~/.gemini/settings.json and project .gemini/settings.json manually; preserve settings schema, context.fileName, MCP, and trust policy"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # OpenCode's JSON/JSONC config is target-specific, merged across global
    # and project scopes, and may reference MCP auth, plugins, commands,
    # agents, and instructions. The MCP sub-object has a dedicated converter;
    # whole-config copying is intentionally fail-closed.
    if [[ "$source_ide" == "opencode" || "$target_ide" == "opencode" ]]; then
        set_status "config" "manual"
        set_message "config" "OpenCode opencode.json/opencode.jsonc is a merged target-specific schema; automatic whole-config migration is unsupported"
        set_manual_step "config" "OpenCode: review ~/.config/opencode/opencode.json, project opencode.json, OPENCODE_CONFIG/OPENCODE_CONFIG_CONTENT, JSONC comments, plugins, agents, commands, instructions, MCP, and auth state manually"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "kimiai" || "$target_ide" == "kimiai" ]]; then
        set_status "config" "manual"
        set_message "config" "Kimi Code config.toml is a target-specific TOML config; whole-file auto migration unsupported" 
        set_manual_step "config" "Kimi Code: review ~/.kimi-code/config.toml, KIMI_CODE_HOME, tui.toml, credentials, hooks, and provider settings manually; do not copy another IDE schema into TOML"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "augment-code" || "$target_ide" == "augment-code" ]]; then
        set_status "config" "manual"
        set_message "config" "Augment settings.json combines providers, MCP, permissions, and project precedence; whole-config migration is unsupported"
        set_manual_step "config" "Augment: review ~/.augment/settings.json, .augment/settings.json, and .augment/settings.local.json manually; preserve project precedence and reconfigure credentials"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "tencent-codebuddy" || "$target_ide" == "tencent-codebuddy" ]]; then
        set_status "config" "manual"
        set_message "config" "CodeBuddy settings.json is a target-specific layered security config; whole-file auto migration unsupported" 
        set_manual_step "config" "CodeBuddy: review ~/.codebuddy/settings.json, .codebuddy/settings.json, .codebuddy/settings.local.json, permissions, hooks, and memory manually"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "zcode" || "$target_ide" == "zcode" ]]; then
        set_status "config" "manual"
        set_message "config" "ZCode config.json is a target-specific config containing MCP/plugin/Agent state; whole-file auto migration unsupported" 
        set_manual_step "config" "ZCode: review ~/.zcode/cli/config.json and .zcode/config.json manually; preserve mcp.servers, plugins, agents, hooks, and GUI-managed credentials"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Blackbox configure is interactive and its storage path/schema is not
    # published in the current first-party CLI docs.
    if [[ "$source_ide" == "blackbox" || "$target_ide" == "blackbox" ]]; then
        set_status "config" "manual"
        set_message "config" "Blackbox configure's storage path and Schema are not disclosed in official docs; auto config migration unsupported" 
        set_manual_step "config" "Blackbox: run/review official blackbox configure flow; do not infer ~/.blackbox or copy ~/.blackbox private state" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "pieces" || "$target_ide" == "pieces" ]]; then
        set_status "config" "manual"
        set_message "config" "Pieces has no documented portable whole-IDE config file"
        set_manual_step "config" "Pieces: review PiecesOS/Desktop Settings and CLI state manually; never copy PiecesOS database directories or infer ~/.pieces as a config file"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # .replit and replit.nix configure the app runtime/build environment and
    # are project-scoped. They are not portable AI settings and must not be
    # copied through the generic config object.
    if [[ "$source_ide" == "replit" || "$target_ide" == "replit" ]]; then
        set_status "config" "manual"
        set_message "config" "Replit app configuration (.replit/replit.nix) is project-scoped and manual"
        set_manual_step "config" "Review .replit and replit.nix separately as Replit app/runtime configuration; do not copy them as AI config, skills, or MCP"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "cody" || "$target_ide" == "cody" ]]; then
        set_status "config" "manual"
        set_message "config" "Cody has no documented portable whole-IDE config file; automatic config migration is unsupported"
        set_manual_step "config" "Cody: review only the documented extension settings surface (VS Code settings.json or JetBrains cody_settings.json); do not infer ~/.config/cody or cody.json"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Supermaven settings are configured through the host editor extension or
    # the official Neovim plugin's setup() call. No standalone portable
    # Supermaven config file/schema is documented, so fail closed.
    if [[ "$source_ide" == "supermaven" || "$target_ide" == "supermaven" ]]; then
        set_status "config" "manual"
        set_message "config" "Supermaven has no documented portable standalone config file; automatic config migration is unsupported"
        set_manual_step "config" "Supermaven: review host-editor settings or supermaven-nvim setup() manually; do not copy ~/.supermaven runtime storage or another IDE's settings file"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # config.yaml is the current Continue format; config.json is deprecated.
    # This mapper has no YAML parser or schema-aware Continue JSON↔YAML
    # converter, so fail closed instead of copying one format into the other.
    if [[ "$source_ide" == "continue" || "$target_ide" == "continue" ]]; then
        set_status "config" "manual"
        set_message "config" "Continue uses YAML/array configuration; automatic MCP/config migration is unsupported"
        set_manual_step "config" "Review ~/.continue/config.yaml manually; do not copy it as JSON or copy another IDE's config into it. Legacy config.json and .continuerc.json require the official YAML migration guide"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    local source_config
    source_config=$(get_config_file "$source_ide")
    local target_config
    target_config=$(get_config_file "$target_ide")

    # Aider's YAML config is a target-specific schema. This mapper only knows
    # how to expose its documented path; copying another IDE's config into it
    # (or copying it elsewhere) would be an unsafe format/precedence change.
    if [[ "$source_ide" == "aider" || "$target_ide" == "aider" ]]; then
        set_status "config" "manual"
        set_message "config" "Aider .aider.conf.yml is YAML/CLI config, cross-IDE auto migration unsupported" 
        set_manual_step "config" "manually review Aider's .aider.conf.yml, AIDER_* env vars, .env, CLI flags and --config/--env-file; do not copy other IDE config directly as Aider YAML" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ -z "$target_config" ]]; then
        set_status "config" "manual"
        set_message "config" "target IDE has no specific config file, manual migration required" 
        set_manual_step "config" "target IDE ($target_ide) does not support automatic config migration, please handle manually" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Neovim documents init.lua/init.vim as editor configuration, but it does
    # not define a portable AI-IDE object format. A generic byte-for-byte copy
    # from another IDE would produce invalid or unsafe Lua, while copying a
    # Neovim init.lua can silently replace a user's editor configuration.
    # Keep the diagnostic config path, but fail closed for automatic migration.
    if [[ "$source_ide" == "neovim" || "$target_ide" == "neovim" ]]; then
        set_status "config" "manual"
        set_message "config" "Neovim init.lua is editor config, cross-IDE auto conversion unsupported, manual review needed" 
        set_manual_step "config" "manually review ~/.config/nvim/init.lua (or init.vim); do not copy other IDE config directly as Neovim Lua, and do not overwrite existing config with auto migration" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Claude Code has distinct user, project, and local settings scopes. Add
    # the scope warning before the source-exists check so a migration from an
    # IDE without a portable config still reports the manual review required
    # for the Claude target.
    if [[ "$source_ide" == "claude" || "$target_ide" == "claude" ]]; then
        set_manual_step "config" "Claude Code: only user settings.json is mapped automatically; review project .claude/settings.json and local .claude/settings.local.json manually"
    fi

    if [[ -z "$source_config" ]]; then
        set_status "config" "skipped"
        set_message "config" "source IDE has no specific config file" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    print_progress "MIGRATE" "Migrating IDE config..." 

    if [[ ! -f "$source_config" ]]; then
        set_status "config" "absent"
        set_message "config" "source config file does not exist: $source_config" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Codex config.toml can carry MCP tables and hooks. Copying it to another
    # IDE would be an invalid schema transfer, and copying another IDE's config
    # into Codex could silently overwrite a trusted-project boundary. Keep all
    # Codex config migration manual; project config remains diagnostic-only.
    if [[ "$source_ide" == "codex" || "$target_ide" == "codex" ]]; then
        set_status "config" "manual"
        set_message "config" "Codex config.toml auto migration unsupported, manual migration required" 
        set_manual_step "config" "manually review Codex user ~/.codex/config.toml and trusted project .codex/config.toml; do not copy TOML, MCP or hooks config across IDEs" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  DRY-RUN: copying config file" 
        echo "    source: $source_config" 
        echo "    target: $target_config" 
        # Dry-run only prints the plan; never mark success.
        set_status "config" "skipped"
        set_message "config" "DRY-RUN: planned config file copy" 
        return 0
    fi

    mkdir -p "$(dirname "$target_config")"

    if [[ -e "$target_config" ]]; then
        case "$STRATEGY" in
            skip)
                echo "  [SKIP] target config file already exists: $target_config" 
                set_status "config" "skipped"
                set_message "config" "target config file already exists, skip (strategy: skip)" 
                MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                return 0
                ;;
            backup)
                local ts
                ts="$(date +%Y%m%d%H%M%S).$$"
                cp -r "$target_config" "$target_config.bak.$ts"
                echo "  [BACKUP] backed up existing config file: $target_config.bak.$ts" 
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
    if cp "$source_config" "$target_config"; then
        if [[ -s "$target_config" ]]; then
            echo "  [COPY] copied config file: $target_config" 
            # SECURITY: settings/config files routinely embed API keys and
            # tokens. Strip them from the COPY (never the source) — same
            # policy as MCP migration.
            local config_redacted
            if config_redacted=$(redact_secrets_in_file "$target_config"); then
                if [[ "${config_redacted:-0}" -gt 0 ]]; then
                    echo "  [SECURITY] cleared $config_redacted suspected secret values, please reconfigure credentials in target IDE" 
                    set_manual_step "config" "config file's $config_redacted secrets have been cleared, need to re-enter in target IDE" 
                fi
                set_status "config" "copied"
                set_message "config" "config file copied (manual format adjustment may be needed, secrets cleared): $target_config" 
                set_manual_step "config" "check and adjust IDE config file format ($source_ide -> $target_ide)" 
                MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
            else
                echo "  [FAIL] config file redaction failed, target copy deleted to prevent secret leak" 
                set_status "config" "failed"
                set_message "config" "config file redaction failed, target copy deleted to prevent secret leak (source file untouched)" 
                MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            fi
        else
            echo "  [FAIL] config file empty after copy" 
            set_status "config" "failed"
        set_message "config" "config file empty after copy" 
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
        fi
    else
        echo "  [FAIL] config file copy failed" 
        set_status "config" "failed"
        set_message "config" "config file copy failed" 
        MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
    fi
}

# Redact secrets in every config-like text file under a migrated project
# tree (the COPY, never the source). Prints the total number of blanked
# values. Fail-closed: redact_secrets_in_file already deletes a copy it
# cannot redact; this helper then reports partial failure via rc=1.
redact_project_copy() {
    # MED-P7: collect all candidate files first, then redact them in ONE
    # python interpreter (the shared engine loops over argv) instead of
    # forking python once per file. Fail-closed semantics are preserved:
    # any per-file failure deletes that copy and the engine exits non-zero.
    local root="$1"
    local total=0 had_fail=0 f rc=0 pyout
    local -a excluded_env_files=()
    local -a files=()

    # .env files are secret stores, not portable configuration. Exclude them
    # from the COPY entirely rather than briefly retaining and regex-redacting
    # them. Include symlinks so a copied .env link cannot escape the target.
    while IFS= read -r -d '' f; do
        excluded_env_files+=("$f")
    done < <(find "$root" \( -type f -o -type l \) -name '.env*' -print0 2>/dev/null)
    if [[ ${#excluded_env_files[@]} -gt 0 ]]; then
        delete_copy_only "${excluded_env_files[@]}"
        echo "  [SECURITY] excluded ${#excluded_env_files[@]} .env file(s) from migrated copy" >&2
    fi

    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$root" -name '*.bak.*' -prune -o -type f \( \
        -name '*.json' -o -name '*.jsonc' -o -name '*.yaml' -o -name '*.yml' \
        -o -name '*.toml' \
        -o -name '*.sh' -o -name '*.bash' -o -name '*.zsh' \) -print0 2>/dev/null)

    if [[ ${#files[@]} -eq 0 ]]; then
        echo 0
        return 0
    fi

    # CR-002 fail-closed: no python3 -> we cannot prove the copies are clean.
    # SECURITY: route through delete_copy_only() so the `--` terminator guards
    # against a copied filename beginning with `-` being parsed as rm options,
    # and the fail-closed surface is uniform with redact_secrets_in_file.
    if ! command -v python3 >/dev/null 2>&1; then
        echo "  [SECURITY] python3 missing, cannot redact project copy; candidate file deleted to prevent secret leak (source directory untouched)" >&2
        delete_copy_only "${files[@]}"
        echo 0
        return 1
    fi
    if ! ensure_redactor_script; then
        echo "  [SECURITY] cannot generate redaction engine, candidate file deleted to prevent secret leak (source directory untouched)" >&2
        delete_copy_only "${files[@]}"
        echo 0
        return 1
    fi

    pyout=$(mktemp "${TMPDIR:-/tmp}/redact-out.XXXXXX")
    python3 "$REDACTOR_PY" "${files[@]}" >"$pyout" || rc=$?
    total=$(cat "$pyout" 2>/dev/null || echo "-1")
    rm -f "$pyout"
    if [[ $rc -ne 0 || -z "$total" || "$total" == "-1" ]]; then
        had_fail=1
        echo "  [SECURITY] project copy redaction has failures, failed files deleted to prevent leak (source directory untouched)" >&2
        [[ "$total" == "-1" || -z "$total" ]] && total=0
    fi
    echo "$total"
    return $had_fail
}

migrate_project() {
    local source_ide="$1"
    local target_ide="$2"

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))

    # .goose is a mixed local namespace for recipes and Memory files. It is
    # not a generic project config root and must never be copied opaquely.
    if [[ "$source_ide" == "goose-cli" || "$target_ide" == "goose-cli" ]]; then
        set_status "project" "manual"
        set_message "project" "Goose .goose contains scoped recipes and memory, not a portable project config tree"
        set_manual_step "project" "Goose: review .goose/recipes/*.yaml and .goose/memory/ independently; migrate .goosehints and .agents/skills through their dedicated objects, never copy the whole .goose directory"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "vscode" || "$target_ide" == "vscode" ]]; then
        set_status "project" "manual"
        set_message "project" "VS Code .vscode mixes MCP, settings, tasks, launch, and extension state"
        set_manual_step "project" "VS Code: review .vscode/mcp.json, settings.json, tasks.json, launch.json, and extension state separately; use dedicated MCP/rules/prompt objects instead of copying the whole .vscode directory"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "windsurf" || "$target_ide" == "windsurf" ]]; then
        set_status "project" "manual"
        set_message "project" "Windsurf/Devin .windsurf mixes Skills, rules, workflows, memories, and application state"
        set_manual_step "project" "Windsurf/Devin: review .windsurf/ objects separately; migrate Skills, rules, workflows, and MCP by their documented scopes, and never copy the whole namespace"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "opencode" || "$target_ide" == "opencode" ||
          "$source_ide" == "kilocode" || "$target_ide" == "kilocode" ||
          "$source_ide" == "kimiai" || "$target_ide" == "kimiai" ||
          "$source_ide" == "workbuddy" || "$target_ide" == "workbuddy" ||
          "$source_ide" == "kiro" || "$target_ide" == "kiro" ||
          "$source_ide" == "augment-code" || "$target_ide" == "augment-code" ||
          "$source_ide" == "baidu-comate" || "$target_ide" == "baidu-comate" ||
          "$source_ide" == "tencent-codebuddy" || "$target_ide" == "tencent-codebuddy" ||
          "$source_ide" == "zcode" || "$target_ide" == "zcode" ||
          "$source_ide" == "roo-code" || "$target_ide" == "roo-code" ||
          "$source_ide" == "void-editor" || "$target_ide" == "void-editor" ]]; then
        set_status "project" "manual"
        set_message "project" "target IDE's project namespace mixes Skills, rules, MCP, Agent or app state; whole-directory auto migration unsupported" 
        set_manual_step "project" "review project objects separately: Roo .roo/, OpenCode .opencode/, Kilo .kilo/, Kimi .kimi-code/, WorkBuddy .workbuddy/, Kiro .kiro/, Augment .augment/, Comate .comate/, CodeBuddy .codebuddy/, ZCode .zcode/; Void has no verified portable project directory; use respective project-skills/project-mcp/rules objects" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Gemini CLI's .gemini namespace mixes settings, Skills, commands, agents,
    # and memory. Never copy it opaquely as a generic project configuration.
    if [[ "$source_ide" == "gemini-cli" || "$target_ide" == "gemini-cli" ]]; then
        set_status "project" "manual"
        set_message "project" "Gemini CLI .gemini is a mixed settings/Skills/commands namespace; whole-project migration is unsupported"
        set_manual_step "project" "Gemini CLI: review .gemini/settings.json, .gemini/skills, .gemini/commands, .gemini/agents, and GEMINI.md separately; preserve each documented scope/schema"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # `.blackbox` is a mixed Blackbox workspace namespace whose only
    # documented portable object here is `.blackbox/skills`. Never copy the
    # whole directory opaquely.
    if [[ "$source_ide" == "blackbox" || "$target_ide" == "blackbox" ]]; then
        set_status "project" "manual"
        set_message "project" "Blackbox .blackbox is a mixed workspace namespace; whole project directory auto migration unsupported" 
        set_manual_step "project" "Blackbox: only review/migrate .blackbox/skills/ per official docs; do not copy entire .blackbox or infer its private config files" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "pieces" || "$target_ide" == "pieces" ]]; then
        set_status "project" "manual"
        set_message "project" "Pieces has no documented portable repository configuration namespace"
        set_manual_step "project" "Pieces: do not copy .pieces as an opaque project directory; configure host-IDE project instructions/MCP separately and keep PiecesOS data local"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Replit's .replit file is app/runtime configuration, not a portable
    # project context directory. Keep this boundary manual so a project
    # migration cannot silently copy build/run settings across IDEs.
    if [[ "$source_ide" == "replit" || "$target_ide" == "replit" ]]; then
        set_status "project" "manual"
        set_message "project" "Replit project app/runtime files (.replit, replit.nix) are manual"
        set_manual_step "project" "Review .replit and replit.nix as Replit app/runtime files; migrate only replit.md or .agents/skills through their dedicated object scopes"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "cody" || "$target_ide" == "cody" ]]; then
        set_status "project" "manual"
        set_message "project" "Cody has no documented portable project configuration namespace"
        set_manual_step "project" "Cody: do not copy .cody as an opaque project directory; review instructions, prompts, MCP, and extension settings separately in their documented surfaces"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Supermaven has no documented project configuration namespace. The
    # first-party maintainer describes .supermavenignore as an indexing
    # exclusion file only; it is not a portable project settings tree.
    if [[ "$source_ide" == "supermaven" || "$target_ide" == "supermaven" ]]; then
        set_status "project" "manual"
        set_message "project" "Supermaven has no documented portable project configuration namespace"
        set_manual_step "project" "Supermaven: preserve .supermavenignore only for repository indexing exclusions and review host-editor/Neovim settings manually; do not copy it as project config"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # .continue is a mixed workspace namespace (models, rules, prompts, and
    # MCP blocks). It is not a generic project-config tree, so copying it from
    # or into another IDE would cross YAML/JSON and scope boundaries.
    if [[ "$source_ide" == "continue" || "$target_ide" == "continue" ]]; then
        set_status "project" "manual"
        set_message "project" "Continue .continue workspace blocks require manual migration"
        set_manual_step "project" "Review .continue/models, .continue/rules, .continue/prompts, and .continue/mcpServers individually; preserve each documented schema and scope"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Tabnine's .tabnine directory mixes guideline files and project MCP.
    # Never copy it opaquely as a generic project config tree.
    if [[ "$source_ide" == "tabnine" || "$target_ide" == "tabnine" ]]; then
        set_status "project" "manual"
        set_message "project" "Tabnine .tabnine is a mixed guideline/MCP namespace; automatic whole-directory migration is unsupported"
        set_manual_step "project" "Review .tabnine/guidelines/*.md and .tabnine/mcp_servers.json separately; preserve project scope and configure MCP permissions through Tabnine Settings"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    local source_project
    source_project=$(get_project_path "$source_ide")
    local target_project
    target_project=$(get_project_path "$target_ide")

    # .amazonq is a multi-object Amazon Q project namespace, not a portable
    # whole-project configuration format. Do not copy its MCP/rules files as
    # an opaque directory.
    if [[ "$source_ide" == "amazon-q" || "$target_ide" == "amazon-q" ]]; then
        set_status "project" "manual"
        set_message "project" "Amazon Q project namespace .amazonq is manual; rules and MCP have separate schemas/scopes"
        set_manual_step "project" "Review .amazonq/rules/*.md and .amazonq/default.json separately; do not copy the entire .amazonq directory"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ "$source_ide" == "jetbrains" || "$target_ide" == "jetbrains" ]]; then
        set_status "project" "manual"
        set_message "project" "JetBrains .junie is a mixed Junie namespace; whole-directory migration is unsupported"
        set_manual_step "project" "Junie: review .junie/skills, .junie/AGENTS.md, legacy .junie/guidelines.md, and .junie/mcp/mcp.json separately; do not copy the whole .junie directory or Junie CLI config.json"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Both TRAE builds use a mixed project namespace containing Skills, Rules,
    # MCP, commands, agents, hooks, memory, and state. Never copy `.trae/`
    # opaquely; use the dedicated object paths and manual boundaries above.
    if [[ "$source_ide" == "trae" || "$target_ide" == "trae" || "$source_ide" == "trae-cn" || "$target_ide" == "trae-cn" ]]; then
        set_status "project" "manual"
        set_message "project" "TRAE .trae project namespace mixes Skills, Rules, MCP, commands, agents, hooks, memory, and state" 
        set_manual_step "project" "TRAE: review .trae/ objects separately; migrate Skills, .trae/rules, .trae/commands, .trae/mcp.json, agents, hooks, memory, and skill-config.json by their documented scopes; do not copy the whole namespace"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Antigravity's .agents project namespace mixes Skills, rules, MCP,
    # hooks, plugins, and other product state. Dedicated object mappings are
    # available, but opaque whole-project copying would cross those schemas.
    if [[ "$source_ide" == "antigravity" || "$target_ide" == "antigravity" ]]; then
        set_status "project" "manual"
        set_message "project" "Antigravity .agents project namespace mixes Skills, rules, MCP, hooks, plugins, and product state"
        set_manual_step "project" "Antigravity: review .agents/skills, .agents/rules, .agents/mcp_config.json, .agents/hooks.json, and .agents/plugins separately; the IDE and CLI share some locations but are different product surfaces; do not copy .agents opaquely"
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    # Aider's project file is YAML with Aider-specific option names and
    # precedence. Do not byte-copy another IDE's project config into it, or
    # export it as another IDE's project format; both directions require a
    # deliberate manual translation.
    if [[ "$source_ide" == "aider" || "$target_ide" == "aider" ]]; then
        set_status "project" "manual"
        set_message "project" "Aider .aider.conf.yml project config needs manual review, auto copy disabled" 
        set_manual_step "project" "manually review project root .aider.conf.yml; rebuild per Aider's YAML options, read list, CLI priority and AIDER_*/.env sources, do not directly copy other IDE config" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ -z "$source_project" ]]; then
        set_status "project" "skipped"
        set_message "project" "source IDE does not support project-level configuration" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    if [[ -z "$target_project" ]]; then
        set_status "project" "skipped"
        set_message "project" "target IDE does not support project-level configuration" 
        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
        return 0
    fi

    print_progress "MIGRATE" "Migrating project-level configuration..." 

    local source_path="$WORKSPACE_ROOT/$source_project"
    local target_path="$WORKSPACE_ROOT/$target_project"

    if [[ ! -e "$source_path" ]]; then
        set_status "project" "skipped"
        set_message "project" "source project config does not exist: $source_project" 
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
        set_message "project" "project config ready to migrate" 
    else
        if [[ -d "$source_path" ]]; then
            # Apply the migration strategy to an EXISTING target (dir or file).
            if [[ -e "$target_path" ]]; then
                case "$STRATEGY" in
                    skip)
                        echo "  [SKIP] target project config already exists: $target_project" 
                        set_status "project" "skipped"
                        set_message "project" "target project config already exists, skip (strategy: skip)" 
                        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                        return 0
                        ;;
                    backup)
                        local ts
                        ts="$(date +%Y%m%d%H%M%S).$$"
                        cp -r "$target_path" "$target_path.bak.$ts"
                        echo "  [BACKUP] backed up existing project config: $target_project.bak.$ts" 
                        ;;
                    overwrite)
                        if ! safe_remove_path_within "$WORKSPACE_ROOT" "$target_path"; then
                            set_status "project" "failed"
                            set_message "project" "refused unsafe target project deletion"
                            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
                            return 0
                        fi
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
            set_message "project" "source project config directory is empty: $source_project" 
                MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                return 0
            fi
            if cp -r "$source_path"/. "$target_path"/; then
                if [[ $(find "$target_path" -type f 2>/dev/null | wc -l | tr -d ' ') -eq 0 ]]; then
                    set_status "project" "failed"
                    set_message "project" "project config empty after copy" 
                    MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
                else
                    echo "  [OK] migrated project config directory" 
                    # SECURITY: project trees routinely bundle .env / .toml /
                    # json credentials (local service configs, etc.). Strip
                    # them from the COPY (never the source) — same policy as
                    # the mcp and config migrations. Fail-closed: if any file
                    # cannot be redacted, the whole copy is removed so no
                    # secret-bearing file is left on disk.
                    local proj_redacted proj_rc=0
                    proj_redacted=$(redact_project_copy "$target_path") || proj_rc=$?
                    if [[ "$proj_rc" -ne 0 ]]; then
                        echo "  [FAIL] project config redaction failed, target copy deleted to prevent secret leak" 
                        safe_remove_path_within "$WORKSPACE_ROOT" "$target_path" || true
                        set_status "project" "failed"
                    set_message "project" "project config redaction failed, target copy deleted to prevent secret leak (source file untouched)" 
                        MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
                    else
                        if [[ "${proj_redacted:-0}" -gt 0 ]]; then
                        echo "  [SECURITY] cleared $proj_redacted suspected secret values, check credentials in target project and reconfigure" 
                        set_manual_step "project" "project config's $proj_redacted secrets have been cleared, please re-enter in target IDE (e.g. .env / config file)" 
                        fi
                        set_status "project" "success"
                    set_message "project" "project config directory migrated, secrets cleared: $target_project" 
                        MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
                    fi
                fi
            else
                set_status "project" "failed"
                    set_message "project" "project config migration failed" 
                MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            fi
        else
            # Single project-level config FILE case (e.g. .dir-locals.el,
            # .aider.conf.yml, .github/copilot-instructions.md).
            if [[ -e "$target_path" ]]; then
                case "$STRATEGY" in
                    skip)
                        echo "  [SKIP] target project config file already exists: $target_project" 
                        set_status "project" "skipped"
                        set_message "project" "target project config file already exists, skip (strategy: skip)" 
                        MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
                        return 0
                        ;;
                    backup)
                        local ts
                        ts="$(date +%Y%m%d%H%M%S).$$"
                        cp "$target_path" "$target_path.bak.$ts"
                        echo "  [BACKUP] backed up existing project config file: $target_project.bak.$ts" 
                        ;;
                    overwrite)
                        rm -f "$target_path"
                        ;;
                esac
            fi
            mkdir -p "$(dirname "$target_path")"
            if cp "$source_path" "$target_path"; then
                if [[ ! -s "$target_path" ]]; then
                    set_status "project" "failed"
                    set_message "project" "project config file empty after copy" 
                    MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
                else
                    echo "  [OK] migrated project config file" 
                    local proj_redacted proj_rc=0
                    proj_redacted=$(redact_project_copy "$target_path") || proj_rc=$?
                    if [[ "$proj_rc" -ne 0 ]]; then
                        echo "  [FAIL] project config redaction failed, target copy deleted to prevent secret leak" 
                        rm -f "$target_path"
                        set_status "project" "failed"
                    set_message "project" "project config redaction failed, target copy deleted to prevent secret leak (source file untouched)" 
                        MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
                    else
                        if [[ "${proj_redacted:-0}" -gt 0 ]]; then
                        echo "  [SECURITY] cleared $proj_redacted suspected secret values, check credentials in target project and reconfigure" 
                        set_manual_step "project" "project config's $proj_redacted secrets have been cleared, please re-enter in target IDE" 
                        fi
                        set_status "project" "success"
                    set_message "project" "project config file migrated, secrets cleared: $target_project" 
                        MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
                    fi
                fi
            else
                set_status "project" "failed"
                    set_message "project" "project config file migration failed" 
                MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            fi
        fi
    fi
}

manual_only_object() {
    local object="$1"
    local source_ide="$2"
    local target_ide="$3"

    MIGRATION_TOTAL=$((MIGRATION_TOTAL + 1))
    case "$object" in
        agents)
            set_status "agents" "manual"
            set_message "agents" "Agents/Subagents are product-specific schema; currently diagnosis only, no auto conversion" 
            set_manual_step "agents" "Agents ($source_ide -> $target_ide): review official surfaces like .github/agents, .claude/agents, .cursor/agents, .trae/agents, .kiro/agents, .codebuddy/agents, .zcode/agents separately; do not copy tools, permissions, hooks, handoffs or mcpServers fields across IDEs" 
            ;;
        hooks)
            set_status "hooks" "manual"
            set_message "hooks" "Hooks execute commands and each IDE's events/schema/scope differ; cross-IDE auto migration has no safe strict intersection" 
            set_manual_step "hooks" "Hooks ($source_ide -> $target_ide): review .github/hooks, .trae/hooks.json, .kiro/hooks/*, .windsurf/hooks.json, Codex hooks.json or settings hooks; do not auto-execute, copy or rewrite commands from one shell to another" 
            ;;
        memory)
            set_status "memory" "manual"
            set_message "memory" "Memory is mostly local/cloud generated state, project identity encoding and schema are inconsistent; currently only listing manual handling boundaries" 
            set_manual_step "memory" "Memory ($source_ide -> $target_ide): Trae/Claude/Codex/Windsurf generated memory, Replit replit.md, Amazon Q .amazonq/rules/memory-bank, Goose memory, CodeBuddy CODEBUDDY.md/Auto Memory, WorkBuddy UI/private memory need item-by-item review; copying entire memory directory is prohibited" 
            ;;
        *)
            set_status "$object" "failed"
            set_message "$object" "unsupported manual object: $object" 
            MIGRATION_FAILED=$((MIGRATION_FAILED + 1))
            ;;
    esac
    MIGRATION_SKIPPED=$((MIGRATION_SKIPPED + 1))
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
                migrate_skills "$source_ide" "$target_ide" "$SCOPE"
                ;;
            rules)
                migrate_rules "$source_ide" "$target_ide"
                ;;
            prompts)
                migrate_prompts "$source_ide" "$target_ide"
                ;;
            mcp)
                if [[ "$SCOPE" == "both" ]]; then
                    migrate_mcp "$source_ide" "$target_ide" "global"
                    migrate_mcp "$source_ide" "$target_ide" "project"
                else
                    migrate_mcp "$source_ide" "$target_ide" "$SCOPE"
                fi
                ;;
            project-mcp)
                migrate_mcp "$source_ide" "$target_ide" "project"
                # Keep the explicit object name visible in reports while
                # reusing the MCP converter's status/detail and manual notes.
                local project_mcp_status project_mcp_message project_mcp_steps project_mcp_step
                project_mcp_status=$(get_status "mcp")
                project_mcp_message=$(get_message "mcp")
                [[ -n "$project_mcp_status" ]] && set_status "project-mcp" "$project_mcp_status"
                [[ -n "$project_mcp_message" ]] && set_message "project-mcp" "$project_mcp_message"
                project_mcp_steps=$(get_manual_steps "mcp")
                if [[ -n "$project_mcp_steps" ]]; then
                    while IFS= read -r project_mcp_step; do
                        [[ -n "$project_mcp_step" ]] && set_manual_step "project-mcp" "$project_mcp_step"
                    done <<< "$project_mcp_steps"
                fi
                ;;
            agents|hooks|memory)
                manual_only_object "$obj" "$source_ide" "$target_ide"
                ;;
            config)
                migrate_config "$source_ide" "$target_ide"
                ;;
            project)
                migrate_project "$source_ide" "$target_ide"
                ;;
            *)
                echo "[WARN] unknown content type: $obj" 
                ;;
        esac
    done
}

generate_report() {
    local source_ide="$1"
    local target_ide="$2"
    local report=""

    report+="========================================\n"
    report+="       IDE migration report
" 
    report+="========================================\n"
    report+="\n"
    report+="Migration details:
" 
    report+="  source IDE: $(get_ide_name "$source_ide") ($source_ide)
" 
    report+="  target IDE: $(get_ide_name "$target_ide") ($target_ide)
" 
    report+="  workspace: $WORKSPACE_ROOT
" 
    report+="  strategy: $STRATEGY
" 
    report+="  time: $(date '+%Y-%m-%dT%H:%M:%S%z')\n"  # portable (BSD date lacks -Iseconds)
    report+="\n"
    report+="Statistics:
" 
    report+="  total operations: $MIGRATION_TOTAL
" 
    report+="  succeeded: $MIGRATION_SUCCESS
" 
    report+="  failed: $MIGRATION_FAILED
" 
    report+="  skipped: $MIGRATION_SKIPPED
" 
    report+="\n"
    report+="Detailed results:
" 

    for obj in skills rules prompts mcp project-mcp config project agents hooks memory; do
        local status
        status=$(get_status "$obj")
        if [[ -n "$status" ]]; then
            local message
            message=$(get_message "$obj")
            local status_icon

            case "$status" in
                success) status_icon="OK" ;;
                copied)  status_icon="OK" ;;
                manual)  status_icon="WARN" ;;
                partial) status_icon="WARN" ;;
                failed)  status_icon="FAIL" ;;
                absent)  status_icon="-" ;;
                skipped) status_icon="-" ;;
                *)       status_icon="?" ;;
            esac

            report+="  [$status_icon] $obj: $message\n"
        fi
    done

    report+="\n"
    report+="Steps requiring manual handling:
" 

    local has_manual=0
    for obj in skills rules prompts mcp project-mcp config project agents hooks memory; do
        local steps
        steps=$(get_manual_steps "$obj")
        if [[ -n "$steps" ]]; then
            has_manual=1
            report+="\n  [$obj]\n"
            report+="    $steps\n"
        fi
    done

    if [[ $has_manual -eq 0 ]]; then
        report+="  none - all migrations completed automatically
" 
    fi

    report+="\n"
    report+="========================================\n"

    if [[ "${MIGRATE_JSON:-}" == "1" ]]; then
        _emit_json_report "$source_ide" "$target_ide"
    else
        printf '%b' "$report"
    fi
}

# Emit a machine-readable JSON summary (used when MIGRATE_JSON=1 / --json).
_emit_json_report() {
    local source_ide="$1"
    local target_ide="$2"
    local entries=()
    local object_entries=()
    local requested_object

    for obj in skills rules prompts mcp project-mcp config project agents hooks memory; do
        local status message token steps
        status=$(get_status "$obj")
        [[ -n "$status" ]] || continue
        message=$(get_message "$obj")
        token=$(status_token "$status")
        entries+=("$(printf '{"object":"%s","status":"%s","token":"%s","message":"%s"}' \
            "$obj" "$status" "$token" "$(json_escape "$message")")")
        steps=$(get_manual_steps "$obj")
        if [[ -n "$steps" ]]; then
            entries+=("$(printf '{"object":"%s","status":"manual","token":"WARN","steps":"%s"}' \
                "$obj" "$(json_escape "$steps")")")
        fi
    done

    local entries_json
    entries_json=$(IFS=,; echo "${entries[*]}")
    while IFS= read -r requested_object; do
        [[ -n "$requested_object" ]] || continue
        object_entries+=("\"$(json_escape "$requested_object")\"")
    done < <(printf '%s\n' "$OBJECTS" | tr ',' '\n')
    local objects_json
    objects_json=$(IFS=,; echo "${object_entries[*]}")

    local report_scope="$SCOPE"
    if [[ ",$OBJECTS," == *",project-mcp,"* && ",$OBJECTS," != *",mcp,"* ]]; then
        report_scope="project"
    fi
    local report_mode="apply"
    [[ $DRY_RUN -eq 1 ]] && report_mode="dry-run"

    local evidence_json=""
    if [[ -s "$MIGRATION_EVIDENCE_FILE" ]]; then
        evidence_json="$(paste -sd, "$MIGRATION_EVIDENCE_FILE")"
    fi

    printf '{"source_ide":"%s","target_ide":"%s","mode":"%s","scope":"%s","objects":[%s],"workspace":"%s","strategy":"%s","opencode_version":"%s","statistics":{"total":%s,"succeeded":%s,"failed":%s,"skipped":%s},"results":[%s],"evidence":{"mcp":[%s]}}\n' \
        "$source_ide" "$target_ide" "$report_mode" "$report_scope" "$objects_json" "$(json_escape "$WORKSPACE_ROOT")" "$STRATEGY" "$OPENCODE_VERSION" \
        "$MIGRATION_TOTAL" "$MIGRATION_SUCCESS" "$MIGRATION_FAILED" "$MIGRATION_SKIPPED" \
        "$entries_json" "$evidence_json"
}


main() {
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
            --source-mcp-file)
                if [[ $# -lt 2 || -z "${2:-}" ]]; then
                    echo "Error: --source-mcp-file requires a file path" >&2
                    exit 1
                fi
                SOURCE_MCP_FILE="$2"
                shift 2
                ;;
            --opencode-version)
                if [[ $# -lt 2 || -z "${2:-}" ]]; then
                    echo "Error: --opencode-version requires v1 or v2" >&2
                    exit 1
                fi
                OPENCODE_VERSION="$2"
                OPENCODE_VERSION_EXPLICIT=1
                shift 2
                ;;
            --scope)
                SCOPE="$2"
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
            --json)
                MIGRATE_JSON=1
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
            echo "Error: unknown argument: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done

    case "$STRATEGY" in
        skip|backup|overwrite)
            ;;
        *)
            echo "Error: invalid strategy: $STRATEGY (options: skip, backup, overwrite)" >&2
            exit 1
            ;;
    esac

    if [[ "${MIGRATE_JSON:-}" == "1" ]]; then
        exec 3>&1
        exec 1>&2
    fi

    # Suppress the banner in read-only diagnostic mode so --print-path emits only
    # the resolved path on stdout (keeps test-ide-paths.sh comparisons exact).
    if [[ -z "$PRINT_PATH_IDE" ]]; then
        print_header
    fi

    if [[ -n "$PRINT_PATH_IDE" ]]; then
        if ! validate_ide "$PRINT_PATH_IDE"; then
            echo "Error: invalid IDE: $PRINT_PATH_IDE" >&2
            echo "Supported IDEs: $SUPPORTED_IDES" >&2
            exit 1
        fi

        resolved=""
        case "$PRINT_PATH_OBJECT" in
            global)  resolved=$(get_global_path "$PRINT_PATH_IDE") ;;
            project) resolved=$(get_project_path "$PRINT_PATH_IDE") ;;
            project-skills) resolved=$(get_project_skills_path "$PRINT_PATH_IDE") ;;
            mcp)     resolved=$(get_mcp_path "$PRINT_PATH_IDE") ;;
            project-mcp) resolved=$(get_project_mcp_path "$PRINT_PATH_IDE") ;;
            project-config) resolved=$(get_project_config_file "$PRINT_PATH_IDE") ;;
            config)  resolved=$(get_config_file "$PRINT_PATH_IDE") ;;
            rules)   resolved=$(get_rules_file "$PRINT_PATH_IDE") ;;
            prompts|commands) resolved=$(get_prompts_path "$PRINT_PATH_IDE") ;;
            *)
            echo "Error: unsupported object: $PRINT_PATH_OBJECT (options: global, project, project-skills, mcp, project-mcp, project-config, config, rules, prompts|commands)" >&2
                exit 1
                ;;
        esac

        if [[ -z "$resolved" ]]; then
            echo "Error: $PRINT_PATH_IDE does not support object: $PRINT_PATH_OBJECT" >&2
            exit 1
        fi

        if [[ "$resolved" == "${HOME}/"* ]]; then
            resolved="~${resolved#"${HOME}"}"
        fi

        echo "$resolved"
        exit 0
    fi

    if [[ -z "$SOURCE_IDE" ]]; then
            echo "Error: source IDE must be specified (--source)" >&2
        echo "" >&2
            echo "Supported IDEs:" >&2
        for ide in $SUPPORTED_IDES; do
            printf "  - %-12s %s\n" "$ide" "$(get_ide_name "$ide")" >&2
        done
        exit 1
    fi

    if [[ -z "$TARGET_IDE" ]]; then
            echo "Error: target IDE must be specified (--target)" >&2
        echo "" >&2
            echo "Supported IDEs:" >&2
        for ide in $SUPPORTED_IDES; do
            printf "  - %-12s %s\n" "$ide" "$(get_ide_name "$ide")" >&2
        done
        exit 1
    fi

    if ! validate_ide "$SOURCE_IDE"; then
            echo "Error: invalid source IDE: $SOURCE_IDE" >&2
            echo "Supported IDEs: $SUPPORTED_IDES" >&2
        exit 1
    fi

    if ! validate_ide "$TARGET_IDE"; then
            echo "Error: invalid target IDE: $TARGET_IDE" >&2
            echo "Supported IDEs: $SUPPORTED_IDES" >&2
        exit 1
    fi

    case "$OPENCODE_VERSION" in
        v1|v2)
            ;;
        *)
            echo "Error: invalid OpenCode version: $OPENCODE_VERSION (options: v1, v2)" >&2
            exit 1
            ;;
    esac
    if [[ $OPENCODE_VERSION_EXPLICIT -eq 1 && "$TARGET_IDE" != "opencode" ]]; then
        echo "Error: --opencode-version applies only when --target opencode" >&2
        exit 1
    fi

    case "$SCOPE" in
        global|project|both)
            ;;
        *)
            echo "Error: invalid scope: ${SCOPE} (options: global, project, both)" >&2
            exit 1
            ;;
    esac

    if [[ "$SOURCE_IDE" == "$TARGET_IDE" ]]; then
            echo "Error: source IDE and target IDE cannot be the same" >&2
        exit 1
    fi

    if [[ -z "$OBJECTS" ]]; then
        OBJECTS=$(list_available_objects "$SOURCE_IDE" | tr ',' '\n' | grep -E '^(skills|rules|prompts)$' | paste -sd, -)
        if [[ -z "$OBJECTS" ]]; then
            OBJECTS="skills,rules,prompts"
        fi
        echo "No --objects specified: by default only low-risk types are migrated (skills,rules,prompts)." >&2
        echo "To migrate mcp/config/project (which may contain secrets), please specify --objects explicitly and confirm reviewed." >&2
    fi

    if [[ -n "$SOURCE_MCP_FILE" ]]; then
        if [[ "$OBJECTS" != *mcp* ]]; then
            echo "Error: --source-mcp-file requires --objects mcp or project-mcp" >&2
            exit 1
        fi
        if [[ "$SCOPE" == "both" ]]; then
            echo "Error: --source-mcp-file cannot represent both global and project MCP scopes; choose one scope" >&2
            exit 1
        fi
        if [[ ! -f "$SOURCE_MCP_FILE" || ! -r "$SOURCE_MCP_FILE" ]]; then
            echo "Error: --source-mcp-file must name a readable regular file: $SOURCE_MCP_FILE" >&2
            exit 1
        fi
        case "${SOURCE_MCP_FILE##*.}" in
            json|jsonc) ;;
            *)
                echo "Error: --source-mcp-file accepts JSON or JSONC only; YAML/TOML MCP formats require manual reconstruction" >&2
                exit 1
                ;;
        esac
        if ! command -v python3 >/dev/null 2>&1; then
            echo "Error: --source-mcp-file requires python3 for safe path and schema validation" >&2
            exit 1
        fi
        SOURCE_MCP_FILE="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$SOURCE_MCP_FILE")"
    fi

    if [[ "$OBJECTS" == *mcp* || "$OBJECTS" == *config* || "$OBJECTS" == *project* ]]; then
        echo "" >&2
        log_warn "SECURITY: This migration includes mcp/config/project, which may contain API keys, tokens," >&2
        log_warn "bearer credentials or embedded URL credentials. Literal credentials are cleared; exact supported environment references may be converted to target syntax."
        log_warn "Review target environment/secret-manager bindings before enabling. Run only between sources and targets you trust."
        echo "" >&2
    fi

    echo "========================================"
    echo "Migration summary" 
    echo "========================================"
    echo ""
    echo "  source IDE: $(get_ide_name "$SOURCE_IDE")" 
    echo "  target IDE: $(get_ide_name "$TARGET_IDE")" 
    echo "  workspace: $WORKSPACE_ROOT" 
    echo "  migration content: $OBJECTS" 
    if [[ -n "$SOURCE_MCP_FILE" ]]; then
        echo "  explicit MCP source: $SOURCE_MCP_FILE"
    fi
    echo "  scope: $SCOPE (only applies to skills/mcp)" 
    echo "  strategy: $STRATEGY" 
    echo ""

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  mode: DRY-RUN (will not modify any files)" 
    fi

    echo ""

    if [[ $DRY_RUN -eq 0 && $ASSUME_YES -eq 0 ]]; then
        if [[ -t 0 ]]; then
        printf 'About to write target IDE config per above summary. Continue? [y/N] ' >&2
            read -r _confirm_reply
            case "$_confirm_reply" in
                y|Y|yes|YES)
                    ;;
                *)
        echo "Cancelled: no files modified. You can preview with --dry-run first." >&2
                    exit 2
                    ;;
            esac
        else
        echo "Error: non-interactive environment and --yes not specified, refusing to write for safety." >&2
        echo "Please preview changes with --dry-run first, then append --yes to execute. No files modified." >&2
            exit 2
        fi
    fi

    init_migration_files

    echo "[START] starting migration: $(get_ide_name "$SOURCE_IDE") -> $(get_ide_name "$TARGET_IDE")" 
    echo ""

    run_migration "$SOURCE_IDE" "$TARGET_IDE"

    echo ""
    echo "========================================"
    echo "       migration complete" 
    echo "========================================"
    echo ""

    if [[ "${MIGRATE_JSON:-}" == "1" ]]; then
        exec 1>&3
    fi

    report=$(generate_report "$SOURCE_IDE" "$TARGET_IDE")
    echo "$report"

    if [[ -n "$REPORT_FILE" ]]; then
        echo "$report" > "$REPORT_FILE"
        if [[ "${MIGRATE_JSON:-}" == "1" ]]; then
            echo "Report saved to: $REPORT_FILE" >&2
        else
            echo "Report saved to: $REPORT_FILE"
        fi
    fi

    # An explicit source file is a strict import contract. Surface schema or
    # conversion failure to automation through the process status as well as
    # the human-readable report; never make a rejected override look accepted.
    if [[ -n "${SOURCE_MCP_FILE:-}" && $MIGRATION_FAILED -gt 0 ]]; then
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
