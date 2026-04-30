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
| `.claude/settings.json` | Project-level settings |
| `.claude.json` | Project-level MCP config |

**Warning**: Claude Code and Claude Desktop use **different** config files!

## Setup Methods

### Method 1: CLI (Recommended)

```bash
# Add MCP server
claude mcp add <name> <command> <args>

# List MCP servers
claude mcp list

# Remove MCP server
claude mcp remove <name>
```

### Method 2: Manual Edit

Create/edit `~/.claude.json` and add MCP servers under `mcpServers` key.

## Common Mistakes

- ❌ `~/.claude/.claude.json` (wrong path)
- ❌ `~/.claude/mcp.json` (wrong filename)
- ❌ Using Claude Desktop config with Claude Code (different files)
- ✅ `~/.claude.json` (correct)

## Verification

```bash
# Check MCP servers
claude mcp list

# Or check Claude Code version
claude --version
```

## Permissions

Claude Code prompts for MCP tool permissions. Approve in:
- First-use prompt
- Settings > MCP Servers
- Project-specific config for scoped access
