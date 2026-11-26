# Skills, commands, workflows, agents, hooks, plugins, and memory

Inventory every requested surface rather than reducing "all context" to rules + Skills + MCP.

## Full-copy policy & `agent_handoff` workflow

- **Full copy by default**: Always copy complete Skill folders (`SKILL.md`, `references/`,
  `assets/`, `scripts/`) and configuration files by value, preserving `0755` executable
  mode on scripts. Never create symlinks unless the user explicitly asks.
- **Zero stray directories & Script-vs-Agent split**: `migrate` and `import-device` never
  create `.migration-review/` folders or default `~/.agent-skills-setup-backups/`
  directories (`--backup-dir` is strictly opt-in). Lossy or unsafe items return
  `outcome: "agent_handoff"` in stdout JSON with `source_path`, `intended_target`,
  `reason`, and `guidance` so the Agent adapts them directly using the tables below.

## Complete 26-IDE Skills, commands, workflows, agents & hooks paths

| Profile ID | Skills (`project` / `user`) | Commands / Prompts / Workflows | Custom Agents (`project` / `user`) | Hooks / Memory |
| --- | --- | --- | --- | --- |
| `antigravity` | `.agents/skills` (legacy `.agent`, `_agents`) / `~/.gemini/config/skills` (env `ANTIGRAVITY_SKILLS_DIR`, legacy `~/.gemini/antigravity/skills`, `~/.gemini/skills`) | Workflows: `.agents/workflows` / `~/.gemini/config/workflows` | `.agents/agents/*.md` / `~/.gemini/config/agents/` (`subagent: true`, `mainAgent: false`; tools `read_file`, `edit_file`, `write_file`, `run_command`, `manage_task`, `search_web`) | Hooks: `.agents/hooks.json` / `~/.gemini/config/hooks.json` + sidecars + plugins + portable `userSettings` |
| `claude-code` | `.claude/skills` / `~/.claude/skills` | Commands: `.claude/commands` / `~/.claude/commands` | `.claude/agents/*.md` / `~/.claude/agents/*.md` (tools `Read`, `Grep`, `Glob`, `Edit`, `Write`, `Bash`, `WebSearch`, `WebFetch`) | Hooks: `"hooks"` inside `.claude/settings*.json` & `~/.claude/settings.json`; Memory: `~/.claude/memory` + `~/.claude/projects/<ws-slug>/memory` |
| `codex` | `.agents/skills` (legacy `.codex/skills`) / `~/.agents/skills` (`$CODEX_HOME/skills`; skips `.system`) | User prompts: `$CODEX_HOME/prompts` (project workflows -> manual Skill) | `.codex/agents` / `$CODEX_HOME/agents` (TOML -> `agent_handoff` across IDEs) | Hooks: `.codex/hooks.json` / `$CODEX_HOME/hooks.json` + `.rules` policies; excludes auto `memories`/`memories_v2` |
| `cursor` | `.cursor/skills` / `~/.cursor/skills` | `.cursor/commands` / `~/.cursor/commands` | `.cursor/agents` / `~/.cursor/agents` | `.cursor/hooks.json` / `~/.cursor/hooks.json` |
| `vscode` | `.github/skills` / `~/.copilot/skills` | `.github/prompts/*.prompt.md` / `—` | `.github/agents/*.agent.md` / `—` | `—` |
| `copilot-cli` | `.github/skills` / `~/.copilot/skills` | `—` (workflows -> manual Skill) | `.github/agents` / `~/.copilot/agents` | `—` |
| `gemini-cli` | `.gemini/skills` / `~/.gemini/skills` | `.gemini/commands/*.toml` (`agent_handoff` to/from MD) | `.gemini/agents` / `~/.gemini/agents` | `—` |
| `windsurf` | `.windsurf/skills` / `~/.codeium/windsurf/skills` | Workflows: `.windsurf/workflows` / `~/.codeium/windsurf/workflows` | `—` | Memory/global rules: `~/.codeium/windsurf/memories/global_rules.md` |
| `cline` | `.cline/skills` / `~/.cline/skills` | Workflows: `.cline/workflows` / `~/.cline/workflows` | `—` | Directory hooks: `.cline/hooks/` / `~/.cline/hooks/` (exec scripts) |
| `kilocode` | `.kilo/skills` / `~/.kilo/skills` | Workflows: `.kilo/workflows` / `~/.kilo/workflows` | `.kilo/agents` / `~/.kilo/agents` | `—` |
| `zed` | `.agents/skills` / `~/.agents/skills` | `—` | `—` | `—` |
| `opencode` | `.opencode/skills` / `~/.config/opencode/skills` | `.opencode/commands` / `~/.config/opencode/commands` | `.opencode/agents` / `~/.config/opencode/agents` | `—` |
| `kimi-code` | `.kimi-code/skills` / `$KIMI_CODE_HOME/skills` | `—` | `—` | `—` |
| `qwen-code` | `.qwen/skills` / `~/.qwen/skills` (uses **`allowedTools`**) | `.qwen/commands` / `~/.qwen/commands` | `.qwen/agents` / `~/.qwen/agents` | `—` |
| `pi` | `.pi/skills` / `~/.pi/agent/skills` | `.pi/prompts` / `~/.pi/agent/prompts` | `—` | `—` |
| `trae-cn` | `.trae/skills` (`.agents/skills`) / `~/.trae-cn/skills` | `.trae/commands` / `~/.trae-cn/commands` | `.trae/agents` / `~/.trae-cn/agents` | `.trae/hooks.json` / `~/.trae-cn/hooks.json` (excludes `trae-jwt-token`, `builtin_skills/`, auto `memory/`) |
| `trae` | `.trae/skills` (`.agents/skills`) / `~/.trae/skills` | `.trae/commands` / `~/.trae/commands` | `.trae/agents` / `~/.trae/agents` | `.trae/hooks.json` / `~/.trae/hooks.json` (excludes `trae-jwt-token`, `builtin_skills/`, auto `memory/`) |
| `kiro` | `.kiro/skills` / `~/.kiro/skills` | `—` (workflows -> manual Skill) | `.kiro/agents` / `~/.kiro/agents` | `.kiro/hooks/` |
| `junie` | `.junie/skills` / `~/.junie/skills` | `—` | `.junie/agents` / `~/.junie/agents` | `—` |
| `codebuddy` | `.codebuddy/skills` / `$CODEBUDDY_CONFIG_DIR/skills` | `.codebuddy/commands` / `$CODEBUDDY_CONFIG_DIR/commands` | `.codebuddy/agents` / `$CODEBUDDY_CONFIG_DIR/agents` | `"hooks"` in `.codebuddy/settings.json` / `$CODEBUDDY_CONFIG_DIR/settings.json` |
| `codebuddy-ide` | `.codebuddy/skills` / `~/.codebuddy/skills` | `.codebuddy/commands` / `~/.codebuddy/commands` | `.codebuddy/agents` / `~/.codebuddy/agents` | Hooks differ per IDE build -> `agent_handoff` |
| `qoder` | `.qoder/skills` / `~/.qoder/skills` | `.qoder/commands` / `~/.qoder/commands` | `.qoder/agents` / `~/.qoder/agents` | Excludes Quest artifacts |
| `qoder-cn` | `.lingma/skills` (`.agents/skills`) / `~/.lingma/skills` | `—` | `—` | `—` |
| `roo-code` | `.roo/skills` / `~/.roo/skills` | `—` | `—` (`.roomodes` distinct schema) | `—` |
| `augment-code` | `.augment/skills` / `~/.augment/skills` | `.augment/commands` / `—` | `.augment/agents` / `—` | User `rules` always apply (`glob` -> `agent_handoff`) |
| `factory-droid` | `.factory/skills` / `~/.factory/skills` | `.factory/commands` / `~/.factory/commands` | `.factory/droids` / `~/.factory/droids` | `—` |

