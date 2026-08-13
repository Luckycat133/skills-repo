# Scripts

`smart-ide-migration.sh` is the public wrapper. Its profile-aware commands are
`detect`, `inventory`, `plan`, `apply`, `verify`, and `rollback`. Always save a
plan with `plan --output plan.json`; `apply plan.json --yes` verifies the plan
checksum, Registry digest, adapter versions, resolved source/target state, and
Git HEAD before any write. Apply emits a checksummed manifest with exact
backups. `--json` reserves stdout for one JSON document and sends diagnostics
to stderr.

Calls beginning with legacy flags remain available for discovery and dry-run
compatibility. Every legacy `--yes` write fails before the retained
compatibility engine runs; use a saved profile-aware plan. The legacy engine is
internal and rejects ordinary direct execution.

The Skill declares local file-read, file-write, and shell capabilities only.
MCP targets that are symbolic links fail before conversion. Redaction cleanup
can remove only the exact target artifacts; copied-skill cleanup must remain
inside its canonicalized target copy root.

`scan-skill-secrets.py` checks every regular source file before a Skill copy and
reports only relative paths and reason categories, never credential values.
`ide-paths.tsv` is generated from `references/ide-paths.json`; regenerate it
with `sync-ide-reference-summaries.py`, never edit it directly. `common.sh` is
an internal helper.

`check-doc-freshness.py` validates source/freshness metadata offline and can
fetch a curated set of official documents with `--online --report`. The weekly
workflow stores that report as an artifact.

`test-*.sh` files are maintainer regression suites run by `bash validate-all.sh`,
not local-IDE migration commands. Legacy converter suites opt into the private
guard explicitly; `test-legacy-registry-gate.sh` covers the public boundary.
