# JetBrains AI 配置指南

触发条件：用户需要为 IntelliJ IDEA、PyCharm、WebStorm 等 JetBrains IDE 配置 AI 功能

## 安装 AI Assistant 插件

1. 打开 Settings/Preferences → Plugins
2. 搜索"AI Assistant"（由 JetBrains 开发）
3. 安装并重启 IDE

## API Key 配置

### 方法 1：使用 JetBrains Account
1. 登录 JetBrains Account
2. AI Assistant → Sign In
3. 获得免费 credits（每月有限）

### 方法 2：自选 Provider
1. Settings → Tools → AI Assistant → AI Services
2. 选择"Custom Model"
3. 配置 Anthropic API Key：
   - Provider: Anthropic
   - API Key: your_anthropic_api_key
   - Model: claude-3-5-sonnet-20241022

## MCP 支持（2024.2+）

JetBrains 2024.2 版本开始支持 MCP：

### 配置 MCP Server
在 `~/.jetbrains.mcp.json` 添加：

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your_github_token_here"
      }
    }
  }
}
```

### 启用 MCP
1. Settings → Tools → AI Assistant → Advanced
2. 勾选"Enable Model Context Protocol"
3. 重启 IDE

## JetBrains AI 功能

### 代码补全
- 实时 inline 补全
- Tab 接受建议
- 自动学习项目上下文

### AI Chat
- 项目级上下文理解
- 多文件分析
- 代码解释和重构建议

### AI Actions
- Generate Documentation
- Explain Code
- Refactor
- Write Tests
- Find Problems

## 快捷键

- `Shift+Shift`：快速搜索（包含 AI 功能）
- `Alt+Enter`：AI 辅助修复
- `Cmd+Shift+A`：查找动作（搜索 AI Actions）

## 注意事项

- 需要 JetBrains 账号或自配 API Key
- MCP 支持仍在发展中
- 不同 JetBrains 产品功能略有差异
- Team 版可能有额外的 AI 功能

## 相关链接

- JetBrains AI Assistant：https://www.jetbrains.com/ai/
- MCP 兼容性：检查具体版本
