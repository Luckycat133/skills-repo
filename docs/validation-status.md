# Validation status — agent-first reset

Baseline: `880c5f58d310f5964963c88e685e0530a60e1757`.
Candidate package metadata: `0.11.0-dev` (unreleased).

| Level | Status |
| --- | --- |
| Local package/link/contract tests | PASS in local Linux sandbox; part of 15 unittest checks |
| Example JSON/TOML and rule fixture checks | PASS: JSON/TOML syntax and expected scope/content preservation examples |
| Official Agent Skills validator | CI runs the pinned validator; not assumed available locally |
| Real agent uses Skill on migration fixtures | NOT RUN; requires an installed/authenticated host |
| Real IDE loads migrated context | NOT RUN |
| Native Windows/remote-host migration behavior | NOT RUN |
| ClawHub publication/download verification | NOT RUN; not authorized by this source edit |

The cases in `evals/` are reviewable test inputs and rubrics, not fabricated user
sessions. Do not infer runtime support from passing structural or example tests.
