---
name: agent-skills-setup
description: Configure AI IDEs with MCP servers and skills from GitHub
triggers:
  - how to configure AI IDE
  - setup Claude Code with skills
  - configure MCP for IDE
  - AI coding assistant setup
---

# Agent Skills Setup

Configure AI IDEs with MCP servers and skills for enhanced productivity.

## IDE Support Matrix

| IDE | MCP Support | Config Path |
|-----|-------------|-------------|
| Claude Code | ✅ Full | `~/.claude.json` |
| Trae | ✅ Full | Settings > MCP |
| Cursor | ✅ Full | `~/.cursor/mcp.json` |
| Continue | ✅ Full | `.continue/config.json` |
| JetBrains AI | ✅ 2025.1+ | Settings > Tools > MCP |
| VS Code Copilot | ⚠️ Extension | `.vscode/mcp.json` |
| Amazon Q | ✅ 2025+ | IDE UI / CLI |
| Gemini CLI | ✅ Full | `~/.gemini/settings.json` |
| Codex CLI | ✅ Full | `~/.codex/settings.json` |

## MCP Server Execution

### Recommended: uvx (Fast, Secure)

```bash
# Install uv first
curl -LsSf https://astral.sh/uv/install.sh | sh

# Use uvx for Python MCP servers
"command": "uvx",
"args": ["--from", "mcp-server-github", "mcp-server-github"]
```

### Alternative: npx (Node.js)

```bash
# For Node.js MCP servers
"command": "npx",
"args": ["-y", "@modelcontextprotocol/server-github"]
```

### Security Note

- **Development**: npx/uvx fine for testing
- **Production**: Consider Docker or pinned versions

## Quick Setup: GitHub MCP

### 1. Get Token

https://github.com/settings/tokens
- Scope: `repo`, `workflow`

### 2. Configure (Claude Code)

```bash
claude mcp add github npx -y @modelcontextprotocol/server-github
```

### 3. Verify

```bash
claude mcp list
```

## Skill Workflow

1. Load skill: `skill_view(name="agent-skills-setup")`
2. Follow IDE-specific guide in `references/`
3. Test with: `Search my repositories on GitHub`

## References

- `references/claude-code.md` - Claude Code setup
- `references/trae.md` - Trae IDE setup
- `references/cursor.md` - Cursor setup
- `references/continue.md` - Continue setup
- `references/jetbrains-ai.md` - JetBrains setup
- `references/vscode-copilot.md` - VS Code Copilot
- `references/amazon-q.md` - Amazon Q setup
- `references/gemini-code-assist.md` - Gemini CLI
- `references/codex.md` - Codex CLI
- `references/ide-migration.md` - Migrate between IDEs
