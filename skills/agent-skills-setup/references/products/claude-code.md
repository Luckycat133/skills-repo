# claude-code

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Claude Code CLI, IDE integration, Desktop Code** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Env override `CLAUDE_CONFIG_DIR` moves `~/.claude/*` and `.claude.json` under `$CLAUDE_CONFIG_DIR/`. Instructions `CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md`, user `~/.claude/CLAUDE.md`, `@path` imports, `.claude/rules/*.md` / `~/.claude/rules/*.md` (`paths: ["glob", ...]`); Skills `.claude/skills/<name>/SKILL.md`, `~/.claude/skills/<name>/SKILL.md` (`disable-model-invocation`, `allowed-tools`, `context: fork`); Commands `.claude/commands/*.md`; Agents `.claude/agents/*.md`; Hooks in `settings.json` / `settings.local.json`; Portable settings & `env`; Plugin registries; Auto/authored memory; MCP `.mcp.json` and `~/.claude.json`. Built-in profile: `claude-code` (`claude`).
- **Deep dives (progressive load per category)**: [Rules, Memory & Skills](claude-code/rules-skills.md) · [MCP](claude-code/mcp.md) · [Agents, Hooks & Settings](claude-code/agents-hooks-settings.md).
- **Migration cautions**: Never write literal secrets into a Git-tracked `.mcp.json` (`migrate_context.py` routes secret-bearing project MCP to untracked `~/.claude.json` `projects[ws].mcpServers` in `0600` mode). Preserve arguments, invocation controls, and `context: fork`; never copy `permissions` grants or `*.jsonl` session transcripts. Desktop's **Code** tab must still have its sandbox/filesystem checked independently.
- **Check**: Skill discovery by name, matching vs non-matching path loading for `.claude/rules/*.md`, resolved `@` imports, and intact sibling keys in `~/.claude.json` / `settings.json`.

Official sources: [1](https://code.claude.com/docs/en/features-overview) · [2](https://code.claude.com/docs/en/memory) · [3](https://code.claude.com/docs/en/skills) · [4](https://code.claude.com/docs/en/mcp)
