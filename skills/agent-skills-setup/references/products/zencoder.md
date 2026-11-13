# Zencoder and Zenflow

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## zencoder

**Zencoder IDE agents and CLI integrations** · Evidence: `documented-subset` · Runtime: `not-run`.

Current official docs share Skills, custom/Zen Agents, SubAgents, saved prompts, context management and MCP across several surfaces. Inspect IDE versus Zenflow versus an external Claude/Codex/Gemini CLI integration; the active harness determines actual loading.

Skills use documented shared Agent Skills locations; verify the chosen root and collision precedence before creating a `.zencoder/skills` directory from an old note. Settings can include model/provider state beside portable MCP definitions: export selected subobjects only.

Move authored Skill packages and prompt text, translate agent tool/model bindings and keep executable integrations parked. Check native Skill source/enable controls and which agent receives each component. An IDE marketplace description is not a complete filesystem contract.

Official sources: [1](https://docs.zencoder.ai/features/skills) · [2](https://docs.zencoder.ai/features/ai-agents) · [3](https://docs.zencoder.ai/features/mcp-deep-dive) · [4](https://docs.zencoder.ai/llms.txt)

## zenflow

**Zenflow Code, Work and remote hosts** · Evidence: `documented-subset` · Runtime: `not-run`.

Use Zencoder's Zenflow, not an unrelated project with the same name. Inventory task/workflow definitions, agent presets, subagent pipelines, saved prompts, Skills, MCP/integrations and scheduled automations. Custom workflows are structured multi-step processes, not interchangeable slash commands.

Preserve workflow phases, artifacts, model/agent assignments and verification scripts. Verification scripts, lifecycle triggers and schedules execute code or call services; prepare reviewed drafts, do not register them automatically. Work account integrations and remote Ubuntu hosts have different paths/credentials from Code Desktop.

Check the actual workflow editor and task profile resolve the intended files. Do not copy worktrees, conversations, auth state or the complete Zenflow app-data tree. A workflow that parses is not necessarily safe to execute.

Official sources: [1](https://docs.zencoder.ai/zenflow/workflows/custom) · [2](https://docs.zencoder.ai/zenflow/orchestration/agent-presets) · [3](https://docs.zencoder.ai/zenflow/subagents) · [4](https://docs.zencoder.ai/zenflow/scheduled-automation) · [5](https://docs.zencoder.ai/zenflow-work)
