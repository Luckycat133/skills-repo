# JetBrains and Xcode: editor versus agent

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## junie

**Junie IDE and CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Guidelines `.junie/guidelines.md` and `AGENTS.md`; Skills `.junie/skills/<name>/SKILL.md`, `~/.junie/skills/<name>/SKILL.md`; Agents `.junie/agents/*.md`; IDE MCP `~/.junie/mcp/mcp.json` (`mcpServers` — patchable out-of-band via `patch-mcp`); CLI extensions/MCP require checking CLI version flags/env overrides.
- **Cautions & check**: Keep Junie's outbound MCP client config distinct from JetBrains IDE's inbound MCP server; map agent tool/Skill allowlists field-by-field without copying action approvals. Check `/skills` or IDE Skill list.

Official sources: [1](https://junie.jetbrains.com/docs/agent-skills.html) · [2](https://junie.jetbrains.com/docs/junie-cli-subagents.html) · [3](https://junie.jetbrains.com/docs/junie-ide-plugin.html) · [4](https://junie.jetbrains.com/docs/environment-variables.html)

## jetbrains-ai

**JetBrains AI Assistant, external ACP agents and Air** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory AI Assistant `.aiassistant/rules/*.md`, prompt library, project `.agents/skills/<name>/SKILL.md` (IDE-installed Skills live in product/version config dirs — use UI import rather than guessing IDE version paths), custom agents, outbound MCP client settings (distinct from the IDE's built-in MCP server), and external ACP harnesses (Claude/Codex). For **JetBrains Air**, inspect generated Skills, hooks, subagent, and MCP bindings without re-running Air's installer or copying IDE caches.

Official sources: [1](https://www.jetbrains.com/help/ai-assistant/agent-skills.html) · [2](https://www.jetbrains.com/help/ai-assistant/agents.html) · [3](https://www.jetbrains.com/help/ai-assistant/mcp.html) · [4](https://www.jetbrains.com/help/air/context-agent-integrations.html)

## xcode

**Xcode Coding Intelligence and external-agent bridge** · Evidence: `documented-subset` · Runtime: `not-run`.

Identify Xcode release and agent harness (built-in Claude/Codex, external ACP, or external client calling Xcode MCP). Apple stores agent-specific configs under `~/Library/Developer/Xcode/CodingAssistant/` (e.g., `ClaudeAgentConfig`), distinct from normal `$HOME`. Inventory project instructions, custom Skills/subagents/plugins, and MCP/ACP entries; check `xcrun mcpbridge` vs Xcode 27 MCP server release notes locally, and never copy simulator state, Apple-built Skills, or keychain/security grants.

Official sources: [1](https://developer.apple.com/documentation/xcode/extending-and-customizing-agents/) · [2](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode) · [3](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes)
