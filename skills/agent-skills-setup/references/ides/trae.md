# trae

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.trae/skills` |
| Project skills | `.trae/skills` |
| Rules | `.trae/rules` |
| MCP | Not mapped |
| Project MCP | `.trae/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.trae/`
- **mcp**: project `.trae/mcp.json` is the only file path exposed by this mapper, as a manual/diagnostic path; root key `mcpServers` · JSON. The official international docs do not publish a stable global MCP file path: use **Settings → MCP Servers** and its raw-JSON editor/import workflow for global configuration.
- **skills**: global `~/.trae/skills/<name>/SKILL.md` · project `.trae/skills/<name>/SKILL.md`; `.agents/skills/` is an opt-in project compatibility directory and `.trae/skills` takes precedence. `SKILL.md` requires `name`/`description` frontmatter; `.trae/skill-config.json` is a narrow disabled-Skills file with undocumented schema.
- **rules**: project `.trae/rules/` with Markdown frontmatter (`alwaysApply`, `globs`, `description`, optional `scene: git_message`); nested directories are supported up to three levels. Root `AGENTS.md`, `CLAUDE.md`, and `CLAUDE.local.md` can be imported through Settings; global Rules remain UI-managed with no portable path.
- **commands**: project `.trae/commands/*.md`; global macOS/Linux `~/.trae/commands/` and Windows `%userprofile%/.trae/commands/`; nesting is supported up to three levels, but the richer command schema is only partially documented and remains manual.
- **subagents**: project `.trae/agents/<name>.md`; the international page publishes a conflicting `~/.trae-cn/agents/` user path, so global Subagents remain manual/unconfirmed. Frontmatter requires `name`/`description` and may include `model`, `tools`, `disallowedTools`, and `mcpServers`.
- **hooks**: global `~/.trae/hooks.json`; project `$PROJECT_FOLDER/.trae/hooks.json` on macOS/Linux; JSON root `version: 1` plus `hooks`, with command hooks and lifecycle matchers. Hooks execute shell commands and remain manual; the Windows project row is not documented.
- **memory**: global `~/.trae/memory/user_profile.md`; project `~/.trae/memory/projects/{project_path}/project_memory.md`; Markdown paths are documented but project-path encoding/portability is not, so manual only.
- **config**: unsupported. Trae IDE itself does not publish a global CLI/argv/settings file; do not infer `~/.trae/argv.json`, `~/.trae/settings.json`, or any other global config path.
- **product boundary**: TRAE Work/Desktop/Web/Mobile, TRAE Plugin, and the separate **`bytedance/trae-agent`** open-source CLI project (with `trae-cli` binary and repo-local `trae_config.yaml`/`trae_config.json`) must not inherit this IDE's `.trae` paths or schemas. Trae Agent ships its MCP config inline inside `trae_config.yaml` (root key `mcp_servers`, priority: CLI args > config > env > defaults) and is **not** an IDE-level MCP target. If a target IDE does not have a Trae Agent companion, do not promote the CLI's repo-local config to a global `.trae` file path.
- **sources**: [TRAE MCP](https://docs.trae.ai/ide/model-context-protocol?_lang=en), [TRAE Skills](https://docs.trae.ai/ide/skills?_lang=en), [TRAE Rules](https://docs.trae.ai/ide/rules?_lang=en), [TRAE Commands](https://docs.trae.ai/ide/slash-commands?_lang=en), [TRAE Hooks](https://docs.trae.ai/ide/automate-actions-with-hooks?_lang=en), [TRAE Memories](https://docs.trae.ai/ide/memories?_lang=en), [TRAE Subagents](https://docs.trae.ai/ide/subagents?_lang=en), [TRAE settings](https://docs.trae.ai/ide/ide-settings-overview?_lang=en), [Trae Agent CLI (separate product)](https://github.com/bytedance/trae-agent).
