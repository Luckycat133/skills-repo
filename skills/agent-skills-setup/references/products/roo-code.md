# roo-code

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Roo Code archived upstream; installed forks remain version-specific** · Evidence: `legacy-source` · Runtime: `not-run`.

Upstream `RooCodeInc/Roo-Code` archived 2026-05-15; built-in profile `roo-code` (`roo`) reads/syncs `.roo/{skills,rules,mcp.json}`, `~/.roo/{skills,rules}`, and legacy `.roorules` (use `patch-mcp` for VS Code `globalStorage` `mcp_settings.json`). `.roo/rules/` is unconditional (no verified file-glob YAML frontmatter), so glob-scoped source rules emit `agent_handoff` rather than silently widening. Preserve mode-specific vs generic precedence and never map `.roomodes` custom-mode tool groups as blanket target permissions.

Official sources: [1](https://github.com/RooCodeInc/Roo-Code) · [2](https://roocodeinc.github.io/Roo-Code/features/skills/)
