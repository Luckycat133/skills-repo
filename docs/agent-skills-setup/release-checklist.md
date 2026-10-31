# 发布检查清单

- [ ] 按实际新增能力和升级影响选择版本；canonical `metadata.version` 与 Changelog 的下一版本或正式日期条目一致。开发期间标明未发布，README 使用已核验的安装标签；发布提交同步版本状态与新标签，远端确认后再报告公开可安装。
- [ ] canonical `SKILL.md` 的触发范围、路由、权限和实际 CLI 一致；frontmatter 使用 Agent Skills 标准字段，`metadata.version` 为字符串；运行 `bash scripts/sync-root-mirror.sh` 后验证根指针。
- [ ] `bash validate-all.sh` 通过，包括官方 `skills-ref validate`、仓库安全校验、完整回归和运行时包验证。跨平台结果来自实际 CI，不以本机通过代替。
- [ ] 已覆盖完整功能链：检测/清点、计划/应用/校验/回滚、快照/恢复、密钥生成/签名/可信公钥验证、doctor；别名与继承 profile 在各检测入口得到相同结果。
- [ ] 签名密钥以 POSIX 私有权限或 Windows 当前用户独占的受保护 ACL 创建和读取；跨平台签名和宽权限拒绝回归通过，不用 POSIX 权限位替代 Windows ACL 检查。
- [ ] 写入范围和已审阅 artifact 明确；用户在当前或此前明确授权的动作可继续执行，CLI `--yes` 记录该授权；缺少关键范围或授权才补问。
- [ ] 预览不写入目标；输出 artifact 不覆盖 Registry、bundle、迁移源或目标，也不互相覆盖；计划重放验证 checksum、Registry、adapter、源/目标和 Git 状态。
- [ ] 成功、失败和 dry-run 回归均使用隔离临时目录；失败保留旧目标；回滚先检查全部备份与目标漂移，再恢复精确文件内容和权限。
- [ ] Skills、instructions、MCP 保留扫描、环境文件排除、路径边界和原子写入；MCP 仅转换支持的子对象并保留无关设置。JSON5/TOML/YAML/XML/Lua/ambiguous storage 和 cloud/UI 保留手动重建边界。
- [ ] plugins / handoff 同时要求显式对象选择和对应 opt-in；插件只复制不安装/执行，交接只传白名单字段。Hooks、Agents、原始会话、信任状态、凭据和生成记忆没有自动写入路径。
- [ ] ACB 校验覆盖 1:1 文件绑定、普通权限、旧包兼容、checksum、秘密/二进制扫描和多源恢复；命名计划绑定原 bundle，跨进程重放检查多 Skill / 合并 MCP 的实际内容。转换损失明确接受，MCP 预览与 doctor 要求真实完整。可信公钥验证与普通完整性验证的结论分开报告。
- [ ] 改动影响规模或资源处理时，运行 `python3 scripts/benchmark-scale.py --sizes 10,100,1000`；保留外部报告，核对内容、回滚和源不变，不将单机耗时或夹具通过写成跨平台性能/原生运行承诺。
- [ ] skill 导入与打包先验证再交付；源/目标重叠和链接拒绝；必需运行时模块完整，排除缓存、eval、`test-*` 和维护工具；隔离 CLI 启动通过。
- [ ] ClawHub bundle 根许可证为 MIT-0，生成的 `SKILL.md` 许可证与运行时要求一致；历史贡献者的再许可授权已确认，正式发布使用 `--acknowledge-mit0` 和完整来源 attribution。
- [ ] 公开文件无私有路径、凭据和机器假设；Registry evidence/freshness、profile contracts、兼容性矩阵和 README 一致；无无证据的 `full` 支持或原生运行验收承诺。
- [ ] 显式 `legacy` 只保留 lookup/零写入 dry-run；隐式旧参数和任何 legacy 写入在兼容引擎执行前拒绝。
- [ ] 同源安全扫描与官方来源报告的 finding 已处理；GitHub commit、annotated tag、Release notes 和 Changelog 一致。
- [ ] ClawHub 本地预备包、registry dry run 和实际发布的证据分别核验；发布后按版本及 `latest` inspect，不以本地包或旧索引宣称已公开安装。

完整命令见 [ClawHub 发布流程](clawhub-release.md)，运行时用法见[命令指南](../../skills/agent-skills-setup/references/cli-workflow.md)。
