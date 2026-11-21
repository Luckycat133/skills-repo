# OpenAI: Codex harness and ChatGPT surfaces

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## codex

**Codex CLI, local IDE integration and app** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Hierarchical `AGENTS.md` (`AGENTS.override.md` takes precedence at the same directory level; user `$CODEX_HOME/AGENTS.md`, default `~/.codex/AGENTS.md`); Skills `.agents/skills/<name>/SKILL.md` and `~/.agents/skills/<name>/SKILL.md` (legacy `.codex/skills`, optional `agents/openai.yaml` UI metadata); Prompts `~/.codex/prompts/*.md`; Local MCP `[mcp_servers.<name>]` in `.codex/config.toml` or `$CODEX_HOME/config.toml` (never `~/.agents/mcp.json`). Built-in profile: `codex`.
- **TOML MCP & secret rules**: Preserve `approval_policy` and unrelated TOML tables/comments. `env_vars = ["VAR"]` forwards **identically named** host variables only (`SERVER_TOKEN = "${HOST_TOKEN}"` cannot use `env_vars` and `[mcp_servers.<name>.env]` does not expand `${...}`). Literal secrets transferred out-of-band use `[mcp_servers.<name>.env]` (`0600` file mode) or `--redact-secrets` -> `env_vars` / `bearer_token_env_var` / `env_http_headers`.
- **Other surfaces & check**: Inventory `.rules` command policies, hooks, plugins, and cloud-task environments separately from Markdown instructions and session logs. Verify `tomllib` parse, `AGENTS.md` hierarchy, and Skill listing without starting MCP servers unless authorized.

Official sources: [1](https://learn.chatgpt.com/docs/agent-configuration/agents-md) · [2](https://learn.chatgpt.com/docs/build-skills) · [3](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)

## openai-plugin

**OpenAI/ChatGPT plugin packages and cloud workspace context** · Evidence: `documented-subset` · Runtime: `not-run`.

Current plugin packages use a root `plugin.json`, optional MCP configuration, Skills, and namespaced OpenAI extensions; do not conflate with older `.codex-plugin/` layouts or third-party plugin manifests. Preserve package identity when the target supports `plugin.json`; otherwise extract only user-selected portable Skills/instructions into reviewed drafts without copying cloud workspace connections, policies, or session state. Validate with the target's current plugin validator/import UI.

Official sources: [1](https://developers.openai.com/plugins/build/plugins) · [2](https://learn.chatgpt.com/docs/build-skills)
