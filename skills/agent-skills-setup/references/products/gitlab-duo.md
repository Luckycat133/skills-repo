# gitlab-duo

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**GitLab Duo IDE, CLI, web and agent flows** · Evidence: `documented-subset` · Runtime: `not-run`.

Check GitLab's per-surface customization table: hierarchical `AGENTS.md` (user path respects `GLAB_CONFIG_DIR` / XDG / Windows `%APPDATA%`), `.gitlab/duo/chat-rules.md`, workspace `skills/<name>/SKILL.md` (not `.agents/skills` unless configured), `.gitlab/duo/mcp.json` (outbound MCP client, distinct from GitLab's MCP server), subagents, and executable YAML flows (keep triggers/tokens separate).

Official sources: [1](https://docs.gitlab.com/user/duo_agent_platform/customize/) · [2](https://docs.gitlab.com/user/duo_agent_platform/customize/agent_skills/) · [3](https://docs.gitlab.com/user/duo_agent_platform/customize/agents_md/) · [4](https://docs.gitlab.com/user/gitlab_duo/model_context_protocol/mcp_clients/)
