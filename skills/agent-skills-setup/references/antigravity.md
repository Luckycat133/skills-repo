# antigravity MCP Setup

Configure MCP servers in antigravity (字节跳动AI代码编辑器).

## Config Path

`.antigravity/mcp.json`

## 简介

antigravity 是字节跳动推出的 AI 代码编辑器，基于 IntelliJ 平台开发，深度集成豆包大模型，支持 MCP 协议扩展。

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
    },
    "filesystem": {
      "command": "uvx",
      "args": ["@modelcontextprotocol/server-filesystem", "/path/to/project"]
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

3. Restart antigravity

## antigravity 特性

| 特性 | 说明 |
|------|------|
| 平台 | 基于 IntelliJ |
| AI 模型 | 豆包大模型 + Claude/GPT |
| MCP 支持 | 完整支持 |
| 代码补全 | 智能上下文感知 |
| 代码审查 | AI 驱动 |
| 多语言 | 中英双语 |

## 内置模型

| 模型 | 来源 | 适用场景 |
|------|------|----------|
| 豆包 | 字节跳动 | 日常编码 |
| Claude | Anthropic | 复杂任务 |
| GPT-4 | OpenAI | 通用任务 |
| 通义 | 阿里云 | 中文场景 |
| DeepSeek | DeepSeek | 高性价比 |

## 与 Trae/Trae CN 的区别

| 特性 | antigravity | Trae | Trae CN |
|------|-------------|------|---------|
| 开发商 | 字节跳动 | 字节跳动 | 字节跳动 |
| 平台 | IntelliJ | Electron | Electron |
| 主模型 | 豆包 | Claude/GPT | 通义/DeepSeek |
| 定位 | 专业IDE | AI协作 | 中国市场 |

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
