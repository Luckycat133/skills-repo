# Cloud IDEs MCP Setup

Configure MCP servers in cloud-based development environments.

## GitHub Codespaces

**Path:** `.devcontainer.json`

### Config Format

```json
{
  "features": {
    "ghcr.io/microsoft/vscode/devcontainers/features/mcp": {}
  },
  "postCreateCommand": "uvx @modelcontextprotocol/server-github --token ${GH_TOKEN}"
}
```

### Alternative: devcontainer.json

```json
{
  "image": "mcr.microsoft.com/devcontainers/universal:2",
  "features": {
    "ghcr.io/devcontainers/features/mcp": {
      "version": "1.0"
    }
  }
}
```

### Environment Variable

Set `GH_TOKEN` in Codespaces Secrets.

---

## StackBlitz

**Support:** Partial (via WebContainer extension)

### Using Extension

1. Install MCP extension for StackBlitz
2. Configure via extension settings

### Limitations

- WebContainer-based (no full Docker)
- Some MCP servers require native binaries

---

## Gitpod

**Path:** `.gitpod.yml`

### Config Format

```yaml
image:
  file: .gitpod.Dockerfile

tasks:
  - name: MCP Server
    init: |
      npm install -g @modelcontextprotocol/server-github
      export GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_TOKEN}

ports:
  - port: 3000
    onOpen: open-browser
```

### Alternative: .gitpod/full.md

```yaml
tasks:
  - command: uvx @modelcontextprotocol/server-github
```

---

## Replit

**Configuration:** Via Secrets panel

### Setup

1. Go to Secrets (Environment Variables)
2. Add `GITHUB_TOKEN` with your GitHub PAT
3. Install MCP server in .replit or via shell

### .replit config

```python
run = "uvx @modelcontextprotocol/server-github"
env = { "GITHUB_PERSONAL_ACCESS_TOKEN": "{{GITHUB_TOKEN}}" }
```

---

## CodeSandbox

**Support:** Partial (via extension)

### Using Extension

1. Install MCP extension
2. Configure in extension settings

### Limitations

- Browser-based sandbox
- Limited native binary support

---

## Cloud9 (AWS)

**Path:** `.cloud9/mcp.json`

### Config Format

```json
{
  "mcpServers": {
    "server-name": {
      "command": "uvx",
      "args": ["mcp-server-package"]
    }
  }
}
```

---

## Glitch

**Configuration:** Via .env and remix.config

### Setup

1. Add secrets in Glitch project
2. Configure MCP server in terminal

---

## Compare Cloud IDEs

| IDE | MCP 支持 | 限制 | 适用场景 |
|-----|---------|------|----------|
| Codespaces | Full | 需要Docker | 生产开发 |
| Gitpod | Full | 配置复杂 | 团队协作 |
| Replit | Full | 付费特性 | 学习/原型 |
| StackBlitz | Partial | WebContainer | 前端项目 |
| CodeSandbox | Partial | 浏览器限制 | 前端分享 |
| Cloud9 | Full | AWS绑定 | AWS项目 |

## Security Notes

- Never commit tokens to version control
- Use environment variables / secrets
- Cloud IDEs provide secure secret storage
- Rotate tokens regularly
