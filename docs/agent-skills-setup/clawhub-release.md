# ClawHub 发布

先确认工作树干净、GitHub 的目标提交可访问，并执行：

```bash
bash validate-all.sh
skillspector scan skills/agent-skills-setup --no-llm
clawhub whoami
```

若未安装 SkillSpector，先用项目规定的隔离方式运行同源扫描，不要跳过安全复核。确认 canonical `SKILL.md` 的 `metadata.version`、Changelog 和根仓库指针一致后，生成发布命令：

```bash
bash scripts/prepare-clawhub-release.sh \
  --skill-dir skills/agent-skills-setup \
  --package-dir dist/clawhub/agent-skills-setup-<version> \
  --slug agent-skills-setup \
  --name "Agent Skills Setup" \
  --version <version> \
  --tags latest,setup,skills,openclaw,cross-ide \
  --changelog "<concise release note>" \
  --source-repo https://github.com/Luckycat133/skills-repo \
  --source-commit <full-commit-sha> \
  --source-ref main \
  --source-path skills/agent-skills-setup
```

辅助脚本将仓库 MIT canonical Skill 转换成独立 MIT-0 bundle：删除冲突的逐 Skill `license`，写入 ClawHub 版本和 `metadata.openclaw.requires.bins: [bash, python3]`，并按白名单加入薄包装、Python core、legacy 兼容引擎、路径表和源凭据扫描器；eval、测试和维护脚本不会进入发行包。

复制脚本输出的 `clawhub publish ...` 命令，为它补充 `--dry-run --json`，记录返回的 `would-publish`、版本、文件数和 fingerprint。正式发布必须再次向辅助脚本传入同一组来源参数；脚本会拒绝缺少仓库、完整提交 SHA、ref 或仓库内路径的发布。只有维护者已确认历史贡献者允许 MIT-0 再许可时，才可同时加入 `--publish --acknowledge-mit0`。该确认是正式发布阻断条件，不能由测试成功替代。

发布后分别运行：

```bash
clawhub inspect agent-skills-setup --version <version>
clawhub inspect agent-skills-setup --tag latest
clawhub inspect agent-skills-setup --versions --limit 5
```

只有定向版本查询和 `latest` 都显示新版本，才报告公开发布完成。检查页面、`SKILL.md` 渲染、权限、安全状态和发行说明链接；索引延迟时报告“发布已接收、尚未公开可见”。

浏览器登录后出现 `fetch failed` 通常是本地回调问题：在同一终端重试，检查 VPN、代理或防火墙对 `127.0.0.1` 的影响；可用时改用 `clawhub login --token <token>`，并先执行 `clawhub whoami`。
