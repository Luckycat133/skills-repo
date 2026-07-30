# tencent-codebuddy-ide (Tencent — standalone IDE, distinct from plugin)
- **detect**: CodeBuddy IDE desktop app
- **mcp**: IDE Settings → MCP · root_key `mcpServers` · JSON · the standalone IDE docs show the JSON schema and UI, but do not publish a portable user/project MCP file path; manual/UI-only
- **project rules**: `.codebuddy/rules/<name>/RULE.mdc` · project rules are version-controlled and use Markdown plus CodeBuddy frontmatter (`description`, `alwaysApply`, `enabled`, `updatedAt`, optional `provider`)
- **project/user skills**: `.codebuddy/skills/` is the canonical project location; the IDE exposes user Skills through its Settings path picker, but the reviewed official docs do not publish a stable user filesystem path
- **context**: project-root `CODEBUDDY.md` is supported; `AGENTS.md` is a compatibility fallback when `CODEBUDDY.md` is absent
- **commands/agents/hooks/memory**: UI/IDE-managed or not given a portable standalone path in the reviewed IDE docs; do not reuse the CLI's global MCP/settings paths for the IDE
- **note**: Standalone IDE is distinct from CodeBuddy Code CLI/plugin. Sources: [CodeBuddy IDE overview](https://www.codebuddy.cn/docs/ide/User-guide/Overview), [IDE Skills](https://www.codebuddy.cn/docs/ide/Features/Skills), [IDE Rules](https://www.codebuddy.cn/docs/ide/User-guide/Rules), [IDE MCP](https://www.codebuddy.cn/docs/ide/User-guide/MCP), [IDE slash commands](https://www.codebuddy.cn/docs/ide/User-guide/Slash-Commands)
