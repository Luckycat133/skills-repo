# 文档专业度审计报告（skills-repo）

> **文档元信息** ｜ 更新日期：2026-07-28 ｜ 作者：skills-repo 维护组 ｜ 类型：审计报告 ｜ 状态：草稿（只读审计产物）

- **生成日期**：2026-07-28
- **审计范围**：仓库内全部对外 markdown 文档，共 5 组约 40 个文件（不含 `.workbuddy/` 内部记忆与 `.superpowers/` 规划文件）
- **审计维度**：① 语言与可读性 ② 结构与风格规范 ③ 技术准确性（与代码/脚本/仓库事实交叉核验）
- **方法**：5 个审计子代理分片并行审查（技能对外文档 / 根 README 家族 / 治理协作文档 / docs 分析文档 / datasets 数据说明），主理人对高影响结论亲自抽检核验
- **语言策略**：全程遵守既有约定——skill 指令类文档（SKILL.md、references/*）保持专业英文、README 多语言各自保留、中文分析文档不翻译。本报告所有修改建议均不破坏该策略

---

## 一、执行摘要

| 优先级 | 问题 | 影响 | 主理人核验 |
|---|---|---|---|
| **P0** | `references/openclaw.md:199` 示例键名 `open_claw` 应为 `openclaw` | 按此示例配置，依赖安装/元数据功能被脚本静默忽略 | ✅ 已核验（脚本读 `metadata.openclaw`） |
| **P0** | `docs/.../clawhub-release.md` 发布命令写死 `--version 0.3.0`（实为 `0.6.1`） | 照抄会发布落后 3 个 minor 的错误版本 | ✅ 已核验 |
| **P0** | `datasets/README.md` §2 命名规范 `<数据集>_<版本>_<切片>.csv` 与 `split_dataset.py` 实际产物 `test_seed42.csv` 矛盾 | 文档与脚本口径冲突，损害复现性 | ✅ 已核验 |
| **P0** | `docs/ide-boundary-verification-2026-07-28.md` 内部"Confirmed Claims"与自身"反馈表/修正要点"冲突，且对 `ide-registry.md` 的"当前文本"引用已失真 | 对外宣称的"已确认事实"与真实源及自身结论相悖 | 子代理核验（详见第四节 D5） |
| **P1** | `CHANGELOG.md` 出现两个完全相同的 `## [0.5.8] - 2026-07-27` 条目，且内部检查数自相矛盾（446/415/218） | 违反 Keep a Changelog 版本号唯一性，自洽性差 | ✅ 已核验 |
| **P1** | "40 IDEs" 声明与 README/CLAUDE/REVIEW 枚举列表（仅 39，缺 `WorkBuddy`）不一致 | 跨多文档的事实声明矛盾 | ✅ 已核验（脚本 `SUPPORTED_IDES` 确为 40） |
| **P1** | `SECURITY-AUDIT.md` 多处路径前缀错误（`scripts/xxx.sh` 应为 `skills/agent-skills-setup/scripts/xxx.sh`），并标注版本 `0.5.8`（实为 `0.6.1`） | 引用不存在路径、版本漂移 | 子代理核验 |
| **P1** | `docs/skill-reviews/trae-code-review.md:63` 称报告位于"skill 同目录 REVIEW.md"，与归档约定矛盾 | 误导维护者去错误位置查找 | 子代理核验 |
| **P1** | 根 README 校验脚本检查数过时（写 215/415/80，子代理实测 235/450/80） | 数字失真 | 子代理核验（建议修改前实跑脚本确认） |
| **P2** | `SECURITY.md` 缺具体上报渠道；`CODE_OF_CONDUCT.md` 缺 Scope/Enforcement/上报方式等标准章节 | 政策不可执行 | 子代理核验 |
| **P2** | "mainstream IDE" 口径摇摆：distribution-guide 说 9 个，别处说 40 个 | 读者无法判断真实覆盖范围 | 子代理核验 |
| **P3** | docs/ 下 13 份多数缺"日期/作者/状态"元信息；长文档缺目录 | 规范性短板 | 子代理核验 |

---

## 二、核验说明

主理人亲自读取源文件与脚本，确认以下高影响结论属实（非仅依赖子代理摘要）：

1. `skills/agent-skills-setup/references/openclaw.md:199` 写 `metadata: {"open_claw":{...}}`；同文档 `:190` 及脚本 `auto-configure-openclaw-skills.sh:517` 均为 `metadata.openclaw`（无下划线）。示例键名错误。
2. `docs/agent-skills-setup/clawhub-release.md:42,56` 两处 `--version 0.3.0`；`skills/agent-skills-setup/SKILL.md` 当前 `version: 0.6.1`。
3. `CHANGELOG.md:35` 与 `:52` 均为 `## [0.5.8] - 2026-07-27`；`:47` 写 `1/446 drift check`，`:57` 写 `asserting 415 path checks`，`:33` 汇总 `446+70+80+851+22`。
4. `README.md:74` 枚举 39 个 IDE 名（缺 `WorkBuddy`）；`smart-ide-migration.sh:22` 的 `SUPPORTED_IDES` 确为 40 个（含 `workbuddy`）。
5. `datasets/scripts/split_dataset.py:109-111` 输出 `train_seed{seed}.csv`/`validation_seed{seed}.csv`/`test_seed{seed}.csv`；`datasets/README.md` §2 强制命名 `<数据集>_<版本>_<切片>.csv`。

其余中低优先级结论由对应审计子代理基于实际文件读取与脚本/目录交叉核验得出，均附证据（行号/路径），子代理编号见第四节各组末尾。

---

## 三、跨文档系统性问题（建议统一处理）

1. **IDE 计数 "40 vs 39"**：README（中/英/日/西）、CLAUDE.md、REVIEW.md、CHANGELOG、distribution-guide 均涉及。根因是 README 枚举漏列 `WorkBuddy`。建议以 `ide-registry.md` 为权威源，补齐枚举至 40（加 `WorkBuddy`）或统一改为 39，并全仓同步。
2. **校验脚本检查数过时/矛盾**：README 写 `verify-ide-config.sh (215)`、`test-ide-paths.sh (415)`；CHANGELOG 写 `446/415/218`。建议修改前实跑三个脚本取得真实值后统一；或改为"以脚本实际输出为准"的措辞。
3. **版本号漂移**：`clawhub-release.md` 写死 `0.3.0`、`SECURITY-AUDIT.md` 写 `0.5.8`，而当前已 `0.6.1`。建议发布类文档一律用变量占位并加"以 SKILL.md 的 version 为准"提示。
4. **路径前缀错误**：`SECURITY-AUDIT.md` 多处 `scripts/xxx.sh` 应为 `skills/agent-skills-setup/scripts/xxx.sh`。
5. **"mainstream IDE" 口径摇摆**：明确区分"跨 IDE 能力迁移实现覆盖（~9）"与"registry 全量 IDE/agent 条目（40）"。
6. **元信息缺失**：docs/ 下文档普遍缺"最后更新日期 / 作者 / 状态（草稿/归档/待办）"头；长文档缺目录。建议建立统一文档头规范。

---

## 四、分组详细发现

### A 组 · 技能对外文档（SKILL.md / references/* / 根 SKILL.md 镜像）
- **`references/openclaw.md`** 【P0·维度三】`:199` 示例 `open_claw` → 改为 `openclaw`（已核验）。【P1·维度二】多处链接用仓库根相对路径 `skills/agent-skills-setup/scripts/...`，reference 文件独立打开会断链 → 改为 `../scripts/...` 或约定"仓库根相对"。【P2·维度二】无 Index，跳转困难。
- **`SKILL.md`（canonical + 根镜像）** 【P2·维度二】对象表称 `commands`，默认作用域描述用 `prompts`；脚本二者为别名 → 文档注明别名关系。根镜像与 canonical 当前一致、无漂移（已核验）。
- **`references/ide-registry.md`** 【P2·维度二】含 63 个 `###` 章节（含手动/不支持/已废弃表面），无索引目录 → 加 Index；开头说明"仅 40 个由脚本自动化"。
- **`references/publishing.md`** 【P3·维度一】示例 `Luckycat133/skills-repo/your-skill` 含具体用户名、`skill_view(...)` 非通用接口 → 改为 `<your-username>` 占位并标注示例。
- **`assets/public-repo-readme-template.md`** 基本合规，无功能性错误。

### B 组 · 根 README 家族 + CHANGELOG
- **`README.md` / `README.zh-CN.md` / `README.ja-JP.md` / `README.es.md`** 【P1·维度三】`:74` "40 IDEs" 枚举仅 39（缺 WorkBuddy）；`:81-83` 检查数 215/415 过时；`:123` `github/awesome-copilot` 为无效/无链接路径 → 改为外部链接或说明。日文版 `## 概要` 表头为英文（维度二·低）。
- **`CHANGELOG.md`** 【P1·维度三/二】重复 `## [0.5.8] - 2026-07-27`（`:35`、`:52`）；内部检查数 446/415/218 自相矛盾；`:55` 枚举同样 39 项。【P3·维度二】仅 0.5.0 条目中英双语，风格不完全统一（项目有意选择，可注明约定）。

### C 组 · 治理与协作文档
- **`CONTRIBUTING.md` / `AGENTS.md` / `THIRD_PARTY_NOTICES.md`** 基本合规，路径/脚本引用经核验真实存在，评分高。
- **`SECURITY-AUDIT.md`** 【P1·维度三】多处 `scripts/smart-ide-migration.sh` 等按字面路径不存在（真实位于 `skills/agent-skills-setup/scripts/`），且与同文档其他处完整前缀矛盾；标注版本 `0.5.8`（实为 `0.6.1`）。
- **`CLAUDE.md`** 【P1·维度三】`:29` "40 IDEs" 枚举仅 39；`:38-39` 提及 `sync-global-skills.sh`/`auto-configure-openclaw-skills.sh` 缺目录前缀。
- **`REVIEW.md`** 【P1·维度二】摘要"at least four blockers"与正文"Six blockers"口径矛盾；`:12/19` "40+/40 IDEs" 与枚举不符。
- **`SECURITY.md`** 【P2·维度二】未给出具体上报渠道（无邮箱/Advisory 链接）。
- **`CODE_OF_CONDUCT.md`** 【P2·维度二】缺 Scope / Enforcement Guidelines / 上报方式 / Attribution 等标准章节。

### D 组 · docs/ 分析与审核文档（中文）
- **`clawhub-release.md`** 【P0·维度三】发布命令写死 `--version 0.3.0`（已核验）；`:77` 短描述仅列 6 个 IDE；标签两处不一致（缺 `cross-ide`）。
- **`ide-boundary-verification-2026-07-28.md`** 【P0·维度三】REG 章节对 `ide-registry.md` 的"当前文本"引用已失真（registry 当天已修订，建议已落地但未记录）；"Confirmed Claims"仍按 🟢 原样列出已被自身反馈表判 ✗ 的项（CD1/V2/AQ1/T6 等）；行号引用随大文件修订易漂移 → 改用章节锚点。
- **`trae-code-review.md`** 【P1·维度三】`:63` 位置声明与归档约定矛盾 → 改为 `docs/skill-reviews/trae-code-review.md`。
- **`distribution-guide.md`** 【P2·维度三】`mainstream IDE coverage` 列 9 个，与"40"摇摆；Launch Copy 只点名 6 个。
- **`release-checklist.md`** 【P3·维度三】中文"`.gitignore` 过滤"与英文"`git ls-files` 跳过被忽略路径"机制描述不一致 → 统一为 `git ls-files`。
- **`cross-ide-capabilities-migration.md`** 【P3·维度一/二】§2 "now covers" 与顶部"Status: Design / Not yet implemented"语义冲突；长文档缺目录。（诚实性良好：未实装脚本与声明一致，未夸大。）
- **`roadmap.md` / `HI-001-ide-paths-single-source.md` / `code-review-2026-07-26.md` / `agent-skills-setup/README.md` / `docs/README.md` / `skill-reviews/README.md` / `agent-team-orchestration.md`** 【P3】主要为元信息缺失（缺日期/作者/状态）、索引遗漏（HI-001 未登入 README）、行号引用漂移（符合归档预期）等低优先级项。

### E 组 · datasets/ 数据说明
- **`datasets/README.md`** 【P0·维度三】§2 命名规范 `<数据集>_<版本>_<切片>.csv` 与 `split_dataset.py` 实际产物 `test_seed42.csv` 矛盾（已核验）→ 二选一统一。
- **`validation_data/README.md`** 【P2·维度三】`:10` "约占总训练数据的 15%–20%" 缺"扣除测试集后的剩余训练池"限定，与 `DATA_USAGE_GUIDE.md:12` 口径偏差。
- **`DATA_USAGE_GUIDE.md`** 【P3·维度二】`:39` `verify_distribution.py --seed 42` 与 README §4 缺 `--seed` 写法不统一。
- **`test_data/README.md`** 【P2·维度三】`:17` 称 `raw/` 为测试数据存放处，但脚本产出位于 `processed/` → 说明澄清。
- **`DATA_VERSION.md`** 【P3】`.manifests/` 当前仅 `.gitkeep`，无 v1.0.0 清单 → Changelog 注明"清单待定版后由 compute_manifest.py 生成"。
- **三个子集 README** 【P3】仍为模板占位（来源/格式/特征字典未填），正式使用前需填充。

---

## 五、优先级行动清单（修改阶段执行，待你确认）

- **P0（会导致错误/误导，优先修）**
  1. `openclaw.md:199` `open_claw` → `openclaw`
  2. `clawhub-release.md` 版本号 → `0.6.1` 或变量占位 + 统一 tags
  3. `datasets/README.md` §2 命名规范与 `split_dataset.py` 统一
  4. `ide-boundary-verification-2026-07-28.md` 修正失真引用 + 闭合内部矛盾
- **P1（跨文档一致性/正确性）**
  5. `CHANGELOG.md` 合并/拆分重复 `0.5.8`，统一检查数
  6. 全仓统一 IDE 计数（补 `WorkBuddy` 或改 39）
  7. `SECURITY-AUDIT.md` 路径前缀 + 版本标注修正
  8. `trae-code-review.md` 位置声明修正
  9. 根 README 校验数刷新（实跑脚本确认）
  10. `openclaw.md` 链接改相对路径；`ide-registry.md` 加 Index + 范围说明
- **P2（政策完整性与口径）**
  11. `SECURITY.md` 补上报渠道；`CODE_OF_CONDUCT.md` 补标准章节
  12. 统一"mainstream IDE" 9 vs 40 口径
  13. `validation_data/README.md` 占比口径；`release-checklist.md` 机制描述统一
- **P3（规范性）**
  14. docs/ 文档补"日期/作者/状态"元信息头 + 长文档加目录
  15. `github/awesome-copilot` 路径处理；日文 README 表头；`publishing.md` 示例占位

---

## 六、语言策略合规性声明

所有修改建议均不改动现有语言分工：英文 skill 指令文档保持英文专业度、README 多语言各自保留、中文分析文档保持中文。审计报告本身以中文撰写，引用原文时保留原文语言。

---

## 七、下一步

本报告为**只读审计产物**，未对任何文件做修改。请确认：
- 是否按上述 P0→P3 范围进入修改阶段；
- P0/P1 中哪些优先处理；
- 修改后是否分批提交（你此前选择"先出审计报告"，故修改动作将在你确认后执行）。

> 子代理溯源：A=agent-cf5804b6，B=agent-ba54b57c，C=agent-981669db，D=agent-ffc52e4d，E=agent-bec07907。
