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

## Overview

This skill helps you configure various AI-powered IDEs to use skills from your centralized skills repository. Skills enable AI assistants to follow specialized workflows, use specific tools, and maintain consistent patterns across different IDEs and sessions.

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

## Quick Setup (All IDEs)

### Step 1: Get Your GitHub Token

Generate a Personal Access Token:
1. Go to https://github.com/settings/tokens
2. Generate new token (classic)
3. Required scopes: `repo`, `workflow`
4. Copy the token

### Step 2: Install Prerequisites

```bash
# Node.js (for npx)
node --version  # >= 18
```

### Step 3: Configure MCP

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

### Step 4: Verify Connection

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

## References (IDE-Specific Guides)

| Guide | Description |
|-------|-------------|
| [Claude Code](references/claude-code.md) | Primary IDE with full ACP support |
| [Trae](references/trae.md) | Chinese-friendly IDE with MCP support |
| [Cursor](references/cursor.md) | AI-first code editor |
| [Continue](references/continue.md) | Open-source AI assistant |
| [VSCode Copilot](references/vscode-copilot.md) | Microsoft Copilot integration |
| [JetBrains AI](references/jetbrains-ai.md) | IntelliJ/PyCharm AI Assistant |
| [Amazon Q](references/amazon-q.md) | AWS integrated AI assistant |
| [Gemini Code Assist](references/gemini-code-assist.md) | Google Cloud AI assistant |
| [Codex](references/codex.md) | OpenAI's CLI assistant |
| [OpenClaw](references/openclaw.md) | Custom IDE integration |

## Additional Resources

| Resource | Description |
|----------|-------------|
| [IDE Migration](references/ide-migration.md) | Migrate skills between IDEs |
| [Publishing](references/publishing.md) | How to publish skills |

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

### Skill Loading Issues
- Verify `skills-repo` is accessible
- Check skill format (SKILL.md with YAML frontmatter)
- Ensure skill name matches trigger

## Related Skills

- [migration/openclaw-migration](migration/openclaw-migration) - Migrate from OpenClaw
