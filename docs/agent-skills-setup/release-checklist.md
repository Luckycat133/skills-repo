# Release Checklist

## 中文

- 确认 `SKILL.md` 的描述足够具体、准确，并能触发正确的使用场景。
- 确认打包脚本通过 shell 语法检查。
- 确认 OpenClaw 相关脚本至少通过一次隔离环境验证。
- 确认跨 IDE 迁移先走 staging 模式，再通过 strict 校验后才允许 direct 写入。
- 确认真实机器测试没有写入用户原有 `~/.openclaw` 配置，或已明确记录任何例外行为。
- 确认公开文档中不包含私有路径、机器特定假设或敏感信息。
- 确认所有支持代理的安装说明都是当前有效版本。
- 确认新增主流 IDE（Cursor、Windsurf、JetBrains、Trae CN）至少完成一次 dry-run 冒烟验证。
- 确认 ClawHub、`skills.sh`、Awesome Copilot 的发布说明与当前官方行为一致。
- 确认 ClawHub 发布命令、slug、版本号和 changelog 文案已经准备完成。
- 确认 README、CHANGELOG 和分发文档已更新为中英双语。
- 确认 `bash validate-all.sh` 在干净本地 checkout 上通过（已完成 R1 修复：校验器过滤 `.gitignore` 忽略的文件）。
- 确认脱敏覆盖 provider-key 值格式（`sk-`/`ghp_`/`AKIA`/`xoxb`/`ya29`/`AIza`），且 `test-mcp-secret-redaction.sh` 含这些值的 fixture（CR-001，详见 `code-review-2026-07-26.md`）。
- 确认无 `python3` 时 `redact_secrets_in_file` 走 fail-closed（拒绝复制或报错），绝不返“成功”却零脱敏（CR-002）。
- 确认 CI 实际执行全量测试套件（已完成 R3 修复：`validate-all.sh` 聚合全部 `verify-ide-config.sh`、`test-ide-paths.sh`、`test-migration.sh`、`test-smart-ide-migration.sh` 及 `test-mcp-secret-redaction.sh`）。
- 确认 OpenClaw 配置 / `.env` 写入权限为 `600`，无明文密钥泄漏到世界可读文件（MED-S1）。
- 确认非 MCP 对象（skills/agents/hooks/memory）复制时也经脱敏或至少扫描告警（MED-S3）。
- 确认 root `SKILL.md` 镜像写入为原子操作（已完成 G4/MED-P4 修复：临时文件 + `mv` 替换，且采用前缀 link 自动重写）。

## English

- Verify the `SKILL.md` description is specific, accurate, and triggerable for the intended use case.
- Verify bundled scripts pass shell syntax checks.
- Verify OpenClaw scripts have passed at least one isolated-environment validation run.
- Verify cross-IDE migration runs in staging mode first, then passes strict validation before any direct-write rollout.
- Verify real-machine testing did not write into the user's existing `~/.openclaw` state, or explicitly document any exception.
- Remove private paths, machine-specific assumptions, and sensitive material from public-facing docs.
- Confirm install instructions for all supported agents are current.
- Verify newly added mainstream IDE targets (Cursor, Windsurf, JetBrains, Trae CN) pass at least one dry-run smoke test.
- Confirm ClawHub, `skills.sh`, and Awesome Copilot guidance still matches current official behavior.
- Confirm the ClawHub publish command, slug, version, and changelog text are ready.
- Confirm the README, CHANGELOG, and distribution docs are updated in both Chinese and English.
- Confirm `bash validate-all.sh` passes on a clean local checkout (R1 resolved: validator uses git ls-files to skip ignored paths).
- Confirm redaction covers provider-key value formats (`sk-`/`ghp_`/`AKIA`/`xoxb`/`ya29`/`AIza`) and `test-mcp-secret-redaction.sh` includes fixtures with these values (CR-001, see `code-review-2026-07-26.md`).
- Confirm `redact_secrets_in_file` fails closed when `python3` is missing (refuses copy or errors) — never returns "success" with zero redaction (CR-002).
- Confirm CI actually runs full test suites (R3 resolved: `validate-all.sh` aggregates all test suites into CI).
- Confirm OpenClaw config / `.env` are written `600`, with no plaintext secrets leaking to world-readable files (MED-S1).
- Confirm non-MCP objects (skills/agents/hooks/memory) are also redacted on copy, or at least scanned with a warning (MED-S3).
- Confirm the root `SKILL.md` mirror write is atomic (G4/MED-P4 resolved: temp file + `mv` with prefix-based link rewriting).
