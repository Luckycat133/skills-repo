# copilot-cli

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.copilot/skills` |
| Project skills | `.github/skills` |
| Rules | `.github/copilot-instructions.md` |
| MCP | `~/.copilot/mcp-config.json` |
| Project MCP | `.mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.copilot/`
- **alias**: migration-script key `copilot` (GitHub Copilot CLI, not VS Code Copilot)
- **mcp**: global `~/.copilot/mcp-config.json` · project `.mcp.json` / `.github/mcp.json` · root_key `mcpServers` · JSON. CLI transports: `local` / `stdio` (command + args) and `http` / `sse` (url); `tools` is required. Treat `sse` as legacy compatibility and do not relabel it as `http` merely because both use a URL. Project files take precedence over user definitions on a name collision. The generic mapper migrates only the global file and leaves both project files for manual review.
- **rules**: project `.github/copilot-instructions.md` · `.github/instructions/**/*.instructions.md` · agent instructions `AGENTS.md` / root `CLAUDE.md` / `GEMINI.md` · personal `~/.copilot/copilot-instructions.md` / `~/.copilot/instructions/**/*.instructions.md`
- **skills**: project `.github/skills/<name>/SKILL.md` / `.claude/skills/<name>/SKILL.md` / `.agents/skills/<name>/SKILL.md` · personal `~/.copilot/skills/<name>/SKILL.md` / `~/.agents/skills/<name>/SKILL.md`
- **prompts**: unsupported — `.github/prompts/*.prompt.md` is for Copilot IDE surfaces, not Copilot CLI
- **agents**: project `.github/agents/*.agent.md` / `.claude/agents/*.agent.md` · personal `~/.copilot/agents/*.agent.md`
- **hooks**: project `.github/hooks/*.json` · personal `~/.copilot/hooks/*.json` or `~/.copilot/settings.json` `hooks` key
- **plugins**: configure declaratively with `enabledPlugins` in `~/.copilot/settings.json` or `.github/copilot/settings.json`; installed-plugin state under `~/.copilot/` is application-managed, not a migration target
- **note**: `.vscode/mcp.json` is VS Code's distinct `servers` schema. Its entries require transport/schema review before placing them in a CLI `mcpServers` file; never copy it unchanged or let the generic mapper choose between `.mcp.json` and `.github/mcp.json`.
