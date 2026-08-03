# 技能仓库

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: [English](README.md) · **中文** · [日本語](README.ja-JP.md) · [Español](README.es.md)

可在本地编写、从 GitHub 发布的可复用 AI 助手技能。

## 安装

```bash
# OpenClaw
openclaw skills install @luckycat133/agent-skills-setup

# skills.sh
npx skills add Luckycat133/skills-repo
```

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

在明确同意后，在受支持的 IDE 与智能体之间迁移选定上下文：已记录的 skills、规则、提示词与 MCP 对象。完整 IDE 配置和不透明项目树始终人工处理。44 个脚本支持标识符及仅人工处理的界面见 [IDE 注册表](skills/agent-skills-setup/references/ide-registry.md)。

## 开发

1. 编辑 `skills/agent-skills-setup/`，不要直接改生成的根 `SKILL.md`。
2. 运行 `bash validate-all.sh`。
3. 修改规范 Skill 后运行 `bash scripts/sync-root-mirror.sh`。
4. 验证通过后合并，再用 `bash install.sh` 或对应同步脚本安装。

除非明确传入 `--force`，现有目标不会被覆盖；该选项会先做带时间戳的备份。外部技能请在分支中用 `bash scripts/import-agent-skill.sh <source-dir> <skill-name>` 导入审查。

## 发布

GitHub 是规范来源；ClawHub、`skills.sh` 与 Awesome Copilot 是分发渠道。发布前运行验证、审阅 `THIRD_PARTY_NOTICES.md`，并清除私有路径、密钥和机器特定假设。

## 项目资料

- [贡献](CONTRIBUTING.md)
- [安全](SECURITY.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [许可证](LICENSE)
