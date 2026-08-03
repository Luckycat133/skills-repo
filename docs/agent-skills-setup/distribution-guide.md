# 分发指南

GitHub 是规范来源；ClawHub 提供 OpenClaw 原生安装与更新；`skills.sh` 提供跨智能体发现；Awesome Copilot 是可选的精选渠道。

1. 从干净的 GitHub 主源发布；版本、根镜像、README、许可证和变更记录必须一致。
2. 运行 `bash validate-all.sh` 和 SkillSpector 等安全扫描，处理结果后再提交。
3. 先推送并核验 GitHub 提交，再按 [ClawHub 发布流程](clawhub-release.md) 执行 registry dry run 和正式发布。
4. 发布后定向检查新版本及 `latest` 标签；若索引仍显示旧版，不要宣称新版本已公开可安装。
5. 验证 `skills.sh` 可安装，再按渠道要求提交精选目录。

公开材料应只说明可发布的 Skill；仓库级自动化、私有工作流和机器状态不随发行包传播。
