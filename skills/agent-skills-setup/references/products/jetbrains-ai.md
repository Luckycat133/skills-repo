# jetbrains-ai

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**JetBrains AI Assistant, external ACP agents and Air** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory AI Assistant `.aiassistant/rules/*.md`, prompt library, project `.agents/skills/<name>/SKILL.md` (IDE-installed Skills live in product/version config dirs — use UI import rather than guessing IDE version paths), custom agents, outbound MCP client settings (distinct from the IDE's built-in MCP server), and external ACP harnesses (Claude/Codex). For **JetBrains Air**, inspect generated Skills, hooks, subagent, and MCP bindings without re-running Air's installer or copying IDE caches.

Official sources: [1](https://www.jetbrains.com/help/ai-assistant/agent-skills.html) · [2](https://www.jetbrains.com/help/ai-assistant/agents.html) · [3](https://www.jetbrains.com/help/ai-assistant/mcp.html) · [4](https://www.jetbrains.com/help/air/context-agent-integrations.html)
