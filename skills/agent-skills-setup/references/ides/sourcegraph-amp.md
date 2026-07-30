# sourcegraph-amp
- **detect**: `~/.config/amp/`
- **mcp**: via `amp mcp add <name> <url>` CLI (NOT config key) · `amp mcp list`
- **rules**: `AGENTS.md`
- **skills**: project `.amp/skills/<name>/SKILL.md` · global `~/.config/amp/skills/` / `~/.amp/skills/` / `~/.agents/skills/`
- **commands**: `~/.config/amp/` (slash commands)
- **agents**: built-in Oracle, Librarian, Painter, Code Review; custom via plugin API
- **hooks**: `~/.config/amp/plugins/*.ts` (TypeScript; events: session.start, agent.start/end, tool.result)
- **note**: Native HTTP+OAuth+DCR; no mcp-remote needed
