# Gemini Code Assist Configuration

**Note**: Gemini Code Assist is a **cloud-based service** (Google Cloud), not a local CLI with local MCP files.

## Overview

Gemini Code Assist provides AI coding assistance through:
- VS Code extension
- JetBrains plugins (IntelliJ, PyCharm, etc.)

## MCP Support

Gemini Code Assist **does NOT** support local MCP server files.

For MCP functionality, use **Gemini CLI** instead (separate tool).

## Gemini CLI (for MCP support)

Gemini CLI is a separate command-line tool that supports MCP.

### Configuration File

**Location**: `~/.gemini/settings.json`

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

### Quick Setup

```bash
# Install Gemini CLI
npm install -g @google/gemini-cli

# Configure MCP in ~/.gemini/settings.json
# Then restart Gemini CLI
```

### Platform-Specific Paths

| OS | Path |
|----|------|
| Linux | `~/.gemini/settings.json` |
| macOS | `~/.gemini/settings.json` |
| Windows | `%USERPROFILE%\.gemini\settings.json` |

## IDE Extension Configuration

### VS Code
1. Install "Gemini Code Assist" extension
2. Authenticate with Google account
3. Configure in VS Code settings

### JetBrains
1. Install Gemini plugin from JetBrains Marketplace
2. Sign in with Google account
3. Configure in IDE settings

## Enterprise Configuration

For Google Cloud enterprise users:
- Configure via [Cloud Console](https://console.cloud.google.com)
- MCP settings managed by organization policies
