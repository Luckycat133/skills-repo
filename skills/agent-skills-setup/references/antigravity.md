# antigravity MCP Setup

Configure MCP servers in Google Antigravity IDE.

## Config Path

`.antigravity/mcp.json`

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
mkdir -p .antigravity
```

2. Create MCP config:
```bash
nano .antigravity/mcp.json
```

3. Restart Antigravity

## antigravity 特性

| 特性 | 说明 |
|------|------|
| 开发商 | Google |
| 主模型 | Gemini 3.1 Pro |
| MCP 支持 | 完整支持 |
| Agent Mode | Agent Manager |
| 代码补全 | Tab autocomplete |
| 命令 | Natural language code commands |

## 内置模型

| 模型 | 来源 | 适用场景 |
|------|------|----------|
| Gemini 3.1 Pro | Google | 主模型 |
| Claude | Anthropic | 备选 |
| GPT-4 | OpenAI | 备选 |

## 与 Trae 的区别

| 特性 | antigravity | Trae |
|------|-------------|------|
| 开发商 | **Google** | 字节跳动 |
| 主模型 | Gemini | Claude/GPT |
| 平台 | Google | Electron |
| Agent | Agent Manager | 内置 |

## Troubleshooting

### MCP 服务器不启动

1. 检查 JSON 语法: `cat .antigravity/mcp.json | python -m json.tool`
2. 确保 uvx 已安装: `uvx --version`
3. 手动测试命令

### 连接超时

增加 timeout 配置:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "uvx",
      "args": ["mcp-server-package"],
      "timeout": 60
    }
  }
}
```
