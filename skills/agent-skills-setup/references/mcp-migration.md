# MCP migration

Use for `mcp`, `project-mcp`, or `--source-mcp-file`. The converter accepts validated JSON/JSONC server maps; read [mcp-transport.md](mcp-transport.md) for remote URLs, transport, OAuth, or headers.

| Target | Automatic shape | Boundary |
| --- | --- | --- |
| Common clients | `mcpServers` | Validate command/URL. |
| VS Code workspace | `servers` in `.vscode/mcp.json` | User MCP is active-Profile/UI managed. |
| Visual Studio | `servers` in `.mcp.json` | Windows only; alternate discovery paths stay manual. |
| OpenCode V1/V2 | `mcp` / `mcp.servers` | V2 requires `--opencode-version v2`. |
| OpenClaw / ZCode | `mcp.servers` | Keep target transport rules. |
| Codex, Continue, Goose | TOML/YAML | Reconstruct and validate manually. |

Validate command/args/env or URL/headers, apply [migration-safety.md](migration-safety.md), convert only target-supported fields, preserve unrelated settings, parse the target, and emit JSON evidence. Exact Cursor `${env:NAME}` may become OpenCode `{env:NAME}`; ambiguous transport, OAuth state, bad schema, YAML, and TOML are manual.

**Embedded-config sources (e.g. Codely).** Some IDEs keep `mcpServers` *inside* a larger config file (Codely: `~/.codely-cli/settings.json`). The converter handles this without copying the whole file: on the source it extracts only the `mcpServers` sub-key (`read_path`), and on a Codely target it merges incoming servers into the existing `mcpServers` sub-key while preserving all other keys. Treat the surrounding config as manual-only (see [ides/codely.md](ides/codely.md)); the MCP sub-key is the safe auto-convertible subset.

`--source-mcp-file <file>` accepts one readable JSON/JSONC file and one scope; `--scope both` and copy-as-is fallback are rejected. It changes only input location: `--source` still selects the schema and target/workspace still select output.

~~~bash
bash scripts/smart-ide-migration.sh \
  --source cursor --target opencode --workspace /path/to/project \
  --objects project-mcp --source-mcp-file /path/to/export.json --dry-run --json
~~~
