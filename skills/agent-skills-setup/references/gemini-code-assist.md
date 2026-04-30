# Gemini Code Assist Configuration

**Note**: Gemini Code Assist is a **cloud-based service** (Google Cloud), not a local IDE with local MCP support.

## Overview

Gemini Code Assist provides AI coding assistance through:
- VS Code extension
- JetBrains plugins (IntelliJ, PyCharm, etc.)
- Google Cloud Console

## MCP Support

Gemini Code Assist does **NOT** use traditional local MCP server files like `~/.gemini/mcp.json`.

Instead:
- MCP support is available through **Gemini CLI** (separate tool)
- Cloud MCP servers are configured via Google Cloud Console
- Enterprise users configure via organization policies

## For Local MCP with Google AI

If you need MCP functionality, use **Gemini CLI** instead:

```bash
# Install Gemini CLI
npm install -g @google/gemini-cli

# Configure MCP in ~/.config/gemini/mcp.json
```

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
- See [Gemini Cloud Assist MCP](https://docs.cloud.google.com/cloud-assist/docs/use-gemini-cloud-assist-mcp)
