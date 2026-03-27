# agent-skills-setup Development Docs

`agent-skills-setup` 的开发文档集中在这里，用于规划、验证、发布和持续迭代。

This folder collects planning, validation, release, and iteration material for `agent-skills-setup`.

日本語: このフォルダには、`agent-skills-setup` の計画、検証、公開準備、改善メモをまとめます。

Español: Esta carpeta reúne la planificación, validación, publicación e iteración continua de `agent-skills-setup`.

## Purpose / 目的

- track future improvements and OpenClaw follow-up work
- 跟踪后续改进项和 OpenClaw 相关演进
- capture publishing and distribution decisions
- 记录发布与分发决策
- keep development notes separate from publishable skill files
- 将开发过程文档与可发布 skill 文件分离
- preserve validation notes, including machine-safe testing guidance
- 保留验证记录，包括“本机安全测试”相关说明

## Recommended Files / 推荐文件

- `roadmap.md`: upcoming features and refactors
- `roadmap.md`：近期功能和重构方向
- `release-checklist.md`: pre-publish verification steps
- `release-checklist.md`：发布前核查步骤
- `ideas.md`: experiments and backlog items
- `ideas.md`：实验想法和 backlog
- `distribution-guide.md`: release, marketplace, and discovery plan
- `distribution-guide.md`：发布、市场渠道和曝光计划
- `clawhub-release.md`: exact ClawHub release commands and metadata
- `clawhub-release.md`：ClawHub 发布命令和元数据说明

## Current Workflow / 当前流程

1. Edit the source skill under Antigravity.
2. 在 Antigravity 中修改源技能。
3. Sync it to local IDE installations.
4. 将其同步到本地各 IDE 安装目录。
5. Import the updated skill into this repository.
6. 把更新后的技能导入到本仓库。
7. Update release, validation, and bilingual docs here before publishing.
8. 在这里补齐发布、验证和双语文档后再准备发布。