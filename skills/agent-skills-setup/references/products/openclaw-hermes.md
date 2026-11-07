# OpenClaw and Hermes

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## openclaw

**OpenClaw Gateway, workspace agents and node hosts** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory Skills from workspace/user/shared/plugin sources, agent workspace bootstrap instructions (such as AGENTS/SOUL/USER/TOOLS where used), authored memory, hooks, cron, plugins, MCP and account integrations. Distinguish authored files from generated memory/history and executable heartbeat/automation instructions.

OpenClaw-specific Skill metadata can declare requirements or configuration. It is not a cross-client permission sandbox. Keep unavailable dependencies as requirements, not installations. Plugin bundles may be compatible with other manifests only for documented components.

Gateway MCP and a node host's `nodeHost.mcp.servers` are different machines/scopes. Never install a node-host server definition into a generic Gateway `mcp.servers` field by analogy. Inspect current config schema and agent workspace ownership; do not copy auth, trust, approvals or channel credentials.

Check the intended agent's Skill visibility and workspace bootstrapping. Recreate selected connections through supported settings, without contacting servers during a config-only migration.

Official sources: [1](https://docs.openclaw.ai/skills) · [2](https://docs.openclaw.ai/gateway/config-extensions) · [3](https://docs.openclaw.ai/nodes/mcp-and-skills) · [4](https://docs.openclaw.ai/plugins/bundles)

## hermes

**Nous Research Hermes Agent** · Evidence: `documented-subset` · Runtime: `not-run`.

Use Nous Research's official Hermes, not unrelated similarly named agents. Inventory Skills, workspace/persona instructions, user-reviewed persistent memory, subagents, cron, messaging, MCP, ACP and configuration. Persistent memory is not automatically all user-authored: separate selected facts from generated history.

Hermes has native migration/import features, including OpenClaw-oriented workflows; they are optional vendor tools, not prerequisites for this Skill. Do not run an import that includes credentials or session state merely to avoid mapping objects manually.

Resolve the active Hermes home/profile and installed version. Copy reviewed Skills with resources, translate instructions and reconstruct selected MCP definitions. Scheduled jobs, custom tools and messaging integrations can execute or send data; park/re-authorize them separately. Check native discovery and memory scope with harmless markers, not actual chat exports.

Official sources: [1](https://hermes-agent.nousresearch.com/docs/) · [2](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills/) · [3](https://github.com/NousResearch/hermes-agent)
