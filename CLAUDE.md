@AGENTS.md

## Additional architecture context

Registry v2 is the profile/surface contract; `references/ide-paths.json` and `ide-paths.tsv` are legacy compatibility data. `smart-ide-migration.sh` is a thin Python launcher with the former Bash engine behind legacy flags. Keep whole IDE configuration and opaque project migrations manual; preserve redaction, deterministic plans, exact target resolution, backup manifests and guarded rollback.

Focused commands:

- Path mapping: `bash skills/agent-skills-setup/scripts/test-ide-paths.sh`.
- Migration: `bash skills/agent-skills-setup/scripts/test-migration.sh`.
- Redaction: `bash skills/agent-skills-setup/scripts/test-mcp-secret-redaction.sh`.
- Import for review: `bash scripts/import-agent-skill.sh <source-dir> <skill-name>`.

Canonical source, generated-root handling and PR validation are defined once in `AGENTS.md`.
