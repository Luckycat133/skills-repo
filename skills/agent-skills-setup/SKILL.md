---
name: agent-skills-setup
license: MIT
compatibility: Requires local Bash, Python 3, environment lookup, and filesystem reads. Writes only approved migration targets; no network access.
metadata:
  version: "0.8.23"
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
- Save the plan, review its diff/rebuild manifest, and apply that exact file. ACB `restore` constructs a dual-side plan binding bundle source directly to real destination targets, supporting replayable plans (`--plan-in`) with strict TOCTOU state lock enforcement.
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
- Device handoff (ACB, **version 0.8.23**):
  - `snapshot --output <b.acb> [--scope <scope>] [--all-installed]`: captures portable skills, instructions, and MCP under strict allowlists and sub-object field isolation (`config-subobject` extracts only authorized sections like `mcpServers`, never leaking sibling settings or host configurations).
  - `bundle-verify <b.acb>`: verifies closed-world SHA256 checksums and re-scans objects for secrets and binary safety.
  - `restore <b.acb> [--plan-only] [--plan-out <plan.json>]`: builds and reviews the dual-side migration plan without writing.
  - `restore <b.acb> --plan-in <plan.json> --yes`: re-verifies bundle and plan integrity, locks expected source/target states (TOCTOU guard), and executes the reviewed exact plan.
  - `restore <b.acb> --yes [--restore-root <dir>]`: applies the reviewed plan to the target IDE on the current device (the verified bundle is always the authoritative source). `--restore-root <dir>` opts into extracting a separate review tree of raw `objects/`.
  - Multi-IDE orchestration: `--all-installed` in snapshot and restore automatically scans, detects, and migrates installed configurations across the device.
- Cross-platform & Windows support: full environment variable resolution (`%APPDATA%`, `%USERPROFILE%`, `%LOCALAPPDATA%`, `$APPDATA`), automatic platform detection, and surface-specific platform path isolation.
- Diagnostics: `detect` / `doctor` inspect local probes and installation states offline with refined state fidelity (`installed`, `configured-only`, `compatibility-only`).
- Surface scope: skills, instructions, MCP, prompts, commands, workflows, agents/droids, and hooks (executable agents/hooks default to `draft-disabled`). Agents/Hooks/Plugins "native conversion" is experimental as of 0.8.23 (audit P1, tracked for a later release).
- Plugins & extensions: opaque binaries/plugins are non-executable and marked manual-rebuild.
- Claude Desktop app MCP in **Settings → Extensions** and **Settings → Connectors** is UI-managed; do not infer or rewrite it from legacy JSON.
- Never move secrets, OAuth/session state, runtime metadata, approval grants, chat history, or generated memory.
