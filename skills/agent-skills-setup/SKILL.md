---
name: agent-skills-setup
license: MIT
compatibility: Bash/Python 3; signing needs cryptography; encrypted credentials need POSIX/Node.js. Filesystem access; no network.
metadata:
  version: "0.10.2"
  permissions.shell: "bundled offline Bash/Python/Node scripts plus local read-only detection commands"
  permissions.env: "read environment variables to resolve product paths"
  permissions.file_read: "selected product surfaces, workspace, bundles, named key/password files, bundled references"
  permissions.file_write: "authorized plan targets, named artifact/key outputs, local transaction state"
  permissions.network: "denied"
description: >-
  Use when a user wants to migrate, back up, restore, compare, or move
  AI-coding-agent context across Cursor, Claude Code, Codex, Cline,
  Copilot, Windsurf, Gemini CLI, or another registered profile, including
  switching computers. Handles Skills, instructions/rules, and MCP with
  secret redaction, preview, verification, rollback, and portable bundles;
  records omissions and next-agent recovery tasks; reviewed field merges
  and context-file restoration cover selected reconstruction material.
  Compatible plugin packages and reviewed handoff require explicit opt-in.
  Authorized provider/API credentials use a separate encrypted supplement.
---

# Agent Skills Setup

Move context across requested IDEs and computers.

## Permissions

- Run bundled local helpers; network access is forbidden. No downloads, installations, or connections.
- Read selected products/scopes, workspace, bundles and named keys. Device-wide discovery requires authorization.
- Write authorized targets/artifacts and transaction state. `--yes` records existing authorization; it grants none.

## Choose the workflow

- Infer products, objects, workspace, and scope. Project requests include user surfaces only when requested.
- Explicit move/apply/restore/rollback requests authorize scoped execution. Preserve prior authorization; preview-only requests stop after preview. Review destinations/losses; ask about unresolved conflicts, unapproved losses, or broader scope.
- Save the plan, review its diff/rebuild manifest, and apply that exact file. Changed inputs require replanning.

| Request | Entry point and guidance |
| --- | --- |
| Inventory | `detect`, `inventory`; [registry](references/ide-registry.md). |
| Cross-IDE migration | `plan` → `apply` → `verify`, or `migrate`; [CLI guide](references/cli-workflow.md). |
| Computer switching/signing | `snapshot`, `bundle-verify`, `doctor`, `restore`, signing commands; [bundle workflow](references/bundle-workflow.md). |
| Verify/undo | `verify`, `rollback`; [verification](references/verification.md). |

Resolve both product profiles through [registry-v2.json](references/registry-v2.json); restore uses bundle manifest selectors.

1. Read selected `references/ides/<source>.md` and `references/ides/<target>.md`; resolve filenames through the registry/profile index.
2. Before preview/apply, read [migration safety](references/migration-safety.md).
3. For MCP, read [MCP migration](references/mcp-migration.md); otherwise [object migration](references/object-migration.md). For delivery, read [verification](references/verification.md).

## Computer switching

- Discover explicit clients with `scripts/discover-context-sources.py --clients <ids> --output <fresh-directory>`; default to user scope. Include project/local context only when requested. Inspect scope, links and exclusions.
- Export with `scripts/device-export.py --spec <scope.json> --output <fresh-directory>`; see the [workflow](references/bundle-workflow.md). Include the bundled runtime. Resolve missing sources before retiring the old machine.
- Native recipes use `scripts/device-restore.py verify/list`, then `plan` → review → `apply --yes`. Cross-IDE requests retain independent source/target selection in general migration/restore.
- Restore review material with `scripts/review-restore.py template` → `plan` → review → `apply --yes` → `verify`; see [mapped restoration](references/review-restoration.md). The AI handles merges; reserve authentication/native trust for users.
- For explicitly authorized provider/API-key transfer, use the separate [encrypted channel](references/private-provider-transfer.md); ordinary bundles remain redacted.
- Read coverage/exclusions and checksummed recovery guides. Use Python 3.11+ for TOML. Keep state/evidence outside packets. Verify configuration writes, native discovery and runtime separately.

## Supported boundaries

- Automatic: `skills`, `instructions`, reviewed local stdio `mcp`. Plugins require `--include-plugins`; reviewed handoff requires `--include-session`.
- Review first: prompts, commands, agents, hooks, workflows, allowlisted preferences and MCP. Mapped restoration never executes code or activates incomplete MCP; Hooks require native/dependency review. Ordinary bundles exclude credentials; the authorized encrypted channel is separate. Never transfer trust, approvals, raw history, or generated memory. Shared configs use selected subobjects only. Cloud/UI require native reconstruction.
- Use the explicit `legacy` subcommand for lookup/dry-run compatibility only; legacy writes are disabled.
- Deliver artifacts, counts, backups, verification and remaining work. Separate configuration, native-discovery and runtime evidence.
