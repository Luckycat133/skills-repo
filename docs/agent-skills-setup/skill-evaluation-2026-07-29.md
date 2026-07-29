# skills-repo 全面评测报告

> **文档元信息** ｜ 评测日期：2026-07-29 ｜ 评测对象：`agent-skills-setup` v0.6.4 基线 → v0.6.5 修复复评，并补充 v0.6.7 发布复核 ｜ 类型：功能、准确性、体验与性能评测 ｜ 状态：评测完成

## 1. 结论摘要

用户所称的 “skills-repo” 是仓库名；仓库内实际发布的 Skill 名为
[`agent-skills-setup`](../../skills/agent-skills-setup/SKILL.md)，根目录
`SKILL.md` 是其生成镜像。本报告评测 canonical 版本
`skills/agent-skills-setup/`。原始成对评测基线版本为 **0.6.4**，本次问题修复版本为 **0.6.5**。

**基线综合评分：81/100（B+，有条件推荐）；v0.6.5 修复后回归复评为 91/100；v0.6.7 在关闭新增 P0 后复评为 91/100（A-，推荐）**。

该 Skill 的核心价值成立：它能显著提高跨 IDE 上下文迁移方案的安全性、格式准确度和可执行性。在 4 组独立成对任务中，使用 Skill 的断言加权通过率为 **20/21（95.2%）**，无 Skill 基线为 **16/21（76.2%）**，净增 **19.0 个百分点**。仓库主验证入口完整通过；当前独立复核发现的 strategy 输入安全缺口也已通过测试驱动修复并纳入该闸门。

v0.6.4 不宜被描述为“所有目标均可无差别自动迁移”。当时最需要解决两项一致性问题：

1. VS Code 用户级 MCP 路径在文档、实现和 focused test 之间发生漂移，且失败测试未被主验证入口执行。
2. 文档宣称“冲突重命名为 `<name>_migrated`”，但实现实际采用备份后替换或同名键更新，仓库中没有对应重命名实现。

v0.6.5 已修复上述两项问题及本报告的其余 P0/P1 建议。它仍不会承诺迁移 UI-only、生成态或未知 schema，但对明确受支持的文件型对象已达到更稳健的自动化写入门槛。

### 1.1 v0.6.7 独立复核

canonical `SKILL.md` 的元数据版本为 0.6.7。相对 0.6.6，本版新增 strategy 入口校验、回归测试和对应文档。为避免把一次未经同条件 paired executor 复测的维护版本写成新的性能突破，本节把 v0.6.7 回归复核与历史基准分开表达。

| 维度 | 权重 | 当前分 | 判断 |
|---|---:|---:|---|
| 功能性 | 25% | 94 | 核心迁移、OpenCode V2、冲突策略、输入校验和 JSON 证据均有端到端回归 |
| 准确性 | 20% | 94 | 路径、schema、Profile 边界及全部公开 strategy 值与实际行为一致 |
| 安全与可靠性 | 15% | 95 | dry-run、确认、备份、脱敏及非法 strategy 零写入均有回归保护 |
| 用户体验 | 15% | 90 | preview/apply 分阶段清晰；机器证据可审计，但生态边界仍较多 |
| 响应速度 | 10% | 76* | 主 Skill 已大幅瘦身，但没有当前版本的独立 paired 时延数据 |
| 可维护性 | 10% | 84 | 22 个 focused suites 全量进入闸门；5,432 行核心脚本仍是主要债务 |
| 应用场景广度 | 5% | 89 | 高价值场景广，但大量产品仍只能诊断或人工迁移 |
| **综合** | **100%** | **90.5 ≈ 91** | **A-，推荐；性能项保持暂定** |

0.6.7 发布前重新执行 `bash validate-all.sh`，退出码为 0：22/22 focused suites、235 项 registry 检查、453 项路径/文档一致性检查、87 项 MCP 脱敏检查全部通过。最终单次 wall-clock 为 44.66 秒；同一评测会话还观测到 50.27 秒和 147.20 秒，说明共享机器负载噪声显著，因此这些数字只作为可复现记录，不用于证明模型响应速度提升或退化。

