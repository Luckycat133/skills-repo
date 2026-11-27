# Release and publication gate

Target candidate: **`0.11.0-dev` (unpublished)**. Do not tag, create a GitHub release,
upload a marketplace archive, or announce compatibility until the owner separately
authorizes publication and the items below are reviewed.

## Gate

- [x] `bash validate-all.sh` passes locally, including unit, torture, canary zero-leak,
  catalog routing, and deterministic zip packaging.
- [x] `scripts/package_skill.py --output <outside-repo>/agent-skills-setup.zip` builds
  reproducibly from rule-based package hygiene (`SKILL.md`, `references/`, `assets/`,
  `LICENSE`, and `0755` `scripts/migrate_context.py`) with zero `dev/`, `evals/`,
  `docs/`, `tests/`, `__pycache__/`, or `.acb` content.
- [ ] Real host-agent / native GUI IDE verification runs from `evals/client-matrix.json`
  are executed on real machines and recorded honestly in [validation-status.md](validation-status.md).
- [ ] `README.md`, `README.zh-CN.md`, `SKILL.md` metadata version, and changelog match
  the verified boundary.
- [ ] Explicit owner approval exists for the version number, Git tag, GitHub Release,
  and any marketplace upload.
