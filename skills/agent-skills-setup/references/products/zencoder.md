# Zencoder and Zenflow

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## zencoder

**Zencoder IDE agents and CLI integrations** · Evidence: `documented-subset` · Runtime: `not-run`.

Identify active surface (Zencoder IDE plugin vs Zenflow vs external Claude/Codex/Gemini CLI bridge). Inventory shared Agent Skills roots (`.agents/skills`, `.claude/skills` — verify precedence before creating `.zencoder/skills`), `.zencoder/rules`, Zen Agents/SubAgents, saved prompts, and selected `mcpServers` subobjects (exclude model/provider auth).

Official sources: [1](https://docs.zencoder.ai/features/skills) · [2](https://docs.zencoder.ai/features/ai-agents) · [3](https://docs.zencoder.ai/features/mcp-deep-dive) · [4](https://docs.zencoder.ai/llms.txt)

## zenflow

**Zenflow Code, Work and remote hosts** · Evidence: `documented-subset` · Runtime: `not-run`.

Zencoder's Zenflow (not unrelated tools named Zenflow) uses multi-phase custom workflows (`.zenflow/workflows/`), agent presets, subagent pipelines, Skills, MCP, and scheduled automations. Preserve workflow phases/agent bindings while keeping verification scripts and scheduled triggers parked until approved, and separate Desktop vs Work vs remote Ubuntu host paths/tokens.

Official sources: [1](https://docs.zencoder.ai/zenflow/workflows/custom) · [2](https://docs.zencoder.ai/zenflow/orchestration/agent-presets) · [3](https://docs.zencoder.ai/zenflow/subagents) · [4](https://docs.zencoder.ai/zenflow/scheduled-automation) · [5](https://docs.zencoder.ai/zenflow-work)
