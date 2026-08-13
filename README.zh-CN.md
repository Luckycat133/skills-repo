# 技能仓库

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: [English](README.md) · **中文** · [日本語](README.ja-JP.md) · [Español](README.es.md)

可在本地编写、从 GitHub 发布的可复用 AI 助手技能。

## 使用方式

通过当前 Agent 自己的 Skill 管理功能或 ClawHub 安装 `agent-skills-setup`。仓库不再提供跨 Agent 安装器；安装只会让当前 Agent 获得参考资料和迁移脚本。
安装时不选择 IDE；`--source`、`--target`、`--objects` 和 `--workspace` 只属于 Agent 之后执行的迁移命令。

## 结构

```text
skills-repo/
├── docs/                         # 仍有效的维护文档
├── scripts/                      # 仓库级工具
└── skills/agent-skills-setup/    # 可发布技能的规范来源
    ├── SKILL.md
    ├── references/
    └── scripts/
```

## `agent-skills-setup`

在产品 profile 之间按明确范围迁移选定上下文。Registry v2 记录生命周期、版本、来源、作用域、存储和逐 surface 策略；legacy、cloud、provider、host-editor 与 alias 条目不会冒充普通写入目标。详见 [IDE 注册表](skills/agent-skills-setup/references/ide-registry.md)。

运行时包只包含参考资料和一个迁移命令；不会安装 IDE 或运行时、创建符号链接、维护注册表锁文件，也不会把自己复制进各个 Agent 目录。全局迁移默认只处理 Skills；项目对象使用命令中明确给出的 workspace。
复制 Skill 目录前会扫描全部源文本；发现疑似字面凭据或指向 Skill 外部的链接时，会在不修改源和已有目标的情况下跳过该 Skill。
规范 frontmatter 只使用 Agent Skills 标准字段。profile-aware CLI 提供 `detect`、`inventory`、`plan`、`apply`、`verify` 和 `rollback`；instructions 经产品原生格式 adapter 与类型化 IR 转换并输出 loss report。`apply` 只接受已保存且带校验和的 plan，会先暂存完整操作、创建精确备份，并在任一步失败时回滚此前全部写入；仅成功后生成带校验和的验证清单。当前经审查的自动子集标为 `partial` 而非 `full`；缺少目标 transport adapter 的远程 MCP、未实现专用 adapter 的格式与 cloud/UI 产品会输出明确的手动重建操作。

## 开发

1. 编辑 `skills/agent-skills-setup/`，不要直接改生成的根目录仓库指针。
2. 运行 `bash validate-all.sh`。
3. 修改规范 Skill 后运行 `bash scripts/sync-root-mirror.sh` 更新根指针。
4. 验证通过后再合并。

外部技能请在分支中用 `bash scripts/import-agent-skill.sh <source-dir> <skill-name>` 导入审查。

## 发布

GitHub 是规范来源；ClawHub 与 Awesome Copilot 是分发渠道。仓库保持 MIT；生成的 ClawHub bundle 单独使用 MIT-0、移除冲突的逐 Skill 许可证并声明 Bash/Python 依赖。只有确认历史贡献者授权并显式确认后才允许发布。详见[发布检查清单](docs/agent-skills-setup/release-checklist.md)。

## 项目资料

- [贡献](CONTRIBUTING.md)
- [安全](SECURITY.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [许可证](LICENSE)
