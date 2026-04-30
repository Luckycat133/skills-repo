# Trae CN MCP Setup

Configure MCP servers in Trae CN (字节跳动AI代码编辑器国际版).

## Config Path

`.trae/mcp.json` (project-level)

## 与 Trae 的区别

| 特性 | Trae | Trae CN |
|------|------|---------|
| 语言 | English | 简体中文 |
| 默认模型 | Claude/GPT | Claude/通义/DeepSeek |
| 区域 | 全球 | 中国大陆 |
| 模型来源 | OpenAI/Anthropic | OpenAI/阿里/DeepSeek |
| MCP配置 | 相同 | 相同 |

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

## Example: Complete GitHub + Filesystem MCP

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

1. Create `.trae` folder in project root:
```bash
mkdir -p .trae
```

2. Create MCP config:
```bash
nano .trae/mcp.json
```

3. Restart Trae CN

## 内置模型 (Trae CN)

| 模型 | 来源 | 特点 |
|------|------|------|
| Claude 3.5 Sonnet | Anthropic | 强编码能力 |
| GPT-4o | OpenAI | 通用强大 |
| 通义千问 Qwen | 阿里云 | 中文优化 |
| DeepSeek Chat | DeepSeek | 高性价比 |
| Gemini Pro | Google | 多模态 |

## Trae CN 特性

- 基于 IntelliJ 平台
- AI 驱动的代码补全
- 智能代码审查
- MCP 协议支持
- 内置终端
- Git 集成
- 多语言支持

## 版本历史

- **v1.0**: 初始版本
- **v1.3.0**: Agent Mode + 增强 MCP 支持

## Troubleshooting

### MCP 服务器不启动

1. 检查 JSON 语法
2. 确保 `uvx` 已安装: `uv --version`
3. 手动测试: `uvx @modelcontextprotocol/server-github`

### 权限问题

```bash
chmod +x /path/to/mcp-server
```
