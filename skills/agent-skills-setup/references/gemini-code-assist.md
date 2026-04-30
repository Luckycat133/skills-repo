# Gemini Code Assist 配置指南

触发条件：用户需要为 GCP/GKE 环境或本地配置 Google Gemini AI 编程助手

## Gemini Code Assist 简介

Gemini Code Assist 是 Google Cloud 提供的 AI 编程助手，基于 Gemini 大模型，支持代码生成、补全、审查等功能。

## 产品版本

| 版本 | 描述 | 定价 |
|------|------|------|
| Gemini Code Assist（基础版） | Cloud Shell/Cloud Workstations | 免费 |
| Gemini Code Assist Enterprise | VSCode/JetBrains | GCP 账单 |
| Gemini in Duet AI | Google Workspace 集成 | 订阅制 |

## GCP 环境配置

### Cloud Shell

1. 打开 [Google Cloud Shell](https://shell.cloud.google.com)
2. Gemini 自动启用
3. 直接在终端使用

### Cloud Workstations

1. Cloud Console → Workstations
2. 创建工作站
3. Gemini 功能已预装

### Cloud Code 扩展（VSCode/JetBrains）

#### VSCode

1. 安装 Cloud Code 扩展
2. 登录 Google Cloud：`gcloud auth login`
3. 启用 Gemini API

#### JetBrains

1. 安装 Google Cloud Code 插件
2. 配置 GCP 凭据

### 启用 Gemini API

```bash
# 使用 gcloud CLI
gcloud services enable aiplatform.googleapis.com

# 设置项目
gcloud config set project YOUR_PROJECT_ID

# 验证
gcloud ai models list
```

## IDE 配置

### VSCode

`~/.config/Code/User/settings.json`：

```json
{
  "gemini-code-assist.apiKey": "your-gemini-api-key",
  "gemini-code-assist.language": "en-US",
  "gemini-code-assist.autocomplete": true,
  "gemini-code-assist.codeGeneration": true
}
```

### JetBrains

`Settings` → `Tools` → `Gemini`：

```json
{
  "apiKey": "your-gemini-api-key",
  "language": "en-US",
  "projectScope": "current"
}
```

## 本地使用 Gemini

### Vertex AI API

```bash
# 设置服务账号
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# 或使用 API Key
export GEMINI_API_KEY="your-api-key"

# 验证
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://aiplatform.googleapis.com/v1/predict
```

### AI Studio

1. 访问 [Google AI Studio](https://aistudio.google.com)
2. 获取 API Key
3. 在 IDE 中配置

## MCP 支持

### 配置 Gemini MCP Server

```json
{
  "mcpServers": {
    "gemini": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-gemini"],
      "env": {
        "GEMINI_API_KEY": "your-api-key"
      }
    },
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

### Gemini Function Calling

Gemini 支持 Function Calling，可以：
- 执行代码
- 查询数据库
- 调用 API

## Gemini Code Assist 功能

### 1. 代码生成

- 自然语言转代码
- 多语言支持（Python, Go, Java, Node.js, etc.）
- 模板和脚手架生成
- 注释转代码

### 2. 代码解释

- 复杂代码分析
- 架构建议
- 性能优化建议
- 文档生成

### 3. 安全扫描

- 漏洞检测
- 最佳实践检查
- 合规性分析
- Secret 泄露检测

### 4. 调试辅助

- 错误分析
- 修复建议
- 日志解释

## GCP 集成场景

### Cloud Run 开发

```bash
# 使用 Gemini 辅助开发
gcloud alpha shell --gemini "帮我创建一个 Cloud Run 服务，使用 Python FastAPI"

# 生成 Dockerfile
gcloud alpha code gen --prompt "创建一个生产级的 Cloud Run Dockerfile"
```

### GKE 调试

Gemini 可以：
- 分析 Pod 日志
- 解释 Kubernetes 错误
- 建议修复方案
- 生成 YAML 配置

### BigQuery

- 自然语言转 SQL
- 查询优化建议
- 数据模型解释

### Cloud Functions

```python
# Gemini 可以帮助你写 Cloud Functions
@genai.prompt
def generate_function(event, context):
    """创建 BigQuery 写入函数"""
    pass
```

### App Engine

- 应用配置建议
- 性能优化
- 迁移指导

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Tab` | 接受补全 |
| `Esc` | 拒绝补全 |
| `Cmd+Shift+Y` | 打开 Gemini Chat |
| `Alt+/` | 触发补全 |

## 定价（2024）

### 免费版

- Cloud Shell：免费
- 基础补全：免费（有配额限制）

### Enterprise 版

按使用量计费：
- 标准查询：$0.002/1K tokens
- 高级模型：$0.035/1K tokens

查看详细定价：https://cloud.google.com/monitoring/api/resources

## 与 Skills 集成

### 配置 Hermes

```json
{
  "mcpServers": {
    "gemini": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-gemini"],
      "env": {
        "GEMINI_API_KEY": "your-api-key"
      }
    },
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

## 常见问题

### Q: Gemini API 多少钱？
A: 有免费额度，超出后按量计费。基础版免费。

### Q: 中国能使用吗？
A: 需要网络访问，可能需要 VPN。Google Cloud 在中国有有限服务。

### Q: 与 Copilot 比较？
A: Gemini 与 GCP 集成更深，适合云原生开发。

### Q: 如何获取 API Key？
A:
1. Google AI Studio：https://aistudio.google.com
2. Vertex AI Console：https://console.cloud.google.com/vertex-ai

## 限制和注意事项

1. 需要 Google Cloud 项目
2. 部分功能需要付费（超出免费配额）
3. API 速率限制
4. 地区可用性差异
5. 不支持所有编程语言
6. 中国区访问受限

## 相关链接

- [Gemini API](https://ai.google.dev/)
- [Cloud Code](https://cloud.google.com/code/docs)
- [Vertex AI](https://cloud.google.com/vertex-ai)
- [Google AI Studio](https://aistudio.google.com)
- [定价](https://ai.google.dev/pricing)
