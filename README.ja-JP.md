# スキルリポジトリ

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: [English](README.md) · [中文](README.zh-CN.md) · **日本語** · [Español](README.es.md)

ローカルで作成し、GitHub から公開する再利用可能な AI アシスタントスキルです。

## インストール

```bash
# OpenClaw
openclaw skills install @luckycat133/agent-skills-setup

# skills.sh
npx skills add Luckycat133/skills-repo
```

## 構成

```text
skills-repo/
├── docs/                         # 現行の保守資料
├── scripts/                      # リポジトリ用ツール
└── skills/agent-skills-setup/    # 公開 Skill の正本
    ├── SKILL.md
    ├── references/
    └── scripts/
```

## `agent-skills-setup`

明示的な同意後、対応 IDE とエージェント間で、文書化された skills、rules、prompts、MCP オブジェクトを移行します。IDE 全体の設定と不透明なプロジェクトツリーは手動確認が必要です。44 のスクリプト対応識別子と手動専用サーフェスは [IDE registry](skills/agent-skills-setup/references/ide-registry.md) を参照してください。

バージョン 0.7.1 が宣言するのはローカルのファイル読み取り、ファイル書き込み、shell のみで、ネットワークは使用しません。書き込みには承認済みの `--yes` が必要です。シンボリックリンクの MCP ターゲットは拒否され、削除範囲は正確な移行先または検証済み Skill コピーのルート内に限定されます。

## 開発

1. `skills/agent-skills-setup/` を編集し、生成物の root `SKILL.md` は編集しません。
2. `bash validate-all.sh` を実行します。
3. 正本の Skill を変えたら `bash scripts/sync-root-mirror.sh` を実行します。
4. 検証後にマージし、`bash install.sh` または対象別 sync スクリプトで導入します。

`--force` を明示しない限り既存の対象は保持されます。指定時はタイムスタンプ付きバックアップ後に置換します。外部 Skill はブランチで `bash scripts/import-agent-skill.sh <source-dir> <skill-name>` を使って確認します。

## 公開

GitHub が正本で、ClawHub、`skills.sh`、Awesome Copilot は配布経路です。公開前に全テストとセキュリティスキャンを通し、GitHub のコミットを push・確認してから、ClawHub の dry run で配布物を検証します。[公開チェックリスト](docs/agent-skills-setup/release-checklist.md)も参照してください。

## プロジェクト

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Code of conduct](CODE_OF_CONDUCT.md)
- [License](LICENSE)
