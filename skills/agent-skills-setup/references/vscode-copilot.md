# VS Code Copilot Configuration

Configure MCP servers in VS Code with Copilot.

## Note

VS Code Copilot has **limited MCP support**. For full MCP, use:
- VS Code with Continue.dev extension
- VS Code with Cline extension

## Via Continue.dev Extension

1. Install Continue.dev extension
2. Configure in `.continue/config.json`

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

## Via Cline Extension

1. Install Cline extension
2. Settings > MCP Servers
3. Add server configuration

## Project-Level Config

`.vscode/mcp.json` for project-specific servers.

## Verification

1. Restart VS Code
2. Check MCP in extension settings
3. Test in chat panel
