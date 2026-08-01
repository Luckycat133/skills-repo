# Working in this repository

## Commands

- Full validation: `bash validate-all.sh`
- Check/regenerate root mirror: `bash scripts/sync-root-mirror.sh --check` / `bash scripts/sync-root-mirror.sh`
- Check path drift: `bash skills/agent-skills-setup/scripts/test-ide-paths.sh`
- Test migration: `bash skills/agent-skills-setup/scripts/test-migration.sh`
- Test one mapper: `bash skills/agent-skills-setup/scripts/test-<ide>-mapping.sh`
- Test redaction: `bash skills/agent-skills-setup/scripts/test-mcp-secret-redaction.sh`
- Install/import: `bash install.sh` / `bash scripts/import-agent-skill.sh <source-dir> <skill-name>`

## Architecture

`skills/agent-skills-setup/` is the source of the publishable migration skill; the root `SKILL.md` is its generated mirror. `references/ide-paths.json` is the path contract, generated summaries live in `references/ides/`, and `smart-ide-migration.sh` is the migration engine. Repository-level scripts handle validation, distribution, OpenClaw automation, and global sync.

## Guardrails

Edit the canonical Skill, then regenerate its mirror. Keep whole IDE config and opaque project migrations fail-closed; preserve redaction, dry-run, and explicit approval boundaries. Run `bash validate-all.sh` before proposing a change.
