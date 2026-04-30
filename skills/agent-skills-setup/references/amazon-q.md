# Amazon Q Developer 配置指南

触发条件：用户需要为 AWS 环境配置 AI 编程助手

## IDE 扩展安装

### VSCode
1. 打开 VSCode Extensions
2. 搜索"Amazon Q"
3. 安装"Amazon Q Developer"
4. 安装"Amazon Q Developer for JetBrains"（如使用 IDE）

### JetBrains
1. Settings → Plugins → Marketplace
2. 搜索"Amazon Q"
3. 安装并重启

## 认证配置

### AWS IAM Identity Center
```bash
# 安装 AWS CLI
aws sso login --profile default

# 或使用 SSO
aws configure sso
```

### IDE 登录
1. 点击 Amazon Q 图标
2. 选择"Sign in with AWS IAM Identity Center"
3. 完成 SSO 认证流程

## MCP 支持

### 配置 Amazon Q MCP Server
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your-github-token"
      }
    },
    "aws-q": {
      "command": "amazon-q",
      "args": ["--mcp"],
      "env": {
        "AWS_PROFILE": "default"
      }
    }
  }
}
```

## Amazon Q 功能

### Q Developer（专业版）
- 无限代码生成
- 安全扫描
- 代码修复
- 架构优化建议

### Q Developer（免费版）
- 每月有限 tokens
- 基础代码补全
- 简单问答

### Q Chat
- `/dev` 命令：代码转换和实现
- `/review` 命令：代码审查
- `/explain` 命令：代码解释
- AWS 知识集成

## AWS 集成功能

### CDK 支持
```bash
# Q 可以帮助你编写 CDK 代码
q chat "创建一个 S3 + CloudFront 的 CDK 堆栈"
```

### Lambda 开发
```python
# Q 可以帮助你写 Lambda 函数
@q.dev
def handler(event, context):
    # Q 会自动生成处理逻辑
    pass
```

### SAM 模板
自然语言生成 SAM 模板

### ECS/Docker
容器化建议和 Dockerfile 生成

## 快捷键

- `Cmd+Shift+A`：打开 Q Chat
- `Tab`：接受补全
- `Esc`：拒绝补全

## 安全扫描

Amazon Q 可以：
- 扫描代码漏洞
- 检查依赖安全问题
- 建议 IAM 权限最小化
- 检测 Secret 泄露

## 注意事项

- 需要 AWS 账号
- 专业版需要订阅
- 某些功能仅限 AWS 环境
- 数据处理可能在境外

## 相关链接

- Amazon Q：https://aws.amazon.com/q/developer/
- AWS Toolkit：https://aws.amazon.com/visual-studio-coding/
