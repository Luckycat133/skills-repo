# TRAE IDE and Work

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## trae-cn

**TRAE China IDE** · Evidence: `documented-subset` · Runtime: `not-run` · Built-in profile: `trae-cn`.

- **Candidate paths & schemas**:
  - Skills: `.trae/skills/<name>/SKILL.md` (and `.agents/skills`), user `~/.trae-cn/skills/<name>/SKILL.md` (macOS also supports custom sync via `sync-skills`).
  - Rules: `.trae/rules/*.md` (always, `globs`, `description` model mode), user `~/.trae-cn/user_rules.md` and `~/.trae-cn/rules/*.md` (legacy `~/.trae/user_rules*`); `@Rule` manual rules stay parked rather than widened.
  - Commands, agents, hooks & MCP: `.trae/{commands,agents,hooks.json,mcp.json}`, user `~/.trae-cn/{commands,agents,hooks.json}` (`~/.trae/hooks.json` legacy fallback), and global MCP `~/Library/Application Support/Trae CN/User/mcp.json` (macOS) / `~/.config/Trae CN/User/mcp.json` (Linux) / `%APPDATA%\Trae CN\User\mcp.json` (Windows).
- **Cautions**: Never widen `@Rule` manual rules into always-on instructions; keep hooks parked via `agent_handoff` unless `--activate-hooks`; built-in profile excludes `~/.trae-cn/trae-jwt-token`, `builtin_skills/`, `builtin/`, `hub_event_cache/`, `permission/`, and auto `memory/`.

Official sources: [1](https://docs.trae.cn/ide_skills) · [2](https://docs.trae.cn/ide_rules) · [3](https://docs.trae.cn/ide_changelog) · [4](https://docs.trae.cn/ide_automate-actions-with-hooks)

## trae

**TRAE International IDE and TRAE Agent CLI** · Evidence: `discovery-required` · Runtime: `not-run` · Built-in IDE profile: `trae`.

International TRAE IDE (`docs.trae.ai`, using `.trae/{skills,rules,commands,agents,hooks.json,mcp.json}` + `~/.trae/*` + OS `Trae/User/mcp.json`, covered by built-in `trae` while excluding `trae-jwt-token`, `builtin_skills`, caches, and auto `memory`) is distinct from TRAE China (`trae-cn`) and open-source `bytedance/trae-agent` CLI (`trae_config.yaml` / JSON). Inspect CLI vs IDE settings before writing, use `agent_handoff` for unverified fields, and never certify International TRAE from a China IDE run.

Official sources: [1](https://docs.trae.ai/) · [2](https://github.com/bytedance/trae-agent)

## trae-work

**TRAE Work** · Evidence: `documented-subset` · Runtime: `not-run`.

China TRAE Work supports `.trae/skills` and `.trae/rules` alongside Work/Code/Design context, integrations, and scheduled tasks (not purely UI-only, though International parity is unverified). Keep cloud memory, live task state, and scheduled triggers excluded or unregistered until approved, and verify loading in TRAE Work itself rather than TRAE IDE.

Official sources: [1](https://docs.trae.cn/work_skills) · [2](https://docs.trae.cn/work_rules)