## Agent adaptation rules for `agent_handoff` items

- **Commands & workflows**: Preserve arguments (`$ARGUMENTS`), body, and restrictions (`allowed-tools`). When `command_schema_differs` or `command restrictions not representable as Skill` (`context: fork`) fires, rewrite explicitly into target slash syntax or manual Skill without dropping constraints.
- **Agents**: Preserve role prompt, tool allow/deny lists, model hints, and isolation. `migrate_context.py` translates 1:1 tool maps across Antigravity <-> Claude Code <-> Codex automatically; when an agent uses `isolation`, `permissionMode`, `context`, `disallowedTools`, unmapped tools, or Codex `.toml` schema, read `source_path` and translate explicitly to `intended_target`.
- **Hooks, sidecars & scripts**: Never activate unreviewed hooks or execute bundled scripts during migration. Only activate same-schema hooks with `--activate-hooks` when authorized; otherwise adapt event names (`PreToolUse`, `PostToolUse`, `Stop`, `SessionStart`) for the target IDE intentionally.
- **Host traps**: Translate Qwen `allowedTools` <-> `allowed-tools`, keep OpenCode `@id` casing, never copy remote MCP-served Skills into local trusted dirs silently, and exclude `history.json`, `*.jsonl`, SQLite/LevelDB DBs, caches, and OAuth/JWT tokens.

Evidence consulted 2026-11-07: [Agent Skills](https://agentskills.io/specification),
[Claude Skills](https://code.claude.com/docs/en/skills), [Cursor Skills](https://cursor.com/docs/skills).
