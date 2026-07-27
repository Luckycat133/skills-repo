# TRAE-code-review 技能审查报告

- **审查日期**：2026-07-27
- **审查对象**：`~/.workbuddy/skills/TRAE-code-review/SKILL.md`（单文件，264 行；无 `scripts/` / `references/` 附件）
- **审查方式**：按该技能自身定义的 7 步方法论执行（Step1–Step7），其中 **Step5.5** 要求用 **2 个独立只读子代理** 做二次交叉验证。
- **验证结论**：8 项问题全部经 **2/2 子代理确认存在（高置信）**，无低置信剔除项。

---

## 一、作者意图推断（Step3）

该技能是一个「平台无关代码审查技能」，目标是让 AI 在给定范围（工作区未提交改动 / 分支对比 / MR·PR / 指定文件）下，执行：

> 确定范围 → 收集上下文 → 推断改动意图 → Mermaid 可视化 → 扫描问题 → 双子代理校验 → 输出结构化表格 → 交互式选择修复

## 二、技能流水线 & 缺陷落点（Step4）

```mermaid
flowchart LR
    A["① 确定审查范围"] --> B["② 收集上下文<br/>#2 SearchCodebase 不存在"]
    B --> C["③ 推断作者意图<br/>#5 假设始终有 diff"]
    C --> D["④ Mermaid 可视化<br/>#1 嵌套围栏损坏"]
    D --> E["⑤ 扫描问题"]
    E --> F["⑤.5 子代理校验<br/>#3 占位符 X 未替换"]
    F --> G["⑥ 输出结果表<br/>#4 缺严重度列 #7 file://链接"]
    G --> H["⑦ 选择修复<br/>#6 修复无协议"]
    style B fill:#fff3e0,color:#e65100
    style C fill:#fff3e0,color:#e65100
    style D fill:#f3e5f5,color:#7b1fa2
    style F fill:#fff3e0,color:#e65100
    style G fill:#fff3e0,color:#e65100
    style H fill:#fff3e0,color:#e65100
```

## 三、审查结果表（Step6）

> 说明：按技能自身 Step6 规范应为 4 列，但**问题 #4 正是「已评估的严重度未输出」**——为不重蹈覆辙，本表补了「Severity」列作为示范修复。

| No. | Severity | Issue Title | Suggestion | Code Link |
|-----|----------|-------------|------------|-----------|
| 1 | 🔴 Major | 「Good example」嵌套代码围栏损坏，Mermaid 示例无法渲染 | 将外层 ` ```markdown ` 改为普通说明文字，让两个 ` ```mermaid ` 作为**顶级独立代码块**存在；或在文档中仅用文字描述、不嵌套同定界符围栏 | [SKILL.md#L74-L104](SKILL.md#L74-L104) |
| 2 | 🔴 Major | 引用不存在的工具 `SearchCodebase` | 改为 WorkBuddy / 通用可用工具：`Glob` / `Grep` / `Bash` 或 `Explore` 子代理，保留 `Read` | [SKILL.md#L25](SKILL.md#L25) |
| 3 | 🟡 Minor | 模板占位符「X」未替换 | 将「validates **ALL X issues**」改为「all identified issues」，并清理 L123 同款残留 | [SKILL.md#L112-L123](SKILL.md#L112-L123) |
| 4 | 🔴 Major | 严重度已评估却未在结果表展示 | Step6 输出表增加「Severity / 严重度」列，或明确 severity → 优先级映射 | [SKILL.md#L152-L156](SKILL.md#L152-L156) |
| 5 | 🔴 Major | 假设始终存在 diff，非 diff 范围未覆盖 | 区分「diff 审查」与「整文件 / 整目录 / 远程 PR 审查」；非 diff 场景改用文件实际行号或 PR 行号 | [SKILL.md#L8-L9](SKILL.md#L8-L9) · [L27-L35](SKILL.md#L27-L35) |
| 6 | 🔴 Major | 「修复」能力无操作协议 | 补充修复步骤：用哪些编辑工具、是否跑测试 / 构建、修复后是否重新审查或需用户再批准 | [SKILL.md#L161-L164](SKILL.md#L161-L164) |
| 7 | 🟡 Minor | 代码链接用本地绝对 `file:///`，远程 / PR 场景无效 | 增加 PR / 远程场景链接格式（平台 permalink 或 diff 行号），或注明本地路径仅适用于本地文件审查 | [SKILL.md#L155](SKILL.md#L155) |
| 8 | 🟡 Minor | Tips #2 要求跳过 `.md`，与「审查 .md skill」自相矛盾 | 增加例外：当审查对象本身是非代码文档（如 SKILL.md、README）时不跳过；或改「默认跳过，用户显式指定则审查」 | [SKILL.md#L247](SKILL.md#L247) |

## 四、根因（Root Cause）

两类系统性病灶：

1. **Trae 平台耦合**：直接引用 Trae 专属工具 `SearchCodebase`（#2），在 WorkBuddy / 通用环境下不存在，会导致上下文收集步骤失败或被静默丢弃。
2. **Diff 中心主义**：Basic Rules 与 Step3 硬编码「存在 diff / 用 new-version 行号」，导致整文件、整目录、远程 PR 三类范围无对应行号（#5），并连带影响 Mermaid 示例设计（#1）、结果表列定义（#4）、修复协议（#6）、链接格式（#7），以及 `.md` 跳过规则（#8）。

## 五、修复状态

- ✅ 已完成：全量审查 + 双子代理交叉验证 + 本报告归档。
- ⏳ 待用户批准：**尚未改动** `SKILL.md`。修复项可选：
  - **A. 修复全部（#1–#8）**
  - 或逐项选择：**B** #1 · **C** #2 · **D** #3 · **E** #4 · **F** #5 · **G** #6 · **H** #7 · **I** #8
- 报告位置：与本技能同目录 `REVIEW.md`。
