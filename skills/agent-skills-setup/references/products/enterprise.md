# Rovo, IBM Bob, GitLab Duo, Tabnine, Qodo and Cody

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## rovodev

**Atlassian Rovo Dev CLI, IDE and cloud** · Evidence: `documented-subset` · Runtime: `not-run`.

Rovo Dev CLI uses `.rovodev/skills/<name>/SKILL.md` and `.agents/skills`, `AGENTS.md`, `.rovodev/prompts.yml` (preserve YAML args and relative `.md` links), subagents (`.rovodev/subagents/`), and `~/.rovodev/config.yml` (read its `mcpConfigPath` rather than guessing `mcp.json` vs `mcp_config.json`, then patch via `patch-mcp`). Keep Rovo Studio / A2A AgentCard skills, IDE/cloud settings, and Atlassian auth tokens separate.

Official sources: [1](https://support.atlassian.com/rovo/docs/extend-rovo-dev-cli-with-agent-skills/) · [2](https://support.atlassian.com/rovo/docs/manage-rovo-dev-cli-settings/) · [3](https://support.atlassian.com/rovo/docs/connect-to-an-mcp-server-in-rovo-dev-cli/) · [4](https://support.atlassian.com/rovo/docs/use-subagents-in-rovo-dev-cli/)

## ibm-bob

**IBM Bob IDE and Bob Shell** · Evidence: `version-sensitive` · Runtime: `not-run`.

Separate Bob IDE from Bob Shell 1 vs Shell 2. Inventory `.bob/skills/<name>/SKILL.md`, `~/.bob/skills`, `.bob/rules*`, `AGENTS.md`, custom modes/subagents, `.bob/plugins` (`~/.bob/plugins`), and IDE global MCP `~/.bob/settings/mcp.json` (`mcpServers` via `patch-mcp`; check Bob Shell's own MCP path separately). Strip `alwaysAllow` and remembered tool approvals.

Official sources: [1](https://bob.ibm.com/docs/ide/features/skills) · [2](https://bob.ibm.com/docs/shell/features/skills) · [3](https://bob.ibm.com/docs/ide/configuration/mcp/mcp-in-bob) · [4](https://bob.ibm.com/docs/shell/configuration/mcp/mcp-bobshell) · [5](https://bob.ibm.com/blog/september-2026-release/)

## gitlab-duo

**GitLab Duo IDE, CLI, web and agent flows** · Evidence: `documented-subset` · Runtime: `not-run`.

Check GitLab's per-surface customization table: hierarchical `AGENTS.md` (user path respects `GLAB_CONFIG_DIR` / XDG / Windows `%APPDATA%`), `.gitlab/duo/chat-rules.md`, workspace `skills/<name>/SKILL.md` (not `.agents/skills` unless configured), `.gitlab/duo/mcp.json` (outbound MCP client, distinct from GitLab's MCP server), subagents, and executable YAML flows (keep triggers/tokens separate).

Official sources: [1](https://docs.gitlab.com/user/duo_agent_platform/customize/) · [2](https://docs.gitlab.com/user/duo_agent_platform/customize/agent_skills/) · [3](https://docs.gitlab.com/user/duo_agent_platform/customize/agents_md/) · [4](https://docs.gitlab.com/user/gitlab_duo/model_context_protocol/mcp_clients/)

## tabnine

**Tabnine IDE/CLI and enterprise context** · Evidence: `version-sensitive` · Runtime: `not-run`.

Identify installed Tabnine CLI/IDE generation first: inventory `TABNINE.md` / guidelines, `.tabnine/commands/`, MCP settings, and any local Skill integration (`tabnine/skills` repo is a Skill catalog, not proof of one universal autoload path). Exclude enterprise Context Engine indexes, provider keys, and org policies.

Official sources: [1](https://docs.tabnine.com/main/getting-started/tabnine-agent/agent-settings) · [2](https://docs.tabnine.com/main/getting-started/tabnine-cli/features/commands) · [3](https://docs.tabnine.com/main/getting-started/tabnine-cli/getting-started/quickstart) · [4](https://github.com/tabnine/skills)

## qodo

**Qodo code review, IDE/Command and toolbox integrations** · Evidence: `version-sensitive` · Runtime: `not-run`.

Separate hosted PR review (`best_practices.md`, ordered review Skill lookup across `.qodo/skills`, `.claude/skills`, `.cursor/skills`, `.agents/skills`, `skills/`), IDE prompts/agents, agentic toolbox MCP plugins, and legacy Command `agent.toml` files. Preserve review rule priority and never infer local MCP files for hosted PR review bots.

Official sources: [1](https://www.qodo.ai/glossary/what-is-agent-skills/) · [2](https://www.qodo.ai/blog/introducing-qodos-agentic-toolbox/) · [3](https://github.com/qodo-ai/agents)

## cody

**Sourcegraph Cody, not Amp** · Evidence: `documented-subset` · Runtime: `not-run`.

Do not apply Amp paths to Cody. Inventory Prompt Library items, pre-instructions, OpenCtx/MCP client settings in VS Code/JetBrains user settings, and explicit repo context notes; exclude Sourcegraph enterprise tokens and remote code-graph indexes.

Official sources: [1](https://sourcegraph.com/docs/cody/capabilities) · [2](https://sourcegraph.com/docs/cody/clients/install-vscode) · [3](https://sourcegraph.com/docs/cody/capabilities/agentic-context-fetching)
