# augment-code

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.augment/skills` |
| Project skills | `.augment/skills` |
| Rules | Not mapped |
| MCP | `~/.augment/settings.json` |
| Project MCP | `.augment/settings.json` |
| Project config | `.augment/settings.json` |
| Config | `~/.augment/settings.json` |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.augment/`
- **mcp**: global `~/.augment/settings.json` · project `.augment/settings.json` / `.augment/settings.local.json` · root_key `mcpServers` · JSON · stdio+HTTP/SSE
- **rules**: user `~/.augment/rules/*.md` · workspace `.augment/rules/*.md` · `.augment-guidelines`; frontmatter: always_apply, agent_requested (manual is IDE-only)
- **skills**: project `.augment/skills/<name>/SKILL.md` · global `~/.augment/skills/` · also loads `~/.claude/skills/`, `~/.agents/skills/` · frontmatter: name, description, agent, fork, color
- **commands**: global `~/.augment/commands/`
- **other**: `~/.augment-plugin/` (plugins marketplace)
- **sources**: [Augment Skills](https://docs.augmentcode.com/using-augment/skills), [Augment Rules](https://docs.augmentcode.com/cli/rules), [Augment MCP](https://docs.augmentcode.com/cli/integrations), [Augment config scopes](https://docs.augmentcode.com/cli/config)
