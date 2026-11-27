# Windsurf / Cascade: MCP (`mcp_config.json`)

Parent: [windsurf.md](../windsurf.md)

## Locations & Limits

- **Global Cascade MCP**: `~/.codeium/windsurf/mcp_config.json` (root key **`mcpServers`**).
- **Devin Local project fallback**: `.devin/mcp_config.json` (also discovered by `windsurf` as legacy read path).
- **Tool cap**: Cascade enforces an active ceiling of ~100 MCP tools simultaneously; prune unused servers/tools during migration if approaching the limit.

## JSON Schema

```json
{
  "mcpServers": {
    "local-tool": {
      "command": "python",
      "args": ["mcp_script.py"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    },
    "remote-tool": {
      "serverUrl": "https://mcp.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${TOKEN}"
      }
    }
  }
}
```

- Note: Windsurf uses **`serverUrl`** for remote MCP endpoints. `migrate_context.py` translates seamlessly between Windsurf `serverUrl` and canonical `url` / Gemini `httpUrl`.

Official sources: [Devin Local overview](https://docs.devin.ai/desktop/devin-local/overview) · [Devin Desktop FAQ](https://docs.devin.ai/desktop/devin-desktop-faq)
