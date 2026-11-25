# MCP migration: translate server definitions without leaking secrets

Treat server name, transport, command/args, `cwd`, environment bindings, URL/headers,
timeout units, disabled state, tool filters, and credentials as distinct fields.
Use `scripts/migrate_context.py` (`migrate` or `patch-mcp`) whenever MCP entries may
contain API keys, tokens, or auth headers so raw secret values never enter LLM context.

## Secrets: transfer out of band or explicitly redact

- Never load raw MCP config into LLM context. The helper moves credentials
  disk-to-disk with `0600` files and `0700` backup directories; stdout only reports
  names, `has_secrets`, and `sha256[:8]`.
- Preserve environment references. For tracked Claude `.mcp.json`, the helper routes
  secret-bearing entries to untracked `~/.claude.json` under `projects[workspace].mcpServers`.
  Other tracked targets refuse (exit 2) unless using `--redact-secrets`, `--scope user`,
  or explicit `--allow-git-tracked-secrets`.
- Use `--redact-secrets` when told not to copy keys or when preparing a commit.
  It replaces literals with target bindings (`${VAR}`, VS Code `${env:VAR}`, or
  Codex `env_vars = ["VAR"]` / `bearer_token_env_var`). Never copy OAuth access or
  refresh tokens, trust, `alwaysAllow`, or `autoApprove` grants.

For stdio `cwd`, OpenCode 1.17.4+ accepts literal absolute paths and native
workspace-relative paths. Defer unverified relative bases or variable expansion.
Zed has no per-server working-directory field; entries requiring one are deferred.

## Worked example: JSON stdio to Codex TOML

Source `mcpServers` definition:

```json
{
  "mcpServers": {
    "project-tools": {
      "command": "node",
      "args": ["tools/project-server.mjs"],
      "env": {"PROJECT_TOKEN": "${PROJECT_TOKEN}"}
    }
  }
}
```

Surgically merge into `.codex/config.toml` (project) or `~/.codex/config.toml` (user),
preserving existing keys such as `approval_policy`:

```toml
[mcp_servers.project-tools]
command = "node"
args = ["tools/project-server.mjs"]
env_vars = ["PROJECT_TOKEN"]
```

- **Env-name rename trap**: `env_vars` forwards only **identically named** host
  variables. Converting `"SERVER_TOKEN": "${HOST_TOKEN}"` into `env_vars = ["HOST_TOKEN"]`
  fails to deliver `SERVER_TOKEN` to the server, and `[mcp_servers.x.env]` in TOML does
  not expand `${...}` strings. Defer and record a rebinding step when names differ.
- **Literal secrets in Codex TOML**: When migrating literal secrets out-of-band (not
  `--redact-secrets`), `migrate_context.py` writes `[mcp_servers.<name>.env]` on disk
  (`0600`) while emitting only `sha256[:8]` on `stdout`.

## Container keys and schema differences across clients

Consult [products.md](products.md) before selecting `--src-key-path` / `--dst-key-path`
for `patch-mcp`:

| Client / Profile | File path (project / user) | Container key & shape |
| --- | --- | --- |
| Cursor | `.cursor/mcp.json`, `~/.cursor/mcp.json` | `mcpServers` (`url`, `env`, `headers`) |
| Claude Code | `.mcp.json`, `~/.claude.json` (`mcpServers` & `projects[ws].mcpServers`) | `mcpServers` (`type: "http"\|"sse"`, `url`) |
| Codex | `.codex/config.toml`, `~/.codex/config.toml` | TOML `[mcp_servers.<name>]` (`env_vars`, `env`, `bearer_token_env_var`) |
| VS Code (Local) | `.vscode/mcp.json`, profile `mcp.json` | `servers` (`type: "stdio"\|"http"`, `${env:VAR}`, `${input:ID}`) |
| Copilot CLI | `~/.copilot/mcp-config.json` | `mcpServers` |
| Gemini CLI | `.gemini/settings.json`, `~/.gemini/settings.json` | `mcpServers` (`httpUrl` for Streamable HTTP, preserve sibling keys) |
| Antigravity | `.agents/mcp_config.json`, `~/.gemini/config/mcp_config.json` (legacy `~/.gemini/antigravity/mcp_config.json`) | `mcpServers` (`serverUrl`, `timeoutSeconds`, `enabledTools`/`disabledTools`; legacy SSE deferred) |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` | `mcpServers` (`serverUrl` for remote HTTP) |
| Cline | `~/.cline/data/settings/cline_mcp_settings.json` | `mcpServers` (never copy `~/.cline/data/tasks` or DBs) |
| Zed | `.zed/settings.json`, `~/.config/zed/settings.json` | `context_servers` (`command: {"path", "args", "env"}`) |
| OpenCode | `opencode.json`, `~/.config/opencode/opencode.json` | V1 `mcp` / V2 `mcp.servers` (`command: [...]`, `environment: {...}`) |
| Pi | `.pi/mcp.json`, `~/.pi/agent/mcp.json` | `mcpServers` (preserve sparse knob-only `{"enabled": false}` overrides) |
| Kimi Code / Qwen / Kilo | `.kimi-code/mcp.json`, `.qwen/settings.json`, `.kilo/mcp.json` | `mcpServers` |

## Review and validation

Validate generated JSON/JSONC/TOML with a real parser (`migrate_context.py` validates
with `json.loads` / `tomllib.loads` before atomic replacement). Show only a redacted
semantic summary: server names, transports, secret variable names (`sha256[:8]`),
preserved sibling settings, and conflicts. Never run `npx`/`uvx` installers or start
untrusted servers merely to validate syntax.

Evidence consulted 2026-11-07:
[Codex MCP](https://developers.openai.com/codex/mcp),
[VS Code MCP](https://code.visualstudio.com/docs/agent-customization/mcp-servers),
[Gemini CLI MCP](https://geminicli.com/docs/tools/mcp-server/),
[Claude Code MCP](https://code.claude.com/docs/en/mcp).
