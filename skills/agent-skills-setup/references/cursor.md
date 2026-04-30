# Cursor Configuration

Configure MCP servers in Cursor AI.

## Configuration File

**Location**: `~/.cursor/mcp.json`

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

## Setup Methods

### Via UI (Recommended)

1. Open Cursor Settings
2. Navigate to Tools & MCP
3. Click "New MCP Server"
4. Enter server configuration

### Via Config File

Create/edit `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "uvx",
      "args": ["--from", "package-name", "server-command"]
    }
  }
}
```

## Project-Level MCP

Cursor also supports project-level MCP in `.cursor/mcp.json`.

## Execution Methods

| Method | Use Case |
|--------|----------|
| `npx` | Node.js servers |
| `uvx` | Python servers (recommended) |
| Docker | Production security |

## Verification

1. Restart Cursor
2. Check MCP servers in Settings > Tools & MCP
3. Test in AI chat
