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

Scoped migration of selected assistant context between product profiles. Registry v2 records lifecycle, version, source, scope, storage, and per-surface policy; legacy, cloud, provider, host-editor, and alias entries are deliberately not ordinary write targets. See the [IDE registry](skills/agent-skills-setup/references/ide-registry.md).

The runtime package contains references plus one migration command. It does not
install IDEs or runtimes, create symlinks, maintain registry locks, or copy
itself into agent directories. Global migrations default to Skills only;
project-backed objects use an explicit workspace.
Before a Skill directory is copied, all source text is scanned; a likely
literal credential or link outside the Skill rejects that Skill without
changing its source or existing target.
The canonical frontmatter uses only standard Agent Skills fields. The
profile-aware CLI provides `detect`, `inventory`, `plan`, `apply`, `verify`, and
`rollback`; instructions pass through native-format adapters and a typed IR
with a loss report, and apply accepts only a saved, checksummed plan. It stages
the full operation, creates exact backups, rolls back all earlier writes on
failure, and emits a checksummed verification manifest only after success.
Generic migration requests authorize planning only; `apply` and `rollback`
require separate explicit approval. Legacy lookup and zero-write dry-runs are
available only through the explicit `legacy` subcommand.
Reviewed subsets are labeled `partial`, not
`full`; remote MCP without a target transport adapter, unsupported
JSON5/TOML/YAML/XML/Lua formats, and cloud/UI products produce explicit manual
reconstruction actions instead of generic conversion.

## Develop

1. Edit `skills/agent-skills-setup/`, never the generated root repository pointer.
2. Run `bash validate-all.sh`.
3. Regenerate the root pointer after canonical-skill edits: `bash scripts/sync-root-mirror.sh`.
4. Merge only after validation.

To review an external skill, use `bash scripts/import-agent-skill.sh <source-dir> <skill-name>` in a branch.

## Release

GitHub is canonical; ClawHub and Awesome Copilot are distribution channels. The repository remains MIT; the generated ClawHub bundle is separately MIT-0, omits a conflicting per-Skill license, declares Bash/Python requirements, and cannot be published until contributor authorization is explicitly acknowledged. See the [release checklist](docs/agent-skills-setup/release-checklist.md).

## Project

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Code of conduct](CODE_OF_CONDUCT.md)
- [License](LICENSE)
