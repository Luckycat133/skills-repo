# kilocode

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

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
- **detect**: project `.kilo/` · global `~/.config/kilo/`
- **mcp**: global `~/.config/kilo/kilo.jsonc` · project `kilo.jsonc` or `.kilo/kilo.jsonc` · root_key `mcp` · JSONC · local `type: local` + command array + environment; remote `type: remote` + url/headers
- **skills**: global `~/.kilo/skills/<name>/SKILL.md` · project `.kilo/skills/<name>/SKILL.md` · compatibility `.agents/skills` and `.claude/skills`
- **rules/agents**: `.kilo/rules/`, `.kilo/agents/`, `AGENTS.md`, and `kilo.jsonc` instructions/agent fields; these are mixed scopes and manual in this mapper
- **sources**: [Kilo Skills](https://kilo.ai/docs/customize/skills), [Kilo MCP](https://kilo.ai/docs/automate/mcp/using-in-kilo-code)

---
