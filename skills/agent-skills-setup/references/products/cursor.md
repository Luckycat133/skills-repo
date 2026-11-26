# cursor

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Cursor IDE, CLI and cloud agents** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Rules `.cursor/rules/*.mdc` (legacy `.cursorrules`), root/nested `AGENTS.md`; Skills `.cursor/skills/<name>/SKILL.md`, `~/.cursor/skills/<name>/SKILL.md`; Commands `.cursor/commands/*.md`, `~/.cursor/commands/*.md`; Agents `.cursor/agents/*.md`, `~/.cursor/agents/*.md`; Hooks `.cursor/hooks.json`, `~/.cursor/hooks.json`; MCP `.cursor/mcp.json` and `~/.cursor/mcp.json` (`mcpServers` root key, `${VAR}` env interpolation, `url` + `headers` for HTTP/SSE). Built-in profile: `migrate_context.py --source/--target cursor`.
- **Activation & scope**: In `.mdc` frontmatter, `alwaysApply: true` wins over `globs`; unquoted (`globs: *.py`), comma-separated (`src/**/*.ts, tests/**/*.ts`), or brace globs are pattern-scoped; `description` alone is model-selected; `alwaysApply: false` with neither `globs` nor `description` is manual (`@rule`). Plain `.md` beside `.mdc` is not auto-loaded as a Cursor rule. User settings, project rules, and cloud agent setup are separate scopes.
- **Migration cautions**: Rule/command-to-Skill conversion applies to on-demand/manual items (`disable-model-invocation: true` for manual-only), never blanket conversion of always-on or glob rules. Keep hooks and shell-evaluated Skill blocks parked until approved; exclude `~/.cursor` SQLite/workspace state and cloud connectors.
- **Check**: Cursor rule type badge, matching vs non-matching path behavior, Skill listing, and `mcp.json` parse without auto-connecting.

Official sources: [1](https://cursor.com/docs/rules) · [2](https://cursor.com/docs/skills) · [3](https://cursor.com/docs/hooks) · [4](https://cursor.com/docs/mcp) · [5](https://cursor.com/docs/customize-cursor)
