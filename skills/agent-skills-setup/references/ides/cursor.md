# cursor

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

| Object | Documented path |
| --- | --- |
| Global skills | `~/.cursor/skills` |
| Project skills | `.cursor/skills` |
| Rules | `.cursor/rules` |
| MCP | `~/.cursor/mcp.json` |
| Project MCP | `.cursor/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- MCP JSON uses `mcpServers`; retain an explicit documented stdio, legacy-SSE, or Streamable HTTP transport. A bare URL is not enough, and `${env:NAME}` is Cursor-specific.
- `.cursor/rules/*.mdc` uses frontmatter; root `.cursorrules` is legacy. `.agents/skills/` is compatibility state, not Cursor's canonical project path.
- `.cursor/commands/*.md` is manual/unsupported for command-to-skill conversion. Agents, hooks, plugins, memories, and `.cursorignore` are manual.
- No stable installation-detection path is used by this mapper.
