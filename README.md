# Skills Repository

> Status: Active Development · Canonical Skill Source

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/openclaw.md)

> 🌐 Languages: **English** · [中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · [Español](README.es.md)

AI Assistant Capabilities (formerly skills) with a local-first authoring workflow and a practical path to public release.

## Install

Install the `agent-skills-setup` skill into your agent environment:

**ClawHub (OpenClaw-native)**

```bash
openclaw skills install @luckycat133/agent-skills-setup
```

**skills.sh (cross-agent, Vercel)**

```bash
npx skills add Luckycat133/skills-repo
```

Source repository: [Luckycat133/skills-repo](https://github.com/Luckycat133/skills-repo)

## Table Of Contents

- [Quick Summary](#quick-summary)
- [Install](#install)
- [Structure](#structure)
- [Conventions](#conventions)
- [Current Capability Module](#current-capability-module)
- [Development Workflow](#development-workflow)
- [Importing Skills](#importing-skills)
- [Open Source Metadata](#open-source-metadata)
- [Publishing](#publishing)

## Quick Summary

| Language | Summary |
| --- | --- |
| English | Build and release reusable agent skills with a local-first workflow, OpenClaw automation, and public distribution guidance. |

## Structure

```text
skills-repo/
├── README.md
├── docs/
│   └── agent-skills-setup/
├── scripts/
└── skills/
    └── agent-skills-setup/
```

## Conventions

- `skills/` stores publishable skill folders.
- `docs/` stores development notes, release plans, validation notes, and maintenance checklists.
- GitHub `main` is the canonical source of truth; do not edit installed copies.
- Product-specific skills stay with their canonical product repository.

## Current Capability Module

- `agent-skills-setup`: multi-agent capability installation, synchronization, OpenClaw automation, and publishing workflow.

Cross-IDE migration scope now includes capabilities, prompts, configurations, rules, and workflows.

Covered mainstream IDE ecosystems now include 40 IDEs & agents (Copilot, Cursor, Windsurf, JetBrains, Claude Code, Claude Desktop, Codex, OpenClaw, Trae, Trae CN, Antigravity, Kimi AI, Amazon Q, Gemini CLI, Zed, VS Code, Goose CLI, OpenCode, Continue, Roo Code, Cline, Kilo Code, Kiro, Augment Code, Baidu Comate, Tencent CodeBuddy, ZCode, Void Editor, Aider, Tabnine, Replit, Blackbox, Neovim, Emacs, Cody, Supermaven, Codeium, PearAI, Pieces, WorkBuddy).

## Development Workflow

1. Edit the skill under `skills/` in a GitHub branch.
2. Run `bash validate-all.sh`.
3. `validate-all.sh` discovers and executes every colocated focused suite. Use
   `bash validate-all.sh --list-tests` to audit the exact list; useful individual
   entry points include:
   - `bash skills/agent-skills-setup/scripts/verify-ide-config.sh` — asserts resolved IDE paths match `references/ide-registry.md` (235 checks).
   - `bash skills/agent-skills-setup/scripts/test-ide-paths.sh` — drift test between `references/ide-paths.json` and the script (449 checks).
   - `bash skills/agent-skills-setup/scripts/test-migration.sh` — migration + global-sync engine tests (80 checks, isolated temp HOME).
   - `bash skills/agent-skills-setup/scripts/test-mcp-secret-redaction.sh` — literal-secret redaction, explicit MCP source/schema preview, symlink identity, and environment-reference conversion regressions.
4. Merge only after the validation workflow passes.
5. Install the merged version into an agent environment:

```bash
bash install.sh
bash sync-to-codex.sh
bash sync-to-openclaw.sh
```

Existing targets are never overwritten silently. Pass `--force` only when you want the installer to move the current copy to a timestamped backup and replace it.

## Importing Skills

The legacy import helper is only for bringing an external skill into a review branch. Imported content is not canonical until validation and merge.

Use the bundled import script:

```bash
bash scripts/import-agent-skill.sh \
    ~/.gemini/config/skills/agent-skills-setup \
    agent-skills-setup
```

## Open Source Metadata

- License: MIT
- Contributions: see `CONTRIBUTING.md`
- Security reporting: see `SECURITY.md`
- Community expectations: see `CODE_OF_CONDUCT.md`

## Publishing

This repository is designed to support both private local development and public distribution.

Current distribution lanes:

- GitHub repository as the canonical public source.
- ClawHub for OpenClaw-native publishing and versioned updates.
- `skills.sh` for cross-agent discovery.
- The awesome-copilot community list, for curated Copilot visibility (tracked as a separate distribution lane).

Before publishing, run `bash validate-all.sh`, review `THIRD_PARTY_NOTICES.md`, and confirm the repository contains no private paths, local secrets, or machine-specific assumptions.
