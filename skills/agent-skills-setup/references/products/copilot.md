# GitHub Copilot and VS Code harnesses

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## vscode

**VS Code: Copilot, Local, Claude and Codex harnesses** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Harness-first routing**: Identify the active **harness** (Copilot/Local vs Claude vs Codex), not just the selected model. Copilot/Local loads `.github/copilot-instructions.md`, scoped `.github/instructions/*.instructions.md` (`applyTo: "glob"`), `AGENTS.md`, `.github/prompts/*.prompt.md`, `.github/agents/*.agent.md`, and `.github/skills/<name>/SKILL.md` (plus `.agents/skills`). Claude and Codex harnesses use their own native files. Built-in profile: `vscode`.
- **MCP schema**: Workspace `.vscode/mcp.json` uses root key **`servers`** (not `mcpServers`), `type: "stdio" | "http" | "sse"`, `${env:VAR}`, and optional `inputs` (`${input:id}`). User MCP lives in the active VS Code profile (`Code` / `Code - Insiders` / remote server) — inspect rather than guessing profile folders.
- **Check**: Active harness loads instructions/Skills, `applyTo` globs match expected paths, and Settings Sync / plugin caches / `state.vscdb` stay excluded.

Official sources: [1](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference) · [2](https://code.visualstudio.com/docs/agents/concepts/customization) · [3](https://code.visualstudio.com/docs/agent-customization/mcp-servers) · [4](https://code.visualstudio.com/docs/agent-customization/agent-plugins)

## copilot-cli

**GitHub Copilot CLI and Copilot app** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Skills `.github/skills`, `.claude/skills`, `.agents/skills`, `~/.copilot/skills`, `~/.agents/skills`; Instructions `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `~/.copilot/copilot-instructions.md`, `AGENTS.md`; Agents `.github/agents/*.agent.md`, `~/.copilot/agents/*.agent.md`; User MCP `~/.copilot/mcp-config.json` using **`mcpServers`** (distinct from VS Code `.vscode/mcp.json` `servers`). Built-in profile: `copilot-cli` (`copilot`, `copilot-app`).
- **Cautions & check**: Resolve duplicate Skill names across shared roots; do not copy CLI auth tokens, session state, or allowlists, and do not invent an app-private folder for Copilot app UI state. Verify discovery in the CLI/app customization view.

Official sources: [1](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills) · [2](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference) · [3](https://docs.github.com/en/copilot/how-tos/github-copilot-app/customize-github-copilot-app)

## copilot-other-hosts

**Visual Studio, JetBrains, Eclipse, Xcode and GitHub cloud coding agent** · Evidence: `documented-subset` · Runtime: `not-run`.

Check GitHub's per-host support matrix per category (stable vs preview vs unavailable across instructions, prompt files, custom agents, subagents, Skills, MCP, and hooks). Visual Studio and Copilot-in-Xcode are not VS Code; cloud coding agents do not read local desktop user profiles. Migrate supported repository instructions (`.github/copilot-instructions.md` / `AGENTS.md`) first, park unsupported categories as reviewed drafts, keep cloud setup steps/hooks unexecuted without approval, and exclude org secrets/policies.

Official sources: [1](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
