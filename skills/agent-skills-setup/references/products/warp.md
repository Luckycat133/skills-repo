# Warp Desktop and Oz

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## warp

**Warp Desktop and Warp Drive** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory `AGENTS.md` (and legacy `WARP.md`), `.agents/skills/<name>/SKILL.md` and user Skills, global Rules, Agent Profiles, MCP server definitions, and Warp Drive prompts/workflows/notebooks/env-var names. Separate local repository files from account-backed Warp Drive objects (rebuilt via Warp Drive UI/export); never copy team permissions, provider auth, or executable workflows without explicit review.

Official sources: [1](https://docs.warp.dev/agents/capabilities/skills) · [2](https://docs.warp.dev/agents/capabilities/agent-profiles-permissions/) · [3](https://docs.warp.dev/agents/capabilities)

## warp-oz

**Oz CLI, cloud runtime and SDK/API** · Evidence: `documented-subset` · Runtime: `not-run`.

Oz is Warp's CLI/cloud/SDK agent runner, not an alias for Warp Desktop UI state. Inventory repository `AGENTS.md`, Skills, Oz run environment/MCP definitions, and agent profiles; rebind working directories and secret names for the cloud runner, keep scheduled jobs unregistered until approved, and exclude cloud session logs/tokens.

Official sources: [1](https://docs.warp.dev/) · [2](https://docs.warp.dev/agents/capabilities)
