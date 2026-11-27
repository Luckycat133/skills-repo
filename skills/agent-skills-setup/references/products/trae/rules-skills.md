# TRAE (China & International): Rules, Skills, Commands & Agents

Parents: [trae-cn.md](../trae-cn.md) · [trae.md](../trae.md)

## Workspace vs User Paths

| Category | Project Path (Shared) | TRAE China User Path | TRAE International User Path |
| --- | --- | --- | --- |
| Always-on User Rules | — | `~/.trae-cn/user_rules.md` (legacy `~/.trae/user_rules*`) | `~/.trae/user_rules.md` (legacy `~/.trae/user_rules`) |
| Modular Rules | `.trae/rules/*.md` | `~/.trae-cn/rules/*.md` | `~/.trae/rules/*.md` |
| Agent Skills | `.trae/skills/<name>/SKILL.md` (plus `.agents/skills`) | `~/.trae-cn/skills/<name>/SKILL.md` | `~/.trae/skills/<name>/SKILL.md` |
| Commands | `.trae/commands/*.md` | `~/.trae-cn/commands/*.md` | `~/.trae/commands/*.md` |
| Custom Agents | `.trae/agents/*.md` | `~/.trae-cn/agents/*.md` | `~/.trae/agents/*.md` |

## Rule Activation & Exclusions

- Project/user rules in `.trae/rules/*.md` support:
  - Always Apply (`alwaysApply: true` or no trigger frontmatter)
  - Glob scoped (`globs: "..."` + `alwaysApply: false`)
  - Agent/Model decision (`description: "..."` + `alwaysApply: false`)
  - Manual (`@Rule`) — **do not widen manual `@Rule` entries into unconditional always-on instructions**.
- **Strict exclusions**: Built-in `trae-cn` and `trae` profiles always exclude `trae-jwt-token`, `builtin_skills/`, `builtin/`, `hub_event_cache/`, `permission/`, and auto-generated `memory/`.

Official sources: [TRAE CN Skills](https://docs.trae.cn/ide_skills) · [TRAE CN Rules](https://docs.trae.cn/ide_rules) · [TRAE Intl Docs](https://docs.trae.ai/)
