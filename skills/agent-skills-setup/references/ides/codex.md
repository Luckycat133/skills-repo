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
- `AGENTS.md` and documented Skills paths are portable; admin skills may also live under `/etc/codex/skills`. `[[skills.config]]`, plugin bundles, hooks, and `agents/openai.yaml` are separate supported surfaces but remain manual because they include policy, UI metadata, or executable lifecycle behavior.

Sources: [config](https://developers.openai.com/codex/config-reference/), [MCP](https://developers.openai.com/codex/mcp/), [Skills](https://developers.openai.com/codex/skills), [customization](https://developers.openai.com/codex/concepts/customization/).
