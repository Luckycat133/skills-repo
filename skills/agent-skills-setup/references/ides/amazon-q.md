# amazon-q

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

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
- Standard IDE MCP uses `default.json` with JSON `mcpServers`; preserve an existing legacy `mcp.json` and merge only the server map.
- `agents/default.json` belongs to another Q/SageMaker surface. If it is the only file, stop for manual product selection; never flatten its prompts, tools, permissions, hooks, and MCP state.
- `.amazonq/` is mixed state, so whole-project migration is manual. Rules, prompts, personas, CLI agents, memory bank, hooks, and skills have no generic portable conversion.
- Q CLI agent files are distinct from IDE MCP and should not be treated as AWS CLI configuration.

Sources: [IDE MCP](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/mcp-ide.html), [project rules](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/context-project-rules.html), [MCP scopes](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/qdev-mcp.html).
