# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added (0.1.0)

- OpenClaw support for `agent-skills-setup`, including shared and per-agent skill configuration guidance.
- 为 `agent-skills-setup` 增加 OpenClaw 支持，包括共享技能与单 agent 技能配置说明。
- `skills/agent-skills-setup/scripts/auto-configure-openclaw-skills.sh` for OpenClaw setup, dependency installation, and config patching.
- 新增 `skills/agent-skills-setup/scripts/auto-configure-openclaw-skills.sh`，用于 OpenClaw 自动配置、依赖安装和配置写入。
- `skills/agent-skills-setup/scripts/update-openclaw-skills.sh` for runtime, registry, and mirrored-skill updates.
- 新增 `skills/agent-skills-setup/scripts/update-openclaw-skills.sh`，用于运行时、注册表和镜像技能更新。
- `skills/agent-skills-setup/scripts/test-openclaw-support.sh` for OpenClaw smoke testing.
- 新增 `skills/agent-skills-setup/scripts/test-openclaw-support.sh`，用于 OpenClaw 冒烟测试。
- `skills/agent-skills-setup/references/openclaw.md` and updated bilingual release/distribution docs.
- 新增 `skills/agent-skills-setup/references/openclaw.md`，并更新了双语发布与分发文档。
- `skills/agent-skills-setup/scripts/prepare-clawhub-release.sh` and `docs/agent-skills-setup/clawhub-release.md` for ClawHub publishing.
- 新增 `skills/agent-skills-setup/scripts/prepare-clawhub-release.sh` 和 `docs/agent-skills-setup/clawhub-release.md`，用于 ClawHub 发布。
- `skills/agent-skills-setup/scripts/migrate-ai-capabilities.sh` for cross-IDE migration of capabilities, prompts, configurations, rules, workflows, hooks, and agents.
- 新增 `skills/agent-skills-setup/scripts/migrate-ai-capabilities.sh`，用于跨 IDE 迁移 capabilities、prompts、configurations、rules、workflows、hooks 和 agents。
- `skills/agent-skills-setup/scripts/validate-capability-migration.sh` for migration quality gates and structural validation.
- 新增 `skills/agent-skills-setup/scripts/validate-capability-migration.sh`，用于迁移质量门禁和结构校验。
- `docs/agent-skills-setup/cross-ide-capabilities-migration.md` as the end-to-end migration implementation guide.
- 新增 `docs/agent-skills-setup/cross-ide-capabilities-migration.md` 作为端到端迁移实施指南。
- Expanded cross-IDE migration target coverage: Copilot, Cursor, Windsurf, JetBrains, Claude Code, Codex, OpenClaw, Trae, and Trae CN.
- 扩展跨 IDE 迁移目标覆盖：Copilot、Cursor、Windsurf、JetBrains、Claude Code、Codex、OpenClaw、Trae、Trae CN。

### Changed

- `skills/agent-skills-setup/scripts/sync-global-skills.sh` now supports OpenClaw mirrors.
- `skills/agent-skills-setup/scripts/sync-global-skills.sh` 已支持 OpenClaw 镜像同步。
- OpenClaw helper scripts now support `--skip-doctor` for non-intrusive runs.
- OpenClaw 辅助脚本现已支持 `--skip-doctor`，便于非侵入式执行。
- Module and release docs now include bilingual Chinese and English guidance.
- 模块文档和发布文档现已提供中英双语内容。
- Public-facing docs now include additional Japanese and Spanish summaries plus improved layout and navigation.
- 面向公开发布的文档现已增加日语和西语摘要，并改进了版式与导航结构。
- Repository wording now standardizes on AI Assistant Capabilities (formerly skills) for cross-IDE migration topics.
- 仓库在跨 IDE 迁移主题中统一使用 AI Assistant Capabilities（原 skills）术语。
- `migrate-ai-capabilities.sh` now supports staging-safe write mode by default and direct-write rollout as an explicit option.
- `migrate-ai-capabilities.sh` 现默认使用 staging 安全写入模式，并将 direct 写入作为显式选项。
- `validate-capability-migration.sh` now validates TOML files and checks platform layouts under staging outputs.
- `validate-capability-migration.sh` 现支持 TOML 校验，并可检查 staging 输出下的平台目录布局。
- `migrate-ai-capabilities.sh` now fails fast when selected objects are missing, unless `--allow-missing-objects` is explicitly set.
- `migrate-ai-capabilities.sh` 现默认在所选对象缺失时失败退出，除非显式设置 `--allow-missing-objects`。

## [0.1.0] - 2026-03-22

### Added

- `agent-skills-setup` skill — multi-agent installation, synchronization, and publishing workflow
- `scripts/sync-global-skills.sh` — sync Antigravity skills to Claude Code, Codex, Copilot, Trae, Trae CN
- `scripts/export-public-skill.sh` — export any skill into a standalone public repository layout
- `references/` — IDE-specific setup guides (Antigravity, Claude Code, Codex, VS Code Copilot, Trae, Trae CN)
- `references/publishing.md` — guide for distributing skills via GitHub, skills.sh, and awesome-copilot
- `assets/public-repo-readme-template.md` — template for generated public repository READMEs
- `scripts/import-agent-skill.sh` — import a skill from Antigravity into this repository
- `docs/agent-skills-setup/` — development notes, roadmap, release checklist, and ideas
- MIT License, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md

[Unreleased]: https://github.com/Luckycat133/skills-repo/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Luckycat133/skills-repo/releases/tag/v0.1.0
