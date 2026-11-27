---
name: agent-skills-setup
description: >-
  Migrates, exports, restores, or syncs AI coding context — rules/instructions,
  Agent Skills, MCP servers, prompts, commands, workflows, custom agents, hooks,
  plugins, portable settings, scripts, user-authored memory, and .env secrets —
  between any AI coding IDEs, CLIs, or computers via full-file copy and out-of-band
  `0700`/`0600` secret handling without exposing secret values to LLM context. Use
  whenever moving IDE configs across tools or machines, backing up AI setups, or
  adapting per-IDE rules, Skills, prompts, agents, hooks, and MCP configs.
license: MIT
metadata:
  version: "0.11.0-dev"
---

# Migrate AI Coding Context Safely

Use this skill with `python3 "<SKILL_DIR>/scripts/migrate_context.py"` and the per-IDE
reference files (`references/products/<id>.md`) indexed in [products.md](references/products.md)
so you can migrate between any of 90+ AI coding tools cleanly without searching external docs.

## 1. Core workflow & invariants

1. **Full copy by default**: Always copy complete files and folders by value — never
   create symlinks unless the user explicitly asks for symlinked management.
2. **Script-mediated secret privacy**: Pull the latest copy of this skill before running,
   use `--help` instead of reading `migrate_context.py` source, and never open secret files
   (`.env*`, `mcp*.json`, `~/.claude.json`, `~/.claude/settings.json`, `~/.codex/config.toml`)
   into LLM context. The script transfers credentials disk-to-disk (`0700`/`0600`, `sha256[:8]` only).
3. **Strict scope & zero stray directories**: Never touch IDEs outside the user's
   requested source/target/profiles, and (outside `export-device`) never create staging
   or default backup directories (`.migration-review/`, `~/.agent-skills-setup-backups/`).
   Pass `--backup-dir <dir>` only when backups of overwritten targets are wanted.
4. **Progressive per-IDE loading**: For any task `A -> B`, look up canonical IDs in
   [products.md](references/products.md) and read ONLY `references/products/<a>.md` and
   `references/products/<b>.md` first (do NOT load all 90 files). Major multi-surface IDEs
   link category sub-files (`references/products/<id>/<topic>.md`) from `<id>.md` — open
   only the sub-file matching the category being translated. Use `inspect --list-profiles`
   to see all declarative built-in profiles supported by `migrate`, and combine generic
   `sync-skills`, `patch-mcp`, and `copy-files` for every other cataloged client.
5. **Script for lossless, Agent for lossy**: Run the script first; preview requests pass
   `--dry-run` (zero target changes). Whenever stdout reports `agent_handoff` items
   (non-1:1 rule triggers, restricted/TOML agents, hooks, incompatible commands), read the
   non-secret source plus [instructions.md](references/instructions.md) /
   [other-context.md](references/other-context.md) and adapt semantically yourself.

## 2. Generic script primitives

| Task | Command (`--dry-run` previews without writing; `--redact-secrets` replaces keys with env refs) |
| --- | --- |
| **List built-in profiles** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" inspect --list-profiles` |
| **Inspect inventory** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" inspect --workspace . --profiles all --summary` |
| **Migrate declarative profiles** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" migrate --source <src> --target <dst> --workspace . --scope all` |
| **Export computer** (`--output` optional) | `python3 "<SKILL_DIR>/scripts/migrate_context.py" export-device --profiles all --scope all --workspace . --output ~/context-transfer` |
| **Restore computer** (`--profiles` scopes IDEs) | `python3 "<SKILL_DIR>/scripts/migrate_context.py" import-device --input ~/context-transfer --target same --profiles <list> --workspace .` |
| **Generic copy any Skill folder** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" sync-skills --src-dir <dir> --dst-dir <dir>` (or `--src-profile <p>`) |
| **Generic patch any MCP map** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" patch-mcp --src-file <f> --src-key-path <k> --dst-file <f> --dst-key-path <k>` |
| **Generic full-copy files/dirs** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" copy-files --src <file_or_dir> --dst <file_or_dir>` |

## 3. References (1-hop)

- **Product catalog (90 per-IDE entry docs + progressive category sub-files)**: [products.md](references/products.md) -> `references/products/<id>.md` (and `references/products/<id>/<topic>.md` when present).
- **Generic semantics**: [instructions.md](references/instructions.md), [mcp.md](references/mcp.md), [other-context.md](references/other-context.md), [device-transfer.md](references/device-transfer.md), [discovery.md](references/discovery.md), [verification.md](references/verification.md), [CLI workflow](references/cli-workflow.md), [Registry v2](references/registry-v2.md).
- **Report templates**: [device-readme.md](assets/device-readme.md), [migration-report.md](assets/migration-report.md).
