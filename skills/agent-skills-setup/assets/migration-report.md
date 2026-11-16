# Migration report

- Request: `<user's intent>`
- Source -> destination: `<product/profile/version evidence and OS/WSL/remote host>`
- Scope & secret mode: `<project/user/all; 0600 out-of-band or --redact-secrets>`

| Source object | Destination | Outcome | Notes / secret key names (`sha256[:8]` only) |
| --- | --- | --- | --- |
| `<$WORKSPACE/... or $HOME/...>` | `<target path>` | `<migrated/noop/conflict/parked_draft/deferred>` | `<scope/format note; never raw secret values>` |

## Verification

- Syntax & checksums: `<JSON/JSONC/TOML/frontmatter parse + 0600 file permissions>`
- Scope & neighbor preservation: `<matching/non-matching globs; unrelated keys intact>`
- Host discovery: `<observed in native client, or not-run and why>`
- Runtime / live connection: `<explicitly authorized result, or not-run>`

## Remaining work & recovery

- Pending actions: `<env rebinding, OAuth re-auth, parked hooks in .migration-review/, conflicts>`
- Private `0700`/`0600` backups: `<exact backup directory for modified files, or none overwritten>`
