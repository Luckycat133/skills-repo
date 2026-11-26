# codebuff

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Codebuff / Freebuff CLI and SDK** · Evidence: `documented-subset` · Runtime: `not-run`.

Codebuff (`CodebuffAI/freebuff`) loads Skills from `.agents/skills/<name>/SKILL.md` and `.claude/skills` (`/skill:name` + model selection), hierarchical `knowledge.md` (`*.knowledge.md` — distinct from `AGENTS.md`), `.agents/*.ts` custom agent templates (executable TS — review as inert text!), `.codebuffignore`, and MCP configs. Exclude chat state and API keys.

Official sources: [1](https://www.codebuff.com/docs/tips/skills) · [2](https://www.codebuff.com/docs/tips/knowledge-files) · [3](https://www.codebuff.com/docs/agents/agent-reference) · [4](https://github.com/CodebuffAI/freebuff)
