# Release Checklist

> **文档元信息** ｜ 更新日期：2026-07-28 ｜ 作者：skills-repo 维护组 ｜ 类型：发布清单 ｜ 状态：已发布

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
- 确认 `bash validate-all.sh` 在干净本地 checkout 上通过（已完成 R1 修复：校验器通过 `git ls-files` 跳过被忽略的路径）。
- 确认脱敏覆盖 provider-key 值格式（`sk-`/`ghp_`/`AKIA`/`xoxb`/`ya29`/`AIza`），且 `test-mcp-secret-redaction.sh` 含这些值的 fixture（CR-001，详见 `code-review-2026-07-26.md`）。
- 确认无 `python3` 时 `redact_secrets_in_file` 走 fail-closed（拒绝复制或报错），绝不返“成功”却零脱敏（CR-002）。
- 确认 CI 实际执行全量测试套件（`validate-all.sh` 自动发现并执行 `skills/agent-skills-setup/scripts/test-*.sh`，用 `--list-tests` 审计清单）。
- 确认 OpenClaw 配置 / `.env` 写入权限为 `600`，无明文密钥泄漏到世界可读文件（MED-S1）。
- 确认非 MCP 对象（skills/agents/hooks/memory）复制时也经脱敏或至少扫描告警（MED-S3）。
- 确认 root `SKILL.md` 镜像写入为原子操作（已完成 G4/MED-P4 修复：临时文件 + `mv` 替换，且采用前缀 link 自动重写）。
- 确认 `--source-mcp-file` 的正常输入、错误 root/schema、符号链接同源和 `--scope both` 拒绝场景均有回归；dry-run 会真实解析但不写 workspace/target。
- 确认字面凭据与混合/复杂表达式 fail-closed，而精确 Cursor `${env:NAME}` 引用转换为 OpenCode `{env:NAME}`；canonical `SKILL.md` 更新后通过同步脚本生成 root 镜像。
- 确认 Eval 4 在隔离 workspace 中实际执行 dry-run/apply，并以目标文件和 source digest 证明零预览写入、正确转换及源不变，而不是只检查回答文字。
- 确认 VS Code 用户级 MCP 保持 active-Profile/manual 边界，不推测 default Profile 路径；项目级仍解析为 `.vscode/mcp.json`。
- 确认 MCP `skip`/`backup`/`overwrite` 策略在共享配置中保留无关字段，并有同名 server 回归；不得再声称创建 `<name>_migrated`。
- 确认 OpenCode V1 与 V2 fixture 均通过，V2 使用 `mcp.servers` 且 `--json` 报告含完整 `evidence.mcp` 证据链。
- 确认 `evals/evals.json` 的 8 个行为案例与 `evals/trigger-evals.json` 的 20 个正负触发案例通过 coverage test。

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
- Confirm CI actually runs every focused suite (`validate-all.sh --list-tests` enumerates all colocated `test-*.sh` files and the default run executes each one).
- Confirm OpenClaw config / `.env` are written `600`, with no plaintext secrets leaking to world-readable files (MED-S1).
- Confirm non-MCP objects (skills/agents/hooks/memory) are also redacted on copy, or at least scanned with a warning (MED-S3).
- Confirm the root `SKILL.md` mirror write is atomic (G4/MED-P4 resolved: temp file + `mv` with prefix-based link rewriting).
- Confirm `--source-mcp-file` covers valid input, wrong root/schema, symlink self-target, and rejected `--scope both`; dry-run must parse the source without writing workspace/target output.
- Confirm literal credentials and mixed/complex expressions fail closed, exact Cursor `${env:NAME}` references become OpenCode `{env:NAME}`, and the root mirror is generated from the canonical `SKILL.md`.
- Confirm Eval 4 actually executes dry-run/apply in an isolated workspace and uses target-file plus source-digest evidence, rather than grading response text alone.
- Confirm VS Code user MCP remains active-Profile/manual and no default Profile path is guessed; project MCP still resolves to `.vscode/mcp.json`.
- Confirm MCP `skip`/`backup`/`overwrite` preserve unrelated shared-config fields and cover same-name servers; never claim a `<name>_migrated` entry is created.
- Confirm OpenCode V1 and V2 fixtures pass, V2 uses `mcp.servers`, and `--json` includes the complete `evidence.mcp` chain.
- Confirm the eight behavior evals and balanced 20-case trigger eval set pass `test-eval-coverage.sh`.
