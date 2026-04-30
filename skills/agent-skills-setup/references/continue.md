# Continue 配置指南

触发条件：用户需要为 VSCode 或 JetBrains 配置开源 AI 编程助手 Continue

## Continue 简介

Continue 是一个开源的 AI 代码助手，支持 VSCode 和 JetBrains，主打高度可定制和本地模型支持。

## 安装

### VSCode

1. 打开 VSCode Extensions
2. 搜索 "Continue"
3. 安装 "Continue - AI coding assistant"
4. 重启 VSCode

### JetBrains

1. `Settings` → `Plugins` → `Marketplace`
2. 搜索 "Continue"
3. 安装并重启 IDE

## 配置 API Key

### 使用 Claude API（推荐）

1. 点击 Continue 图标（或 `Cmd+L`）
2. 点击右上角设置图标
3. 选择 "Configure Models"
4. 添加配置：

```json
{
  "models": [
    {
      "title": "Claude",
      "provider": "anthropic",
      "model": "claude-3-5-sonnet-20241022",
      "api_key": "sk-ant-你的_key"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Claude Haiku",
    "provider": "anthropic",
    "model": "claude-3-5-haiku-20241022",
    "api_key": "sk-ant-你的_key"
  }
}
```

### 使用本地模型（Ollama）

```json
{
  "models": [
    {
      "title": "Local Llama",
      "provider": "ollama",
      "model": "llama3"
    }
  ]
}
```

### 使用 OpenAI

```json
{
  "models": [
    {
      "title": "GPT-4",
      "provider": "openai",
      "model": "gpt-4",
      "api_key": "sk-你的_key"
    }
  ]
}
```

## MCP 配置

### 配置文件

`~/.continue/config.json`（用户级）或项目根目录 `.continue/config.json`（项目级）

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

### 常用 MCP Servers

| Server | 功能 |
|---------|------|
| `github` | GitHub 操作 |
| `filesystem` | 文件系统访问 |
| `fetch` | 获取网页内容 |
| `brave-search` | 网页搜索 |
| `slack` | Slack 集成 |

### 自定义 MCP Server

```json
{
  "mcpServers": {
    "custom": {
      "command": "npx",
      "args": ["-y", "@custom/mcp-server"],
      "env": {
        "API_KEY": "your_key"
      }
    }
  }
}
```

## 功能详解

### Slash Commands

| 命令 | 功能 |
|------|------|
| `/edit` | 编辑选中的代码 |
| `/comment` | 添加注释解释代码 |
| `/share` | 分享当前对话 |
| `/config` | 打开配置 |
| `/model` | 切换模型 |
| `/clear` | 清空对话 |
| `/test` | 生成测试 |

### 快捷操作

- **选中代码 + `/edit`**：编辑选中部分
- **选中代码 + `/comment`**：解释代码
- **选中代码 + `/test`**：生成测试用例
- **选中代码 + `/refactor`**：重构代码

### 多文件编辑

Continue 支持：
- 整个项目的上下文理解
- 跨文件修改
- 批量重构
- 代码生成

### 代码补全

- Inline 补全（类似 Copilot）
- Tab 接受
- 语法预测
- 注释转代码

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd+L` | 打开聊天 |
| `Cmd+K` | 编辑当前文件 |
| `Tab` | 接受补全 |
| `Cmd+Shift+R` | 拒绝补全 |
| `Cmd+Shift+E` | 快速编辑 |
| `Esc` | 取消操作 |

## 高级配置

### 自定义快捷键

```json
{
  "customShortcuts": [
    {
      "prompt": "/edit",
      "shortcut": "cmd+shift+e"
    },
    {
      "prompt": "/comment",
      "shortcut": "cmd+shift+c"
    }
  ]
}
```

### 系统提示

```json
{
  "systemMessage": "你是一个专业的 {LANGUAGE} 开发者，熟悉最佳实践..."
}
```

### 语言特定配置

```json
{
  "language": "python",
  "completionShortcuts": ["tab"],
  "disableFuzzyMatch": false,
  "maxTokens": 2048
}
```

### 自动完成设置

```json
{
  "tabAutocompleteOptions": {
    "disable": false,
    "languageBoundary": {
      "blacklist": ["plaintext", "md"]
    }
  }
}
```

## 与 Skills 集成

### 配置 Hermes

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_你的_token"
      }
    },
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

## 部署选项

### 云端使用

- 官方在线版本
- 无需本地配置
- 使用官方 API Key

### 本地部署

```bash
# 使用 Ollama
ollama serve

# 配置 Continue 使用 Ollama
{
  "models": [{
    "provider": "ollama",
    "model": "codellama"
  }]
}
```

### 自托管

```bash
# 克隆 Continue
git clone https://github.com/continuedev/continue

# 本地运行
cd continue
npm install
npm run dev
```

## 与其他 IDE 的比较

| 特性 | Continue | Copilot | Claude Code |
|------|----------|---------|------------|
| 开源 | ✅ | ❌ | ❌ |
| 本地模型 | ✅ | ❌ | ❌ |
| MCP 支持 | ✅ | 部分 | ✅ |
| 自定义程度 | 高 | 低 | 中 |
| 价格 | 免费 | 部分免费 | 付费 |

## 常见问题

### Q: Continue 和 Copilot 哪个好？
A: Continue 更开源、可定制；Copilot 与 IDE 集成更深。

### Q: 如何使用本地模型？
A: 安装 Ollama，配置 provider 为 "ollama"。

### Q: MCP 不工作？
A:
1. 确认 Node.js 已安装
2. 检查配置文件格式
3. 查看 VSCode Output 面板的 Continue 日志

## 相关链接

- [Continue 官网](https://continue.dev)
- [GitHub](https://github.com/continuedev/continue)
- [文档](https://docs.continue.dev)
- [Discord](https://discord.gg/vpeqG85B)
