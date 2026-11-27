# augment-code

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Auggie CLI, Augment IDE and Cosmos** · Evidence: `documented-subset` · Runtime: `not-run` · Built-in profile: `augment-code` (`augment`, `auggie`).

- **Candidate paths & precedence traps**: Skills `~/.augment/skills/<name>/SKILL.md` and `.augment/skills/<name>/SKILL.md` (**user `~/.augment/skills` wins over workspace/compatibility roots** in Auggie CLI — opposite of most tools!); Rules `.augment/rules/*.md`, user `~/.augment/rules/*.md`, `AGENTS.md` / `CLAUDE.md` fallback (not concatenated), legacy `.augment-guidelines`; Commands `.augment/commands/`, `~/.augment/commands/`; Agents `.augment/agents/`; `mcpServers` in `.augment/settings.json` / `.augment/settings.local.json` / `~/.augment/settings.json` (patch subobject via `patch-mcp`).
- **Scope trap**: Augment **user rules always apply** — never move a file-scoped glob rule into user rules without explicit user consent to broaden scope. Exclude enterprise context indexes and Cosmos cloud state.

Official sources: [1](https://docs.augmentcode.com/cli/skills) · [2](https://docs.augmentcode.com/cli/rules) · [3](https://docs.augmentcode.com/)
