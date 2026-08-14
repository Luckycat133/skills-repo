---
name: agent-skills-setup
license: MIT
compatibility: Requires local Bash, Python 3, environment lookup, and filesystem reads. Writes only approved migration targets; no network access.
metadata:
  version: "0.8.2"
description: >
  Use only when a user names two supported IDEs or agent products, identifies
  specific skills, instructions, prompts, commands, or MCP objects, and asks to
  plan or perform a migration. The skill inventories local paths and runs
  bundled Bash/Python; separately approved apply or rollback may write targets,
  create backups/manifests, verify results, and scan or redact secrets.
---

# AI IDE Context Migration

## Capabilities and authorization

- `detect`, `inventory`, and `plan` may read only the named products, objects,
  scope, and workspace. Shell use is limited to bundled scripts; environment
  access resolves paths only, and network access is forbidden.
- A generic migration request authorizes planning only. Before `apply` or
  `rollback`, show the exact reviewed artifact and target paths and obtain
  separate explicit user approval; `--yes` records that approval.

## Route

1. Resolve source, target, objects, scope, and workspace. If any selection is
   missing, stop before filesystem inspection and ask for it.
2. Resolve both product profiles in [registry-v2.json](references/registry-v2.json)
   and [ide-registry.md](references/ide-registry.md), then read
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

- With the profile-aware CLI, select `--objects`, `--scope`, and workspace.
  Save the plan, review its diff/rebuild manifest, then apply that exact file.
  The explicit `legacy` subcommand keeps lookup and zero-write dry-run
  compatibility; legacy writes are disabled.
- Before copying a Skill, scan every source text file and reject literal
  credentials or links outside that Skill; leave both source and target intact.
- Profile-aware apply rejects changed source/target state, Registry data,
  adapter versions, or Git HEAD. It creates a checksummed manifest and exact
  backups, stages every output, and rolls back the whole operation if any write
  or manifest step fails. Repository-only compatibility regressions retain
  `--strategy backup|skip|overwrite`.
- Instruction migration parses and emits target-native activation fields. If a
  conditional, model-decided, or manual rule cannot be represented by the
  target, keep it manual instead of silently making it unconditional.
- Keep whole `config` files and opaque `project` trees manual. Rebuild a
  documented setting or migrate a dedicated supported object.
- Never move secrets, OAuth/session state, runtime metadata, approval grants,
  chat history, databases, or generated memory. Use manual reconstruction when
  redaction or conversion is unclear.
- Claude Desktop app MCP in **Settings → Extensions** and **Settings → Connectors** is UI-managed; do not infer or rewrite it from legacy JSON.
- Use `plan --output` for a credential-free preview. After separate approval,
  use `apply <plan> --yes --json`. For cloud/UI/manual profiles, return the
  rebuild manifest. Report checksums, loss, verification, and native discovery.

## Commands

Run `bash scripts/smart-ide-migration.sh <command> --help` for the profile-aware
interface. Commands run from this Skill directory. Calls that begin with a
flag are rejected; compatibility requires the explicit `legacy` subcommand.

~~~bash
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
