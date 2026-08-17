---
name: agent-skills-setup
license: MIT
compatibility: Requires local Bash, Python 3, environment lookup, and filesystem reads. Writes only approved migration targets; no network access.
metadata:
  version: "0.8.2"
description: >
  Use when a user names two supported IDEs or agent products to plan, migrate,
  or inspect specific skills, instructions, and MCP. The skill inventories local
  paths and runs bundled Bash/Python; an approved apply or rollback may write
  targets, create backups/manifests, verify results, and scan or redact secrets.
  Network access is forbidden.
---

# AI IDE Context Migration

## Capabilities and authorization

- `detect`, `inventory`, and `plan` read only named products and workspace; network access is forbidden.
- A generic migration request authorizes planning only; separate explicit user approval (`--yes`) or explicit action verbs (apply, restore, 迁到) under `--apply-safe` authorize write.
- Save the plan, review its diff/rebuild manifest, and apply that exact file.
- The explicit `legacy` subcommand keeps lookup compatibility; legacy writes are disabled.

## Route

1. Resolve both product profiles through [ide-registry.md](references/ide-registry.md) / [registry-v2.json](references/registry-v2.json).
2. Read only [references/ides/<source>.md](references/ides/) and [references/ides/<target>.md](references/ides/).
3. Load reference by need:
   - Before preview or apply: [references/migration-safety.md](references/migration-safety.md)
   - MCP objects: [references/mcp-migration.md](references/mcp-migration.md)
   - Other file objects: [references/object-migration.md](references/object-migration.md)
   - Approved apply / proof: [references/verification.md](references/verification.md)

## Execution

- High-level: `bash scripts/smart-ide-migration.sh migrate --source <src> --target <dst> --workspace . --objects all-portable --yes`
- Step-by-step: `plan --output <plan.json>` -> `apply <plan.json> --manifest <manifest.json> --yes` -> `verify --manifest <manifest.json>` -> `rollback --manifest <manifest.json> --yes`.
- Default `--apply-safe` lands `ready` and `draft-disabled`; manual/forbidden items record to manifest.
- Rejects changed source/target, Registry, adapter, or Git HEAD. Atomic writes, exact backups, guarded rollback.
- Claude Desktop app MCP in **Settings → Extensions** and **Settings → Connectors** is UI-managed; do not infer or rewrite it from legacy JSON.
- Never move secrets, OAuth/session state, runtime metadata, approval grants, chat history, or generated memory.
