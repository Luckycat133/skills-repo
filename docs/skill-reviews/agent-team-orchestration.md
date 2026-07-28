# Review — agent-team-orchestration

> **文档元信息** ｜ 更新日期：2026-07-28 ｜ 作者：skills-repo 维护组 ｜ 类型：技能审查报告 ｜ 状态：已归档

user-level skill 全量内容审查报告。来源：2026-07-26 全量审查（SKILL.md + `_skillhub_meta.json` + 4 个 references）。
本文件仅记录问题，未改动 skill 实际内容。修复待用户批准。

> 落点说明：原临时审查在 `/tmp`，后一度误放 skill 自身目录 `REVIEW.md`；按用户要求改为统一归档到项目 `docs/`（2026-07-27）。

## 状态总览

| 级别 | 数量 | 说明 |
|------|------|------|
| P1 | 3 | 阻断在本环境（WorkBuddy）下直接执行 |
| P2 | 2 | 内部一致性矛盾 |
| P3 | 2 | 打磨级 / 可移植性措辞 |

---

## P1 — 平台耦合（必须修，否则本环境无法照搬）

### P1-1 工具名不匹配
skill 直接引用了 Claude Code 的会话工具名，本环境不存在对应命令：

| skill 中引用 | 本环境对应 |
|--------------|-----------|
| `sessions_spawn`（SKILL.md L141、communication.md） | `Agent` 工具 |
| `sessions_send`（communication.md L27、L110） | `SendMessage` 工具 |
| 团队管理（隐含） | `TeamCreate` / `TeamDelete` |
| 任务状态追踪（隐含） | `TaskCreate` / `TaskUpdate` / `TaskList` / `TaskOutput` |

按字面执行会失败。

### P1-2 工作区路径为虚构约定
- `team-setup.md` 与 `communication.md` 反复使用 `/workspace/agents/...` 与 `/shared/`（specs/artifacts/reviews/decisions）。
- 本环境真实结构：`~/.workbuddy/teams/{team-name}/`（团队配置）+ `~/.workbuddy/tasks/{team-name}/`（任务列表）。
- skill 未提供任何映射说明，共享产物目录需自行约定。

### P1-3 `allowed-tools` 过窄
frontmatter `allowed-tools: Read,Write,Bash,Grep,Glob` 不含编排所需工具（Agent / SendMessage / TeamCreate / TaskOutput）。若当作可执行 runbook 自动驱动工具会缺关键能力；作为纯概念指南可接受，但需显式注明。

**建议修复**：在 `communication.md` 与 SKILL.md 增 "WorkBuddy 映射" 小节（`sessions_spawn→Agent`、`sessions_send→SendMessage`、团队/任务目录映射），并修正 `allowed-tools`。

---

## P2 — 内部一致性

### P2-1 升级阈值矛盾
- `team-setup.md` Builder SOUL 示例："Blocked for >10 minutes? Comment on the task and move on"
- `patterns.md` Escalation 章节："escalate after 10 minutes"

两者语义冲突。应统一为"10 分钟即升级（escalate）"，而非静默转移。

### P2-2 "Test" 阶段被过度承诺
`patterns.md` 标题 `Spec → Review → Build → Test` 承诺了独立 Test 阶段，但流程图无独立测试步（测试并入 Builder 写单测 + Reviewer 集成测）。

建议：标题改为 `Spec → Build → Review`，或在流程中补明确的测试 agent 步骤。

---

## P3 — 打磨级

### P3-1 模型示例绑定友商
`team-setup.md` 用 `Claude Opus / GPT-4.5 / GPT-4o-mini / Haiku` 举例。作为通用建议无碍；若定位 WorkBuddy skill，可改为环境档位（high-reasoning / lite / default）以免歧义。

### P3-2 缺中文角色说明
frontmatter 已有 `description_zh` / `description_en` 双语字段，但正文角色表为纯英文。可补中文角色映射延续双语风格。

---

## 备注
- 以上问题均为**文档/可移植性**层面，无代码行为变更。
- 概念层面（角色 / 状态机 / 交接 / 质量门禁）评价为优秀，建议修 P1 后保留。
- 修复未应用（用户 2026-07-27 要求归档到项目 docs，未授权改 skill）。
