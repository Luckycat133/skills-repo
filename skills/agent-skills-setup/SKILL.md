---
name: agent-skills-setup
license: MIT
compatibility: Requires local Bash and filesystem read/write access for resolved migration targets. Python 3 is required for automatic MCP conversion and redaction. No network access.
metadata:
  version: "0.8.1"
description: >
  Use when a user asks to migrate or transfer AI-assistant context between two
  named supported IDEs or agent products. Handle selected skills, rules,
  prompts, commands, or MCP configuration with a scoped, verifiable plan.
---

# AI IDE Context Migration

## Route

1. Resolve source, target, objects, scope, and workspace from the request and
   environment. Ask only when a missing choice would change the destination.
2. Resolve both product profiles in [registry-v2.json](references/registry-v2.json)
   and [ide-registry.md](references/ide-registry.md), then read
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

- With the profile-aware CLI, always select `--objects`, `--scope`, and a
  workspace deliberately. Save the plan, review its diff/rebuild manifest,
  then apply that exact file. The legacy flag interface keeps lookup and
  zero-write dry-run compatibility; legacy writes are disabled.
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
- Use `plan --output` to resolve paths, policies, projected semantic loss, and
  a credential-free diff without writing. If the user already requested the
  migration and the target is unambiguous, apply the saved plan with
  `apply <plan> --yes --json` in the same task; do not ask for redundant
  confirmation. For cloud/UI/manual profiles, return the rebuild manifest
  instead of applying. Report plan/manifest checksums, loss, verification, and
  native target discovery.

## Commands

Run `bash scripts/smart-ide-migration.sh <command> --help` for the profile-aware
interface. Commands run from this Skill directory. Calls that begin with a
legacy flag are delegated to the compatibility engine.

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
bash scripts/smart-ide-migration.sh --print-path cursor project-mcp
~~~
