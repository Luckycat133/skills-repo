# claude (Claude Code)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.claude/skills` |
| Project skills | `.claude/skills` |
| Rules | `CLAUDE.md` |
| MCP | `~/.claude.json` |
| Project MCP | `.mcp.json` |
| Project config | `.claude/settings.json` |
| Config | `~/.claude/settings.json` |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.claude/`
- **settings**: user `~/.claude/settings.json` · project `.claude/settings.json` · local `.claude/settings.local.json`.
- **mcp**: user and local scopes are stored in `~/.claude.json`; shared project scope is `.mcp.json` at the project root. The server-map key is `mcpServers`. The migration mapper's `mcp` path is the user file and its `project-mcp` diagnostic path is `.mcp.json`; it does not select or rewrite local per-project entries in `~/.claude.json`, so review those manually. Local MCP scope is distinct from local settings.
- **rules**: user `~/.claude/CLAUDE.md` / `~/.claude/rules/*.md` · project `CLAUDE.md`, `.claude/CLAUDE.md`, or `.claude/rules/*.md` · local `CLAUDE.local.md`.
- **skills**: project `.claude/skills/<name>/SKILL.md` · user `~/.claude/skills/<name>/SKILL.md`. `SKILL.md` is required; `description` is recommended and `name` is optional (defaults to the directory name).
- **commands**: `.claude/commands/*.md` is legacy compatibility. Prefer skills for new commands; this registry does not claim an unverified global commands path.
- **agents**: project `.claude/agents/*.md` · user `~/.claude/agents/*.md`. `name` and `description` are required; consult the current subagent frontmatter reference before copying additional fields.
- **hooks**: the `hooks` key in user, project, or local settings JSON; no standalone hooks file is documented.
- **memory**: auto memory is machine-local at `~/.claude/projects/<project>/memory/`. Do not auto-migrate auto memory or assume fixed topic filenames; use `/memory` to inspect it and manually select portable context.
- **sources**: [settings](https://code.claude.com/docs/en/settings), [MCP](https://code.claude.com/docs/en/mcp), [memory](https://code.claude.com/docs/en/memory), [skills](https://code.claude.com/docs/en/slash-commands), [subagents](https://code.claude.com/docs/en/sub-agents), [hooks](https://code.claude.com/docs/en/hooks).
