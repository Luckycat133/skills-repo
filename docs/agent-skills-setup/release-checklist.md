# 发布检查清单

- [ ] `SKILL.md` 描述具体、可触发；根镜像已同步。
- [ ] `SKILL.md` frontmatter 只声明 `file_read`、`file_write`、`shell`，并要求两个已命名的受支持产品作为触发上下文。
- [ ] `bash validate-all.sh` 在干净 checkout 通过。
- [ ] SkillSpector 或等效同源扫描无未处置 finding；报告版本与待发布版本一致。
- [ ] Agent 可在用户已明确请求且目标无歧义时完成预览与执行，不增加重复确认回合。
- [ ] 全局默认只迁移 Skills；rules、prompts 和其他项目对象必须使用显式 workspace。
- [ ] Skill 复制前扫描全部源文本；疑似字面凭据或越界链接会在目标变更前阻断整个 Skill。
- [ ] 聚焦测试覆盖路径漂移、MCP schema/transport、秘密处理、符号链接、目标冲突和零预览写入。
- [ ] 删除操作只接受精确目标或已解析目标副本根目录内的文件；符号链接 MCP 目标在任何转换或清理前被拒绝。
- [ ] 仓库不提供安装第三方运行时、批量镜像全部 Skill 或跨 Agent 自复制的组合脚本。
- [ ] ClawHub 运行时白名单包含迁移器及其源凭据扫描器，不包含 eval、`test-*`、引用生成器或新增维护脚本。
- [ ] 公开文件不含私有路径、凭据或机器特定假设；`.env` 不复制。
- [ ] 支持的 IDE/安装渠道、README、变更记录和发行文档一致。
- [ ] GitHub 提交已推送并核验；ClawHub dry run 返回预期版本、文件数和 fingerprint。
- [ ] ClawHub 的 slug、版本、标签、来源提交和简短 changelog 已准备；发布后已按版本及 `latest` 分别 inspect。

完整命令见 [ClawHub 发布流程](clawhub-release.md)；细粒度回归由 `validate-all.sh` 自动发现的 `test-*.sh` 维护。