现有 v0.6.4 paired benchmark 的数字经独立复核仍然自洽：with-skill 为 20/21（95.2%），without-skill 为 16/21（76.2%）；平均耗时分别为 116.84 秒和 90.78 秒。iteration-2 的 19/19 是带输出和 grading 的顺序自检，但缺少旧版本 baseline、独立 timing 和重复运行，所以不能与 paired benchmark 混称。

#### 已关闭的 P0：未知 `--strategy` 曾会静默覆盖

修复前，CLI 帮助只声明 `skip`、`backup`、`overwrite`，默认值为 `backup`，但参数解析没有验证枚举值。独立审查和主评测者复现结果一致：在隔离 HOME 中准备一个已有 Claude Skill 后，以 `--strategy typo --yes` 执行 Cursor → Claude Skills 迁移，命令返回 0、把目标 `SKILL.md` 替换为来源内容、没有创建 `.bak.*`，并报告 `succeeded: 1`。

根因位于参数入口和执行分支之间：`--strategy` 只写入 `STRATEGY`；后续 `apply_skill_strategy()` 的 `case` 仅处理三个已知值且没有默认失败分支，因此未知值直接落到“继续复制”。修复采用统一入口校验，在 banner、路径解析和所有对象迁移之前只接受 `skip|backup|overwrite`，避免在 MCP、config 和 project 分支分别补丁。

新增回归先在旧实现上以“unknown strategy exited successfully”稳定失败，再在修复后通过。它验证任何非 `skip|backup|overwrite` 值都在目标解析和写入前非零退出、已有目标摘要逐字节不变、不创建备份并输出明确错误。因为校验位于共享入口，该断言覆盖所有后续 Skill、MCP、config 和 project strategy 分支。

### 1.2 v0.6.5 修复后复评

| 维度 | 权重 | 基线 | 修复后 | 主要证据 |
|---|---:|---:|---:|---|
| 功能性 | 25% | 84 | 94 | OpenCode V2、冲突矩阵和 JSON 证据链均有端到端回归 |
| 准确性 | 20% | 77 | 93 | VS Code active Profile、真实 conflict 语义、OpenCode V1/V2 已统一文档与实现 |
| 安全与可靠性 | 15% | 90 | 94 | 无效 overwrite 保留上一个有效目标；全部 focused suites 进入发布闸门 |
| 用户体验 | 15% | 82 | 91 | 首轮只给 preview；策略结果、版本开关和证据字段可预测 |
| 响应速度 | 10% | 68 | 82* | 主 Skill 词数减少 71.1%；尚未重跑独立模型时延基准 |
| 可维护性 | 10% | 76 | 88 | 自动发现测试、评测覆盖闸门、root mirror 与 registry 漂移检查 |
| 应用场景广度 | 5% | 91 | 91 | 支持面未通过无依据的自动化扩张来换分 |
| **综合** | **100%** | **81.2** | **91.4 ≈ 91** | **A-，推荐；性能项为保守暂定分** |

修复明细：

| 原问题/建议 | 修复结果 | 验证证据 |
|---|---|---|
| VS Code 用户 MCP 路径漂移 | 恢复 manual-only；named/default/Insiders/VSCodium 均不猜路径，项目级仍为 `.vscode/mcp.json` | `test-vscode-mapping.sh`、235 项 registry 校验 |
| `<name>_migrated` 虚假契约 | 删除不存在的重命名承诺，精确定义 `skip`/`backup`/`overwrite`；共享文件始终保留无关字段 | `test-conflict-strategies.sh` |
| 主验证漏跑 focused test | `validate-all.sh` 自动发现全部 `test-*.sh`，并增加 `--list-tests` 自审计 | `test-validate-all-coverage.sh` |
| OpenCode V2 前向兼容 | 增加 `--opencode-version v1|v2`；V2 原生输出 `mcp.servers` 并完成字段转换 | `test-opencode-v2-mapping.sh` |
| 验证证据靠临时 Shell 拼装 | `--json` 直接输出 canonical path、source/target hash、parse、backup、status、scope | `test-migration-evidence.sh` |
| 主 Skill 上下文过重 | 从 401 行 / 5,699 词 / 41,904 字节降至 248 行 / 1,647 词 / 11,858 字节，按 source/target 渐进读取 registry | root mirror 与 Skill validator |
| eval 缺少负触发和关键边界 | 行为案例 4 → 8；新增 20 条正负各半 trigger case；明确 Continue scope 与 Eval 4 机器证据 | `test-eval-coverage.sh` |
| 版本/发布文档漂移 | 版本提升至 0.6.5，并同步 CHANGELOG、release checklist、ClawHub 命令和根镜像 | mirror `--check`、全量验证 |

