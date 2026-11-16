# Changelog

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
- **Repository & CI hardening**: Add 40+ contract, torture, canary secret zero-leak,
  and E2E workflow checks; pin GitHub Actions by SHA; enforce `PYTHONUTF8=1` and
  unmasked per-Skill official `skills-ref validate` steps across Linux, macOS, and Windows.

Earlier release history is preserved in
[the historical changelog](docs/history/CHANGELOG-before-agent-first.md).
