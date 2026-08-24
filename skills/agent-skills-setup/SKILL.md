---
name: agent-skills-setup
license: MIT
compatibility: Requires local Bash, Python 3, environment lookup, and filesystem reads. Writes only approved migration targets; no network access.
metadata:
  version: "0.8.32"
  permissions.shell: "bundled offline Bash/Python scripts in scripts/ only"
  permissions.env: "read environment variables to resolve product paths"
  permissions.file_read: "named source products, workspace tree, bundled references"
  permissions.file_write: "reviewed plan targets after explicit --yes consent"
  permissions.network: "denied"
description: >
  Use when a user names two supported IDEs or agent products to plan, migrate,
  or inspect specific skills, instructions, and MCP. The skill inventories local
  paths and runs bundled Bash/Python; an approved apply or rollback may write
  targets, create backups/manifests, verify results, and scan or redact secrets.
  Network access is forbidden.
---

# AI IDE Context Migration

## Permissions

- `shell`: bundled offline Bash/Python scripts only; no other binary is invoked.
- `env`: path resolution only; credential-looking values are redacted, never copied or printed.
- `file_read`: named source products, workspace tree, bundled `references/`; no startup sniffing of unlisted products.
- `file_write`: reviewed plan targets after `--yes` consent; backups/manifests/rollback state under `<workspace>/.agent-context-migration/`.
- `network`: denied. Every subcommand is offline; no downloads, telemetry, or remote calls.

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
- Device handoff (ACB): `snapshot` captures portable skills/instructions/MCP with atomic staging and 1:1 manifest bindings (subobject extraction only); `bundle-verify` re-checks checksums, bindings, secrets; `restore [--plan-only | --plan-in <plan> --yes]` reviews then executes the exact dual-side plan. `--all-installed` is a bulk operation — review its printed detection table before proceeding; all writes still require plan review plus `--yes`.
- Cross-platform: `%APPDATA%` / `%USERPROFILE%` / `$APPDATA` resolution, platform detection, per-surface path isolation (remote extension hosts experimental). `detect` / `doctor` report offline installation-state fidelity.
- The `legacy` subcommand is read-only lookup compatibility (`--print-path`, `--dry-run`) enforced by the Python wrapper; no legacy write path exists.
- Object-type scope (exhaustive — apply writes nothing outside it):
  - Auto-migratable (`ready`): `skills`, `instructions`, `mcp`.
  - Everything else is inventory / draft / manual-rebuild only and has no staging writer: `prompts`, `commands`, `agents`, `hooks`, `workflows`, plugin packages, session artifacts. Executable surfaces and opaque packages are never written to live product paths; replayed plans marking them eligible fail closed. Session/handoff content is never transferred at all.
  - Never migrated: trust state, generated memory, cloud knowledge, approvals, chat history.
- Sensitive shared settings files are read only for the named migration's authorized MCP subobject; trust sections (`never-migrate`) and sibling settings never enter plans or bundles; strict secret redaction before output. See [references/mcp-migration.md](references/mcp-migration.md).
- Claude Desktop app MCP in **Settings → Extensions** and **Settings → Connectors** is UI-managed; do not infer or rewrite it from legacy JSON.
