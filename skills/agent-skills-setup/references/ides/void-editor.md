# void-editor

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | Not mapped |
| Project skills | Not mapped |
| Rules | `.voidrules` |
| MCP | `~/.void-editor/mcp.json` |
| Project MCP | `.vscode/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **status**: the official repository (`voideditor/void`) was archived by the owner on 2026-06-02 and is now read-only; the most recent published GitHub release is **v1.3.4** dated 2026-04-15 (pre-archive), and there have been no post-archive release tags. Release notes and prior Discord-community references still mention weekly contribution meetings, which describe pre-archive activity and do not contradict the read-only status. The official website still advertises a beta, but the source-of-truth repository is closed; treat the Void-specific store as a legacy target and do not copy its whole data directory.
- **mcp (Void-specific)**: global `~/.void-editor/mcp.json` · root key `mcpServers` · JSON · local `command`/`args`/`env`; remote `url` is recognized, but authenticated/header-bearing remote entries are manual because the archived runtime does not reliably pass headers to the transport
- **mcp (inherited VS Code)**: project `.vscode/mcp.json` with root key `servers`, plus profile/UI-managed user MCP and multi-root workspace settings; this is a distinct inherited VS Code surface and is diagnostic/manual here, never written by the Void-specific global converter
- **rules**: `.voidrules` is read at the workspace-folder root and concatenated across multi-root folders; it is plain text/Markdown without a frontmatter contract. Global AI Instructions remain UI-managed.
- **skills/config/commands/agents/hooks/memory**: no first-party portable Agent Skills, whole-config, user command, agent, hook, or portable memory path was established; manual/UI only
- **sources**: [Void official site](https://voideditor.com/), [Void repository](https://github.com/voideditor/void), [Void releases](https://github.com/voideditor/void/releases), [product.json](https://raw.githubusercontent.com/voideditor/void/main/product.json), [custom MCP service](https://github.com/voideditor/void/blob/main/src/vs/workbench/contrib/void/common/mcpService.ts), [native MCP discovery](https://github.com/voideditor/void/blob/main/src/vs/workbench/contrib/mcp/common/discovery/configMcpDiscovery.ts), [`.voidrules` consumer](https://github.com/voideditor/void/blob/main/src/vs/workbench/contrib/void/browser/convertToLLMMessageService.ts), [Void changelog](https://voideditor.com/changelog)

---
