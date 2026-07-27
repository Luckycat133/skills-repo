# Repository Guidelines

## Project Structure & Module Organization

`skills/agent-skills-setup/` is the canonical publishable skill. Its `SKILL.md` defines behavior, `scripts/` contains migration and synchronization tools, `references/` stores IDE metadata and supporting guidance, and `assets/` holds reusable templates. The root `SKILL.md` is generated for distribution; edit the canonical copy and run `bash scripts/sync-root-mirror.sh`. Repository-wide utilities live in `scripts/`. Design notes and release guidance for this repository's own skill belong in `docs/agent-skills-setup/`; reviews of other (user-level) skills belong in `docs/skill-reviews/`. Shell integration tests are colocated with the skill as `skills/agent-skills-setup/scripts/test-*.sh`.

## Build, Test, and Development Commands

- `bash validate-all.sh` runs shell syntax checks, Python skill validation, mirror verification, and the core regression suites.
- `python3 scripts/validate_skills.py` checks skill frontmatter, names, relative links, secrets, and private paths.
- `bash scripts/sync-root-mirror.sh --check` verifies that the root mirror is current; omit `--check` to regenerate it.
- `bash skills/agent-skills-setup/scripts/test-migration.sh` runs isolated migration and global-sync integration tests.
- `bash skills/agent-skills-setup/scripts/test-<ide>-mapping.sh` exercises one IDE mapping, such as `test-cursor-mapping.sh`.

Run the full validation command before opening a pull request.

## Coding Style & Naming Conventions

Write portable Bash with `#!/usr/bin/env bash`, quoted variables, descriptive uppercase environment variables, and `set -euo pipefail` unless a test intentionally accumulates failures. Use four-space indentation in shell and Python. Python utilities should use type hints, `pathlib`, and standard-library dependencies where practical. Name skills and directories in lowercase kebab-case; name tests `test-<feature>.sh`. Keep Markdown concise and use relative repository links. Never edit generated mirrors directly.

## Testing Guidelines

Tests use self-contained Bash harnesses with temporary directories and explicit `PASS`/`FAIL` assertions. Do not read from or write to a contributor's real agent configuration. Add regression coverage beside the affected script, and verify both success and failure or dry-run behavior. No numeric coverage threshold is enforced; changed behavior must be exercised by a focused test and `validate-all.sh`.

## Commit & Pull Request Guidelines

Follow the repository's Conventional Commit pattern, for example `fix(security): redact MCP secrets` or `docs: update release guidance`. Keep commits focused. Pull requests should explain what changed and why, identify affected skills or IDEs, link relevant issues, and report validation commands run. Include screenshots only for user-visible documentation or UI changes. Update `README.md`, relevant `docs/` files, and `CHANGELOG.md` when behavior, configuration, or release steps change.

## Security & Configuration

Do not commit credentials, private absolute paths, or machine-specific assumptions. Preserve dry-run and confirmation safeguards in migration tools, and follow `SECURITY.md` for vulnerability reports.
