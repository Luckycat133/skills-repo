# ClawHub 发布

先确认工作树干净、GitHub 的目标提交可访问，并执行：

```bash
bash validate-all.sh
skillspector scan skills/agent-skills-setup --no-llm
clawhub whoami
```

若未安装 SkillSpector，先用项目规定的隔离方式运行同源扫描，不要跳过安全复核。确认 `SKILL.md` 的版本、权限声明、Changelog 和根镜像一致后，生成发布命令：

```bash
bash scripts/prepare-clawhub-release.sh \
  --skill-dir skills/agent-skills-setup \
  --slug agent-skills-setup \
  --name "Agent Skills Setup" \
  --version <version> \
  --tags latest,setup,skills,openclaw,cross-ide \
  --changelog "<concise release note>"
```

复制脚本输出的 `clawhub publish ...` 命令，为它补充 `--source-repo`、`--source-commit`、`--source-ref`、`--source-path` 和 `--dry-run --json`；不要把这些参数传给辅助脚本。记录 dry run 返回的 `would-publish`、版本、文件数和 fingerprint。确认预览与已核验提交一致后，移除 `--dry-run`，以其余参数不变的同一条底层命令正式发布。

发布后分别运行：

```bash
clawhub inspect agent-skills-setup --version <version>
clawhub inspect agent-skills-setup --tag latest
clawhub inspect agent-skills-setup --versions --limit 5
```

只有定向版本查询和 `latest` 都显示新版本，才报告公开发布完成。检查页面、`SKILL.md` 渲染、权限、安全状态和发行说明链接；索引延迟时报告“发布已接收、尚未公开可见”。

浏览器登录后出现 `fetch failed` 通常是本地回调问题：在同一终端重试，检查 VPN、代理或防火墙对 `127.0.0.1` 的影响；可用时改用 `clawhub login --token <token>`，并先执行 `clawhub whoami`。
