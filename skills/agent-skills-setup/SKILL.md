---
name: agent-skills-setup
license: MIT
compatibility: Requires local Bash, Python 3, environment lookup, and filesystem reads. Writes only approved migration targets; no network access.
metadata:
  version: "0.8.2"
description: >
  Use when a user names supported IDEs or agent products and asks to plan,
  perform, or "一键" / "一句话" migrate their context. Natural-language
  triggers may name only a source and target with an action verb (apply,
  restore, 迁到, 迁移到, 应用). The skill inventories local paths and runs
  bundled Bash/Python; an authorized apply may write targets, create
  backups/manifests, verify results, and scan or redact secrets.
---

# AI IDE Context Migration

## Capabilities and authorization

- `detect`, `inventory`, and `plan` may read only the named products, objects,
  scope, and workspace. Shell use is limited to bundled scripts; environment
  access resolves paths only, and network access is forbidden.
- A natural-language phrase that explicitly contains an action verb such as
  `apply`, `restore`, `migrate`, `迁到`, `迁移到`, `应用`, or `直接应用`
  is treated as combined authorization for `ready` and `draft-disabled` items
  under `--apply-safe`. The Skill still requires explicit per-item
  confirmation for: enabling or executing Hooks; writing literal secrets,
  OAuth state, or trust/approval grants; cross-workspace destructive
  overwrites with unresolved conflicts; and enterprise or cloud policy
  changes.
- The explicit `legacy` subcommand keeps lookup and zero-write dry-run
  compatibility; legacy writes are disabled.

## Route

1. Resolve source, target, objects, scope, and workspace. If any selection is
   missing, stop before filesystem inspection and ask for it.
2. Resolve both product profiles through
   [registry-v2.json](references/registry-v2.json) — aliases such as
   `vscode`, `claude-desktop`, `codeium`, and `jetbrains-ai` are
   automatically resolved to their canonical product/profile. Read
   only [references/ides/<source>.md](references/ides/) and
   [references/ides/<target>.md](references/ides/). Use
   [ide-paths.json](references/ide-paths.json) or `legacy --print-path` for paths.
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

- For natural-language intents ("迁到 X", "migrate to X"), prefer
  `bash scripts/smart-ide-migration.sh migrate ... --yes` over composing
  separate `plan` / `apply` / `verify` invocations. The migrate subcommand
  orchestrates detect → inventory → plan → apply → verify in one process,
  records artifacts under `<workspace>/.migration/`, and respects the
  danger list above.
- The profile-aware CLI still exposes `inventory`, `plan`, `apply`,
  `verify`, `rollback`, and `legacy` for callers that want step-by-step
  control. Use `plan --output` for a credential-free preview, then
  `apply <plan> --yes --json` (or `migrate --plan-only` to stop after
  planning).
- Default apply mode is `--apply-safe`: only `ready` and `draft-disabled`
  items land; `manual-rebuild`, `forbidden`, `conflict`, and `invalid`
  items appear in the manifest with a reason. Add `--include lossy` or
  `--accept-loss <ids>` to opt into `ready-lossy` items. `--strict`
  preserves the legacy all-or-nothing semantics.
- Before copying a Skill, scan every source text file and reject literal
  credentials or links outside that Skill; leave both source and target intact.
- Profile-aware apply rejects changed source/target state, Registry data,
  adapter versions, or Git HEAD. It creates a checksummed manifest and exact
  backups, stages every output, and rolls back the whole operation if any write
  or manifest step fails.
- Instruction migration parses and emits target-native activation fields. If a
  conditional, model-decided, or manual rule cannot be represented by the
  target, keep it manual instead of silently making it unconditional.
- Directory-style instruction targets use basename-first naming; on
  collision the apply appends a short object_id suffix so file identity is
  preserved across re-runs.
- Keep whole `config` files and opaque `project` trees manual. Rebuild a
  documented setting or migrate a dedicated supported object.
- Never move secrets, OAuth/session state, runtime metadata, approval grants,
  chat history, databases, or generated memory. Use manual reconstruction when
  redaction or conversion is unclear.
- Claude Desktop app MCP in **Settings → Extensions** and **Settings → Connectors** is UI-managed; do not infer or rewrite it from legacy JSON.
- For cloud/UI/manual profiles, return the rebuild manifest. Report
  checksums, loss, verification, and native discovery.

## Commands

Run `bash scripts/smart-ide-migration.sh <command> --help` for the profile-aware
interface. Commands run from this Skill directory. Calls that begin with a
flag are rejected; compatibility requires the explicit `legacy` subcommand.

~~~bash
# One-sentence migration: detect -> inventory -> plan -> apply -> verify.
bash scripts/smart-ide-migration.sh migrate \
  --source cline/ide --target claude/code-cli --workspace . \
  --scope user,project --objects all-portable --yes

# Step-by-step:
bash scripts/smart-ide-migration.sh inventory \
  --product cline --profile ide --workspace /path/to/project --json

bash scripts/smart-ide-migration.sh plan \
  --source cline/ide --target forge/cli --workspace /path/to/project \
  --objects skills,instructions,mcp --scope project \
  --output /path/to/plan.json --json

bash scripts/smart-ide-migration.sh apply \
  /path/to/plan.json --manifest /path/to/manifest.json --yes --json

bash scripts/smart-ide-migration.sh verify --manifest /path/to/manifest.json
bash scripts/smart-ide-migration.sh rollback --manifest /path/to/manifest.json --yes

# Legacy compatibility lookup
bash scripts/smart-ide-migration.sh legacy --print-path cursor project-mcp
~~~
