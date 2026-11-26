# mistral-vibe

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Mistral Vibe Code and Vibe Work** · Evidence: `documented-subset` · Runtime: `not-run`.

Keep Vibe Code (CLI/IDE/web) distinct from Vibe Work. Vibe Code uses `~/.vibe/config.toml` and `.vibe/config.toml` (TOML `mcp_servers`, agents, skill paths), Skills in `.vibe/skills/<name>/SKILL.md`, `~/.vibe/skills`, and `.agents/skills`, plus agents, hooks, and plugins. Preserve `user-invocable` vs model-selected flags, check user-vs-plugin MCP shadowing, and exclude approval state.

Official sources: [1](https://docs.mistral.ai/vibe/code/overview) · [2](https://docs.mistral.ai/vibe/code/cli/configuration) · [3](https://docs.mistral.ai/vibe/code/cli/skills) · [4](https://docs.mistral.ai/vibe/code/cli/agents) · [5](https://docs.mistral.ai/vibe/code/cli/plugins)
