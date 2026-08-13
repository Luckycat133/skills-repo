# MCP migration

Use for the profile-aware `mcp` object. The automatic core accepts the reviewed stdio subset of JSON and JSONC server maps. Remote HTTP/SSE requires a dedicated target-profile transport adapter and currently produces reconstruction actions; read [mcp-transport.md](mcp-transport.md) for remote URLs, OAuth, or headers.

| Target | Automatic shape | Boundary |
| --- | --- | --- |
| Common clients | `mcpServers` | Automatic for reviewed stdio `command`/`args`/`env`; permission and lifecycle fields enter the loss report. |
| Registered JSON/JSONC profiles | Profile-specific root key | Validate command/URL and preserve unrelated keys. |
| TOML/YAML/JSON5/XML/Lua | Dedicated manual adapter | Generate a reviewed reconstruction; never use JSON fallback. |
| Cloud/UI profiles | Rebuild manifest | Use the official API/UI; never invent a local file. |

Validate command/args/env or URL/headers, apply [migration-safety.md](migration-safety.md), convert only target-supported fields, preserve unrelated settings, parse the target, and emit a credential-free diff. Ambiguous transport, OAuth/session state, unknown schema, and non-automatic adapters remain manual.

~~~bash
bash scripts/smart-ide-migration.sh plan \
  --source cline/ide --target forge/cli --workspace /path/to/project \
  --objects mcp --scope project --output /path/to/plan.json --json
~~~
