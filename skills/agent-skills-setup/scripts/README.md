# Scripts

`smart-ide-migration.sh` resolves documented paths, previews or applies a
scoped migration, redacts supported credentials, and emits JSON evidence.
Start with `--help` or `--print-path` when a mapping is unfamiliar. It never
prompts: use `--dry-run` for zero-write review and add `--yes` only after
approval. `--json` reserves stdout for one JSON document and sends diagnostics
to stderr; exit code 2 means the write gate refused an unconfirmed apply.
Lifecycle-restricted IDs may be source-only; currently `firebase-studio` can
only export existing workspace rules to a maintained target.

`ide-paths.tsv` is generated from `references/ide-paths.json`; regenerate it
with `sync-ide-reference-summaries.py`, never edit it directly. `common.sh` is
an internal helper.

`test-*.sh` files are maintainer regression suites run by `bash validate-all.sh`,
not local-IDE migration commands.
