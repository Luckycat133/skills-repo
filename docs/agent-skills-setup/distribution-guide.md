# Distribution Guide / 分发与曝光指南

> **文档元信息** ｜ 更新日期：2026-07-28 ｜ 作者：skills-repo 维护组 ｜ 类型：发布分发指南 ｜ 状态：已发布

## 目录

- [Language Snapshots / 多语言摘要](#language-snapshots--多语言摘要)
- [Goal / 目标](#goal--目标)
- [Channel Matrix / 渠道矩阵](#channel-matrix--渠道矩阵)
- [Recommended Release Order / 推荐发布顺序](#recommended-release-order--推荐发布顺序)
- [Assets To Prepare / 需要准备的素材](#assets-to-prepare--需要准备的素材)
- [Suggested Launch Copy / 建议的发布文案](#suggested-launch-copy--建议的发布文案)
- [Post-Release Visibility / 发布后的曝光动作](#post-release-visibility--发布后的曝光动作)


This document turns the publishing research into an execution plan for AI Assistant Capabilities (formerly skills).

这份文档把 AI Assistant Capabilities（原 skills）的发布调研结果整理成可执行的落地方案。

日本語: このドキュメントは、GitHub・ClawHub・skills.sh・Awesome Copilot への公開導線を実行可能な手順に整理したものです。

Español: Este documento convierte la investigación de distribución en un plan ejecutable para GitHub, ClawHub, skills.sh y Awesome Copilot.

## Language Snapshots / 多语言摘要

| Language | Release Focus |
| --- | --- |
| English | Publish from a clean GitHub source, then amplify through ClawHub, skills.sh, and curated directories. |
| 中文 | 先从干净的 GitHub 主源发布，再通过 ClawHub、skills.sh 和精选目录放大曝光。 |
| 日本語 | まず GitHub を正本として公開し、その後 ClawHub や skills.sh で発見性を高めます。 |
| Español | Publica primero en GitHub como fuente canónica y después amplía el alcance con ClawHub y skills.sh. |

## Goal / 目标

- publish the skill in a way that users can install it reliably
- 让用户能够稳定安装这个 skill
- make the skill discoverable beyond direct repo links
- 让 skill 不止依赖仓库直链传播
- keep private local workflow details out of the public release
- 避免把私有本地工作流细节带入公开版本

Cross-IDE migration implementation reference:

跨 IDE 迁移实施参考：


Mainstream IDE coverage:

主流 IDE 覆盖范围：

- Copilot, Cursor, Windsurf, JetBrains, Claude Code, Codex, OpenClaw, Trae, Trae CN

Safe rollout rule:

安全发布规则：

- Use staging-first migration and strict validation before any direct-write rollout.
- 先执行 staging 迁移并通过 strict 校验，再进行 direct 写入发布。

## Channel Matrix / 渠道矩阵

| Channel | Role | Why it matters | What to prepare |
| --- | --- | --- | --- |
| GitHub | Canonical source | Issues, releases, README, stars, backlinks | Public repo, README, LICENSE, CHANGELOG |
| ClawHub | OpenClaw-native registry | Search, install, update, semantic discovery, version history | Skill folder, version, tags, changelog |
| `skills.sh` | Cross-agent discovery | Leaderboard and multi-agent installs | Public repo layout, installable structure, strong README |
| `github/awesome-copilot` | Curated visibility | Copilot audience and credibility | High-signal skill, validation results, PR to `staged` |

| 渠道 | 角色 | 为什么重要 | 需要准备的内容 |
| --- | --- | --- | --- |
| GitHub | 公开主源 | 承载 Issue、Release、README、Star 和外链 | 公开仓库、README、LICENSE、CHANGELOG |
| ClawHub | OpenClaw 原生注册表 | 提供搜索、安装、更新、语义发现和版本历史 | skill 目录、版本号、标签、changelog |
| `skills.sh` | 跨代理曝光渠道 | 提供排行榜和多代理安装入口 | 公开仓库结构、可安装布局、强 README |
| `github/awesome-copilot` | 精选目录曝光 | 提供 Copilot 用户可见度和公信力 | 高信号 skill、验证结果、提交到 `staged` 的 PR |

Visual rule of thumb:

视觉化理解：

- GitHub is the canonical home.
- GitHub 是唯一主源。
- ClawHub is the OpenClaw-native marketplace and updater.
- ClawHub 是 OpenClaw 原生市场和更新入口。
- `skills.sh` is the discovery amplifier.
- `skills.sh` 是曝光放大器。
- `github/awesome-copilot` is the curated endorsement lane.
- `github/awesome-copilot` 是精选背书渠道。

## Recommended Release Order / 推荐发布顺序

1. Publish a clean public GitHub repository.
2. 发布一个干净的公开 GitHub 仓库。
3. Add screenshots, installation snippets, and update instructions.
4. 补上截图、安装片段和更新说明。
5. Publish to ClawHub if OpenClaw support is part of the public promise.
6. 如果 OpenClaw 是公开承诺的一部分，就发布到 ClawHub。
7. Validate installability through `skills.sh`.
8. 验证 `skills.sh` 可安装性。
9. Submit to `github/awesome-copilot` if the skill remains specific and differentiated enough.
10. 如果 skill 足够具体且有差异化，再提交到 `github/awesome-copilot`。

## Assets To Prepare / 需要准备的素材

- bilingual README
- 双语 README
- short one-line description for registry and social posts
- 用于注册表和社交媒体的一句话简介
- installation snippets for GitHub, OpenClaw, and `skills.sh`
- 面向 GitHub、OpenClaw 和 `skills.sh` 的安装片段
- at least one screenshot or terminal demo
- 至少一张截图或一个终端演示
- concise changelog text for each release
- 每次发布都要准备简洁的 changelog 文本
- tags and GitHub topics
- 标签和 GitHub topics
- exact ClawHub publish command（见 [`clawhub-release.md`](./clawhub-release.md)）
- 精确可执行的 ClawHub 发布命令

## Suggested Launch Copy / 建议的发布文案

Short description:

简短描述：

`agent-skills-setup` is a scoped AI-assistant context migration skill for supported IDEs and agents. Repository-level tooling provides validation and publishing support; those maintainer tools are not part of the publishable skill workflow.

`agent-skills-setup` 是一个面向受支持 IDE 与 agent 的、范围明确的 AI 助手上下文迁移 skill。验证与发布支持由仓库级维护工具提供，不属于可发布 skill 的执行流程。

## Post-Release Visibility / 发布后的曝光动作

1. Create a GitHub release with screenshots and install commands.
2. 发布 GitHub Release，并附上截图和安装命令。
3. Add GitHub topics and a short project description.
4. 添加 GitHub topics 和项目简介。
5. Publish or sync to ClawHub.
6. 发布或同步到 ClawHub。
7. Verify the repo is installable from `skills.sh`.
8. 验证仓库可以通过 `skills.sh` 安装。

9. Submit to `github/awesome-copilot` if it fits their contribution bar.
10. 如果满足要求，提交到 `github/awesome-copilot`。
11. Share a concise announcement with one screenshot and one installation example.
12. 用一张截图和一个安装示例发布简短公告。
