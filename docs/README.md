# docs/

> **文档元信息** ｜ 更新日期：2026-07-28 ｜ 作者：skills-repo 维护组 ｜ 类型：文档索引 ｜ 状态：已发布

本目录只保留 `agent-skills-setup` 当前仍在使用的设计、维护与发布文档。

## 目录划分

[`agent-skills-setup/`](./agent-skills-setup/) 存放本仓库自有 skill 的路线图、发布流程、迁移指南和架构设计。外部 skill 的审查、一次性评测结果和临时调查记录应保存在对应项目或任务工作区，不在本仓库归档。

## 命名规范

1. **小写 kebab-case**：`roadmap.md`、`distribution-guide.md`、`release-checklist.md`。禁用空格、驼峰、中文文件名。
2. **按关注点分子目录**：同一主题的文档放进同一子目录；跨主题的内容先做拆分再归档，不在根 `docs/` 堆积。
3. **维护索引**：用子目录的 `README.md` 列出仍有效的文档及用途。
4. **避免过程归档**：一次性审计、评测输出、调查快照和本机状态不得提交；结论应转化为测试、路线图条目或维护规则。
5. **避免重复**：同一事实只在一处定义，别处用相对链接引用（如发布命令集中写在 `clawhub-release.md`，`distribution-guide.md` 仅交叉引用）。

## 新增文档流程

1. 确认内容是长期维护资料，而非一次性过程输出。
2. 用 kebab-case 命名并放入 `agent-skills-setup/`。
3. 在子目录的 `README.md` 索引中登记（标题 + 一句话摘要）。
4. 文档间使用相对仓库路径。

## 相关

- 仓库级约定见 [`AGENTS.md`](../AGENTS.md) 与 [`CONTRIBUTING.md`](../CONTRIBUTING.md)。
- 根 `SKILL.md` 是生成镜像，真源在 `skills/agent-skills-setup/SKILL.md`，由 `scripts/sync-root-mirror.sh` 同步——不要直接编辑根 `SKILL.md`。
