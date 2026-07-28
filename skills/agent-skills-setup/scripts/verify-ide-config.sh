#!/usr/bin/env bash

# Verify each IDE's config paths against the IDE Registry (real path validation).
#
# Uses smart-ide-migration.sh's read-only diagnostic flag --print-path to resolve
# the real path for each IDE/object type, then compares it exactly against the registry.
# Any mismatch prints a FAIL line and the script exits non-zero at the end.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_SCRIPT="${SCRIPT_DIR}/smart-ide-migration.sh"

if [[ ! -f "$MIGRATION_SCRIPT" ]]; then
    echo "ERROR: migration script not found: $MIGRATION_SCRIPT" >&2
    exit 1
fi

# Resolve platform-specific EXPECTED entries. Some IDE paths (e.g. Cline's MCP
# store under the VS Code extension's user/globalStorage) differ between macOS,
# Linux, and Windows. Compute the value for the current runner before any
# array initialization so the EXPECTED entry below can reference it.
case "$(uname -s)" in
    Darwin)
        CLINE_MCP_PATH='~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json'
        ;;
    Linux)
        CLINE_MCP_PATH='~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json'
        ;;
    *)
        CLINE_MCP_PATH='${APPDATA}/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json'
        ;;
esac

# Expected registry canonical paths. Format: "ide|object|expected".
# object ∈ global|project|project-skills|mcp|project-mcp|project-config|config|rules
EXPECTED=(
    "antigravity|global|~/.gemini/antigravity/skills"
    "antigravity|project|.agents"
    "antigravity|project-skills|.agents/skills"
    "antigravity|rules|.agents/rules"
    "antigravity|mcp|~/.gemini/config/mcp_config.json"
    "antigravity|project-mcp|.agents/mcp_config.json"
    "kimiai|global|~/.kimi-code/skills"
    "kimiai|project-skills|.kimi-code/skills"
    "kimiai|rules|AGENTS.md"
    "kimiai|config|~/.kimi-code/config.toml"
    "kimiai|mcp|~/.kimi-code/mcp.json"
    "kimiai|project-mcp|.kimi-code/mcp.json"
    "copilot|global|~/.copilot/skills"
    "copilot|project-skills|.github/skills"
    "copilot|rules|.github/copilot-instructions.md"
    "copilot|mcp|~/.copilot/mcp-config.json"
    "copilot|project-mcp|.mcp.json"
    "codex|global|~/.agents/skills"
    "codex|project-skills|.agents/skills"
    "codex|mcp|~/.codex/config.toml"
    "codex|project-mcp|.codex/config.toml"
    "codex|project-config|.codex/config.toml"
    "codex|config|~/.codex/config.toml"
    "workbuddy|global|"
    "workbuddy|project-skills|"
    "workbuddy|mcp|~/.workbuddy/mcp.json"
    "workbuddy|project-mcp|.workbuddy/mcp.json"
    "workbuddy|config|"
    "claude|global|~/.claude/skills"
    "claude|project-skills|.claude/skills"
    "claude|rules|CLAUDE.md"
    "claude|mcp|~/.claude.json"
    "claude|project-mcp|.mcp.json"
    "claude|project-config|.claude/settings.json"
    "claude|config|~/.claude/settings.json"
    "claude-desktop|mcp|"
    "claude-desktop|config|"
    "amazon-q|global|"
    "amazon-q|project|.amazonq"
    "amazon-q|project-skills|"
    "amazon-q|rules|.amazonq/rules"
    "amazon-q|mcp|"
    "amazon-q|project-mcp|.amazonq/default.json"
    "amazon-q|config|"
    "gemini-cli|global|~/.gemini/skills"
    "gemini-cli|project|.gemini"
    "gemini-cli|project-skills|.gemini/skills"
    "gemini-cli|rules|GEMINI.md"
    "gemini-cli|mcp|~/.gemini/settings.json"
    "gemini-cli|project-mcp|.gemini/settings.json"
    "gemini-cli|project-config|.gemini/settings.json"
    "gemini-cli|config|~/.gemini/settings.json"
    "openclaw|global|~/.openclaw/skills"
    "openclaw|project-skills|skills"
    "openclaw|rules|AGENTS.md"
    "openclaw|mcp|~/.openclaw/openclaw.json"
    "openclaw|config|~/.openclaw/openclaw.json"
    "goose-cli|global|~/.agents/skills"
    "goose-cli|project|.goose"
    "goose-cli|project-skills|.agents/skills"
    "goose-cli|rules|.goosehints"
    "goose-cli|mcp|~/.config/goose/config.yaml"
    "goose-cli|project-mcp|"
    "goose-cli|project-config|"
    "goose-cli|config|~/.config/goose/config.yaml"
    "jetbrains|global|~/.junie/skills"
    "jetbrains|project-skills|.junie/skills"
    "jetbrains|rules|.junie/AGENTS.md"
    "jetbrains|mcp|~/.junie/mcp/mcp.json"
    "jetbrains|project-mcp|.junie/mcp/mcp.json"
    "jetbrains|config|"
    "opencode|global|~/.config/opencode/skills"
    "opencode|project-skills|.opencode/skills"
    "opencode|rules|AGENTS.md"
    "opencode|mcp|~/.config/opencode/opencode.json"
    "opencode|project-mcp|opencode.json"
    "opencode|project-config|opencode.json"
    "opencode|config|~/.config/opencode/opencode.json"
    "continue|global|"
    "continue|project|.continue"
    "continue|project-skills|"
    "continue|rules|.continue/rules"
    "continue|mcp|~/.continue/config.yaml"
    "continue|project-mcp|.continue/mcpServers"
    "continue|config|~/.continue/config.yaml"
    "trae|global|~/.trae/skills"
    "trae|project|.trae"
    "trae|project-skills|.trae/skills"
    "trae|project-mcp|.trae/mcp.json"
    "trae|mcp|"
    "trae|rules|.trae/rules"
    "trae|config|"
    "trae-cn|global|~/.trae-cn/skills"
    "trae-cn|project|.trae"
    "trae-cn|project-skills|.trae/skills"
    "trae-cn|rules|.trae/rules"
    "trae-cn|project-mcp|.trae/mcp.json"
    "trae-cn|mcp|"
    "trae-cn|config|"
    "vscode|global|~/.copilot/skills"
    "vscode|project|.vscode"
    "vscode|project-skills|.github/skills"
    "vscode|rules|.github/copilot-instructions.md"
    "vscode|project-mcp|.vscode/mcp.json"
    "vscode|mcp|"
    "vscode|config|"
    "zed|global|~/.agents/skills"
    "zed|project-skills|.agents/skills"
    "zed|rules|AGENTS.md"
    "zed|mcp|~/.config/zed/settings.json"
    "zed|project-mcp|.zed/settings.json"
    "zed|config|"
    "cline|global|~/.cline/skills"
    "cline|project|"
    "cline|project-skills|.cline/skills"
    "cline|rules|.clinerules"
    "cline|mcp|${CLINE_MCP_PATH}"
    "cline|config|"
    "cody|global|"
    "cody|project|"
    "cody|project-skills|"
    "cody|rules|"
    "cody|mcp|"
    "cody|project-mcp|"
    "cody|project-config|"
    "cody|config|"
    "codeium|global|"
    "codeium|project|"
    "codeium|project-skills|"
    "codeium|rules|"
    "codeium|mcp|"
    "codeium|project-mcp|"
    "codeium|project-config|"
    "codeium|config|"
    "supermaven|global|"
    "supermaven|project|"
    "supermaven|project-skills|"
    "supermaven|rules|"
    "supermaven|mcp|"
    "supermaven|project-mcp|"
    "supermaven|project-config|"
    "supermaven|config|"
    "tabnine|global|"
    "tabnine|project-skills|"
    "tabnine|rules|.tabnine/guidelines"
    "tabnine|mcp|~/.tabnine/mcp_servers.json"
    "tabnine|project-mcp|.tabnine/mcp_servers.json"
    "tabnine|config|"
    "replit|global|"
    "replit|project|.replit"
    "replit|project-skills|.agents/skills"
    "replit|rules|replit.md"
    "replit|mcp|"
    "replit|project-mcp|"
    "replit|project-config|.replit"
    "replit|config|"
    "pearai|global|"
    "pearai|project|"
    "pearai|project-skills|"
    "pearai|rules|"
    "pearai|mcp|"
    "pearai|project-mcp|"
    "pearai|project-config|"
    "pearai|config|"
    "pieces|global|"
    "pieces|project|"
    "pieces|project-skills|"
    "pieces|rules|"
    "pieces|mcp|"
    "pieces|project-mcp|"
    "pieces|project-config|"
    "pieces|config|"
    "blackbox|global|"
    "blackbox|project|.blackbox"
    "blackbox|project-skills|.blackbox/skills"
    "blackbox|rules|"
    "blackbox|mcp|"
    "blackbox|project-mcp|"
    "blackbox|project-config|"
    "blackbox|config|"
    "kilocode|global|~/.kilo/skills"
    "kilocode|project-skills|.kilo/skills"
    "kilocode|rules|AGENTS.md"
    "kilocode|mcp|~/.config/kilo/kilo.jsonc"
    "kilocode|project-mcp|.kilo/kilo.jsonc"
    "kilocode|project-config|.kilo/kilo.jsonc"
    "kilocode|config|~/.config/kilo/kilo.jsonc"
    "kiro|global|~/.kiro/skills"
    "kiro|project-skills|.kiro/skills"
    "kiro|rules|"
    "kiro|mcp|~/.kiro/settings/mcp.json"
    "kiro|project-mcp|.kiro/settings/mcp.json"
    "kiro|config|"
    "augment-code|global|~/.augment/skills"
    "augment-code|project-skills|.augment/skills"
    "augment-code|rules|"
    "augment-code|mcp|~/.augment/settings.json"
    "augment-code|project-mcp|.augment/settings.json"
    "augment-code|project-config|.augment/settings.json"
    "augment-code|config|~/.augment/settings.json"
    "void-editor|global|"
    "void-editor|project-skills|"
    "void-editor|rules|.voidrules"
    "void-editor|mcp|~/.void-editor/mcp.json"
    "void-editor|project-mcp|.vscode/mcp.json"
    "void-editor|config|"
    "baidu-comate|global|~/.comate/skills"
    "baidu-comate|project-skills|.comate/skills"
    "baidu-comate|rules|"
    "baidu-comate|mcp|~/.comate/mcp.json"
    "baidu-comate|project-mcp|.comate/mcp.json"
    "baidu-comate|config|"
    "tencent-codebuddy|global|~/.codebuddy/skills"
    "tencent-codebuddy|project-skills|.codebuddy/skills"
    "tencent-codebuddy|rules|CODEBUDDY.md"
    "tencent-codebuddy|mcp|~/.codebuddy/.mcp.json"
    "tencent-codebuddy|project-mcp|.mcp.json"
    "tencent-codebuddy|project-config|.codebuddy/settings.json"
    "tencent-codebuddy|config|~/.codebuddy/settings.json"
    "zcode|global|~/.zcode/skills"
    "zcode|project-skills|"
    "zcode|rules|AGENTS.md"
    "zcode|mcp|~/.zcode/cli/config.json"
    "zcode|project-mcp|.zcode/config.json"
    "zcode|project-config|.zcode/config.json"
    "zcode|config|~/.zcode/cli/config.json"
)

