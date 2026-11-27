# copilot-cli

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**GitHub Copilot CLI and Copilot app** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Skills `.github/skills`, `.claude/skills`, `.agents/skills`, `~/.copilot/skills`, `~/.agents/skills`; Instructions `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `~/.copilot/copilot-instructions.md`, `AGENTS.md`; Hooks `.github/hooks/*.json`; Agents `.github/agents/*.agent.md`, `~/.copilot/agents/*.agent.md`; User MCP `~/.copilot/mcp-config.json` using **`mcpServers`** (distinct from VS Code `.vscode/mcp.json` `servers`). Built-in profile: `copilot-cli` (`copilot`, `copilot-app`).
- **Deep dives (progressive load per category)**: [Rules, Prompts, Agents & Skills](vscode/rules-prompts-agents.md) · [MCP & Hooks](vscode/mcp-and-hooks.md).
- **Cautions & check**: Resolve duplicate Skill names across shared roots; do not copy CLI auth tokens, session state, or allowlists, and do not invent an app-private folder for Copilot app UI state. Verify discovery in the CLI/app customization view.

Official sources: [1](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills) · [2](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference) · [3](https://docs.github.com/en/copilot/how-tos/github-copilot-app/customize-github-copilot-app)
