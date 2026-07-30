# jetbrains (Junie in JetBrains IDEs; not JetBrains AI Assistant)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.junie/skills` |
| Project skills | `.junie/skills` |
| Rules | `.junie/AGENTS.md` |
| MCP | `~/.junie/mcp/mcp.json` |
| Project MCP | `.junie/mcp/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.junie/` is a Junie home heuristic; IDE settings themselves are managed by JetBrains UI and have no verified portable file path
- **mcp**: project `.junie/mcp/mcp.json` · user `~/.junie/mcp/mcp.json` · root_key `mcpServers` · JSON · project/user scopes are documented by Junie
- **skills**: project `.junie/skills/<name>/SKILL.md` · user `~/.junie/skills/<name>/SKILL.md` · open Agent Skills format; project skill takes precedence when names collide
- **rules**: preferred project `.junie/AGENTS.md`; root `AGENTS.md` is the documented fallback; legacy `.junie/guidelines.md` / `.junie/guidelines/` and custom Project Settings paths remain compatibility/manual inputs, not CLI-only files
- **MCP conversion boundary**: automatic conversion handles only local `command`/optional `args`/`env`; remote/headers/type/transport/unknown fields fail closed for manual review. Project MCP remains manual in this generic user-scope operation.
- **project namespace**: `.junie/` mixes Skills, AGENTS/guidelines, MCP, and IDE state; whole-directory migration is blocked. Junie CLI uses a documented config precedence: CLI flags > `~/.junie/settings.json` > `<project-root>/.junie/config.json` (when the CLI project is trusted) > `~/.junie/config.json`; a `--config-location <path>` (env `JUNIE_CONFIG_LOCATION`) override loads even on untrusted projects and disables defaults when `JUNIE_CONFIG_DEFAULT_LOCATIONS=false`. **Important**: hooks from the default project `.junie/config.json` are intentionally ignored — personal hooks must live in `~/.junie/config.json` or be passed explicitly via `--config-location`. Trust markers live under `<Junie Home>/trust` (default `~/.junie/trust`).
- **config**: empty/manual for this IDE mapper. Junie CLI documents user `~/.junie/config.json`, user `~/.junie/settings.json`, and project `<project-root>/.junie/config.json`; that is CLI configuration, not a verified JetBrains IDE settings file. The IDE-level `(Settings | Tools | Junie | Project Settings)` / `(Settings | Tools | Junie | MCP Settings)` / `(Settings | Tools | Junie | Action Allowlist)` paths remain UI-managed.
- **JetBrains AI Assistant**: separate product surface. Its MCP servers and agent settings are configured in Settings → Tools → AI Assistant → Model Context Protocol (MCP)/Agents; no portable global/project path is claimed here. Treat GUI-only settings and migrations as manual/unsupported.
- **sources**: [Junie Skills](https://junie.jetbrains.com/docs/agent-skills.html), [Junie IDE plugin](https://junie.jetbrains.com/docs/junie-ide-plugin.html), [Junie Project Settings](https://junie.jetbrains.com/docs/junie-plugin-project-settings.html), [Junie MCP Settings](https://junie.jetbrains.com/docs/junie-plugin-mcp-settings.html), [Junie CLI config](https://junie.jetbrains.com/docs/junie-cli-configuration.html)
