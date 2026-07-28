# Roadmap

> **文档元信息** ｜ 更新日期：2026-07-28 ｜ 作者：skills-repo 维护组 ｜ 类型：规划 ｜ 状态：进行中

## Near Term / 近期

- improve the repository export workflow and produce cleaner public release bundles
- 优化仓库导出流程，产出更干净的公开发布包
- add support for importing multiple skills at once
- 支持一次导入多个 skills
- add validation for missing `SKILL.md` and malformed frontmatter
- 增加对缺失 `SKILL.md` 和 frontmatter 格式错误的校验
- add a non-intrusive OpenClaw validation mode that avoids live gateway interference
- 增加不干预本机网关的 OpenClaw 安全验证模式

## Later / 后续

- generate public repository metadata automatically
- 自动生成公开仓库元数据
- add a publish checklist for `awesome-copilot`
- 增加针对 `awesome-copilot` 的发布清单
- add a `skills.sh` compatibility test flow
- 增加 `skills.sh` 兼容性测试流程
- add release assets for screenshots, examples, and short marketplace copy
- 增加截图、示例和市场简介等发布素材生成能力

## Backlog / Ideas（待办点子）

自由形式的 backlog，部分已与上方「Later」重叠，合并于此统一跟踪：

- `--skill <name>` 过滤：给同步脚本增加按 skill 名精确过滤
- `doctor` 脚本：专用 skill 完整性检查
- 可复用的公开仓库 License 与发布模板
- skill 发布的 changelog 工作流
- 分发素材生成器：自动产出 README 徽章、截图占位与安装片段（与「Later · release assets」重叠）

> 注：`ideas.md` 中原列的「ClawHub 发布辅助脚本」已经实装为
> `skills/agent-skills-setup/scripts/prepare-clawhub-release.sh`，故不再列入。

## Audit Backlog (2026-07-26 multi-reviewer review) / 审计 backlog

完整报告见 [`code-review-2026-07-26.md`](./code-review-2026-07-26.md)（31 项：3 Critical / 4 High / 17 Medium / 7 Low）。安全与测试闸门已进 `release-checklist.md`；此处收录可纳入规划的**重构与已知问题**。

### Completed in Recent Sprint / 已完成项目
- ✅ **R1** `validate_skills.py` 读取 `git ls-files`，解决 `.gitignore` 过滤失效导致的误报
- ✅ **R2** 统一 `SKILL.md` / `README.md` 中的 IDE 支持数量为 40
- ✅ **R3 / CR-003** `validate-all.sh` 聚合全量测试套件（`verify-ide-config.sh`、`test-ide-paths.sh`、`test-migration.sh`、`test-smart-ide-migration.sh`、`test-mcp-secret-redaction.sh`）并接入 CI
- ✅ **R4** `smart-ide-migration.sh` 补充标准 Bash `main()` 函数守卫
- ✅ **R5 / MED-P2 (install.sh)** `install.sh` 增加 `--target`/`--skill` 必填参数守卫
- ✅ **R6** `validate_skills.py` 扫描扩展至 `.json` 与 `.toml`
- ✅ **G4 / MED-P4** `sync-root-mirror.sh` 采用临时文件 + `mv` 原子写与前缀正则链接重写
- ✅ **G6** `.gitignore` 增加 `datasets/` 与 `.superpowers/`

### Security (must-fix before release) / 发布前必修 — 详见 release-checklist.md
- ✅ **CR-001** 运行时脱敏对 provider-key 值（`sk-`/`ghp_/`AKIA/`xoxb`/`ya29`/`AIza`）失明 — 已修：运行时不分 key 名做值扫描，复用 validator 的 PROVIDER_SECRET_RE；MCP/config 两路径都覆盖（2026-07-27）
- ✅ **CR-002** 无 `python3` 时 `redact_secrets_in_file` 返成功却零脱敏（fail-open） — 已修：无 python3 分支改 fail-closed（`rm -f` + `[SECURITY]` 告警 + `return 1`），各调用方已具备失败处理（2026-07-27）

### Architecture / 架构重构
- **HI-001** IDE 路径表在 json/md/bash/verify/test 重复 4–5 份 → 抽 `ide-paths.json` 单一真源 + 代码生成
- **HI-002** ~118 个近重复 per-IDE guard 块 → 数据驱动表 + `apply_manual_guards`
- **HI-003** 脱敏算法实现两份且漂移 → 抽共享脱敏模块
- **MED-A1** 策略/拷贝逻辑重复 4–5× → `apply_strategy` helper
- **MED-A2** `convert_mcp_file` 隐式顺序相关退出码分支 → 显式 `ALLOW_FALLBACK`/`FAIL_CLOSED` 表
- **MED-A3** 死代码 `get_project_mcp_path` / `get_project_config_file` → 实现或删除

### Performance & Robustness / 性能与健壮性
- **MED-P1** 临时文件泄漏（auto-configure / sync-global-skills）→ 全局 EXIT trap
- **MED-P3** `cp 2>/dev/null` 吞掉真实错误 → 去掉或捕获
- **MED-P5** `validate_skills.py` 无 frontmatter 时 IndexError → 守卫 split
- **MED-P6** `export-public-skill.sh` sed 未转义插值 → `python3` `str.replace`
- **MED-P7** `redact_project_copy` 每文件 fork python → 单次 `os.walk`
- **MED-P8** `rsync` macOS 默认不存在 → 检测 + `cp -R` 回退或显式声明依赖

### Testing / 测试
- **HI-004** validator 未测且与运行时漂移 → 加 `test-validate-skills.sh`
- **MED-T1** 断言依赖 `set -e` 不透明 → 走 `check_pass`/`check_fail` 累加器
- **MED-T2** `hooks`/`agents`/`memory` 与完整策略矩阵未测
- **MED-T3** 缺边界测试（畸形 JSON / 软链 / 只读目标）
- **LOW-T1** 脱敏测试缺 `LAST_RC` 断言
- **LOW-A4** 备份时间戳同秒冲突 → `date +%Y%m%d%H%M%S.$$`
