# Contributing

Read [AGENTS.md](AGENTS.md) and the [development Skill](dev/skills/maintain-agent-skills-setup/SKILL.md).
Improve one observable migration behavior with primary vendor evidence and a focused
test case. Keep `skills/agent-skills-setup/scripts/migrate_context.py` as the single
zero-dependency Python 3.11+ stdlib helper; do not reintroduce the retired `.acb`
engine, signing service, SQLite store, background daemon, or fake product-pair matrix.

Run `bash validate-all.sh`. Keep fixtures isolated in temporary directories with
synthetic canary secrets only — never real credentials or live `HOME` directories — and
verify zero secret values appear in `stdout`, `stderr`, or `MIGRATION.md`. State
whether testing was structural/script, guided fixture, real-host discovery, or native
IDE runtime. Unavailable live checks remain `not-run` or `blocked-environment`.

Open a focused PR. Preserve existing `main` protection and do not publish releases
or marketplace packages without maintainer authorization.
