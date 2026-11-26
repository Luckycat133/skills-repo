# openclaw

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**OpenClaw Gateway, workspace agents and node hosts** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & scope trap**: Workspace bootstrap files (`AGENTS.md`, `SOUL.md`, `USER.md`, `TOOLS.md`), workspace/user/shared/plugin `skills/<name>/SKILL.md`, authored memory, hooks/cron, plugin bundles, and `~/.openclaw/openclaw.json`.
- **Gateway vs Node Host MCP**: Gateway `mcp.servers` and a remote machine's `nodeHost.mcp.servers` run on **different hosts** — never mix them when running `patch-mcp`. Keep `metadata.openclaw` requirements declarative (no auto-install) and exclude channel tokens/trust/heartbeats.

Official sources: [1](https://docs.openclaw.ai/skills) · [2](https://docs.openclaw.ai/gateway/config-extensions) · [3](https://docs.openclaw.ai/nodes/mcp-and-skills) · [4](https://docs.openclaw.ai/plugins/bundles)
