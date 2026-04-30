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
| [Claude Code](#claude-code) | Anthropic | Full | `~/.claude.json` | 2025-03 |
| [Cursor](#cursor) | Cursor | Full | `~/.cursor/mcp.json` | 2025-03 |
| [JetBrains AI](#jetbrains-ai) | JetBrains | Full | `~/.jetbrains.mcp.json` | 2025-03 |
| [Trae](#trae) | ByteDance | Full | `~/.cursor/mcp.json` (全局) / `.trae/mcp.json` (项目) | 2025-03 |
| [Trae CN](#trae-cn) | ByteDance | Full | `~/.cursor/mcp.json` (全局) / `.trae/mcp.json` (项目) | 2025-03 |
| [antigravity](#antigravity) | Google | Full | `~/.gemini/antigravity/mcp_config.json` | 2025-03 |
| [Windsurf](#windsurf) | Codeium | Full | `.windsurf/mcp.json` | 2025-03 |
| [Zed](#zed) | Zed | Full | `~/.config/zed/mcp.json` | 2025-03 |
| [Helix](#helix) | Helix | Full | `~/.config/helix/MCP.toml` | 2025-03 |
| [Lapce](#lapce) | Lapce | Full | `~/.config/lapce/mcp.toml` | 2025-03 |

### Cloud & Web IDEs

| IDE | Developer | MCP Support | Config Path | Last Updated |
|-----|-----------|-------------|-------------|--------------|
| [GitHub Codespaces](#github-codespaces) | GitHub | Full | `.devcontainer.json` | 2025-03 |
| [StackBlitz](#stackblitz) | StackBlitz | Partial | Via extension | 2025-03 |
| [Gitpod](#gitpod) | Gitpod | Full | `.gitpod.yml` | 2025-03 |
| [Replit](#replit) | Replit | Full | Via secrets | 2025-03 |
| [CodeSandbox](#codesandbox) | CodeSandbox | Partial | Via extension | 2025-03 |

### Enterprise & Team IDEs

| IDE | Developer | MCP Support | Config Path | Last Updated |
|-----|-----------|-------------|-------------|--------------|
| [VS Code + Copilot](#vs-code-copilot) | Microsoft | Partial | `.vscode/mcp.json` | 2025-03 |
| [Amazon Q](#amazon-q) | AWS | Full | `.amazonq/mcp.json` | 2025-03 |
| [Gemini CLI](#gemini-cli) | Google | Full | `~/.gemini/settings.json` | 2025-03 |
| [Codex](#codex) | OpenAI | Full | `~/.codex/settings.json` | 2025-03 |

### Legacy & Specialized

| IDE | Developer | MCP Support | Config Path | Last Updated |
|-----|-----------|-------------|-------------|--------------|
| [Sublime Merge](#sublime-merge) | Sublime HQ | Full | `Packages/User/mcp.json` | 2025-03 |
| [Nova](#nova) | Panic | Full | Nova extensions path | 2025-03 |
| [Forge](#forge) | Forge | Full | `.forge/mcp.json` | 2025-03 |
| [BBEdit](#bbedit) | Bare Bones | Partial | Via extension | 2025-03 |
| [Zulip](#zulip) | Zulip | Partial | Via webhook | 2025-03 |

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

## Claude Code

**Path:** `~/.claude.json`

---

## Cursor

**Path:** `~/.cursor/mcp.json`

---

## JetBrains AI

**Path:** `~/.jetbrains.mcp.json`

---

## Windsurf

**Path:** `.windsurf/mcp.json`

---

## Zed

**Path:** `~/.config/zed/mcp.json`

---

## Helix

**Path:** `~/.config/helix/MCP.toml`

---

## Lapce

**Path:** `~/.config/lapce/mcp.toml`

---

## Sublime Merge

**Path:** `Packages/User/mcp.json`

---

## Nova

**Path:** `~/Library/Application Support/Nova/extensions/mcp-servers.json`

---

## Forge

**Path:** `.forge/mcp.json`

---

## BBEdit

Partial support via extension.

---

## GitHub Codespaces

**Path:** `.devcontainer.json`

---

## StackBlitz

Partial - via WebContainer extension.

---

## Gitpod

**Path:** `.gitpod.yml`

---

## Replit

Configuration via Secrets panel.

---

## CodeSandbox

Partial - via extension.

---

## VS Code + Copilot

**Path:** `.vscode/mcp.json` (Insiders) or via Continue/Cline extensions.

---

## Amazon Q

**Path:** `.amazonq/mcp.json`

---

## Gemini CLI

**Path:** `~/.gemini/settings.json`

---

## Codex

**Path:** `~/.codex/settings.json`

---

## Zulip

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
