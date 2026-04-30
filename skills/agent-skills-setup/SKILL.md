---
name: agent-skills-setup
description: Configure AI IDEs (Claude Code, Trae, Cursor, JetBrains, etc.) with skills from GitHub
triggers:
  - how to configure AI IDE
  - setup Claude Code with skills
  - configure MCP for IDE
  - AI coding assistant setup
---

# Agent Skills Setup

Comprehensive guide for configuring AI IDEs with skills from `Luckycat133/skills-repo`.

## Supported IDEs

| IDE | Support Level | MCP | Skills |
|-----|--------------|-----|--------|
| Claude Code | ⭐⭐⭐⭐⭐ | Native | Full |
| Trae | ⭐⭐⭐⭐ | Native | Full |
| Cursor | ⭐⭐⭐⭐ | Native | Full |
| Continue | ⭐⭐⭐⭐ | Native | Full |
| VSCode Copilot | ⭐⭐⭐ | Extension | Partial |
| JetBrains AI | ⭐⭐⭐ | Plugin | Partial |
| Amazon Q | ⭐⭐⭐ | Native | Partial |
| Gemini Code Assist | ⭐⭐⭐ | MCP | Partial |
| Codex | ⭐⭐⭐ | CLI | Limited |
| OpenClaw | ⭐⭐⭐⭐⭐ | Custom | Full |

## Quick Setup

### Step 1: Get Your GitHub Token

1. Go to https://github.com/settings/tokens
2. Generate new token (classic)
3. Required scopes: `repo`, `workflow`
4. Copy the token

### Step 2: Configure MCP

Add to your IDE's MCP configuration:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_your_token_here"
      }
    }
  }
}
```

Configuration file locations:
- **Claude Code**: `~/.claude/mcp.json`
- **Trae**: `~/.trae/mcp.json`
- **Cursor**: `~/.cursor/mcp.json`
- **VSCode**: `.vscode/mcp.json` (workspace) or user settings
- **Continue**: `~/.continue/config.json`
- **JetBrains**: `.jetbrains.mcp.json`

### Step 3: Verify Connection

```bash
# Test GitHub MCP
npx -y @modelcontextprotocol/server-github --help

# Check token
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user
```

## Tools

### Core Tools (via GitHub MCP)

| Tool | Description |
|------|-------------|
| `mcp_github_get_me` | Get authenticated user info |
| `mcp_github_get_file_contents` | Read files from repos |
| `mcp_github_search_repositories` | Search repos |
| `mcp_github_list_issues` | List repository issues |
| `mcp_github_list_commits` | List commits |
| `mcp_github_pull_request_*` | PR operations |

### Skill Management Tools

| Tool | Description |
|------|-------------|
| `skill_manage` | Create/update/delete skills |
| `skill_view` | Load skill content |
| `skill_list` | List available skills |

## Verification

After setup, verify in your IDE:

```
# Test GitHub access
List my repositories on GitHub

# Test skill loading
Load the agent-skills-setup skill

# Test MCP tools
Search for repositories with "python" in name
```

## Troubleshooting

### Token Issues
- Verify token has `repo` scope
- Check token hasn't expired
- Ensure token has access to private repos

### Connection Issues
- Restart IDE after config changes
- Clear MCP cache: `rm -rf ~/.claude/mcp*`
- Check network connectivity

## Related Skills

- [migration/openclaw-migration](migration/openclaw-migration) - Migrate from OpenClaw
