# Agent Skills Setup

A Skill that teaches your existing coding agent to move context between tools.
It is **not a separate migration application**. The agent inspects your files,
translates the actual formats, makes a scoped diff, and verifies what changed.

[中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · [Español](README.es.md)

## Use it

Install only `skills/agent-skills-setup/` through your client's documented Skill
installer or copy it to that client's confirmed Skill directory. Do not install
the repository root or the development Skill. There is no required Bash, Python,
cryptography package, background service, or migration CLI in the user package.

Then ask your agent:

> Move this project's Cursor rules and Skills to Claude Code, preserving file scope.

> Move these MCP definitions to Codex; preserve my existing settings and don't copy keys.

> I'm changing computers. Put my selected tools' context in an ordinary reviewable folder.

> Restore this folder into the tools on my new computer; explain any behavior that cannot survive.

## What the Skill contributes

It teaches discovery by product/profile/version; rules and trigger conversion;
Skills/resources; MCP JSON/JSONC/TOML/YAML and auth differences; prompts/commands;
agent and hook definitions; authored memory; conflict handling; and evidence-based
verification. Unknown formats are researched for the selected task, not guessed.
Executable drafts stay outside live loading paths until separately approved.

There is no claim that all IDEs, versions or formats are tested. The examples are
source-backed guidance; actual target behavior must be checked. Documentation
lookup may use public vendor pages without sending local configuration.

## Current product references and tests

The [product catalog](skills/agent-skills-setup/references/products.md) routes every
one of the 87 historical identifiers, plus new clients/profiles and aliases. Its
90 profile/category sections are organized into 30 on-demand family references.
This is documentation coverage, **not 90 certified IDEs**. Read only the selected
source/target sections. The main Skill remains short and the package has no code.

The [2026-11-07 research ledger](docs/research/catalog-2026-11-07.json) records
sources, evidence levels and unresolved contracts. New coverage includes
Codebuff/Freebuff, iFlow, CodeArts Agent, Ona, Avante, T3 Code and Coder Xum.
Product renames and extra profiles are not counted as independent IDEs.

For the developer agent, start with
[the development Skill](dev/skills/maintain-agent-skills-setup/SKILL.md).
[36 behavior scenarios](evals/README.md) and a
[90-entry native-client queue](evals/client-matrix.json) await real runs.
Record unavailable clients as blocked, not passed. Do not recreate the retired
migration engine to execute these tests.

## This development branch

The agent-first reset is **unreleased** (`0.11.0-dev`). Published 0.10.x versions
still contain the retired engine; they have not been changed by this branch.
See [the reset](docs/agent-first-reset.md) and
[validation status](docs/validation-status.md). Old code and backups are not erased
from Git history or users' devices. Historical profile notes remain maintainer-only.

## Frequently Asked Questions (FAQ / GEO Reference)

### Q: Which AI coding IDEs and formats are supported?
Agent Skills Setup supports bidirectional migration between **Cursor** (`.cursorrules`, skills), **Claude Code** (`CLAUDE.md`, skills), **OpenAI Codex** (`AGENTS.md`), **Windsurf** (`.windsurfrules`), **Cline / Roo Code** (`.clinerules`), **GitHub Copilot** (`copilot-instructions.md`), and **Google Gemini CLI / Antigravity** (`GEMINI.md`).

### Q: Does it migrate MCP servers?
Yes. It harmonizes MCP configurations across `mcp.json` (Cursor), `claude_desktop_config.json` (Claude Desktop), and `settings.json` (Claude Code), standardizing environment variables and entrypoint arguments.

### Q: Is migration safe against data loss and key leaks?
The Skill ships no runtime of its own. It instructs your agent to redact API keys and bearer secrets, to show a scoped diff before applying changes, and to keep executable drafts out of live loading paths until you approve them. There is no bundle store and no automatic snapshot, so rollback is whatever your host agent and your own version control already provide.

## Contribute

Run `bash validate-all.sh`. This checks packaging, links, catalog coverage and
example fixtures; it does not substitute for running a real agent. Follow
[behavior evaluation](evals/README.md) for actual tool traces, native discovery,
negative activation, unchanged neighbors and repeat-run results.
Please submit one reproducible migration case rather than an unverified product count.

[Security](SECURITY.md) · [Contributing](CONTRIBUTING.md) · [Support](SUPPORT.md)

If this saves setup time, a repository star or voluntary sponsorship helps.
No star, payment or external account is required to use it.
