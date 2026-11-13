# GitHub Copilot and VS Code harnesses

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## vscode

**VS Code: Copilot, Local, Claude and Codex harnesses** · Evidence: `documented-subset` · Runtime: `not-run`.

First identify the selected **harness**, not only the model. Current VS Code documentation separates Copilot, Local, Claude and Codex customization. Native harnesses load their own files; selecting a Claude model inside another harness does not automatically select Claude Code conventions.

Copilot repository instructions include `.github/copilot-instructions.md`, scoped `.github/instructions/*.instructions.md` and documented AGENTS discovery. Claude uses CLAUDE/rules; Codex uses AGENTS discovery. Local/Profile prompt files and user storage are not universal native-harness locations. Skills, agents, hooks, plugins and MCP availability vary by harness.

For Local VS Code MCP, `.vscode/mcp.json` uses `servers`; active user MCP is profile-managed. Never guess Stable/Insiders/VSCodium or remote profile locations. `${input:...}`, input definitions and env-file features may not work in portable/native MCP config. Preserve selected input references only if the destination resolves them.

Check: active harness recognizes instructions and Skills; scoped `applyTo` matches the same path set; active user profile and remote extension host are correct. Do not transfer Settings Sync state or managed plugin caches. Current plugins can contain more than Skills: hooks, MCP, LSP and other UI/automation components need individual review.

Official sources: [1](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference) · [2](https://code.visualstudio.com/docs/agents/concepts/customization) · [3](https://code.visualstudio.com/docs/agent-customization/mcp-servers) · [4](https://code.visualstudio.com/docs/agent-customization/agent-plugins)

## copilot-cli

**GitHub Copilot CLI and Copilot app** · Evidence: `documented-subset` · Runtime: `not-run`.

CLI Skills may be project `.github/skills`, `.claude/skills`, `.agents/skills` and documented personal roots such as `~/.copilot/skills` and `~/.agents/skills`. Resolve duplicate names before writing. CLI user MCP is `~/.copilot/mcp-config.json`, using `mcpServers`; it is not VS Code's `servers` schema.

Inventory custom instructions, agents, skills, hooks, plugins, slash commands, MCP and custom settings separately. The Copilot app adds its own UI features and reuses some CLI/repository customizations; do not invent an app-local storage tree from that fact. Import approved definitions, never CLI credentials, sessions, remembered trust or allowlists.

Check CLI/app discovery using its actual customization view. Command-line flags and native configuration determine scope. Do not copy VS Code prompt-file/hook layouts into CLI merely because both products are called Copilot.

Official sources: [1](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills) · [2](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference) · [3](https://docs.github.com/en/copilot/how-tos/github-copilot-app/customize-github-copilot-app)

## copilot-other-hosts

**Visual Studio, JetBrains, Eclipse, Xcode and GitHub cloud coding agent** · Evidence: `documented-subset` · Runtime: `not-run`.

Use GitHub's client support table for each category, not a single green tick for the brand. At review time the table distinguishes stable, preview and unavailable support for instructions, prompt files, custom agents, subagents, Skills, MCP and hooks. Visual Studio and Copilot-in-Xcode are not VS Code; cloud coding agents do not inherit desktop user-profile state.

Record IDE version, Copilot extension version, feature flags and supported object types. Translate selected project instructions first. For a type absent from that client, preserve a reviewed portable file or UI rebuild instruction rather than dropping it or claiming automatic loading. Organization policy and environment secrets are administrative state, not portable instructions.

Check discovery in the exact IDE/cloud job. Preview support is not a tested guarantee. GitHub cloud setup steps and hooks are executable and require approval; do not run them during migration.

Official sources: [1](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
