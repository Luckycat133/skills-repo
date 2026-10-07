---
name: agent-skills-setup-maintenance
description: Develop or audit this repository's agent-context migration engine, profile registry, mappers and release package. Use for implementation or contract maintenance; use agent-skills-setup to perform an actual user migration.
---

# Agent Skills Setup maintenance

Read `AGENTS.md` and `CLAUDE.md`. Keep the public product in `skills/agent-skills-setup/`; this maintainer Skill is not part of its runtime archive.

## Find the contract owner

| Change | Source / focused verification |
|---|---|
| Product/profile surfaces and aliases | `references/registry-v2.json`, its schema; `scripts/test-registry-v2.sh`, `test-profile-contracts.sh`, `test-alias-resolution.sh` |
| Detection | `scripts/detect/`; `test-detection-probes.sh` |
| Instruction/MCP mapping | `scripts/migration_core.py`; affected `test-<ide>-mapping.sh` and `test-mcp-adapters.sh` |
| Plan/apply and drift checks | `scripts/context-migrator.py`, `migration_core.py`; `test-partial-safe-apply.sh`, `test-migration-evidence.sh` |
| Bundle snapshot/restore | `scripts/acb/`, `context-migrator.py`; relevant `test-acb-*.sh` |
| Public runtime packaging | repository `scripts/stage-runtime-skill.sh`, `build-clawhub-skill.py`, `test-runtime-package.sh` |

Paths in the first five rows are relative to `skills/agent-skills-setup/`. Registry v2 is authoritative; legacy path tables are compatibility data, not a second place to invent support.

## Preserve migration semantics

A source directory existing is not evidence that the destination client can load its objects. Keep profile, surface, scope, target path, object classification and loss report consistent. Executable surfaces such as hooks/workflows remain draft-only under the current product contract; do not add a writer merely because a path is known. Trust state, raw chats and generated memory are excluded. User-requested handoff is a separate opt-in summary/selected-file mechanism.

For a plan/restore change, use isolated source and target fixtures. Verify the exact saved plan binds the intended source and destination, stale targets fail without writes, successful apply preserves unrelated settings, and rollback respects its manifest. Test redaction and MCP subobject isolation when touching shared settings. Never run migration regression tests against the user's real client configuration.

## Validate and package proportionately

Start with the affected mapper/contract suite. Use `python3 scripts/validate_skills.py` for publishable content and links, and `bash scripts/sync-root-mirror.sh --check` for the generated frontmatter-free root pointer. Edit canonical Skill content rather than hand-editing that pointer.

The runtime packager takes an explicit source Skill, a new output directory outside it and a version; it copies an allowlist of runtime scripts/packages and license material. New runtime imports must be included and exercised from the staged package, not only from the source tree. Do not add maintainer tests or machine-specific paths to the public archive to fix an import accidentally.

Documentation-only work uses focused link/content checks. Broad registry or migration behavior changes and PR/release preparation use `bash validate-all.sh` as required by repository rules. Publishing is separate from validation and requires the current task to include it.
