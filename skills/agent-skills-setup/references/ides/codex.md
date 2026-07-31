# codex

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.agents/skills` |
| Project skills | `.agents/skills` |
| Rules | `AGENTS.md` |
| MCP | `~/.codex/config.toml` |
| Project MCP | `.codex/config.toml` |
| Project config | `.codex/config.toml` |
| Config | `~/.codex/config.toml` |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.codex/`
- **config / MCP**: user `~/.codex/config.toml` · project `.codex/config.toml` (loaded only for trusted projects) · root key `mcp_servers` · TOML · stdio + Streamable HTTP · `codex mcp add`, `codex mcp list`, `codex mcp --help`. This mapper reports project config diagnostically only and leaves every Codex MCP/config transfer manual; it never converts JSON `mcpServers` into TOML.
- **rules**: project `AGENTS.md` · global `~/.codex/AGENTS.md`
- **skills**: project `.agents/skills/<name>/SKILL.md` · global `~/.agents/skills/<name>/SKILL.md` (documented Codex skill locations; do not treat them as an undocumented compatibility alias)
- **commands / prompts**: no standalone migration target documented; use skills for reusable workflows instead.
- **hooks**: global `~/.codex/hooks.json` or `~/.codex/config.toml` · project `.codex/hooks.json` or `.codex/config.toml` (project layer requires trust)
- **note**: configure each MCP server in TOML as `[mcp_servers.<server-name>]`; stdio uses `command` and Streamable HTTP uses `url`, with optional `bearer_token_env_var` or `http_headers`. Do not add MCP protocol/session headers or map a legacy SSE source URL to this field without a server-owner replacement endpoint; Codex performs protocol negotiation at runtime. Hooks can be `hooks.json` or inline `[hooks]` beside the active config layer; project hooks also require trust. JSON↔TOML MCP migration is unsupported by the script and must be rebuilt manually. Sources: [config reference](https://developers.openai.com/codex/config-reference/), [MCP](https://developers.openai.com/codex/mcp/), [advanced config](https://developers.openai.com/codex/config-advanced/), [customization / skills](https://developers.openai.com/codex/concepts/customization/).
