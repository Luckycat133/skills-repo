# continue

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Continue IDE extension and cn CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: `~/.continue/config.yaml` (Windows `%USERPROFILE%\.continue\config.yaml`); project `.continue/rules/*.md` (`globs`, `regex`, `alwaysApply`), `.continue/prompts/*.md`, `.continue/mcpServers/*.yaml` or YAML `mcpServers:`. Inspect legacy `config.json` / `config.ts` by version; never execute TS.
- **Cautions & check**: Context providers, MCP and prompts differ. Verify native Skill discovery before placing `SKILL.md`. Preserve `${{ secrets.NAME }}` and env bindings; never print secrets.

Official sources: [1](https://docs.continue.dev/customize/deep-dives/configuration) · [2](https://docs.continue.dev/customize/deep-dives/mcp) · [3](https://docs.continue.dev/customize/deep-dives/rules) · [4](https://docs.continue.dev/customize/prompts)
