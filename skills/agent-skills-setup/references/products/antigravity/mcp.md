# Antigravity: MCP (`mcp_config.json`)

Parent: [antigravity.md](../antigravity.md)

## File Locations

- Workspace MCP: `.agents/mcp_config.json`
- Global MCP: `~/.gemini/config/mcp_config.json` (legacy `~/.gemini/antigravity/mcp_config.json`)
- Plugin MCP: `plugins/<plugin_name>/mcp_config.json` (active only when parent plugin is enabled; receives `PLUGIN_ROOT` and `PLUGIN_DATA`)

## Canonical JSON Schema

Root key is **`mcpServers`**:

```json
{
  "mcpServers": {
    "sqlite-helper": {
      "command": "sqlite-mcp-server",
      "args": ["/path/to/database.db"],
      "env": {
        "DB_READONLY": "true"
      }
    },
    "remote-service": {
      "url": "https://mcp.mycompany.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      },
      "timeoutSeconds": 60,
      "enabledTools": ["search"],
      "disabledTools": []
    }
  }
}
```

## Transport & Translation Rules

- **Stdio**: Requires `command`; optional `args`, `cwd`, `env`.
- **Streamable HTTP**: Uses **`url`** (canonical; legacy `serverUrl` is still accepted on read). `migrate_context.py` emits canonical `url` when targeting `antigravity` and accepts either `url` or `serverUrl` on read.
- **No legacy HTTP+SSE**: Legacy 2024-11-05 `/sse` endpoints are NOT supported natively. Bridge SSE-only servers with `npx -y mcp-remote <url>` or mark as `deferred`/`agent_handoff`.
- **Optional fields**: `timeoutSeconds` (mapped from/to `timeout`), `enabledTools` (tool allowlist), `disabledTools` (tool denylist).

Official sources: [customization discovery](https://antigravity.google/docs/customization-discovery) · [mcp spec](https://modelcontextprotocol.io/specification/2025-03-26/basic/transports#streamable-http)
