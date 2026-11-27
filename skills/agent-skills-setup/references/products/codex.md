# codex

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Codex CLI, local IDE integration and app** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Hierarchical `AGENTS.md` (`AGENTS.override.md` takes precedence at the same directory level; user `$CODEX_HOME/AGENTS.md` & `AGENTS.override.md`, default `~/.codex/`); Skills `.agents/skills/<name>/SKILL.md` and `~/.agents/skills/<name>/SKILL.md` (legacy `.codex/skills`, skipping built-in `.system/`, optional `agents/openai.yaml` UI metadata); Prompts `~/.codex/prompts/*.md`; Agents `.codex/agents/` & `$CODEX_HOME/agents/`; Hooks `.codex/hooks.json` & `$CODEX_HOME/hooks.json`; Helper scripts `$CODEX_HOME/scripts/`; Command-policy `.codex/rules/*.rules` & `$CODEX_HOME/rules/*.rules` (parked by default); Portable `config.toml` keys/tables (excluding `approval_policy`/`sandbox_mode`/`projects`/`notify` and admin `requirements.toml`); Local MCP `[mcp_servers.<name>]` in `.codex/config.toml` or `$CODEX_HOME/config.toml` (never `~/.agents/mcp.json`). Built-in profile: `codex`.
- **Deep dives (progressive load per category)**: [Instructions & Skills](codex/rules-skills.md) · [`config.toml` & MCP](codex/mcp-and-config.md) · [Agents, Hooks & Policies](codex/agents-hooks.md).
- **TOML MCP & secret rules**: Preserve `approval_policy` and unrelated TOML tables/comments. `env_vars = ["VAR"]` forwards **identically named** host variables only (`SERVER_TOKEN = "${HOST_TOKEN}"` cannot use `env_vars` and `[mcp_servers.<name>.env]` does not expand `${...}`). Literal secrets transferred out-of-band use `[mcp_servers.<name>.env]` (`0600` file mode) or `--redact-secrets` -> `env_vars` / `bearer_token_env_var` / `env_http_headers`.
- **Other surfaces & check**: Exclude `$CODEX_HOME/{memories,memories_v2,auth.json,archived_sessions}` and SQLite state DBs. Verify `tomllib` parse, `AGENTS.md` hierarchy, and Skill listing without starting MCP servers unless authorized.

Official sources: [1](https://learn.chatgpt.com/docs/agent-configuration/agents-md) · [2](https://learn.chatgpt.com/docs/build-skills) · [3](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)
