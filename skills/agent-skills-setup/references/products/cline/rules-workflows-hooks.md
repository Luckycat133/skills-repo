# Cline: Rules, Skills, Workflows & Hooks

Parent: [cline.md](../cline.md)

## Rules (`.cline/rules/` vs Legacy `.clinerules`)

| Scope | Path | Notes |
| --- | --- | --- |
| Workspace rules | `.cline/rules/*.md` (legacy `.clinerules` single file or `.clinerules/*.md`) | Always-on rules unless conditional frontmatter applies; `migrate_context.py` prefers `.cline/rules/` for clean workspaces while preserving existing `.clinerules` |
| Global user rules | `~/.cline/rules/*.md` (compatibility fallback `~/Documents/Cline/Rules/`) | Global across Cline IDE, CLI, SDK |

## Skills, Workflows & Hooks

- **Skills**: Project `.cline/skills/<name>/SKILL.md` (and `.agents/skills/<name>/SKILL.md`), Global `~/.cline/skills/<name>/SKILL.md` (fallback `~/.agents/skills/`).
- **Workflows**: Project `.cline/workflows/*.md` (legacy `.clinerules/workflows/`), Global `~/.cline/workflows/*.md` (`~/Documents/Cline/Workflows/` fallback).
- **Hooks**: Executable scripts under `.cline/hooks/` (legacy `.clinerules/hooks/`) and `~/.cline/hooks/` (`PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `TaskStart`) — keep parked unless `--activate-hooks`.

Official sources: [getting started config](https://docs.cline.bot/getting-started/config) · [skills](https://docs.cline.bot/features/skills) · [cline rules](https://docs.cline.bot/features/cline-rules) · [hooks](https://docs.cline.bot/features/hooks)
