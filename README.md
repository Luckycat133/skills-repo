# Skills Repository

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: **English** · [中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · [Español](README.es.md)

Reusable AI-assistant skills, authored locally and published from GitHub.

## Install

```bash
# OpenClaw
openclaw skills install @luckycat133/agent-skills-setup

# skills.sh
npx skills add Luckycat133/skills-repo
```

## Layout

```text
skills-repo/
├── docs/                         # active maintainer guidance
├── scripts/                      # repository tooling
└── skills/agent-skills-setup/    # canonical publishable skill
    ├── SKILL.md
    ├── references/
    └── scripts/
```

## `agent-skills-setup`

Consent-gated migration of selected assistant context between supported IDEs and agents. It handles documented skills, rules, prompts, and MCP objects; whole IDE configuration and opaque project trees stay manual. See the [IDE registry](skills/agent-skills-setup/references/ide-registry.md) for the 40 supported identifiers.

## Develop

1. Edit `skills/agent-skills-setup/`, never the generated root `SKILL.md`.
2. Run `bash validate-all.sh`.
3. Regenerate the root mirror after canonical-skill edits: `bash scripts/sync-root-mirror.sh`.
4. Merge only after validation, then install with `bash install.sh` or a target-specific sync script.

Existing targets are preserved unless `--force` explicitly requests a timestamped backup and replacement. To review an external skill, use `bash scripts/import-agent-skill.sh <source-dir> <skill-name>` in a branch.

## Release

GitHub is canonical; ClawHub, `skills.sh`, and Awesome Copilot are distribution channels. Before release, run validation, review `THIRD_PARTY_NOTICES.md`, and remove private paths, secrets, and machine-specific assumptions.

## Project

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Code of conduct](CODE_OF_CONDUCT.md)
- [License](LICENSE)
