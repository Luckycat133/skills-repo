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

在受支持的 IDE 与智能体之间按明确范围迁移选定上下文：已记录的 Skills、规则、提示词与 MCP 对象。完整 IDE 配置和不透明项目树始终人工处理。44 个脚本支持标识符及仅人工处理的界面见 [IDE 注册表](skills/agent-skills-setup/references/ide-registry.md)。

运行时包只包含参考资料和一个迁移命令；不会安装 IDE 或运行时、创建符号链接、维护注册表锁文件，也不会把自己复制进各个 Agent 目录。全局迁移默认只处理 Skills；项目对象使用命令中明确给出的 workspace。

## 开发

1. 编辑 `skills/agent-skills-setup/`，不要直接改生成的根 `SKILL.md`。
2. 运行 `bash validate-all.sh`。
3. 修改规范 Skill 后运行 `bash scripts/sync-root-mirror.sh`。
4. 验证通过后再合并。

外部技能请在分支中用 `bash scripts/import-agent-skill.sh <source-dir> <skill-name>` 导入审查。

## 发布

GitHub 是规范来源；ClawHub 与 Awesome Copilot 是分发渠道。发布前必须通过全量测试和安全扫描，推送并核验 GitHub 提交，再以 ClawHub dry run 确认发行包。详见[发布检查清单](docs/agent-skills-setup/release-checklist.md)。

## 项目资料

- [贡献](CONTRIBUTING.md)
- [安全](SECURITY.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [许可证](LICENSE)
