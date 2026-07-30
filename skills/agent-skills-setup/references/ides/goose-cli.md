# goose-cli (Goose CLI)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.agents/skills` |
| Project skills | `.agents/skills` |
| Rules | `.goosehints` |
| MCP | `~/.config/goose/config.yaml` |
| Project MCP | Not mapped |
| Project config | Not mapped |
| Config | `~/.config/goose/config.yaml` |

<!-- END GENERATED: ide-paths.json summary -->
- **status**: current Goose CLI/desktop documentation is published by the Agentic AI Foundation at `goose-docs.ai`; the CLI and desktop share core config/extension storage
- **detect/config**: POSIX primary config `~/.config/goose/config.yaml`; Windows `%APPDATA%\Block\goose\config\config.yaml` (the mapper's `~/.config/goose` path is the documented macOS/Linux form)
- **mcp/config**: global `~/.config/goose/config.yaml` · root key `extensions` · YAML, not JSON · extension entries use documented type-specific fields such as `builtin`/`platform`/`stdio`/`streamable_http`/`frontend`/`inline_python`, `cmd`, `args`, `envs`, `uri`, `headers`, `enabled`, `timeout`, and `available_tools`; legacy `sse` may appear for compatibility
- **skills**: global `~/.agents/skills/` · project `.agents/skills/` · `SKILL.md` in each named subdirectory; `.goose/skills/`, `.claude/skills/`, `~/.claude/skills/`, and platform-specific config directories are documented backward-compatible discovery locations, not this mapper's canonical targets
- **rules/context**: global `~/.config/goose/.goosehints`; local `.goosehints` at project/root or nested directories; `AGENTS.md` and other names are loaded when selected through `CONTEXT_FILE_NAMES` (default context names are `AGENTS.md` then `.goosehints`)
- **recipes**: global `~/.config/goose/recipes/` · local `.goose/recipes/` · YAML/JSON recipe files with instructions/extensions/parameters; NOT skills or MCP config
- **prompt templates**: global `~/.config/goose/prompts/` · no documented project prompt-template directory; custom slash commands are `slash_commands` entries in `~/.config/goose/config.yaml` pointing to recipe files
- **memory**: global `~/.config/goose/memory/` · local `.goose/memory/` · Memory extension-managed files; this is a directory/object store, not a portable rules or Skills path
- **other**: `~/.config/goose/permission.yaml` · `~/.config/goose/secrets.yaml` (or keyring); never copy secrets automatically
- **automatic migration boundary**: Skills and local `.goosehints` can use the dedicated low-risk paths. MCP/config/project/prompt operations involving Goose are manual because the format is YAML, scopes are mixed, and `config.yaml`/`secrets.yaml` are not interchangeable with another IDE's JSON schema
- **sources**: [Agent Skills](https://goose-docs.ai/docs/guides/context-engineering/using-skills/), [goosehints](https://goose-docs.ai/docs/guides/context-engineering/using-goosehints/), [configuration files](https://goose-docs.ai/docs/guides/config-files/), [using extensions](https://goose-docs.ai/docs/getting-started/using-extensions/), [prompt templates](https://goose-docs.ai/docs/guides/context-engineering/prompt-templates/), [recipes](https://goose-docs.ai/docs/guides/recipes/storing-recipes/), [slash commands](https://goose-docs.ai/docs/guides/context-engineering/slash-commands/), [Memory extension](https://goose-docs.ai/docs/mcp/memory-mcp/)
