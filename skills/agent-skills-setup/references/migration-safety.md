# Migration safety and conflicts

Use before a migration can write. Inspect only the named source, target, and workspace; reject source/target identity and unsupported formats. Save the profile-aware plan and review its exact file list/diff or cloud rebuild actions. Apply only that saved plan: its checksum binds the Registry digest, adapter versions, resolved surfaces, source/target hashes, and Git provenance. Any drift requires a new review. Inventory canonical and compatibility paths; if more than one alternative exists, stop for explicit selection, and if multiple precedence files exist, do not pretend they are one document. Before copying a Skill directory or converting instructions, scan the source and reject likely literal credentials. Reject links outside a Skill root, exclude `.env` and `.env.*`, and preserve the source.

Apply stages and validates every output before the first target mutation, snapshots every destination, then commits the saved plan as one operation. A failure in any later write or in manifest creation restores every earlier target in reverse order; no partial success is reported. Plan and manifest artifact paths must not overlap the Registry or any selected source/target surface. The manifest is written only after all target hashes are recorded.

Use [mcp-transport.md](mcp-transport.md) for remote transport, OAuth, or protocol state. The script blanks literal credentials and may translate an exact documented environment reference; mixed or complex expressions need manual reconstruction. MCP target symlinks fail before conversion. Redaction cleanup accepts only the exact target artifacts, while copied-skill cleanup is contained within the canonical target copy root.

| Strategy | Existing selected object |
| --- | --- |
| `skip` | Leave unchanged. |
| `backup` (default) | Save `.bak.<timestamp>`, then merge. |
| `overwrite` | Replace only the selected object, without backup. |

For shared MCP configuration, preserve unrelated settings; `overwrite` replaces only the selected server map. Do not invent renamed fallback entries.

The legacy flag interface supports lookup and zero-write dry-runs only. Any legacy `--yes` write fails before the compatibility engine runs; create and apply a saved profile-aware plan instead.

Restate source, target, objects, scope, workspace, and boundaries. After review, use `apply <plan.json> --yes --json`; report checksums, paths, parse result, source integrity, target evidence, backup, and manual follow-ups.
