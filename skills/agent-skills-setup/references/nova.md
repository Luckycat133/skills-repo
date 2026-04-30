# Nova MCP Setup

Configure MCP servers in Nova Editor (Panic Inc.).

## Config Path

`~/Library/Application Support/Nova/extensions/mcp-servers.json`

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

## Setup Steps

1. Create config directory:
```bash
mkdir -p "~/Library/Application Support/Nova/extensions"
```

2. Create config file:
```bash
nano "~/Library/Application Support/Nova/extensions/mcp-servers.json"
```

3. Restart Nova

## macOS Only

Nova is macOS exclusive. If you're on Windows/Linux, use another editor.

## Extension-Based MCP

Nova also supports MCP through its extension system. Check Nova Extensions panel.
