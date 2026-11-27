# factory-droid

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Factory Droid CLI, desktop and cloud** · Evidence: `documented-subset` · Runtime: `not-run`.

Binary is `droid` (not `factory`). Built-in profile: `factory-droid` (`droid`). Inventory `AGENTS.md`, `.factory/skills/<name>/SKILL.md`, `~/.factory/skills` (plus `.agents/skills`, `~/.agents/skills`), custom droids (`.factory/droids/*.md`, `~/.factory/droids/*.md`), commands (`.factory/commands/`, `~/.factory/commands/`), hooks (`.factory/hooks.json`, `~/.factory/hooks.json`, parked via `agent_handoff`), `~/.factory/mcp.json` / `.factory/mcp.json` (`mcpServers`), and `.factory-plugin/plugin.json` bundles. When a user requests only a Skill from a plugin bundle, copy only that Skill + inert resources and leave bundled hooks/MCP inactive.

Official sources: [1](https://docs.factory.com/harness/skills) · [2](https://docs.factory.com/harness/plugins) · [3](https://docs.factory.com/harness/subagents) · [4](https://docs.factory.com/droid-cli/overview)