# Native GNU Emacs has no generic skills/rules/MCP/config/project path. Init
# files and .dir-locals.el are Emacs Lisp and require manual adaptation.
EMACS_UNSUPPORTED=(global project project-skills rules mcp project-mcp project-config config)

failures=0
checks=0

echo "========================================"
echo "Verifying IDE config paths (real validation)"
echo "========================================"
echo ""

for entry in "${EXPECTED[@]}"; do
    ide="${entry%%|*}"
    rest="${entry#*|}"
    object="${rest%%|*}"
    expected="${rest#*|}"

    checks=$((checks + 1))

    actual="$(bash "$MIGRATION_SCRIPT" --print-path "$ide" "$object" 2>/dev/null)"
    rc=$?

    if [[ -z "$expected" ]]; then
        if [[ -z "$actual" ]]; then
            echo "PASS: ${ide}/${object} -> (unsupported/empty)"
        else
            echo "FAIL: ${ide}/${object} - expected empty, got: ${actual}"
            failures=$((failures + 1))
        fi
        continue
    fi

    if [[ $rc -ne 0 ]]; then
        echo "FAIL: ${ide}/${object} - script exited non-zero (cannot resolve path)"
        failures=$((failures + 1))
        continue
    fi

    if [[ "$actual" == "$expected" ]]; then
        echo "PASS: ${ide}/${object} -> ${actual}"
    else
        echo "FAIL: ${ide}/${object}"
        echo "  expected: ${expected}"
        echo "  actual:   ${actual}"
        failures=$((failures + 1))
    fi
done

for object in "${EMACS_UNSUPPORTED[@]}"; do
    checks=$((checks + 1))
    actual="$(bash "$MIGRATION_SCRIPT" --print-path emacs "$object" 2>/dev/null || true)"
    if [[ -z "$actual" ]]; then
        echo "PASS: emacs/${object} -> (unsupported/empty)"
    else
        echo "FAIL: emacs/${object} - expected unsupported/empty, got: ${actual}"
        failures=$((failures + 1))
    fi
done

echo ""
echo "========================================"
if [[ $failures -eq 0 ]]; then
    echo "PASS: all ${checks} checks match the registry"
    echo "========================================"
    exit 0
else
    echo "FAIL: ${failures}/${checks} checks mismatched"
    echo "========================================"
    exit 1
fi
