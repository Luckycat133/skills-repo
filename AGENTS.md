# Repository Guidelines

## Layout

`skills/agent-skills-setup/` is the canonical publishable skill: `SKILL.md` defines behavior, `references/` holds conditional guidance, `scripts/` holds migration tools and colocated `test-*.sh` suites, and `assets/` holds reusable templates. The root `SKILL.md` is generated; edit the canonical file and run `bash scripts/sync-root-mirror.sh`. Keep repository tooling in `scripts/` and only active, repository-owned guidance in `docs/agent-skills-setup/`.

## Validate

- `bash validate-all.sh` — required before a PR; runs syntax, validation, mirror checks, and focused suites.
- `python3 scripts/validate_skills.py` — frontmatter, links, secrets, and private-path checks.
- `bash scripts/sync-root-mirror.sh --check` — verify the generated mirror.
- `bash skills/agent-skills-setup/scripts/test-<feature>.sh` — run a focused regression, for example `test-cursor-mapping.sh`.

## Style

Use portable Bash (`#!/usr/bin/env bash`, quoted variables, `set -euo pipefail`) and four-space indentation. Python uses type hints, `pathlib`, and preferably the standard library. Use lowercase kebab-case names and concise Markdown with relative links. Do not edit generated mirrors.

## Changes

Keep changes focused; add a nearby regression for changed behavior, including success and failure/dry-run paths. Tests must use isolated temporary directories and never touch real agent configuration. Use Conventional Commits. PRs explain scope, affected IDEs, and validation; update the README, docs, and changelog when behavior or release steps change.

## Security

Never commit credentials, private absolute paths, or machine-specific assumptions. Preserve dry-run and confirmation safeguards. Follow `SECURITY.md` for vulnerability reports.
