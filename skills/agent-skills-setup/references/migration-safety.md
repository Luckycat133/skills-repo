# Migration safety and conflicts

Use before a migration can write. A generic request to migrate or transfer authorizes planning only. Inspect only the explicitly named source, target, objects, scope, and workspace; if any is missing, stop before filesystem inspection. Save the profile-aware plan and show its exact file list/diff or cloud rebuild actions and target paths. Obtain separate explicit user approval before `apply` or `rollback`; `--yes` records that approval but does not replace it. Apply only the reviewed plan: its checksum binds the Registry digest, adapter versions, resolved surfaces, source/target hashes, and Git provenance. Any drift requires a new review. Inventory canonical and compatibility paths; if more than one alternative exists, stop for explicit selection, and if multiple precedence files exist, do not pretend they are one document. Before copying a Skill directory or converting instructions, scan the source and reject likely literal credentials. Reject links outside a Skill root, exclude `.env` and `.env.*`, and preserve the source.

Apply stages and validates every output before the first target mutation, snapshots every destination, then commits the saved plan as one operation. A failure in any later write or in manifest creation restores every earlier target in reverse order; no partial success is reported. Plan and manifest artifact paths must not overlap the Registry or any selected source/target surface. The manifest is written only after all target hashes are recorded.

## Device handoff and Agent Context Bundle (ACB) safety

- ACB bundles (`<name>.acb/`) package reviewed objects offline without capturing machine-specific paths, local usernames, or Git commits.
- Bundles must pass `bundle-verify` against `checksums.json` before restore.
- Credential redaction (`assert_no_lateral_secrets`) scans all bundle JSON and files; any literal token or secret immediately halts bundling.
- Restoring a bundle requires explicit user approval (`--yes`) and writes only approved target paths.

## Surface and runtime boundaries

- **Plugins & Extensions**: Binary packages and executable plugins are not auto-installed or executed; they are recorded as `draft-disabled` or `manual-rebuild`.
- **Sessions & Runtime State**: Interactive chat logs, runtime tokens, OAuth tokens, and approval grants are strictly non-migratable and excluded.
- **Probes & Diagnostics**: `detect` and `doctor` run local filesystem and binary checks only; network access is forbidden.

Use [mcp-transport.md](mcp-transport.md) for remote transport, OAuth, or protocol state. The script blanks literal credentials and may translate an exact documented environment reference; mixed or complex expressions need manual reconstruction. MCP target symlinks fail before conversion. Redaction cleanup accepts only the exact target artifacts, while copied-skill cleanup is contained within the canonical target copy root.

| Strategy | Existing selected object |
| --- | --- |
| `skip` | Leave unchanged. |
| `backup` (default) | Save `.bak.<timestamp>`, then merge. |
| `overwrite` | Replace only the selected object, without backup. |

For shared MCP configuration, preserve unrelated settings; `overwrite` replaces only the selected server map. Do not invent renamed fallback entries.

The explicit `legacy` subcommand supports lookup and zero-write dry-runs only. Calls beginning with an implicit legacy flag are rejected. Any `legacy --yes` write fails before the compatibility engine runs; create and apply a saved profile-aware plan instead.

Restate source, target, objects, scope, workspace, and boundaries. After review, use `apply <plan.json> --yes --json`; report checksums, paths, parse result, source integrity, target evidence, backup, and manual follow-ups.
