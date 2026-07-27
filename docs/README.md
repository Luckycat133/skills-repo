# docs/

本仓库的文档根目录。所有非代码说明性文档集中存放于此，便于检索与维护。

## 目录划分

文档按**关注点**分为两个子目录，互不复用：

| 子目录 | 内容 | 受众 |
| --- | --- | --- |
| [`agent-skills-setup/`](./agent-skills-setup/) | 本仓库自有 skill（`skills/agent-skills-setup`）的开发文档：路线图、发布流程、能力迁移指南、代码审查记录等。 | 维护者 / 贡献者 |
| [`skill-reviews/`](./skill-reviews/) | 对其他 **user-level** skill 的独立审查报告（非本仓库产物）。 | 评估者 / 使用者 |

> 原则：本仓库自有 skill 的文档归 `agent-skills-setup/`；对外部 skill 的审查归 `skill-reviews/`。不要把 skill 审查报告写进 skill 自身目录或根 `docs/` 散落。

## 命名规范

1. **小写 kebab-case**：`roadmap.md`、`distribution-guide.md`、`release-checklist.md`。禁用空格、驼峰、中文文件名。
2. **按关注点分子目录**：同一主题的文档放进同一子目录；跨主题的内容先做拆分再归档，不在根 `docs/` 堆积。
3. **每个子目录有一个索引**：子目录内用 `README.md` 作为索引，列出该目录全部文档及一句话摘要，并标注归档/状态（如 `code-review-2026-07-26.md` 顶部标「归档」）。
4. **日期标记**：带时间属性的过程文档用 `YYYY-MM-DD` 后缀（如 `code-review-2026-07-26.md`），便于按时间排序。
5. **避免重复**：同一事实只在一处定义，别处用相对链接引用（如发布命令集中写在 `clawhub-release.md`，`distribution-guide.md` 仅交叉引用）。

## 新增文档流程

1. 判断归属：`agent-skills-setup/`（自有）还是 `skill-reviews/`（外部审查）。
2. 用 kebab-case 命名，必要时放进对应子目录。
3. 在所属子目录的 `README.md` 索引中登记（标题 + 一句话摘要）。
4. 若文档引用其他文档，使用相对仓库路径（如 `../skill-reviews/foo.md`）。

## 相关

- 仓库级约定见 [`AGENTS.md`](../AGENTS.md) 与 [`CONTRIBUTING.md`](../CONTRIBUTING.md)。
- 根 `SKILL.md` 是生成镜像，真源在 `skills/agent-skills-setup/SKILL.md`，由 `scripts/sync-root-mirror.sh` 同步——不要直接编辑根 `SKILL.md`。
