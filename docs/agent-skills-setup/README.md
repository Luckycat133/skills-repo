# agent-skills-setup Development Docs

> **文档元信息** ｜ 更新日期：2026-07-29 ｜ 作者：skills-repo 维护组 ｜ 类型：开发文档索引 ｜ 状态：已发布

`agent-skills-setup` 的长期维护文档集中在这里，用于规划、发布和能力说明。

This folder contains durable planning, release, and capability guidance for `agent-skills-setup`.

日本語: このフォルダには、`agent-skills-setup` の計画、検証、公開準備、改善メモをまとめます。

Español: Esta carpeta reúne la planificación, validación, publicación e iteración continua de `agent-skills-setup`.

## Purpose / 目的

- track future improvements and OpenClaw follow-up work
- 跟踪后续改进项和 OpenClaw 相关演进
- capture publishing and distribution decisions
- 记录发布与分发决策
- keep development notes separate from publishable capability files
- 将开发过程文档与可发布 capability 文件分离
- keep durable decisions here; leave temporary audits and evaluation output in task workspaces
- 这里只保留长期有效的结论；临时审计与评测输出留在任务工作区

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
- `HI-001-ide-paths-single-source.md`: design note on single-source-of-truth for IDE paths (drives `scripts/ide-paths.json` + `test-ide-paths.sh`)
- `HI-001-ide-paths-single-source.md`：IDE 路径单一真源（single-source-of-truth）的架构设计说明（驱动 `scripts/ide-paths.json` 与 `test-ide-paths.sh`）

## Current Workflow / 当前流程

1. Edit the canonical skill under `skills/agent-skills-setup/` in this repository.
2. 在本仓库的 `skills/agent-skills-setup/` 中编辑 canonical skill。
3. Regenerate the root mirror with `bash scripts/sync-root-mirror.sh`.
4. 使用 `bash scripts/sync-root-mirror.sh` 生成根目录镜像。
5. Update active release and maintenance documentation when behavior changes.
6. 行为变化时更新有效的发布与维护文档。
7. Run `bash validate-all.sh`, including the explicit-source, redaction, path, and progressive-disclosure regressions.
8. 运行 `bash validate-all.sh`，覆盖显式来源、脱敏、路径与渐进式披露回归。
