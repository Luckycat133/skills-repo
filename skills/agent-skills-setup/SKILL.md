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
  workspace deliberately. The legacy flag interface keeps its historical
  global-Skills default for compatibility.
- Before copying a Skill, scan every source text file and reject literal
  credentials or links outside that Skill; leave both source and target intact.
- Profile-aware apply creates a manifest and exact backups before replacing a
  target. The legacy flag interface retains `--strategy backup|skip|overwrite`.
- Keep whole `config` files and opaque `project` trees manual. Rebuild a
  documented setting or migrate a dedicated supported object.
- Never move secrets, OAuth/session state, runtime metadata, approval grants,
  chat history, databases, or generated memory. Use manual reconstruction when
  redaction or conversion is unclear.
- Claude Desktop app MCP in **Settings → Extensions** and **Settings → Connectors** is UI-managed; do not infer or rewrite it from legacy JSON.
- Use `plan` to resolve paths, policies, and projected semantic loss without
  writing. If the user already requested the migration and the target is
  unambiguous, apply the reviewed plan with `apply --yes --json` in the same
  task; do not ask for redundant confirmation. Report the manifest, loss
  report, verification result, and native target discovery.

## Commands

Run `bash scripts/smart-ide-migration.sh <command> --help` for the profile-aware
interface. Commands run from this Skill directory. Calls that begin with a
legacy flag are delegated to the compatibility engine.

~~~bash
bash scripts/smart-ide-migration.sh inventory \
  --product cline --profile ide --workspace /path/to/project --json

bash scripts/smart-ide-migration.sh plan \
  --source cline/ide --target forge/cli --workspace /path/to/project \
  --objects skills,instructions,mcp --scope project --json

bash scripts/smart-ide-migration.sh apply \
  --source cline/ide --target forge/cli --workspace /path/to/project \
  --objects skills,instructions,mcp --scope project --yes --json

bash scripts/smart-ide-migration.sh verify --manifest /path/to/manifest.json
bash scripts/smart-ide-migration.sh rollback --manifest /path/to/manifest.json --yes

# Legacy compatibility lookup
bash scripts/smart-ide-migration.sh --print-path cursor project-mcp
~~~
