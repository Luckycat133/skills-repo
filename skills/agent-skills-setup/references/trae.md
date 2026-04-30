# Trae / Trae CN MCP Setup

Configure MCP servers in Trae IDE.

## Config Paths

| 类型 | 路径 |
|------|------|
| **全局配置** | `~/.cursor/mcp.json` |
| **项目配置** | `.trae/mcp.json` |

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

## Example: GitHub + Filesystem MCP

### 全局配置 (~/.cursor/mcp.json)

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
      "args": ["@modelcontextprotocol/server-filesystem", "/default/path"]
    }
  }
}
```

### 项目配置 (.trae/mcp.json)

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

## UI 配置方式

1. 点击右上角 Settings 图标
2. 左侧导航选择 MCP
3. 添加/管理 MCP 服务器

## Trae CN 特有

| 特性 | Trae | Trae CN |
|------|------|---------|
| 语言 | English | 简体中文 |
| 默认模型 | Claude/GPT | 通义/DeepSeek |
| 区域 | 全球 | 中国大陆 |
| MCP配置 | 相同 | 相同 |

## 内置模型 (Trae CN)

| 模型 | 来源 |
|------|------|
| Claude 3.5 Sonnet | Anthropic |
| GPT-4o | OpenAI |
| 通义千问 Qwen | 阿里云 |
| DeepSeek Chat | DeepSeek |

## 与 antigravity 对比

| 特性 | Trae | antigravity |
|------|------|-------------|
| 开发商 | ByteDance | Google |
| 全局配置 | `~/.cursor/mcp.json` | `~/.gemini/antigravity/mcp_config.json` |
| 项目配置 | `.trae/mcp.json` | 不支持 |

## 版本历史

- **v1.0**: 初始版本
- **v1.3.0**: Agent Mode + MCP 支持
