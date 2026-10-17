# Restore mapped review material

Use when native ACB recipes do not cover selected configuration, including
Antigravity, Tuanjie and WorkBuddy. `review-restore.py` restores files and selected
fields through an explicit destination mapping. It does not pretend to be a
product's native import API. Existing cross-IDE `plan/apply/restore` adapters stay
the first choice for semantic conversion. This helper can map compatible captured
files or field schemas explicitly, including between clients after reviewing
target compatibility; it neither guesses nor renames native fields.

## Generate a destination mapping

Run each command with the bundled script's absolute path and a real packet path:

```sh
python3 -B scripts/review-restore.py template --packet /path/to/packet --destination-home /path/to/destination-home --workspace-map /path/to/workspaces.json --output /path/to/state/mapping.json
```

`workspaces.json` maps source workspace IDs from the packet's `scope.json` to
existing destination project directories. Omit it for user-only restoration.
The helper only generates data; it does not write configuration. Read
`pending_mappings`, every selected source's exclusions and the mapping before
planning. Unknown roots and SQLite-backed configuration require explicit native
targets; never import a source database or guess a UI database key on the target.

The AI edits the mapping, removing sources outside the requested restore scope
and resolving paths. Compatible structured sources targeting the same file are
merged into one transaction; conflicting selected fields still require review. All
outputs must lie under explicit `roots`, outside the packet. Example:

```json
{
  "schema_version": 1,
  "roots": ["/path/to/destination-home"],
  "entries": [
    {"client": "workbuddy", "source": "source-id-from-review-index", "target": "/path/to/destination-home/.workbuddy/skills/example", "conflict": "error"},
    {"client": "tuanjie", "source": "model-source-id", "target": "/path/to/destination-home/.codely/config.yaml", "format": "yaml", "conflict": "replace", "allow_reformat": true}
  ]
}
```

- `client` and `source` select an exact pair from `review/index.json`.
- Skills retain captured relative paths and ordinary executable modes. Redacted
  documents remain reviewed material; incomplete packages are skipped unless the
  mapping explicitly sets `accept_partial: true` after reviewing missing files.
  Cross-package and directory references resolve against the entire plan;
  unresolved references remain explicit tasks without discarding preserved files.
- Text requires `layout: "file"` for a single target file or `"directory"` for a
  captured directory. An explicit `files` object maps captured relative payload
  paths to target-relative paths when names/layout need adaptation.
- Preferences use an explicit `format`: JSON, JSONC, TOML (Python 3.11+), or the
  bounded YAML subset described in the bundle workflow. Only captured safe fields
  are merged. Model lists match stable `id`, `name`, or model/provider identity;
  existing credential siblings and unrelated models survive.
- `conflict: "error"` preserves conflicting values. Choose `"replace"` only after
  reviewing which selected fields/files should adopt the source. This does not
  replace whole shared settings or unrelated destination fields.
- JSONC/TOML/YAML serialization can normalize formatting and remove comments.
  Existing files require explicit `allow_reformat: true` after reviewing that loss;
  semantic round-trip checks preserve parsed sibling values.
- `path_map` maps literal source path prefixes to destination paths. Structured
  values are remapped only at complete path-prefix boundaries; authored text uses
  the reviewed literal replacements. Values are data, never shell commands.
- MCP mappings additionally specify the native `container` (`mcpServers`,
  `servers`, `mcp`, or TOML `mcp_servers`). Definitions with missing authentication
  or omitted fields remain pending. Never activate placeholder credentials or
  invent native support for disabled/approval fields.
  Existing authentication siblings survive same-server merges. Changing an
  authenticated server's endpoint, executable or arguments requires separate
  native authentication review; generic `conflict: "replace"` does not rebind it.
- Hook sources preserve only selected `hooks`/`notify` fields and reviewed text
  dependencies. Management/trust state is excluded. The template leaves
  `activation_reviewed: false`; inspect the native definition and every
  `dependency_targets` mapping before setting it to `true`. Missing/dynamic or
  rejected dependencies require reconstruction, not a blanket review flag.
  Captured scripts retain modes and use reviewed path replacements. Installed
  app binaries are recorded for rebinding, never copied. Shared settings retain
  unrelated events, credentials and target-only trust state. Run the client's
  native Hook review/trust flow separately and verify actual event behavior.
- Permission-rule text and automation sources remain pending separate native
  review. This helper never runs captured scripts, starts a service, schedules
  tasks or changes trust.

## Plan, apply, verify, undo

```sh
python3 -B scripts/review-restore.py plan --packet /path/to/packet --mapping /path/to/state/mapping.json --plan-out /path/to/state/restore.plan.json
python3 -B scripts/review-restore.py apply --packet /path/to/packet --mapping /path/to/state/mapping.json --plan-in /path/to/state/restore.plan.json --state-dir /path/to/state/transaction --yes
python3 -B scripts/review-restore.py verify --state-dir /path/to/state/transaction
python3 -B scripts/review-restore.py rollback --state-dir /path/to/state/transaction --yes
```

Review the saved plan's targets, statuses and `remaining_work`. Plans contain
hashes and field/source identities, never destination credential values. Changed
packet, mapping, target bytes, permissions or symlinks require a new plan. Apply
uses a fresh private state directory, saves local backups, writes atomically and
verifies hashes/modes. It refuses empty application and attempted transaction replay. Rollback validates every local backup before any writes and refuses
to overwrite files changed since application. Keep local backups on the target;
they may contain its pre-existing secrets and must not enter a portable packet.

After file verification, the AI checks actual native discovery, effective model
selection and MCP execution on that machine. Record these as separate evidence.
A source-machine isolated rehearsal proves file behavior only. Unsupported
formats, source omissions and authentication remain actionable tasks; they are
not counted as successful restores.
