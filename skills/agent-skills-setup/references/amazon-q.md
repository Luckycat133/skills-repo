# Amazon Q Developer Configuration

Amazon Q Developer supports MCP servers for extending capabilities.

## MCP Support Timeline

- **CLI**: MCP support added **April 2025**
- **IDE**: MCP support added **June 2025**
- **Admin controls**: August 2025
- **Remote MCP servers**: September 2025

## Configuration Method

MCP servers can be configured via:
- **IDE UI**: Settings > MCP Servers > Add
- **CLI**: `q mcp` commands

### Via IDE Interface

1. Open Amazon Q Developer in VS Code or JetBrains
2. Go to Amazon Q settings
3. Find MCP Servers section
4. Click "+" to add new MCP server
5. Configure name, command, and arguments

### Via CLI

```bash
# Add MCP server
q mcp add <name> <command> <args>

# List MCP servers
q mcp list

# Remove MCP server
q mcp remove <name>
```

### Configuration Options

| Setting | Description |
|---------|-------------|
| Scope | Global or Local (per project) |
| Name | Display name for the MCP server |
| Type | stdio, sse, or http |
| Command | npx, uvx, or full path |
| Arguments | Command-line arguments |

## Verification

1. Open Amazon Q Developer
2. Check MCP servers: `q mcp list`
3. Tools should appear in Amazon Q chat
