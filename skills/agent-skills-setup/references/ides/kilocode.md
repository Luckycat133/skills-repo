# kilocode

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

| Object | Documented path |
| --- | --- |
| Global skills | `~/.kilo/skills` |
| Project skills | `.kilo/skills` |
| Rules | `AGENTS.md` |
| MCP | `~/.config/kilo/kilo.jsonc` |
| Project MCP | `.kilo/kilo.jsonc` |
| Project config | `.kilo/kilo.jsonc` |
| Config | `~/.config/kilo/kilo.jsonc` |

<!-- END GENERATED: ide-paths.json summary -->
- MCP is JSONC `mcp` with distinct local/remote shapes; do not flatten it into another client schema.
- Skills use documented locations, with compatibility directories kept separate.
- Rules, agents, and config fields are mixed scopes and manual.

Sources: [Skills](https://kilo.ai/docs/customize/skills), [MCP](https://kilo.ai/docs/automate/mcp/using-in-kilo-code).
