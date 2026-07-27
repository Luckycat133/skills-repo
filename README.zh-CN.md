# 技能仓库

> 状态：积极开发中 · 规范技能来源

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/openclaw.md)

> 🌐 Languages: [English](README.md) · **中文** · [日本語](README.ja-JP.md) · [Español](README.es.md)

AI 助手能力（原 skills）采用本地优先的创作工作流，并提供通往公开发布的实用路径。

## 安装

将 `agent-skills-setup` 技能安装到你的智能体环境中：

**ClawHub（OpenClaw 原生）**

```bash
openclaw skills install @luckycat133/agent-skills-setup
```

**skills.sh（跨智能体，Vercel）**

```bash
npx skills add Luckycat133/skills-repo
```

源仓库：[Luckycat133/skills-repo](https://github.com/Luckycat133/skills-repo)

## 目录

- [快速摘要](#快速摘要)
- [安装](#安装)
- [结构](#结构)
- [约定](#约定)
- [当前能力模块](#当前能力模块)
- [开发工作流](#开发工作流)
- [导入技能](#导入技能)
- [开源元数据](#开源元数据)
- [发布](#发布)

## 快速摘要

| 语言 | 摘要 |
| --- | --- |
| 中文 | 采用本地优先的工作流构建并发布可复用的智能体技能，支持 OpenClaw 自动化与公开发布指南。 |

## 结构

```text
skills-repo/
├── README.md
├── docs/
│   └── agent-skills-setup/
├── scripts/
└── skills/
    └── agent-skills-setup/
```

## 约定

- `skills/` 存放可发布的技能文件夹。
- `docs/` 存放开发笔记、发布计划、验证记录与维护清单。
- GitHub 的 `main` 分支是规范的唯一可信来源；请勿编辑已安装的副本。
- 特定产品的技能应保留在其规范的对应产品仓库中。

## 当前能力模块

- `agent-skills-setup`：多智能体能力安装、同步、OpenClaw 自动化与发布工作流。

跨 IDE 迁移范围现已涵盖能力、提示词、配置、规则与工作流。

现已覆盖的主流 IDE 生态包含 40 个 IDE 与智能体（Copilot, Cursor, Windsurf, JetBrains, Claude Code, Claude Desktop, Codex, OpenClaw, Trae, Trae CN, Antigravity, Kimi AI, Amazon Q, Gemini CLI, Zed, VS Code, Goose CLI, OpenCode, Continue, Roo Code, Cline, Kilo Code, Kiro, Augment Code, Baidu Comate, Tencent CodeBuddy, ZCode, Void Editor, Aider, Tabnine, Replit, Blackbox, Neovim, Emacs, Cody, Supermaven, Codeium, PearAI, Pieces）。

## 开发工作流

1. 在 GitHub 分支下编辑 `skills/` 中的技能。
2. 运行 `bash validate-all.sh`。
3. 针对 `agent-skills-setup` 的改动，还需运行聚焦的验证套件：
   - `bash skills/agent-skills-setup/scripts/verify-ide-config.sh` — 断言已解析的 IDE 路径与 `references/ide-registry.md` 一致（215 项检查）。
   - `bash skills/agent-skills-setup/scripts/test-ide-paths.sh` — `references/ide-paths.json` 与脚本之间的漂移测试（415 项检查）。
   - `bash skills/agent-skills-setup/scripts/test-migration.sh` — 迁移 + 全局同步引擎测试（80 项检查，隔离的临时 HOME）。
4. 仅在验证工作流通过后合并。
5. 将合并后的版本安装到智能体环境中：

```bash
bash install.sh
bash sync-to-codex.sh
bash sync-to-openclaw.sh
```

已存在的目标文件绝不会被静默覆盖。仅当你希望安装程序将当前副本移动到带时间戳的备份并替换它时，才传递 `--force`。

## 导入技能

旧的导入辅助工具仅用于将外部技能引入审查分支。导入的内容在通过验证并合并之前并非规范版本。

使用随附的导入脚本：

```bash
bash scripts/import-agent-skill.sh \
    ~/.gemini/config/skills/agent-skills-setup \
    agent-skills-setup
```

## 开源元数据

- 许可证：MIT
- 贡献方式：见 `CONTRIBUTING.md`
- 安全报告：见 `SECURITY.md`
- 社区规范：见 `CODE_OF_CONDUCT.md`

## 发布

本仓库旨在同时支持私有本地开发与公开发布。

当前的分发渠道：

- GitHub 仓库作为规范的公开来源。
- ClawHub 用于 OpenClaw 原生发布与带版本更新。
- `skills.sh` 用于跨智能体发现。
- `github/awesome-copilot` 用于精选的 Copilot 曝光。

发布前，请运行 `bash validate-all.sh`、审阅 `THIRD_PARTY_NOTICES.md`，并确认仓库不包含任何私有路径、本地密钥或机器相关的假设。
