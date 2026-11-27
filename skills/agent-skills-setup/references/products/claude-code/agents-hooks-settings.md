# Claude Code: Subagents, Hooks, Settings & Plugins

Parent: [claude-code.md](../claude-code.md)

## Subagents

- Paths: `.claude/agents/*.md`, `~/.claude/agents/*.md`.
- Frontmatter fields: `name`, `description`, `tools` (e.g. `Read, Edit, Bash` or list), `disallowedTools`, `model` (`sonnet` / `opus` / `haiku` / `inherit`), `permissionMode` (`default` / `acceptEdits` / `plan` / `bypassPermissions`), `isolation: worktree`, `maxTurns`, `hooks`.
- Cross-IDE caution: Targets lacking isolated worktree/permission-mode enforcement (e.g. Trae, OpenCode plain markdown) receive `agent_handoff` instead of silent downgrade.

## Settings Hierarchy & Lifecycle Hooks (`settings.json`)

Precedence (highest -> lowest): Managed settings -> CLI flags -> `.claude/settings.local.json` -> `.claude/settings.json` -> `~/.claude/settings.json` (`$CLAUDE_CONFIG_DIR/settings.json`).

- Hooks live inside the `"hooks"` subobject of `settings.json` / `settings.local.json` (across 25 lifecycle events, matcher-wrapped command/prompt/agent/HTTP handlers).
- Portable settings preserve preferences & `"env"` in `0600` mode while strictly stripping non-portable `permissions`, `hooks`, `apiKeyHelper`, and trust/oauth flags.
- `--activate-hooks` supports surgical same-profile merge of the `"hooks"` subobject while leaving sibling keys intact.

## Plugin Registries

- `~/.claude/plugins/installed_plugins.json` and `known_marketplaces.json` store installed plugin manifests and marketplace sources; exclude `plugins/cache/`, `plugins/store/`, and `plugin-directory-cache-v2.json`.

Official sources: [features overview](https://code.claude.com/docs/en/features-overview) · [sub-agents](https://code.claude.com/docs/en/sub-agents)
