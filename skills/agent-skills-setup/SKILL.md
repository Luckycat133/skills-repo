---
name: agent-skills-setup
license: MIT
compatibility: Requires local Bash, Python 3, environment lookup, and filesystem reads. Writes only approved migration targets; no network access.
metadata:
  version: "0.8.22"
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
- Save the plan, review its diff/rebuild manifest, and apply that exact file. ACB `restore` constructs a dual-side plan binding bundle source directly to real destination targets, ensuring the reviewed plan matches the executed plan at all times.
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
- Device handoff (ACB, **general availability in 0.8.22**):
  - `snapshot --output <b.acb> [--scope <scope>]`: captures portable skills, instructions, and MCP under a strict allowlist (forbidden policies, sessions, chats, runtimes, generated memory, and unrequested scopes are strictly rejected).
  - `bundle-verify <b.acb>`: verifies closed-world SHA256 checksums and re-scans objects for secrets and binary safety.
  - `restore <b.acb> [--plan-only]`: builds and reviews the dual-side migration plan without writing.
  - `restore <b.acb> --yes [--restore-root <dir>]`: applies the reviewed plan to the target IDE on the current device (the verified bundle is always the authoritative source). `--restore-root <dir>` opts into extracting a separate review tree of raw `objects/`.
  - All 0.8.21 audit blockers (P0-1 plan/exec alignment, P0-2 snapshot allowlist, P0-3 bundle source precedence, P0-4 strict handoff whitelist) are fully closed in 0.8.22 — see CHANGELOG `[0.8.22]`.
- Diagnostics: `detect` / `doctor` inspect local probes and installation states offline.
- Surface scope: skills, instructions, MCP, prompts, commands, workflows, agents/droids, and hooks (executable agents/hooks default to `draft-disabled`). Agents/Hooks/Plugins "native conversion" is experimental as of 0.8.22 (audit P1, tracked for a later release).
- Plugins & extensions: opaque binaries/plugins are non-executable and marked manual-rebuild.
- Claude Desktop app MCP in **Settings → Extensions** and **Settings → Connectors** is UI-managed; do not infer or rewrite it from legacy JSON.
- Never move secrets, OAuth/session state, runtime metadata, approval grants, chat history, or generated memory.