修复过程中，新的全量闸门还抓到了两项二阶回归：瘦身时遗漏 Claude Desktop UI 边界，以及旧测试把“失败后保留上一个有效目标”误判为新写入。前者恢复为必要的高风险说明；后者改为 byte-for-byte 不变断言，使失败路径既 fail-closed 又可恢复。

修复后新增 4 个边界案例进行了顺序自检，结果为 **19/19 断言通过**。由于本轮未允许启动独立子代理，这不是新的 paired benchmark；v0.6.4 的独立成对数据仍作为模型效果基线，v0.6.5 的实现结论以可重复回归测试为准。

最终发布闸门 `bash validate-all.sh` **退出码 0，用时 42.68 秒，22/22 focused suites 全部通过**，其中包括 235 项 registry 校验、449 项路径/registry 漂移检查和 87 项 MCP 脱敏检查。该时间不能直接与 v0.6.4 的 21.92 秒比较：旧入口只执行六个手工列出的 core suites，新入口会执行全部 22 个 focused suites。

## 2. 评测范围与方法

本次评测遵循 `skill-creator` 的成对基准流程，并结合静态审查、仓库测试和官方文档抽查。

| 方法 | 范围 | 结果用途 |
|---|---|---|
| 静态审查 | `SKILL.md`、IDE registry、迁移脚本、18 个 focused tests、CI/验证入口 | 功能覆盖、契约一致性、维护性 |
| 成对动态评测 | 4 个任务 × `with_skill` / `without_skill`，每个配置 1 次独立执行 | 真实响应准确度、体验、耗时、token 工作量 |
| 仓库验证 | `bash validate-all.sh`，另逐个执行所有 focused tests | 回归可靠性、隐藏失败 |
| 官方文档抽查 | Cursor、Continue、Codex、Claude Code、VS Code、OpenCode | 路径、root key、格式和版本准确性 |
| 独立评分 | executor 与 grader 分离；另做 claim audit | 降低自评偏差、发现“断言通过但陈述不实” |

### 2.1 规模

| 组件 | v0.6.4 基线 | v0.6.5 修复后 |
|---|---:|---:|
| canonical `SKILL.md` | 401 行 / 5,699 词 / 41,904 字节 | 248 行 / 1,647 词 / 11,858 字节 |
| `references/ide-registry.md` | 638 行 / 10,340 词 / 94,273 字节 | 638 行 / 10,425 词 / 94,905 字节 |
| `smart-ide-migration.sh` | 5,229 行 / 28,328 词 / 261,404 字节 | 5,423 行 / 28,983 词 / 269,188 字节 |
| Shell 脚本 | 26 个 | 37 个 |
| focused `test-*.sh` | 18 个 | 22 个，全部由主验证发现 |

### 2.2 局限

- 每个任务/配置只有 1 次执行；表中的标准差反映 4 个不同任务之间的差异，不是重复试验的置信区间。
- executor 的精确模型 ID 未暴露，因此只能记录为当前 Codex session default。
- 任务并行运行于同一台机器，wall-clock 数值可能包含共享负载噪声。
- 本次只深测 4 条高风险路径，不等于对 registry 声称覆盖的每个 IDE 组合做端到端验证。
- v0.6.4 eval 集没有 negative-trigger、同名冲突、VS Code named profile 和 OpenCode V2 专门案例；v0.6.5 已补齐这四类。回滚、畸形 JSONC、unsupported transport 和 symlink identity 继续由确定性 Shell 回归覆盖。
- v0.6.5 没有重新运行独立 `with_skill`/旧版本 paired executor，因此 91 分中的响应速度提升是基于上下文体量下降的保守推断，不是新的 wall-clock 测量。

> 以下第 3–12 节保留 v0.6.4 原始证据与问题分析，便于审计修复前后的差异；当前结论与状态以第 1.1 和 12.2 节为准。

