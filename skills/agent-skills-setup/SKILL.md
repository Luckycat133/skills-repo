---
name: agent-skills-setup
version: 0.7.2
license: MIT
compatibility: Requires local Bash and filesystem access. Python 3 is required for automatic MCP conversion and redaction. No network access.
description: >
  Migrate, move, transfer, copy, convert, or sync AI-assistant context between
  different IDEs or agents, including skills, rules, prompts, commands, and MCP
  configuration. Resolve product-specific formats and execute a scoped,
  verifiable migration.
---

# AI IDE Context Migration

## Route

1. Resolve source, target, objects, scope, and workspace from the request and
   environment. Ask only when a missing choice would change the destination.
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

## Execution

- Global scope defaults to `skills`. Project-backed objects require an explicit
  workspace in the command.
- Keep whole `config` files and opaque `project` trees manual. Rebuild a
  documented setting or migrate a dedicated supported object.
- Never move secrets, OAuth/session state, runtime metadata, approval grants,
  chat history, databases, or generated memory. Use manual reconstruction when
  redaction or conversion is unclear.
- Claude Desktop app MCP in **Settings → Extensions** and **Settings → Connectors** is UI-managed; do not infer or rewrite it from legacy JSON.
- Use `--dry-run` to resolve the plan. If the user already requested the
  migration and the target is unambiguous, apply the same command with
  `--yes --json` in the same task; do not ask for redundant confirmation.
  Report evidence and native target discovery.

## Commands

Run `bash scripts/smart-ide-migration.sh --help` for flags. Commands run from
this Skill directory.

~~~bash
bash scripts/smart-ide-migration.sh --print-path cursor project-mcp

bash scripts/smart-ide-migration.sh \
  --source cursor --target claude --workspace /path/to/project \
  --objects skills,rules --scope project --dry-run
~~~
