# zcode

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Z.ai ZCode** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & precedence trap**: Skills `.zcode/skills/<name>/SKILL.md`, `~/.zcode/skills/<name>/SKILL.md` (check documented body-size cap and flat plugin Skill discovery); Rules `AGENTS.md` / `.zcode/rules`; Plugins root `plugin.json` (legacy `.zcode-plugin`); MCP `.zcode/mcp.json` and `~/.zcode/mcp.json` (`mcpServers`).
- **Scope-level shadowing**: Native `.zcode` MCP config **suppresses** shared `.agents/mcp.json` at the scope level rather than merging server-by-server — merge explicitly with `patch-mcp` after user confirmation.

Official sources: [1](https://zcode.z.ai/en/docs/skill) · [2](https://zcode.z.ai/en/docs/mcp-services) · [3](https://zcode.z.ai/en/docs/plugin)
