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
- Extension MCP is `cline_mcp_settings.json` in VS Code globalStorage, with JSON `mcpServers`; `CLINE_MCP_PATH` handles non-standard installs. Cline CLI uses `~/.cline/mcp.json`; if both surfaces exist, stop for manual selection. Streamable HTTP requires explicit `type: streamableHttp`.
- Project MCP is `.cline/mcp.json`; verify active-surface precedence.
- `.cline/` mixes skills, hooks, plugins, agents, workflows, and state, so whole-project migration is unsupported. Project rules primarily use the `.clinerules/` directory; OS Documents/Cline/Rules stores global rules. They are manual because scoped files must not be flattened.
- Skills use `.cline/skills/` and `~/.cline/skills/`, with `.clinerules/skills/` and `.claude/skills/` compatibility locations kept separate.
- Prompts/workflows, provider settings, sessions, config, and memory are manual. Never copy providers or secrets.

Sources: [MCP](https://docs.cline.bot/mcp/mcp-overview), [rules](https://docs.cline.bot/customization/cline-rules), [Skills](https://docs.cline.bot/customization/skills).
