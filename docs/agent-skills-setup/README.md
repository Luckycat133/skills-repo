# agent-skills-setup Development Docs

> **文档元信息** ｜ 更新日期：2026-07-28 ｜ 作者：skills-repo 维护组 ｜ 类型：开发文档索引 ｜ 状态：已发布

`agent-skills-setup` 的开发文档集中在这里，用于规划、验证、发布和持续迭代。

This folder collects planning, validation, release, and iteration material for `agent-skills-setup`.

日本語: このフォルダには、`agent-skills-setup` の計画、検証、公開準備、改善メモをまとめます。

Español: Esta carpeta reúne la planificación, validación, publicación e iteración continua de `agent-skills-setup`.

## Purpose / 目的

- track future improvements and OpenClaw follow-up work
- 跟踪后续改进项和 OpenClaw 相关演进
- capture publishing and distribution decisions
- 记录发布与分发决策
- keep development notes separate from publishable capability files
- 将开发过程文档与可发布 capability 文件分离
- preserve validation notes, including machine-safe testing guidance
- 保留验证记录，包括“本机安全测试”相关说明

## Recommended Files / 推荐文件

- `roadmap.md`: upcoming features and refactors
- `roadmap.md`：近期功能和重构方向
- `release-checklist.md`: pre-publish verification steps
- `release-checklist.md`：发布前核查步骤
- `roadmap.md` › Backlog/Ideas: experiments and backlog items (merged from former `ideas.md`)
- `roadmap.md` › Backlog/Ideas：实验想法与 backlog（由原 `ideas.md` 合并而来）
- `distribution-guide.md`: release, marketplace, and discovery plan
- `distribution-guide.md`：发布、市场渠道和曝光计划
- `clawhub-release.md`: exact ClawHub release commands and metadata
- `clawhub-release.md`：ClawHub 发布命令和元数据说明
- `cross-ide-capabilities-migration.md`: full migration playbook across capabilities, prompts, configurations, rules, and workflows
- `cross-ide-capabilities-migration.md`：覆盖 capabilities、prompts、configurations、rules、workflows 的跨 IDE 迁移总指南
- `HI-001-ide-paths-single-source.md`: design note on single-source-of-truth for IDE paths (drives `scripts/ide-paths.json` + `test-ide-paths.sh`)
- `HI-001-ide-paths-single-source.md`：IDE 路径单一真源（single-source-of-truth）的架构设计说明（驱动 `scripts/ide-paths.json` 与 `test-ide-paths.sh`）
- `code-review-2026-07-26.md`: full multi-reviewer audit (31 findings: 3 Critical / 4 High / 17 Medium / 7 Low)
- `code-review-2026-07-26.md`：完整多维度审查归档（31 项：3 Critical / 4 High / 17 Medium / 7 Low）

## Current Workflow / 当前流程

1. Edit the source skill under Antigravity.
2. 在 Antigravity 中修改源技能。
3. Sync it to local IDE installations.
4. 将其同步到本地各 IDE 安装目录。
5. Import the updated skill into this repository.
6. 把更新后的技能导入到本仓库。
7. Update release, validation, and bilingual docs here before publishing.
8. 在这里补齐发布、验证和双语文档后再准备发布。
