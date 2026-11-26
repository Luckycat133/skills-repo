# codecompanion-nvim

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**CodeCompanion.nvim** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & `.mdc` scope trap**: Supports rules (`AGENTS.md`, `CLAUDE.md`, configured rule groups), Skills (`.agents/skills/<name>/SKILL.md`), prompt library, workflows, HTTP/ACP adapters, and MCP. Adding `.cursor/rules/**/*.mdc` to an autoload rule group **ignores Cursor `globs`/`alwaysApply`**, silently making scoped rules unconditional — park or bind scoped rules explicitly, and never execute Lua callbacks during transfer.

Official sources: [1](https://codecompanion.olimorris.dev/guides/sharing-rules-and-skills) · [2](https://codecompanion.olimorris.dev/configuration/mcp) · [3](https://codecompanion.olimorris.dev/usage/skills)
