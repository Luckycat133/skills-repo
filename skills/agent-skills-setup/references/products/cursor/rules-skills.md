# Cursor: Rules (`.mdc`), Skills, Commands & Subagents

Parent: [cursor.md](../cursor.md)

## `.cursor/rules/*.mdc` (4 Activation Modes)

- Project rules live under `.cursor/rules/*.mdc` (plus root/nested `AGENTS.md` and legacy `.cursorrules`). User-scope rules live in Cursor Settings / `~/.cursor/rules/`. Plain `.md` files beside `.mdc` are ignored as rules.
- YAML frontmatter precedence:
  1. **Always Apply**: `alwaysApply: true` (wins even if `globs` is present).
  2. **Apply to Specific Files**: `alwaysApply: false` + `globs: "*.py"` or `"src/**/*.ts, tests/**/*.ts"`.
  3. **Apply Intelligently (Model Decision)**: `alwaysApply: false` + `description: "..."` (no `globs`).
  4. **Apply Manually (`@rule`)**: `alwaysApply: false` with neither `globs` nor `description`.

## Skills, Commands & Subagents

- **Skills**: Project `.cursor/skills/<name>/SKILL.md` (and `.agents/skills/<name>/SKILL.md`), Global `~/.cursor/skills/<name>/SKILL.md` (invoked via `/skill-name`, `@skill-name`, or model relevance).
- **Commands**: Project `.cursor/commands/*.md`, Global `~/.cursor/commands/*.md` (`/` slash shortcuts).
- **Subagents**: Project `.cursor/agents/*.md`, Global `~/.cursor/agents/*.md` (`name`, `description`, instructions).

Official sources: [rules](https://cursor.com/docs/rules) · [skills](https://cursor.com/docs/skills) · [subagents](https://cursor.com/docs/subagents)
