# OpenAI: Codex harness and ChatGPT surfaces

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## codex

**Codex CLI, local IDE integration and app** · Evidence: `documented-subset` · Runtime: `not-run`.

Instructions are hierarchical `AGENTS.md` with `AGENTS.override.md` precedence at the same level; do not flatten different scopes into one file. Check `CODEX_HOME` and custom fallback names. Skills use the documented Agent Skills discovery roots, including project/user `.agents/skills`; UI/dependency metadata in `agents/openai.yaml` is a separate extension, not portable permission policy.

Local MCP belongs in `[mcp_servers.<name>]` tables in `~/.codex/config.toml` or the trusted project's `.codex/config.toml`, not `~/.agents/mcp.json`. Preserve other TOML tables. `env_vars` forwards identically named variables; it does not rename `HOST_TOKEN` to `SERVER_TOKEN`. HTTP auth must be rebound, not copied.

Also inventory command-policy `.rules`, agent definitions, hooks, plugins, scheduled tasks and authored instructions separately from generated memories and app state. Their availability and paths require the installed surface/version; they are not interchangeable with Markdown rules. Cloud tasks have a different filesystem and environment setup.

Check: actual Codex loader recognizes the Skill and AGENTS hierarchy; native configuration parses; MCP is listed without starting/connecting it unless authorized. Current legacy developer-doc links redirect to ChatGPT Learn: follow the Codex/CLI surface selector, not a generic ChatGPT page.

Official sources: [1](https://learn.chatgpt.com/docs/agent-configuration/agents-md) · [2](https://learn.chatgpt.com/docs/build-skills) · [3](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)

## openai-plugin

**OpenAI/ChatGPT plugin packages and cloud workspace context** · Evidence: `documented-subset` · Runtime: `not-run`.

New plugin documentation describes a root `plugin.json`, optional MCP configuration and namespaced OpenAI extensions. Do not conflate this with an older `.codex-plugin/` layout or another vendor's manifest solely because the bundle contains Skills.

Inventory Skills, app/tool bindings, MCP, UI metadata and other package components. Preserve package identity when the target understands the same manifest; otherwise unpack only the user-selected portable components into reviewed drafts. Do not reconstruct account connections, managed workspace policy or a cloud task's session state from local files.

Check the target's current plugin validator/import UI and namespace requirements. A local Codex migration test does not certify ChatGPT workspace import.

Official sources: [1](https://developers.openai.com/plugins/build/plugins) · [2](https://learn.chatgpt.com/docs/build-skills)
