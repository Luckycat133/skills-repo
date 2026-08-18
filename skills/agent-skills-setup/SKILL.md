---
name: agent-skills-setup
license: MIT
compatibility: Requires local Bash, Python 3, environment lookup, and filesystem reads. Writes only approved migration targets; no network access.
metadata:
  version: "0.8.21"
description: >
  Use when a user names two supported IDEs or agent products to plan, migrate,
  or inspect specific skills, instructions, and MCP. The skill inventories local
  paths and runs bundled Bash/Python; an approved apply or rollback may write
  targets, create backups/manifests, verify results, and scan or redact secrets.
  Network access is forbidden.
---

# AI IDE Context Migration

## Capabilities and authorization

- `detect`, `doctor`, `inventory`, `plan`, `snapshot`, and `bundle-verify` read only named products and workspace; network access is forbidden.
- A generic migration request authorizes planning only; separate explicit user approval (`--yes`) or explicit action verbs (apply, restore, 迁到) under `--apply-safe` authorize write.
- Save the plan, review its diff/rebuild manifest, and apply that exact file. ACB `restore` rebuilds and executes from the reviewed plan, so the reviewed plan always equals the executed plan.
- The explicit `legacy` subcommand keeps lookup compatibility; legacy writes are disabled.

## Route

1. Resolve both product profiles through [ide-registry.md](references/ide-registry.md) / [registry-v2.json](references/registry-v2.json).
2. Read only [references/ides/<source>.md](references/ides/) and [references/ides/<target>.md](references/ides/).
3. Load reference by need:
   - Before preview or apply: [references/migration-safety.md](references/migration-safety.md)
   - MCP objects: [references/mcp-migration.md](references/mcp-migration.md)
   - Other file objects: [references/object-migration.md](references/object-migration.md)
   - Approved apply / proof: [references/verification.md](references/verification.md)

## Execution & Scope

- High-level: `bash scripts/smart-ide-migration.sh migrate --source <src> --target <dst> --workspace . --objects all-portable --yes`
- Step-by-step: `plan --output <plan.json>` -> `apply <plan.json> --manifest <manifest.json> --yes` -> `verify --manifest <manifest.json>` -> `rollback --manifest <manifest.json> --yes`.
- Device handoff (ACB, **general availability in 0.8.21**): `snapshot --output <b.acb>` -> `bundle-verify <b.acb>` -> `restore <b.acb> --yes --restore-root <dir>` (offline self-contained archive; `--restore-root` opts into object extraction, otherwise `restore` only builds/reviews the plan). The 0.8.20 audit blockers (plan/exec mismatch, silent no-op, multi-scope, handoff leak) are closed in 0.8.21 — see CHANGELOG `[0.8.21]`.
- Diagnostics: `detect` / `doctor` inspect local probes and installation states offline.
- Surface scope: skills, instructions, MCP, prompts, commands, workflows, agents/droids, and hooks (executable agents/hooks default to `draft-disabled`). Agents/Hooks/Plugins "native conversion" is experimental as of 0.8.21 (audit P1, tracked for a later release).
- Plugins & extensions: opaque binaries/plugins are non-executable and marked manual-rebuild.
- Claude Desktop app MCP in **Settings → Extensions** and **Settings → Connectors** is UI-managed; do not infer or rewrite it from legacy JSON.
- Never move secrets, OAuth/session state, runtime metadata, approval grants, chat history, or generated memory.
