---
name: agent-skills-setup
description: Configure and manage MCP servers in AI-powered IDEs (Claude Code, Cursor, JetBrains, Amazon Q, Gemini, Codex, Trae, VS Code Copilot, Windsurf, Zed, etc.)
triggers:
  - setup mcp server
  - configure claude code mcp
  - cursor mcp config
  - install mcp in ide
  - AI IDE mcp setup
  - windsurf mcp
  - zed mcp setup
  - submodule studio mcp
  ---

# MCP Server Setup for AI IDEs

Configure Model Context Protocol (MCP) servers across popular AI-powered IDEs.

## Supported IDEs

| IDE | MCP Support | MCP Config Path | Last Updated |
|-----|-------------|-----------------|--------------|
| [Claude Code](#claude-code) | Full | `~/.claude.json` | 2025-03 |
| [Cursor](#cursor) | Full | `~/.cursor/mcp.json` | 2025-03 |
| [JetBrains AI](#jetbrains-ai) | Full | `~/.jetbrains.mcp.json` | 2025-03 |
| [Amazon Q](#amazon-q) | Full | `.amazonq/mcp.json` | 2025-03 |
| [Gemini CLI](#gemini-cli) | Full | `~/.gemini/settings.json` | 2025-03 |
| [Codex](#codex) | Full | `~/.codex/settings.json` | 2025-03 |
| [Trae](#trae) | Full | `.trae/mcp.json` | 2025-03 |
| [VS Code + Copilot](#vs-code-copilot) | Partial | `.vscode/mcp.json` | 2025-03 |
| [Windsurf](#windsurf) | Full | `.windsurf/mcp.json` | 2025-03 |
| [Zed](#zed) | Full | `~/.config/zed/mcp.json` | 2025-03 |
| [Sublime Merge](#sublime-merge) | Full | `Packages/User/mcp.json` | 2025-03 |
| [Nova](#nova) | Full | `~/Library/Application Support/Nova/extensions/mcp-servers.json` | 2025-03 |
| [BBEdit](#bbedit) | Partial | Via extension | 2025-03 |
| [Helix](#helix) | Full | `~/.config/helix/MCP.toml` | 2025-03 |
| [Lapce](#lapce) | Full | `~/.config/lapce/mcp.toml` | 2025-03 |
| [Forge](#forge) | Full | `.forge/mcp.json` | 2025-03 |
| [Zulip](#zulip) | Partial | Via webhook | 2025-03 |

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

## Claude Code

**Path:** `~/.claude.json`

### macOS / Linux

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

### Windows

```powershell
# Add to %USERPROFILE%\.claude.json
```

### Verify

```bash
claude mcp list
```

---

## Cursor

**Path:** `~/.cursor/mcp.json`

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

### Setup

```bash
mkdir -p ~/.cursor
# Edit ~/.cursor/mcp.json
```

---

## JetBrains AI

**Path:** `~/.jetbrains.mcp.json`

### Supported Products (2025.1+)

- IntelliJ IDEA
- PyCharm
- WebStorm
- PhpStorm
- RubyMine
- GoLand
- CLion
- Rider
- DataSpell
- DataGrip

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

## Amazon Q

**Path:** `.amazonq/mcp.json` (project-level)

### CLI (Standalone)

Released April 2025 - supports MCP via `~/.aws/amazonq/mcp.json`.

### IDE Extension (June 2025)

Create MCP config in project root:

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

## Gemini CLI

**Path:** `~/.gemini/settings.json`

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

## Codex

**Path:** `~/.codex/settings.json`

### Status

Reactivated and improved in 2025.

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

---

## VS Code + Copilot

**Path:** `.vscode/mcp.json`

### Native Support

VS Code Copilot has limited native MCP support. Use extensions or Continue plugin.

### Option 1: Continue Extension (Recommended)

1. Install Continue extension
2. Edit `.continue/config.py`:

```python
from continuedev.src.main import *

config = ContinueConfig(
    mcp_servers=[
        {
            "name": "server-name",
            "command": "uvx",
            "args": ["mcp-server-package"]
        }
    ]
)
```

### Option 2: Cline Extension

1. Install Cline extension
2. Configure in Cline Settings > MCP Servers

### Option 3: Native MCP (Insiders)

VS Code Insiders 1.99+ supports MCP natively:

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

### Setup

```bash
mkdir -p ~/.windsurf
# Edit ~/.windsurf/mcp.json
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

### Setup

```bash
mkdir -p ~/.config/zed
# Edit ~/.config/zed/mcp.json
```

---

## Sublime Merge

**Path:** `Packages/User/mcp.json`

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

### Setup

1. Open Sublime Merge
2. Preferences > Browse Packages
3. Create `User/mcp.json`

---

## Nova

**Path:** `~/Library/Application Support/Nova/extensions/mcp-servers.json`

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

## BBEdit

**MCP Support:** Partial (via extension)

### Using Extension

1. Install BBEdit MCP extension
2. Configure via extension preferences

---

## Helix

**Path:** `~/.config/helix/MCP.toml`

### Config Format

```toml
[server.server-name]
command = "uvx"
args = ["mcp-server-package"]
```

---

## Lapce

**Path:** `~/.config/lapce/mcp.toml`

### Config Format

```toml
[server.server-name]
command = "uvx"
args = ["mcp-server-package"]
```

---

## Forge

**Path:** `.forge/mcp.json`

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

## Zulip

**MCP Support:** Partial (via webhook)

### Using Webhook

Configure MCP server as Zulip webhook integration.

---

## Troubleshooting

### Server Not Starting

1. Check config syntax (JSON/ TOML)
2. Verify `uvx` or `npx` is installed
3. Test command manually: `uvx mcp-server-package`

### Permission Denied

```bash
chmod +x /path/to/mcp-server
```

### Path Issues

Use absolute paths in config.

---

## See Also

- [Publishing Skills](publishing.md)
- [IDE Migration Guide](ide-migration.md)
- [MCP Official Docs](https://modelcontextprotocol.io)
