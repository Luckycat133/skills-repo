# Working in this repository

## Commands

- Full validation: `bash validate-all.sh`
- Check/regenerate root pointer: `bash scripts/sync-root-mirror.sh --check` / `bash scripts/sync-root-mirror.sh`
- Check path drift: `bash skills/agent-skills-setup/scripts/test-ide-paths.sh`
- Test migration: `bash skills/agent-skills-setup/scripts/test-migration.sh`
- Test one mapper: `bash skills/agent-skills-setup/scripts/test-<ide>-mapping.sh`
- Test redaction: `bash skills/agent-skills-setup/scripts/test-mcp-secret-redaction.sh`
- Import for review: `bash scripts/import-agent-skill.sh <source-dir> <skill-name>`

## Architecture

`skills/agent-skills-setup/` is the source of the publishable migration skill; the root `SKILL.md` is a generated, frontmatter-free repository pointer. Registry v2 is the profile/surface contract; `references/ide-paths.json` and `ide-paths.tsv` remain legacy compatibility data. `smart-ide-migration.sh` is a thin Python launcher with the former Bash engine retained behind legacy flags. Repository-level scripts handle validation and runtime-only release packaging.

## Guardrails

Edit the canonical Skill, then regenerate the root pointer. Keep whole IDE config and opaque project migrations manual; preserve redaction, deterministic plans, exact target resolution, backup manifests, and guarded rollback. Run `bash validate-all.sh` before proposing a change.
