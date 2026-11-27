# Antigravity: Rules, Instructions & Skills

Parent: [antigravity.md](../antigravity.md)

## Instructions & Rules

| Scope | Path | Format / Frontmatter | Limit / Behavior |
| --- | --- | --- | --- |
| Workspace hierarchical | `AGENTS.md`, `GEMINI.md` (walking up CWD to repo root) | Plain Markdown (no frontmatter) | Always active for directory subtree; deduplicated by resolved path |
| Workspace modular rules | `.agents/rules/*.md` (legacy `.agent/`, `_agents/`, `_agent/`) | YAML `trigger: always_on \| glob \| model_decision \| manual`, `globs`, `description` | 24,000 bytes per file (after `@`-include file expansion) |
| Global user doc / rules | `~/.gemini/config/AGENTS.md`, `~/.gemini/config/rules/*.md` (legacy `~/.gemini/{AGENTS,GEMINI}.md`) | Same as workspace rules | Shared `defaultRulesBudget`: 20,000 tokens across always-on & global rules; overflow becomes file-path pointers |

- **Manifest registration**: `.agents/rules.json` and `~/.gemini/config/rules.json` can register shared rule paths explicitly (`declared` priority sits between workspace hierarchical and global discovery).
- **Frontmatter equivalence**:
  - `trigger: glob` + `globs: "*.ts, src/**"` (+ optional `description`) <-> Claude Code `paths:` <-> Cursor `globs:` + `alwaysApply: false` <-> Kiro `inclusion: fileMatch` + `fileMatchPattern`.
  - `trigger: model_decision` + `description` -> Codex / Claude Code on-demand `SKILL.md`.
  - `trigger: manual` -> Claude Code / Cursor `SKILL.md` with `disable-model-invocation: true`, or Kiro `inclusion: manual`.

## Skills & Legacy Workflows

| Scope | Path | Schema |
| --- | --- | --- |
| Workspace skills | `.agents/skills/<name>/SKILL.md` (legacy `.agent/skills/`, `_agents/skills/`, `_agent/skills/`) | Agent Skills spec: YAML `name` + `description`, optional `disable-model-invocation: true`, optional `scripts/`, `references/`, `assets/` |
| Global skills | `$ANTIGRAVITY_SKILLS_DIR` or `~/.gemini/config/skills/<name>/SKILL.md` (legacy `~/.gemini/antigravity/skills`, `~/.gemini/antigravity-cli/skills`, `~/.gemini/skills`) | Progressive disclosure: only `name` + `description` load initially |
| Manifests | `.agents/skills.json`, `~/.gemini/config/skills.json` | JSON registry for non-standard skill folders |
| Workflows | `.agents/workflows/*.md`, `~/.gemini/config/workflows/*.md` (legacy `.agent/workflows/*.md`) | On-demand procedural workflows (App 2.12+ migrates to `SKILL.md`, never always-on rules) |

Official sources: [skills](https://antigravity.google/docs/skills) · [customization discovery](https://antigravity.google/docs/customization-discovery) · [workflows to skills](https://antigravity.google/docs/migration/workflows-to-skills)
