# Verification and evidence

Read this reference after an approved apply or when explaining proof. Use
`--json` for automation rather than inventing a separate evidence harness.

The MCP evidence array contains:

- effective scope and status;
- canonical source and target paths;
- source SHA-256 before/after and `source_unchanged`;
- target existence, SHA-256, and parse validation; and
- backup path when one was created.

Report those fields together with any manual follow-up. Static parse success
does not prove credentials, OAuth, permissions, or server connectivity.

Then use the target's native discovery surface when available, such as
`claude mcp list`, `codex mcp list`, `opencode mcp list`, `opencode2 mcp list`,
`copilot mcp list`, or the IDE MCP panel. Read the selected target section in
[ide-registry.md](ide-registry.md) for the authoritative method.
