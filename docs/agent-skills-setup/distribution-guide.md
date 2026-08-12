# 分发指南

GitHub 是规范来源；ClawHub 提供版本化发布；Awesome Copilot 是可选的精选渠道。

1. 从干净的 GitHub 主源发布；版本、根仓库指针、README、许可证契约和变更记录必须一致。
2. 运行 `bash validate-all.sh` 和 SkillSpector 等安全扫描，处理结果后再提交。
3. 先推送并核验 GitHub 提交，再按 [ClawHub 发布流程](clawhub-release.md) 执行 registry dry run 和正式发布。
4. 发布后定向检查新版本及 `latest` 标签；若索引仍显示旧版，不要宣称新版本已公开可安装。
5. 按渠道要求提交精选目录；验证 runtime-only 包可由目标 Agent 自己的 Skill 管理器读取。

公开材料应只说明可发布的 Skill；仓库级自动化、私有工作流和机器状态不随发行包传播。发行包使用显式运行时白名单，而不是“复制后排除已知文件”。仓库与 canonical Skill 使用 MIT；ClawHub bundle 单独生成 MIT-0 许可证并由 contributor authorization 阻断正式发布。

安装只负责让目标 Agent 能读取 Skill，不接受 IDE 迁移参数，也不执行迁移脚本。`--source`、`--target`、`--objects` 和 `--workspace` 仅在用户之后要求迁移时由 Agent 传给运行时命令。
