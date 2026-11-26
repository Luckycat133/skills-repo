# junie

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Junie IDE and CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Guidelines `.junie/guidelines.md` and `AGENTS.md`; Skills `.junie/skills/<name>/SKILL.md`, `~/.junie/skills/<name>/SKILL.md`; Agents `.junie/agents/*.md`, `~/.junie/agents/*.md`; IDE MCP `.junie/mcp/mcp.json` and `~/.junie/mcp/mcp.json` (`mcpServers`); CLI extensions/MCP require checking CLI version flags/env overrides. Built-in profile: `junie`.
- **Cautions & check**: Keep Junie's outbound MCP client config distinct from JetBrains IDE's inbound MCP server; map agent tool/Skill allowlists field-by-field without copying action approvals. Check `/skills` or IDE Skill list.

Official sources: [1](https://junie.jetbrains.com/docs/agent-skills.html) · [2](https://junie.jetbrains.com/docs/junie-cli-subagents.html) · [3](https://junie.jetbrains.com/docs/junie-ide-plugin.html) · [4](https://junie.jetbrains.com/docs/environment-variables.html)
