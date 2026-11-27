# Codex: `config.toml` & MCP Servers

Parent: [codex.md](../codex.md)

## TOML MCP Schema (`[mcp_servers.<name>]`)

Paths: Project `.codex/config.toml` and User `$CODEX_HOME/config.toml` (never `~/.agents/mcp.json`).

```toml
[mcp_servers.github]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-github"]
env_vars = ["GITHUB_PERSONAL_ACCESS_TOKEN"]
startup_timeout_sec = 20
tool_timeout_sec = 120

[mcp_servers.github.env]
CUSTOM_FLAG = "literal-value"

[mcp_servers.remote_api]
url = "https://api.example.com/mcp"
bearer_token_env_var = "API_BEARER_TOKEN"
env_http_headers = { "X-Api-Key" = "API_KEY_VAR" }
```

## Critical Env & Secret Traps

- `env_vars = ["VAR"]` forwards **identically named** host environment variables only (`TARGET_KEY = "${HOST_VAR}"` cannot use `env_vars`!).
- `[mcp_servers.<name>.env]` does **NOT** expand `${VAR}` placeholders — only put literal secrets there when written out-of-band in `0600` mode, or use `--redact-secrets` to emit `env_vars` / `bearer_token_env_var` / `env_http_headers`.
- Preserve `startup_timeout_sec`, `tool_timeout_sec`, `enabled_tools`, `disabled_tools`, and `enabled = false` independently.

## Portable `config.toml` Settings vs Exclusions

- **Portable keys/tables**: `model`, `model_reasoning_effort`, `web_search`, `features`, `memories`, `plugins`, `marketplaces`, `model_providers` (`0600` if key-bearing).
- **Must strip & preserve target**: `approval_policy`, `sandbox_mode`, `[projects."..."]`, `notify` (and admin `requirements.toml`). Surgical merge must leave existing TOML comments and target policy untouched.

Official sources: [extend MCP](https://learn.chatgpt.com/docs/extend/mcp?surface=cli) · [config schema](https://developers.openai.com/codex/config-schema.json)
