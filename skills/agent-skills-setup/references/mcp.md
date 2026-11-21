# MCP migration: translate server definitions without leaking secrets

Treat server name, transport, command/args, `cwd`, environment bindings, URL/headers,
timeout units, disabled state, tool filters, and credentials as distinct fields.
Use `scripts/migrate_context.py` (`migrate` or `patch-mcp`) whenever MCP entries may
contain API keys, tokens, or auth headers so raw secret values never enter LLM context.

## Secret handling: out-of-band by default, `--redact-secrets` on request

1. **Zero LLM exposure**: Never `cat` raw `mcp.json`, `~/.claude.json`,
   `.gemini/settings.json`, or `.codex/config.toml` into prompt context to copy keys.
   `scripts/migrate_context.py` moves literal credentials disk-to-disk with `0600`
   permissions and prints only key names, `has_secrets`, and `sha256[:8]` on `stdout`.
2. **Default out-of-band transfer**: Preserves `${VAR}` / `${env:VAR}` placeholders as
   variable references and copies literal API keys/headers to the destination in `0600`
   mode (creating a `0600` backup of any existing target file in a `0700` backup dir).
3. **Git-tracked target protection**: Never write literal secrets into a Git-tracked
   project file silently. When `.mcp.json` is tracked in Git, `migrate_context.py`
   automatically routes secret-bearing Claude Code MCP servers to untracked local
   `~/.claude.json` (`projects[workspace].mcpServers`) and warns. For other tracked
   targets, it refuses with exit code `2` unless `--redact-secrets`, `--scope user`,
   or `--allow-git-tracked-secrets` is specified.
4. **Explicit redaction (`--redact-secrets`)**: When the user says "don't copy keys" or
   prepares a committed config, pass `--redact-secrets` to convert literal secrets into
   target placeholders (`${VAR}`, VS Code `${env:VAR}`, or Codex `env_vars = ["VAR"]`
   / `bearer_token_env_var`). Never transfer OAuth access/refresh tokens or `trust` /
   `alwaysAllow` / `autoApprove` grants.

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
| Antigravity / Windsurf | `.agents/mcp_config.json`, `~/.gemini/antigravity/mcp_config.json`, `~/.codeium/windsurf/mcp_config.json` | `mcpServers` (`serverUrl` for remote HTTP) |
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
