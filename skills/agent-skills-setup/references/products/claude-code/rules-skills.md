# Claude Code: Rules, Instructions, Memory & Skills

Parent: [claude-code.md](../claude-code.md)

## Env Root (`CLAUDE_CONFIG_DIR`)

When `CLAUDE_CONFIG_DIR` is set, global `~/.claude/*` paths and `.claude.json` resolve under `$CLAUDE_CONFIG_DIR/` instead of `~/.claude/`.

## Instructions & Scoped Rules

| Scope | Path | Loading & Features |
| --- | --- | --- |
| User global | `~/.claude/CLAUDE.md` | Always loaded at session start; supports `@path/to/file.md` recursive imports |
| Project root / subdir | `CLAUDE.md`, `.claude/CLAUDE.md`, local `CLAUDE.local.md` (also reads `AGENTS.md` fallback) | `@path` dependencies are NOT auto-inlined across IDEs — migrate/adapt imported files explicitly |
| Path-scoped modular rules | `.claude/rules/*.md`, `~/.claude/rules/*.md` | YAML **`paths: ["src/**/*.ts"]`** array restricts activation; rules without `paths:` load unconditionally |

## Skills

- Paths: `.claude/skills/<name>/SKILL.md`, `~/.claude/skills/<name>/SKILL.md` (legacy slash commands: `.claude/commands/*.md`, `~/.claude/commands/*.md`).
- Supported frontmatter fields: `name`, `description`, `disable-model-invocation: true` (manual `/name` only), `allowed-tools`, `context: fork` (isolated subagent execution), `argument-hint`, `$ARGUMENTS` / `$1`.
- Cross-IDE note: `context: fork` and command-level `allowed-tools` constraints have no equivalent in plain-Markdown command targets; emit `agent_handoff` when a target cannot enforce them.

## Authored Memory vs Auto Memory

- User-authored memory: `~/.claude/memory/*.md` and workspace auto-memory `~/.claude/projects/<ws-slug>/memory/*.md` (`MEMORY.md` + topic `.md` files).
- Exclude session transcripts (`*.jsonl`), `cache/`, `sessions/`, `plugins/{cache,store}`, and `plugin-directory-cache-v2.json`.

Official sources: [features overview](https://code.claude.com/docs/en/features-overview) · [memory](https://code.claude.com/docs/en/memory) · [skills](https://code.claude.com/docs/en/skills)
