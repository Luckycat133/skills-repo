# MCP migration: complete cross-IDE mapping & zero-leak rules

Treat server name, transport, command/args, `cwd`, environment bindings, URL/headers,
timeout units, disabled state, tool filters, and credentials as distinct fields.
Always use `scripts/migrate_context.py` (`migrate` or `patch-mcp`) whenever MCP entries
may contain API keys, tokens, or auth headers so raw secret values never enter LLM context.

## Secrets: transfer out-of-band (`0600`) or explicitly redact

- Never open raw MCP files into LLM context. The helper moves credentials disk-to-disk
  with `0600` files (and `0700` backups only when `--backup-dir` is explicitly given);
  stdout reports only server names, variable names, `has_secrets`, and `sha256[:8]`.
- For Git-tracked Claude `.mcp.json`, secret-bearing entries automatically route to
  untracked `~/.claude.json` (`projects[workspace].mcpServers`). Other tracked targets
  refuse (exit `2`) unless `--redact-secrets`, `--scope user`, or `--allow-git-tracked-secrets`.
- Use `--redact-secrets` when told not to copy keys (`${VAR}`, VS Code `${env:VAR}`, or
  Codex `env_vars = ["VAR"]` / `bearer_token_env_var`). Never copy OAuth tokens or
  `alwaysAllow`/`autoApprove`/`trust` grants.
- **Env-name rename trap**: Codex `env_vars` forwards only identically named variables;
  `"SERVER_TOKEN": "${HOST_TOKEN}"` with `--redact-secrets` defers rather than breaking.
- For stdio `cwd`, OpenCode accepts literal absolute paths and native workspace-relative
  paths; Zed lacks per-server `cwd` and defers entries requiring one.

## Complete 26-IDE built-in MCP path & schema table

| Profile ID | Project MCP file | User MCP file | Container key & schema quirks |
| --- | --- | --- | --- |
| `antigravity` | `.agents/mcp_config.json` | `~/.gemini/config/mcp_config.json` (legacy `~/.gemini/antigravity/mcp_config.json`) | `mcpServers` (`serverUrl` HTTP only; `timeoutSeconds`; `enabledTools`/`disabledTools`; legacy SSE deferred) |
| `claude-code` | `.mcp.json` (fallback `~/.claude.json` `projects[ws].mcpServers`) | `~/.claude.json` | `mcpServers` (`type: "http"\|"sse"`, `url`, `headers`) |
| `codex` | `.codex/config.toml` | `$CODEX_HOME/config.toml` | TOML `[mcp_servers.<name>]` (`env_vars`, `env`, `bearer_token_env_var`, `tool_timeout_sec`) |
| `cursor` | `.cursor/mcp.json` | `~/.cursor/mcp.json` | `mcpServers` (`url`, `env`, `headers`) |
| `vscode` | `.vscode/mcp.json` | profile `mcp.json` (via `patch-mcp`) | `servers` (`type: "stdio"\|"http"`, `${env:VAR}`, `${input:ID}`) |
| `copilot-cli` | `—` (routes to user if `--scope all`) | `~/.copilot/mcp-config.json` | `mcpServers` |
| `gemini-cli` | `.gemini/settings.json` | `~/.gemini/settings.json` | `mcpServers` (`httpUrl` for Streamable HTTP; sibling settings preserved) |
| `windsurf` | `—` | `~/.codeium/windsurf/mcp_config.json` | `mcpServers` (`serverUrl` for remote HTTP) |
| `cline` | `—` | `~/.cline/data/settings/cline_mcp_settings.json` | `mcpServers` (strips `alwaysAllow`/`disabled` grants appropriately) |
| `kilocode` | `.kilo/mcp.json` (legacy `.kilocode/mcp.json`) | `~/.kilo/mcp.json` | `mcpServers` |
| `zed` | `.zed/settings.json` | `~/.config/zed/settings.json` | `context_servers` (`command: {"path", "args", "env"}`) |
| `opencode` | `opencode.json` | `~/.config/opencode/opencode.json` | V1 `mcp` / V2 `mcp.servers` (`command: [...]`, `environment: {...}`) |
| `kimi-code` | `.kimi-code/mcp.json` | `$KIMI_CODE_HOME/mcp.json` (legacy `~/.kimi/mcp.json`) | `mcpServers` |
| `qwen-code` | `.qwen/settings.json` | `~/.qwen/settings.json` | `mcpServers` inside `settings.json` (sibling keys preserved) |
| `pi` | `.pi/mcp.json` | `~/.pi/agent/mcp.json` | `mcpServers` (preserves sparse knob-only `{"enabled": false}`) |
| `trae-cn` | `.trae/mcp.json` | macOS `~/Library/Application Support/Trae CN/User/mcp.json`, Linux `~/.config/Trae CN/User/mcp.json`, Win `%APPDATA%\Trae CN\User\mcp.json` | `mcpServers` |
| `trae` | `.trae/mcp.json` | macOS `~/Library/Application Support/Trae/User/mcp.json`, Linux `~/.config/Trae/User/mcp.json`, Win `%APPDATA%\Trae\User\mcp.json` | `mcpServers` |
| `kiro` | `.kiro/settings/mcp.json` | `~/.kiro/settings/mcp.json` | `mcpServers` |
| `junie` | `.junie/mcp/mcp.json` | `~/.junie/mcp/mcp.json` | `mcpServers` |
| `codebuddy` | `.codebuddy/.mcp.json` (fallback `.mcp.json`) | `$CODEBUDDY_CONFIG_DIR/.mcp.json` | `mcpServers` |
| `codebuddy-ide` | `.codebuddy/mcp.json` | `~/.codebuddy/mcp.json` | `mcpServers` |
| `qoder` | `.qoder/settings.json` | `~/.qoder/settings.json` | `mcpServers` inside `settings.json` |
| `qoder-cn` | `.lingma/mcp.json` | `~/.lingma/mcp.json` | `mcpServers` |
| `roo-code` | `.roo/mcp.json` | VS Code `globalStorage` `mcp_settings.json` (IDE-version dependent via `patch-mcp`) | `mcpServers` |
| `augment-code` | `—` | `~/.augment/settings.json` | `mcpServers` inside `settings.json` |
| `factory-droid` | `.factory/mcp.json` | `~/.factory/mcp.json` | `mcpServers` |

## Other tools (`patch-mcp`) & validation

For any unlisted or IDE-version-specific MCP file, consult [products.md](products.md) and
run `migrate_context.py patch-mcp --src-file ... --src-key-path ... --dst-file ... --dst-key-path ...`.
Generated JSON/JSONC/TOML is parsed before atomic replacement (`0600` when secrets exist).

Evidence consulted 2026-11-07:
[Codex MCP](https://developers.openai.com/codex/mcp),
[VS Code MCP](https://code.visualstudio.com/docs/agent-customization/mcp-servers),
[Gemini CLI MCP](https://geminicli.com/docs/tools/mcp-server/),
[Claude Code MCP](https://code.claude.com/docs/en/mcp).
