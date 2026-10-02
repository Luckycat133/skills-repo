# Script maintenance

`smart-ide-migration.sh` is the public offline wrapper. Use the
[public CLI workflow](../references/cli-workflow.md) for detection, inventory,
planning, apply, verification, rollback, and legacy lookup. Use the
[bundle workflow](../references/bundle-workflow.md) for snapshot, restore,
signing/key generation, bundle verification, and doctor diagnostics. Those
references are included in runtime packages; this file is maintainer guidance.

`migration_core.py`, `context-migrator.py`, `acb/`, `detect/`, `registry/`,
`skill_secret_scanner.py`, and the guarded legacy engine implement that wrapper.
Direct legacy execution and all legacy writes are disabled. Shell/Python,
filesystem, and environment capabilities remain offline and within authorized
scope; tests never grant permission to mutate a user's configuration.

## Maintainer helpers

- `scan-skill-secrets.py` scans regular source files before Skill copies and
  reports relative paths and reason categories, never credential values.
- `sync-ide-reference-summaries.py` regenerates reference summaries and
  `ide-paths.tsv` from `references/ide-paths.json`; edit the source JSON, not
  generated tables. `common.sh` is internal.
- `validate-registry-v2.py` validates registry structure and contracts.
  `generate-compatibility-matrix.py` renders repository compatibility guidance.
- `check-doc-freshness.py` validates official HTTPS provenance, schema, and
  `verified_at` freshness offline. It performs no network verification.

`test-*.sh` files are focused maintainer regression suites, run together by
`bash validate-all.sh` at the repository root. They are excluded from the
runtime package and must use isolated fixtures rather than real agent settings.
Legacy converter suites opt into the private test guard;
`test-legacy-registry-gate.sh` covers the public read-only boundary.
