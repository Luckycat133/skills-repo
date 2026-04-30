# Amazon Q Developer Configuration

Amazon Q Developer supports MCP servers for extending capabilities.

## MCP Support Timeline

**Important**: MCP support for Amazon Q Developer IDE was added in **June 2025**.

## Configuration Method

MCP servers are configured through the **IDE UI**, not JSON files.

### Via IDE Interface

1. Open Amazon Q Developer in VS Code or JetBrains
2. Go to Amazon Q settings
3. Find MCP Servers section
4. Click "+" to add new MCP server
5. Configure name, command, and arguments

### Configuration Options

| Setting | Description |
|---------|-------------|
| Scope | Global (all projects) or Local (current project) |
| Name | Display name for the MCP server |
| Type | stdio, sse, or http |
| Command | npx, uvx, or full path to executable |
| Arguments | Command-line arguments |

## Legacy Settings

For older settings before MCP:

**Location**: `~/.aws/amazonq/` (varies by platform)

Note: This is not for MCP - it's for legacy Amazon Q preferences.

## Verification

1. Open Amazon Q Developer
2. Check MCP servers in settings
3. Tools should appear in Amazon Q chat
