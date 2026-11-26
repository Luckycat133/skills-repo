# pi

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Pi coding agent** · Evidence: `version-sensitive` · Runtime: `not-run`.

- **Candidate paths & schemas**: Native MCP `~/.pi/agent/mcp.json` and `.pi/mcp.json` (`mcpServers`; sparse project knob-only overrides such as `{"enabled": false}` inherit user server connection fields — **never** discard them as malformed!); Instructions `AGENTS.md`, `~/.pi/agent/AGENTS.md`; Skills `.pi/skills/<name>/SKILL.md`, `~/.pi/agent/skills/<name>/SKILL.md`, `.agents/skills` (`disable-model-invocation` supported); Prompts `.pi/prompts/*.md`, `~/.pi/agent/prompts/*.md`. Built-in profile: `pi`.
- **Cautions**: Keep TypeScript extensions/packages inactive during transfer and never copy project trust or OAuth tokens.

Official sources: [1](https://pi.dev/docs/latest/skills) · [2](https://pi.dev/docs/latest/mcp) · [3](https://pi.dev/docs/latest/extensions)
