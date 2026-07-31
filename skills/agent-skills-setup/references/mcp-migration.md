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

## Protocol compatibility boundary

This workflow migrates **client configuration**, not MCP wire-protocol state.
The client and server negotiate the protocol version at runtime; do not add or
copy `MCP-Protocol-Version`, `Mcp-Session-Id`, `Last-Event-ID`, handshake,
subscription, or request metadata fields into a client server entry.

Execution approvals are also target-local policy. The converter removes
`autoApprove`, `enabledTools`, and `disabledTools`; do not recreate them during
manual reconstruction. Review and grant tool access in the target client after
the imported server has been verified.

For the 2026-07-28 MCP revision, Streamable HTTP uses one MCP endpoint with a
POST per JSON-RPC message. It can return a request-scoped SSE response, but it
is not the deprecated HTTP+SSE transport. In particular:

- Treat an explicit `sse` label as legacy transport compatibility. Preserve it
  only when the selected target documents that same label; never relabel it to
  `http`, `streamable-http`, `streamableHttp`, or `httpUrl` automatically.
- Treat an explicit Streamable HTTP label as portable only when the selected
  target documents its corresponding field and spelling. A bare `url` does not
  identify a transport.
- Do not rewrite a server URL merely because it contains an older protocol date
  or an `/sse` path. The server owner, not the migration tool, publishes a
  replacement endpoint.
- Copy no OAuth access/refresh-token cache, session identifier, or dynamic
  registration state. Preserve only reviewed, target-supported connection
  metadata; complete authorization again in the target client and bind any
  stored credential to the issuing authorization server.

See the [MCP 2026-07-28 key changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog),
[Streamable HTTP transport](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/streamable-http),
and [authorization requirements](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization).

For Claude Desktop, the legacy local JSON is only one surface. Review local
integrations in **Settings → Extensions** and remote MCP in **Settings →
Connectors**; treat UI-managed entries as a review topic rather than inferring
them from JSON.

## Conversion procedure

1. Identify command/args/env or URL/headers **and the explicit transport**
   after confirming one endpoint shape. Stop for review when a remote URL has
   no target-supported transport discriminator or uses legacy `sse`.
2. Apply the credential rules in [migration-safety.md](migration-safety.md).
   Translate exact Cursor `${env:NAME}` to OpenCode `{env:NAME}` when relevant.
3. Convert root and target-specific fields without emitting protocol-runtime
   metadata or upgrading transports. For ambiguous or legacy transports,
   conflicting fields, OAuth state, or invalid target JSON, explain the
   ambiguity and offer a manual path.
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
