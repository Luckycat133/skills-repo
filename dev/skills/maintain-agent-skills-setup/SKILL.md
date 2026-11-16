---
name: maintain-agent-skills-setup
description: >-
  Maintain Luckycat133/skills-repo as an agent-first context-migration Skill
  with a zero-context-leak stdlib helper script. Use for checking vendor docs,
  refining format conversions and scripts/migrate_context.py, running the
  real-agent/client acceptance queue, updating evidence, or packaging the Skill.
  Not for migrating an end user's context directly.
license: MIT
metadata:
  version: "1.2"
---

# Maintain an Agent-First Skill + Safe Out-of-Band Script

Keep the owner's architecture boundary intact. Do not reintroduce the retired `.acb`
bundle format, Ed25519 signing/key service, SQLite state store, background sync,
auto-installer, telemetry, or generated product-pair matrix.

The distributable package (`skills/agent-skills-setup/`) ships only `SKILL.md`,
`references/`, `assets/`, `LICENSE`, and `scripts/migrate_context.py` (a single
self-contained Python 3.11+ stdlib helper with PEP 723 metadata).

## Read first

Read root `AGENTS.md`, `skills/agent-skills-setup/SKILL.md`, and only the affected
references. Read [acceptance](references/acceptance.md),
[remaining work](references/remaining-work.md),
[real-client test procedure](references/client-tests.md), and
[research method](references/research-method.md). Check the current branch and HEAD
commit before editing; never hardcode stale commit SHAs.

The 2026-11-07 catalog routes all 87 historical identifiers plus new clients and
profiles across 90 records in 30 family references. It is documentation coverage,
**not runtime certification**. `docs/research/catalog-2026-11-07.json` is maintainer
bookkeeping; `evals/client-matrix.json` is the native-client acceptance queue.
Historical notes under `docs/history/` are clues only, never active contracts.

## Hard security invariants for `scripts/migrate_context.py`

- **Zero LLM secret exposure**: Move sensitive config values (API keys, MCP
  `env`/`headers`, `.env*` files) strictly out-of-band on disk by default (and honor
  `--redact-secrets` when requested). Never print secret values to `stdout`, `stderr`,
  or `MIGRATION.md`; emit only variable/key names, `has_secrets`, and 8-hex-char
  SHA-256 prefixes (`sha256[:8]`).
- **Strict permissions & private backups**: Enforce `0700` on secret/backup/transfer
  directories and atomic `0600` writes on secret-bearing, backup, and transfer files.
  Keep backups outside auto-loaded context trees and `/tmp` by default.
- **Git-tracked protection**: Refuse silent writes of literal secrets into Git-tracked
  workspace files (or route to untracked local config such as `~/.claude.json`
  `projects[workspace].mcpServers` with explicit reporting).
- **Non-portable exclusions**: Always exclude chat histories, transcripts, SQLite/LevelDB
  databases, vector indexes, caches, session cookies, and approval/trust grants.

## When asked to run the tests

1. Run `bash validate-all.sh` (unit, contract, catalog, torture tests, and `skills-ref`
   when installed). Do not call structural or script tests a real native-IDE pass.
2. Read `evals/cases.json` and `evals/catalog-cases.json`. Use isolated fixture roots
   and synthetic canary values only; never touch the operator's real `HOME` without
   separate authorization.
3. Execute available rows in `evals/client-matrix.json` per
   [client-tests.md](references/client-tests.md). Unavailable clients stay
   `blocked-environment`, never `pass`.
4. Save redacted traces, before/after diffs, native discovery proof, negative scope
   checks, unchanged neighbors, and repeat-run outcomes via
   [result template](references/result-template.md).
5. Fix the smallest script/guidance gap and re-run both positive and negative cases.
   Summarize `pass`, `fail`, `blocked-*`, and `not-run` separately.

## Editing and review rules

- Keep `skills/agent-skills-setup/SKILL.md` under 140 lines and total packaged size
  under `MAX_PACKAGE_BYTES` (`260,000` bytes).
- Preserve instruction scope/activation, manual invocation (`disable-model-invocation`),
  env-name mapping, target neighbors, and per-object conflict isolation.
- Park hooks and executable workflows outside live discovery paths unless explicitly
  authorized (`--activate-hooks`).
- Publication, tags, marketplace uploads, and account/payment changes require separate
  owner authorization.
