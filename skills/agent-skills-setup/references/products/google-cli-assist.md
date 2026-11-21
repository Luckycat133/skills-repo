# Gemini CLI and Gemini Code Assist

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## gemini-cli

**Gemini CLI and its ACP/IDE integration** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Instructions `GEMINI.md` and `~/.gemini/GEMINI.md` (`@file` imports and configurable context filenames); Skills `.gemini/skills/<name>/SKILL.md`, `~/.gemini/skills/<name>/SKILL.md` (plus `.agents/skills` and extension-provided Skills); Custom commands `.gemini/commands/*.toml`, `~/.gemini/commands/*.toml`; Agents `.gemini/agents/*.md`, `~/.gemini/agents/*.md`; MCP **`mcpServers`** subobject inside `.gemini/settings.json` and `~/.gemini/settings.json` (Streamable HTTP uses `httpUrl`; SSE uses `url`; `${VAR}` env bindings). Built-in profile: `gemini-cli`.
- **Cautions & check**: Extract/patch **only** `mcpServers` in `settings.json` — never copy `theme`, `trust`, OAuth state, Auto Memory, or checkpoints/worktrees. Translate TOML command args and `!{...}` shell blocks explicitly (keep executable commands inactive). For ACP integrations, resolve the CLI process's execution `HOME`.

Official sources: [1](https://geminicli.com/docs/reference/configuration/) · [2](https://geminicli.com/docs/cli/skills/) · [3](https://geminicli.com/docs/cli/gemini-md/) · [4](https://geminicli.com/docs/cli/custom-commands/)

## gemini-code-assist

**Gemini Code Assist VS Code, JetBrains and enterprise** · Evidence: `documented-subset` · Runtime: `not-run`.

Distinct from Gemini CLI: do not assume `.gemini/commands/*.toml` or CLI Skill directories load here. Inventory IDE UI Rules, Prompt Library/custom commands, agent-mode MCP connections, and enterprise customizations. Note the June 2026 sunset of individual-plan Code Assist request service while checking Standard/Enterprise IDE availability separately. Transfer reviewed rule/prompt text via the IDE's current UI controls without copying enterprise credentials or inventing undocumented paths.

Official sources: [1](https://docs.cloud.google.com/gemini/docs/codeassist/code-overview) · [2](https://docs.cloud.google.com/gemini/docs/codeassist/chat-gemini) · [3](https://docs.cloud.google.com/gemini/docs/codeassist/use-agentic-chat-pair-programmer)
