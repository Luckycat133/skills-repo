# Rules and instructions: complete cross-IDE mapping reference

Check text, scope, activation trigger, glob base, directory hierarchy, imports, and
local overrides. Keep technical requirements and human language intact.

## Mapping decisions (lossless vs `agent_handoff`)

| Source behavior | Script / Agent strategy |
| --- | --- |
| Always-on project/user instructions | Merge an idempotent `<!-- agent-skills-setup:begin id=... -->` section into target root/user instructions without clobbering existing content |
| File-pattern rule (`.mdc` `globs`, Claude `paths`, VS Code `applyTo`, Kiro `fileMatchPattern`) | Convert to target's native pattern-scoped rule format; if target lacks glob rules (or is `augment-code` user scope, where all user rules always apply), `migrate_context.py` emits `agent_handoff` instead of widening scope or creating stray folders unless `--allow-broaden-scope` is approved |
| Model-selected rule (`description`, `trigger: model_decision`, `alwaysApply: false`) | Convert to native `model_decision` / `alwaysApply: false` rule or on-demand `SKILL.md` |
| Manual rule (`@rule` / `trigger: manual` / `inclusion: manual`) | Convert to `trigger: manual`, `inclusion: manual`, manual-only Skill (`disable-model-invocation: true`), or explicit slash command; targets without manual flags emit `agent_handoff` |
| Subdirectory instruction (`nested/AGENTS.md`) | Keep directory hierarchy; never flatten into repository root |
| Imported `@path` instruction | Defer / hand off; rebase relative references within authorized roots cleanly |

## Complete 26-IDE built-in rule & instruction matrix

