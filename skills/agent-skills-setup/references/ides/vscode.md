# vscode (VS Code + GitHub Copilot IDE; not the `copilot` CLI target)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

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
- Workspace MCP is `.vscode/mcp.json` with `servers`. User MCP is active-Profile/UI managed: use **MCP: Open User Configuration**, never guess a default, Insiders, VSCodium, or relocated path.
- Keep explicit `http`/legacy `sse` types, re-authorize OAuth, and fail closed on foreign schemas. This differs from CLI `mcpServers`.
- Rules include `.github/copilot-instructions.md` and scoped instruction files; project prompts are `.github/prompts/*.prompt.md`. User prompt paths, extensions, agents, hooks, plugins, and their storage remain manual.
- The `copilot` mapper key is GitHub Copilot CLI, not this VS Code surface.

Sources: [MCP](https://code.visualstudio.com/docs/agent-customization/mcp-servers), [instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions), [Skills](https://code.visualstudio.com/docs/agent-customization/agent-skills), [prompts](https://code.visualstudio.com/docs/agent-customization/prompt-files), [profiles](https://code.visualstudio.com/docs/configure/profiles).
