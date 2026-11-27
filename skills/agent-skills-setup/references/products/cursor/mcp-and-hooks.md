# Cursor: MCP (`mcp.json`) & Lifecycle Hooks

Parent: [cursor.md](../cursor.md)

## MCP (`mcp.json`)

- Project: `.cursor/mcp.json`; Global: `~/.cursor/mcp.json`. Root key: **`mcpServers`**.
- Supports `${VAR}` env interpolation, Stdio (`command`, `args`, `env`), and HTTP/SSE (`url`, `headers`).

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "mcp-server-package"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

## Hooks (`.cursor/hooks.json` & `.cursor/hooks/`)

- Config: `.cursor/hooks.json` or `~/.cursor/hooks.json`; helper scripts under `.cursor/hooks/*.sh`.
- Agent/editor lifecycle events include `sessionStart`, `preToolUse`, `subagentStart`, `beforeShellExecution`, `beforeMCPExecution`, and `stop` over stdio JSON.
- Always park hooks on cross-IDE migration (`agent_handoff`) unless `--activate-hooks` is passed on same-profile restore; exclude SQLite workspace state and `~/.cursor` caches.

Official sources: [mcp](https://cursor.com/docs/mcp) · [hooks](https://cursor.com/docs/hooks) · [customize cursor](https://cursor.com/docs/customize-cursor)
