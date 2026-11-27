# OpenCode: `opencode.json` MCP (V1 vs V2) & Agents

Parent: [opencode.md](../opencode.md)

## Config Files & V1 vs V2 MCP Container

- Paths: `./opencode.json`, `./opencode.jsonc`, `./.opencode/opencode.json` (project), and `~/.config/opencode/opencode.json` (global).
- **V1 root key**: `"mcp"` (`mcp.<name>`)
- **V2 root key**: `"mcp.servers"` (`mcp.servers.<name>`) — `migrate_context.py` detects and preserves existing `mcp.servers` vs `mcp` cleanly!

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "codegraph": {
      "type": "local",
      "command": ["codegraph", "serve", "--mcp"],
      "environment": { "API_KEY": "${API_KEY}" },
      "cwd": "packages/app",
      "enabled": true
    },
    "remote-docs": {
      "type": "remote",
      "url": "https://mcp.example.com/mcp",
      "headers": { "Authorization": "Bearer ${API_TOKEN}" },
      "enabled": true
    }
  }
}
```

- **OpenCode incompatibilities to guard**:
  - `cwd` inside OpenCode `local` MCP cannot contain `${...}`/`{env:...}`/`~` or relative workspace paths on non-OpenCode sources (`migrate_context.py` defers safely).
  - OpenCode MCP objects cannot preserve per-tool allow/deny lists (`tool_allow`/`tool_deny`) natively — emit `deferred` instead of dropping restrictions.

## Subagents & Permissions

- Paths: `.opencode/agents/*.md`, `~/.config/opencode/agents/*.md` (and `agent` entries in `opencode.json`).
- Keep `permission` allow/ask/deny rules separated from portable prompt content unless explicitly audited.

Official sources: [mcp servers](https://opencode.ai/docs/mcp-servers/) · [v2 mcp](https://opencode.ai/v2/docs/mcp-servers) · [migrate v1](https://opencode.ai/v2/docs/migrate-v1)
