# ClawHub 发布

先执行 `clawhub login`，确认技能目录含有效 `SKILL.md`，且发布版本与其 `version:` 一致。先生成并检查命令：

```bash
bash scripts/prepare-clawhub-release.sh \
  --skill-dir skills/agent-skills-setup \
  --slug agent-skills-setup \
  --name "Agent Skills Setup" \
  --version <version> \
  --tags latest,setup,skills,openclaw,cross-ide \
  --changelog "<concise release note>"
```

确认后为同一命令追加 `--publish`。发布后运行 `clawhub inspect agent-skills-setup`，检查页面、`SKILL.md` 渲染和 README/发行说明链接。

浏览器登录后出现 `fetch failed` 通常是本地回调问题：在同一终端重试，检查 VPN、代理或防火墙对 `127.0.0.1` 的影响；可用时改用 `clawhub login --token <token>`，并先执行 `clawhub whoami`。
