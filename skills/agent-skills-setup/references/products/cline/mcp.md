# Cline: MCP (`cline_mcp_settings.json`)

Parent: [cline.md](../cline.md)

## Path & Override (`CLINE_MCP_SETTINGS_PATH`)

- Default user MCP file: `~/.cline/data/settings/cline_mcp_settings.json`.
- Can be overridden via environment variable `CLINE_MCP_SETTINGS_PATH` (honored by `migrate_context.py`).

## JSON Schema & Exclusions

Root key is **`mcpServers`** (supports local Stdio and remote HTTP/SSE):

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      },
      "disabled": false
    }
  }
}
```

- **Security exclusions**: Extract/patch **only** `mcpServers`; strip `alwaysAllow` / `autoApprove` permission grants, and strictly exclude `~/.cline/data/tasks`, `state`, histories, cookies, and sqlite DBs.

Official sources: [config](https://docs.cline.bot/getting-started/config) · [mcp overview](https://docs.cline.bot/mcp/configuring-mcp-servers)
