# Distribution Guide / 分发与曝光指南

This document turns the publishing research into an execution plan.

这份文档把发布调研结果整理成可执行的落地方案。

## Goal / 目标

- publish the skill in a way that users can install it reliably
- 让用户能够稳定安装这个 skill
- make the skill discoverable beyond direct repo links
- 让 skill 不止依赖仓库直链传播
- keep private local workflow details out of the public release
- 避免把私有本地工作流细节带入公开版本

## Channel Matrix / 渠道矩阵

| Channel | Role | Why it matters | What to prepare |
|---|---|---|---|
| GitHub | Canonical source | Issues, releases, README, stars, backlinks | Public repo, README, LICENSE, CHANGELOG |
| ClawHub | OpenClaw-native registry | Search, install, update, semantic discovery, version history | Skill folder, version, tags, changelog |
| `skills.sh` | Cross-agent discovery | Leaderboard and multi-agent installs | Public repo layout, installable structure, strong README |
| `github/awesome-copilot` | Curated visibility | Copilot audience and credibility | High-signal skill, validation results, PR to `staged` |

| 渠道 | 角色 | 为什么重要 | 需要准备的内容 |
|---|---|---|---|
| GitHub | 公开主源 | 承载 Issue、Release、README、Star 和外链 | 公开仓库、README、LICENSE、CHANGELOG |
| ClawHub | OpenClaw 原生注册表 | 提供搜索、安装、更新、语义发现和版本历史 | skill 目录、版本号、标签、changelog |
| `skills.sh` | 跨代理曝光渠道 | 提供排行榜和多代理安装入口 | 公开仓库结构、可安装布局、强 README |
| `github/awesome-copilot` | 精选目录曝光 | 提供 Copilot 用户可见度和公信力 | 高信号 skill、验证结果、提交到 `staged` 的 PR |

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
- exact ClawHub publish command
- 精确可执行的 ClawHub 发布命令

## Suggested Launch Copy / 建议的发布文案

Short description:

简短描述：

`agent-skills-setup` is a multi-agent skill setup workflow for Antigravity, Claude Code, Codex, Copilot, Trae, and OpenClaw, with sync, validation, and publishing helpers.

`agent-skills-setup` 是一个面向 Antigravity、Claude Code、Codex、Copilot、Trae 和 OpenClaw 的多代理 skill 配置工作流，提供同步、验证和发布辅助能力。

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