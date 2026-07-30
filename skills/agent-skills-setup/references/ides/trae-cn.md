# trae-cn

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.trae-cn/skills` |
| Project skills | `.trae/skills` |
| Rules | `.trae/rules` |
| MCP | Not mapped |
| Project MCP | `.trae/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **product distinction**: Trae CN is the China build; do not reuse the international build's undocumented global MCP/config assumptions. The CN docs use the `~/.trae-cn/` namespace for user Skills, Commands, Memory, and Hooks.
- **global skills**: `~/.trae-cn/skills/<name>/SKILL.md` (macOS/Linux) / `%userprofile%/.trae-cn/skills/<name>/SKILL.md` (Windows); **project skills**: `.trae/skills/<name>/SKILL.md`.
- **skills compatibility**: `.agents/skills/` is supported when enabled in Settings, with `.trae/skills/` taking precedence on duplicate names; `.trae/skill-config.json` records disabled project Skills but its schema is undocumented and remains manual.
- **project rules**: `.trae/rules/` (Markdown with documented `alwaysApply`, `globs`, `description`, and optional `scene` frontmatter); global rules are managed in the UI and have no documented portable file path, so global rules remain manual.
- **commands/prompts**: project `.trae/commands/`; global `~/.trae-cn/commands/` (macOS/Linux) / `%userprofile%/.trae-cn/commands/` (Windows). The mapper's prompt object is project-scoped only; global Commands require manual review.
- **subagents**: project `.trae/agents/<name>.md`; global `~/.trae-cn/agents/<name>.md` (macOS/Linux) / `%userprofile%/.trae-cn/agents/<name>.md` (Windows); required frontmatter is `name` and `description`, with optional `model`, `tools`, `disallowedTools`, and `mcpServers`. The feature may require the Subagents setting/Beta capability, so this mapper leaves it manual.
- **mcp**: project `.trae/mcp.json` (when project MCP is enabled), root key `mcpServers`, JSON. The official CN MCP page documents the project file and **Settings → MCP Servers/raw-JSON** workflow but does not publish a stable user-global MCP filesystem path; the mapper leaves global MCP empty and manual/UI-only. Community/forum paths are not promoted to automatic mappings.
- **config/argv**: empty/unsupported for Trae IDE itself. Trae IDE does not publish a global CLI/argv/settings file under `~/.trae-cn/`; do not infer `~/.trae-cn/argv.json` or any other settings file. The Trae Agent bytedance/trae-agent project is a separate open-source CLI (repo-local `trae_config.yaml`) and is not an IDE target here.
- **memory**: documented but not an automatic migration object: global `~/.trae-cn/memory/user_profile.md`; project `~/.trae-cn/memory/projects/{project_path}/project_memory.md`. The `{project_path}` encoding/keying is not specified, so review/copy manually.
- **hooks**: documented but not an automatic migration object: global `~/.trae-cn/hooks.json` (macOS/Linux) / `%userprofile%/.trae-cn/hooks.json` (Windows); project `.trae/hooks.json`. The JSON root is `version` plus `hooks`; hook commands execute arbitrary shell commands, so never copy or run them automatically.
- **product boundary**: do not merge TRAE CLI (`trae_cli.yaml`/YAML MCP), TRAE Plugin, or TRAE Work/Desktop paths into this IDE entry. Trae Agent (`bytedance/trae-agent`) is a separate product and does not write to `~/.trae-cn/`.
- **sources**: [TRAE CN Skills](https://docs.trae.cn/ide/skills), [TRAE CN Rules](https://docs.trae.cn/ide/rules), [TRAE CN MCP](https://docs.trae.cn/ide/add-mcp-servers), [TRAE CN Commands](https://docs.trae.cn/ide/slash-commands), [TRAE CN Memory](https://docs.trae.cn/ide_memories) (confirms `~/.trae-cn/memory/user_profile.md`), [TRAE CN Hooks overview](https://docs.trae.cn/ide_automate-actions-with-hooks), [TRAE CN Hooks reference](https://docs.trae.cn/ide_hook-configuration-reference) (confirms global `~/.trae-cn/hooks.json`), [TRAE CN Subagents](https://docs.trae.cn/ide_subagents) (confirms global `~/.trae-cn/agents/<name>.md`), [TRAE CN changelog](https://docs.trae.cn/ide_changelog), [TRAE CN sitemap](https://docs.trae.cn/sitemap.xml).
