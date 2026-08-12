# スキルリポジトリ

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: [English](README.md) · [中文](README.zh-CN.md) · **日本語** · [Español](README.es.md)

ローカルで作成し、GitHub から公開する再利用可能な AI アシスタントスキルです。

## 利用方法

現在のエージェント自身の Skill 管理機能または ClawHub から `agent-skills-setup` を導入します。このリポジトリはクロスエージェント用インストーラーを提供せず、導入先のエージェントに参照資料と移行スクリプトだけを提供します。
導入時に IDE は選びません。`--source`、`--target`、`--objects`、`--workspace` は、後でエージェントが実行する移行コマンドの引数です。

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

製品 profile 間で対象範囲を明確にしてコンテキストを移行します。Registry v2 は lifecycle、version、source、scope、storage、surface ごとの policy を保持し、legacy、cloud、provider、host-editor、alias を通常の書き込み先として扱いません。[IDE registry](skills/agent-skills-setup/references/ide-registry.md) を参照してください。

実行パッケージに含まれるのは参照資料と 1 つの移行コマンドだけです。IDE やランタイムの導入、シンボリックリンクやレジストリロックの作成、各エージェントディレクトリへの自己コピーは行いません。global 移行の既定対象は Skills のみで、project オブジェクトにはコマンドで明示した workspace を使います。
Skill ディレクトリをコピーする前にすべてのソーステキストを検査し、リテラル資格情報の疑いまたは Skill 外へのリンクがあれば、ソースと既存ターゲットを変更せずにその Skill をスキップします。
正本 frontmatter は Agent Skills の標準フィールドだけを使います。profile-aware CLI は `detect`、`inventory`、`plan`、`apply`、`verify`、`rollback` を提供し、instructions は loss report 付きの型付き IR を通り、apply は正確なバックアップと検証 manifest を作成します。

## 開発

1. `skills/agent-skills-setup/` を編集し、生成されたルートのリポジトリポインターは編集しません。
2. `bash validate-all.sh` を実行します。
3. 正本の Skill を変えたら `bash scripts/sync-root-mirror.sh` でルートポインターを更新します。
4. 検証後にマージします。

外部 Skill はブランチで `bash scripts/import-agent-skill.sh <source-dir> <skill-name>` を使って確認します。

## 公開

GitHub が正本で、ClawHub と Awesome Copilot は配布経路です。リポジトリは MIT を維持し、生成する ClawHub bundle だけを MIT-0 として競合ライセンスを除去し、Bash/Python 要件を宣言します。公開には contributor authorization の明示確認が必要です。[公開チェックリスト](docs/agent-skills-setup/release-checklist.md)も参照してください。

## プロジェクト

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Code of conduct](CODE_OF_CONDUCT.md)
- [License](LICENSE)
