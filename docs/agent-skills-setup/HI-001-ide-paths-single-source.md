# HI-001 — IDE 路径表单源化

> **文档元信息** ｜ 更新日期：2026-07-30 ｜ 作者：skills-repo 维护组 ｜ 类型：架构设计说明 ｜ 状态：已实施

> 状态：**已实施**。`ide-paths.json` 是路径映射的规范性来源；参考文档由其生成，运行时解析器由一致性测试约束。
> 类型：已完成的改进（High-priority Improvement，编号 HI-001）。

## 问题

IDE 路径与能力映射过去以多份副本存在于仓库，互相之间靠人工同步，容易漂移。

| 副本 | 位置 | 角色 |
| --- | --- | --- |
| 层 | 位置 | 当前职责 |
| --- | --- | --- |
| 规范 | `references/ide-paths.json` | 结构化的路径与能力契约 |
| 文档 | `references/ides/<ide>.md` | 每个 IDE 的生成路径摘要和人工维护的产品行为说明 |
| 运行时 | `scripts/smart-ide-migration.sh` | 迁移引擎的解析与执行逻辑 |
| 验证 | `scripts/test-ide-paths.sh`、`scripts/test-ide-reference-generation.sh` | 分别校验运行时与 JSON 的一致性，以及生成文档是否最新 |

漂移后果：某个 `references/ides/<ide>.md` 说 A 路径、`ide-paths.json` 写 B、`smart-ide-migration.sh` 用 C——三者都“看似正确”，但行为以代码副本为准，文档与数据已失真。

## 目标

以 JSON 契约和生成/测试闸门消除人工同步：

- **规范来源**：`references/ide-paths.json` 是路径映射的唯一规范来源。
- **文档生成**：`scripts/sync-ide-reference-summaries.py` 从 JSON 写入 40 个 mapper IDE 参考文件中的 `<!-- GENERATED -->` 路径摘要；各文件其余内容保留为人工维护的产品语义、兼容性证据和迁移建议。
- **一致性闸门**：`test-ide-paths.sh` 反查运行时使用的路径与 JSON 是否一致；`test-ide-reference-generation.sh --check` 阻止过期生成摘要进入验证流程。`validate-all.sh` 会自动执行这些测试。

## 维护方式

- 修改路径契约时，运行 `python3 scripts/sync-ide-reference-summaries.py` 更新生成摘要，再运行 `bash validate-all.sh`。
- 运行时解析器可以保留产品需要的条件逻辑；任何路径变更都必须通过 `test-ide-paths.sh` 与 JSON 契约保持一致。
- 不手改带 `<!-- GENERATED -->` 标记的区块；把解释性、产品特性和兼容性信息写在该区块之外。
- 旧的人工路径验证器 `verify-ide-config.sh` 已删除，避免它成为第二份待同步的预期数据。

## 关联

- 当前约定：脚本路径契约 = `references/ide-paths.json`；对应参考文件的路径摘要由生成器维护。改 `smart-ide-migration.sh` 的路径函数后，更新 JSON 并运行完整验证。
- 路线图：`docs/agent-skills-setup/roadmap.md`
