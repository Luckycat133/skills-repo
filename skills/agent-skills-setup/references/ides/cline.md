# cline

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

| Object | Documented path |
| --- | --- |
| Global skills | `~/.cline/skills` |
| Project skills | `.cline/skills` |
| Rules | `.clinerules` |
| MCP | darwin: `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`<br>linux: `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`<br>windows: `${APPDATA}/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` |
| Project MCP | `.cline/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- Global MCP is `cline_mcp_settings.json` in VS Code extension globalStorage, with JSON `mcpServers`; `CLINE_MCP_PATH` handles non-standard installs. A legacy `~/.cline/mcp.json` can exist—if both exist, stop for manual selection.
- Project MCP is `.cline/mcp.json`; verify active-surface precedence.
- `.cline/` mixes skills, rules, hooks, plugins, agents, workflows, and state, so whole-project migration is unsupported. The single-file rules mapper uses `.clinerules`; other rule stores are manual.
- Prompts/workflows, provider settings, sessions, config, and memory are manual. Never copy providers or secrets.

Source: [Cline MCP](https://docs.cline.bot/mcp).
