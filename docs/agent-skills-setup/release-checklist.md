# 发布检查清单

- [ ] `SKILL.md` 描述具体、可触发；根镜像已同步。
- [ ] `bash validate-all.sh` 在干净 checkout 通过。
- [ ] 迁移保持 dry-run、显式 `--yes`、冲突策略、脱敏和 fail-closed 边界。
- [ ] 聚焦测试覆盖路径漂移、MCP schema/transport、秘密处理、符号链接、目标冲突和零预览写入。
- [ ] 可发布 Skill 不包含安装、发布、全局同步或字面环境值写入工具。
- [ ] 公开文件不含私有路径、凭据或机器特定假设；`.env` 不复制。
- [ ] 支持的 IDE/安装渠道、README、变更记录和发行文档一致。
- [ ] ClawHub 的 slug、版本、标签和简短 changelog 已准备；发布后已 inspect。

完整命令见 [ClawHub 发布流程](clawhub-release.md)；细粒度回归由 `validate-all.sh` 自动发现的 `test-*.sh` 维护。
