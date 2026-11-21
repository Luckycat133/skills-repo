# Continue and Zed

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## continue

**Continue IDE extension and cn CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: `~/.continue/config.yaml` (Windows `%USERPROFILE%\.continue\config.yaml`); project `.continue/rules/*.md` (`globs`, `regex`, `alwaysApply`), `.continue/prompts/*.md`, `.continue/mcpServers/*.yaml` or YAML `mcpServers:`. Inspect legacy `config.json` / `config.ts` by version; never execute TS.
- **Cautions & check**: Context providers, MCP and prompts differ. Verify native Skill discovery before placing `SKILL.md`. Preserve `${{ secrets.NAME }}` and env bindings; never print secrets.

Official sources: [1](https://docs.continue.dev/customize/deep-dives/configuration) · [2](https://docs.continue.dev/customize/deep-dives/mcp) · [3](https://docs.continue.dev/customize/deep-dives/rules) · [4](https://docs.continue.dev/customize/prompts)

## zed

**Zed native agent versus external ACP agent** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Native Skills `.agents/skills/<name>/SKILL.md`, `~/.agents/skills/<name>/SKILL.md`; personal `~/.config/zed/AGENTS.md` (Windows `%APPDATA%\Zed\AGENTS.md`); project uses native first match ([1] below). MCP `context_servers` in project `.zed/settings.json` or user `~/.config/zed/settings.json` (JSONC; stdio `command: {"path", "args", "env"}`). Profile: `zed`.
- **Cautions & check**: Warn if a file outranks `AGENTS.md`. External ACP uses its own config. Defer restricted MCP rather than drop tool lists; preserve other settings.

Official sources: [1](https://zed.dev/docs/ai/instructions) · [2](https://zed.dev/docs/ai/skills) · [3](https://zed.dev/docs/ai/mcp) · [4](https://zed.dev/docs/ai/external-agents)
