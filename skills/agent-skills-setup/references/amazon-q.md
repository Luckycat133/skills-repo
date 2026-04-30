# Amazon Q Developer 配置指南

触发条件：用户需要为 AWS 环境配置 AI 编程助手 Amazon Q

## Amazon Q 简介

Amazon Q Developer 是 AWS 提供的 AI 编程助手，支持代码生成、审查、调试等功能，与 AWS 服务深度集成。

## 产品版本

| 版本 | 描述 | 价格 |
|------|------|------|
| Amazon Q Free | 基础功能 | 免费 |
| Q Developer Pro | 高级功能、无限使用 | 订阅制 |
| Q Developer Business | 企业版 | 企业定价 |
| Q in AWS re:Post | 社区问答集成 | 免费 |

## 安装扩展

### VSCode

1. 打开 VSCode Extensions
2. 搜索 "Amazon Q"
3. 安装 "Amazon Q: AI Coding Assistant"
4. 重启 VSCode

### JetBrains

1. `Settings` → `Plugins` → `Marketplace`
2. 搜索 "Amazon Q"
3. 安装 "Amazon Q Developer for JetBrains IDEs"
4. 重启 IDE

### 关联产品

- AWS Toolkit for Visual Studio
- AWS Cloud9
- Amazon SageMaker Studio

## 认证配置

### AWS IAM Identity Center（推荐）

```bash
# 使用 AWS CLI 登录
aws sso login --profile default

# 或使用 SSO
aws configure sso
```

### IDE 内登录

1. 点击 Amazon Q 图标（侧边栏）
2. 选择 "Sign in with AWS IAM Identity Center"
3. 浏览器打开授权页面
4. 完成 SSO 认证

### 手动配置

如果 CLI 不可用：

1. AWS Console → IAM Identity Center
2. 创建应用程序客户端
3. 获取 client_id 和 client_secret
4. 在 IDE 中手动输入

## MCP 支持

### 配置 Amazon Q MCP Server

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

### Q Developer MCP（实验性）

```json
{
  "mcpServers": {
    "amazon-q": {
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

### 1. 代码生成（Dev）

使用 `/dev` 启动开发任务：

```
/dev 创建 一个 Python Lambda 函数处理 S3 上传事件
```

功能：
- 自然语言转代码
- 完整的文件生成
- 依赖处理
- 测试用例生成

### 2. 代码审查（Review）

使用 `/review` 启动审查：

```
/review 检查这段代码的安全漏洞
```

功能：
- 安全漏洞检测
- 最佳实践检查
- 性能问题
- 代码质量评估

### 3. 代码解释（Explain）

使用 `/explain` 解释代码：

```
/explain 这段代码做了什么
```

### 4. 其他命令

| 命令 | 功能 |
|------|------|
| `/fix` | 修复错误 |
| `/test` | 生成测试 |
| `/refactor` | 重构代码 |
| `/optimize` | 优化性能 |
| `/document` | 生成文档 |

## AWS 集成功能

### CDK 支持

```bash
# Q 可以帮助你编写 CDK 代码
Q: 帮我创建一个 S3 + CloudFront + ACM 的 CDK 堆栈
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

自然语言生成 SAM 模板：

```
Q: 创建一个 API Gateway + Lambda 的 SAM 模板
```

### ECS/Docker

- 容器化建议
- Dockerfile 生成
- docker-compose 配置

### CloudFormation

- 模板生成
- 资源优化建议

## 安全扫描

Amazon Q 可以：

1. **漏洞检测**
   - SQL 注入
   - XSS
   - 认证问题
   - 敏感信息泄露

2. **IAM 检查**
   - 最小权限原则
   - 风险策略识别
   - 建议修复

3. **Secret 检测**
   - API Key 识别
   - 密码硬编码警告
   - 环境变量建议

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd+Shift+A` | 打开 Q Chat |
| `Tab` | 接受补全 |
| `Esc` | 拒绝补全 |
| `Cmd+Shift+.` | 触发内联补全 |

## 免费版 vs 专业版

### 免费版限制

- 每月 50 条消息
- 基础代码补全
- 简单问答

### 专业版功能

- 无限消息
- 高级安全扫描
- 自定义规则
- 团队协作
- 优先支持

## 定价

| 计划 | 价格 | 用户 |
|------|------|------|
| Free | $0 | 个人开发者 |
| Pro | $19/人/月 | 专业开发者 |
| Business | 询价 | 企业团队 |

## 与 Skills 集成

### 配置 GitHub MCP

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

### 配置 Hermes Skills

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

### Q: 为什么提示需要 AWS 账号？
A: Amazon Q 需要 AWS 账号进行身份认证，可以使用免费账号。

### Q: 免费版和专业版区别？
A: 免费版每月限 50 条消息，专业版无限使用且有高级功能。

### Q: 数据隐私？
A: AWS 承诺不会用您的代码训练模型，数据处理可能在境外。

### Q: MCP 不工作？
A:
1. 确认 AWS CLI 已配置
2. 检查 SSO 会话是否过期
3. 重启 IDE
4. 查看 Q 日志

## 注意事项

1. 需要 AWS 账号
2. 部分功能需要专业版订阅
3. 某些功能仅限 AWS 环境
4. 数据处理可能在境外
5. 中国区可能需要 VPN

## 相关链接

- [Amazon Q Developer](https://aws.amazon.com/q/developer/)
- [AWS Toolkit](https://aws.amazon.com/visualstudio-coding/)
- [文档](https://docs.aws.amazon.com/amazonq/)
- [定价](https://aws.amazon.com/q/pricing/)
