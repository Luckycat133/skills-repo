# Kiro: Steering Modes & Agent Skills

Parent: [kiro.md](../kiro.md)

## Steering Files (`.kiro/steering/*.md`, `~/.kiro/steering/*.md`)

Kiro supports 4 steering `inclusion` modes via YAML frontmatter (plus root `AGENTS.md`):

| `inclusion` mode | Frontmatter keys | Semantic Equivalence |
| --- | --- | --- |
| `always` (default) | `inclusion: always` (or omitted) | Always-on project/user instruction |
| `fileMatch` | `inclusion: fileMatch` + `fileMatchPattern: ["*.ts", "src/api/**/*"]` (string or array) | Glob-scoped rule (`paths:` / `globs:` / `trigger: glob`) |
| `auto` | `inclusion: auto` + `description: "..."` | Model-selected rule / on-demand `SKILL.md` (`migrate_context.py` preserves `auto` round-trips) |
| `manual` | `inclusion: manual` | Explicit `#filename` / `/` invocation (`disable-model-invocation: true`) |

## Agent Skills & Specs

- **Skills**: Project `.kiro/skills/<name>/SKILL.md`, User `~/.kiro/skills/<name>/SKILL.md` (with progressive `scripts/`, `references/`, `assets/`).
- **Specs & Powers**: `.kiro/specs/` contains task artifacts (not global rules); **Kiro Powers** (`POWER.md`) bundle prompts, MCP, and hooks separately.

Official sources: [steering](https://kiro.dev/docs/steering) · [skills](https://kiro.dev/docs/skills) · [powers](https://kiro.dev/docs/)
