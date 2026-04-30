# Forge MCP Setup

Configure MCP servers in Forge Editor.

## Config Path

`.forge/mcp.json` (project-level)

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
mkdir -p .forge
```

2. Create config file:
```bash
nano .forge/mcp.json
```

3. Restart Forge

## Project-Level Config

Forge uses project-level MCP configuration, making it easy to have different servers per project.
