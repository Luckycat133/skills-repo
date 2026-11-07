---
name: maintain-agent-skills-setup
description: >-
  Develop and review Luckycat133/skills-repo after the agent-first scope reset.
  Use for changing its migration guidance, verifying an IDE format, adding a
  regression case, packaging the Skill, or completing the recorded acceptance
  backlog. Do not use for migrating an end user's own context.
license: MIT
metadata:
  version: "1.0"
---

# Maintain the migration Skill, not a migration platform

The owner's decision is binding: the deliverable teaches an existing agent to
migrate context. It must not grow back into an independent CLI/application.
Runtime orchestration, ACB, key management, bulk autoinstall, background sync,
telemetry, commercial dashboards and opaque state engines are out of scope.
Do not propose them as prerequisites for good migration.

## Before changing anything

Read root AGENTS.md, the canonical Skill and only the affected conversion reference.
Read [acceptance](references/acceptance.md) and [remaining work](references/remaining-work.md).
Check the current branch and diff; do not assume the baseline is still current.

Historical implementation at `880c5f58d310f5964963c88e685e0530a60e1757` is reference
material, not a specification. Historical profile notes under `docs/history/` are
unverified inputs. Do not re-add them to the published Skill without source checks.
Do not execute old migration scripts or import its engine to avoid doing the work.

## Work on one observable migration behavior

1. Write a realistic user request and before-files. Include the relevant failure
   case: scope loss, missing dependency, conflict, private data, or unknown schema.
2. Confirm the actual vendor/profile/version from official docs and, when available,
   the installed client. Record path, fields, precedence, activation and evidence.
3. Update a small reference and an expected example. Teach the host agent how to
   inspect/convert/edit, not how to memorize a generic runtime's flags.
4. Use native host tools in an isolated temporary fixture. Verify content, syntax,
   positive/negative scope samples and unchanged neighboring settings. Never touch
   the developer's real home directory during an eval.
5. Run structural tests. Then run the real agent/host scenario when access exists.
   Report these as separate levels. A check for a string in Markdown is not a
   behavioral evaluation. Never mark an unavailable client as passed.
6. Update evidence and the remaining-work status. Keep incomplete work precise.

## Scope rules

- Preserve all requested categories in inventory. Missing code is not a reason to
  drop commands, authored memory, agents or hooks. Explain conversions and limits.
- Small deterministic helpers are allowed only after a repeated measured failure
  shows existing host tools insufficient. One helper, one job, no migration engine.
  Require owner agreement before adding a new runtime/dependency to the user package.
- Do not count product-pair combinations as tested compatibility. Do not invent
  disabled fields, command invocations, schema paths, or equal trigger semantics.
- Publish only the explicit canonical package allowlist. Never ship this development
  Skill, evals, historical notes, maintainer scripts or old runtime code.
- Keep the legacy changelog/history accessible. Do not silently break installed
  releases or claim to have updated ClawHub merely by changing GitHub files.
- Retain safety around secrets, opt-in execution and unrelated-file preservation
  without forcing repeated confirmations already granted by the user's request.

## Done means

A specific request is better served by the Skill; a focused regression is recorded;
only intended files changed; structural checks pass; real behavior evidence is
reported honestly; public descriptions match that evidence. Do not call it done
because an architectural component or another large adapter registry was added.

No release, tag, marketplace upload, account configuration, payment link change,
or automatic schedule is authorized by this maintenance Skill alone.
