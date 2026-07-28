# Code Review — `agent-skills-setup` (2026-07-26)

> **文档元信息** ｜ 更新日期：2026-07-28 ｜ 作者：skills-repo 维护组 ｜ 类型：代码审查报告 ｜ 状态：已归档

## 目录

- [Executive Summary](#executive-summary)
- [Critical Findings (3)](#critical-findings-3)
- [High Findings (4)](#high-findings-4)
- [Medium Findings (17)](#medium-findings-17)
- [Low Findings (7)](#low-findings-7)
- [Summary](#summary)
- [Recommendation (prioritized)](#recommendation-prioritized)


> 本文件是 `agent-skills-setup` 全量审查（multi-reviewer-patterns）的**完整归档**。
> 审查方法：4 个隔离只读子代理并行审 Security / Architecture / Testing / Performance&Robustness，结果人工去重并统一校准严重度。
> 分流跟踪：安全与测试闸门进 [`release-checklist.md`](./release-checklist.md)；架构重构与技术债 backlog 进 [`roadmap.md`](./roadmap.md)。

> **归档说明**：本文件为 2026-07-26 的历史审查归档，逐条状态以 `release-checklist.md` 与 `roadmap.md` 为准，请勿照此直接逐条修改。

**Target**: 整个 `agent-skills-setup` skill（`skills-repo` 工作区）
**Reviewers（并行维度）**: Security · Architecture · Testing · Performance & Robustness
**Date**: 2026-07-26
**Files Reviewed**: ~60（含 1× 4005 行主引擎 `smart-ide-migration.sh`、19 个 `test-*.sh`、4 个 reference 文档、Python `validate_skills.py`、根脚本、`docs/`、`datasets/`）
**Totals**: 31 findings — **3 Critical · 4 High · 17 Medium · 7 Low**

---

## Executive Summary

功能丰富、安全意识真实存在（consent gate、`--dry-run`、不可读文件 fail-closed、覆盖前备份、无凭据扫描、供应链 SHA-256 钉固）。**但“密钥恒被清空”这一核心承诺被两个 Critical 缺陷破坏，而本应抓住它们的测试套件并未在 CI 中运行。** 其余问题集中于**重复**（IDE 路径表 4–5 份、脱敏算法两份、~118 个近重复 per-IDE guard 块）与**错误/边界处理脆弱**（临时文件泄漏、吞掉失败、缺参崩溃）。

---

## Critical Findings (3)

### [CR-001] 脱敏对 provider-key 值格式失明 — 密钥被原样复制
**Dimension**: Security (+Testing) — *合并 SEC-001 + TST-002 + TST-005*
**Severity**: Critical
**Location**: `skills/agent-skills-setup/scripts/smart-ide-migration.sh:2461`（`is_secret_value`/`SECRET_KEY_RE`）、`:1606`（MCP convert 脱敏）；对照 `scripts/validate_skills.py:14`（其实已覆盖）。
**Description**: 运行时脱敏仅在 (a) key 名匹配 `api_key|token|secret|password|…`、(b) 值像凭据 URL/query、(c) 含无空格 secret 关键字时才清空。真实 provider key 全不匹配：`sk-…`、`sk-ant-…`、`ghp_…`、`AKIA…`、`xox[baprs]-…`、`ya29.…`、`AIza…`、`sk_live_…` 被原样复制。发布期 `validate_skills.py:14` **有**这些 pattern，但只查仓库文件、不查用户实时配置。脱敏测试（`test-mcp-secret-redaction.sh`）只用 key-named fixture（`API_KEY`、`GITHUB_TOKEN`），盲区未被测，且 `[SECURITY]` 警告给出虚假安全感。
**Impact**: 真实凭据迁移到目标 IDE，直接违背 fail-closed 设计。
**Fix**: 复用 `validate_skills.py:14` 的 provider 交替式（`sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-…|ya29\.…|AIza…|sk_live_…`）放入 `is_secret_value` 与 argv 循环；做值扫描而不仅是 key 名。去重两份正则集避免漂移。补 key 值 fixture（`MY_KEY`、`WEBHOOK_URL`）。

### [CR-002] 无 `python3` 时脱敏 fail-OPEN — 报成功却零脱敏
**Dimension**: Security (+Testing +Architecture) — *合并 SEC-002 + TST-001 + ARC-006*
**Severity**: Critical
**Location**: `smart-ide-migration.sh:2430-2431`（`command -v python3 || { echo 0; return 0; }`）、`:1601`（无 python3 跳过 MCP JSON 转换）、调用方 `:2280-2288`、`:2396-2404`、`:3317`、`:3354`。
**Description**: `python3` 缺失时 `redact_secrets_in_file` 返回 `0`（“成功”）但**零脱敏**。调用方把 rc=0 当“已清空”并打印“密钥已清空”。MCP JSON 路径被跳过、回落到原样 `cp` + 失效脱敏。结果：密钥原样复制，且报告谎称已清空——与全 skill 其余 fail-closed 设计相反。
**Impact**: 任何无 python3 主机（最小/CI 镜像）上核心安全承诺被静默破坏。
**Fix**: 无 python3 分支必须 **fail-closed**——`rm -f "$file"`、发 `[SECURITY]` 警告、`return 1`。理想情况下对 `mcp`/`config`/`project` 对象在缺 python3 时拒绝迁移。补“剥离 PATH 中 python3 跑机密迁移、断言目标无密钥”的测试。

### [CR-003] CI 只跑 18 个测试文件中的 1 个；`validate-all.sh` 从不执行套件
**Dimension**: Testing — *TST-003*
**Severity**: Critical
**Location**: `.github/workflows/validate.yml:18,26`；`validate-all.sh:7-10`。
**Description**: workflow 跑 `validate-all.sh`（仅 `bash -n` 语法检查 + `validate_skills.py` + 镜像 `--check`）后只跑单个测试文件（`test-mcp-secret-redaction.sh`）。`test-smart-ide-migration.sh`(884)、`test-migration.sh`(395)、`test-ide-paths.sh`、`test-remaining-ide-mappings.sh`、13 个 IDE-mapping 测试、`verify-ide-config.sh` **从未在 CI 执行**。`validate-all.sh` 只对它们做 `bash -n`（仅语法），从不调用。
**Impact**: 真实迁移逻辑/隔离/策略覆盖在 CI 中是死重；`test-migration.sh` 回归会绿合并。
**Fix**: 让 `validate-all.sh` 实际调用每个 `test-*.sh` 并聚合退出码（或加 CI glob 步骤）。这同时卡住上面两个 Critical。

---

## High Findings (4)

### [HI-001] IDE 路径表重复 4–5 份（json/md/bash/verify/test）
**Dimension**: Architecture (+Testing +Performance) — *ARC-002 + TST-007 + PER-010*
**Severity**: High
**Location**: `references/ide-paths.json`；`references/ide-registry.md`；`smart-ide-migration.sh` `get_*_path`（≈78–740）；`verify-ide-config.sh` `EXPECTED`（21–229）；`test-ide-paths.sh`（131、200–214）；`test-*.sh` 中 ~86 个硬编码 `$HOME` 路径。
**Description**: 同一路径表存在于 JSON、prose、bash `case` 解析器、校验 expectations 数组、测试字面量。已漂移（`ide-paths.json` 多数 IDE 缺 `project`，而 `get_project_path` 有返回值）。`verify-ide-config.sh` 逐字复制 `ide-paths.json` 且自身不在 CI，静默腐烂。它还为每个 `EXPECTED` 条目 spawn 整份 4005 行引擎（≈200× 全脚本解析）只为调 `--print-path`。
**Fix**: 让 `ide-paths.json` 为单一真源，从中生成 bash 解析器 + 校验/测试 expectations（代码生成或 `source` 生成的 `lib_paths.sh`）。删除冗余的 `verify-ide-config.sh`（被 JSON 驱动的 `test-ide-paths.sh` 覆盖）。

### [HI-002] ~118 个近重复 per-IDE 手动 guard 块
**Dimension**: Architecture — *ARC-003*
**Severity**: High
**Location**: 每个 `migrate_*` 函数（skills ~1008、rules 1226、prompts 1443、mcp 2750、config 3068、project 3368）；118 处 `target_ide" == "` 出现。
**Description**: 每个函数开头一长串 `if [[ "$source_ide"/"$target_ide" == "X" ]]` 设置手动步骤/跳过。模式与文案跨函数近相同（如 Goose/Kimi/OpenCode “review project scope manually” 在 5 个函数重复）。
**Fix**: 数据驱动表（associative array 或 JSON，键 `ide → object → message`）+ 单个 `apply_manual_guards(ide, object)`。把 118 块压成一次查表。

### [HI-003] 脱敏逻辑实现两份 — 且已漂移
**Dimension**: Architecture — *ARC-004*
**Severity**: High
**Location**: `smart-ide-migration.sh:1606-1631`（MCP convert，JSON 树遍历）vs `:2461-2471`（config/project，行正则）。常量逐字重复（`SECRET_KEY_RE`、`SHORT_SECRET_FLAGS`、URL/query/flag 正则）。
**Description**: MCP 转换按解析后 JSON 树脱敏（`redact_node`）；config/project 脱敏按原始文本行正则。同一安全目标两套算法。
**Fix**: 抽一个共享脱敏模块，常量共用；`redact_json_node()` 与 `redact_raw_text()` 都 import 它（关联 HI-004 / 抽 Python 引擎）。

### [HI-004] validator↔运行时漂移，且 validator 未测
**Dimension**: Testing — *TST-004*
**Severity**: High
**Location**: `scripts/validate_skills.py:14` vs `smart-ide-migration.sh:2461,1606`；全仓无测试引用 `validate_skills`。
**Description**: validator 检测 provider key + 私有绝对路径 + 链接转义；运行时脱敏不检测（见 CR-001），且 `validate_skills.py` **无对应测试**。唯一能抓 provider key 的地方自身未验证，而真正搬密钥的运行时不检测。
**Fix**: 加 `test-validate-skills.py` 覆盖每个 validator 分支（注入 `sk-…`、`ghp_…`、`HOME_PATH/…`、转义链接），并让运行时正则与 validator 对齐（关联 CR-001 / HI-003）。

---

## Medium Findings (17)

### Security
- **[MED-S1] OpenClaw 配置/`.env` 以 0644 创建且含明文密钥** — *SEC-003* — `auto-configure-openclaw-skills.sh:429, 881-906, 940-941`；`smart-ide-migration.sh:2433,2731`。`~/.openclaw/openclaw.json`（含 `--env` API key / `apiKey` SecretRef）与 `~/.openclaw/.env` 创建为 `0644`。**Fix**: 写后 `chmod 600`；`os.open(TMP, O_WRONLY|O_CREAT|O_TRUNC, 0o600)`；碰凭据文件前 `umask 077`。
- **[MED-S2] 密钥经命令行 `--env` / `--api-key-env` 传入** — *SEC-004* — `auto-configure-openclaw-skills.sh:226-235, 899-914`。值在 `ps` 与 shell 历史可见。**Fix**: 改 `--env-file <path>` 或交互输入；至少文档化暴露风险。
- **[MED-S3] 非 MCP 对象（skills/agents/hooks/memory）未脱敏** — *SEC-005* — `smart-ide-migration.sh` `migrate_skills` 原样 `cp -r`（`:1149/:1200`）；`migrate_agents`/`migrate_hooks`/`migrate_memory` **无** `redact_secrets_in_file` 调用。仅 `mcp`/`config`/`project` 脱敏。用户 skill 目录里的 `.env`/`credentials.json`/硬编码 key 被原样复制——且 `skills` 在**默认** scope。**Fix**: 对复制的 skill/agent/hook/memory 树跑现有 `redact_project_copy`（匹配 `*.env`/json/yaml/toml），或至少扫描+告警。

### Architecture
- **[MED-A1] 策略 + 拷贝逻辑重复 4–5×** — *ARC-005* — `migrate_skills`（1128-1146、1179-1197）、`migrate_mcp`（3011-3028）、`migrate_config`（3285-3303）、`migrate_project`（3547-3565、3618-3636）——7 处 `backup)`；copilot 与 else 拷贝分支重叠。**Fix**: `apply_strategy(path)` helper + 统一拷贝循环（关联 LOW-A4 备份时间戳冲突）。
- **[MED-A2] `convert_mcp_file` 隐式、顺序相关的退出码分支** — *ARC-007* — `:2363,2381,2387`。不可转换源变原样 `copied` 回落还是硬 `failed`，取决于散落的 `if target_ide == X` 列表；加新 IDE 静默改变 fail-open/closed。**Fix**: 显式 per-target 策略表（`ALLOW_FALLBACK`/`FAIL_CLOSED`）。
- **[MED-A3] 死代码诊断解析器** — *ARC-008* — `get_project_mcp_path`（346）、`get_project_config_file`（407）仅被 `--print-path` 调用，无 `migrate_*` 调用。**Fix**: 实现或删除并文档化为不支持。

### Testing
- **[MED-T1] 断言依赖 `set -e`，失败不透明** — *TST-006* — `test-smart-ide-migration.sh:42,46,154,160,185,402,446,…`。裸 `grep -Fq '…' <<< "$OUT"` 无 `|| exit 1`；未命中以通用非零中止整脚本且无 `FAIL:` 行，掩盖后续检查。**Fix**: 每个检查走 `check_pass`/`check_fail` 累加器（如 `test-migration.sh`）。
- **[MED-T2] `hooks`/`agents`/`memory` 对象与完整策略矩阵未测** — *TST-008* — 这些对象的真实拷贝/脱敏行为未验证；既有部分文件冲突合并未测；项目树脱敏（D3）只查 `.env` 不查 `svc.json`。**Fix**: 加定向拷贝+脱敏测试；断言备份**所有**复制文件。
- **[MED-T3] 缺边界测试** — *TST-009* — 无畸形/非法 JSON（`_fail_closed` 是干净删文件返 ≠0 还是让迁移崩？）、空配置、**软链**（`cp -r` 解引用，skill 树内指向密钥的软链被复制）、只读目标测试。**Fix**: 各加 fixture。

### Performance & Robustness
- **[MED-P1] 临时文件泄漏（auto-configure & sync-global-skills）** — *PER-001/002/003* — `auto-configure-openclaw-skills.sh:325-327`（trap 引用 `local tmp_install` → `set -u` 下 `unbound variable`，curl 失败时泄漏）、`:589`（`tmp_dir` **无** trap，多 `die`/`set -e` 路径跳过清理）、`sync-global-skills.sh:136-137`（`mktemp` 列表从不删，每 run 6×）。**Fix**: 单一全局 EXIT trap 删临时目录/文件（用**全局**变量）。
- **[MED-P2] CLI 参数缺失守卫缺失，崩溃为 `unbound variable`** — *PER-004/005* — `smart-ide-migration.sh:3784-3816`、`install.sh:17-18` 消费 `$2`/`$3` 无 `[[ $# -ge N ]]` 守卫；如 `--source` 无值 →  cryptic `bash: $2: unbound variable`。**Fix**: 消费前守卫（对照 `prepare-clawhub-release.sh:54`）。
- **[MED-P3] `cp … 2>/dev/null` 吞掉真实失败** — *PER-006* — `smart-ide-migration.sh:1430,1561,3310,3639`。权限拒绝/磁盘满/ACL 被吞，用户只见通用“迁移失败”。**Fix**: 去掉 `2>/dev/null` 或捕获并展示错误。
- **[MED-P4] `sync-root-mirror.sh` 直接 `>` 截断 root `SKILL.md`（损坏风险）** — *PER-007* — `:73` `build_mirror > "$ROOT_MIRROR"`（先截断再写，无临时文件+`mv`）。`sed` 在 `set -e` 中途失败会让被跟踪/发布的 root `SKILL.md` 损坏。**Fix**: 写 `mktemp` 后原子 `mv`（同 python 脱敏器 `:2731-2733` 模式）。
- **[MED-P5] `validate_skills.py` 无 frontmatter 时 IndexError** — *PER-008* — `:59` `text.split("---", 2)[1]` 在既无 frontmatter 也无 `"---"` 时 `IndexError`，中止整个 validator 使其未能报告其他错误。**Fix**: 守卫 split（`if len(parts) > 1 and "description:" not in parts[1]`）。
- **[MED-P6] `export-public-skill.sh` 未转义 `sed` 插值** — *PER-009* — `:102-105` `sed -e "s/{{SKILL_NAME}}/$SKILL_NAME/g"`；若名字含 `/`、`&` 或 `#` 定界符，`sed` 异常。**Fix**: `python3` `str.replace` 或定界符 + `&`→`\&` 转义。
- **[MED-P7] `redact_project_copy` 每文件 fork 一个 `python3`** — *PER-011* — `smart-ide-migration.sh:3353-3363`。复制树上 O(n) 解释器 fork。**Fix**: 单次 Python 调用 `os.walk` 树内脱敏。
- **[MED-P8] 假定 `rsync` 存在（macOS 默认无）** — *PER-013* — `export-public-skill.sh`、`sync-global-skills.sh`、`import-agent-skill.sh`、`auto-configure` 用 `rsync -a --delete`。现代 macOS arm64 默认无 `rsync` → 脚本 `die`/失败。`auto-configure` 还假定 `node`/`unzip`。**Fix**: `command -v rsync` + `cp -R` 回退，或显式声明依赖。

---

## Low Findings (7)

- **[LOW-S1] `import-agent-skill.sh` 路径穿越** — *SEC-006* — `:14` `TARGET_DIR="$REPO_ROOT/skills/$SKILL_NAME"` + `:22` `rsync … "$TARGET_DIR/"`；`SKILL_NAME` 未校验（对照 `install.sh:52` `^[a-z0-9-]+$`）。**Fix**: 加同样守卫。
- **[LOW-A1] 全局可变状态 + 临时文件 IPC** — *ARC-009* — 计数器 `MIGRATION_TOTAL/SUCCESS/FAILED/SKIPPED` 全局；status/message/manual 经临时文件 `awk … | tail -1`（后写覆盖）传递。不可并行、难单测。
- **[LOW-A2] 成功计数粗糙** — *ARC-010* — `migrate_skills` 不论实际复制几个 skill 都 +1，摘要可能掩盖“0/N 复制”。
- **[LOW-A3] `set` 严格度不一致** — *ARC-011* — 多数 `set -euo pipefail`；`verify-ide-config.sh:9`、`test-ide-paths.sh:17` 用 `set -uo pipefail`（无 `-e`）。文档化测试例外。
- **[LOW-A4] 备份时间戳冲突** — *PER-012* — `date +%Y%m%d%H%M%S`（`:1135/1186/3021/3558`）；同秒内两次 run/两个 skill 在 `.bak.$timestamp` 冲突覆盖旧备份。**Fix**: `date +%Y%m%d%H%M%S.$$` 或 `mktemp` 风格后缀（关联 MED-A1）。
- **[LOW-A5] `root/SKILL.md` 手动镜像漂移风险** — *ARC-012* — root `SKILL.md` 是 `skills/agent-skills-setup/SKILL.md` 的再生镜像，需手动步骤。**Fix**: CI 检查或 `make mirror`（并入 HI-001 代码生成）。
- **[LOW-T1] 脱敏测试缺 `LAST_RC` 断言** — *TST-010* — `test-mcp-secret-redaction.sh:41,112,200,321` 靠后续文件断言暗示成功；显式 `rc==0` 仅少数段落断言。**Fix**: 每个 `run …` 块断言 `LAST_RC==0`。

---

## Summary

| Dimension            | Critical | High | Medium | Low | Total |
| -------------------- | -------- | ---- | ------ | --- | ----- |
| Security             | 2        | 0    | 3      | 1   | 6     |
| Architecture         | 0        | 3    | 3      | 5   | 11    |
| Testing              | 1        | 1    | 3      | 1   | 6     |
| Performance/Robust.  | 0        | 0    | 8      | 0   | 8     |
| **Total**            | **3**    | **4**| **17**  | **7**| **31**|

## Recommendation (prioritized)

1. **发布前先修两个 Critical 脱敏缺陷**（CR-001、CR-002）。都在 `redact_secrets_in_file`/`is_secret_value` 同一处：(a) 加 provider-key 值 pattern（复用 `validate_skills.py:14`）；(b) 无 `python3` 分支改 fail-closed 而非返成功。这是“迁移安全”与“迁移泄漏凭据”的分界。
2. **把测试套件接入 CI**（CR-003）。让 `validate-all.sh` 跑每个 `test-*.sh`（或加 CI glob 步骤）。再补两个能抓 Critical 的测试：provider-key 值脱敏、无 python3 fail-closed（HI-004 / TST-004 validator 测试也在此）。
3. **去重安全 + 路径数据**（HI-001、HI-003、HI-004）。让 `ide-paths.json` 为单一真源（生成 bash 解析器+测试 expectations），抽一个共享脱敏模块（运行时与 validator 永不再漂移）。这是最高杠杆的结构修复，也消除 CR-001 根因。
4. **硬化错误/边界路径**（MED-P1–P6）。全局 EXIT trap 清临时文件、消费 CLI 参数前 `[[ $# -ge N ]]` 守卫、不再吞 `cp` 失败、root `SKILL.md` 镜像原子写、守卫 validator 的 split。
5. **长期缩减巨石**（HI-002、MED-A1、MED-A2、MED-A3）。抽 ~1000 行内联 Python 为独立 `convert_mcp.py`/`redact.py`；把 ~118 个 per-IDE guard 块换查表；实现或删除死代码 project-mcp/project-config 解析器。

**Overall**: 安全*设计*扎实，却毁于脱敏路径上的两个 Critical *实现*缺口，加上未卡 merge 的测试套件。无需重写——Critical/High 项都局部、可一轮聚焦修复。
