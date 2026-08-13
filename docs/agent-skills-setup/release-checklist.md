# 发布检查清单

- [ ] canonical `SKILL.md` 描述具体、可触发，frontmatter 只含 Agent Skills 标准字段，`metadata.version` 为字符串；无 frontmatter 的根仓库指针已同步。
- [ ] 官方 `skills-ref validate` 和仓库安全补充 validator 都通过。
- [ ] `bash validate-all.sh` 在干净 checkout 通过。
- [ ] SkillSpector 或等效同源扫描无未处置 finding；报告版本与待发布版本一致。
- [ ] Agent 可在用户已明确请求且目标无歧义时完成预览与执行，不增加重复确认回合。
- [ ] 全局默认只迁移 Skills；rules、prompts 和其他项目对象必须使用显式 workspace。
- [ ] Skill 复制前扫描全部源文本；疑似字面凭据或越界链接会在目标变更前阻断整个 Skill。
- [ ] rules/prompts 的默认 `backup`、`skip`、`overwrite` 策略有回归覆盖；符号链接和错误目标类型在写入前拒绝。
- [ ] 聚焦测试覆盖路径漂移、MCP schema/transport、秘密处理、符号链接、目标冲突和零预览写入。
- [ ] 删除操作只接受精确目标或已解析目标副本根目录内的文件；符号链接 MCP 目标在任何转换或清理前被拒绝。
- [ ] 仓库不提供安装第三方运行时、批量镜像全部 Skill 或跨 Agent 自复制的组合脚本。
- [ ] ClawHub bundle 根许可证为 MIT-0，`SKILL.md` 不含冲突 `license`，且 `metadata.openclaw.requires.bins` 包含 `bash`、`python3`。
- [ ] 历史贡献者的 MIT-0 再许可授权已由维护者确认；正式发布命令包含 `--acknowledge-mit0`，dry run 不将该标志冒充法律确认。
- [ ] ClawHub 运行时白名单包含薄包装、Python core、legacy 兼容引擎及源凭据扫描器，不包含 eval、`test-*`、引用生成器或新增维护脚本。
- [ ] 公开文件不含私有路径、凭据或机器特定假设；`.env` 不复制。
- [ ] Registry v2 的 profile/source/verified_at/freshness 校验通过；README、变更记录和发行文档不使用误导性的“支持 IDE 数量”。
- [ ] support contract 没有无证据的 `full` profile；`partial` 自动 surface 与 `evals/profile-contracts.json` 完全一致。
- [ ] `plan --output` → `apply <plan> --yes` 回归覆盖 plan/Registry/adapter/source/target/Git 漂移，manifest 校验和、verify 和 guarded rollback。
- [ ] JSON/JSONC 自动 adapter 及 JSON5/TOML/YAML/XML/Lua/ambiguous storage 的 manual/fail-closed 契约通过；cloud/UI 只生成无秘密 rebuild manifest。
- [ ] legacy flag 只保留查询和零写入 dry-run；任何 `--yes` 都在运行旧引擎前拒绝，公开写入只能使用已保存的 profile-aware plan。
- [ ] 文档新鲜度离线检查通过；定时 online workflow 的官方来源报告无未处置失败。
- [ ] GitHub 提交已推送并核验；ClawHub dry run 返回预期版本、文件数和 fingerprint。
- [ ] ClawHub 的 slug、版本、标签、来源提交和简短 changelog 已准备；发布后已按版本及 `latest` 分别 inspect。

完整命令见 [ClawHub 发布流程](clawhub-release.md)；细粒度回归由 `validate-all.sh` 自动发现的 `test-*.sh` 维护。
