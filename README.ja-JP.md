# スキルリポジトリ

> ステータス: 開発進行中 · 正規スキルソース

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/openclaw.md)

> 🌐 Languages: [English](README.md) · [中文](README.zh-CN.md) · **日本語** · [Español](README.es.md)

AI アシスタント機能（旧称 skills）を、ローカル優先の執筆ワークフローと、公開に向けた実践的な手順とともに提供します。

## インストール

エージェント環境に `agent-skills-setup` スキルをインストールします。

**ClawHub (OpenClaw-native)**

```bash
openclaw skills install @luckycat133/agent-skills-setup
```

**skills.sh（クロスエージェント、Vercel）**

```bash
npx skills add Luckycat133/skills-repo
```

ソースリポジトリ: [Luckycat133/skills-repo](https://github.com/Luckycat133/skills-repo)

## 目次

- [概要](#概要)
- [インストール](#インストール)
- [構成](#構成)
- [規約](#規約)
- [現在の機能モジュール](#現在の機能モジュール)
- [開発ワークフロー](#開発ワークフロー)
- [スキルのインポート](#スキルのインポート)
- [オープンソースメタデータ](#オープンソースメタデータ)
- [公開](#公開)

## 概要

| Language | Summary |
| --- | --- |
| 日本語 | ローカル優先のワークフロー、OpenClaw 自動化、公開配布の手引きを通じて、再利用可能なエージェントスキルを構築・公開します。 |

## 構成

```text
skills-repo/
├── README.md
├── docs/
│   └── agent-skills-setup/
├── scripts/
└── skills/
    └── agent-skills-setup/
```

## 規約

- `skills/` は公開可能なスキルフォルダを格納します。
- `docs/` は開発メモ、リリース計画、検証メモ、メンテナンスチェックリストを格納します。
- GitHub の `main` ブランチが正規の情報源（単一の真実）です。インストール済みのコピーは編集しないでください。
- プロダクト固有のスキルは、それぞれの正規のプロダクトリポジトリに置きます。

## 現在の機能モジュール

- `agent-skills-setup`: マルチエージェント機能のインストール、同期、OpenClaw 自動化、および公開ワークフロー。

クロス IDE 移行の対象範囲には、機能、プロンプト、設定、ルール、ワークフローが含まれるようになりました。

現在カバーしている主流の IDE エコシステムは 40 の IDE およびエージェント（Copilot、Cursor、Windsurf、JetBrains、Claude Code、Claude Desktop、Codex、OpenClaw、Trae、Trae CN、Antigravity、Kimi AI、Amazon Q、Gemini CLI、Zed、VS Code、Goose CLI、OpenCode、Continue、Roo Code、Cline、Kilo Code、Kiro、Augment Code、Baidu Comate、Tencent CodeBuddy、ZCode、Void Editor、Aider、Tabnine、Replit、Blackbox、Neovim、Emacs、Cody、Supermaven、Codeium、PearAI、Pieces）です。

## 開発ワークフロー

1. GitHub のブランチ上で `skills/` 配下のスキルを編集します。
2. `bash validate-all.sh` を実行します。
3. `agent-skills-setup` の変更については、以下の焦点を絞った検証スイートも実行します。
   - `bash skills/agent-skills-setup/scripts/verify-ide-config.sh` — 解決された IDE パスが `references/ide-registry.md` と一致することを検証します（215 件のチェック）。
   - `bash skills/agent-skills-setup/scripts/test-ide-paths.sh` — `references/ide-paths.json` とスクリプト間のドリフト（乖離）テストを行います（415 件のチェック）。
   - `bash skills/agent-skills-setup/scripts/test-migration.sh` — 移行およびグローバル同期エンジンのテストを行います（80 件のチェック、分離された一時 HOME）。
4. 検証ワークフローが通過してからのみ、マージします。
5. マージ済みのバージョンをエージェント環境にインストールします。

```bash
bash install.sh
bash sync-to-codex.sh
bash sync-to-openclaw.sh
```

既存のターゲットがサイレントに上書きされることはありません。`--force` を指定するのは、インストーラーに現在のコピーをタイムスタンプ付きのバックアップへ移動させて置き換えたい場合のみにしてください。

## スキルのインポート

レガシーなインポートヘルパーは、外部のスキルをレビューブランチに取り込むためだけに使います。インポートした内容は、検証とマージが行われるまで正規のものではありません。

同梱のインポートスクリプトを使用します。

```bash
bash scripts/import-agent-skill.sh \
    ~/.gemini/antigravity/skills/agent-skills-setup \
    agent-skills-setup
```

## オープンソースメタデータ

- ライセンス: MIT
- コントリビューション: `CONTRIBUTING.md` を参照
- セキュリティ報告: `SECURITY.md` を参照
- コミュニティの期待: `CODE_OF_CONDUCT.md` を参照

## 公開

このリポジトリは、プライベートなローカル開発と公開配布の両方をサポートするように設計されています。

現在の配布チャネル:

- 正規の公開ソースとしての GitHub リポジトリ。
- OpenClaw ネイティブな公開とバージョン管理された更新のための ClawHub。
- クロスエージェントな発見のための `skills.sh`。
- 厳選された Copilot の露出のための `github/awesome-copilot`。

公開前に、`bash validate-all.sh` を実行し、`THIRD_PARTY_NOTICES.md` を確認し、リポジトリにプライベートなパス、ローカルのシークレット、またはマシン固有の前提が含まれていないことを確認してください。
