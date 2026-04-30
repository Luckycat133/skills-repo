# Continue 配置指南

触发条件：用户需要为 VSCode 或 JetBrains 配置开源 AI 编程助手 Continue

## 安装

### VSCode
1. 打开 VSCode Extensions
2. 搜索"Continue"
3. 安装"Continue - AI coding assistant"
4. 重启 VSCode

### JetBrains
1. Settings → Plugins → Marketplace
2. 搜索"Continue"
3. 安装并重启 IDE

## 配置

### 基础配置
1. 点击 Continue 图标
2. 选择 AI Provider：
   - OpenAI
   - Anthropic (Claude)
   - Azure OpenAI
   - Local ( Ollama, LM Studio)
   - Custom

### 使用 Claude API
```json
// ~/.continue/config.json
{
  "models": [
    {
      "title": "Claude",
      "provider": "anthropic",
      "model": "claude-3-5-sonnet-20241022",
      "api_key": "your-anthropic-api-key"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Claude",
    "provider": "anthropic",
    "model": "claude-3-5-haiku-20241022",
    "api_key": "your-anthropic-api-key"
  }
}
```

### 使用本地模型
```json
{
  "models": [
    {
      "title": "Local",
      "provider": "ollama",
      "model": "codellama"
    }
  ]
}
```

## MCP 支持

### 配置 MCP Servers
```json
// ~/.continue/config.json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your-github-token"
      }
    }
  }
}
```

### 常用 MCP Servers
- GitHub
- Filesystem
- Fetch (web content)
- Brave Search
- Slack

## Continue 功能

### Slash Commands
- `/edit`：编辑代码
- `/comment`：添加注释
- `/share`：分享对话
- `/config`：配置
- `/model`：切换模型

### 快捷操作
- 选中代码 + `/edit`：编辑选中部分
- 选中代码 + `/comment`：解释代码
- 选中代码 + `/test`：生成测试

### 多文件编辑
Continue 支持：
- 整个项目的上下文理解
- 跨文件修改
- 批量重构

## 自定义配置

### 快捷键
```json
{
  "customShortcuts": [
    {
      "prompt": "/edit",
      "shortcut": "cmd+shift+e"
    }
  ]
}
```

### 系统提示
```json
{
  "systemMessage": "你是一个专业的 Rust 开发者..."
}
```

### 语言特定配置
```json
{
  "language": "python",
  "completionShortcuts": ["tab"],
  "disableFuzzyMatch": false
}
```

## 与其他 IDE 的比较

| 功能 | Continue | Copilot | Claude Code |
|------|----------|---------|-------------|
| 开源 | ✅ | ❌ | ❌ |
| 本地模型 | ✅ | ❌ | ❌ |
| MCP 支持 | ✅ | 部分 | ✅ |
| 自定义 | 高 | 低 | 中 |
| 免费 | ✅ | 部分 | ❌ |

## 注意事项

- 需要配置 API Key（除本地模型外）
- MCP 支持程度因 server 而异
- 开源可自托管
- 配置灵活性高

## 相关链接

- Continue 官网：https://continue.dev
- GitHub：https://github.com/continuedev/continue
- 文档：https:// continue.dev/docs
