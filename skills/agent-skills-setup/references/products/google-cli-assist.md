# Gemini CLI and Gemini Code Assist

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## gemini-cli

**Gemini CLI and its ACP/IDE integration** · Evidence: `documented-subset` · Runtime: `not-run`.

Read `GEMINI.md` discovery/imports and any configured context filename. MCP is a `mcpServers` subobject of user/project `.gemini/settings.json`, not a separate universally supported `mcp.json`. Resolve system/user/project precedence and retain unrelated settings.

Inventory Skills and aliases, custom TOML commands, subagents/remote subagents, lifecycle hooks, extensions, policies, ignore files, system-prompt overrides and authored memory. Auto Memory and session/checkpoint/worktree state are distinct, partly experimental features: do not copy them as instructions. Native Skills may come from files or extensions; preserve origin and precedence.

Translate TOML command parameters, file references and shell interpolation explicitly. Export just the selected MCP entries; `url`/HTTP transport, env references and headers need destination-specific mapping. An extension's settings and tools are not an ordinary Skill folder.

Check syntax with the installed schema, instruction discovery/import base, Skill listing and command expansion. MCP enumeration/connection or executing a command is a separate authorized test. An IDE plugin using Gemini CLI ACP uses the CLI's actual execution home, not necessarily the desktop editor's home.

Official sources: [1](https://geminicli.com/docs/reference/configuration/) · [2](https://geminicli.com/docs/cli/skills/) · [3](https://geminicli.com/docs/cli/gemini-md/) · [4](https://geminicli.com/docs/cli/custom-commands/)

## gemini-code-assist

**Gemini Code Assist VS Code, JetBrains and enterprise** · Evidence: `documented-subset` · Runtime: `not-run`.

This is not Gemini CLI. Inventory UI Rules, Prompt Library/custom commands, chat/agent-mode configuration, MCP connections and enterprise customization for the selected IDE and account. Do not presume `.gemini/commands` or CLI Skill roots are consumed here.

The official overview documents the end of the individual-plan Code Assist request service in June 2026; enterprise offerings and supported IDE surfaces must be checked separately. Do not label the whole product retired or copy enterprise state to a personal account.

Move reviewed user text through the current UI/export mechanism, preserving prompt arguments and project/account scope. MCP configuration availability differs between chat and agent mode. Check the target IDE actually presents each type; missing file documentation means inspect UI/schema, not invent a path.

Official sources: [1](https://docs.cloud.google.com/gemini/docs/codeassist/code-overview) · [2](https://docs.cloud.google.com/gemini/docs/codeassist/chat-gemini) · [3](https://docs.cloud.google.com/gemini/docs/codeassist/use-agentic-chat-pair-programmer)
