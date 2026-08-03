---
name: agent-skills-setup
version: 0.7.0
license: MIT
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
2. Resolve both IDs in [ide-registry.md](references/ide-registry.md), then read
   only [references/ides/<source>.md](references/ides/) and
   [references/ides/<target>.md](references/ides/). Use
   [ide-paths.json](references/ide-paths.json) or `--print-path` for paths.
3. Load only the needed reference:

| Situation | Read |
| --- | --- |
| Before preview or apply | [migration-safety.md](references/migration-safety.md) |
| `mcp`, `project-mcp`, or `--source-mcp-file` | [mcp-migration.md](references/mcp-migration.md) |
| Any other file-backed object | [object-migration.md](references/object-migration.md) |
| Approved apply or proof | [verification.md](references/verification.md) |

The per-IDE reference describes product behavior; the script describes what is
automated. Flag a mismatch before applying.

## Safety and execution

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

Run `bash scripts/smart-ide-migration.sh --help` for flags. Commands run from
this Skill directory.

~~~bash
bash scripts/smart-ide-migration.sh --print-path cursor project-mcp

bash scripts/smart-ide-migration.sh \
  --source cursor --target claude --workspace /path/to/project \
  --objects skills,rules --scope project --dry-run
~~~
