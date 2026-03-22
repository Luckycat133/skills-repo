# ClawHub Release Guide / ClawHub 发布指南

This document explains the exact release flow for publishing `agent-skills-setup` to ClawHub.

这份文档给出把 `agent-skills-setup` 发布到 ClawHub 的精确流程。

## Preconditions / 前置条件

- `clawhub` is installed.
- 已安装 `clawhub`。
- You are logged in with `clawhub login`.
- 已通过 `clawhub login` 登录。
- The skill folder contains a valid `SKILL.md`.
- skill 目录中包含有效的 `SKILL.md`。
- Release docs and changelog are already updated.
- 发布文档和 changelog 已更新。

## Recommended Commands / 推荐命令

Validate and print the exact publish command first:

先做校验并生成精确发布命令：

```bash
bash skills/agent-skills-setup/scripts/prepare-clawhub-release.sh \
    --skill-dir skills/agent-skills-setup \
    --slug agent-skills-setup \
    --name "Agent Skills Setup" \
    --version 0.2.0 \
    --tags latest,setup,skills,openclaw \
    --changelog "Add OpenClaw support, bilingual docs, release guidance, and publishing helpers."
```

Publish immediately after validation:

校验后直接发布：

```bash
bash skills/agent-skills-setup/scripts/prepare-clawhub-release.sh \
    --skill-dir skills/agent-skills-setup \
    --slug agent-skills-setup \
    --name "Agent Skills Setup" \
    --version 0.2.0 \
    --tags latest,setup,skills,openclaw \
    --changelog "Add OpenClaw support, bilingual docs, release guidance, and publishing helpers." \
    --publish
```

## Suggested Metadata / 建议的发布元数据

- Slug: `agent-skills-setup`
- Slug：`agent-skills-setup`
- Display name: `Agent Skills Setup`
- 显示名称：`Agent Skills Setup`
- Initial OpenClaw-enabled version: `0.2.0`
- 首个包含 OpenClaw 支持的版本：`0.2.0`
- Suggested tags: `latest,setup,skills,openclaw,cross-ide`
- 建议标签：`latest,setup,skills,openclaw,cross-ide`

## Post-Publish Checklist / 发布后检查项

1. Run `clawhub inspect agent-skills-setup`.
2. 运行 `clawhub inspect agent-skills-setup`。
3. Verify the published `SKILL.md` renders as expected.
4. 确认发布后的 `SKILL.md` 渲染正常。
5. Star the skill from the release account if appropriate.
6. 如合适，可使用发布账号为技能点星。
7. Add the ClawHub URL to the GitHub README and release notes.
8. 把 ClawHub 页面链接加入 GitHub README 和 Release 说明。