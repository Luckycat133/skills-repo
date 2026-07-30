# cline

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.cline/skills` |
| Project skills | `.cline/skills` |
| Rules | `.clinerules` |
| MCP | darwin: `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`<br>linux: `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`<br>windows: `${APPDATA}/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` |
| Project MCP | `.cline/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.cline/`
- **mcp** (global/shared): `cline_mcp_settings.json` under the VS Code extension globalStorage `saoudrizwan.claude-dev/settings/` — macOS `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`, Linux `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`, Windows `${APPDATA}/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` (native notation: `%APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json`; confirmed by docs.cline.bot/mcp and multiple independent sources, 2026-07). Root key `mcpServers` · JSON. A legacy `~/.cline/mcp.json` CLI alternative may exist; the mapper writes globalStorage by default, honors `CLINE_MCP_PATH` for non-standard installs (Insiders/VSCodium/relocated `--user-data-dir`), and stops for manual selection if both globalStorage and `~/.cline/mcp.json` are present.
- **mcp** (project): `.cline/mcp.json` · root key `mcpServers` · JSON. Project and global scopes are separate; verify precedence in the active Cline surface.
- **rules**: project `.clinerules/` (extension-compatible) and CLI `.cline/rules/`; Cline also reads `.cursorrules`, `.windsurfrules`, and `AGENTS.md`. The generic single-file rules mapper targets `.clinerules` and leaves `.cline/rules/` manual.
- **project config**: generic `.cline/` copying is unsupported/manual because the directory mixes rules, skills, hooks, plugins, agents, cron, and other state; dedicated object mappings are required.
- **skills**: project `.cline/skills/` (also `.clinerules/skills/` and `.claude/skills/`) · global `~/.cline/skills/`
- **workflows/prompts**: Cline workflows are not a generic prompt-template directory: project `.clinerules/workflows/`, global `~/.cline/data/workflows/` (also `~/Documents/Cline/Workflows/`). Prompt migration is manual/unsupported.
- **settings/config**: `~/.cline/data/settings/global-settings.json` and `providers.json` are CLI/shared state; provider settings can contain credentials. Whole-config migration is unsupported; do not copy `config.json`, settings, providers, sessions, or secrets automatically.
- **memory**: no official portable memory-bank contract; `memory-bank/*.md` is a community methodology and manual context review only
- **other**: `.clineignore`
