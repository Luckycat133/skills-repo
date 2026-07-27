# {{SKILL_NAME}}

[![GitHub](https://img.shields.io/badge/GitHub-{{REPO_NAME}}-181717?logo=github)](https://github.com/{{REPO_NAME}})
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> 🌐 Languages: **English** · [中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · [Español](README.es.md)

Reusable multi-agent skill for Antigravity, Claude Code, OpenAI Codex, GitHub Copilot, Trae, OpenClaw, and related tooling.

## At A Glance

A publishable skill repository template with install guidance and multi-agent compatibility notes.

## Table Of Contents

- [What It Does](#what-it-does)
- [Supported Agents](#supported-agents)
- [Repository Layout](#repository-layout)
- [Install](#install)
- [Example Prompts](#example-prompts)
- [Notes](#notes)

## What It Does

Describe the exact workflow or capability this skill adds.

## Supported Agents

- Antigravity
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Trae
- Trae CN
- OpenClaw

Adjust this list if the skill only supports a subset.

## Repository Layout

```text
.
├── README.md
└── {{SKILL_NAME}}/
    ├── SKILL.md
    ├── scripts/
    ├── references/
    └── assets/
```

## Install

### skills.sh CLI

```bash
npx skills add {{REPO_NAME}}
```

### ClawHub

```bash
clawhub publish ./{{SKILL_NAME}} --slug {{SKILL_NAME}} --name "{{SKILL_NAME}}" --version 1.0.0 --tags latest
```

### Manual Install

Copy the `{{SKILL_NAME}}/` folder into the appropriate global or project-level skills directory for your agent.

## Example Prompts

- Add practical prompt examples here.
- Explain when the skill should be invoked.

## Notes

- Replace any local-only assumptions before publishing.
- Document OS or shell requirements for bundled scripts.
- Add a license before publishing publicly.

<!--
LOCALIZATION — multi-file, big-repo style (do NOT inline other languages):

This file is the English primary (README.md). Each language lives in its own
sibling file; readers switch via the language row at the top of every file.

File tree to publish:
.
├── README.md          (English — this file)
├── README.zh-CN.md   (中文)
├── README.ja-JP.md   (日本語)
└── README.es.md       (Español)

To add a translation:
  1. Copy this file to README.<lang>.md (e.g. README.zh-CN.md).
  2. Translate the body; keep the structure/anchors.
  3. Replace the top language row so the CURRENT language is bold and
     every language links to its file:

     > 🌐 Languages: [English](README.md) · **中文** · [日本語](README.ja-JP.md) · [Español](README.es.md)

Keep the switcher identical (same links) across all language files so readers
can jump between them from any entry point.
-->
