# Release Checklist

## 中文

- 确认 `SKILL.md` 的描述足够具体、准确，并能触发正确的使用场景。
- 确认打包脚本通过 shell 语法检查。
- 确认 OpenClaw 相关脚本至少通过一次隔离环境验证。
- 确认真实机器测试没有写入用户原有 `~/.openclaw` 配置，或已明确记录任何例外行为。
- 确认公开文档中不包含私有路径、机器特定假设或敏感信息。
- 确认所有支持代理的安装说明都是当前有效版本。
- 确认 ClawHub、`skills.sh`、Awesome Copilot 的发布说明与当前官方行为一致。
- 确认 ClawHub 发布命令、slug、版本号和 changelog 文案已经准备完成。
- 确认 README、CHANGELOG 和分发文档已更新为中英双语。

## English

- Verify the `SKILL.md` description is specific, accurate, and triggerable for the intended use case.
- Verify bundled scripts pass shell syntax checks.
- Verify OpenClaw scripts have passed at least one isolated-environment validation run.
- Verify real-machine testing did not write into the user's existing `~/.openclaw` state, or explicitly document any exception.
- Remove private paths, machine-specific assumptions, and sensitive material from public-facing docs.
- Confirm install instructions for all supported agents are current.
- Confirm ClawHub, `skills.sh`, and Awesome Copilot guidance still matches current official behavior.
- Confirm the ClawHub publish command, slug, version, and changelog text are ready.
- Confirm the README, CHANGELOG, and distribution docs are updated in both Chinese and English.