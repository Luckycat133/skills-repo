# mcphub-nvim

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**MCPHub.nvim** · Evidence: `documented-subset` · Runtime: `not-run`.

Manages MCP servers (`~/.config/mcphub/servers.json` and `.mcphub/servers.json` using JSON5/JSONC `mcpServers` + `nativeMCPServers`). Use `migrate_context.py patch-mcp --src-format jsonc` so `//` comments and trailing commas parse cleanly, strip `autoApprove` arrays, and keep Lua-defined `nativeMCPServers` unexecuted.

Official sources: [1](https://ravitemer.github.io/mcphub.nvim/configuration.html) · [2](https://ravitemer.github.io/mcphub.nvim/mcp/servers_json.html) · [3](https://github.com/ravitemer/mcphub.nvim)
