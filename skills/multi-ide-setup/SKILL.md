---
name: multi-ide-setup
description: Configure multiple AI IDEs (Claude Code, Trae, VSCode Copilot, Codex, etc.) with unified skills management
category: devops
---

# Multi-IDE Skills Setup

Unified configuration guide for integrating your skills-repo with multiple AI IDE platforms.

## Supported IDEs

| IDE | Command | Transport | Skill Loading |
|-----|---------|-----------|---------------|
| **Claude Code** | `claude --acp --stdio` | ACP/stdio | Native |
| **Trae** | Custom MCP client | HTTP | Via MCP config |
| **VSCode Copilot** | `github.copilot-chat` | Extension | Via VSCode settings |
| **Codex** | `claude` (proxied) | CLI | Via env vars |

## Quick Start

### 1. Claude Code (Primary)

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_your_token_here"
      }
    },
    "skills": {
      "command": "npx",
      "args": ["-y", "@anthropic/hermes-cli", "serve", "--skills-repo", "Luckycat133/skills-repo"]
    }
  }
}
```

Run: `claude --acp --stdio`

### 2. Trae IDE

Add to `~/.trae/mcp.json`:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_your_token_here"
      }
    },
    "skills": {
      "command": "npx",
      "args": ["-y", "@anthropic/hermes-cli", "serve", "--skills-repo", "Luckycat133/skills-repo"]
    }
  }
}
```

### 3. VSCode Copilot Chat

Add to `.vscode/mcp.json`:

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

Then in Copilot Chat settings, enable:
- `github.copilot-chat.agent.enabled: true`
- `github.copilot-chat.mcp.enabled: true`

### 4. Codex (OpenAI)

Set environment variables:

```bash
export GITHUB_TOKEN="ghp_your_token_here"
export ANTHROPIC_API_KEY="your_anthropic_key"
export CODEX_SKILLS_REPO="Luckycat133/skills-repo"
```

Run Codex with MCP bridge:
```bash
claude --acp --stdio | codex --mcp
```

## Unified Skills Loading

All IDEs can load skills from `Luckycat133/skills-repo` using Hermes CLI:

```bash
npx -y @anthropic/hermes-cli serve \
  --skills-repo Luckycat133/skills-repo \
  --port 8080
```

## Configuration Priority

1. **Claude Code**: Native ACP transport, full skill support
2. **Trae**: MCP JSON config, good skill support
3. **VSCode Copilot**: Extension-based, limited skill context
4. **Codex**: CLI-based, requires bridge for full features

## IDE-Specific Features

### Claude Code
- Full ACP transport support
- Native skill loading
- Session persistence
- Tool use with skills

### Trae
- Chinese interface
- MCP protocol support
- Good file editing
- Integrated terminal

### VSCode Copilot
- Inline chat
- Inline completion
- Chat participants
- MCP tools (limited)

### Codex
- CLI interface
- Multi-file editing
- Test generation
- Code review

## Migration Between IDEs

When switching IDEs, skills from `skills-repo` remain compatible:

```bash
# Export from source IDE
hermes-cli export --all --output ./my-skills

# Import to target IDE
hermes-cli import --from ./my-skills --ide <target>
```

## Troubleshooting

### Common Issues

1. **Token not recognized**
   - Verify `GITHUB_TOKEN` is set correctly
   - Check token has required scopes (repo, workflow)

2. **Skills not loading**
   - Ensure Hermes CLI is installed: `npx -y @anthropic/hermes-cli --version`
   - Check network connectivity to GitHub
   - Verify skills-repo is public or token has access

3. **MCP connection failed**
   - Restart IDE
   - Clear MCP cache: `rm -rf ~/.config/<ide>/mcp*`
   - Check logs for specific error

### Verification Commands

```bash
# Test GitHub MCP
npx -y @modelcontextprotocol/server-github --help

# Test Hermes CLI
npx -y @anthropic/hermes-cli --version

# Check token
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user
```

## See Also

- [Claude Code Setup](references/claude-code.md)
- [Trae Setup](references/trae.md)
- [VSCode Copilot Setup](references/vscode-copilot.md)
- [IDE Migration Guide](references/ide-migration.md)
