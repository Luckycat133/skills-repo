# Trae IDE Configuration

Configure MCP servers in Trae IDE.

## Requirements

- **Version**: 1.3.0+ (MCP support added)

## Configuration

### Via UI

1. Open Settings (gear icon)
2. Navigate to MCP
3. Click "Add" > "Manually Add"
4. Enter server configuration

### Config File

**Location**: `.trae/mcp.json` or global settings

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

## Features

- **Agents**: Create custom agents with MCP servers
- **Per-agent MCP**: Different agents can have different MCP configs
- **Project-level**: MCP configs per project

## Verification

1. Restart Trae
2. Check MCP servers in Settings
3. Test in AI chat
