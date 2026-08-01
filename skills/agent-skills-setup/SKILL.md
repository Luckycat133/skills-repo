---
name: agent-skills-setup
version: 0.6.12
license: MIT
description: >
  Use when a user explicitly asks to migrate, move, transfer, copy, convert, or
  sync AI-assistant context between different IDEs or agents, including skills,
  rules, prompts, commands, or MCP configuration. Preview a scoped change;
  write only after approval. Do not use for explanation, installation,
  debugging, validation, or same-tool copies.
triggers:
  - migrate mcp config
  - move skills from cursor to claude
  - transfer mcp servers between ide
  - migrate rules from windsurf to cursor
  - copy mcp config to another ide
  - migrate ai context from one ide to another
capabilities:
  - read: user-selected IDE/agent config paths
  - write: file-backed migration objects, gated by dry-run, consent, and strategy
  - exec: local migration and verification scripts
---

# AI IDE Context Migration

Treat similarly named files as incompatible until their paths, schema,
credentials, and conflict rules are checked.

## Route

1. Resolve source, target, objects, scope, and workspace. State a safe obvious
   assumption; otherwise ask one focused question.
2. Read [references/ides/<source>.md](references/ides/) and
   [references/ides/<target>.md](references/ides/). Use
   [ide-paths.json](references/ide-paths.json) or
   `bash scripts/smart-ide-migration.sh --print-path` for a path lookup.
   `iflycode` and `raccoon-ai` share the reference linked from
   [ide-registry.md](references/ide-registry.md).
3. Load only the needed reference:

| Situation | Read |
| --- | --- |
| Before preview or apply | [migration-safety.md](references/migration-safety.md) |
| `mcp`, `project-mcp`, or `--source-mcp-file` | [mcp-migration.md](references/mcp-migration.md) |
| Any other file-backed object | [object-migration.md](references/object-migration.md) |
| Approved apply or proof | [verification.md](references/verification.md) |

The per-IDE reference describes product behavior; the script describes what is
automated. Flag a mismatch before applying.

## Recommendations

Apply these recommendations to the approved scope and risk.

- Inspect only named paths; default to `skills,rules,prompts`.
- Keep whole `config` files and opaque `project` trees manual. Rebuild a
  documented setting or migrate a dedicated supported object.
- Never move secrets, OAuth/session state, runtime metadata, approval grants,
  chat history, databases, or generated memory. Use manual reconstruction when
  redaction or conversion is unclear.
- Claude Desktop app MCP in **Settings → Extensions** and **Settings → Connectors** is UI-managed; do not infer or rewrite it from legacy JSON.
- Offer value-free `--dry-run`; use `--yes` only after approval and normally
  add `--json` for evidence.

## Workflow

1. Plan paths, objects, boundaries, and strategy.
2. Run `--dry-run`; report credential handling without claiming completion.
3. After approval, rerun the reviewed command with `--yes`.
4. Report JSON evidence and native target discovery.

## Commands

Run `bash scripts/smart-ide-migration.sh --help` for flags. Commands run from
this Skill directory.

~~~bash
bash scripts/smart-ide-migration.sh --print-path cursor project-mcp

bash scripts/smart-ide-migration.sh \
  --source cursor --target claude --workspace /path/to/project \
  --objects skills,rules --scope project --dry-run
~~~
