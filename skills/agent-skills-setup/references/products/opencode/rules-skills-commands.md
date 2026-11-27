# OpenCode: Instructions, Skills & Custom Commands

Parent: [opencode.md](../opencode.md)

## Instructions & Skills

- **Instructions**: Project `AGENTS.md` and User `~/.config/opencode/AGENTS.md`; `opencode.json` / `.opencode/opencode.json` can also declare `"instructions": ["AGENTS.md", "docs/*.md"]` globs.
- **Skills**: Project `.opencode/skills/<id>/SKILL.md` (and `.claude/skills`, `.agents/skills`), Global `~/.config/opencode/skills/<id>/SKILL.md`.
- **V2 Skill ID trap**: In V2, Skill IDs come from **case-sensitive directory names**, `@id` invocation, and `opencode/autoinvoke` + ordered `permission.skill` rules — never silently rename directories from `name` frontmatter alone or enable `autoinvoke` implicitly.

## Custom Slash Commands

- Project: `.opencode/commands/<name>.md`; Global: `~/.config/opencode/commands/<name>.md` (can also be declared in `opencode.json`).
- Supports `$ARGUMENTS`, positional `$1`/`$2`, and dynamic shell execution `` !`git diff` `` — always review/park shell-evaluated blocks across targets!

Official sources: [skills](https://opencode.ai/docs/skills/) · [v2 skills](https://opencode.ai/v2/docs/skills) · [commands](https://opencode.ai/docs/commands/)
