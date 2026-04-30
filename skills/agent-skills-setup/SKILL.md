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
| [Trae](#trae) | ByteDance | Full | `.trae/mcp.json` | 2025-03 |
| [Trae CN](#trae-cn) | ByteDance | Full | `.trae/mcp.json` | 2025-03 |
| [antigravity](#antigravity) | **Google** | Full | `.antigravity/mcp.json` | 2025-03 |
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

uvx is faster and safer than npx:

```bash
# Install uv if needed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Run MCP servers with uvx
uvx mcp-server-package --key value
```

### Alternative: npx

```bash
npx -y mcp-server-package --key value
```

### Python venv

```bash
python -m venv .venv
source .venv/bin/activate
pip install mcp-server-package
```

---

## Trae

**Developer:** ByteDance
**Path:** `.trae/mcp.json`

### Config Format

```json
{
  "mcpServers": {
    "server-name": {
      "command": "uvx",
      "args": ["mcp-server-package"]
    }
  }
}
```

### Trae v1.3.0+

Added Agent Mode with enhanced MCP support.

---

## Trae CN

**Developer:** ByteDance
**Path:** `.trae/mcp.json` (same as Trae)

### 区别

| 特性 | Trae | Trae CN |
|------|------|---------|
| 语言 | English | 简体中文 |
| 默认模型 | Claude/GPT | Claude/通义/DeepSeek |
| 区域 | 全球 | 中国大陆 |
| 模型来源 | OpenAI/Anthropic | OpenAI/阿里/DeepSeek |
| MCP配置 | 相同 | 相同 |

---

## antigravity

**Developer:** Google
**Path:** `.antigravity/mcp.json`

### 简介

Google Antigravity 是 Google 推出的 AI 优先 IDE，基于 Gemini 大模型，支持 MCP 协议扩展。

### Config Format

```json
{
  "mcpServers": {
    "server-name": {
      "command": "uvx",
      "args": ["mcp-server-package"]
    }
  }
}
```

### Example: GitHub MCP

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

### antigravity 特性

| 特性 | 说明 |
|------|------|
| 主模型 | Gemini 3.1 Pro |
| Agent Mode | Agent Manager |
| 代码补全 | Tab autocomplete |
| 命令 | Natural language code commands |

---

## Windsurf

**Developer:** Codeium
**Path:** `.windsurf/mcp.json`

---

## Zed

**Developer:** Zed
**Path:** `~/.config/zed/mcp.json`

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
**Path:** `~/.jetbrains.mcp.json`

Supported: IntelliJ IDEA, PyCharm, WebStorm, PhpStorm, RubyMine, GoLand, CLion, Rider, DataSpell, DataGrip

---

## Gemini CLI

**Developer:** Google
**Path:** `~/.gemini/settings.json`

---

## Codex

**Developer:** OpenAI
**Path:** `~/.codex/settings.json`

---

## Helix

**Developer:** Helix
**Path:** `~/.config/helix/MCP.toml`

```toml
[server.server-name]
command = "uvx"
args = ["mcp-server-package"]
```

---

## Lapce

**Developer:** Lapce
**Path:** `~/.config/lapce/mcp.toml`

---

## Sublime Merge

**Developer:** Sublime HQ
**Path:** `Packages/User/mcp.json`

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

## Zulip

**Developer:** Zulip
Via webhook integration.

---

## Troubleshooting

### Server Not Starting

1. Check config syntax (JSON/TOML)
2. Verify `uvx` or `npx` is installed
3. Test command manually: `uvx mcp-server-package`

### Permission Denied

```bash
chmod +x /path/to/mcp-server
```

---

## See Also

- [Publishing Skills](publishing.md)
- [IDE Migration Guide](ide-migration.md)
- [MCP Official Docs](https://modelcontextprotocol.io)
