# Windsurf / Cascade & Devin Transition: Rules, Workflows & Skills

Parent: [windsurf.md](../windsurf.md)

## Cascade vs Devin Local Paths

Windsurf documentation redirects to Devin Desktop, while installed editors may run **legacy Cascade** or **Devin Local**:
- **Workspace rules**: `.windsurf/rules/*.md` (Devin-era preferred/compatible also checks `.devin/rules/*.md`, plus legacy `.windsurfrules` and `AGENTS.md`). Max 12,000 characters per workspace rule file.
- **Activation frontmatter**: `trigger: always_on | glob | model_decision | manual` with `globs` / `description`.
- **Global user rule**: `~/.codeium/windsurf/memories/global_rules.md` (max 6,000 characters; migrate **only** `global_rules.md`, never auto-generated memories!).

## Workflows & Skills

- **Workflows**: `.windsurf/workflows/*.md` and `~/.codeium/windsurf/workflows/*.md`.
- **Skills**: `.windsurf/skills/<name>/SKILL.md` and `~/.codeium/windsurf/skills/<name>/SKILL.md`.
- If running Devin Local explicitly, avoid double-importing overlapping `.devin/` and `.windsurf/` files; use [devin.md](../devin.md) paths directly.

Official sources: [Devin Desktop Cascade](https://docs.devin.ai/desktop/cascade) · [Windsurf memories](https://docs.windsurf.com/windsurf/cascade/memories)
