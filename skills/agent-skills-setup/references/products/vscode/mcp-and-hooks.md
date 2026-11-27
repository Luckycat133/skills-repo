# VS Code & Copilot CLI: MCP (`servers`) & Hooks

Parent: [vscode.md](../vscode.md)

## Workspace MCP (`.vscode/mcp.json`) vs Copilot CLI (`mcp-config.json`)

- VS Code `.vscode/mcp.json` uses root key **`servers`** (NOT `mcpServers`), explicit `"type": "stdio" | "http" | "sse"`, env placeholder **`${env:VAR}`**, and optional **`inputs`** (`${input:id}`).
- Copilot CLI user MCP lives at `~/.copilot/mcp-config.json` (uses `mcpServers`).

```json
{
  "servers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${env:GITHUB_TOKEN}"
      }
    }
  }
}
```

- **Secret & `${input:...}` guard**: `migrate_context.py` translates `${VAR} <-> ${env:VAR}` cleanly across VS Code and sibling tools, while entries referencing `${input:...}` emit explicit `deferred` / `agent_handoff` on non-VS Code targets so dangling placeholders are never installed silently.

## Lifecycle Hooks (`.github/hooks/*.json`)

- Both VS Code Copilot and Copilot CLI read project hooks from `.github/hooks/*.json`.
- Always keep hook scripts parked via `agent_handoff` on cross-tool moves unless `--activate-hooks` is explicitly passed on compatible targets; exclude Settings Sync & `state.vscdb`.

Official sources: [VS Code MCP](https://code.visualstudio.com/docs/agent-customization/mcp-servers) · [GitHub Copilot cheat sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
