# zed

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Zed native agent versus external ACP agent** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Native Skills `.agents/skills/<name>/SKILL.md`, `~/.agents/skills/<name>/SKILL.md`; personal `~/.config/zed/AGENTS.md` (Windows `%APPDATA%\Zed\AGENTS.md`); project uses native first match ([1] below). MCP `context_servers` in project `.zed/settings.json` or user `~/.config/zed/settings.json` (JSONC; stdio `command: {"path", "args", "env"}`). Profile: `zed`.
- **Cautions & check**: Warn if a file outranks `AGENTS.md`. External ACP uses its own config. Defer restricted MCP rather than drop tool lists; preserve other settings.

Official sources: [1](https://zed.dev/docs/ai/instructions) · [2](https://zed.dev/docs/ai/skills) · [3](https://zed.dev/docs/ai/mcp) · [4](https://zed.dev/docs/ai/external-agents)
