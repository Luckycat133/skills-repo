# Zed MCP Setup

Configure MCP servers in Zed Editor.

## Config Path

`~/.config/zed/settings.json`

**Note:** Zed uses the same `settings.json` for MCP configuration, not a separate `mcp.json` file.

## Config Format

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

## Example: File System MCP

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "uvx",
      "args": ["@modelcontextprotocol/server-filesystem", "/path/to/allowed/dir"]
    }
  }
}
```

## Setup Steps

1. Create config directory:
```bash
mkdir -p ~/.config/zed
```

2. Create/Edit settings file:
```bash
nano ~/.config/zed/settings.json
```

3. Reload Zed window

## Zed AI Features

Zed includes built-in AI features. MCP support allows extending with custom servers.

## Verification

Check MCP servers in Zed Agent Panel settings view.

## Troubleshooting

- Config location: Linux/macOS use `~/.config`, Windows uses `%APPDATA%`
- Ensure valid JSON syntax
- Restart Zed after config changes
