# Chinese coding agents: versioned native surfaces

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## comate

**Baidu Comate IDE plugins and standalone IDE** · Evidence: `documented-subset` · Runtime: `not-run`.

Distinguish standalone Comate IDE from VS Code/JetBrains plugins. Inventory `.comate/skills/<name>/SKILL.md`, `.comate/rules/*.md`, `.comateignore`, custom agents/subagents, Spec/Mission task docs (keep as task artifacts, not always-on rules), and MCP (`mcpServers` resolved via native settings). Exclude generated Memory, indexes, credentials, and task history.

Official sources: [1](https://cloud.baidu.com/doc/COMATE/s/qm7yrpa11) · [2](https://cloud.baidu.com/doc/COMATE/s/Qlup6nu65) · [3](https://cloud.baidu.com/doc/COMATE/s/Nmpe5edyb)

## kimi-code

**Kimi Code current CLI and IDE/ACP use** · Evidence: `version-sensitive` · Runtime: `not-run`.

- **Candidate paths & schemas**: Active home is `$KIMI_CODE_HOME` or **`~/.kimi-code`** (legacy `~/.kimi` is source-only fallback; shared `~/.agents/skills` stays under `$HOME`). Files: `~/.kimi-code/AGENTS.md` and workspace `AGENTS.md`; Skills `.kimi-code/skills/<name>/SKILL.md`, `~/.kimi-code/skills/<name>/SKILL.md`; MCP `.kimi-code/mcp.json` and `~/.kimi-code/mcp.json` (`mcpServers`); plus `config.toml`, `tui.toml`, plugins/commands/hooks. Built-in profile: `kimi-code` (`kimiai`).
- **Cautions**: Exclude sessions and provider API keys in `config.toml` unless authorized; for ACP, resolve the agent process's execution `HOME`.

Official sources: [1](https://moonshotai.github.io/kimi-code/en/configuration/data-locations.html) · [2](https://moonshotai.github.io/kimi-code/en/customization/skills) · [3](https://moonshotai.github.io/kimi-code/en/customization/mcp) · [4](https://moonshotai.github.io/kimi-code/en/guides/ides)

## zcode

**Z.ai ZCode** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & precedence trap**: Skills `.zcode/skills/<name>/SKILL.md`, `~/.zcode/skills/<name>/SKILL.md` (check documented body-size cap and flat plugin Skill discovery); Rules `AGENTS.md` / `.zcode/rules`; Plugins root `plugin.json` (legacy `.zcode-plugin`); MCP `.zcode/mcp.json` and `~/.zcode/mcp.json` (`mcpServers`).
- **Scope-level shadowing**: Native `.zcode` MCP config **suppresses** shared `.agents/mcp.json` at the scope level rather than merging server-by-server — merge explicitly with `patch-mcp` after user confirmation.

Official sources: [1](https://zcode.z.ai/en/docs/skill) · [2](https://zcode.z.ai/en/docs/mcp-services) · [3](https://zcode.z.ai/en/docs/plugin)

## minimax-code

**MiniMax Code CLI and separately identified desktop/cloud products** · Evidence: `documented-subset` · Runtime: `not-run`.

`MiniMax-AI/minimax-code` provides a local coding CLI (`~/.minimax` or named profile root, workspace instructions, Skills, MCP, and reviewed memory); keep desktop/cloud MiniMax products separate. Exclude provider auth/session state and verify supported categories against the installed CLI build.

Official sources: [1](https://github.com/MiniMax-AI/minimax-code)

## mmx-cli

**MiniMax multimedia/service CLI** · Evidence: `provider-or-installer` · Runtime: `not-run`.

`MiniMax-AI/cli` (`mmx`) is a media/service CLI and Skill installer, not a coding-agent host with native rules/MCP. Route any Skills it installs to the consuming agent's profile and exclude `mmx` API host/key config unless specifically migrating `.env` service vars.

Official sources: [1](https://github.com/MiniMax-AI/cli)

## codely

**Tuanjie Codely IDE and Codely CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

Use Tuanjie's official Codely docs: CLI Skills `.codely-cli/skills/<name>/SKILL.md` and user Skills, `CODELY.md` / rules, commands, subagents, and `mcpServers` JSON (patchable via `patch-mcp`). Keep Unity Insight / Codely Context separate from authored rules, exclude Unity editor caches/scene DBs and session grants, and distinguish CLI vs IDE `@` reference syntax.

Official sources: [1](https://codely-docs.tuanjie.cn/guides/customization/) · [2](https://codely-docs.tuanjie.cn/guides/migration/) · [3](https://codely-docs.tuanjie.cn/features-introduction/MCP-guide/)
