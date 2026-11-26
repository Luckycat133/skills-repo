# ibm-bob

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**IBM Bob IDE and Bob Shell** · Evidence: `version-sensitive` · Runtime: `not-run`.

Separate Bob IDE from Bob Shell 1 vs Shell 2. Inventory `.bob/skills/<name>/SKILL.md`, `~/.bob/skills`, `.bob/rules*`, `AGENTS.md`, custom modes/subagents, `.bob/plugins` (`~/.bob/plugins`), and IDE global MCP `~/.bob/settings/mcp.json` (`mcpServers` via `patch-mcp`; check Bob Shell's own MCP path separately). Strip `alwaysAllow` and remembered tool approvals.

Official sources: [1](https://bob.ibm.com/docs/ide/features/skills) · [2](https://bob.ibm.com/docs/shell/features/skills) · [3](https://bob.ibm.com/docs/ide/configuration/mcp/mcp-in-bob) · [4](https://bob.ibm.com/docs/shell/configuration/mcp/mcp-bobshell) · [5](https://bob.ibm.com/blog/september-2026-release/)
