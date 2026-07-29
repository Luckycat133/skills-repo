# HI-001 — IDE 路径表单源化（待办重构）

> **文档元信息** ｜ 更新日期：2026-07-28 ｜ 作者：skills-repo 维护组 ｜ 类型：架构设计说明 ｜ 状态：已审阅

> 状态：**待办 / 延后**。属于核心引擎重构，风险高，不在「文档与文件结构优化」本轮范围内。
> 类型：技术债（High-priority Improvement，编号 HI-001）。

## 问题

IDE 路径与能力映射目前以 **4–5 份副本** 存在于仓库，互相之间靠人工同步，长期必然漂移：

| 副本 | 位置 | 角色 |
| --- | --- | --- |
| 文档 | `references/ide-registry.md` | 人类可读的 IDE 注册表与路径说明 |
| 数据 | `references/ide-paths.json` | 结构化路径/能力 JSON（脚本读取） |
| 代码 | `skills/agent-skills-setup/scripts/smart-ide-migration.sh` 内的路径函数 | 迁移引擎实际查表逻辑 |
| 测试 | `skills/agent-skills-setup/scripts/test-ide-paths.sh` | 校验路径函数与 json 是否一致 |
| （可能）其他映射脚本 | `scripts/*-mapping.sh` / `verify-ide-config.sh` | 部分重复常量 |

漂移后果：`ide-registry.md` 说 A 路径、`ide-paths.json` 写 B、`smart-ide-migration.sh` 用 C——三者都“看似正确”，但行为以代码副本为准，文档与数据已失真。

## 目标

单一真源 + 代码生成，消除人工同步：

- **选定真源**：`references/ide-paths.json`（结构化、可被脚本与生成器直接消费）。
- **代码生成**：新增生成器（如 `scripts/gen-ide-paths.sh` 或 Python），从 `ide-paths.json` 生成：
  - `smart-ide-migration.sh` 中所需的路径函数/关联数组（生成片段写入 `references/` 或 `scripts/generated/`，被主脚本 `source`）；
  - `references/ide-registry.md` 中的路径表章节（每次发布前重新生成）。
- **测试改为一致性闸门**：`test-ide-paths.sh` 反查“代码中实际使用的路径”是否全部能在 `ide-paths.json` 中找到；并让 `validate-all.sh` 校验 `ide-registry.md` 路径表由生成器产出（带 `<!-- GENERATED -->` 标记），防止手改。

## 执行约束

- **不要**直接改写 `smart-ide-migration.sh` 的路径逻辑来“顺便修”。
- 先写生成器 + 单测，再用生成器产出片段替换手写在 `smart-ide-migration.sh` 中的路径块；分 PR 推进。
- 真源变更必须经 `test-ide-paths.sh` 全绿 + `validate-all.sh` 通过。
- 完成后删除其余副本中的重复常量，仅保留“生成片段 + 真源 + 文档”。
- 与 `scripts/sync-root-mirror.sh` 类似，生成器产出物不进手改，靠钩子/CI 防漂移。

## 关联

- 当前约定：脚本路径真源 = `references/ide-registry.md` + `references/ide-paths.json`；改 `smart-ide-migration.sh` 路径函数后必须同步 `ide-paths.json` 并跑 `test-ide-paths.sh`。本 HI-001 正是要把这条“人工同步”升级为“自动生成”。
- 路线图：`docs/agent-skills-setup/roadmap.md`
