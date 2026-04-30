# Windsurf MCP Setup

Configure MCP servers in Cascade IDE (Windsurf).

## Config Path

`~/.windsurf/mcp.json` or project-level `.windsurf/mcp.json`

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

## Example: GitHub MCP

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

## Setup Steps

1. Create config directory:
```bash
mkdir -p ~/.windsurf
```

2. Create/Edit config file:
```bash
nano ~/.windsurf/mcp.json
```

3. Restart Windsurf

## Verification

Check MCP servers in Windsurf settings panel.
