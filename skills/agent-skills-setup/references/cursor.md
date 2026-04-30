# Cursor AI 配置指南

触发条件：用户需要为 Cursor IDE 配置 AI 功能或 MCP 服务

## MCP 配置

在 Cursor 设置中添加 MCP Server，配置文件路径：`~/.cursor/mcp.json`（macOS）或 `%USERPROFILE%\.cursor\mcp.json`（Windows）

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

## Cursor 特有功能

### Cmd+K / Cmd+L
- Cmd+K：编辑器内补全
- Cmd+L：聊天模式（类似 Copilot Chat）

### 快捷键
- `Cmd+K`：打开补全
- `Cmd+L`：打开聊天
- `Tab`：接受补全建议
- `Cmd+Enter`：接受整个补全块

### MCP 工具支持
Cursor 对 MCP 工具有良好支持，可以：
- 浏览文件系统
- 执行终端命令
- 使用 skill 工具

## 验证步骤

1. 重启 Cursor
2. 打开 Cmd+L 聊天
3. 测试 GitHub 操作（如查看 issues）
4. 确认 skill 工具可用

## 注意事项

- Cursor 使用自己的 AI 模型（默认）
- 如需使用 Claude API，需在设置中配置 API Key
- MCP 支持与 VSCode 基本兼容
- Cursor 的"混合模型"功能可同时使用多个 AI 提供商

## 相关链接

- Cursor 官网：https://cursor.sh
- MCP 文档：https://modelcontextprotocol.io
