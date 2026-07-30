# zed

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.agents/skills` |
| Project skills | `.agents/skills` |
| Rules | `AGENTS.md` |
| MCP | `~/.config/zed/settings.json` |
| Project MCP | `.zed/settings.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.config/zed/` (mac/linux/win — Zed stores `settings.json` here cross-platform; `~/Library/Application Support/Zed/` holds extensions/data only)
- **mcp**: global `~/.config/zed/settings.json` · project `.zed/settings.json` (diagnostic/manual scope) · root_key `context_servers` · JSON · local `command`/`args`/`env` or remote `url`/`headers`
- **rules**: project `AGENTS.md`; personal `~/.config/zed/AGENTS.md` (since 1.4.2; compatible project instruction files remain supported)
- **skills**: global `~/.agents/skills/<name>/SKILL.md` · project `.agents/skills/<name>/SKILL.md`
- **prompts**: no documented standalone prompt-template directory; MCP Prompts are server-provided and are not file prompt templates
- **config**: unsupported for generic cross-IDE copying; `settings.json` is Zed's native settings/MCP file, not a portable whole-IDE config target
- **agents**: via `agent_servers` config (ACP protocol to external agents)
- **note**: GUI-launched Zed lacks shell PATH — use absolute paths
