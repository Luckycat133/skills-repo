---
name: agent-skills-setup
description: Configure and manage MCP servers in AI-powered IDEs (Claude Desktop, Claude Code, Cursor, JetBrains, Amazon Q, Gemini CLI, Codex, Trae, Trae CN, Windsurf, Zed, VS Code Copilot, Cline, Continue, antigravity, Helix, etc.)
triggers:
  - setup mcp server
  - configure claude code mcp
  - cursor mcp config
  - install mcp in ide
  - AI IDE mcp setup
  - windsurf mcp
  - zed mcp setup
  - trae mcp setup
  - antigravity mcp
  - vs code copilot mcp
  - cline mcp
---

# MCP Server Setup for AI IDEs

Configure Model Context Protocol (MCP) servers across popular AI-powered IDEs.

> **Last Updated**: 2026-07
> **MCP Protocol Version**: 2025-11-25 (stable), upcoming RC (stateless core, MCP Apps, Tasks)
> **Note**: Old SSE transport is deprecated; use Streamable HTTP for remote servers.

## Supported IDEs

### Desktop Clients & CLI Tools

| IDE | Developer | MCP Support | Config Path | Root Key |
|-----|-----------|-------------|-------------|----------|
| [Claude Desktop](#claude-desktop) | Anthropic | Full | macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`<br>Windows: `%APPDATA%\Claude\claude_desktop_config.json`<br>Linux: `~/.config/Claude/claude_desktop_config.json` | `mcpServers` |
| [Claude Code](#claude-code) | Anthropic | Full | `~/.claude.json` (global) / `.mcp.json` (project) | `mcpServers` |
| [Cursor](#cursor) | Cursor | Full | macOS/Linux: `~/.cursor/mcp.json`<br>Windows: `%APPDATA%\Cursor\mcp.json`<br>Project: `.cursor/mcp.json` | `mcpServers` |
| [Cline (Roo Code)](#cline) | Cline | Full | VS Code settings / GUI marketplace | `mcpServers` |
| [Continue.dev](#continuedev) | Continue | Open Source | `.continue/mcpServers/*.yaml` | YAML format |
| [JetBrains AI](#jetbrains-ai) | JetBrains | Full | GUI (Settings > Tools > AI Assistant > MCP) | `mcpServers` |
| [VS Code + Copilot](#vs-code--copilot) | Microsoft | Full (v1.102+) | Workspace: `.vscode/mcp.json`<br>User: `settings.json` > `mcp.servers` | **`servers`** (not mcpServers) |
| [Trae](#trae--trae-cn) | ByteDance | Full | See OS-specific paths below | `mcpServers` |
| [Trae CN](#trae--trae-cn) | ByteDance | Full | See OS-specific paths below | `mcpServers` |
| [antigravity](#antigravity) | Google | Full | Global: `~/.gemini/antigravity/mcp_config.json`<br>Workspace: `.agents/mcp_config.json` | `mcpServers` |
| [Windsurf](#windsurf) | Codeium | Full | macOS/Linux: `~/.codeium/windsurf/mcp_config.json`<br>Windows: `%USERPROFILE%\.codeium\windsurf\mcp_config.json` | `mcpServers` |
| [Zed](#zed) | Zed | Full | Linux: `~/.config/zed/settings.json`<br>macOS: `~/Library/Application Support/Zed/settings.json`<br>Windows: `%APPDATA%\Zed\settings.json`<br>Project: `.zed/settings.json` | **`context_servers`** |
| [Helix](#helix) | Helix | Plugin (helix-ai) | `~/.config/helix/config.toml` | `[mcp_servers.name]` (TOML) |
| [Gemini CLI](#gemini-cli) | Google | Full | `~/.gemini/settings.json` (global) / `.gemini/settings.json` (project) | `mcpServers` |
| [Codex CLI](#codex-cli) | OpenAI | Full | `~/.codex/config.toml` (global) / `.codex/config.toml` (project) | **`[mcp_servers.name]`** (TOML) |
| [Amazon Q](#amazon-q) | AWS | Full | New: `~/.aws/amazonq/default.json` / `.amazonq/default.json`<br>Legacy: `.amazonq/mcp.json` | `mcpServers` |
| [Nova](#nova) | Panic | Extension | Claude Code Bridge extension (not a generic MCP client) | N/A |
| [BBEdit](#bbedit) | Bare Bones | ❌ None | No MCP support (AI Chat Worksheets only) | N/A |

### Cloud & Web IDEs

| IDE | Developer | MCP Support | Configuration |
|-----|-----------|-------------|---------------|
| [Replit](#replit) | Replit | ✅ Native | Built-in MCP integration panel, project settings |
| [GitHub Codespaces](#github-codespaces) | GitHub | ⚠️ Ecosystem | Use VS Code MCP inside devcontainer + devcontainer-mcp bridge |
| [StackBlitz](#stackblitz) | StackBlitz | ⚠️ Third-party server | Read-only access via `stackblitz-mcp` (external client) |
| [CodeSandbox](#codesandbox) | CodeSandbox | ⚠️ Third-party server | Via `@techlibs/codesandbox-mcp` (external client) |
| [Gitpod](#gitpod) | Gitpod | ❌ No native | Can run MCP clients inside workspace, but no platform MCP endpoint |

### Specialized Tools

| Tool | Developer | MCP Support | Config Path | Root Key |
|------|-----------|-------------|-------------|----------|
| [Forge](#forge) | Forge | Full | `.forge/mcp.json` | `mcpServers` |
| [Zulip](#zulip) | Zulip | ⚠️ Third-party servers | Multiple community MCP servers available | N/A |
| Lapce | Lapce | ❌ No native | Use Cursor/Zed instead | N/A |
| Sublime Merge | Sublime HQ | ❌ None | No plugin API | N/A |

---

## Installation Methods

### Recommended: uvx (Python)

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Run MCP servers with uvx
uvx mcp-server-package --key value
```

### Alternative: npx (Node.js)

```bash
npx -y @modelcontextprotocol/server-package
```

### Other Methods

| Method | Usage | Notes |
|--------|-------|-------|
| **pipx** | `pipx install mcp-server-package` | Python, more mature than uvx |
| **Docker** | `docker run -i --rm ghcr.io/owner/mcp-server` | Isolated, standardized deployment |
| **mcp-remote** | `npx mcp-remote https://example.com/mcp` | HTTP→stdio bridge for clients without native HTTP support |
| **Global install** | `npm install -g <package>` or `pip install <package>` | For frequently used servers |

> **Find MCP servers**: Official registry at https://registry.modelcontextprotocol.io, Docker MCP Catalog (hub.docker.com/mcp) has 300+ verified images.

---

## Transport Types

MCP supports two main transport types:

### stdio (Local Process)
Most common for local tools. Starts a subprocess and communicates via stdin/stdout.

```json
{
  "mcpServers": {
    "server-name": {
      "command": "uvx",
      "args": ["mcp-server-package"],
      "env": { "API_KEY": "${env:MY_API_KEY}" },
      "cwd": "/optional/working/directory"
    }
  }
}
```

### Streamable HTTP (Remote)
Modern standard for remote servers (replaces deprecated SSE transport). Single endpoint, session management, load-balancer friendly.

```json
{
  "mcpServers": {
    "remote-server": {
      "url": "https://example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${env:MY_TOKEN}"
      }
    }
  }
}
```

> **Note**: For clients without native HTTP support (e.g., older Claude Desktop), use `mcp-remote` bridge:
> ```json
> { "command": "npx", "args": ["mcp-remote", "https://example.com/mcp", "-y"] }
> ```

### Common Configuration Fields

| Field | Description |
|-------|-------------|
| `command` | Executable path (stdio only, no spaces - use args for parameters) |
| `args` | Array of command arguments |
| `env` | Environment variables key-value pairs |
| `url` | Remote server URL (HTTP transport) |
| `headers` | HTTP headers (HTTP transport) |
| `cwd` | Working directory for the server process |
| `timeout` / `startup_timeout_sec` | Server startup/tool timeout |
| `disabled` | Set to `true` to temporarily disable without removing |
| `autoApprove` / `alwaysAllow` | List of tools to auto-approve (use cautiously) |

---

## Claude Desktop

**Developer:** Anthropic

| OS | Config Path |
|----|-------------|
| macOS | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Windows | `%APPDATA%\Claude\claude_desktop_config.json` |
| Linux | `~/.config/Claude/claude_desktop_config.json` |

Root key: `mcpServers`

```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${env:GITHUB_TOKEN}"
      }
    }
  }
}
```

> **Note**: After editing config, fully quit and restart Claude Desktop (not just close window).

---

## Claude Code

**Developer:** Anthropic

| Config Type | Path |
|-------------|------|
| Global | `~/.claude.json` |
| Project | `.mcp.json` (project root, can be shared via Git) |

Root key: `mcpServers`

### CLI Commands
```bash
claude mcp add --transport stdio <name> -- <command> [args...]
claude mcp list
claude mcp remove <name>
```

> **Important**: Do NOT use `~/.claude/settings.json` - that path does not work for MCP.

---

## Cursor

**Developer:** Cursor

| Config Type | Path |
|-------------|------|
| Global (macOS/Linux) | `~/.cursor/mcp.json` |
| Global (Windows) | `%APPDATA%\Cursor\mcp.json` |
| Project | `.cursor/mcp.json` |

Root key: `mcpServers`

Project config overrides global for same-named servers.

---

## Cline

**Developer:** Cline (formerly Roo Code)

**Platform:** VS Code extension

Cline includes a built-in MCP Marketplace for one-click installation. Access via:
1. Open Cline sidebar
2. Click MCP Servers icon
3. Browse marketplace or add manually

Config file: `cline_mcp_settings.json` (managed via GUI)
Root key: `mcpServers`

---

## Continue.dev

**Developer:** Continue (Open Source)

**Platforms:** VS Code, JetBrains

Config format: YAML files in `.continue/mcpServers/` directory. Can import from Claude/Cursor JSON configs directly.

Each MCP server gets its own YAML file:

```yaml
# .continue/mcpServers/github.yaml
name: GitHub
command: npx
args:
  - -y
  - "@modelcontextprotocol/server-github"
env:
  GITHUB_PERSONAL_ACCESS_TOKEN: ${env:GITHUB_TOKEN}
```

---

## JetBrains AI

**Developer:** JetBrains
**Version required:** 2025.2+

**Method:** GUI configuration (Settings > Tools > AI Assistant > Model Context Protocol)

Supports both global and project-level configuration. STDIO and Streamable HTTP transports are supported. Has "Import from Claude" button to migrate existing configs. JSON config format uses `mcpServers` root key (compatible with Claude Desktop format).

---

## Trae / Trae CN

**Developer:** ByteDance
**Version required:** v1.3.0+

### Global Config Paths

| OS | Trae International | Trae CN |
|----|-------------------|---------|
| Windows | `%APPDATA%\Trae\User\mcp.json` | `%APPDATA%\Trae CN\User\mcp.json` |
| macOS | `~/Library/Application Support/Trae/User/mcp.json` | `~/Library/Application Support/Trae CN/User/mcp.json` |
| Linux | `~/.config/Trae/User/mcp.json` | `~/.config/Trae CN/User/mcp.json` |

> **Easiest way**: Settings → MCP → Click "Raw Config (JSON)" button to open the actual config file.

### Project Config
Path: `.trae/mcp.json` (project root)
**Requires manual enable**: Settings → MCP → Toggle on "Enable project-level MCP"

> **Important**: Project-level MCP is experimental and does NOT work in Trae SOLO cloud mode as of 2026-06. Only works in local IDE mode.

Root key: `mcpServers`

### MCP Marketplace
Trae includes a built-in MCP marketplace (Settings → MCP → Add → Add from marketplace) with one-click install for popular servers (GitHub, Figma, Playwright, Tavily, etc.).

### Cursor Compatibility
Early Trae versions read `~/.cursor/mcp.json` for migration compatibility. Current versions use independent paths but the JSON format is identical - just copy/paste the `mcpServers` contents.

---

## antigravity

**Developer:** Google

| Config Type | Path |
|-------------|------|
| Global | `~/.gemini/antigravity/mcp_config.json` |
| Workspace | `.agents/mcp_config.json` |

Root key: `mcpServers`

---

## Windsurf

**Developer:** Codeium

| OS | Path |
|----|------|
| macOS/Linux | `~/.codeium/windsurf/mcp_config.json` |
| Windows | `%USERPROFILE%\.codeium\windsurf\mcp_config.json` |

Root key: `mcpServers`
Note: Windsurf uses the non-standard field name `serverUrl` for remote HTTP servers (most other clients use the standard `url` field).

> **Note**: Path must include the `windsurf` subdirectory. Some non-English docs incorrectly omit it.
> **No project-level config** - only global.

---

## Zed

**Developer:** Zed

| Config Type | Linux | macOS | Windows |
|-------------|-------|-------|---------|
| User | `~/.config/zed/settings.json` | `~/Library/Application Support/Zed/settings.json` | `%APPDATA%\Zed\settings.json` |
| Project | `.zed/settings.json` | `.zed/settings.json` | `.zed/settings.json` |

**Root key: `context_servers`** (NOT `mcpServers` - this is a common mistake!)

```json
{
  "context_servers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "${env:GITHUB_TOKEN}" }
    },
    "remote": {
      "url": "https://example.com/mcp",
      "headers": { "Authorization": "Bearer token" }
    }
  }
}
```

> **Important**: GUI-launched Zed does NOT inherit shell PATH. Use absolute paths for commands and explicitly set all required env vars. Check status in Settings → AI → MCP Servers (green indicator = active).

---

## VS Code + Copilot

**Developer:** Microsoft
**Version required:** v1.102+ (stable)

| Config Type | Path | Root Key |
|-------------|------|----------|
| Workspace (recommended for teams) | `.vscode/mcp.json` | **`servers`** |
| User Global | `settings.json` → `mcp.servers` | `mcp.servers` |

```json
{
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@microsoft/mcp-server-playwright"]
    }
  }
}
```

> **Critical**: Root key is `servers`, NOT `mcpServers`! MCP tools are only available in **Agent mode**.
> Access GUI via Command Palette → "MCP: Add Server" or "MCP: List Servers".

> **Copilot CLI Note**: Copilot CLI uses separate config at `.mcp.json` or `.github/mcp.json` with root key `mcpServers` and requires `"type": "local"` or `"type": "http"` per server.

---

## Gemini CLI

**Developer:** Google

| Config Type | Path |
|-------------|------|
| Global | `~/.gemini/settings.json` |
| Project | `.gemini/settings.json` |
| System (Linux/macOS) | `/etc/gemini-cli/settings.json` |

Root key: `mcpServers`

Supports STDIO, SSE (legacy), and Streamable HTTP. Server names use hyphens not underscores (e.g., `brave-search` not `brave_search`). Supports variable interpolation: `$VAR_NAME` or `${VAR_NAME}`.

---

## Codex CLI

**Developer:** OpenAI

| Config Type | Path |
|-------------|------|
| Global | `~/.codex/config.toml` |
| Project | `.codex/config.toml` (trusted projects only) |

**Format: TOML**, section name is `[mcp_servers.<name>]` (underscore, NOT hyphen!)

```toml
# Remote HTTP (recommended for GitHub)
[mcp_servers.github]
url = "https://api.githubcopilot.com/mcp/"
bearer_token_env_var = "GITHUB_PAT_TOKEN"

# Local stdio
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
startup_timeout_sec = 20
```

### CLI Commands
```bash
codex mcp add <name> -- <command> [args...]   # stdio
codex mcp add <name> --url <url>              # HTTP
codex mcp list
codex mcp remove <name>
```

> Check servers in Codex with `/mcp` command.

---

## Helix

**Developer:** Helix
**Support:** ⚠️ Via third-party `helix-ai` plugin only (early stage)

Helix core has no native MCP. The helix-ai plugin adds basic Tools-only support (no Resources/Prompts/Sampling).

Config file: `~/.config/helix/config.toml` (main config, no separate MCP.toml)

```toml
[mcp_servers.github]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-github"]
startup_timeout_sec = 10
tool_timeout_sec = 60
env = { GITHUB_TOKEN = "${GITHUB_TOKEN}" }
```

---

## Amazon Q

**Developer:** AWS

| Config Type | New Path (recommended) | Legacy Path (compatible) |
|-------------|----------------------|------------------------|
| Global | `~/.aws/amazonq/default.json` | `~/.aws/amazonq/mcp.json` |
| Project | `.amazonq/default.json` | `.amazonq/mcp.json` |

Root key: `mcpServers`

Set `"useLegacyMcpJson": true` in default.json to also read legacy mcp.json files. Project config takes priority over global. GUI configuration available via Q Developer panel.

---

## Nova

**Developer:** Panic
**Support:** ⚠️ Third-party extension "Claude Code Bridge" only

Nova has NO generic MCP client. The Claude Code Bridge extension (`ca.okapi.claudecode-nova`) bridges Nova as an IDE to Claude Code CLI via WebSocket. It shares editor context (active file, selection, workspace) with Claude Code but cannot add arbitrary MCP servers like filesystem or postgres.

To use other MCP tools, configure them in Claude Code's config, not in Nova.

---

## BBEdit

**Developer:** Bare Bones
**Support:** ❌ No MCP support

BBEdit 15/16 has AI Chat Worksheets for basic LLM chat but NO MCP client capability (no tool calls, no server connections). LSP support is solid, but MCP is not implemented.

A third-party `bb-applescript-mcp-server` exists to control BBEdit FROM external MCP clients (via AppleScript), but this does not add MCP functionality inside BBEdit itself.

---

## Forge

**Developer:** Forge

| Config Type | Path |
|-------------|------|
| Project | `.forge/mcp.json` |

Root key: `mcpServers`
Supports stdio and HTTP transports (SSE is legacy/deprecated).

---

## GitHub Codespaces

**Developer:** GitHub
**Support:** ⚠️ Ecosystem support (no native MCP endpoint)

Options:
1. **Inside Codespaces**: Use VS Code Copilot MCP (`.vscode/mcp.json`) since Codespaces runs full VS Code
2. **Control Codespaces externally**: Use third-party `devcontainer-mcp` bridge to manage Codespaces from your local AI IDE

No native Codespaces-as-MCP-server endpoint exists.

---

## Replit

**Developer:** Replit
**Support:** ✅ Native MCP host

Replit has built-in MCP integration:
1. Open project settings → MCP/AI Integration section
2. Select permission level (read-only, read-write, full execution)
3. Generate access token and copy endpoint URL to your client

Replit exposes filesystem, command execution, console output, and environment variable access via MCP. Official template available at https://replit.com/@matt/Learn-about-MCP.

---

## StackBlitz

**Developer:** StackBlitz
**Support:** ⚠️ Third-party MCP server (external access only)

Community `stackblitz-mcp` package provides **read-only** access to StackBlitz projects from external MCP clients:

```bash
npm i -g stackblitz-mcp
```

Tools: resolve_project, list_files, read_file, search_files (all read-only, no write/execute). StackBlitz's web IDE itself has no built-in MCP client.

---

## Gitpod

**Developer:** Gitpod
**Support:** ❌ No native MCP support

Gitpod has no official MCP integration or MCP server endpoint. You can run MCP clients (like Claude Code) inside a Gitpod workspace, but the Gitpod platform itself does not expose MCP services.

---

## CodeSandbox

**Developer:** CodeSandbox
**Support:** ⚠️ Third-party MCP server (external access)

Community `@techlibs/codesandbox-mcp` provides read/write access from external clients:

```json
{
  "mcpServers": {
    "codesandbox": {
      "command": "npx",
      "args": ["-y", "@techlibs/codesandbox-mcp@latest", "--read-only"],
      "env": { "CODESANDBOX_API_TOKEN": "${env:CSB_API_KEY}" }
    }
  }
}
```

Supports sandbox lifecycle, file read/write, and command execution. CodeSandbox IDE itself has no MCP client.

---

## Zulip

**Developer:** Zulip
**Support:** ⚠️ Third-party MCP servers

Zulip has no official MCP webhook integration. Community options:
- `npx zulipmcp` - basic bot for @mention handling
- Vinkius hosted MCP - production-grade managed service with 9 tools
- Composio integration - framework-level for CrewAI/LangChain agents

All require creating a Zulip bot user and configuring `ZULIP_API_KEY`, `ZULIP_EMAIL`, `ZULIP_SITE` env vars.

---

## Lapce

**MCP Support:** ❌ No native support
Use Cursor or Zed instead for MCP support.

---

## Sublime Merge

**MCP Support:** ❌ No native support
Sublime Merge has no plugin API for MCP integration.

---

## MCP Server Examples

### GitHub (Recommended - Docker or Remote)

> **Note**: The old npm package `@modelcontextprotocol/server-github` is **deprecated** and no longer maintained. Use the official Go rewrite from GitHub.

Option 1: Remote (simplest, no local install):
```toml
# Codex example - works similarly in JSON configs
[mcp_servers.github]
url = "https://api.githubcopilot.com/mcp/"
bearer_token_env_var = "GITHUB_TOKEN"
```

Option 2: Docker:
```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${env:GITHUB_TOKEN}" }
    }
  }
}
```

---

## Troubleshooting

### Common Issues & Fixes

| Problem | Solution |
|---------|----------|
| **Server won't start / red indicator** | 1. Check JSON/TOML syntax carefully<br>2. Verify command is in PATH (GUI apps don't inherit shell PATH! Use absolute paths: run `which npx`/`which uvx` to get full path)<br>3. Test manually in terminal first<br>4. Check all required env vars are explicitly set in `env` block |
| **Changes not taking effect** | **Fully quit and restart the IDE/client** (not just close window). Some clients require a full process restart. Look for a "Refresh" button in MCP settings as a lighter alternative. |
| **stdout protocol errors / garbage output** | **#1 most common issue!** MCP servers must write logs to **stderr**, NOT stdout! Any non-JSON output on stdout breaks the protocol. Use `console.error()` (Node.js) or `print(..., file=sys.stderr, flush=True)` (Python). |
| **PATH not found in GUI app** | GUI apps on macOS/Windows don't read shell rc files. Use full absolute paths (e.g., `/usr/local/bin/npx` instead of `npx`, or `/home/user/.local/bin/uvx`). Find paths with `which npx` in terminal. |
| **Can't find MCP tools in chat** | Ensure you're in **Agent mode** (VS Code Copilot). Check MCP server list for connection status. Some servers take 5-10s to initialize. |
| **Timeout errors** | Increase timeout: add `timeout` field (milliseconds in some clients, seconds in others). Remote servers need higher timeouts. |
| **Project config not working** | Check if project config is enabled (Trae requires manual toggle). Verify project is trusted. Ensure file is in correct location relative to project root. |

### Debug Tools

**MCP Inspector** - official GUI debugger for any MCP server:
```bash
npx @modelcontextprotocol/inspector
# Open http://127.0.0.1:6274 in browser
# Test both stdio and HTTP servers, view message flow, test tool calls
```

### Log Locations

| Client | Log Path |
|--------|----------|
| Claude Desktop (macOS) | `~/Library/Logs/Claude/mcp-server-*.log` |
| Cursor | Output panel → MCP |
| Zed | Settings → AI → MCP Servers (tooltip on status indicator) |
| Most clients | Developer tools console or Output panel |

### Manual Testing

Test a stdio server directly in terminal:
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | uvx mcp-server-package
```

Test HTTP endpoint with curl:
```bash
curl -X POST https://example.com/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
```

---

## Security Best Practices

1. **Never hardcode secrets** - Always use environment variables: `"env": { "API_KEY": "${env:API_KEY}" }`
2. **Least privilege** - Grant only necessary scopes to API tokens
3. **Be careful with autoApprove** - Don't auto-approve tools with side effects (write, execute, send)
4. **Gitignore config files with secrets** - Global configs stay out of Git naturally; project configs should either not contain secrets or use env vars
5. **HTTP server security** - Remote MCP servers should require authentication; CORS/origin validation prevents DNS rebinding; bind local servers to 127.0.0.1 only
6. **Trust project configs** - Only enable project-level MCP in trusted repositories (similar to trusting devcontainer.json)

---

## Environment Variable Interpolation

Most clients support these variables in config values:

| Variable | Description |
|----------|-------------|
| `${env:VAR_NAME}` or `$VAR_NAME` | Environment variable |
| `${workspaceFolder}` | Current project root absolute path |
| `${userHome}` | User home directory |

---

## See Also

- [MCP Official Docs](https://modelcontextprotocol.io)
- [MCP Registry](https://registry.modelcontextprotocol.io) - Find public MCP servers
- [MCP Inspector](https://github.com/modelcontextprotocol/inspector) - Debugging tool
- [Publishing Skills](publishing.md)
- [IDE Migration Guide](ide-migration.md)
