# Cline, Kilo and Roo

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## cline

**Cline IDE, CLI and SDK** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Rules `.clinerules` (file or `.clinerules/*.md`), `.cline/rules/*.md`, `~/.cline/rules/*.md`; Skills `.cline/skills/<name>/SKILL.md`, `~/.cline/skills/<name>/SKILL.md`; Workflows `.cline/workflows/*.md`, `~/.cline/workflows/*.md`; Hooks `.cline/hooks/`, `~/.cline/hooks/`; Agents/plugins/cron under `~/.cline/`; User MCP `~/.cline/data/settings/cline_mcp_settings.json` (`mcpServers` root key). Built-in profile: `cline`.
- **Cautions & check**: Extract **only** `mcpServers` from `cline_mcp_settings.json` — strictly exclude `~/.cline/data/tasks`, `state`, histories, `alwaysAllow` grants, and active hooks/cron. Verify discovery in Cline's customization view.

Official sources: [1](https://docs.cline.bot/getting-started/config) · [2](https://docs.cline.bot/features/skills) · [3](https://docs.cline.bot/features/cline-rules)

## kilocode

**Kilo IDE and CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Skills `.kilo/skills/<name>/SKILL.md`, `~/.kilo/skills/<name>/SKILL.md` (plus `.agents`/`.claude` compatibility and legacy `.kilocode/skills`); Rules `.kilo/rules/*.md`, `~/.kilo/rules/*.md`, `AGENTS.md`; Agents `.kilo/agents/*.md`, `~/.kilo/agents/*.md` (legacy custom modes `.kilocodemodes` are a different schema); Workflows `.kilo/workflows/*.md`, `~/.kilo/workflows/*.md`; Config/MCP `kilo.jsonc` and `.kilo/mcp.json` / `~/.kilo/mcp.json` (`mcpServers` or native command arrays — inspect active file). Built-in profile: `kilocode` (`kilo`).
- **Cautions & check**: Check workflow vs Skill slash-command collisions, keep dynamic shell blocks inactive, and strip tool auto-approvals.

Official sources: [1](https://kilo.ai/docs/customize/skills) · [2](https://kilo.ai/docs/customize/custom-modes) · [3](https://kilo.ai/docs/customize/workflows) · [4](https://kilo.ai/articles/claude-code-to-kilo-code-migration-guide)

## roo-code

**Roo Code archived upstream; installed forks remain version-specific** · Evidence: `legacy-source` · Runtime: `not-run`.

Upstream `RooCodeInc/Roo-Code` archived 2026-05-15; built-in profile `roo-code` (`roo`) reads/syncs `.roo/{skills,rules,mcp.json}` and `~/.roo/{skills,rules}` (use `patch-mcp` for VS Code `globalStorage` `mcp_settings.json`). Preserve mode-specific vs generic precedence and never map `.roomodes` custom-mode tool groups as blanket target permissions.

Official sources: [1](https://github.com/RooCodeInc/Roo-Code) · [2](https://roocodeinc.github.io/Roo-Code/features/skills/)
