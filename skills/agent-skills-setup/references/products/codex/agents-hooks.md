# Codex: Subagents, Hooks, Scripts & Policy Rules

Parent: [codex.md](../codex.md)

## Subagents

- Paths: `.codex/agents/*.md` and `$CODEX_HOME/agents/*.md` (and `.toml` agent specs when present — TOML agent files emit `agent_handoff` on cross-IDE migration).
- Preserves portable `name`, `description`, `tools`, `model` (`gpt-*` <-> Claude `sonnet`/`opus`/`haiku` via semantic handoff or model fields).

## Hooks, Scripts & Starlark Command Policies

- **Hooks**: `.codex/hooks.json` and `$CODEX_HOME/hooks.json` (kept parked via `agent_handoff` unless `--activate-hooks` on same-profile restore).
- **Helper scripts**: `$CODEX_HOME/scripts/` (executable mode preserved on same-profile restore; cross-IDE targets receive `agent_handoff`).
- **Command-policy rules**: `.codex/rules/*.rules` and `$CODEX_HOME/rules/*.rules` (`prefix_rule(pattern=[...], decision="allow"|"prompt"|"forbid")` — always parked by default unless `--activate-hooks`).

## Excluded Runtime State

Always exclude: `$CODEX_HOME/memories/`, `$CODEX_HOME/memories_v2/`, `$CODEX_HOME/auth.json`, `$CODEX_HOME/archived_sessions/`, `skills/.system/`, and SQLite DBs.

Official sources: [AGENTS.md guide](https://learn.chatgpt.com/docs/agent-configuration/agents-md) · [build skills](https://learn.chatgpt.com/docs/build-skills)
