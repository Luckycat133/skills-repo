# antigravity (Antigravity IDE / shared 2.0 surface)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

| Object | Documented path |
| --- | --- |
| Global skills | `~/.gemini/config/skills` |
| Project skills | `.agents/skills` |
| Rules | `.agents/rules` |
| MCP | `~/.gemini/config/mcp_config.json` |
| Project MCP | `.agents/mcp_config.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- MCP uses JSON `mcpServers`; remote endpoints use `serverUrl`, not `url`. The global file is shared by Antigravity surfaces; workspace MCP remains manual.
- Global Skills default to the generated path. `ANTIGRAVITY_SKILLS_DIR` overrides it; otherwise preserve a legacy-only tree and never merge legacy/current trees implicitly. `.agent/` remains legacy compatibility.
- Workspace rules use `.agents/rules/`; do not invent `.agents/AGENTS.md`. No official installation-detection or stable workflow path exists.
- Plugins, hooks, agents, workflows, and workspace MCP/rules are mixed or runtime-sensitive, so reconstruct manually. Antigravity CLI is separate; do not treat its paths as IDE paths.

Sources: [IDE Skills](https://antigravity.google/docs/ide/skills), [shared Skills](https://antigravity.google/docs/skills?app=antigravity-ide), [MCP](https://antigravity.google/docs/mcp), [plugins](https://antigravity.google/docs/ide/plugins).
