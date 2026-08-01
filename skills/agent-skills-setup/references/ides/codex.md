# codex

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

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
- MCP/config is TOML `mcp_servers`; project config requires trust. JSON `mcpServers` is never converted automatically—rebuild and validate `[mcp_servers.<name>]` manually.
- Codex supports stdio and Streamable HTTP; do not map legacy SSE or add protocol/session headers. Recheck authorization with `codex mcp list`.
- `AGENTS.md` and documented Skills paths are portable. Commands/prompts lack a standalone target; hooks and project config remain manual.

Sources: [config](https://developers.openai.com/codex/config-reference/), [MCP](https://developers.openai.com/codex/mcp/), [customization](https://developers.openai.com/codex/concepts/customization/).
