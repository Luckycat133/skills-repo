# IDE Migration Guide

Migrate MCP servers and skills between different AI IDEs.

## MCP Config Locations

| IDE | Path |
|-----|------|
| Claude Code | `~/.claude.json` |
| Cursor | `~/.cursor/mcp.json` |
| Continue | `.continue/config.json` |
| JetBrains | `~/.jetbrains.mcp.json` |
| VS Code | `.vscode/mcp.json` |
| Gemini CLI | `~/.gemini/settings.json` |
| Codex | `~/.codex/settings.json` |

## Migration Process

### 1. Export Current Config

Copy your MCP configuration from current IDE.

### 2. Convert Format

Most IDEs use similar JSON format:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package-name"],
      "env": {
        "KEY": "value"
      }
    }
  }
}
```

### 3. Import to Target IDE

Place config in the correct location for target IDE.

## Shared MCP Config

Create a shared config file and symlink:

```bash
# Create shared config
mkdir -p ~/.config/mcp
cp mcp.json ~/.config/mcp/shared.json

# Symlink for Cursor
ln -sf ~/.config/mcp/shared.json ~/.cursor/mcp.json

# Symlink for Claude Code
# Note: Claude Code uses ~/.claude.json, not a subdirectory
```

## Skill Migration

Skills are IDE-specific but often compatible:
- Claude Code skills work with Hermes Agent
- Some Continue skills can port to other platforms

## Verification

After migration, test each MCP server:

```bash
# Claude Code
claude mcp list

# Cursor
# Check in Settings > Tools & MCP

# Continue
# Test in chat: /config
```
