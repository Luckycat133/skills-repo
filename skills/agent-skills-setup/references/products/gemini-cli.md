# gemini-cli

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Gemini CLI and its ACP/IDE integration** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Instructions `GEMINI.md` and `~/.gemini/GEMINI.md` (`@file` imports and configurable context filenames); Skills `.gemini/skills/<name>/SKILL.md`, `~/.gemini/skills/<name>/SKILL.md` (plus `.agents/skills` and extension-provided Skills); Custom commands `.gemini/commands/*.toml`, `~/.gemini/commands/*.toml`; Agents `.gemini/agents/*.md`, `~/.gemini/agents/*.md`; MCP **`mcpServers`** subobject inside `.gemini/settings.json` and `~/.gemini/settings.json` (Streamable HTTP uses `httpUrl`; SSE uses `url`; `${VAR}` env bindings). Built-in profile: `gemini-cli`.
- **Cautions & check**: Extract/patch **only** `mcpServers` in `settings.json` — never copy `theme`, `trust`, OAuth state, Auto Memory, or checkpoints/worktrees. Translate TOML command args and `!{...}` shell blocks explicitly (keep executable commands inactive). For ACP integrations, resolve the CLI process's execution `HOME`.

Official sources: [1](https://geminicli.com/docs/reference/configuration/) · [2](https://geminicli.com/docs/cli/skills/) · [3](https://geminicli.com/docs/cli/gemini-md/) · [4](https://geminicli.com/docs/cli/custom-commands/)
