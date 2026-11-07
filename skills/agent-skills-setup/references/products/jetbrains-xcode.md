# JetBrains and Xcode: editor versus agent

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## junie

**Junie IDE and CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

Skills work in Junie CLI and JetBrains IDEs; inspect `.junie/skills`, `~/.junie/skills` and configured extra locations. Inventory AGENTS/guidelines, Skills, `.junie/agents/*.md`, custom commands, extensions and MCP separately. CLI extensions can bundle several of those types.

Junie IDE MCP settings are documented at `~/.junie/mcp/mcp.json`; this does not establish every CLI version's discovery contract. Inspect CLI flags/environment overrides and schema. Do not migrate action allowlists or remembered approvals. Agent tool restrictions, model/reasoning, Skills and MCP allowlists must be mapped field by field, not copied as portable permissions.

Check native `/skills` or the IDE Skill view, guideline activation and agent discovery. The IDE's MCP server exposed to external agents is a separate **provider** from Junie's outbound MCP client configuration.

Official sources: [1](https://junie.jetbrains.com/docs/agent-skills.html) · [2](https://junie.jetbrains.com/docs/junie-cli-subagents.html) · [3](https://junie.jetbrains.com/docs/junie-ide-plugin.html) · [4](https://junie.jetbrains.com/docs/environment-variables.html)

## jetbrains-ai

**JetBrains AI Assistant, external ACP agents and Air** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory AI Assistant project/user rules, prompt library, Skills, custom agents, MCP and the selected external ACP agent. Current AI Assistant supports project `.agents/skills`; IDE-installed Skills live in product/version-managed directories. Use the documented OS-specific location or UI import rather than guessing one global JetBrains folder.

The integrated IDE MCP server exposes code intelligence to external agents. That server configuration is not the same as AI Assistant's MCP client settings. Passing MCP servers to an ACP agent may be optional. Claude/Codex agents retain harness-specific context conventions.

Air/JetBrains Context is an additional integration surface: its setup can add Skills, usage instructions, a subagent, hooks, MCP and Codex execution rules. Inventory those generated integrations before moving selected authored customizations; do not rerun an installer as a migration step.

Check the intended agent, project/profile and Skill test UI. Do not copy entire IDE caches or the IDE-managed agent runtime.

Official sources: [1](https://www.jetbrains.com/help/ai-assistant/agent-skills.html) · [2](https://www.jetbrains.com/help/ai-assistant/agents.html) · [3](https://www.jetbrains.com/help/ai-assistant/mcp.html) · [4](https://www.jetbrains.com/help/air/context-agent-integrations.html)

## xcode

**Xcode Coding Intelligence and external-agent bridge** · Evidence: `documented-subset` · Runtime: `not-run`.

Record Xcode release and agent (built-in Claude/Codex, external ACP, or external client using Xcode MCP). Current Apple docs explicitly support agent customization and plugins with Skills, subagents, MCP and ACP configuration. Do not classify all Xcode context as opaque application state.

Apple documents agent-specific subfolders inside `~/Library/Developer/Xcode/CodingAssistant`, including `ClaudeAgentConfig`; resolve the actual agent's folder, not normal shell HOME. Inventory project instructions, custom Skills/subagents/plugins and selected MCP/ACP definitions. Xcode 26.3-era `xcrun mcpbridge` and newer MCP-server experiences have version boundaries; do not substitute one command without checking local help.

Only copy selected authored components. IDE security grants, accounts, simulator state, sessions and Apple-built Skills are not portable user context. Test discovery in Xcode's selected agent; builds, simulator input and MCP tool execution need separate authorization.

Official sources: [1](https://developer.apple.com/documentation/xcode/extending-and-customizing-agents/) · [2](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode) · [3](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes)
