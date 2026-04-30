# Lapce MCP Setup

Configure MCP servers in Lapce Editor.

## Config Path

`~/.config/lapce/mcp.toml`

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
mkdir -p ~/.config/lapce
```

2. Create config file:
```bash
nano ~/.config/lapce/mcp.toml
```

3. Restart Lapce

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

## Lapce Features

- Rust-based (fast)
- GPU rendering
- Remote development
- Built-in terminal
- LSP support
- MCP for AI extensions
