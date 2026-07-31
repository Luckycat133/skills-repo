# pieces (Pieces for Developers)

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
- **role**: PiecesOS + Pieces Desktop/CLI + editor integrations; Pieces is the local MCP **server/provider**, not a file-backed MCP client or portable Agent Skills host.
- **automatic migration**: **unsupported/empty for every object** (`skills`, `rules`, `prompts`, `mcp`, `config`, `project`, `project-mcp`, and `project-config`). The official docs do not define `~/.pieces`, `.pieces`, a `SKILL.md` directory, a project rules file, or a Pieces-owned MCP/config file; the mapper must not infer any of them.
- **MCP setup**: enable PiecesOS/LTM and configure the consuming client from PiecesOS/Desktop **Settings → MCP** (the active port/endpoint is copied from that UI), or use the Pieces CLI's `pieces mcp setup`. Current official examples include Streamable HTTP `http://localhost:39300/model_context_protocol/2025-03-26/mcp` and legacy SSE `http://localhost:39300/model_context_protocol/2024-11-05/sse`; the port may vary and these are server endpoints, not Pieces path mappings. Never rewrite the date or `/sse` path while migrating: obtain the target endpoint and transport from PiecesOS or the server owner. Sources: [Pieces MCP overview](https://docs.pieces.app/products/mcp), [Cursor setup](https://docs.pieces.app/products/mcp/cursor), [Claude Code setup](https://docs.pieces.app/products/mcp/claude-code), [Pieces CLI](https://docs.pieces.app/products/cli/get-started).
- **local data (reference only)**: PiecesOS stores its database/logs in platform-specific application data locations such as macOS `~/Library/com.pieces.os/`, Linux `~/.local/share/com.pieces.os/`, and the documented Windows application-data directory. These are non-portable databases, not skills/rules/config, and must never be migrated. Source: [Pieces on-device storage](https://docs.pieces.app/extensions-plugins/raycast/troubleshooting).
- **editor integrations**: Pieces' VS Code integration is an extension backed by PiecesOS; project materials are managed through the extension/Drive/Copilot rather than a documented `.pieces` project namespace. Source: [Pieces VS Code extension](https://docs.pieces.app/extensions-plugins/vscode).
