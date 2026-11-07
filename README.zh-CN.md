# Agent Skills Setup

**帮助现有 Agent 迁移上下文的 Skill，不是另一个迁移软件。**

Agent 使用自己已有的读写、编辑、diff 和查资料能力，识别源与目标的真实格式，
保留作用域、触发条件、权限边界，完成迁移并报告验证结果。用户不需要学习另一套 CLI。

## 使用

只把 `skills/agent-skills-setup/` 安装到客户端官方支持的 Skill 目录；不要安装仓库根目录，
也不要把开发 Skill 一起安装。用户包不要求 Bash、Python、签名依赖或后台服务。

直接对 Agent 说：

> 把当前项目 Cursor 的规则和 Skills 迁到 Claude Code，保留原来的文件作用域。

> 把这些 MCP 配置迁到 Codex，保留目标已有设置，不复制密钥。

> 我要换电脑，把我选定工具的上下文整理成普通文件夹和迁移说明。

> 在新电脑恢复这个文件夹，按实际工具配置，告诉我哪些语义不能保留。

覆盖指导包括 Skills、Rules/Instructions、MCP、Prompts、Commands、Agents、Hooks、
Workflows、Plugins 和用户手写 Memory。不是将脚本不认识的类型一律丢弃。
可执行内容先作为非加载目录里的草稿；凭据、授权状态、原始聊天和数据库不整库复制。

## 当前状态

这是未发布的 `0.11.0-dev` 收缩版本。旧 CLI、ACB、签名和自动执行引擎已退出工作树和
用户发布目录，完整旧实现仍在 Git 历史中；用户已有文件与旧备份不会被自动删除。
旧版市场安装没有被此次修改自动更新，也没有承诺全部 IDE 实机验证。

## 开发

`bash validate-all.sh` 检查包边界、引用和示例；不冒充真实 Agent/IDE 行为测试。
后续开发必须先读 [开发 Skill](dev/skills/maintain-agent-skills-setup/SKILL.md)。
未完成任务有具体证据和验收标准，不再通过继续造平台来填补迁移质量问题。

[English](README.md) · [贡献](CONTRIBUTING.md) · [安全](SECURITY.md)

觉得有用可以 Star 或自愿支持；使用不要求收藏、支付或注册外部服务。
