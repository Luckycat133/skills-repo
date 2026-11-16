# OpenClaw and Hermes

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## openclaw

**OpenClaw Gateway, workspace agents and node hosts** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & scope trap**: Workspace bootstrap files (`AGENTS.md`, `SOUL.md`, `USER.md`, `TOOLS.md`), workspace/user/shared/plugin `skills/<name>/SKILL.md`, authored memory, hooks/cron, plugin bundles, and `~/.openclaw/openclaw.json`.
- **Gateway vs Node Host MCP**: Gateway `mcp.servers` and a remote machine's `nodeHost.mcp.servers` run on **different hosts** — never mix them when running `patch-mcp`. Keep `metadata.openclaw` requirements declarative (no auto-install) and exclude channel tokens/trust/heartbeats.

Official sources: [1](https://docs.openclaw.ai/skills) · [2](https://docs.openclaw.ai/gateway/config-extensions) · [3](https://docs.openclaw.ai/nodes/mcp-and-skills) · [4](https://docs.openclaw.ai/plugins/bundles)

## hermes

**Nous Research Hermes Agent** · Evidence: `documented-subset` · Runtime: `not-run`.

Resolve Nous Research Hermes (`~/.hermes/` or active profile): Skills (`~/.hermes/skills/<name>/SKILL.md`), persona/workspace instructions, reviewed durable memory (`MEMORY.md` / `USER.md` — separate from raw chat history), subagents, `config.yaml` MCP entries, ACP, cron, and messaging channels. Do not run vendor bulk importers that carry credentials/sessions; keep cron jobs and messaging bots parked until separately authorized.

Official sources: [1](https://hermes-agent.nousresearch.com/docs/) · [2](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills/) · [3](https://github.com/NousResearch/hermes-agent)
