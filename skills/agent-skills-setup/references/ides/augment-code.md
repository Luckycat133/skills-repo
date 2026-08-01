# augment-code

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

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
- MCP JSON uses `mcpServers`; retain explicit `http`/legacy `sse`, never infer transport from URL.
- Rules and Skills have documented locations; compatibility Skill directories are not merge targets.
- Commands and plugins are separate state. Project/local settings are manual, not portable whole-config migration.

Sources: [Skills](https://docs.augmentcode.com/using-augment/skills), [Rules](https://docs.augmentcode.com/cli/rules), [MCP](https://docs.augmentcode.com/cli/integrations).
