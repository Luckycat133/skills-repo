# Skills Repository

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-0b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/openclaw.md)

AI agent skills with a local-first authoring workflow and a practical path to public release.

AI agent skills 仓库，采用本地优先的编写流程，并保留清晰的公开发布路径。

日本語: このリポジトリは、Antigravity を編集元として保ちながら、OpenClaw を含む複数のエージェント環境へ skill を同期・公開するためのワークフローを提供します。

Español: Este repositorio ofrece un flujo de trabajo para crear, sincronizar y publicar skills reutilizables para varios agentes, con Antigravity como fuente principal y OpenClaw como destino de primera clase.

## Table Of Contents / 目录

- [Quick Summary / 快速说明](#quick-summary--快速说明)
- [Structure / 结构](#structure--结构)
- [Conventions / 约定](#conventions--约定)
- [Current Skill / 当前技能](#current-skill--当前技能)
- [Development Workflow / 开发流程](#development-workflow--开发流程)
- [Importing Skills / 导入技能](#importing-skills--导入技能)
- [Open Source Metadata / 开源元数据](#open-source-metadata--开源元数据)
- [Publishing / 发布](#publishing--发布)

## Quick Summary / 快速说明

| Language | Summary |
|---|---|
| English | Build and release reusable agent skills with a local-first workflow, OpenClaw automation, and public distribution guidance. |
| 中文 | 以本地优先方式构建和发布可复用 agent skills，包含 OpenClaw 自动化和公开分发指南。 |
| 日本語 | ローカル優先の開発フローで skill を管理し、OpenClaw 自動化と公開配布まで一貫して扱います。 |
| Español | Gestiona skills reutilizables con un flujo local-first, automatización para OpenClaw y rutas claras de distribución pública. |

## Structure / 结构

```text
skills-repo/
├── README.md
├── docs/
│   └── agent-skills-setup/
├── scripts/
└── skills/
    └── agent-skills-setup/
```

## Conventions / 约定

- `skills/` stores publishable skill folders.
- `skills/` 用于存放可发布的 skill 目录。
- `docs/` stores development notes, release plans, validation notes, and maintenance checklists.
- `docs/` 用于存放开发笔记、发布方案、验证记录和维护清单。
- Antigravity remains the authoring source of truth unless explicitly changed.
- 除非明确变更，否则始终以 Antigravity 作为技能内容的事实来源。
- Import or sync changes into this repository before preparing a public release.
- 在准备公开发布前，先把变更导入或同步到本仓库。

## Current Skill / 当前技能

- `agent-skills-setup`: multi-agent skill installation, synchronization, OpenClaw automation, and publishing workflow.
- `agent-skills-setup`：面向多代理环境的技能安装、同步、OpenClaw 自动化配置与发布工作流。

## Development Workflow / 开发流程

1. Edit the source skill in Antigravity.
2. 在 Antigravity 中修改源技能。
3. Import or sync the updated skill into this repository.
4. 将更新后的技能导入或同步到本仓库。
5. Refine release docs under `docs/agent-skills-setup/`.
6. 在 `docs/agent-skills-setup/` 下完善发布文档和验证材料。
7. Publish the repository when the skill, metadata, and validation results are ready.
8. 当技能、元数据和验证结果准备就绪后再进行发布。

## Importing Skills / 导入技能

Use the bundled import script:

使用内置导入脚本：

```bash
bash scripts/import-agent-skill.sh \
    ~/.gemini/antigravity/skills/agent-skills-setup \
    agent-skills-setup
```

## Open Source Metadata / 开源元数据

- License: MIT
- License：MIT
- Contributions: see `CONTRIBUTING.md`
- 贡献方式：见 `CONTRIBUTING.md`
- Security reporting: see `SECURITY.md`
- 安全报告：见 `SECURITY.md`
- Community expectations: see `CODE_OF_CONDUCT.md`
- 社区行为规范：见 `CODE_OF_CONDUCT.md`

## Publishing / 发布

This repository is designed to support both private local development and public distribution.

本仓库同时支持私有本地开发和公开分发。

Current distribution lanes:

当前建议的分发路径：

Additional public-language positioning:

额外的多语言发布定位：

- Japanese readers can use this repo as a release playbook for OpenClaw and cross-agent skill maintenance.
- 日语读者可以把这个仓库当作 OpenClaw 与多代理 skill 维护的发布手册。
- Spanish-speaking users can use it as an operational guide for preparing GitHub, ClawHub, and skills.sh releases.
- 西语用户可以把它当作 GitHub、ClawHub 和 skills.sh 发布准备的操作手册。

- GitHub repository as the canonical public source.
- 以 GitHub 仓库作为公开主源。
- ClawHub for OpenClaw-native publishing and versioned updates.
- 使用 ClawHub 进行 OpenClaw 原生发布和版本化更新。
- `skills.sh` for cross-agent discovery.
- 使用 `skills.sh` 提升跨代理生态的可发现性。
- `github/awesome-copilot` for curated Copilot visibility.
- 使用 `github/awesome-copilot` 获取 Copilot 社区的精选曝光。

Before publishing, review the files under `docs/agent-skills-setup/` and confirm the repository contains no private paths, local secrets, or machine-specific assumptions.

发布前，请先审阅 `docs/agent-skills-setup/` 下的文档，并确认仓库中不包含私有路径、本地密钥或特定机器假设。