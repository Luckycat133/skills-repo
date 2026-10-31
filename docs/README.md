# 文档

这里只保留 `agent-skills-setup` 的现行设计、发布和维护说明；一次性审计、评测输出和本机状态不得提交。

文件使用小写 kebab-case，按主题放入 `agent-skills-setup/`。同一事实只保留一处，其余使用相对链接。新增文档前确认它是长期维护资料，并在相关文档中链接它。

根 `SKILL.md` 是不含 frontmatter 的生成式仓库指针，不是可发布 Skill；编辑 `skills/agent-skills-setup/SKILL.md` 后运行 `bash scripts/sync-root-mirror.sh`。

- [更新记录](../CHANGELOG.md)
- [当前功能与后续验证](agent-skills-setup/roadmap.md)
- [兼容性矩阵](agent-skills-setup/compatibility-matrix.md)
- [发布检查清单](agent-skills-setup/release-checklist.md)
- [分发指南](agent-skills-setup/distribution-guide.md)与 [ClawHub 发布流程](agent-skills-setup/clawhub-release.md)
