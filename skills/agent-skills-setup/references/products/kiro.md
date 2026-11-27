# kiro

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Kiro IDE, CLI, web/mobile and Crew** · Evidence: `version-sensitive` · Runtime: `not-run`.

- **Candidate paths & schemas**: Steering `.kiro/steering/*.md` and `~/.kiro/steering/*.md` (`inclusion: always | fileMatch | auto | manual`, `fileMatchPattern`); `AGENTS.md`; Skills `.kiro/skills/<name>/SKILL.md`, `~/.kiro/skills/<name>/SKILL.md`; MCP `.kiro/settings/mcp.json` and `~/.kiro/settings/mcp.json` (`mcpServers`); Specs (`.kiro/specs/`), Powers, hooks (`.kiro/hooks/`), and CLI custom agents (`.kiro/agents/`). Built-in profile: `kiro` (`kiro-cli`).
- **Version & surface traps**: CLI 3 agent permissions/inclusion differ from CLI 2 (`allowedTools`/`toolsSettings`) — match installed CLI major version and note CLI custom agents only load declared Skill resources. Keep Specs (task artifacts), Powers, Crew scope, and inactive hook drafts separate.
- **Deep dives (progressive load per category)**: [Steering & Skills](kiro/steering-skills.md) · [Agents, Hooks & MCP](kiro/agents-hooks-mcp.md).

Official sources: [1](https://kiro.dev/docs/steering) · [2](https://kiro.dev/docs/skills) · [3](https://kiro.dev/docs/custom-agents) · [4](https://kiro.dev/docs/mcp/configuration) · [5](https://kiro.dev/docs/)
