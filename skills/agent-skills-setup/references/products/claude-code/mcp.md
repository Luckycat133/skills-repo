# Claude Code: MCP Configuration

Parent: [claude-code.md](../claude-code.md)

## Three Official Scopes

| Scope | File & Key | Git / Secret Policy |
| --- | --- | --- |
| Project (shared) | `.mcp.json` -> `mcpServers` | Tracked in Git — **never write literal secrets here** |
| Local project (personal override) | `~/.claude.json` -> `projects["/abs/workspace"].mcpServers` | Private (`0600`) — `migrate_context.py` automatically routes secret-bearing project MCP here unless `--allow-git-tracked-secrets` or `--redact-secrets` is passed |
| User global | `~/.claude.json` (or `$CLAUDE_CONFIG_DIR/.claude.json`) -> root `mcpServers` | Private (`0600`) |

## JSON Schema

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "remote-http": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      }
    },
    "legacy-sse": {
      "type": "sse",
      "url": "https://sse.example.com/events"
    }
  }
}
```

- Supports both `type: "http"` (Streamable HTTP) and `type: "sse"`, `${VAR}` env expansion, and sibling non-MCP keys inside `~/.claude.json` (oauth tokens, project trust, preferences) which surgical patching MUST preserve untouched.

Official sources: [mcp](https://code.claude.com/docs/en/mcp) · [features overview](https://code.claude.com/docs/en/features-overview)
