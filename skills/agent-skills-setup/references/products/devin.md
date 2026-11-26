# devin

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Devin CLI, Desktop Local and Cloud** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: User config `~/.config/devin/config.json` (Windows `%APPDATA%\devin\config.json`), project `.devin/config.json`; Project MCP `.devin/mcp_config.json` (`mcpServers` — compatible with `migrate_context.py patch-mcp`); Rules via global/project `AGENTS.md`, Skills, subagent profiles, hooks, and plugins. Cloud Knowledge, Playbooks, and schedules are UI/API objects.
- **Cautions & check**: Never invoke `/handoff` (network/cloud session transfer) as a local file migration step; exclude auth, sandbox grants, and session state. Verify CLI vs Desktop Local discovery separately.

Official sources: [1](https://docs.devin.ai/cli/extensibility/configuration) · [2](https://docs.devin.ai/cli/extensibility/rules) · [3](https://docs.devin.ai/cli/extensibility/index) · [4](https://docs.devin.ai/cli/handoff)
