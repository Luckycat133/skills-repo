# Additional clients found in this review

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## codebuff

**Codebuff / Freebuff CLI and SDK** · Evidence: `documented-subset` · Runtime: `not-run`.

Codebuff (`CodebuffAI/freebuff`) loads Skills from `.agents/skills/<name>/SKILL.md` and `.claude/skills` (`/skill:name` + model selection), hierarchical `knowledge.md` (`*.knowledge.md` — distinct from `AGENTS.md`), `.agents/*.ts` custom agent templates (executable TS — review as inert text!), `.codebuffignore`, and MCP configs. Exclude chat state and API keys.

Official sources: [1](https://www.codebuff.com/docs/tips/skills) · [2](https://www.codebuff.com/docs/tips/knowledge-files) · [3](https://www.codebuff.com/docs/agents/agent-reference) · [4](https://github.com/CodebuffAI/freebuff)

## iflow

**iFlow CLI** · Evidence: `version-sensitive` · Runtime: `not-run`.

Inventory `IFLOW.md`, `.iflow/skills/<name>/SKILL.md`, `~/.iflow/skills/<name>/SKILL.md` (project wins; historical `skill.toml` may coexist), `.iflow/settings.json` / `~/.iflow/settings.json` (`mcpServers` via `patch-mcp`), subagents, subcommands, workflows, and hooks. **Never** run marketplace install commands during migration (they can execute package setup scripts).

Official sources: [1](https://docs.iflow.cn/cli/examples/skill/) · [2](https://docs.iflow.cn/cli/quickstart/) · [3](https://docs.iflow.cn/cli/examples/mcp/) · [4](https://docs.iflow.cn/cli/changelog/)

## codearts

**Huawei CodeArts Agent IDE and console** · Evidence: `documented-subset` · Runtime: `not-run`.

CodeArts Agent supports `SKILL.md` folders + resources, persistent Rules, custom agents, and stdio/remote MCP across enterprise, team, project, and local/cloud user scopes. Use IDE settings or console import/export (never guess disk roots or copy enterprise/team rules into personal scope without admin consent) and keep setup scripts unexecuted.

Official sources: [1](https://support.huaweicloud.com/intl/en-us/usermanual-codeartsagent/codeartsagent_ug_0027.html) · [2](https://support.huaweicloud.com/intl/en-us/usermanual-codeartsagent/codeartsagent_ug_0024.html) · [3](https://support.huaweicloud.com/intl/en-us/usermanual-codeartsagent/codeartsagent_ug_0019.html) · [4](https://support.huaweicloud.com/intl/en-us/usermanual-enterprise/codeartsagent_enterprise_0028.html)

## ona

**Ona / former Gitpod and its agent harnesses** · Evidence: `version-sensitive` · Runtime: `not-run`.

Current Ona agent docs redirect to a Codex-based harness: verify repository `AGENTS.md`, `.agents/skills/<name>/SKILL.md`, organization Skills, and MCP against the active remote runner rather than assuming `.ona/skills` or treating `.gitpod.yml` / `.devcontainer` environment files as AI rules. Exclude runner secrets and session logs.

Official sources: [1](https://ona.com/docs/ona/agents/codex) · [2](https://ona.com/docs/ona/agents/skills) · [3](https://ona.com/docs/ona/skills) · [4](https://ona.com/docs/ona/agents-md) · [5](https://ona.com/docs/ona/mcp)

## t3-code

**T3 Code desktop/web and providers** · Evidence: `documented-subset` · Runtime: `not-run`.

T3 Code (`pingdotgg/t3code`) wraps external/ACP agent providers: Skills, instructions, and MCP belong to the underlying provider harness (plus T3 composer commands and thread-scoped MCP). Route files to the active provider's profile, exclude T3 thread state/tokens, and **restart the T3 agent session** after edits so Skill/MCP discovery refreshes.

Official sources: [1](https://github.com/pingdotgg/t3code/blob/main/docs/user/providers-acp.md) · [2](https://github.com/pingdotgg/t3code/blob/main/docs/user/composer.md) · [3](https://github.com/pingdotgg/t3code/blob/main/docs/user/outside-agents.md)

## coder-xum

**Coder Xum / former coder/mux** · Evidence: `version-sensitive` · Runtime: `not-run`.

`coder/mux` redirects to `coder/xum` (distinct from unrelated Mux/AgentMux projects; `.mux` vs `.xum` paths depend on installed build). Inspect the installed desktop/SSH workspace config for `AGENTS.md`, Skills, custom agents, and MCP before writing, and rebind remote SSH connections/credentials separately.

Official sources: [1](https://github.com/coder/xum) · [2](https://coder.com/docs/ai-coder/agents/extending-agents)
