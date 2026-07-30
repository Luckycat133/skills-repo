# claude-desktop (Claude Desktop app)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | Not mapped |
| Project skills | Not mapped |
| Rules | Not mapped |
| MCP | darwin: `~/Library/Application Support/Claude/claude_desktop_config.json`<br>windows: `%APPDATA%\Claude\claude_desktop_config.json` |
| Project MCP | Not mapped |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **Automatic migration**: the mapper supports the legacy JSON `claude_desktop_config.json` path on macOS and Windows, but the modern Extension / `.mcpb` / Remote Connector flow remains UI-installed. The mapper never guesses Linux or Windows MSIX virtualized paths.
- **Legacy local MCP JSON** (still documented and writable): macOS `~/Library/Application Support/Claude/claude_desktop_config.json`; native Windows `%APPDATA%\Claude\claude_desktop_config.json`; root key `mcpServers` · JSON. This is an *alternative* to UI installation and is one of the two supported mechanisms in the current docs (the file also accepts remote MCP server entries with URL/SSE transports). The [MCP protocol guide](https://modelcontextprotocol.io/docs/develop/connect-local-servers) documents the platform file locations; the current local-server help page describes the product workflow.
- **Modern local MCP** (UI / Extension flow): **Settings → Extensions → Advanced settings → Install Extension** for a custom `.mcpb` package. `.mcpb` is the packaged extension format with a manifest and server files; do not unpack it into a guessed Skills/config directory. Sensitive fields marked `"sensitive": true` are encrypted by the OS keychain (macOS Keychain, Windows Credential Manager, Linux distro keychain). Sources: [local MCP servers](https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop), [MCPB](https://claude.com/docs/connectors/building/mcpb).
- **Remote MCP**: add via **Customize → Connectors → Add custom connector** in claude.ai / Cowork (or organization connector settings for Team/Enterprise). The Claude Desktop app's `claude_desktop_config.json` also accepts remote MCP server entries (URL/SSE transports) and is the on-device path for both *local* and *remote* MCP servers; remote connector traffic otherwise originates from Anthropic's cloud. The migration script only writes the local JSON path; remote URL config handled via the Cowork UI is left to the user. Source: [remote MCP connectors](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp).
- **Claude Code import**: on macOS/WSL, `claude mcp add-from-claude-desktop` is the official interactive import; it is not a portable Desktop package export. Source: [Claude Code MCP](https://code.claude.com/docs/en/mcp).
- Other migration objects: unsupported (desktop app; no project-level context mapping).
