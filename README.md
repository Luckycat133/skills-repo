# Agent Context Migrator

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: **English** · [中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · [Español](README.es.md)

Offline, previewed, and rollback-safe migration of AI coding context (Skills, Rules, Instructions, and MCP) across **Cursor, Claude Code, Codex, Cline, Windsurf, Copilot, Gemini CLI**, and dozens of supported AI coding tools.

---

## ⚡ Quick Install

Install `agent-skills-setup` via ClawHub / OpenClaw:

```bash
openclaw skills install @luckycat133/agent-skills-setup
```

Or install directly from GitHub:

```bash
git clone --depth 1 --branch v0.9.1 https://github.com/Luckycat133/skills-repo.git

openclaw skills install \
  ./skills-repo/skills/agent-skills-setup \
  --as agent-skills-setup
```

---

## 💬 Say this to your agent

> *"Migrate Skills, rules, and MCP from Cursor in this project to Claude Code."*

> *"I am switching computers. Back up all portable AI coding setup from my installed IDEs."*

> *"Restore this ACB bundle to the installed IDEs on my new computer."*

---

## 🛡️ Migration Boundary

| Tier | Items | Behavior |
|---|---|---|
| **Automatic** | Skills, Instructions/Rules (`CLAUDE.md`, `.cursorrules`), Local stdio MCP | Verified copy for Skills, semantic conversion for instructions, and supported local stdio MCP subset conversion. |
| **Explicit Opt-in** | Plugin package copy (`--include-plugins`), Session handoff summary (`--include-session`) | Preserved with structured whitelisting and consent. |
| **Manual Checklist** | Remote MCP (HTTP/SSE), Cloud/UI configurations, Prompts, Commands, Agents, Hooks | Emits concrete reconstruction checklists; never writes unreviewed executable scripts. |
| **Never Moved** | API keys, OAuth tokens, credentials, trust state, raw chat history, generated memory | Strict secret scanning, subobject isolation, and fail-closed exclusions. Literal credentials are rejected or redacted before migration. |

---

## 🚀 Capabilities

- **`migrate`**: One-sentence flow: `detect` -> `inventory` -> `plan` -> `apply` -> `verify`.
- **`snapshot`**: Capture an atomic, portable **Agent Context Bundle (ACB)** with 1:1 manifest file binding.
- **`restore`**: Dual-side restore planning from ACB bundles onto newly installed target tools with TOCTOU state guards.
- **`bundle-sign` & `bundle-verify`**: Sign and verify ACB bundles with Ed25519 cryptographic keys.
- **`doctor`**: Inspect bundle requirements and missing dependencies offline.

---

## 🌟 Support the Project

If Agent Context Migrator saved you setup or computer-switching time, please ⭐ **Star this repository on GitHub** to help other developers discover it!

You can also sponsor development through [GitHub Sponsors](https://github.com/sponsors/Luckycat133) or [Afdian / Ko-fi](https://afdian.com/a/Luckycat133).

---

## Layout

```text
skills-repo/
├── docs/                         # Maintainer guidance & release checklists
├── scripts/                      # Repository tooling
└── skills/agent-skills-setup/    # Canonical publishable skill
    ├── SKILL.md                  # Skill descriptor & entry point
    ├── references/               # Profile registry v2 & format adapters
    └── scripts/                  # Context migrator core & ACB engine
```

## Develop & Validate

1. Edit `skills/agent-skills-setup/`, never the generated root repository pointer.
2. Run `bash validate-all.sh`.
3. Regenerate the root pointer after canonical-skill edits: `bash scripts/sync-root-mirror.sh`.
4. Merge only after all validation passes.

## Project

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Code of conduct](CODE_OF_CONDUCT.md)
- [License](LICENSE)
