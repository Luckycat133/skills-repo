# Tencent CodeBuddy and WorkBuddy

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## codebuddy

**CodeBuddy Code CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Instructions `CODEBUDDY.md` / `AGENTS.md`; Skills `.codebuddy/skills/<name>/SKILL.md`, `~/.codebuddy/skills/<name>/SKILL.md` (`$CODEBUDDY_CONFIG_DIR`, `context: fork`, Skill-scoped hooks); Commands `.codebuddy/commands/`, Agents `.codebuddy/agents/`, hooks inside `settings.json`, LSP, and MCP `.codebuddy/.mcp.json` / `$CODEBUDDY_CONFIG_DIR/.mcp.json` (`mcpServers`). Built-in profile: `codebuddy`.
- **Cautions**: Never carry `allowUntrustedFrontmatterHooks` trust flags or activate command/prompt/agent/HTTP hooks without explicit approval; do not mix CLI schemas with standalone IDE `RULE.mdc`.

Official sources: [1](https://www.codebuddy.cn/docs/cli/skills) · [2](https://www.codebuddy.cn/docs/cli/hooks) · [3](https://www.codebuddy.cn/docs/cli/plugins-reference)

## codebuddy-ide

**CodeBuddy IDE and IDE plugins** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory `.codebuddy/skills`, `.codebuddy/rules` (`RULE.mdc` / `*.md`), `.codebuddy/commands`, `.codebuddy/agents`, hooks, MCP (`.codebuddy/mcp.json`), and IDE Memory (built-in profile: `codebuddy-ide`). Supported hook events and generated Memory differ from CodeBuddy CLI: inspect the installed IDE build and local/remote extension host, exclude auto-generated Memory and auth tokens, and preserve rule file-scope triggers.

Official sources: [1](https://www.codebuddy.cn/docs/ide/Features/Hooks) · [2](https://www.codebuddy.cn/docs/ide/User-guide/Memory) · [3](https://www.codebuddy.cn/docs/ide/release-notes/release-notes)

## workbuddy

**WorkBuddy desktop/workspace** · Evidence: `documented-subset` · Runtime: `not-run`.

Current WorkBuddy Skills Market/import uses standard `SKILL.md` packages (not the retired `skill.yml`-only assumption). Import reviewed `SKILL.md` folders and workspace instructions through supported app controls, reauthorize MCP integrations, exclude app-data stores/generated memory, and confirm exact local directories on the installed build before direct disk writes.

Official sources: [1](https://www.codebuddy.cn/docs/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/Skills-Market)
