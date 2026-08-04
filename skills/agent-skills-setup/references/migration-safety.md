# Migration safety and conflicts

Use before a migration can write. Inspect only the named source, target, and workspace; reject source/target identity and unsupported formats. Before copying a Skill directory, scan every regular text file and reject the whole Skill if likely literal credentials or a link outside its source root is found. Existing rules and prompt targets use `backup` by default; `skip` preserves them and `overwrite` is explicit. Exclude `.env` and `.env.*`; preserve the source.

Use [mcp-transport.md](mcp-transport.md) for remote transport, OAuth, or protocol state. The script blanks literal credentials and may translate an exact documented environment reference; mixed or complex expressions need manual reconstruction. MCP target symlinks fail before conversion. Redaction cleanup accepts only the exact target artifacts, while copied-skill cleanup is contained within the canonical target copy root.

| Strategy | Existing selected object |
| --- | --- |
| `skip` | Leave unchanged. |
| `backup` (default) | Save `.bak.<timestamp>`, then merge. |
| `overwrite` | Replace only the selected object, without backup. |

For shared MCP configuration, preserve unrelated settings; `overwrite` replaces only the selected server map. Do not invent renamed fallback entries.

Restate source, target, objects, scope, workspace, boundaries, and strategy; offer an exact value-free `--dry-run`. After approval, use `--yes` and usually `--json`; report paths, parse result, source integrity, target evidence, backup, and manual follow-ups.
