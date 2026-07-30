# vscode (VS Code + GitHub Copilot IDE; not cloud agent or the `copilot` script target)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.copilot/skills` |
| Project skills | `.github/skills` |
| Rules | `.github/copilot-instructions.md` |
| MCP | Not mapped |
| Project MCP | `.vscode/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: no stable portable VS Code installation/config path is used by this mapper; `~/.vscode/` is application data, not a Skills or whole-project target
- **mcp**: workspace `.vscode/mcp.json` · root_key `servers` · JSON. User MCP is profile-scoped and must be resolved with `MCP: Open User Configuration`; the mapper intentionally returns no global filesystem path because default/named Profiles, Insiders/VSCodium, and relocated `--user-data-dir` installations can select different stores. Local entries use `command`/`args`/`env` and optional `type: stdio`; remote entries use `type: http|sse` plus `url`/optional `headers`/`oauth`. This schema is distinct from CLI `mcpServers`; the converter validates it and fails closed on foreign `transport`/`serverUrl` fields.
- **rules**: `.github/copilot-instructions.md` · `.github/instructions/**/*.instructions.md` (frontmatter: `applyTo`) · other agent instruction files are surface-specific and require manual review
- **skills**: project `.github/skills/<name>/SKILL.md` / `.claude/skills/<name>/SKILL.md` / `.agents/skills/<name>/SKILL.md` · personal `~/.copilot/skills/<name>/SKILL.md` / `~/.claude/skills/<name>/SKILL.md` / `~/.agents/skills/<name>/SKILL.md`
- **prompts**: workspace `.github/prompts/*.prompt.md`; user-level prompt files are supported by the UI, but the official docs do not publish a portable user path, so user prompt migration is manual. VS Code frontmatter fields including `description`, `name`, `agent`, `model`, and `tools` are optional · not supported by Copilot CLI
- **extensions**: manual only. Extensions are installed and managed by VS Code; extension-contributed skills are declared by the extension's `package.json` `chatSkills` contribution point, not in a portable user/workspace file. Do not copy extension storage or invent an extension registry path.
- **note**: The `vscode` mapper key is VS Code/Copilot IDE only. GitHub Copilot CLI remains the separate `copilot` target with `~/.copilot/mcp-config.json` and `mcpServers`.
- **agents/hooks/plugins**: `.github/agents/*.agent.md`, `.github/hooks/*.json`, and plugin manifests/settings belong to the selected Copilot agent/cloud/CLI surface, not a portable VS Code extension config. Agent `description`/other frontmatter is surface/version-specific; review these files manually and do not assume a required hook `version` or a VS Code user path.
- **sources**: [VS Code MCP](https://code.visualstudio.com/docs/agent-customization/mcp-servers), [custom instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions), [agent skills](https://code.visualstudio.com/docs/agent-customization/agent-skills), [prompt files](https://code.visualstudio.com/docs/agent-customization/prompt-files), [custom agents](https://code.visualstudio.com/docs/agent-customization/custom-agents), [hooks](https://code.visualstudio.com/docs/agent-customization/hooks), [profiles](https://code.visualstudio.com/docs/configure/profiles)
