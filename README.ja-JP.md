# Agent Skills Setup

[English](README.md) · [中文](README.zh-CN.md) · [Español](README.es.md)

`agent-skills-setup` は既存の AI コーディングエージェント向けの移植可能な
[Agent Skill](https://agentskills.io/specification) です。ルール・指示、Agent Skills、
MCP サーバー定義、コマンド、カスタムエージェント、フック、ユーザー作成メモリ、および
API キー / `.env` シークレットを、**平文の秘密値を LLM のプロンプトコンテキストに露出させずに**
IDE・CLI・PC 間で移行・変換します。

## ゼロ・コンテキスト漏洩設計

- **Agent-First + 依存ゼロ標準ライブラリスクリプト**: 簡潔な `SKILL.md`、段階的リファレンス
  (`references/`)、テンプレート (`assets/`)、および Python 3.11+ 標準ライブラリスクリプト
  (`skills/agent-skills-setup/scripts/migrate_context.py`) のみを配布します。旧 `.acb`
  バンドルエンジン、署名サービス、常駐デーモンは含みません。
- **アウトオブバンド `0700`/`0600` シークレット移行**: デフォルトで MCP 認証情報や `.env*` を
  ディスク間で直接 `0600` 権限で書き込み（変更前バックアップも `0600`）、Git 管理下ファイルへの
  意図しない秘密値書き込みを拒否し、`stdout` や `MIGRATION.md` には変数名と `sha256[:8]`
  のみを出力します。秘密値を伏せる場合は `--redact-secrets` を指定します。
- **90 プロファイルの段階的カタログ**: 15 の組み込みプロファイルに加え、75 以上のツールを
  `references/products.md` と `patch-mcp` でルーティングします（調査日: 2026-11-07。
  ドキュメント上の整理であり、全 IDE の実機動作保証ではありません）。

クライアントの公式 Skills ディレクトリには `skills/agent-skills-setup/` のみを配置してください。
ソース版 `0.11.1` の検証状況は [docs/validation-status.md](docs/validation-status.md) を参照してください。

[コントリビュート](CONTRIBUTING.md) · [セキュリティ](SECURITY.md) · [ライセンス (MIT)](LICENSE)
