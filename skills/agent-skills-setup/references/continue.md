# Continue Configuration

Configure Continue.dev with MCP servers for enhanced AI coding assistance.

## Configuration File

Continue uses `config.json` (or `config.yaml`) in your workspace root.

**Location**: `.continue/config.json`

```json
{
  "models": [...],
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

## Alternative: JSON MCP Files

You can also place JSON MCP config files in:

```
.continue/mcpServers/mcp.json
```

This allows sharing MCP configs with other tools (Claude Desktop, Cursor, Cline).

## Quick Setup

1. Install Continue extension in VS Code or JetBrains
2. Create `.continue/config.json` in your project root
3. Add MCP servers to the `mcpServers` section
4. Restart Continue

## Verification

```bash
# Check config is loaded
# In Continue chat, type: /config
```
