# qoder (International)

Qoder International exposes distinct CLI and IDE profiles. The CLI uses user Skills at `~/.qoder/skills/`, project Skills at `.qoder/skills/`, user settings at `~/.qoder/settings.json`, local project settings at `.qoder/settings.local.json`, and shareable MCP at `.mcp.json`.

Hooks live in layered settings and must only be emitted as disabled drafts. MCP conversion merges only `mcpServers`; OAuth tokens and permissions are not portable. Qoder CN, Work, and Cloud remain separate profiles.

Sources: [Skills](https://docs.qoder.com/en/cli/Skills), [MCP](https://docs.qoder.com/en/cli/mcp-servers), [hooks](https://docs.qoder.com/cli/hooks).
