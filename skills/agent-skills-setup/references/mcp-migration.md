# MCP migration

Use this reference for `mcp`, `project-mcp`, or `--source-mcp-file` work.
The bundled converter currently understands validated JSON or JSONC server maps;
other formats are useful candidates for reviewed reconstruction.

## Target formats and boundaries

| Target | Automatic root/shape | Boundary |
|---|---|---|
| Cursor and common clients | `mcpServers` | Validate command or URL shape. |
| VS Code workspace | `servers` in `.vscode/mcp.json` | User MCP is active-Profile/UI managed; ask for the resolved path rather than guessing. |
| OpenCode V1 | direct servers under `mcp` | Default legacy-compatible target. |
| OpenCode V2 | servers under `mcp.servers` | Pass `--opencode-version v2`; convert enabled, timeout, and OAuth fields. |
| OpenClaw / ZCode | `mcp.servers` | Apply each target's documented transport rules. |
| Codex | `[mcp_servers.<name>]` TOML | Reconstruct manually and validate TOML. |
| Continue | YAML `mcpServers` array / project blocks | Reviewed manual reconstruction is clearer than object-map conversion. |
| Goose | YAML extensions with type-specific fields | Rebuild the YAML deliberately rather than treating JSON as equivalent. |

For Claude Desktop, the legacy local JSON is only one surface. Review local
integrations in **Settings → Extensions** and remote MCP in **Settings →
Connectors**; treat UI-managed entries as a review topic rather than inferring
them from JSON.

## Conversion procedure

1. Identify command/args/env or URL/headers after confirming one endpoint
   shape.
2. Apply the credential rules in [migration-safety.md](migration-safety.md).
   Translate exact Cursor `${env:NAME}` to OpenCode `{env:NAME}` when relevant.
3. Convert root and target-specific fields. For ambiguous transports,
   conflicting fields, or invalid target JSON, explain the ambiguity and offer
   a manual path.
4. Apply the selected conflict strategy to the server map while preserving
   unrelated settings.
5. Parse the written target and emit JSON evidence.

`--source-mcp-file <file>` accepts one readable JSON/JSONC file and one scope.
The current script rejects `--scope both`, resolves symlinks, expects the
declared source root/schema, and does not offer a copy-as-is fallback. It
changes only the input location:
`--source` still selects the schema/root and the target registry plus workspace
still select output. Continue/Goose YAML and Codex TOML remain manual even when
the user points at a file.

When YAML or TOML is involved, a reviewed reconstruction and validation is a
good default. For Codex, reconstruct `[mcp_servers.<name>]` in the reviewed user
or trusted project `config.toml`, validate TOML, then run `codex mcp list`.

## Commands

~~~bash
# Preview an explicit Cursor project MCP export.
bash scripts/smart-ide-migration.sh \
  --source cursor --target opencode --workspace /path/to/project \
  --objects project-mcp --source-mcp-file /path/to/export.json \
  --dry-run --json

# Apply only after the user approves that preview.
bash scripts/smart-ide-migration.sh \
  --source cursor --target opencode --workspace /path/to/project \
  --objects project-mcp --source-mcp-file /path/to/export.json \
  --strategy backup --yes --json
~~~
