# Sublime Merge MCP Setup

Configure MCP servers in Sublime Merge.

## Config Path

`Packages/User/mcp.json`

## Finding Your Packages Directory

1. Open Sublime Merge
2. Preferences > Browse Packages
3. Note the path (usually `~/.config/sublime-merge/Packages` on Linux)

## Config Format

```json
{
  "mcpServers": {
    "server-name": {
      "command": "uvx",
      "args": ["mcp-server-package"]
    }
  }
}
```

## Example: GitHub MCP

```json
{
  "mcpServers": {
    "github": {
      "command": "uvx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token"
      }
    }
  }
}
```

## Setup Steps

1. Open Sublime Merge
2. Preferences > Browse Packages
3. Navigate to `User` folder
4. Create/edit `mcp.json`

## Use Cases

- Enhanced git history analysis
- AI-powered commit message suggestions
- Repository insights
