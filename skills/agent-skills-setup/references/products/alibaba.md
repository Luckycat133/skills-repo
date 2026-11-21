# Qwen Code, Qoder and Lingma

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## qwen-code

**Qwen Code CLI and its IDE/desktop integrations** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Instructions `QWEN.md`, `~/.qwen/QWEN.md`, scoped rules; Skills `.qwen/skills/<name>/SKILL.md`, `~/.qwen/skills/<name>/SKILL.md` (native `.qwen` wins over shared `.agents/skills`); Commands `.qwen/commands/*`, `~/.qwen/commands/*`; Agents `.qwen/agents/*.md`, `~/.qwen/agents/*.md`; MCP **`mcpServers`** subobject in `.qwen/settings.json` and `~/.qwen/settings.json`. Built-in profile: `qwen-code` (`qwen`).
- **Field & hook traps**: Qwen Skills use **`allowedTools`** (not `allowed-tools`; `migrate_context.py` translates spelling and flags tool-name verification). Keep command/HTTP/function/prompt hooks inactive and exclude Auto-Skill archives and non-MCP `settings.json` keys.

Official sources: [1](https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/) · [2](https://qwenlm.github.io/qwen-code-docs/en/users/features/rules/) · [3](https://qwenlm.github.io/qwen-code-docs/en/users/features/hooks/) · [4](https://qwenlm.github.io/qwen-code-docs/en/)

## qoder

**Qoder International IDE, CLI, JetBrains, Work, cloud and Wake** · Evidence: `documented-subset` · Runtime: `not-run`.

Separate CLI (`~/.qoder/settings.json`, `.qoder/settings.json`, `.qoder/settings.local.json`, `.qoder/skills`, `.qoder/rules`, `.qoder/agents`) from IDE, Work, Wake, and cloud UI storage. Patch only selected `mcpServers` subobjects via `patch-mcp`, keep local grants out of shared `.qoder/settings.json`, preserve plugin component namespaces, and exclude Quest/autonomous task artifacts from persistent rules.

Official sources: [1](https://docs.qoder.com/product-series/what-is-qoder) · [2](https://docs.qoder.com/cli/config-scope) · [3](https://docs.qoder.com/extensions/plugins) · [4](https://docs.qoder.com/qoder/custom-agents)

## qoder-cn

**Qoder CN / Tongyi Lingma** · Evidence: `version-sensitive` · Runtime: `not-run`.

Brand rename to Qoder CN did not rename every path: current CN IDE docs still use `.lingma/skills/<name>/SKILL.md`, `~/.lingma/skills/<name>/SKILL.md`, and `.lingma/rules` (`.agents/skills` compatibility is version-dependent). Do not overwrite CN IDE paths with International `.qoder` CLI paths; inspect CN IDE vs CN CLI vs Work settings locally and check duplicate Skill names across `.lingma` and `.agents`.

Official sources: [1](https://docs.qoder.cn/user-guide/skills) · [2](https://docs.qoder.cn/user-guide/what-is-qoder-cn) · [3](https://help.aliyun.com/zh/lingma/qoder-cn-update-log)
