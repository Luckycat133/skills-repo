---
name: agent-skills-setup
description: Configure and manage MCP servers in AI-powered IDEs (Claude Code, Cursor, JetBrains, Amazon Q, Gemini, Codex, Trae, Trae CN, Windsurf, Zed, VS Code Copilot, antigravity, etc.)
triggers:
  - setup mcp server
  - configure claude code mcp
  - cursor mcp config
  - install mcp in ide
  - AI IDE mcp setup
  - windsurf mcp
  - zed mcp setup
  - trae mcp setup
  - antigravity mcp
  ---

# MCP Server Setup for AI IDEs

Configure Model Context Protocol (MCP) servers across popular AI-powered IDEs.

## Supported IDEs

### Primary Editors (CLI & Desktop)

| IDE | Developer | MCP Support | Config Path | Last Updated |
|-----|-----------|-------------|-------------|--------------|
| [Claude Code](#claude-code) | Anthropic | Full | `~/.claude.json` | 2025-04 |
| [Cursor](#cursor) | Cursor | Full | `~/.cursor/mcp.json` | 2025-04 |
| [JetBrains AI](#jetbrains-ai) | JetBrains | Full | GUI (Settings > Tools > AI Assistant > MCP) | 2025-04 |
| [Trae](#trae) | ByteDance | Full | `~/.cursor/mcp.json` (全局) / `.trae/mcp.json` (项目) | 2025-04 |
| [Trae CN](#trae-cn) | ByteDance | Full | `~/.cursor/mcp.json` (全局) / `.trae/mcp.json` (项目) | 2025-04 |
| [antigravity](#antigravity) | Google | Full | `~/.gemini/antigravity/mcp_config.json` | 2025-04 |
| [Windsurf](#windsurf) | Codeium | Full | `~/.codeium/windsurf/mcp_config.json` | 2025-04 |
| [Zed](#zed) | Zed | Full | `~/.config/zed/settings.json` | 2025-04 |
| [Helix](#helix) | Helix | Full | `~/.config/helix/MCP.toml` | 2025-04 |

### Cloud & Web IDEs

| IDE | Developer | MCP Support | Config Path | Last Updated |
|-----|-----------|-------------|-------------|--------------|
| [GitHub Codespaces](#github-codespaces) | GitHub | Full | `.devcontainer.json` | 2025-04 |
| [StackBlitz](#stackblitz) | StackBlitz | Partial | Via extension | 2025-04 |
| [Gitpod](#gitpod) | Gitpod | Full | `.gitpod.yml` | 2025-04 |
| [Replit](#replit) | Replit | Full | Via secrets | 2025-04 |
| [CodeSandbox](#codesandbox) | CodeSandbox | Partial | Via extension | 2025-04 |

### Enterprise & Team IDEs

| IDE | Developer | MCP Support | Config Path | Last Updated |
|-----|-----------|-------------|-------------|--------------|
| [VS Code + Copilot](#vs-code-copilot) | Microsoft | Partial | `.vscode/mcp.json` (Insiders) | 2025-04 |
| [Amazon Q](#amazon-q) | AWS | Full | `.amazonq/mcp.json` | 2025-04 |
| [Gemini CLI](#gemini-cli) | Google | Full | `~/.gemini/settings.json` | 2025-04 |
| [Codex](#codex) | OpenAI | Full | `~/.codex/config.toml` | 2025-04 |

### Specialized Tools

| Tool | Developer | MCP Support | Config Path | Last Updated |
|------|-----------|-------------|-------------|--------------|
| [Forge](#forge) | Forge | Full | `.forge/mcp.json` | 2025-04 |
| [Nova](#nova) | Panic | Full | `~/Library/Application Support/Nova/extensions/mcp-servers.json` | 2025-04 |
| [BBEdit](#bbedit) | Bare Bones | Partial | Via extension | 2025-04 |
| [Zulip](#zulip) | Zulip | Partial | Via webhook | 2025-04 |

### Legacy / No Native Support

| Tool | MCP Support | Notes |
|------|-------------|-------|
| [Lapce](#lapce) | ❌ No | Use Cursor/Zed instead |
| [Sublime Merge](#sublime-merge) | ❌ No | No plugin API |

## Installation Methods

### Recommended: uvx

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Run MCP servers with uvx
uvx mcp-server-package --key value
```

### Alternative: npx

```bash
npx -y mcp-server-package --key value
```

---

## Trae / Trae CN

**Developer:** ByteDance

| 配置类型 | 路径 |
|---------|------|
| 全局配置 | `~/.cursor/mcp.json` |
| 项目配置 | `.trae/mcp.json` |

```json
{
  "mcpServers": {
    "github": {
      "command": "uvx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token"
      }
    }
  }
}
```

---

## antigravity

**Developer:** Google

| 配置类型 | 路径 |
|---------|------|
| 全局配置 | `~/.gemini/antigravity/mcp_config.json` |

```json
{
  "mcpServers": {
    "github": {
      "command": "uvx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token"
      }
    }
  }
}
```

---

## Windsurf

**Developer:** Codeium

| OS | 路径 |
|----|------|
| macOS/Linux | `~/.codeium/windsurf/mcp_config.json` |
| Windows | `%USERPROFILE%\.codeium\windsurf\mcp_config.json` |

---

## Zed

**Developer:** Zed

**Path:** `~/.config/zed/settings.json`

---

## Claude Code

**Developer:** Anthropic
**Path:** `~/.claude.json`

---

## Cursor

**Developer:** Cursor
**Path:** `~/.cursor/mcp.json`

---

## JetBrains AI

**Developer:** JetBrains
**Method:** GUI 配置 (Settings > Tools > AI Assistant > MCP)

---

## Gemini CLI

**Developer:** Google
**Path:** `~/.gemini/settings.json`

---

## Codex

**Developer:** OpenAI
**Path:** `~/.codex/config.toml`

---

## Helix

**Developer:** Helix
**Path:** `~/.config/helix/MCP.toml`

---

## Nova

**Developer:** Panic
**Path:** `~/Library/Application Support/Nova/extensions/mcp-servers.json`

---

## Forge

**Developer:** Forge
**Path:** `.forge/mcp.json`

---

## BBEdit

**Developer:** Bare Bones
**Partial support** via extension.

---

## GitHub Codespaces

**Developer:** GitHub
**Path:** `.devcontainer.json`

---

## StackBlitz

**Developer:** StackBlitz
**Partial** - via WebContainer extension.

---

## Gitpod

**Developer:** Gitpod
**Path:** `.gitpod.yml`

---

## Replit

**Developer:** Replit
**Configuration:** Via Secrets panel.

---

## CodeSandbox

**Developer:** CodeSandbox
**Partial** - via extension.

---

## VS Code + Copilot

**Developer:** Microsoft
**Path:** `.vscode/mcp.json` (Insiders) or via Continue/Cline extensions.

---

## Amazon Q

**Developer:** AWS
**Path:** `.amazonq/mcp.json`

---

## Lapce

**MCP Support:** ❌ No native support

Use Cursor or Zed instead for MCP support.

---

## Sublime Merge

**MCP Support:** ❌ No native support

Sublime Merge has no plugin API.

---

## Zulip

**Developer:** Zulip
Via webhook integration.

---

## Troubleshooting

### Server Not Starting

1. Check config syntax
2. Verify `uvx` is installed
3. Test: `uvx mcp-server-package`

---

## See Also

- [Publishing Skills](publishing.md)
- [IDE Migration Guide](ide-migration.md)
- [MCP Official Docs](https://modelcontextprotocol.io)
