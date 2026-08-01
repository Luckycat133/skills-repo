# Scripts

`smart-ide-migration.sh` resolves documented paths, previews or applies a
scoped migration, redacts supported credentials, and emits JSON evidence.
Start with `--help` or `--print-path` when a mapping is unfamiliar.

`ide-paths.tsv` is generated from `references/ide-paths.json`; regenerate it
with `sync-ide-reference-summaries.py`, never edit it directly. `common.sh` is
an internal helper.

`test-*.sh` files are maintainer regression suites run by `bash validate-all.sh`,
not local-IDE migration commands.
