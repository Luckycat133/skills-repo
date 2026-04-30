# JetBrains AI 配置指南

触发条件：用户需要为 IntelliJ IDEA、PyCharm、WebStorm 等 JetBrains IDE 配置 AI 功能

## 支持的产品

- IntelliJ IDEA Ultimate
- PyCharm Professional
- WebStorm
- PhpStorm
- RubyMine
- GoLand
- DataGrip
- Rider
- CLion

## 安装 AI Assistant 插件

### 步骤 1：打开插件市场

1. `Settings/Preferences` → `Plugins`
2. 点击 `Marketplace` 标签
3. 搜索 "AI Assistant"

### 步骤 2：安装插件

1. 找到 "AI Assistant"（由 JetBrains 开发）
2. 点击 `Install`
3. 重启 IDE

## API Key 配置

### 方法 1：使用 JetBrains 账号（默认）

1. `Settings` → `Tools` → `AI Assistant`
2. 点击 `Sign In`
3. 使用 JetBrains 账号登录
4. 获得免费 credits（每月有限）

### 方法 2：自选 Provider（推荐）

当免费 credits 用完或需要更强大模型时：

1. `Settings` → `Tools` → `AI Assistant` → `AI Services`
2. 选择 "Custom LLM Provider"
3. 配置 Anthropic：

| 配置项 | 值 |
|--------|-----|
| Provider | `Anthropic` |
| API Key | `sk-ant-你的_key` |
| Model | `claude-3-5-sonnet-20241022` |

### 方法 3：Azure OpenAI

```
Provider: Azure OpenAI
Endpoint: https://your-resource.openai.azure.com
API Key: 你的_key
Deployment: gpt-4
```

## MCP 支持（2024.2+）

JetBrains 2024.2 版本开始支持 MCP 协议：

### 配置 MCP Server

在项目根目录创建 `.jetbrains.mcp.json`：

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

### 启用 MCP

1. `Settings` → `Tools` → `AI Assistant` → `Advanced`
2. 勾选 "Enable Model Context Protocol"
3. 重启 IDE

## JetBrains AI 功能

### 1. 代码补全（Code Completion）

- 实时 inline 补全
- Tab 接受建议
- 自动学习项目上下文
- 支持多种语言

### 2. AI Chat

- 项目级上下文理解
- 多文件分析
- 代码解释和重构建议
- 对话历史保存

### 3. AI Actions

| Action | 功能 |
|--------|------|
| `Generate Documentation` | 生成文档注释 |
| `Explain Code` | 解释选中代码 |
| `Refactor` | 重构建议 |
| `Write Tests` | 生成测试用例 |
| `Find Problems` | 查找问题 |
| `Optimize` | 代码优化 |

### 4. 意图操作（Intention Actions）

在代码上按 `Alt+Enter` 显示 AI 辅助选项：
- AI 解释错误
- AI 生成修复
- AI 优化代码

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Shift+Shift` | Quick Search（含 AI） |
| `Alt+Enter` | AI 辅助修复 |
| `Cmd+Shift+A` | Find Action |
| `Cmd+/` | AI 注释 |
| `F2` | 下一个问题（AI 检测） |

## 与 Skills 集成

### 方式 1：Hermes MCP Server

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

### 方式 2：直接使用 GitHub API

通过 AI Assistant 的自定义 endpoint 配置：
```
Base URL: https://api.github.com
Token: ghp_你的_token
```

## 团队使用

### 团队共享配置

1. 在项目根目录创建 `.idea/ai-config.xml`
2. 团队成员克隆项目后自动继承配置

### 许可证

- AI Assistant 是付费功能
- 需要有效的 JetBrains 订阅
- 或使用自定义 LLM Provider（需要自己付费）

## 常见问题

### Q: 为什么我的 AI Assistant 是灰色的？
A: 可能需要登录 JetBrains 账号或订阅已过期。

### Q: 如何关闭 AI 自动补全？
A: `Settings` → `Editor` → `General` → `Code Completion` → 关闭 AI。

### Q: MCP 连接失败？
A:
1. 确认 Node.js 已安装
2. 检查 token 是否有效
3. 尝试更新插件到最新版本
4. 查看 `.idea/log/` 中的错误日志

## 注意事项

1. 需要 JetBrains 账号或自配 API Key
2. MCP 支持仍在发展中（部分功能）
3. 不同 JetBrains 产品功能略有差异
4. Team 版可能有额外的 AI 功能
5. 中国区可能需要配置网络代理

## 相关链接

- [JetBrains AI Assistant](https://www.jetbrains.com/ai/)
- [AI Assistant 文档](https://www.jetbrains.com/help/idea/ai-assistant.html)
- [MCP 兼容性列表](https://modelcontextprotocol.io/implementations)
