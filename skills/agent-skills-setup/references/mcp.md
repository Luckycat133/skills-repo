# MCP migration: generic out-of-band server & secret translation

Look up exact per-client MCP file locations and container keys in ONLY
`references/products/<source>.md` and `references/products/<target>.md` (indexed by
[products.md](products.md)). Use `scripts/migrate_context.py` (`migrate` or `patch-mcp`)
so API keys, tokens, and headers move disk-to-disk without entering LLM context.

## Transport, fields & secret invariants

- **Out-of-band `0600` secrets**: Never open raw secret-bearing MCP configs into LLM
  context. The helper reads and writes `0600` files directly, printing only server names,
  variable names, `has_secrets`, and `sha256[:8]`.
- **Git-tracked guard**: For tracked `.mcp.json` on Claude Code, secret-bearing servers
  automatically route to untracked `~/.claude.json` (`projects[workspace].mcpServers`).
  Other tracked targets refuse (exit `2`) unless `--redact-secrets`, `--scope user`, or
  explicit `--allow-git-tracked-secrets`.
- **Placeholder & format translation**:
  - `--redact-secrets` rewrites literal secrets into host bindings (`${VAR}`, VS Code
    `${env:VAR}`, Codex `env_vars = ["VAR"]` / `bearer_token_env_var`).
  - Normalize transport shapes across JSON/JSONC/TOML: HTTP `url` <-> Gemini `httpUrl`
    <-> Windsurf/Antigravity `serverUrl`; OpenCode `command: [...]` + `environment` <->
    standard `command` + `args` + `env`; Zed `context_servers` `command: {path, args, env}`.
  - Map `timeout` / `timeoutSeconds` <-> Codex `tool_timeout_sec`; carry disabled state
    and tool allow/deny filters (`enabledTools` / `disabledTools`) when supported, or defer
    explicitly when unsupported (e.g. legacy SSE on Antigravity, per-tool filters on OpenCode).
  - **Codex `env_vars` trap**: `env_vars` forwards only **identically named** host env
    vars (`SERVER_TOKEN = "${HOST_TOKEN}"` defers on `--redact-secrets` because Codex TOML
    does not expand `${...}`).
  - **Exclude grants**: Never copy `alwaysAllow`, `autoApprove`, `trust`, or OAuth tokens.

## Composable usage (`patch-mcp`) & validation

- For any client listed in [products.md](products.md), run:
  `python3 "<SKILL_DIR>/scripts/migrate_context.py" patch-mcp --src-file <src> --src-key-path <src_key> --dst-file <dst> --dst-key-path <dst_key>`
- Output files are syntax-verified (`json.loads` / `tomllib.loads`) before atomic write;
  never run `npx`/`uvx` installers just to test MCP syntax.

Evidence consulted 2026-11-07:
[Codex MCP](https://developers.openai.com/codex/mcp),
[VS Code MCP](https://code.visualstudio.com/docs/agent-customization/mcp-servers),
[Gemini CLI MCP](https://geminicli.com/docs/tools/mcp-server/),
[Claude Code MCP](https://code.claude.com/docs/en/mcp).
