# Context transfer

This folder (`0700` directory, `0600` files) contains reviewed AI coding context, not
an installer or an instruction to execute bundled scripts. On the destination machine,
verify checksums and restore via `migrate_context.py import-device` (or inspect and map
manually). **No raw secret values or private local usernames appear in this file.**

- Source products/profiles: `<names and version evidence>`
- Requested scopes: `<user / project / all>`
- Secret policy: `<out-of-band in 0600 files (SHA-256[:8] below) | redacted (--redact-secrets)>`

| Bundle file | Source profile & scope | Category / target | Secret keys (`sha256[:8]` only) / notes |
| --- | --- | --- | --- |
| `<files/...>` | `<profile / user or project>` | `<logical $HOME or $WORKSPACE path>` | `<VAR_NAME (a1b2c3d4) or none>` |

- Excluded non-portable state: `<chat histories, transcripts, DBs, caches, OAuth/trust grants>`
- Parked drafts: `<review/hooks/... or unmapped scoped rules needing explicit approval>`
- Verification performed: `<manifest SHA-256 + JSON/TOML/frontmatter syntax>`
- Not verified: `<destination native IDE discovery and live MCP runtime connections>`