## 3. 综合评分

| 维度 | 权重 | 得分 | 加权贡献 | 评价 |
|---|---:|---:|---:|---|
| 功能性 | 25% | 84 | 21.0 | 覆盖广、核心迁移可执行；1 个 focused test 失败 |
| 准确性 | 20% | 77 | 15.4 | 主要格式经官方文档印证；两处重要契约漂移 |
| 安全与可靠性 | 15% | 90 | 13.5 | dry-run、显式确认、备份、fail-closed 脱敏表现优秀 |
| 用户体验 | 15% | 82 | 12.3 | 命令明确、边界解释充分；篇幅和策略语义仍有认知负担 |
| 响应速度 | 10% | 68 | 6.8 | 准确率提升明显，但平均时延和上下文工作量增加 |
| 可维护性 | 10% | 76 | 7.6 | registry、镜像和测试体系成熟；单体脚本过大，测试入口不完整 |
| 应用场景广度 | 5% | 91 | 4.6 | 对多 IDE 迁移和团队标准化有较高实用价值 |
| **综合** | **100%** |  | **81.2 ≈ 81** | **B+，有条件推荐** |

## 4. 动态基准结果

### 4.1 任务级结果

| Eval | 场景 | With Skill | Without Skill | With / Without 耗时 |
|---:|---|---:|---:|---:|
| 1 | Cursor → Claude 项目级只读迁移计划 | 4/4（100%） | 2/4（50%） | 86.75s / 41.87s |
| 2 | 显式 MCP JSON 输入与安全预览 | 7/7（100%） | 6/7（85.7%） | 84.16s / 64.22s |
| 3 | Continue YAML → Codex TOML 的 fail-closed 边界 | 5/5（100%） | 3/5（60%） | 93.51s / 85.73s |
| 4 | 真正执行 dry-run + apply 的 MCP 迁移 | 4/5（80%） | 5/5（100%） | 202.94s / 171.28s |
| **按任务平均** |  | **95.0%** | **73.9%** | **116.84s / 90.78s** |
| **按断言加权** |  | **20/21（95.2%）** | **16/21（76.2%）** | — |

Eval 4 中 Skill 组唯一失败项并非迁移本身失败，而是 executor 的事后证据探针在给 `$TARGET_FILE` 赋值前就使用了它，因此不能可靠证明目标文件存在。实际 dry-run 和 apply 均为退出码 0，输出 schema、安全检查和源文件摘要检查均通过。这个结果仍暴露了一个体验问题：Skill 没有提供统一、机器可读的验证脚本，导致执行者临时拼装证据链时容易犯错。

### 4.2 响应与 token 性能

| 指标 | With Skill | Without Skill | 变化 |
|---|---:|---:|---:|
| 平均耗时 | 116.84s | 90.78s | **+26.07s（+28.7%）** |
| 平均总 reported tokens | 354,964 | 170,723 | **+184,241（+107.9%）** |
| 平均输出 tokens | 3,464 | 2,590 | **+874（+33.8%）** |

总 token 指标包含 cached input/context reads，只适合作为上下文工作量方向性指标，不能直接等同于计费。性能增量主要来自 Skill 主文件较长、执行者继续读取 registry/脚本，以及 Eval 4 的完整执行与验证。另一方面，仓库自身的 `validate-all.sh` 在本机约 **21.92 秒**完成，说明问题主要在模型响应和上下文消耗，而不是 fixture 级 Shell 工具吞吐。

## 5. 功能性评测

### 5.1 已验证优势

- 默认只迁移 `skills`、`rules`、`prompts`，MCP/config/project 等高风险对象必须显式选择。
- 写入前要求 `--dry-run` 预览与 `--yes` 确认；`skip`、`backup`、`overwrite` 策略均有明确入口。
- MCP 迁移能做 root-key 与部分目标 schema 转换，并对 literal secrets 执行 fail-closed 脱敏。
- 对 YAML/TOML、UI-only、agents/hooks/memory 等不安全或不稳定边界，倾向于停止自动转换并给出手工重建步骤。
- 支持 project/global scope、显式 workspace、显式 MCP 输入、source/target identity 检查和迁移后验证。
- canonical Skill 与根镜像同步校验通过，结构化 registry 与辅助脚本把平台细节从主流程中分离。

