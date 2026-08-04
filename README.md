# Skills Repository

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: **English** · [中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · [Español](README.es.md)

Reusable AI-assistant skills, authored locally and published from GitHub.

## Use

Install `agent-skills-setup` through the current agent's own Skill manager or
ClawHub. The repository does not provide a cross-agent installer. Installation
only makes the references and migration script available to that agent.
Installation has no IDE target: `--source`, `--target`, `--objects`, and
`--workspace` belong to a later migration command run by the agent.

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

Scoped migration of selected assistant context between supported IDEs and agents. It handles documented skills, rules, prompts, and MCP objects; whole IDE configuration and opaque project trees stay manual. See the [IDE registry](skills/agent-skills-setup/references/ide-registry.md) for the 44 script-supported identifiers and documented manual-only surfaces.

The runtime package contains references plus one migration command. It does not
install IDEs or runtimes, create symlinks, maintain registry locks, or copy
itself into agent directories. Global migrations default to Skills only;
project-backed objects use an explicit workspace.
Before a Skill directory is copied, all source text is scanned; a likely
literal credential or link outside the Skill rejects that Skill without
changing its source or existing target.
The Skill metadata declares only local file-read, file-write, and shell
capabilities, and its trigger describes migration between two named supported
products.
Project rules and prompt targets use the selected conflict strategy, defaulting
to a backup before copy.

## Develop

1. Edit `skills/agent-skills-setup/`, never the generated root `SKILL.md`.
2. Run `bash validate-all.sh`.
3. Regenerate the root mirror after canonical-skill edits: `bash scripts/sync-root-mirror.sh`.
4. Merge only after validation.

To review an external skill, use `bash scripts/import-agent-skill.sh <source-dir> <skill-name>` in a branch.

## Release

GitHub is canonical; ClawHub and Awesome Copilot are distribution channels. Before release, run the full suite and security scan, push and verify the GitHub commit, then require a successful ClawHub dry run before publishing. See the [release checklist](docs/agent-skills-setup/release-checklist.md).

## Project

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Code of conduct](CODE_OF_CONDUCT.md)
- [License](LICENSE)
