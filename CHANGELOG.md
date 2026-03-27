# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

### Changed

- `skills/agent-skills-setup/scripts/sync-global-skills.sh` now supports OpenClaw mirrors.
- `skills/agent-skills-setup/scripts/sync-global-skills.sh` 已支持 OpenClaw 镜像同步。
- OpenClaw helper scripts now support `--skip-doctor` for non-intrusive runs.
- OpenClaw 辅助脚本现已支持 `--skip-doctor`，便于非侵入式执行。
- Module and release docs now include bilingual Chinese and English guidance.
- 模块文档和发布文档现已提供中英双语内容。
- Public-facing docs now include additional Japanese and Spanish summaries plus improved layout and navigation.
- 面向公开发布的文档现已增加日语和西语摘要，并改进了版式与导航结构。

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
