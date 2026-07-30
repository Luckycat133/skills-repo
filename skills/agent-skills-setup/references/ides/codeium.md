# codeium (Codeium → Windsurf)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | Not mapped |
| Project skills | Not mapped |
| Rules | Not mapped |
| MCP | Not mapped |
| Project MCP | Not mapped |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **status**: legacy product name; the current product/plugin is Windsurf (formerly Codeium)
- **detection**: no automatic legacy path is claimed. `~/.codeium/` is a shared historical/current namespace and must not be treated as a standalone Codeium installation; review any pre-rebrand residue manually, excluding `~/.codeium/windsurf/`.
- **skills / rules / mcp / config**: unsupported/empty in this mapper. No standalone Codeium Skills, MCP, or portable config path is evidenced by the current official docs; current Windsurf mappings are listed only under `### windsurf`.
- **migration boundary**: the `codeium` CLI token remains only so an explicitly selected legacy source fails closed with a manual/unsupported result. Do not use generic `.codeium` state as Skills or copy it as opaque project config.
- **sources**: [Windsurf Plugins — formerly Codeium](https://docs.windsurf.com/plugins/getting-started), [Cascade Skills](https://docs.windsurf.com/windsurf/cascade/skills), [Cascade MCP Integration](https://docs.windsurf.com/windsurf/cascade/mcp)
