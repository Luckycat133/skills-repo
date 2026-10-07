# Repository Guidelines

## Layout

`skills/agent-skills-setup/` is the canonical publishable skill: `SKILL.md` defines behavior, `references/` holds conditional guidance, `scripts/` holds migration tools and colocated `test-*.sh` suites, and `assets/` holds reusable templates. The root `SKILL.md` is generated; edit the canonical file and run `bash scripts/sync-root-mirror.sh`. Keep repository tooling in `scripts/` and only active, repository-owned guidance in `docs/agent-skills-setup/`.

## Validate

- `bash validate-all.sh` — required before a PR; runs syntax, validation, mirror checks, and focused suites.
- `python3 scripts/validate_skills.py` — frontmatter, links, secrets, and private-path checks.
- `bash scripts/sync-root-mirror.sh --check` — verify the generated mirror.
- `bash skills/agent-skills-setup/scripts/test-<feature>.sh` — run a focused regression, for example `test-cursor-mapping.sh`.

## Style

Use portable Bash (`#!/usr/bin/env bash`, quoted variables, `set -euo pipefail`) and four-space indentation. Python uses type hints, `pathlib`, and preferably the standard library. Use lowercase kebab-case names and concise Markdown with relative links. Do not edit generated mirrors.

## Changes

Keep changes focused; add a nearby regression for changed behavior, including success and failure/dry-run paths. Tests must use isolated temporary directories and never touch real agent configuration. Use Conventional Commits. PRs explain scope, affected IDEs, and validation; update the README, docs, and changelog when behavior or release steps change.

## Security

Never commit credentials, private absolute paths, or machine-specific assumptions. Preserve dry-run and confirmation safeguards. Follow `SECURITY.md` for vulnerability reports.

## Maintainer Skill routing

For registry, mapper, guarded plan/restore or packaging development, use [.agents/skills/agent-skills-setup-maintenance/SKILL.md](.agents/skills/agent-skills-setup-maintenance/SKILL.md). Use the canonical public `agent-skills-setup` Skill to perform an actual user migration. Other project capabilities are routed in [.agents/SKILLS.md](.agents/SKILLS.md).

<!-- agent-workflow:v1:start -->
## 通用执行约定（2026-09-13）

- 将行动请求执行到可验证结果；用上下文补齐常规细节，只有答案会实质改变结果时才澄清。新消息用于调整当前目标，不因阶段完成而反复询问是否继续。
- 系统/开发者限制优先；用户明确授权高于通用 Skill 默认流程。本块统一通用工作流，保留本项目的产品基线、兼容性、发布、凭据和计费专用门禁。缺少必要授权时先完成可审查的前置工作；已有同范围授权不重复索取。
- 只加载当前任务相关的入口、技能和必要片段；历史日志不是当前状态。规则导致暂停或偏离时，给出准确文件、条款和原因，不把自己的推断说成硬门。
- 默认用简洁段落报告结果和必要证据。独立子任务在工具与权限允许、且能明显节省时间时并行，先分配文件所有权；小任务不强行委派，不默默创建用户侧边栏任务。
- 验证覆盖实际改动和风险；小型文档或可逆改动不自动触发全产品测试。协议、发布、数据迁移等仍执行项目相应门禁。通过后停止重复检查；失败、新改动或未解决风险才扩大测试。
- 分开报告已改、已验证、未执行与阻塞；操作发起不等于结果完成。保留用户工作，未经当前任务授权不提交、推送、发布或改变模型/账户配置。

维护：只同步此标记块；各工具专用正文保留，不强求整份入口相同。项目若明确规定完整镜像，仍保持完整镜像。仅在规则更新或交付涉及规则时检查入口/副本一致性。
<!-- agent-workflow:v1:end -->
