# cursor

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

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
- **detect**: no stable, documented installation-detection path used by this mapper; manual only
- **mcp**: global `~/.cursor/mcp.json` · project `.cursor/mcp.json` · root_key `mcpServers` · JSON · official docs describe stdio, legacy SSE, and Streamable HTTP; environment interpolation uses `${env:NAME}`. These client options are not interchangeable migration targets: retain an explicit documented transport and do not infer one from a bare URL.
- **rules**: canonical project directory `.cursor/rules/*.mdc` · frontmatter includes `description`, `globs`, and `alwaysApply`; root `.cursorrules` is legacy/deprecated compatibility
- **skills**: project `.cursor/skills/<name>/SKILL.md` · global `~/.cursor/skills/<name>/SKILL.md`; `.agents/skills/` is a separate cross-tool compatibility location, not the Cursor canonical project path
- **commands**: project `.cursor/commands/*.md` · plain Markdown commands; command-to-skill conversion is not performed automatically here
- **agents**: project `.cursor/agents/*.md`, `.claude/agents/*.md`, or `.codex/agents/*.md`; user `~/.cursor/agents/*.md`, `~/.claude/agents/*.md`, or `~/.codex/agents/*.md`; Markdown frontmatter/body is documented, but tools, MCP inheritance, permissions, and model fields are surface-specific and manual in this mapper
- **hooks**: `.cursor/hooks.json` project and `~/.cursor/hooks.json` global are documented; hook schema/events are not converted by this mapper, so manual/unsupported
- **plugins**: Cursor supports plugins, but this registry does not claim a portable package path or `plugin.json` schema; manual/unsupported
- **memory**: Cursor Memories are managed by Cursor and scoped to repositories; no portable file migration target is claimed
- **other**: `.cursorignore` is not AI context migration data