### 5.2 测试结果

`bash validate-all.sh` 完整通过，覆盖 Shell 语法、Skill frontmatter/链接/敏感路径、root mirror、IDE 配置、路径漂移、迁移、secret redaction 和 Trae 边界等验证；输出中至少包含 **880 条有编号断言**，另有语法、镜像和 isolation 检查。

但逐个执行 18 个 focused tests 后结果为 **17 通过、1 失败**：

```text
test-vscode-mapping.sh
FAIL: vscode/mcp expected unsupported/empty,
got '~/Library/Application Support/Code/User/mcp.json'
```

失败测试没有进入 [`validate-all.sh`](../../validate-all.sh) 的六个 core suite 清单，CI 只调用该入口，因此当前主验证会“全绿但漏掉 focused failure”。

## 6. 准确性评测

### 6.1 官方文档抽查

以下核心事实与当前官方资料一致：

- Cursor 使用 `mcpServers`，支持项目 `.cursor/mcp.json` 与用户 `~/.cursor/mcp.json`，并覆盖 stdio、SSE、Streamable HTTP。[Cursor MCP 文档](https://docs.cursor.com/context/model-context-protocol)
- Continue 的 YAML 形态使用 `mcpServers` 数组，项目级 MCP 位于 `.continue/mcpServers`，与普通 JSON root-map 不能直接等价复制。[Continue MCP 文档](https://docs.continue.dev/customize/deep-dives/mcp)
- Codex 使用 `config.toml` 中的 `[mcp_servers.<name>]`，可位于用户级或受信项目 `.codex/config.toml`。[OpenAI Codex MCP 文档](https://developers.openai.com/codex/mcp/)
- Claude Code 的 skills 支持用户级 `~/.claude/skills` 与项目级 `.claude/skills`，入口为 `SKILL.md` 并可带辅助文件。[Claude Code Skills 文档](https://code.claude.com/docs/en/skills)
- VS Code 的用户 MCP 配置与当前 Profile 相关，官方推荐通过 `MCP: Open User Configuration` 打开；项目配置为 `.vscode/mcp.json`。[VS Code MCP 文档](https://code.visualstudio.com/docs/agent-customization/mcp-servers)

### 6.2 发现的准确性风险

#### A. “冲突重命名”与实现不一致

[`SKILL.md`](../../skills/agent-skills-setup/SKILL.md) 在 Critical rules、conversion rules 和 safety checklist 多次宣称：

```text
Merge, never overwrite. Conflicts renamed to <name>_migrated.
```

但实现中：

- Skill 的 `backup` 策略把现有目录移动到 `.bak.<timestamp>`，再复制新目录；`overwrite` 会安全删除现有目录。
- MCP JSON 合并使用 `cur.update(servers)` / `existing.update(servers)`，同名 server 会以来源值更新目标值。
- 仓库范围内没有 `_migrated` 冲突重命名实现。

因此这不是文字润色问题，而是会影响用户对数据保留方式的判断。应选择并统一一种真实契约：实现 deterministic rename，或把文档改成“备份后替换/同名键更新”。

#### B. VS Code 用户级 MCP 路径契约漂移

主文档和迁移函数后半段注释仍说“用户级文件由 Profile/UI 管理，不猜测 portable path”；focused test 也要求 `vscode/mcp` 为空。然而 `get_mcp_path` 已返回默认 Profile 的 macOS/Linux/Windows 路径，使原有 fail-closed guard 不再触发。

这会在用户使用 named profile 时读取或写入错误的 Profile。建议二选一：

1. 保持 manual-only，恢复空路径并要求用户通过 VS Code 命令或显式文件路径选择 active profile；或
2. 增加明确的 `--vscode-profile` / `--target-mcp-file` 机制，只在用户确认 Profile 后解析路径，并让文档、registry、实现和测试同步更新。

#### C. OpenCode V1/V2 版本语义不足

Skill 当前输出 direct `mcp` 结构，对 OpenCode V1 是正确的。OpenCode V2 当前仍为迁移阶段并兼容翻译 V1 配置，但 V2 原生结构把 server 放在 `mcp.servers` 下。[OpenCode V2 MCP 文档](https://opencode.ai/v2/docs/mcp-servers) [V1 → V2 迁移说明](https://opencode.ai/v2/docs/migrate-v1)

这暂时不是立即失效，但属于明显的前向兼容风险。Skill 应标明“V1/legacy-compatible”或根据目标版本生成 native V2 结构。

## 7. 用户体验评测

### 7.1 优点

- 触发描述很窄：只有用户明确要求跨 IDE migrate/move/transfer/copy/sync 时才激活，减少误读配置的风险。
- 命令包含 `--source`、`--target`、`--workspace`、`--objects`、`--scope` 和 `--dry-run`，用户能清楚审查操作边界。
- Eval 2 中能明确解释 `--source-mcp-file` 只改变输入位置，schema 仍由 `--source` 决定，输出仍由 workspace 与目标 registry 决定；基线遗漏了其中一项。
- Unsupported boundary 不只说“手工处理”，还会给 reconstruction、格式校验和 discovery 验证步骤。
- 报告中对脱敏、备份、manual steps 和成功/失败状态有清晰区分。

### 7.2 摩擦点

- 主 Skill 已接近建议体量上限，大量 IDE 表格、例外和示例会增加首次响应延迟；执行者也容易重复读取 registry。
- `backup`、`overwrite`、`merge`、`conflict rename` 四个概念的当前关系不清晰，用户难以预测同名对象最终状态。
- 自动验证证据不是单一机器可读产物，执行者需要自行组合 `test -f`、解析器、hash 和日志，Eval 4 已展示这种脆弱性。
- `--scope` 与 IDE 特有的 user/project/profile 语义并不总是一一对应；VS Code 和 Continue 尤其需要更明确的交互提示。

## 8. 安全与可靠性评测

这是该 Skill 最成熟的部分。

- 不扫描整个 home，也不自动发现所有 IDE，只解析用户指定的 source/target。
- preview 不输出 raw config 或 secret values；写入需要显式确认。
- literal credentials 在副本中清空，源文件保持不变；不支持的表达式保持 blank/manual。
- source 与 target 同文件、symlink identity、无效 schema、无效 transport 和脱敏失败均倾向 fail closed。
- 网络安装需要 `--yes` 与 SHA-256，且与普通本地迁移分离。
- `test-mcp-secret-redaction.sh` 的 **87 项检查**通过，Eval 4 也确认 source digest 未改变。

扣分主要来自 VS Code 默认路径可能选错 Profile，以及冲突策略描述不实可能导致用户错误理解覆盖风险。

## 9. 潜在应用场景

### 9.1 高适配

1. **开发者换用 IDE/Agent**：将 Cursor、Claude Code、Codex、Windsurf 等之间的 skills、rules、prompts 和受支持 MCP 配置迁移。
2. **团队项目标准化**：把个人配置整理为 project-scoped 文件，先 dry-run 再纳入代码审查。
3. **新成员 onboarding**：用可审计脚本复制低风险上下文，避免手工漏项。
4. **供应商切换或并行试用**：在不搬运聊天历史和运行时状态的前提下复用可移植能力。
5. **配置审计与灾备**：利用 value-free preview、备份和验证报告检查结构及回滚材料。
6. **安全迁移演练**：在临时 workspace 中验证 secret redaction、schema 转换和 fail-closed 行为。

### 9.2 低适配或不应使用

- 持续双向同步或多主写入；当前没有冲突解析协议。
- 迁移聊天历史、数据库、向量索引、workspace storage 或其他生成态数据。
- 自动搬运 live secrets，或替用户建立新的 secret-manager 绑定。
- UI-only、profile-dependent、binary/proprietary 配置的无人值守迁移。
- 未明确 source、target、objects 的模糊请求。
- 未做版本锁定和 canary 验证的组织级批量下发。

## 10. 改进建议与优先级（原始评测）

以下条目记录 v0.6.4 评测时提出的建议及后续修复依据。第 1.1 节后来发现的未知 `--strategy` 零写入校验也已关闭。

### P0：下一次发布前

1. **统一 VS Code 全局 MCP 契约。** 决定 manual-only 还是显式 profile-aware；同步 `SKILL.md`、registry、`get_mcp_path`、source/target guard 与 `test-vscode-mapping.sh`。
2. **统一冲突策略语义。** 为同名 Skill 和同名 MCP server 分别定义 `skip`、`backup`、`overwrite` 的最终状态；实现并测试 `<name>_migrated`，或删除这一承诺。
3. **让主验证覆盖全部 focused tests。** 使用显式 manifest 或遍历 `test-*.sh`，避免新增测试不进入 CI；先修复当前 VS Code failure。

### P1：下一小版本

4. **瘦身 `SKILL.md`。** 主文件只保留 trigger、安全模型、decision tree、命令骨架和高风险边界；把 IDE quick reference、长示例和平台特例继续下沉到 references。目标可考虑 200–300 行，并按目标 IDE定向加载 registry 段落。
5. **提供 deterministic verifier。** 生成统一 JSON 证据：resolved source/target、dry-run/apply exit code、目标 parse/schema 检查、source/target hash、backup path、redaction count；避免执行者临时拼装 shell 证据。
6. **增加 OpenCode 版本感知。** 支持 `v1`、`v2` 或 auto-detect，明确 legacy-compatible 与 native V2 输出，并加双版本 fixture。
7. **消除重复真源。** VS Code 这类规则应尽可能由 `ide-paths.json`/registry 生成或校验脚本代码和文档，减少“注释、实现、focused test”三方漂移。

### P2：评测与体验增强

8. **扩展 eval 集。** 增加 negative trigger、同名冲突、named profile、source=target symlink、rollback、malformed JSONC、unsupported transport、Continue global/project 和 OpenCode V2。
9. **拆分响应层级。** 默认回答只给风险摘要和 dry-run 命令；用户确认后再加载转换细节，减少首次响应 token 与时延。
10. **提高断言可判定性。** Eval 3 应明确 Continue global config 与 project `.continue/mcpServers`；Eval 4 应提供固定变量和验收脚本，避免证据探针自身出错。

## 11. 建议的验收门槛

完成 P0 后，建议下一版本至少满足：

- `validate-all.sh` 自动执行 18/18 focused tests 且全绿。
- VS Code global source/target 在 default profile 与 named profile 下都有确定、可解释的行为。
- 同名 Skill/MCP server 的三种 strategy 均有端到端 fixture，文档与实际文件树完全一致。
- 现有 4 个 paired eval 保持断言加权 ≥95%，新增 negative-trigger 集无误触发。
- 平均 with-skill 响应时延增量压到 20%以内，或用分阶段加载证明首轮 preview 响应达到该门槛。

## 12. 最终判断

`agent-skills-setup` 已不是概念性 Skill，而是一套具有实际迁移脚本、registry、安全控制和回归测试的成熟工具。它相对无 Skill 基线带来的准确率提升具有测量依据，尤其擅长把“看似可复制”的配置问题转化为“先辨认 schema、scope、secret 和手工边界”的受控流程。

v0.6.4 的短板很集中：**契约漂移、单体体量和上下文成本**。当时预计完成 VS Code、冲突策略、按需加载和确定性 verifier 后可从 81 提升到约 88–91。

### 12.1 修复后最终判断

v0.6.5 达到了当时评测的预期上沿：该轮已识别的 P0 全部关闭，P1 的 Skill 瘦身、确定性 verifier、OpenCode 版本感知和测试真源约束均已落地，完整发布闸门覆盖 22/22 focused suites。当时的修复后综合评分为 **91/100**。

当时记录的剩余风险主要是长期维护性：迁移脚本仍是 5,000 行以上的单体文件，且 40 个生态不可能在一次评测中全部做真实产品端到端验证。

### 12.2 v0.6.7 最终判断

本轮独立复核新增并关闭了一个明确的 correctness blocker：未知 `--strategy` 原本会静默退化为无备份覆盖，现在会在共享入口非零退出且保持目标逐字节不变。因此当前结论为：**91/100，A-，推荐**。

当前可恢复为对 registry 明确标记为 automatic 的文件型迁移推荐使用。UI-only、生成态、版本不明、非 JSON schema 和真实凭据仍应继续人工审查；响应速度分仍是基于上下文体量的暂定分，不能替代当前版本的多轮 paired benchmark。
