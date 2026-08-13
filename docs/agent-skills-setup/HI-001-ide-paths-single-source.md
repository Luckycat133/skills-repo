# HI-001：IDE 路径单一来源

Registry v2 已成为产品/profile/surface 与 support contract 的权威契约。`references/ide-paths.json` 仅为旧参数接口生成每 IDE 参考摘要和 `scripts/ide-paths.tsv` 兼容解析表；新 CLI 直接解析 `registry-v2.json`。公开 wrapper 只把查询和零写入 dry-run 交给旧 Bash 引擎；任何 legacy `--yes` 都会先被拒绝，公开写入只能应用已保存的 Registry v2 plan。

修改路径时更新 JSON，运行 `python3 skills/agent-skills-setup/scripts/sync-ide-reference-summaries.py --paths skills/agent-skills-setup/references/ide-paths.json --references skills/agent-skills-setup/references/ides --resolver skills/agent-skills-setup/scripts/ide-paths.tsv`，再运行 `bash validate-all.sh`。不要手改 `<!-- GENERATED -->` 区块或 TSV。
