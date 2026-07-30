# sourcegraph-cody

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | Not mapped |
| Project skills | Not mapped |
| Rules | Not mapped |
| MCP | Not mapped |
| Project MCP | Not mapped |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **status**: Current official docs support Cody on Sourcegraph Enterprise (VS Code, JetBrains, Visual Studio, Web, and an experimental CLI). Free, Pro, and Enterprise Starter access ended July 23, 2025; Amp is the documented replacement for those tiers. See [Cody](https://sourcegraph.com/docs/cody), [Cody FAQs](https://sourcegraph.com/docs/cody/faq), and [Cody clients](https://sourcegraph.com/docs/cody/clients).
- **mcp**: unsupported for automatic file migration. Cody MCP is configured in the editor extension setting `cody.mcpServers` (VS Code `settings.json` or JetBrains `cody_settings.json`), or through the Cody MCP Settings UI; it is disabled by default, supports local servers and tools only, and requires the Enterprise `agentic-context-mcp-enabled` feature flag. See [Agentic Context Fetching](https://sourcegraph.com/docs/cody/capabilities/agentic-context-fetching). No portable standalone Cody MCP file is established here.
- **commands/prompts**: manual only. Current Cody prompts are created and stored in the Enterprise Prompt Library; the docs link legacy custom-command migration to that library and do not establish a portable workspace command file. See [Prompts](https://sourcegraph.com/docs/cody/capabilities/prompts).
- **skills/agents/rules/config/project**: unsupported/manual. Current official docs do not establish Cody Agent Skills, subagent definitions, `.codyrules`, a portable whole-Cody config file, or a portable project-instructions file. Do not infer `.cody`, `.codyrules`, `~/.config/cody/`, `~/.vscode/cody.json`, or `.vscode/cody.json` as automatic targets.
- **related product**: Sourcegraph MCP Server is a separate Enterprise server for external agents; it is configured in the client (for example `amp mcp add`), not as Cody's local MCP store. See [Sourcegraph MCP Server](https://sourcegraph.com/docs/api/mcp).

---
