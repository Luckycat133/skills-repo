# Skills, commands, workflows, agents, hooks, plugins, and memory

Look up exact per-client directories in ONLY `references/products/<source>.md` and
`references/products/<target>.md` (indexed by [products.md](products.md)).

## Full-copy policy & `agent_handoff` workflow

- **Full copy by value**: Always copy complete Skill folders (`SKILL.md`, `references/`,
  `assets/`, `scripts/`) and configuration files directly — never create symlinks unless
  the user explicitly asks. Preserve `0755` executable mode on `scripts/*`.
- **Zero stray directories**: `migrate` and `import-device` never create `.migration-review/`
  folders or default backup dirs (`--backup-dir` is opt-in). Any non-1:1 or sensitive item
  returns `outcome: "agent_handoff"` in stdout JSON with `source_path`, `intended_target`,
  `reason`, and `guidance` so you adapt it semantically using the rules below.

## Category conversion rules

- **Skills (`SKILL.md`)**: Copy whole unit, compute directory digest for idempotency (`noop`
  vs `conflict`), translate `allowed-tools` <-> `allowedTools` (Qwen Code) explicitly, and
  synthesize minimal `name` / `description` frontmatter only when required (Antigravity).
  Use generic `sync-skills` to copy Skills between any directories or profiles.
- **Prompts, slash commands & workflows**: Plain Markdown workflows map to slash commands
  or manual-only Skills (`disable-model-invocation: true`, carrying `allowed-tools`). When
  formats or restrictions cannot map losslessly (e.g. Gemini `.toml` commands, `context: fork`),
  the helper returns `agent_handoff` rather than dropping constraints.
- **Agents / subagents**: Losslessly translates 1:1 tool maps (`Read`/`Edit`/`Write`/`Bash`/
  `WebSearch` <-> `read_file`/`edit_file`/`write_file`/`run_command`/`search_web`) and safe
  model hints across Antigravity <-> Claude Code <-> Codex. Complex schemas (Codex `.toml`
  agents, `isolation`, `permissionMode`, `context`, unmapped tools) emit `agent_handoff`.
- **Hooks, sidecars & policy rules**: Kept inactive (`agent_handoff`) by default; activate
  same-schema hooks/sidecars/Codex `.rules` only with explicit `--activate-hooks`. Use
  generic `copy-files` for verified standalone config/helper files.
- **Plugins, memory & exclusions**: Copy portable plugin registries and user-authored
  Markdown memory (`~/.claude/memory`, workspace-encoded `~/.claude/projects/<slug>/memory`),
  while always excluding chat transcripts (`*.jsonl`), SQLite/LevelDB DBs, caches, OAuth/JWT
  tokens, built-in system skills, and `permissions`/`trust` grants.

Evidence consulted 2026-11-07:
[Agent Skills](https://agentskills.io/specification),
[Claude Skills](https://code.claude.com/docs/en/skills),
[Cursor Skills](https://cursor.com/docs/skills).
