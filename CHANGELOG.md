# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.2] - 2026-07-22

### Security
- **Fixed arbitrary code execution (RCE) in `auto-configure-openclaw-skills.sh`.** The OpenClaw config file was previously parsed with `Function("return (…)")()`, which executes the file's contents as JavaScript. Replaced with a non-executing parser: strict `JSON.parse` first, then a string-aware JSONC-tolerant fallback (strips `//` and `/* */` comments and trailing commas) — never `eval`/`Function`. Verified by harness: valid JSON and JSONC still parse; embedded `child_process.execSync(...)` payloads are rejected and produce zero side effects.
- **Added a `--yes` confirmation gate to `sync-global-skills.sh`.** The script mirrors with `rsync -a --delete` (which deletes skills in targets absent from the source). It now refuses to run destructively unless `--yes` is passed, and prints an explicit `WARNING` listing the targets and the deletion behavior before applying. `--dry-run` remains the safe default for previewing.
- **Tightened SKILL.md triggers.** The activation description now requires an explicit user instruction and states the dry-run/`--yes` safety model; the broad `ai ide migration` trigger was narrowed to `migrate ai ide context` to reduce unintended activation.

### Changed
- Bumped `SKILL.md` (source + root mirror) to `0.5.2`.

## [0.5.1] - 2026-07-22

### Security
- Made `OPENCLAW_INSTALL_SHA256` **mandatory** for the OpenClaw `install.sh` step (previously optional; an unverified remote script could execute). The installer now refuses to run without a verified checksum.
- Made SHA-256 **mandatory** for skill `download` specs in `install_download_spec()` (previously warned-and-proceeded on a missing hash).
- Hardened `export-public-skill.sh`: `rsync --delete` now supports `--dry-run` and refuses to run against a non-empty existing target unless `--force` is given.
- Added a `capabilities:` declaration to `SKILL.md` so platforms can enforce boundaries.
- Corrected the skill description, which previously claimed it "merges without overwriting" while an explicit `overwrite` strategy (rsync --delete) existed. Default strategy remains `backup`.

## [0.5.0] - 2026-07-22

> **Note:** ClawHub was previously published at v0.4.0 (2026-05-11). Versions 0.2.0–0.4.0 were released to ClawHub but not recorded in this file; this release catches the changelog up.

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

### Fixed

- Resolved 18 audit findings (C1–C3, H1–H4, M1–M6, L1–L5) in `agent-skills-setup`: real MCP/config migration (no false success on empty transfer), corrected Copilot/Codex/WorkBuddy sync paths, supply-chain-safe OpenClaw install gated behind `--yes` with optional `OPENCLAW_INSTALL_SHA256` pin, IDE path registry (`references/ide-paths.json`) as single source of truth with a 182-check drift test, hardened shell scripts (`set -euo pipefail`, deterministic temp-file cleanup), honest migration status vocabulary (`success`/`copied`/`manual`/`absent`/`skipped`), and SKILL.md accuracy.
- 修复 `agent-skills-setup` 中的 18 项审计问题（C1–C3、H1–H4、M1–M6、L1–L5）：真实 MCP/配置迁移（空迁移不再虚假成功）、修正 Copilot/Codex/WorkBuddy 同步路径、供应链安全的 OpenClaw 安装（需 `--yes` 且可校验 `OPENCLAW_INSTALL_SHA256`）、以 IDE 路径注册表（`references/ide-paths.json`）作为单一事实来源并新增 182 项漂移测试、加固 Shell 脚本（`set -euo pipefail`、确定性临时文件清理）、诚实的迁移状态描述（`success`/`copied`/`manual`/`absent`/`skipped`），以及 SKILL.md 准确性修正。
- Reconciled three non-blocking follow-ups: Copilot global sync now mirrors full skill directories (matching `smart-ide-migration.sh` H4) instead of flattening to `<name>.md`; the capabilities-migration doc clarifies the JetBrains `.idea/ai-capabilities/` layout is distinct from the Junie `~/.junie` skill-install path in `ide-registry.md`; the stale pre-audit WorkBuddy working-tree changes were already discarded.
- 进一步收敛三项非阻塞遗留：Copilot 全局同步改为镜像完整技能目录（与 `smart-ide-migration.sh` H4 一致），不再扁平化为 `<name>.md`；能力迁移文档补充说明 JetBrains 的 `.idea/ai-capabilities/` 布局与 `ide-registry.md` 中 Junie 的 `~/.junie` 技能路径互不冲突；审计前遗留的 WorkBuddy 工作树改动此前已丢弃。

### Planned

- `skills/agent-skills-setup/scripts/migrate-ai-capabilities.sh` and `validate-capability-migration.sh` are **designed but not yet shipped** (see `docs/agent-skills-setup/cross-ide-capabilities-migration.md` §6/§11). Their command examples are illustrative of the intended interface, not runnable today.
- `skills/agent-skills-setup/scripts/migrate-ai-capabilities.sh` 与 `validate-capability-migration.sh` **已设计但尚未实装**（见 `docs/agent-skills-setup/cross-ide-capabilities-migration.md` §6/§11）。其命令示例仅说明预期接口，目前不可直接运行。

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

[0.5.0]: https://github.com/Luckycat133/skills-repo/compare/v0.4.0...HEAD
[0.4.0]: https://clawhub.ai/Luckycat133/agent-skills-setup
[0.1.0]: https://github.com/Luckycat133/skills-repo/releases/tag/v0.1.0
