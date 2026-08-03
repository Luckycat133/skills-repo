<!--
  MIRROR FILE — not the source of truth.
  Some platforms (e.g. smithery.ai) only scan the repository ROOT for SKILL.md.
  The canonical, maintained copy lives at: skills/agent-skills-setup/SKILL.md
  Regenerate this mirror after editing the canonical with:
    bash scripts/sync-root-mirror.sh
  Repo-relative links (references/, scripts/) are rewritten to
  skills/agent-skills-setup/... so they resolve correctly from the repository root.
-->

---
name: agent-skills-setup
version: 0.7.1
license: MIT
compatibility: Requires local Bash and filesystem read access. Writes are limited to resolved migration targets after explicit approval. Python 3 is required for automatic MCP conversion and redaction. No network access.
permissions:
  - file_read
  - file_write
  - shell
description: >
  Use when a user explicitly asks to migrate, move, transfer, copy, convert, or
  sync AI-assistant context between different IDEs or agents, including skills,
  rules, prompts, commands, or MCP configuration. Preview a scoped change;
  write only after approval. Do not use for explanation, installation,
  debugging, validation, or same-tool copies.
---

# AI IDE Context Migration

Treat similarly named files as incompatible until their paths, schema,
credentials, and conflict rules are checked.

## Route

1. Resolve source, target, objects, scope, and workspace. State a safe obvious
   assumption; otherwise ask one focused question.
2. Resolve both IDs in [ide-registry.md](skills/agent-skills-setup/references/ide-registry.md), then read
   only [references/ides/<source>.md](skills/agent-skills-setup/references/ides/) and
   [references/ides/<target>.md](skills/agent-skills-setup/references/ides/). Use
   [ide-paths.json](skills/agent-skills-setup/references/ide-paths.json) or `--print-path` for paths.
3. Load only the needed reference:

| Situation | Read |
| --- | --- |
| Before preview or apply | [migration-safety.md](skills/agent-skills-setup/references/migration-safety.md) |
| `mcp`, `project-mcp`, or `--source-mcp-file` | [mcp-migration.md](skills/agent-skills-setup/references/mcp-migration.md) |
| Any other file-backed object | [object-migration.md](skills/agent-skills-setup/references/object-migration.md) |
| Approved apply or proof | [verification.md](skills/agent-skills-setup/references/verification.md) |

The per-IDE reference describes product behavior; the script describes what is
automated. Flag a mismatch before applying.

## Safety and execution

- Use filesystem read and shell only for the selected references, path lookup,
  preview, and verification. Use filesystem write only for the approved target
  paths; this Skill needs no network access.
- Inspect only named paths; default to `skills,rules,prompts`.
- Keep whole `config` files and opaque `project` trees manual. Rebuild a
  documented setting or migrate a dedicated supported object.
- Never move secrets, OAuth/session state, runtime metadata, approval grants,
  chat history, databases, or generated memory. Use manual reconstruction when
  redaction or conversion is unclear.
- Claude Desktop app MCP in **Settings → Extensions** and **Settings → Connectors** is UI-managed; do not infer or rewrite it from legacy JSON.
- Run `--dry-run` and report credential handling without claiming completion.
  After approval, rerun the reviewed command with `--yes --json`; report its
  evidence and native target discovery.

## Commands

Run `bash skills/agent-skills-setup/scripts/smart-ide-migration.sh --help` for flags. Commands run from
this Skill directory.

~~~bash
bash skills/agent-skills-setup/scripts/smart-ide-migration.sh --print-path cursor project-mcp

bash skills/agent-skills-setup/scripts/smart-ide-migration.sh \
  --source cursor --target claude --workspace /path/to/project \
  --objects skills,rules --scope project --dry-run
~~~
