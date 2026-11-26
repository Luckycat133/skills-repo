# Rules and instructions: generic cross-IDE activation mapping

Read ONLY `references/products/<source>.md` and `references/products/<target>.md` (via
[products.md](products.md)) for exact file paths and frontmatter keys. This guide defines
the format-agnostic rules preserved by `migrate_context.py` and Agent handoff.

## Core activation modes & lossless conversion rules

| Source activation | Target conversion rule | Lossy case (`agent_handoff`) |
| --- | --- | --- |
| **Always-on** (root/global doc or unconditional rule) | Idempotent `<!-- agent-skills-setup:begin id=... -->` section merge; preserve local overrides (`AGENTS.override.md`, `CLAUDE.local.md`) | Shadowing warning when higher-priority root files exist (e.g. Zed `.rules` > `AGENTS.md`) |
| **File-pattern (`glob`)** (`.mdc` `globs`, Claude `paths`, VS Code `applyTo`, Windsurf/Antigravity `trigger: glob`, Kiro `fileMatchPattern`) | Translate to target's native pattern-scoped rule frontmatter | Target lacks file-glob rules or user scope always applies (Codex `AGENTS.md`, Augment user rules) — emit `agent_handoff` instead of widening |
| **Model-selected** (`description` + `alwaysApply: false` / `trigger: model_decision`) | Translate to native model-decision rule or on-demand `SKILL.md` (`name` + `description`) | Target has neither rules nor Skills dir -> `deferred` |
| **Manual / explicit** (`@rule`, `trigger: manual`, `inclusion: manual`) | Translate to native manual rule, manual-only Skill (`disable-model-invocation: true`), or explicit slash command | Target lacks verified manual-only flag -> `agent_handoff` (never make always-on) |
| **Subdirectory scope** (`nested/AGENTS.md`) | Preserve directory hierarchy; never flatten into repo root | Target has no subdir doc discovery -> `agent_handoff` / `deferred` |
| **Imported `@path`** | Never inline external/private files silently | Defer / `agent_handoff` for explicit path rebinding |

## Idempotency & semantic verification

- Repeat runs hash merged blocks (`sha256[:12]`) so identical content reports `noop` and
  divergent edits isolate per item as `conflict`.
- Test representative matching and non-matching file paths after migrating glob rules, and
  note when host loading semantics differ (e.g. eager injection vs on-read attachment).

Evidence consulted 2026-11-07:
[Cursor rules](https://cursor.com/docs/rules),
[Claude memory](https://code.claude.com/docs/en/memory),
[VS Code instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions),
[Codex instructions](https://developers.openai.com/codex/guides/agents-md).
