# kiro

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

| Object | Documented path |
| --- | --- |
| Global skills | `~/.kiro/skills` |
| Project skills | `.kiro/skills` |
| Rules | Not mapped |
| MCP | `~/.kiro/settings/mcp.json` |
| Project MCP | `.kiro/settings/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- MCP JSON uses `mcpServers`; migrate only reviewed endpoint metadata and re-authorize OAuth in Kiro.
- Steering rules have their own inclusion frontmatter. Skills use documented directories.
- IDE agents, CLI agents, hooks, and specs have distinct schemas/scopes; reconstruct manually and never convert CLI JSON into IDE Markdown.

Sources: [Skills](https://kiro.dev/docs/skills/), [MCP](https://kiro.dev/docs/mcp/configuration/), [steering](https://kiro.dev/docs/steering/), [custom agents](https://kiro.dev/docs/custom-agents/), [hooks](https://kiro.dev/docs/hooks/).
