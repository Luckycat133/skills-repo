# Cursor AI 配置指南

触发条件：用户需要为 Cursor IDE 配置 AI 功能、MCP 服务或 skills

## Cursor 简介

Cursor 是由 Anysphere 开发的 AI-first 代码编辑器，基于 VS Code 打造，专注于 AI 辅助编程。

## 安装 Cursor

```bash
# macOS
brew install --cask cursor

# 或从官网下载
# https://cursor.sh
```

## MCP 配置

### 配置文件位置

| 操作系统 | 路径 |
|----------|------|
| macOS | `~/.cursor/mcp.json` |
| Linux | `~/.cursor/mcp.json` |
| Windows | `%USERPROFILE%\.cursor\mcp.json` |

### GitHub MCP Server

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_你的_token"
      }
    }
  }
}
```

### 验证 MCP 配置

1. 重启 Cursor
2. 打开设置 → MCP Servers
3. 确认 GitHub server 显示为绿色（connected）

## Cursor 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd+K` | 打开 AI 补全/编辑 |
| `Cmd+L` | 打开 AI 聊天 |
| `Tab` | 接受当前补全 |
| `Cmd+Enter` | 接受整个补全块 |
| `Esc` | 拒绝补全 |
| `Cmd+Shift+L` | 应用到所有相似位置 |

## Cursor 模式

### Normal Mode（普通模式）
- 标准编辑操作
- 使用快捷键触发 AI

### Insert Mode（插入模式）
- Inline 补全
- Tab 接受建议

### Agent Mode（代理模式）
- 自动化任务执行
- 多文件修改
- 代码重构

## 高级配置

### 自定义 Model

```json
// .cursor/mcp.json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_你的_token"
      }
    }
  }
}
```

### 使用 Claude API

1. Settings → Models
2. 选择 "Use custom model endpoint"
3. 配置：
   - Provider: Anthropic
   - API Key: 你的 Claude API Key
   - Base URL: `https://api.anthropic.com`

## 与 Skills 集成

Cursor 可以通过 MCP 使用 Hermes 的 skills：

```bash
# 启动 Hermes MCP Server
npx -y @anthropic/hermes-cli serve \
  --skills-repo Luckycat133/skills-repo \
  --port 8080
```

在 Cursor 的 MCP 配置中添加：
```json
{
  "mcpServers": {
    "hermes": {
      "command": "npx",
      "args": ["-y", "@anthropic/hermes-cli", "serve"],
      "env": {
        "SKILLS_REPO": "Luckycat133/skills-repo"
      }
    }
  }
}
```

## 常见问题

### Q: Cursor 和 VSCode 有什么区别？
A: Cursor 内置 AI 功能，开箱即用，不需要额外配置 Copilot。

### Q: 如何使用自己的 API Key？
A: Settings → Models → Add custom model

### Q: MCP 不工作怎么办？
A:
1. 确认 Node.js 已安装
2. 检查 token 是否正确
3. 重启 Cursor
4. 查看 MCP 日志

## 最佳实践

1. **上下文利用**：在修改文件时打开相关文件，获得更好上下文
2. **分步操作**：复杂的重构分多步完成
3. **代码审查**：AI 生成后手动检查
4. **快捷键熟练**：掌握 Cmd+K 和 Cmd+L 提高效率

## 相关链接

- [Cursor 官网](https://cursor.sh)
- [Cursor 文档](https://docs.cursor.sh)
- [MCP 协议](https://modelcontextprotocol.io)
