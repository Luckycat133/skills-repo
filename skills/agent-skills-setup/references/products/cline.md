# cline

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Cline IDE, CLI and SDK** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Rules `.cline/rules/*.md` (legacy `.clinerules` file or `.clinerules/*.md`), `~/.cline/rules/*.md`; Skills `.cline/skills/<name>/SKILL.md` (plus `.agents/skills`), `~/.cline/skills/<name>/SKILL.md`; Workflows `.cline/workflows/*.md` (legacy `.clinerules/workflows/`), `~/.cline/workflows/*.md`; Hooks `.cline/hooks/` (legacy `.clinerules/hooks/`), `~/.cline/hooks/`; User MCP `~/.cline/data/settings/cline_mcp_settings.json` (`CLINE_MCP_SETTINGS_PATH` override supported, `mcpServers` root key). Built-in profile: `cline`.
- **Deep dives (progressive load per category)**: [Rules, Workflows & Hooks](cline/rules-workflows-hooks.md) · [MCP](cline/mcp.md).
- **Cautions & check**: Extract **only** `mcpServers` from `cline_mcp_settings.json` — strictly exclude `~/.cline/data/tasks`, `state`, histories, `alwaysAllow` grants, and active hooks/cron. Verify discovery in Cline's customization view.

Official sources: [1](https://docs.cline.bot/getting-started/config) · [2](https://docs.cline.bot/features/skills) · [3](https://docs.cline.bot/features/cline-rules)
