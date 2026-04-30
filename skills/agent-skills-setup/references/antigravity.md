# antigravity MCP Setup

Configure MCP servers in Google Antigravity IDE.

## Config Path

`~/.gemini/antigravity/mcp_config.json`

## 简介

Google Antigravity 是 Google 推出的 AI 优先 IDE，基于 Gemini 大模型，支持 MCP 协议扩展。

## Config Format

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

## Example: GitHub MCP

```json
{
  "mcpServers": {
    "github": {
      "command": "uvx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token"
      }
    }
  }
}
```

## Setup Steps

1. Create config directory:
```bash
mkdir -p ~/.gemini/antigravity
```

2. Create MCP config:
```bash
nano ~/.gemini/antigravity/mcp_config.json
```

3. Restart Antigravity

## UI 配置方式

1. 点击 MCP Store 中的 "Manage MCP Servers"
2. 点击 "View raw config"
3. 修改 `mcp_config.json`

## antigravity 特性

| 特性 | 说明 |
|------|------|
| 开发商 | Google |
| 主模型 | Gemini 3.1 Pro |
| MCP 支持 | 完整支持 |
| Agent Mode | Agent Manager |
| 代码补全 | Tab autocomplete |
| 命令 | Natural language code commands |

## 与 Trae 的区别

| 特性 | antigravity | Trae |
|------|-------------|------|
| 开发商 | Google | ByteDance |
| 主模型 | Gemini | Claude/GPT |
| 全局配置 | `~/.gemini/antigravity/mcp_config.json` | `~/.cursor/mcp.json` |
| 项目配置 | 不支持 | `.trae/mcp.json` |

## Troubleshooting

### MCP 服务器不启动

1. 检查 JSON 语法: `cat ~/.gemini/antigravity/mcp_config.json | python -m json.tool`
2. 确保 uvx 已安装: `uvx --version`
3. 重启 Antigravity
