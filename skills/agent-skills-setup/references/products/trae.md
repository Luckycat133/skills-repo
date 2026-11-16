# TRAE IDE and Work

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## trae-cn

**TRAE China IDE** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Skills `.trae/skills/<name>/SKILL.md` and user Skills; Rules `.trae/rules/*.md` (legacy `project_rules.md`) with always, file-glob, model, and `@Rule` manual modes; Commands, subagents, hooks (`.trae/hooks.json`), and MCP (`mcpServers` in IDE/project config — patch via `patch-mcp`).
- **Cautions**: Never widen `@Rule` manual rules into always-on instructions, never copy `.trae` generated state/auto-Memory wholesale, and keep hooks parked until approved.

Official sources: [1](https://docs.trae.cn/ide_skills) · [2](https://docs.trae.cn/ide_rules) · [3](https://docs.trae.cn/ide_changelog) · [4](https://docs.trae.cn/ide_automate-actions-with-hooks)

## trae

**TRAE International IDE and TRAE Agent CLI** · Evidence: `discovery-required` · Runtime: `not-run`.

International TRAE IDE (`docs.trae.ai`) and open-source `bytedance/trae-agent` CLI (`trae_config.yaml` / JSON) are distinct from TRAE China IDE; do not assume identical MCP, hook, or memory schemas across regions or between CLI and IDE. Inspect the installed build's settings/schema before writing, park drafts when docs are inaccessible, and never certify International TRAE from a China IDE run.

Official sources: [1](https://docs.trae.ai/) · [2](https://github.com/bytedance/trae-agent)

## trae-work

**TRAE Work** · Evidence: `documented-subset` · Runtime: `not-run`.

China TRAE Work supports `.trae/skills` and `.trae/rules` alongside Work/Code/Design context, integrations, and scheduled tasks (not purely UI-only, though International parity is unverified). Keep cloud memory, live task state, and scheduled triggers excluded or unregistered until approved, and verify loading in TRAE Work itself rather than TRAE IDE.

Official sources: [1](https://docs.trae.cn/work_skills) · [2](https://docs.trae.cn/work_rules)
