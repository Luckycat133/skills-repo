# vscode

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**VS Code: Copilot, Local, Claude and Codex harnesses** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Harness-first routing**: Identify the active **harness** (Copilot/Local vs Claude vs Codex), not just the selected model. Copilot/Local loads `.github/copilot-instructions.md`, scoped `.github/instructions/*.instructions.md` (`applyTo: "glob"`), `AGENTS.md`, `.github/prompts/*.prompt.md`, `.github/agents/*.agent.md`, `.github/hooks/*.json`, and `.github/skills/<name>/SKILL.md` (plus `.agents/skills`). Claude and Codex harnesses use their own native files. Built-in profile: `vscode`.
- **MCP schema**: Workspace `.vscode/mcp.json` uses root key **`servers`** (not `mcpServers`), `type: "stdio" | "http" | "sse"`, `${env:VAR}`, and optional `inputs` (`${input:id}`). User MCP lives in the active VS Code profile (`Code` / `Code - Insiders` / remote server) — inspect rather than guessing profile folders.
- **Deep dives (progressive load per category)**: [Rules, Prompts, Agents & Skills](vscode/rules-prompts-agents.md) · [MCP & Hooks](vscode/mcp-and-hooks.md).
- **Check**: Active harness loads instructions/Skills, `applyTo` globs match expected paths, and Settings Sync / plugin caches / `state.vscdb` stay excluded.

Official sources: [1](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference) · [2](https://code.visualstudio.com/docs/agents/concepts/customization) · [3](https://code.visualstudio.com/docs/agent-customization/mcp-servers) · [4](https://code.visualstudio.com/docs/agent-customization/agent-plugins)
