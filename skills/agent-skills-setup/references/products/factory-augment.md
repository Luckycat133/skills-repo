# Factory Droid and Augment

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## factory-droid

**Factory Droid CLI, desktop and cloud** · Evidence: `documented-subset` · Runtime: `not-run`.

Binary is `droid` (not `factory`). Inventory `AGENTS.md`, `.factory/skills/<name>/SKILL.md`, `~/.factory/skills`, custom droids (`.factory/droids/*.md`, `~/.factory/droids/*.md`), commands (`.factory/commands/`), hooks, `~/.factory/mcp.json` / `.factory/mcp.json` (`mcpServers` via `patch-mcp`), and `.factory-plugin/plugin.json` bundles. When a user requests only a Skill from a plugin bundle, copy only that Skill + inert resources and leave bundled hooks/MCP inactive.

Official sources: [1](https://docs.factory.com/harness/skills) · [2](https://docs.factory.com/harness/plugins) · [3](https://docs.factory.com/harness/subagents) · [4](https://docs.factory.com/droid-cli/overview)

## augment-code

**Auggie CLI, Augment IDE and Cosmos** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & precedence traps**: Skills `~/.augment/skills/<name>/SKILL.md` and `.augment/skills/<name>/SKILL.md` (**user `~/.augment/skills` wins over workspace/compatibility roots** in Auggie CLI — opposite of most tools!); Rules `.augment/rules/*.md`, user rules, `AGENTS.md` / `CLAUDE.md` fallback (not concatenated), legacy `.augment-guidelines`; Commands `.augment/commands/`, Agents `.augment/agents/`, and `mcpServers` in `~/.augment/settings.json` (patch subobject via `patch-mcp`).
- **Scope trap**: Augment **user rules always apply** — never move a file-scoped glob rule into user rules without explicit user consent to broaden scope. Exclude enterprise context indexes and Cosmos cloud state.

Official sources: [1](https://docs.augmentcode.com/cli/skills) · [2](https://docs.augmentcode.com/cli/rules) · [3](https://docs.augmentcode.com/)
