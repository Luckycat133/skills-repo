# Kiro and Amazon Q

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## kiro

**Kiro IDE, CLI, web/mobile and Crew** · Evidence: `version-sensitive` · Runtime: `not-run`.

- **Candidate paths & schemas**: Steering `.kiro/steering/*.md` and `~/.kiro/steering/*.md` (`inclusion: always | fileMatch | manual`, `fileMatchPattern`); `AGENTS.md`; Skills `.kiro/skills/<name>/SKILL.md`, `~/.kiro/skills/<name>/SKILL.md`; MCP `.kiro/settings/mcp.json` and `~/.kiro/settings/mcp.json` (`mcpServers`); Specs (`.kiro/specs/`), Powers, hooks (`.kiro/hooks/`), and CLI custom agents (`.kiro/agents/`). Built-in profile: `kiro` (`kiro-cli`).
- **Version & surface traps**: CLI 3 agent permissions/inclusion differ from CLI 2 (`allowedTools`/`toolsSettings`) — match installed CLI major version and note CLI custom agents only load declared Skill resources. Keep Specs (task artifacts), Powers, Crew scope, and inactive hook drafts separate.

Official sources: [1](https://kiro.dev/docs/steering) · [2](https://kiro.dev/docs/skills) · [3](https://kiro.dev/docs/custom-agents) · [4](https://kiro.dev/docs/mcp/configuration) · [5](https://kiro.dev/docs/)

## amazon-q

**Amazon Q Developer IDE and legacy/current CLI profiles** · Evidence: `version-sensitive` · Runtime: `not-run`.

- **Candidate paths & official path conflict**: Project rules `.amazonq/rules/*.md`; Project MCP `.amazonq/mcp.json` or `.amazonq/default.json`. Official AWS docs disagree on global IDE MCP (`~/.aws/amazonq/default.json` on the IDE page vs `~/.aws/amazonq/agents/default.json` on the overview; CLI agents use `~/.aws/amazonq/cli-agents/*.json`).
- **Resolution rule**: Inspect which global file the installed IDE/CLI actually reads before running `patch-mcp`; never write all candidate paths blindly, relabel Amazon Q as Kiro, or copy AWS SSO/IAM credentials.

Official sources: [1](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/mcp-ide.html) · [2](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/qdev-mcp.html) · [3](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/context-project-rules.html)
