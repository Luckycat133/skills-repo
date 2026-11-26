# rovodev

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Atlassian Rovo Dev CLI, IDE and cloud** · Evidence: `documented-subset` · Runtime: `not-run`.

Rovo Dev CLI uses `.rovodev/skills/<name>/SKILL.md` and `.agents/skills`, `AGENTS.md`, `.rovodev/prompts.yml` (preserve YAML args and relative `.md` links), subagents (`.rovodev/subagents/`), and `~/.rovodev/config.yml` (read its `mcpConfigPath` rather than guessing `mcp.json` vs `mcp_config.json`, then patch via `patch-mcp`). Keep Rovo Studio / A2A AgentCard skills, IDE/cloud settings, and Atlassian auth tokens separate.

Official sources: [1](https://support.atlassian.com/rovo/docs/extend-rovo-dev-cli-with-agent-skills/) · [2](https://support.atlassian.com/rovo/docs/manage-rovo-dev-cli-settings/) · [3](https://support.atlassian.com/rovo/docs/connect-to-an-mcp-server-in-rovo-dev-cli/) · [4](https://support.atlassian.com/rovo/docs/use-subagents-in-rovo-dev-cli/)
