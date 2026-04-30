# Helix MCP Setup

Configure MCP servers in Helix Editor.

## Config Path

`~/.config/helix/MCP.toml`

## Config Format

```toml
[server.server-name]
command = "uvx"
args = ["mcp-server-package"]

# With environment variables
[server.github]
command = "uvx"
args = ["@modelcontextprotocol/server-github"]
env = { GITHUB_PERSONAL_ACCESS_TOKEN = "your-token" }
```

## Setup Steps

1. Create config directory:
```bash
mkdir -p ~/.config/helix
```

2. Create config file:
```bash
nano ~/.config/helix/MCP.toml
```

3. Restart Helix

## Example: Complete Config

```toml
[server.github]
command = "uvx"
args = ["@modelcontextprotocol/server-github"]
env = { GITHUB_PERSONAL_ACCESS_TOKEN = "ghp_xxx" }

[server.filesystem]
command = "uvx"
args = ["@modelcontextprotocol/server-filesystem", "/home/user/projects"]
```

## Helix Features

- Terminal-based modal editor
- Multiple cursors
- Tree-sitter syntax
- LSP support
- MCP for AI extensions
