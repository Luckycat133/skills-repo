# Changelog

## [0.11.1]

- Verify the latest stable, reviewed Skill release before use and route credential movements through the pinned migration helper so agents never open raw secret files.
- Keep the Skill descriptor, CLI and documentation entry points on the same version. The device-transfer manifest schema remains 1.

## [0.11.0]

### Workflow, evidence and delivery review (2026-11-14)

- Clarify native CLI use and retired runtime commands without restoring an engine.
- Add Registry v2 interpretation rules: archived policies are evidence to recheck,
  not current write authority; compatibility remains per profile/surface/version.
- Add per-object delivery outcomes and separate syntax/discovery/activation/runtime
  results, preview zero-artifact rules, concurrent-edit checks and private recovery.
- Require checkout/version provenance when reporting local validation; retain older
  logs as user-reported until their source revision and evidence are available.
- Add 10 pending workflow scenarios and 10 structural/rubric regression checks.
  These are not new native-client passes.
- Publish only two additional on-demand Markdown references; no runtime or dependency
  is added and no historical product evidence date is refreshed by this review.

### Agent-First + Zero-Context-Leak Script

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

- Document the lossless OpenCode working-directory migration and explicit deferred
  status for unsupported Zed or unrepresentable entries.

Earlier release history is preserved in
[the historical changelog](docs/history/CHANGELOG-before-agent-first.md).
