# Authorized private provider transfer

Use this separate channel when the user authorizes migration of provider definitions
and API keys. Ordinary ACB/device captures still redact or reject secrets. Do not
add credentials to Git, ordinary capture specs, plain reports or unencrypted handoff
files. This POSIX (macOS/Linux) helper needs local Python 3 and Node.js; it installs and connects to
nothing. Its format is distinct from `crouter.crm`; use crouter's own migration
commands for that file.

## Select the exact source surfaces

Inspect source configuration without printing secret values. Write a private local
JSON spec. Its only root keys are `entries` and optional `source_home`; there is no
`schema_version` field. `source_home` defaults to the exporting user's HOME and is
recorded inside the encrypted artifact. Use absolute source paths and relative
HOME destinations. This illustrative spec selects provider fields and two exact
SQLite item keys; replace paths and selectors with verified source identities:

```json
{
  "source_home": "/absolute/source-home",
  "entries": [
    {
      "id": "selected-providers",
      "client": "tuanjie",
      "kind": "json-fields",
      "path": "/absolute/source-home/.codely/settings.json",
      "relative_target": ".codely/settings.json",
      "fields": [
        "customModelProvider", "customModelProviders", "customModels",
        "migratedToSingleProvider", "migratedToMultiProvider"
      ]
    },
    {
      "id": "selected-mcp",
      "client": "claude-code",
      "kind": "json-fields",
      "path": "/absolute/source-home/.claude.json",
      "relative_target": ".claude.json",
      "fields": [["mcpServers", "selected-server"]],
      "home_paths": [["mcpServers", "selected-server", "command"]]
    },
    {
      "id": "selected-model-records",
      "client": "trae",
      "kind": "sqlite-items",
      "path": "/absolute/source-home/Library/Application Support/SelectedIDE/User/globalStorage/state.vscdb",
      "relative_target": "Library/Application Support/SelectedIDE/User/globalStorage/state.vscdb",
      "keys": ["exact.model_list_map.first", "exact.model_list_map.second"]
    }
  ]
}
```

Each entry requires `id`, `client`, `kind`, `path`, `relative_target`:

- `json-fields` additionally requires `fields`: root field names or arrays of
  nested property names. Select credential-bearing subtrees precisely; selecting
  an entire MCP definition also captures its command and arguments. Existing
  unselected target siblings remain unchanged. All selected source fields must exist.
- `sqlite-items` additionally requires `keys`: exact `ItemTable` keys. It reads a
  normal read-only SQLite transaction including committed WAL values, without
  copying the full database. Text, blobs, integers, real values and null retain
  their SQLite types. All selected keys must exist. The target must use the plain
  `ItemTable(key,value)` table without triggers; other target rows remain unchanged.
- `json-file` selects a complete, dedicated JSON object/array file and accepts no
  `fields` or `keys`. Use only for an explicitly reviewed provider/API-auth file,
  never as a shortcut for a shared application configuration.
- Optional `home_paths` is supported only for `json-fields`: exact property paths
  contained inside selected fields. Each must hold an absolute string starting
  with `source_home/`. Import and verify replace only that prefix with destination
  HOME. Other values, including keys and URLs containing the old HOME, remain exact.
  Paths containing traversal or noncanonical components are rejected. The helper
  does not expand shell variables or repair arbitrary command arguments.

Duplicate IDs, destinations or overlapping field selections are rejected.
Source files must be bounded ordinary files owned by the current user and not
writable by group/others; source/destination symlinks and hard links are rejected.
Source files are read without modification. Do not select native OAuth sessions,
trust state or approvals; destination account login remains a separate action.

## Export and transport

Create or reuse an explicitly authorized password file outside the packet. On
POSIX it must be an ordinary current-user-owned file with mode `0600`. Use at
least 16 UTF-8 bytes. One final LF or CRLF is ignored; all other whitespace remains
part of the passphrase. Never put the passphrase itself in command arguments or logs.

```sh
python3 skill/scripts/private-provider-transfer.py export \
    --spec /private/local/provider-scope.json \
    --output /private/local/providers.encrypted \
    --password-file /private/local/provider-password
```

An existing output is never overwritten. AES-256-GCM with a random salt/nonce and
scrypt protects the artifact; authentication precedes destination writes. Selected
payload plaintext crosses only anonymous pipes between Python and Node.js, with no
plaintext payload dump. Actual destination configuration files naturally contain
the restored credentials. Persisted rollback backups are encrypted.

Transport only the encrypted artifact through the authorized channel. Transfer the
passphrase separately; do not put its local file inside the packet. Keep an
artifact checksum in the handoff and record selected clients/fields without values.

## Destination merge and verification

Install required client versions separately. Close the affected IDE before import
to prevent its live state from overwriting restored settings. Preserve destination
changes and review differing selected fields; use `--replace` only when replacement
is already authorized. Without it, differing existing selected data blocks import.

```sh
python3 skill/scripts/private-provider-transfer.py import \
    /private/local/providers.encrypted \
    --home "$HOME" --password-file /private/local/provider-password --replace

python3 skill/scripts/private-provider-transfer.py verify \
    /private/local/providers.encrypted \
    --home "$HOME" --password-file /private/local/provider-password
```

Import validates all entries before writing, creates a private encrypted backup
under `.ai-ide-migration/private-provider-backups/`, merges selected fields/rows,
and reads back exact values with declared HOME mapping. Failed writes roll back
previous changes; SQLite busy errors are failures. Retain the encrypted backup if
rollback reports incomplete, and let the agent reconcile it before retrying.
There is no standalone backup-import command. Output reports IDs, field names,
key counts, status and sanitized failure reasons, never credential values.

`verify` proves only selected file/row equality on that machine. It does not prove
that the IDE discovered the provider, loaded a key, authenticated, or completed a
model/MCP request. Check native provider lists, selected defaults and harmless
runtime requests separately. Report reauthentication, missing executables and
other unresolved dependencies explicitly; do not claim the configuration is usable
solely because an encrypted export or offline verify passed.
