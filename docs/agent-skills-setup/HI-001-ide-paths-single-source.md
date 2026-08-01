# HI-001：IDE 路径单一来源

已实施。`references/ide-paths.json` 是路径契约；它生成每 IDE 参考摘要和 `scripts/ide-paths.tsv` 运行时解析表。`smart-ide-migration.sh` 仅保留产品特有的动态选择。

修改路径时更新 JSON，运行 `python3 skills/agent-skills-setup/scripts/sync-ide-reference-summaries.py --paths skills/agent-skills-setup/references/ide-paths.json --references skills/agent-skills-setup/references/ides --resolver skills/agent-skills-setup/scripts/ide-paths.tsv`，再运行 `bash validate-all.sh`。不要手改 `<!-- GENERATED -->` 区块或 TSV。
