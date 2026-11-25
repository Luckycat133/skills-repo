# Rules and instructions: preserve when and where they apply

Check text, scope, activation trigger, glob base, directory hierarchy, imports, and
local overrides. Keep technical requirements and human language intact.

## Mapping decisions

| Source behavior | Safe destination strategy |
| --- | --- |
| Always-on project/user instructions | Merge an idempotent `<!-- agent-skills-setup:begin id=... -->` section into target root/user instructions without clobbering existing content |
| File-pattern rule (`.mdc` `globs`, Claude `paths`, VS Code `applyTo`) | Convert to target's native pattern-scoped rule format; if target has only directory-level `AGENTS.md`, park a draft in `.migration-review/rules/` unless `--allow-broaden-scope` is approved |
| Model-selected rule (`description` only, `alwaysApply: false`) | Convert to target `model_decision` rule or on-demand Skill and note host-specific selection behavior |
| Manual rule (`@rule`, `alwaysApply: false`, no `globs`/`description`) | Convert to manual-only Skill (`disable-model-invocation: true`) or explicit slash command — **never** an always-on rule |
| Subdirectory instruction (`nested/AGENTS.md`) | Keep directory hierarchy; never flatten into repository root |
| Imported `@path` instruction | Rebase relative references within authorized roots; never inline external private files silently |

Cursor `.mdc` uses `alwaysApply`, `globs` (often unquoted such as `globs: *.py` or
comma-separated `src/**/*.ts, tests/**/*.ts`, or brace-expanded `src/**/*.{ts,tsx}`),
and `description`. **`alwaysApply: true` overrides `globs`**. Claude Code uses YAML
`paths: [...]`; VS Code uses `applyTo: "..."`; Antigravity and Windsurf use
`trigger: always_on | glob | model_decision | manual` (Antigravity `rules/*.md`
must declare `trigger`, and `AGENTS.md` / `GEMINI.md` hold unconditional rules).

## Worked example: Cursor scoped rule to Claude Code

Source `.cursor/rules/python-tests.mdc`:

```mdc
---
globs: "tests/**/*.py"
alwaysApply: false
---
Use pytest fixtures and do not add network calls to unit tests.
```

Destination `.claude/rules/python-tests.md` (`CLAUDE.md` stays untouched):

```markdown
---
paths:
  - "tests/**/*.py"
---
Use pytest fixtures and do not add network calls to unit tests.
```

Verify representative matching (`tests/test_api.py`, `tests/unit/test_api.py`) and
non-matching (`src/api.py`) paths, and parse frontmatter so invalid YAML cannot widen
the rule unconditionally. Report that Cursor attachment timing and Claude file-read
loading are not identical.

## Other target formats & idempotency

- **VS Code / Copilot**: `.github/instructions/<slug>.instructions.md` with `applyTo: "tests/**/*.py"`.
- **Codex / Zed / OpenCode / Kimi / Pi**: `AGENTS.md` is directory-scoped, not an extension-glob container; check `AGENTS.override.md` and Zed first-match shadowing (`.rules`, `.cursorrules`, `CLAUDE.md`, `GEMINI.md`) before writing.
- **Repeat runs**: `scripts/migrate_context.py` hashes section blocks (`sha256[:12]`) so identical re-runs report `noop` and divergent edits report `conflict` without suppressing independent rules.

Evidence consulted 2026-11-07:
[Cursor rules](https://cursor.com/docs/rules),
[Claude memory and rule frontmatter](https://code.claude.com/docs/en/memory),
[VS Code instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions),
[Codex instructions](https://developers.openai.com/codex/guides/agents-md).
