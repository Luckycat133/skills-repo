# Claude Code Configuration

Configure Claude Code with MCP servers and settings.

## Configuration File Locations

### Primary Config (Important!)

**MCP servers and settings go in `~/.claude.json`**

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your_token"
      }
    }
  }
}
```

### Other Config Files

| File | Purpose |
|------|---------|
| `~/.claude.json` | User-level MCP and settings |
| `~/.claude/settings.json` | Alternative location (may work) |
| `.claude/settings.json` | Project-level settings |
| `.claude.json` | Project-level MCP config |

**Warning**: Claude Code and Claude Desktop use **different** config files!

## Common Mistakes

- ❌ `~/.claude/.claude.json` (wrong path)
- ❌ `~/.claude/mcp.json` (wrong filename)
- ✅ `~/.claude.json` (correct)

## Setup Steps

1. Create/edit `~/.claude.json`
2. Add MCP servers under `mcpServers` key
3. Restart Claude Code

## Verification

```bash
# Check Claude Code version
claude --version

# Test MCP connection
claude /mcp
```

## Permissions

Claude Code prompts for MCP tool permissions. Approve in:
- First-use prompt
- Settings > MCP Servers
- Project-specific `.claude.json` for scoped access
