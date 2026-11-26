# cline

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Cline IDE, CLI and SDK** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Rules `.clinerules` (file or `.clinerules/*.md`), `.cline/rules/*.md`, `~/.cline/rules/*.md`; Skills `.cline/skills/<name>/SKILL.md`, `~/.cline/skills/<name>/SKILL.md`; Workflows `.cline/workflows/*.md`, `~/.cline/workflows/*.md`; Hooks `.cline/hooks/`, `~/.cline/hooks/`; Agents/plugins/cron under `~/.cline/`; User MCP `~/.cline/data/settings/cline_mcp_settings.json` (`mcpServers` root key). Built-in profile: `cline`.
- **Cautions & check**: Extract **only** `mcpServers` from `cline_mcp_settings.json` — strictly exclude `~/.cline/data/tasks`, `state`, histories, `alwaysAllow` grants, and active hooks/cron. Verify discovery in Cline's customization view.

Official sources: [1](https://docs.cline.bot/getting-started/config) · [2](https://docs.cline.bot/features/skills) · [3](https://docs.cline.bot/features/cline-rules)
