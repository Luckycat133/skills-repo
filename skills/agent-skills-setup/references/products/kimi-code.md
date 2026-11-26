# kimi-code

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Kimi Code current CLI and IDE/ACP use** · Evidence: `version-sensitive` · Runtime: `not-run`.

- **Candidate paths & schemas**: Active home is `$KIMI_CODE_HOME` or **`~/.kimi-code`** (legacy `~/.kimi` is source-only fallback; shared `~/.agents/skills` stays under `$HOME`). Files: `~/.kimi-code/AGENTS.md` and workspace `AGENTS.md`; Skills `.kimi-code/skills/<name>/SKILL.md`, `~/.kimi-code/skills/<name>/SKILL.md`; MCP `.kimi-code/mcp.json` and `~/.kimi-code/mcp.json` (`mcpServers`); plus `config.toml`, `tui.toml`, plugins/commands/hooks. Built-in profile: `kimi-code` (`kimiai`).
- **Cautions**: Exclude sessions and provider API keys in `config.toml` unless authorized; for ACP, resolve the agent process's execution `HOME`.

Official sources: [1](https://moonshotai.github.io/kimi-code/en/configuration/data-locations.html) · [2](https://moonshotai.github.io/kimi-code/en/customization/skills) · [3](https://moonshotai.github.io/kimi-code/en/customization/mcp) · [4](https://moonshotai.github.io/kimi-code/en/guides/ides)
