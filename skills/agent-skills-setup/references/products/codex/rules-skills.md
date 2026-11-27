# Codex: Instructions & Skills

Parent: [codex.md](../codex.md)

## Env Root (`$CODEX_HOME`)

Global configuration defaults to `~/.codex/` (override via `CODEX_HOME`).

## Hierarchical Instructions (`AGENTS.md`)

| Scope | Files (Precedence at same directory level) | Behavior |
| --- | --- | --- |
| User global | `$CODEX_HOME/AGENTS.override.md` > `$CODEX_HOME/AGENTS.md` | Always loaded at session start |
| Project root -> CWD tree | `<dir>/AGENTS.override.md` > `<dir>/AGENTS.md` | Codex reads root downward; nested subdirectory `AGENTS.md` files apply to their subtree (marked `directory_scoped` in cross-IDE migration so they never silently widen) |

- No native file-glob YAML rule directory exists: `.claude/rules/*.md` or `.cursor/rules/*.mdc` glob rules cannot be auto-activated per file extension without explicit `agent_handoff` or `--allow-broaden-scope`.

## Agent Skills & Prompts

- **Skills**: Project `.agents/skills/<name>/SKILL.md` (legacy `.codex/skills/`), User `~/.agents/skills/<name>/SKILL.md` (always skips built-in `.system/` directory!).
- Optional UI metadata file inside each skill: `agents/openai.yaml`.
- **Legacy Prompts**: `~/.codex/prompts/*.md` (user scope). Cross-IDE migration maps Antigravity workflows & manual rules to on-demand `SKILL.md` (`disable-model-invocation: true` preserved where applicable).

Official sources: [AGENTS.md guide](https://learn.chatgpt.com/docs/agent-configuration/agents-md) · [build skills](https://learn.chatgpt.com/docs/build-skills)
