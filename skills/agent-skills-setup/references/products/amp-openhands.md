# Amp and OpenHands

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## amp

**Amp CLI/editor/cloud surfaces** · Evidence: `documented-subset` · Runtime: `not-run`.

Distinct from Sourcegraph Cody. Inventory hierarchical `AGENTS.md`, Skills (`.agents/skills/<name>/SKILL.md`, `~/.config/agents/skills`, `.claude/skills` compatibility, plus MCP servers bundled inside Skills), `amp.mcpServers` in `~/.config/amp/settings.json` (patch via `patch-mcp --src-key-path amp.mcpServers`), TypeScript plugins, subagents, and permissions. Keep TS plugins unexecuted, reauthorize OAuth, and exclude cloud threads/schedules.

Official sources: [1](https://ampcode.com/docs) · [2](https://ampcode.com/docs/customize/skills) · [3](https://ampcode.com/docs/customize/mcp)

## openhands

**OpenHands local CLI, SDK, hosted app and agent canvas** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory `AGENTS.md`, `.agents/skills/<name>/SKILL.md`, `~/.openhands/skills` (legacy `.openhands/microagents/*.md` and `.openhands/skills`), CLI/SDK MCP config, hooks, and setup scripts. In OpenHands Skills, `paths` (file-encounter binding) takes precedence over keyword `triggers`, while legacy triggerless microagents load unconditionally — preserve trigger frontmatter so behavior does not silently widen, and exclude condenser memory/sessions.

Official sources: [1](https://docs.openhands.dev/overview/skills) · [2](https://docs.openhands.dev/)
