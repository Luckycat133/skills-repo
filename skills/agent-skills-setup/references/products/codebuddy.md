# codebuddy

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**CodeBuddy Code CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Instructions `CODEBUDDY.md` / `AGENTS.md`; Skills `.codebuddy/skills/<name>/SKILL.md`, `~/.codebuddy/skills/<name>/SKILL.md` (`$CODEBUDDY_CONFIG_DIR`, `context: fork`, Skill-scoped hooks); Commands `.codebuddy/commands/`, Agents `.codebuddy/agents/`, hooks inside `settings.json`, LSP, and MCP `.codebuddy/.mcp.json` / `$CODEBUDDY_CONFIG_DIR/.mcp.json` (`mcpServers`). Built-in profile: `codebuddy`.
- **Cautions**: Never carry `allowUntrustedFrontmatterHooks` trust flags or activate command/prompt/agent/HTTP hooks without explicit approval; do not mix CLI schemas with standalone IDE `RULE.mdc`.

Official sources: [1](https://www.codebuddy.cn/docs/cli/skills) · [2](https://www.codebuddy.cn/docs/cli/hooks) · [3](https://www.codebuddy.cn/docs/cli/plugins-reference)
