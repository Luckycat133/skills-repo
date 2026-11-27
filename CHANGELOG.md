# Changelog

## Unreleased — Antigravity / Claude Code / Codex completeness & 3-way equivalence (2026-11-25)

- **macOS & CLI ergonomics**: Auto-detect Python 3.11+ or `uv` in `validate-all.sh` and
  add a Python 3.11+ self-bootstrap in `migrate_context.py`; add `inspect --summary`,
  top-level `totals`, optional `--output` on `export-device`, and graceful broken-symlink
  exclusion (using canonical product names without invented shorthand aliases).
- **Complete Antigravity, Claude Code & Codex coverage**:
  - **Antigravity**: Align primary user paths to `~/.gemini/config/` (`AGENTS.md`,
    `rules/*.md`, `skills/`, `agents/`, `workflows/`, `hooks.json`, `mcp_config.json`),
    preserve legacy paths, add plugins + `config.json` registry, discovery manifests,
    scripts, parked sidecars, portable `userSettings`, CLI settings/keybindings,
    `timeoutSeconds`, `enabledTools`, and legacy SSE deferral.
  - **Claude Code**: Add `.claude/settings.local.json` hooks, same-profile `--activate-hooks`
    surgical merge into `settings.json`, portable `settings.json` + `env` out-of-band
    secrets, plugin registries, and workspace-encoded project memory remapping.
  - **Codex**: Add `AGENTS.override.md`, `.codex/agents/` & `$CODEX_HOME/agents/`,
    `hooks.json`, `$CODEX_HOME/scripts/`, parked `.rules` policies, portable `config.toml`
    surgical merge (preserving `approval_policy` & `[mcp_servers]`), and `.system` skip.
- **3-way equivalent migration (`Antigravity <-> Claude Code <-> Codex`)**: Add native
  Antigravity rule `trigger` conversion (`glob`/`model_decision`/`manual`), Antigravity
  `SKILL.md` frontmatter synthesis, workflow <-> command <-> manual Skill mapping, and
  custom agent frontmatter/tool translation across all three IDEs.
- **Standalone 90-IDE references, progressive sub-files & official-doc alignment**:
  - Split all 30 merged family docs into 90 standalone per-IDE reference files
    (`references/products/<id>.md`) plus **25** progressive category sub-files across
    11 major multi-surface IDEs (`references/products/<id>/<topic>.md`) verified against
    official vendor documentation.
  - Aligned `migrate_context.py` with official vendor docs: Antigravity canonical `url`
    (with `serverUrl` read compatibility), Claude Code `CLAUDE_CONFIG_DIR`, VS Code /
    Copilot `.github/hooks` + `.agents/skills`, Windsurf `.devin/` legacy paths, Cline
    `.cline/rules` default + `.clinerules` legacy + `CLINE_MCP_SETTINGS_PATH`, Kiro
    `inclusion: auto` round-trip, Junie `.junie/AGENTS.md` + `.junie/rules` primary &
    `.junie/guidelines.md` legacy, Roo Code unconditional rules without silent glob
    widening, Qoder & Gemini CLI `hooks` in `settings.json`, Augment `.augment/settings.json`,
    Factory Droid `hooks.json` + `.agents/skills`, and OpenCode `.opencode/opencode.json`.
  - Expanded built-in profiles declaratively from 26 to **40** (adding `continue`, `amp`,
    `goose`, `devin`, `warp`, `openhands`, `aider`, `comate`, `minimax-code`,
    `mistral-vibe`, `crush`, `forge`, `codely`, `zcode`), added `inspect --list-profiles`,
    and added the generic out-of-band full-copy `copy-files` primitive alongside
    `sync-skills` and `patch-mcp`.
  - Removed `skills-ref` completely from `validate-all.sh`, `.github/workflows/validate.yml`,
    and active tests/docs, and replaced hardcoded `ALLOWED`/`MAX_PACKAGE_BYTES`/prose-lock
    checks with rule-based package hygiene validation.
- **Zero stray folders, `agent_handoff`, & clean entrypoint**:
  Streamlined `SKILL.md` (<100 lines) and removed default `~/.agent-skills-setup-backups/`
  and `.migration-review/` parking in favor of opt-in `--backup-dir`, `--profiles` filtering
  on `import-device`, and structured `agent_handoff` stdout items for lossy translations.

## Unreleased — workflow, evidence and delivery review (2026-11-14)

- Clarify native CLI use and retired runtime commands without restoring an engine.
- Add Registry v2 interpretation rules: archived policies are evidence to recheck,
  not current write authority; compatibility remains per profile/surface/version.
- Add per-object delivery outcomes and separate syntax/discovery/activation/runtime
  results, preview zero-artifact rules, concurrent-edit checks and private recovery.
- Require checkout/version provenance when reporting local validation; retain older
  logs as user-reported until their source revision and evidence are available.
- Add 10 pending workflow scenarios and 10 structural/rubric regression checks.
  These are not new native-client passes; candidate remains `0.11.0-dev`.
- Publish only two additional on-demand Markdown references; no runtime or dependency
  is added and no historical product evidence date is refreshed by this review.

## Unreleased — `0.11.0-dev` (Agent-First + Zero-Context-Leak Script)

- **Agent-First Skill reset**: Retire the standalone `.acb` archive engine, signing/key
  CLI, SQLite transaction store, background sync, and generated compatibility claims;
  preserve historical source in Git history.
- **Zero-context-leak migration helper (`scripts/migrate_context.py`)**: Add a single
  self-contained Python 3.11+ stdlib script (`inspect`, `migrate`, `export-device`,
  `import-device`, `patch-mcp`) that migrates context and `.env`/MCP credentials
  out-of-band on disk (`0700` dirs, `0600` files & private backups, `--redact-secrets`
  option, Git-tracked file protection, zero secret values in `stdout`/`stderr`/`MIGRATION.md`).
- **90-profile progressive catalog**: Route all 87 historical identifiers plus 25 new
  product/profile names across 30 on-demand `references/products/*.md` files with
  concrete paths, container keys, frontmatter fields, and env interpolation guidance.
- **Repository & CI hardening**: Add 44 contract, catalog, torture, canary secret
  zero-leak, E2E workflow, and repo-consistency checks; pin GitHub Actions by SHA;
  enforce `PYTHONUTF8=1` and unmasked single-command CI steps (including separate
  official `skills-ref validate` steps) across Linux, macOS, and Windows.

Earlier release history is preserved in
[the historical changelog](docs/history/CHANGELOG-before-agent-first.md).
