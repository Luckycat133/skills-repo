# ClawHub Release Guide / ClawHub 发布指南

This document explains the exact release flow for publishing `agent-skills-setup` to ClawHub.

这份文档给出把 `agent-skills-setup` 发布到 ClawHub 的精确流程。

日本語: `agent-skills-setup` を ClawHub に公開するための最短手順と推奨メタデータをまとめています。

Español: Este documento resume el flujo exacto y los metadatos recomendados para publicar `agent-skills-setup` en ClawHub.

## Quick Summary / 快速摘要

| Language | One-line Guidance |
|---|---|
| English | Validate first, publish second, inspect third. |
| 中文 | 先校验，再发布，最后检查发布结果。 |
| 日本語 | 先に検証し、その後公開し、最後に公開結果を確認します。 |
| Español | Primero valida, después publica y al final inspecciona el resultado. |

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
    --version 0.3.0 \
    --tags latest,setup,skills,openclaw \
    --changelog "Add cross-IDE capability migration scripts, strict validation gates, staging-first rollout defaults, and expanded mainstream IDE coverage."
```

Publish immediately after validation:

校验后直接发布：

```bash
bash skills/agent-skills-setup/scripts/prepare-clawhub-release.sh \
    --skill-dir skills/agent-skills-setup \
    --slug agent-skills-setup \
    --name "Agent Skills Setup" \
    --version 0.3.0 \
    --tags latest,setup,skills,openclaw \
    --changelog "Add cross-IDE capability migration scripts, strict validation gates, staging-first rollout defaults, and expanded mainstream IDE coverage." \
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

Suggested short description for registry pages:

建议用于注册表页面的一句话简介：

`A cross-agent skills setup workflow for Antigravity, OpenClaw, Copilot, Codex, Claude Code, and Trae.`

`一个面向 Antigravity、OpenClaw、Copilot、Codex、Claude Code 和 Trae 的跨代理 skill 配置工作流。`

## Post-Publish Checklist / 发布后检查项

1. Run `clawhub inspect agent-skills-setup`.
2. 运行 `clawhub inspect agent-skills-setup`。
3. Verify the published `SKILL.md` renders as expected.
4. 确认发布后的 `SKILL.md` 渲染正常。
5. Star the skill from the release account if appropriate.
6. 如合适，可使用发布账号为技能点星。
7. Add the ClawHub URL to the GitHub README and release notes.
8. 把 ClawHub 页面链接加入 GitHub README 和 Release 说明。

## Login Troubleshooting / 登录故障排查

If `clawhub login` opens the browser but the CLI ends with `fetch failed`, treat it as a callback failure rather than a permission denial.

如果 `clawhub login` 已经打开浏览器，但 CLI 最后报 `fetch failed`，应把它视为本地回调失败，而不是账号权限问题。

Recommended recovery steps:

建议的恢复步骤：

1. Retry `clawhub login` from the same terminal session.
2. 在同一个终端会话中重新执行 `clawhub login`。
3. Temporarily disable VPN, proxy rewriting, or local firewall rules that may block `127.0.0.1` callback traffic.
4. 临时关闭可能拦截 `127.0.0.1` 回调的 VPN、代理改写或本机防火墙规则。
5. If browser login still fails, use a token-based path if available: `clawhub login --token <token>`.
6. 如果浏览器登录持续失败，改用 token 登录：`clawhub login --token <token>`。
7. Verify with `clawhub whoami` before running publish commands.
8. 在执行发布命令前，先用 `clawhub whoami` 确认登录成功。