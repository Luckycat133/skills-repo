# amazon-q

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | Not mapped |
| Project skills | Not mapped |
| Rules | `.amazonq/rules` |
| MCP | `~/.aws/amazonq/default.json` |
| Project MCP | `.amazonq/default.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.aws/amazonq/`
- **project namespace**: `.amazonq/` (manual/diagnostic only; it contains separate rules and MCP scopes and must not be copied as one opaque directory)
- **mcp (standard IDE)**: global `~/.aws/amazonq/default.json` and project `.amazonq/default.json`; legacy global/project `mcp.json` are also documented, with root key `mcpServers` · JSON. The mapper uses `default.json` for a fresh install, preserves an existing legacy `mcp.json`, and narrows automatic migration to the `mcpServers` map while retaining other fields. Legacy behavior is controlled by `useLegacyMcpJson` in the applicable default configuration.
- **ambiguous Q surface**: another AWS overview/SageMaker surface names global `~/.aws/amazonq/agents/default.json` and `.amazonq/agents/default.json`; AWS publishes no version discriminator that lets this mapper equate it with the standard IDE file. If it is the only existing file, migration stops for manual product selection. These files can combine prompt, tools, permissions, resources, hooks, and `mcpServers` and must not be flattened automatically.
- **rules (IDE)**: project `.amazonq/rules/*.md` · Markdown files · directory migration is manual because the generic mapper only copies one file
- **prompts (IDE)**: global `~/.aws/amazonq/prompts/*.md` · `@PromptName` in the IDE · global/cross-project and manual in this mapper
- **personas**: global `~/.aws/amazonq/personas/default.json` · project `.amazonq/personas/default.json`; permissions and MCP references are security-sensitive and manual
- **agents/MCP (CLI)**: global `~/.aws/amazonq/cli-agents/` · separate CLI custom-agent/MCP scope; manual only and never confused with generic AWS CLI configuration or IDE `default.json`
- **skills**: no official Amazon Q Agent Skills path was found in the primary AWS docs reviewed; registry and automatic mapper leave global/project skills empty
- **product boundary**: Q CLI agent files `~/.aws/amazonq/cli-agents/*.json` / `.amazonq/cli-agents/*.json` are historical CLI state, distinct from IDE `agents/default.json`; Q CLI is now superseded by Kiro.
- **memory bank (IDE)**: project `.amazonq/rules/memory-bank/` · generated Markdown under the project-rules namespace. The path is official, but generated content/lifecycle is not a portable cross-IDE memory contract; keep it manual and never copy the whole directory automatically.
- **config/hooks**: no portable whole-config or standalone hook path/schema established for this mapper; keep manual/empty
- **sources**: [MCP in the IDE](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/mcp-ide.html) · [project rules](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/context-project-rules.html) · [saved prompts](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/context-prompt-library.html) · [memory bank](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/context-memory-bank.html) · [MCP with Amazon Q / CLI and IDE scopes](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/qdev-mcp.html) · [AWS language-server MCP source](https://raw.githubusercontent.com/aws/language-servers/main/server/aws-lsp-codewhisperer/src/language-server/agenticChat/tools/mcp/mcpUtils.ts) · [CLI agent locations](https://raw.githubusercontent.com/aws/amazon-q-developer-cli/main/docs/agent-file-locations.md) · [Amazon Q CLI repository](https://github.com/aws/amazon-q-developer-cli)
