# Kiro: Custom Agents, Hooks & MCP

Parent: [kiro.md](../kiro.md)

## Custom Agents (`.kiro/agents/`, `~/.kiro/agents/`)

- Defined as `.json` (legacy/v2) or `.md` with YAML frontmatter (`tools`, `model`, `permissions`, `mcpServers`, `resources` using `file://...` or `skill://...`).
- **CLI v2 vs v3 trap**: CLI v3 agent permissions (`allowedTools` / `toolsSettings`) differ from CLI v2 — confirm installed CLI major version and note that custom agents only load declared `skill://` / `file://` resources unless specified.

## Hooks (`.kiro/hooks/`) & MCP (`.kiro/settings/mcp.json`)

- **Hooks**: JSON files under `.kiro/hooks/` for `PostFileSave`, `PreToolUse`, `PostToolUse`, `Stop` — parked via `agent_handoff` unless `--activate-hooks` is approved.
- **MCP**: Project `.kiro/settings/mcp.json`, User `~/.kiro/settings/mcp.json` (root key **`mcpServers`**). In CLI v3 custom agents, MCP entries can also be embedded per agent.

Official sources: [custom agents](https://kiro.dev/docs/custom-agents) · [mcp configuration](https://kiro.dev/docs/mcp/configuration)
