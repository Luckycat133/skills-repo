# Gemini Code Assist 配置指南

触发条件：用户需要为 GCP/GKE 环境或本地配置 Google Gemini AI 编程助手

## GCP 环境配置

### Cloud Code 扩展
1. 安装 VSCode 或 JetBrains 的 Cloud Code 扩展
2. 登录 Google Cloud：`gcloud auth login`
3. 启用 Gemini API：
   ```bash
   gcloud services enable aiplatform.googleapis.com
   ```

### IDE 配置
VSCode：`~/.config/Code/User/settings.json`
```json
{
  "gemini-code-assist.apiKey": "your-gemini-api-key",
  "gemini-code-assist.language": "en-US"
}
```

## 本地使用 Gemini

### Gemini in Cloud Shell
1. 打开 Google Cloud Shell
2. 激活 Gemini：`gcloud alpha shell`
3. 自动使用项目凭证

### Vertex AI API
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
export GEMINI_API_KEY="your-api-key"
```

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
        "GITHUB_TOKEN": "your-github-token"
      }
    }
  }
}
```

## Gemini Code Assist 功能

### 代码生成
- 自然语言转代码
- 多语言支持（Python, Go, Java, Node.js 等）
- 模板和脚手架生成

### 代码解释
- 复杂代码分析
- 架构建议
- 性能优化建议

### 安全扫描
- 漏洞检测
- 最佳实践检查
- 合规性分析

## 集成场景

### Cloud Run 开发
```bash
# 使用 Gemini 辅助开发
gcloud alpha shell --gemini "帮我创建一个 Cloud Run 服务"
```

### GKE 调试
Gemini 可以分析日志、建议修复方案

### BigQuery 查询
自然语言转 SQL

## 限制和注意事项

- 需要 Google Cloud 项目
- 部分功能需要付费（超出免费配额）
- API 速率限制
- 地区可用性差异
- 不支持所有编程语言

## 相关链接

- Gemini API：https://ai.google.dev/
- Cloud Code：https://cloud.google.com/code/docs
- Vertex AI：https://cloud.google.com/vertex-ai
