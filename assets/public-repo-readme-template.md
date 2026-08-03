# {{SKILL_NAME}}

[![GitHub](https://img.shields.io/badge/GitHub-{{REPO_NAME}}-181717?logo=github)](https://github.com/{{REPO_NAME}})
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> Languages: **English** · [中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · [Español](README.es.md)

One sentence: the specific workflow this skill provides and when to use it.

## Install

```bash
npx skills add {{REPO_NAME}}
clawhub publish ./{{SKILL_NAME}} --slug {{SKILL_NAME}} --name "{{SKILL_NAME}}" --version 1.0.0 --tags latest --source-repo <owner/repo> --source-commit <sha> --source-ref main --source-path <path> --dry-run --json
```

For manual installation, copy `{{SKILL_NAME}}/` to the selected agent's global or project skills directory.

## Layout

```text
{{SKILL_NAME}}/
├── SKILL.md
├── scripts/
├── references/
└── assets/
```

## Before release

- Replace local assumptions and document OS/shell requirements.
- Add a license, install example, and invocation examples.
- Keep translations in sibling `README.<lang>.md` files with the same language switcher.
