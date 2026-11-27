# Gemini CLI: `settings.json` (`mcpServers` & Hooks)

Parent: [gemini-cli.md](../gemini-cli.md)

## Locations & Subobject Policy

- Project: `.gemini/settings.json`; User: `~/.gemini/settings.json` (supports `$VAR_NAME` and `${VAR_NAME}` string interpolation).
- Patch **only** `"mcpServers"` (and `"hooks"` when `--activate-hooks` is explicitly passed on same-profile restore). Never copy `theme`, `trust`, OAuth state, auto memory, or checkpoints!

## `mcpServers` JSON Schema

```json
{
  "mcpServers": {
    "local-db": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      },
      "includeTools": ["query"],
      "excludeTools": ["drop_table"]
    },
    "stream-api": {
      "httpUrl": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      }
    },
    "sse-api": {
      "url": "https://sse.example.com/events"
    }
  }
}
```

- **Key transport trap**: Streamable HTTP uses **`httpUrl`**; legacy SSE uses **`url`**. Tool allow/deny uses **`includeTools`** / **`excludeTools`** (plus global `mcp.allowed` / `mcp.excluded` lists).

Official sources: [configuration reference](https://geminicli.com/docs/reference/configuration/) · [hooks](https://geminicli.com/docs/hooks/)
