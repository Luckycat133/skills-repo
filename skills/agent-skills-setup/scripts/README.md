# Scripts

## Agent-facing entry points

- `smart-ide-migration.sh` — resolves documented paths, previews or applies a
  scoped migration, redacts supported credential forms, and can emit JSON
  evidence. Start with `--help` or `--print-path` when an IDE/object mapping is
  unfamiliar.

## Maintainer regression suites

Files named `test-*.sh` are repository regression tests. They are run by
`bash validate-all.sh`; they are not migration commands for a user's local IDE
configuration. Individual tests focus on one compatibility boundary, such as
MCP redaction, conflict strategy, or an IDE mapping.

`common.sh` supplies internal helpers for the migration engine. It is sourced
by scripts rather than run directly.
