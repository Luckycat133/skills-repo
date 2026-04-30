# JetBrains AI Assistant Configuration

Configure MCP servers in JetBrains IDEs with AI Assistant.

## Requirements

- **IDE Version**: 2025.1 or later
- **AI Assistant**: Built-in or plugin

## Configuration

### Via Settings UI

1. Open Settings (Ctrl+Shift+Alt+/)
2. Navigate to Tools > MCP
3. Click "+" to add server
4. Configure name, command, transport

### Config File

**Location**: `~/.jetbrains.mcp.json`

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your_token"
      }
    }
  }
}
```

## Transport Options

| Transport | Description |
|-----------|-------------|
| stdio | Standard I/O (recommended) |
| SSE | Server-Sent Events |

## Version History

- **2025.2**: Built-in MCP support added
- **2025.1**: MCP plugin support introduced
- **Pre-2025.1**: No MCP support

## Verification

1. Restart JetBrains IDE
2. Check MCP servers in AI Assistant settings
3. Test tools in AI chat
