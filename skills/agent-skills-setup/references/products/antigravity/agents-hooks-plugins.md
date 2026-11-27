# Antigravity: Custom Agents, Hooks, Plugins & Settings

Parent: [antigravity.md](../antigravity.md)

## Custom Agents

- Paths: `.agents/agents/<name>.md` or `.agents/agents/<name>/agent.md`, global `~/.gemini/config/agents/`, manifest `agents.json`.
- Frontmatter: `name`, `description`, `tools` (array e.g. `[read_file, write_to_file, run_command, grep_search]`), `subagent: true|false`, `mainAgent: false`, optional `model`.
- Tool mapping (`Antigravity <-> Claude Code`): `read_file <-> Read`, `write_to_file / replace_file_content <-> Write / Edit`, `run_command <-> Bash`, `grep_search <-> Grep`, `find_by_name <-> Glob`, `read_url_content <-> WebFetch`, `search_web <-> WebSearch`.

## Lifecycle Hooks (`hooks.json`)

- Paths: `.agents/hooks.json`, `~/.gemini/config/hooks.json`, or `plugins/<name>/hooks.json` (must be at plugin root for native plugins, not `hooks/hooks.json`!).
- Structure: Top-level JSON object keyed by **hook name**, optional `"enabled": false`, event keys:
  - Flat handler list: `SessionStart`, `PreInvocation`, `PostInvocation`, `Stop`
  - Matcher-grouped (`"matcher"` regex on lowercase step type without `CORTEX_STEP_TYPE_`, `"hooks"` array): `PreToolUse`, `PostToolUse`
- Handler fields: `type: "command"`, `command`, `timeout` (default `30`s). `stdin`/`stdout` payloads use **camelCase** protojson (`conversationId`, `stepIdx`).
- Helper scripts live in `~/.gemini/config/scripts/`; sidecars live in `~/.gemini/config/sidecars/`.

## Plugins & Portable Settings

- Plugin layout: `plugins/<name>/plugin.json` (or `.antigravity-plugin/plugin.json` / `.gemini-plugin/plugin.json`), plus `mcp_config.json`, root `hooks.json`, `rules/AGENTS.md`, `skills/<skill>/SKILL.md`; manifest `plugins.json`.
- `config.json`: Stores `"plugins": {"<name>": {"enabled": false}}` (overrides `plugin.json` `disabled`) and portable `"userSettings"` (`themeMode`, `orchestratorModel`, `permissionPreset` — exclude OAuth/token state!).
- Antigravity CLI: `~/.gemini/antigravity-cli/settings.json` and `keybindings.json`.
- Always exclude: `~/.gemini/antigravity/{conversations,brain}`, sqlite DBs, `.subagent_sessions/`, and `jetski-standalone-oauth-token`.

Official sources: [customization discovery](https://antigravity.google/docs/customization-discovery) · [changelog](https://antigravity.google/changelog)
