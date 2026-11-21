# Anthropic: Code is not Desktop Chat

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## claude-code

**Claude Code CLI, IDE integration, Desktop Code** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Instructions `CLAUDE.md`, `.claude/CLAUDE.md`, local `CLAUDE.local.md`, user `~/.claude/CLAUDE.md`, `@path` imports, and scoped `.claude/rules/*.md` / `~/.claude/rules/*.md` (`paths: ["glob", ...]`); Skills `.claude/skills/<name>/SKILL.md`, `~/.claude/skills/<name>/SKILL.md` (`disable-model-invocation`, `allowed-tools`, `context: fork`); Legacy commands `.claude/commands/*.md`, `~/.claude/commands/*.md`; Agents `.claude/agents/*.md`, `~/.claude/agents/*.md`; Hooks `hooks` subobject in `.claude/settings.json` / `.claude/settings.local.json` / `~/.claude/settings.json`; Authored memory `~/.claude/memory/*.md` (exclude `projects/*/sessions/*.jsonl`); MCP project `.mcp.json` (`mcpServers`), local project override `~/.claude.json` -> `projects[<workspace>].mcpServers`, user `~/.claude.json` -> `mcpServers` (`${VAR}` interpolation, `type: "http"|"sse"` + `url`). Built-in profile: `claude-code` (`claude`).
- **Migration cautions**: Never write literal secrets into a Git-tracked `.mcp.json` (`migrate_context.py` routes secret-bearing project MCP to untracked `~/.claude.json` `projects[ws].mcpServers` in `0600` mode). Preserve arguments, invocation controls, and `context: fork`; never copy `permissions.allow` or session transcripts. Desktop's **Code** tab must still have its sandbox/filesystem checked independently.
- **Check**: Skill discovery by name, matching vs non-matching path loading for `.claude/rules/*.md`, resolved `@` imports, and intact sibling keys in `~/.claude.json` / `settings.json`.

Official sources: [1](https://code.claude.com/docs/en/features-overview) · [2](https://code.claude.com/docs/en/memory) · [3](https://code.claude.com/docs/en/skills) · [4](https://code.claude.com/docs/en/mcp)

## claude-desktop

**Claude Desktop Chat, web Projects and Cowork** · Evidence: `discovery-required` · Runtime: `not-run`.

Do not merge Chat, Projects, Cowork, and the Code tab into one profile. Inventory uploaded Skills, Project instructions/knowledge, connectors, desktop extensions (`.mcpb`), and any exposed `claude_desktop_config.json` (`mcpServers`) through the actual build's UI. A valid Skill directory does not prove file-based installation on every account.

Import reviewed instructions and Skill archives via documented UI controls. Desktop extensions (`.mcpb`) are executable bundles, not plain JSON server entries; reauthorize connectors on the new device and never copy Desktop app-data folders or assume `.claude/` feeds Chat. Confirm visibility in the exact Chat/Project/Code surface.

Official sources: [1](https://support.claude.com/) · [2](https://code.claude.com/docs/en/desktop)
