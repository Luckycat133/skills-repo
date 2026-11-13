# Agent Skills Setup

既存のエージェントが AI 開発ツール間でコンテキストを移すための Skill です。
独立した移行アプリや常駐サービスではありません。

`skills/agent-skills-setup/` のみを、利用クライアントが対応する Skill ディレクトリに
インストールしてください。リポジトリのルートや開発用 Skill は配布対象ではありません。

例：「このプロジェクトの Cursor のルールと Skills を Claude Code に移し、適用範囲を維持して。」

現在の agent-first リセットは未公開の `0.11.0-dev` です。すべての IDE での実機検証を
保証するものではありません。旧エンジンは Git 履歴に残っています。

[English](README.md) · [中文](README.zh-CN.md) · [検証状況](docs/validation-status.md)
