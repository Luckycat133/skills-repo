# Contributing

## Scope

Contributions should improve the quality, usability, portability, or publishability of the skills in this repository.

## How To Contribute

1. Create a branch for your change.
2. Keep changes focused on a specific skill or repository concern.
3. Update documentation when behavior, workflow, or release steps change.
4. Validate bundled scripts before submitting changes.
5. Open a pull request with a clear summary of what changed and why.

## Skill Quality Expectations

- Keep skills specific and high-signal.
- Avoid private paths, secrets, or machine-specific assumptions in public-facing files.
- Prefer deterministic helper scripts over vague instructions for repeatable workflows.
- Document supported agents and any platform limitations.

## Before Opening A PR

- Review the relevant files under `docs/`.
- Run shell syntax checks for any updated scripts.
- Confirm the repository README still reflects the current workflow.

## Local Setup (Git Hooks)

The repository-root `SKILL.md` is a generated mirror of the canonical copy at
`skills/agent-skills-setup/SKILL.md`. A lightweight pre-commit hook blocks
commits when the two drift apart. Enable it once (repo-local, not committed):

```bash
git config core.hooksPath "$(git rev-parse --show-toplevel)/scripts/git-hooks"
```

If a commit is blocked, run `bash scripts/sync-root-mirror.sh`, then
`git add SKILL.md` and commit again. CI also enforces this via `validate-all.sh`.