| Profile ID | Project root doc | User global doc | Scoped rules dir (`project` / `user`) | Frontmatter & activation schema |
| --- | --- | --- | --- | --- |
| `antigravity` | `AGENTS.md` (legacy `GEMINI.md`) | `~/.gemini/config/AGENTS.md` | `.agents/rules/*.md` / `~/.gemini/config/rules/*.md` | `trigger: always_on \| glob \| model_decision \| manual`, `globs`, `description` |
| `claude-code` | `CLAUDE.md` (`.claude/CLAUDE.md`, `CLAUDE.local.md`) | `~/.claude/CLAUDE.md` | `.claude/rules/*.md` / `~/.claude/rules/*.md` | `paths: [...]` (glob); omitted `paths` -> unconditional |
| `codex` | `AGENTS.md` + `AGENTS.override.md` + subdirs | `$CODEX_HOME/AGENTS.md` + `AGENTS.override.md` | `agent_handoff` (no extension globs; subdir `AGENTS.md` only) | Plain Markdown sections; never widen globs without consent |
| `cursor` | `AGENTS.md` (legacy `.cursorrules`) | `—` | `.cursor/rules/*.mdc` / `~/.cursor/rules/*.mdc` | `alwaysApply`, `globs` (unquoted/comma/brace), `description` (`alwaysApply: true` wins) |
| `vscode` | `.github/copilot-instructions.md` | `—` | `.github/instructions/*.instructions.md` / `—` | `applyTo: "..."` |
| `copilot-cli` | `.github/copilot-instructions.md` | `~/.copilot/copilot-instructions.md` | `.github/instructions/*.instructions.md` / `—` | `applyTo: "..."` |
| `gemini-cli` | `GEMINI.md` | `~/.gemini/GEMINI.md` | `—` | Plain Markdown root/home doc |
| `windsurf` | `AGENTS.md` (legacy `.windsurfrules`) | `~/.codeium/windsurf/memories/global_rules.md` | `.windsurf/rules/*.md` / `—` | `trigger: always_on \| glob \| model_decision \| manual`, `globs`, `description` |
| `cline` | `.clinerules` (file or dir) | `—` | `.clinerules/*.md` / `~/.cline/rules/*.md` | Plain Markdown rule files |
| `kilocode` | `AGENTS.md` | `—` | `.kilo/rules/*.md` / `~/.kilo/rules/*.md` | Plain Markdown / legacy `.kilocode/rules` |
| `zed` | `.rules` > `.cursorrules` > `CLAUDE.md` > `AGENTS.md` | `~/.config/zed/AGENTS.md` | `—` | First-match shadowing across root files |
| `opencode` | `AGENTS.md` | `~/.config/opencode/AGENTS.md` | `—` | Plain Markdown |
| `kimi-code` | `AGENTS.md` | `$KIMI_CODE_HOME/AGENTS.md` (legacy `~/.kimi/AGENTS.md`) | `—` | Plain Markdown |
| `qwen-code` | `QWEN.md` | `~/.qwen/QWEN.md` | `—` | Plain Markdown |
| `pi` | `AGENTS.md` | `~/.pi/agent/AGENTS.md` | `—` | Plain Markdown |
| `trae-cn` | `—` | `~/.trae-cn/user_rules.md` (legacy `~/.trae/user_rules*`) | `.trae/rules/*.md` / `~/.trae-cn/rules/*.md` | `alwaysApply`, `globs`, `description` (`@Rule` manual stays `agent_handoff`) |
| `trae` | `—` | `~/.trae/user_rules.md` (legacy `user_rules`) | `.trae/rules/*.md` / `~/.trae/rules/*.md` | `alwaysApply`, `globs`, `description` (`@Rule` manual stays `agent_handoff`) |
| `kiro` | `AGENTS.md` | `—` | `.kiro/steering/*.md` / `~/.kiro/steering/*.md` | `inclusion: always \| fileMatch \| manual`, `fileMatchPattern` |
| `junie` | `.junie/guidelines.md` (fallback `AGENTS.md`) | `—` | `—` | Plain Markdown |
| `codebuddy` | `CODEBUDDY.md` (fallback `AGENTS.md`) | `$CODEBUDDY_CONFIG_DIR/CODEBUDDY.md` | `.codebuddy/rules/*.md` / `~/.codebuddy/rules/*.md` | `alwaysApply`, `globs`, `description` |
| `codebuddy-ide` | `—` | `—` | `.codebuddy/rules/*.md` / `~/.codebuddy/rules/*.md` | `alwaysApply`, `globs`, `description` (`RULE.mdc` in older IDE builds) |
| `qoder` | `AGENTS.md` | `—` | `.qoder/rules/*.md` / `~/.qoder/rules/*.md` | `alwaysApply`, `globs`, `description` |
| `qoder-cn` | `—` | `—` | `.lingma/rules/*.md` / `~/.lingma/rules/*.md` | `alwaysApply`, `globs`, `description` |
| `roo-code` | `—` | `—` | `.roo/rules/*.md` / `~/.roo/rules/*.md` | `alwaysApply`, `globs`, `description` |
| `augment-code` | legacy `.augment-guidelines` | `—` | `.augment/rules/*.md` / `~/.augment/rules/*.md` | Project supports `globs`; **user `~/.augment/rules` always apply** (`glob` emits `agent_handoff`) |
| `factory-droid` | `AGENTS.md` | `—` | `—` | Plain Markdown |

## Handling `agent_handoff` rules & idempotency

- When `migrate_context.py` emits `agent_handoff` on an instruction item, read `source_path` and either adapt it into the target's native pattern (e.g., rewrite `@Rule` triggers as explicit commands) or omit it if unwanted — zero `.migration-review/` draft folders are written to the repo.
- Repeat runs hash merged root sections (`sha256[:12]`): identical re-runs report `noop` and divergent edits isolate as `conflict`.

Evidence consulted 2026-11-07:
[Cursor rules](https://cursor.com/docs/rules),
[Claude memory and rule frontmatter](https://code.claude.com/docs/en/memory),
[VS Code instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions),
[Codex instructions](https://developers.openai.com/codex/guides/agents-md).
