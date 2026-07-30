# continue

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | Not mapped |
| Project skills | Not mapped |
| Rules | `.continue/rules` |
| MCP | `~/.continue/config.yaml` |
| Project MCP | `.continue/mcpServers` |
| Project config | Not mapped |
| Config | `~/.continue/config.yaml` |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.continue/`
- **config**: global `~/.continue/config.yaml` · current YAML schema requires `name`, `version`, and `schema`; legacy `config.json` is deprecated and `.continuerc.json` is a separate legacy workspace override
- **project blocks**: `.continue/models/`, `.continue/rules/`, `.continue/prompts/`, and `.continue/mcpServers/`; these are block directories, not one generic project config file
- **mcp**: global `~/.continue/config.yaml` or project `.continue/mcpServers/<name>.yaml` · root_key `mcpServers` · YAML · ARRAY format (not object), with each server requiring `name` and `command` for local stdio entries
- **rules**: project `.continue/rules/*.md` (Markdown with YAML frontmatter; `name`, `globs`, `regex`, `alwaysApply`, `description` are documented fields); no official `CONTINUE.md` path
- **prompts**: `.continue/prompts/*.md` · prompt files use YAML frontmatter and can be invoked as slash commands
- **skills**: unsupported; Continue docs do not define a `SKILL.md` skill directory
- **automatic boundary**: this mapper exposes paths for diagnosis but does not automatically copy Continue `config.yaml`, MCP, rules, or the mixed `.continue` project namespace; its generic JSON converter cannot safely convert YAML or an `mcpServers` array
- **sources**: [config.yaml reference](https://docs.continue.dev/reference), [configuration](https://docs.continue.dev/customize/deep-dives/configuration), [MCP](https://docs.continue.dev/customize/deep-dives/mcp), [rules](https://docs.continue.dev/customize/deep-dives/rules), [prompts](https://docs.continue.dev/customize/prompts), [YAML migration](https://docs.continue.dev/reference/yaml-migration), [config.json reference](https://docs.continue.dev/reference/json-reference)
