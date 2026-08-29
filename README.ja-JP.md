# Agent Context Migrator (エージェントコンテキスト移行ツール)

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: [English](README.md) · [中文](README.zh-CN.md) · **日本語** · [Español](README.es.md)

**Cursor、Claude Code、Codex、Cline、Windsurf、Copilot、Gemini CLI** など、多数の AI コーディングツール間で Skills、ルール/指示、MCP 設定を**オフライン・プレビュー可能・ロールバック安全**に移行・バックアップ・復元します。

---

## ⚡ クイックインストール

ClawHub / OpenClaw からインストール:

```bash
openclaw skills install @luckycat133/agent-skills-setup
```

または GitHub から直接インストール:

```bash
git clone --depth 1 --branch v0.9.1 https://github.com/Luckycat133/skills-repo.git

openclaw skills install \
  ./skills-repo/skills/agent-skills-setup \
  --as agent-skills-setup
```

---

## 💬 エージェントへの指示例

> *"このプロジェクトの Cursor の Skills、ルール、MCP を Claude Code に移行して。"*

> *"PC を移行するので、インストール済み IDE の AI コーディング設定をバックアップして。"*

> *"この ACB バンドルを新しい PC のインストール済み IDE に復元して。"*

---

## 🛡️ 移行の安全境界

| 区分 | 対象 | 動作 |
|---|---|---|
| **自動移行** | Skills、Instructions/Rules (`CLAUDE.md`, `.cursorrules`)、ローカル stdio MCP | Skills の検証付き複製、指示のセマンティック変換と損失レポート、ローカル stdio MCP のサブセット自動変換。 |
| **明示的オプトイン** | プラグインパッケージ複製 (`--include-plugins`)、セッション引き継ぎ要約 (`--include-session`) | 構造化ホワイトリストと同意に基づき処理。 |
| **手動チェックリスト** | リモート MCP (HTTP/SSE)、クラウド/UI 設定、Prompts、Commands、Agents、Hooks | 具体的な再構築手順を出力（未検証の実行可能スクリプトは自動書き込みしません）。 |
| **移行対象外** | API キー、OAuth トークン、資格情報、信頼状態、会話履歴、生成メモリ | 厳格なシークレットスキャン、サブオブジェクト分離、Fail-closed 除外；平文の機密情報は移行前に自動除外・マスキング。 |

---

## 🚀 主なコマンド

- **`migrate`**: ワンステップ移行: `detect` -> `inventory` -> `plan` -> `apply` -> `verify`。
- **`snapshot`**: 1:1 マニフェストファイルバインディングを備えたアトミックでポータブルな **Agent Context Bundle (ACB)** を取得。
- **`restore`**: ACB バンドルからターゲット環境への二者間復元プランを生成し、TOCTOU ガード付きで実行。
- **`bundle-sign` & `bundle-verify`**: Ed25519 暗号鍵で ACB バンドルに署名・検証。
- **`doctor`**: バンドルの依存関係と不足しているツールをオフラインで診断。

---

## 🌟 プロジェクトの支援

Agent Context Migrator が環境構築や PC 移行の手間を省く役に立った場合は、ぜひ ⭐ **GitHub で Star をお願いします**！

[GitHub Sponsors](https://github.com/sponsors/Luckycat133) や [Afdian / Ko-fi](https://afdian.com/a/Luckycat133) からの開発支援も歓迎しています。

---

## 構成

```text
skills-repo/
├── docs/                         # 現行の保守資料・リリースチェックリスト
├── scripts/                      # リポジトリ用検証ツール
└── skills/agent-skills-setup/    # 公開 Skill の正本
    ├── SKILL.md                  # Skill 定義・エントリーポイント
    ├── references/               # Profile 登録表 v2・アダプター仕様
    └── scripts/                  # 移行コアエンジン・ACB ツール
```

## 開発と検証

1. `skills/agent-skills-setup/` を編集し、生成されたルートのリポジトリポインターは編集しません。
2. `bash validate-all.sh` を実行します。
3. 正本の Skill を変えたら `bash scripts/sync-root-mirror.sh` でルートポインターを更新します。
4. すべての検証が通過した後にマージします。

## プロジェクト資料

- [貢献ガイド](CONTRIBUTING.md)
- [セキュリティ](SECURITY.md)
- [行動規範](CODE_OF_CONDUCT.md)
- [ライセンス](LICENSE)

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Code of conduct](CODE_OF_CONDUCT.md)
- [License](LICENSE)
