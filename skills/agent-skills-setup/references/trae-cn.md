# Trae CN MCP Setup

Configure MCP servers in Trae CN.

## Config Paths

| 类型 | 路径 |
|------|------|
| **全局配置** | `~/.cursor/mcp.json` |
| **项目配置** | `.trae/mcp.json` |

## 与 Trae 的区别

| 特性 | Trae | Trae CN |
|------|------|---------|
| 语言 | English | 简体中文 |
| 默认模型 | Claude/GPT | Claude/通义/DeepSeek |
| 区域 | 全球 | 中国大陆 |
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
    },
    "filesystem": {
      "command": "uvx",
      "args": ["@modelcontextprotocol/server-filesystem", "/path/to/project"]
    }
  }
}
```

## Setup Steps

### 全局配置

```bash
mkdir -p ~ && nano ~/.cursor/mcp.json
```

### 项目配置

```bash
mkdir -p .trae && nano .trae/mcp.json
```

## UI 配置方式

1. 点击右上角 Settings 图标
2. 左侧导航选择 MCP
3. 添加/管理 MCP 服务器

## 内置模型 (Trae CN)

| 模型 | 来源 | 特点 |
|------|------|------|
| Claude 3.5 Sonnet | Anthropic | 强编码能力 |
| GPT-4o | OpenAI | 通用强大 |
| 通义千问 Qwen | 阿里云 | 中文优化 |
| DeepSeek Chat | DeepSeek | 高性价比 |
| Gemini Pro | Google | 多模态 |

## 与 antigravity 对比

| 特性 | Trae/Trae CN | antigravity |
|------|-------------|-------------|
| 开发商 | ByteDance | Google |
| 全局配置 | `~/.cursor/mcp.json` | `~/.gemini/antigravity/mcp_config.json` |
| 项目配置 | `.trae/mcp.json` | 不支持 |

## Troubleshooting

### MCP 服务器不启动

1. 检查 JSON 语法
2. 确保 `uvx` 已安装: `uv --version`
3. 手动测试: `uvx @modelcontextprotocol/server-github`

### 权限问题

```bash
chmod +x /path/to/mcp-server
```
