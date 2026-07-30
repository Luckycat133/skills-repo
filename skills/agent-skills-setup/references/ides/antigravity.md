# antigravity (Antigravity IDE / shared 2.0 surface)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.gemini/config/skills` |
| Project skills | `.agents/skills` |
| Rules | `.agents/rules` |
| MCP | `~/.gemini/config/mcp_config.json` |
| Project MCP | `.agents/mcp_config.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: no officially documented IDE installation-detection path. Do not infer one from Antigravity IDE app data such as `~/.gemini/antigravity-ide/`.
- **mcp**: global `~/.gemini/config/mcp_config.json` · workspace `.agents/mcp_config.json` · root_key `mcpServers` · JSON · remote uses `serverUrl` (NOT `url`). The global file is shared by Antigravity 2.0, IDE, and CLI; the workspace file is an IDE-supported project scope.
- **rules**: global `~/.gemini/GEMINI.md` · workspace `.agents/rules/` (legacy `.agent/rules/` remains supported). Do not invent `.agents/AGENTS.md`.
- **skills**: the current shared Skills page documents `~/.gemini/config/skills/<name>/` · workspace `.agents/skills/<name>/SKILL.md`; the IDE-specific Skills page also documents the legacy IDE path `~/.gemini/antigravity/skills/<name>/`. The mapper uses `ANTIGRAVITY_SKILLS_DIR` when set, otherwise preserves an existing legacy-only tree and defaults a fresh install to `~/.gemini/config/skills`; never merge both trees implicitly. Legacy `.agent/skills/` remains supported by the product.
- **CLI product boundary**: Antigravity CLI is a separate surface. Its migration guide documents `~/.gemini/antigravity-cli/skills/` and `.agents/skills/`, while the current CLI MCP guide documents `~/.gemini/config/mcp_config.json` and `.agents/mcp_config.json`; use `agy plugin import gemini` for extension conversion and do not treat the CLI path as the IDE path.
- **workflows**: the official docs describe Global/Workspace management but do not publish a stable physical workflow directory; the previously suggested `global_workflows`/`.agents/workflows` paths are diagnostic candidates only and remain manual.
- **plugins**: global `~/.gemini/config/plugins/<plugin>/` · workspace `.agents/plugins/<plugin>/` or `_agents/plugins/<plugin>/`. A plugin requires `plugin.json` and may contain `mcp_config.json`, `hooks.json`, `skills/<skill>/SKILL.md`, and `rules/<rule>.md`.
- **hooks**: global `~/.gemini/config/hooks.json` · workspace `.agents/hooks.json` · JSON object keyed by hook name. Supported events are `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`, and `Stop`.
- **subagents**: workspace `.agents/agents/<name>.md` (or `.agents/agents/<name>/agent.md` as a directory with `agent.md` inside) · global `~/.gemini/config/agents/<name>.md` (or the equivalent directory variant). Plugins can also bundle agents under `plugins/<plugin_name>/agents/`. Markdown frontmatter required; the generic mapper has no agents object and these files remain manual.
- **migration note**: `smart-ide-migration.sh` has global MCP and Skills handlers. Plugins, hooks, subagents, workflows, workspace MCP, and workspace rule directories remain manual because they are mixed/runtime-sensitive even though several physical paths are documented.
- **sources**: [Antigravity IDE skills](https://antigravity.google/docs/ide/skills) · [current shared Skills](https://antigravity.google/docs/skills?app=antigravity-ide) · [CLI migration](https://antigravity.google/docs/cli/gcli-migration) · [Antigravity MCP](https://antigravity.google/docs/mcp) · [Antigravity IDE plugins](https://antigravity.google/docs/ide/plugins) · [Antigravity hooks](https://antigravity.google/docs/hooks) · [Antigravity Rules + Workflows](https://antigravity.google/docs/rules-workflows) · [Antigravity Subagents](https://antigravity.google/docs/subagents)
