# Codex CLI Configuration

Configure MCP servers in OpenAI Codex CLI.

## Status

✅ **Active** - Codex CLI was relaunched in 2025 with MCP support.

## Installation

```bash
# Install Codex CLI
npm install -g @openai/codex

# Or via official installer
curl -sLS https://github.com/openai/codex/releases/latest/download/codex-linux-x64 -o codex
chmod +x codex
mv codex /usr/local/bin/
```

## Configuration

**Location**: `~/.codex/settings.json`

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

## Usage

```bash
# Start Codex
codex

# Or with specific model
codex --model gpt-5-codex
```

## MCP Integration

Codex CLI supports MCP tool calls for:
- File operations
- Git operations
- Database access
- Custom tools

## History

- **2023**: Original Codex API deprecated
- **2025**: Codex CLI relaunched with GPT-5 models
- **2025.09**: Major update with GPT-5.5 model

## Verification

```bash
codex --version
codex mcp list
```
