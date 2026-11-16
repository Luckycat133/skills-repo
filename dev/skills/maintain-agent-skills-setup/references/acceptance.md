# Acceptance criteria

A migration succeeds only when intended user content arrives in a target surface
that recognizes it, with no silent scope, activation, invocation, or permission
widening. Unsupported fields become explicit losses or parked drafts.

Required invariants:
- Source files unchanged; unrelated target settings, comments, and sibling objects preserved.
- Independent non-conflicting objects apply even when one sibling conflicts; same-content re-run is a `noop`.
- Sensitive credentials (API keys, MCP `env`/headers, `.env*` files) transfer strictly out-of-band on disk in `0700` directories / `0600` files by default (or are stripped when `--redact-secrets` is requested), with **zero** raw secret exposure in LLM context, `stdout`, `stderr`, or `MIGRATION.md` (only key names and `sha256[:8]`).
- Git-tracked target files never silently receive literal secrets without explicit authorization or local-config routing.
- OAuth/session cookies, chat histories, transcripts, SQLite/LevelDB databases, caches, indexes, and approval/trust grants are always excluded.
- Executable hooks/workflows stay parked outside live discovery paths unless `--activate-hooks` is explicitly approved.
- Preview (`--dry-run`) performs zero filesystem writes and creates zero backup directories.

All requested context categories must be inventoried (`instructions`, `skills`, `prompts`,
`commands`, `agents`, `hooks`, `workflows`, `mcp`, `authored-memory-knowledge`,
`plugins-extensions`, `settings-policy-trust`). Unknown formats require official/local
evidence, never guessed paths.

Repository checks (`bash validate-all.sh`): entrypoints stay concise; links and `#anchors`
resolve; catalog Column 1 routes every canonical ID and alias; real-client status is
never fabricated; the publishable archive contains only the explicit allowlist
(`SKILL.md`, `references/`, `assets/`, `LICENSE`, and `scripts/migrate_context.py`),
excludes `dev/`, `evals/`, `docs/`, and `tests/`, stays under `220,000` bytes, is
reproducible, and refuses clobbering. Structural/script checks do not replace
[client-tests.md](client-tests.md).
