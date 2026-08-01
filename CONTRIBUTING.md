# Contributing

Improve a skill's quality, portability, usability, or publishability.

1. Create a focused branch and change.
2. Update affected documentation and regressions.
3. Run relevant syntax checks and `bash validate-all.sh`.
4. Open a PR explaining what changed, why, and how it was verified.

Public files must be specific, high-signal, and free of secrets, private paths, and machine-specific assumptions. Prefer deterministic helper scripts for repeatable work; document supported agents and platform limits.

## Optional local hook

The root `SKILL.md` mirrors `skills/agent-skills-setup/SKILL.md`. Enable the repo-local hook once to block mirror drift:

```bash
git config core.hooksPath "$(git rev-parse --show-toplevel)/scripts/git-hooks"
```

If blocked, run `bash scripts/sync-root-mirror.sh`, stage `SKILL.md`, and retry. CI enforces the same check.
