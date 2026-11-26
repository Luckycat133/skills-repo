# trae-cn

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**TRAE China IDE** · Evidence: `documented-subset` · Runtime: `not-run` · Built-in profile: `trae-cn`.

- **Candidate paths & schemas**:
  - Skills: `.trae/skills/<name>/SKILL.md` (and `.agents/skills`), user `~/.trae-cn/skills/<name>/SKILL.md` (macOS also supports custom sync via `sync-skills`).
  - Rules: `.trae/rules/*.md` (always, `globs`, `description` model mode), user `~/.trae-cn/user_rules.md` and `~/.trae-cn/rules/*.md` (legacy `~/.trae/user_rules*`); `@Rule` manual rules stay parked rather than widened.
  - Commands, agents, hooks & MCP: `.trae/{commands,agents,hooks.json,mcp.json}`, user `~/.trae-cn/{commands,agents,hooks.json}` (`~/.trae/hooks.json` legacy fallback), and global MCP `~/Library/Application Support/Trae CN/User/mcp.json` (macOS) / `~/.config/Trae CN/User/mcp.json` (Linux) / `%APPDATA%\Trae CN\User\mcp.json` (Windows).
- **Cautions**: Never widen `@Rule` manual rules into always-on instructions; keep hooks parked via `agent_handoff` unless `--activate-hooks`; built-in profile excludes `~/.trae-cn/trae-jwt-token`, `builtin_skills/`, `builtin/`, `hub_event_cache/`, `permission/`, and auto `memory/`.

Official sources: [1](https://docs.trae.cn/ide_skills) · [2](https://docs.trae.cn/ide_rules) · [3](https://docs.trae.cn/ide_changelog) · [4](https://docs.trae.cn/ide_automate-actions-with-hooks)
