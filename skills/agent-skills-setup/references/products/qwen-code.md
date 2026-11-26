# qwen-code

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Qwen Code CLI and its IDE/desktop integrations** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Instructions `QWEN.md`, `~/.qwen/QWEN.md`, scoped rules; Skills `.qwen/skills/<name>/SKILL.md`, `~/.qwen/skills/<name>/SKILL.md` (native `.qwen` wins over shared `.agents/skills`); Commands `.qwen/commands/*`, `~/.qwen/commands/*`; Agents `.qwen/agents/*.md`, `~/.qwen/agents/*.md`; MCP **`mcpServers`** subobject in `.qwen/settings.json` and `~/.qwen/settings.json`. Built-in profile: `qwen-code` (`qwen`).
- **Field & hook traps**: Qwen Skills use **`allowedTools`** (not `allowed-tools`; `migrate_context.py` translates spelling and flags tool-name verification). Keep command/HTTP/function/prompt hooks inactive and exclude Auto-Skill archives and non-MCP `settings.json` keys.

Official sources: [1](https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/) · [2](https://qwenlm.github.io/qwen-code-docs/en/users/features/rules/) · [3](https://qwenlm.github.io/qwen-code-docs/en/users/features/hooks/) · [4](https://qwenlm.github.io/qwen-code-docs/en/)
