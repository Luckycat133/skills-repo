# Skills, prompts, commands, agents, hooks, plugins, and memory

Inventory every requested surface rather than reducing "all context" to rules + Skills + MCP.

## Skills

Copy each reviewed Skill directory as a unit (`SKILL.md`, `references/`, `assets/`,
`scripts/`), preserving `0755` executable mode on `scripts/*`. Reject symlinks or `..`
paths escaping the authorized root, and never auto-copy `agent-skills-setup` itself
unless explicitly requested. Compare directory digests per Skill: identical content is
`noop`; differing content is an isolated `conflict`. Preserve `disable-model-invocation`
and translate tool-restriction differences explicitly (e.g., `allowed-tools` <-> Qwen
`allowedTools`). Copying a Skill never authorizes running its bundled scripts.

## Prompts, slash commands, and workflows

Extract invocation name, description, parameters, body, file references, and shell
interpolation. Plain Markdown commands/workflows without incompatible shell macros can
map to target command folders (`.cursor/commands/`, `.claude/commands/`,
`.opencode/commands/`, `.github/prompts/*.prompt.md`) or manual-only Skills
(`disable-model-invocation: true`). Gemini CLI custom commands use `.gemini/commands/*.toml`;
when schemas differ, park a draft in `.migration-review/commands/` and report losses.

## Agents, modes, personas, and subagents

Preserve role prompt, tool allow/deny lists, model hints, and isolation (`context: fork`)
only against verified target schemas (`.claude/agents/*.md`, `.cursor/agents/*.md`,
`.github/agents/*.agent.md`, `.kilo/agents/*.md`, `.junie/agents/*.md`). Never drop a
source restriction to grant broader tool access silently, and never import approval grants.

## Hooks and executable automations

Hooks, cron jobs, setup scripts, and workflow verifiers execute arbitrary commands.
Keep migrated hooks parked in `.migration-review/hooks/<target>/` (`0700`/`0600`) by
default; write to live hook paths only when the user explicitly approves
`--activate-hooks` after confirming event and I/O semantics. Never invent a fake
`enabled: false` key in a live hook file or execute hook commands during migration.

## Plugins, extensions, and authored memory

- **Plugins**: Prefer native manifest import when formats match (`.factory-plugin/plugin.json`,
  root `plugin.json`); otherwise migrate only the user-selected inert components (such
  as a single Skill) while reporting omitted hooks/MCP/LSP components separately.
- **Memory & `.env` secrets**: Migrate reviewed user-authored Markdown preferences
  (e.g., `~/.claude/memory/*.md`, Windsurf `global_rules.md`) and `.env*` secrets
  out-of-band (`0600`). Always exclude `history.json`, `*.jsonl` transcripts, SQLite/LevelDB
  databases, vector indexes, caches, and generated memory dumps.

## Host-specific traps (consult [products.md](products.md))

| Trap | Requirement |
| --- | --- |
| Qwen `allowedTools` vs `allowed-tools` | Translate field spelling and verify target tool names; never claim automatic enforcement without checking |
| OpenCode V2 directory ID vs `name` | Preserve directory slug casing and `@id` / `opencode/autoinvoke` semantics |
| OpenHands `paths` & `triggers` | Preserve path-encounter precedence over keyword triggers |
| Augment user rules always apply | Never place a file-scoped rule into Augment user rules without consent |
| CodeCompanion autoloaded `.mdc` | Autoload groups ignore Cursor `globs`/`alwaysApply`; park or scope explicitly |
| Zed first-match instructions | Warn when `.rules`, `.cursorrules`, `CLAUDE.md`, or `GEMINI.md` shadow `AGENTS.md` |
| Kiro CLI v2 vs v3 agents | Match major version schema; do not turn old allowlists into blanket permissions |
| MCP-served Skills vs local Skills | Preserve remote server provenance; do not install remote content as local scripts |
| Aider conventions | Bind read-only convention files via `read:` in `.aider.conf.yml` |

Evidence consulted 2026-11-07: [Agent Skills](https://agentskills.io/specification),
[Claude Skills](https://code.claude.com/docs/en/skills), [Cursor Skills](https://cursor.com/docs/skills).
