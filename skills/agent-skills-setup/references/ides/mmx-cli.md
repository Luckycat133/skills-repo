# mmx-cli (MiniMax CLI)
- **detect**: `~/.mmx/`
- **mcp**: N/A (mmx IS the tool, not an MCP client) · config `~/.mmx/config.json` · JSON · Zod validated
- **skills**: `npx skills add MiniMax-AI/cli` symlinks to `~/.claude/skills/`, `~/.openclaw/skills/`, TRAE, OpenCode, etc.
- **commands**: `mmx text chat`, `mmx image generate`, `mmx video generate`, `mmx speech synthesize`, `mmx music generate`, `mmx vision describe`, `mmx search query`
- **note**: Region trap: global=api.minimax.io / cn=api.minimaxi.com (extra 'i'); API Key + Host must match region; `mmx config set --key region --value global|cn` if 401
