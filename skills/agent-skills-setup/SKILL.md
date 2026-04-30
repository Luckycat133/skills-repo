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

| IDE | Type | MCP Support | Config Path | Last Updated |
|-----|------|-------------|-------------|--------------|
| [Claude Code](#claude-code) | CLI | Full | `~/.claude.json` | 2025-03 |
| [Cursor](#cursor) | Desktop | Full | `~/.cursor/mcp.json` | 2025-03 |
| [JetBrains AI](#jetbrains-ai) | Desktop | Full | `~/.jetbrains.mcp.json` | 2025-03 |
| [Trae](#trae) | Desktop | Full | `.trae/mcp.json` | 2025-03 |
| [Trae CN](#trae-cn) | Desktop | Full | `.trae/mcp.json` | 2025-03 |
| [antigravity](#antigravity) | Desktop | Full | `.antigravity/mcp.json` | 2025-03 |
| [Windsurf](#windsurf) | Desktop | Full | `.windsurf/mcp.json` | 2025-03 |
| [Zed](#zed) | Desktop | Full | `~/.config/zed/mcp.json` | 2025-03 |
| [Helix](#helix) | Terminal | Full | `~/.config/helix/MCP.toml` | 2025-03 |
| [Lapce](#lapce) | Desktop | Full | `~/.config/lapce/mcp.toml` | 2025-03 |

### Cloud & Web IDEs

| IDE | Type | MCP Support | Config Path | Last Updated |
|-----|------|-------------|-------------|--------------|
| [GitHub Codespaces](#github-codespaces) | Cloud | Full | `.devcontainer.json` | 2025-03 |
| [StackBlitz](#stackblitz) | Cloud | Partial | Via extension | 2025-03 |
| [Gitpod](#gitpod) | Cloud | Full | `.gitpod.yml` | 2025-03 |
| [Replit](#replit) | Cloud | Full | Via secrets | 2025-03 |
| [CodeSandbox](#codesandbox) | Cloud | Partial | Via extension | 2025-03 |

### Enterprise & Team IDEs

| IDE | Type | MCP Support | Config Path | Last Updated |
|-----|------|-------------|-------------|--------------|
| [VS Code + Copilot](#vs-code-copilot) | Desktop | Partial | `.vscode/mcp.json` | 2025-03 |
| [Amazon Q](#amazon-q) | Desktop | Full | `.amazonq/mcp.json` | 2025-03 |
| [Gemini CLI](#gemini-cli) | CLI | Full | `~/.gemini/settings.json` | 2025-03 |
| [Codex](#codex) | CLI | Full | `~/.codex/settings.json` | 2025-03 |

### Legacy & Specialized

| IDE | Type | MCP Support | Config Path | Last Updated |
|-----|------|-------------|-------------|--------------|
| [Sublime Merge](#sublime-merge) | Git UI | Full | `Packages/User/mcp.json` | 2025-03 |
| [Nova](#nova) | Desktop (macOS) | Full | Nova extensions path | 2025-03 |
| [Forge](#forge) | Desktop | Full | `.forge/mcp.json` | 2025-03 |
| [BBEdit](#bbedit) | Text Editor | Partial | Via extension | 2025-03 |
| [Zulip](#zulip) | Chat | Partial | Via webhook | 2025-03 |

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

### Setup

```bash
mkdir -p .trae
nano .trae/mcp.json
```

---

## Trae CN

**Path:** `.trae/mcp.json` (same as Trae)

### 区别

| 特性 | Trae | Trae CN |
|------|------|---------|
| 语言 | English | 简体中文 |
| 默认模型 | Claude/GPT | Claude/通义/DeepSeek |
| 区域 | 全球 | 中国大陆 |
| 模型来源 | OpenAI/Anthropic | OpenAI/阿里/DeepSeek |
| MCP配置 | 相同 | 相同 |

### Config Format

```json
{
  "mcpServers": {
    "github": {
      "command": "uvx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token"
      }
    },
    "filesystem": {
      "command": "uvx",
      "args": ["@modelcontextprotocol/server-filesystem", "/path/to/project"]
    }
  }
}
```

### Setup

1. Create `.trae` folder in project root:
```bash
mkdir -p .trae
```

2. Create MCP config:
```bash
nano .trae/mcp.json
```

3. Restart Trae CN

### 内置模型 (Trae CN)

- Claude 3.5 Sonnet
- GPT-4o
- 通义千问 (Qwen)
- DeepSeek Chat
- Gemini Pro

---

## antigravity

**Path:** `.antigravity/mcp.json`

### 简介

antigravity 是字节跳动推出的 AI 代码编辑器，基于 IntelliJ 平台，支持 MCP 协议。

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

### Setup

1. Create config directory:
```bash
mkdir -p .antigravity
```

2. Create MCP config:
```bash
nano .antigravity/mcp.json
```

3. Restart antigravity

### 特性

- 基于 IntelliJ 平台
- 深度集成豆包大模型
- 支持 Claude/GPT 等外部模型
- MCP 协议支持
- 智能代码补全
- 代码审查

---

## Windsurf

**Path:** `.windsurf/mcp.json`

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

---

## Zed

**Path:** `~/.config/zed/mcp.json`

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

---

## Claude Code

**Path:** `~/.claude.json`

```bash
cat >> ~/.claude.json << 'EOF'
{
  "mcpServers": {
    "server-name": {
      "command": "uvx",
      "args": ["mcp-server-package", "--key", "value"]
    }
  }
}
EOF
```

---

## Cursor

**Path:** `~/.cursor/mcp.json`

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

---

## JetBrains AI

**Path:** `~/.jetbrains.mcp.json`

Supported: IntelliJ IDEA, PyCharm, WebStorm, PhpStorm, RubyMine, GoLand, CLion, Rider, DataSpell, DataGrip

---

## Gemini CLI

**Path:** `~/.gemini/settings.json`

---

## Codex

**Path:** `~/.codex/settings.json`

---

## Helix

**Path:** `~/.config/helix/MCP.toml`

```toml
[server.server-name]
command = "uvx"
args = ["mcp-server-package"]
```

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

```json
{
  "features": {
    "ghcr.io/microsoft/vscode/devcontainers/features/mcp": {}
  }
}
```

---

## StackBlitz

Partial - via WebContainer extension.

---

## Gitpod

**Path:** `.gitpod.yml`

```yaml
tasks:
  - init: npx -y @modelcontextprotocol/server-* && exit
```

---

## Replit

Configure via Secrets panel.

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

## Zulip

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
