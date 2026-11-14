---
name: maintain-agent-skills-setup
description: >-
  Maintain Luckycat133/skills-repo as an agent-first context-migration Skill.
  Use for checking product documentation, improving format conversions, running
  the repository's real-agent/client acceptance queue, updating evidence, or
  packaging the guidance. Not for migrating an end user's context directly.
license: MIT
metadata:
  version: "1.2"
---

# Maintain guidance, not a migration platform

The owner's scope reset is binding. Use host-agent tools to research, edit and
verify context migrations. Do not reintroduce an orchestration CLI, ACB engine,
auto-installer, signing service, background sync, telemetry or commercial platform.
The user package contains only Markdown guidance/templates and LICENSE.

## Read first

Read root AGENTS.md, the canonical Skill and only the affected product/conversion
references. Read [acceptance](references/acceptance.md),
[remaining work](references/remaining-work.md) and the
[real-client test procedure](references/client-tests.md).
For current research decisions read [research method](references/research-method.md).
For CLI, Registry v2 or test-log claims read
[checkout review](references/checkout-review.md). Record the branch/commit, dirty
state and loaded Skill version; never infer the current runtime from an older log.
Unavailable local results stay user-reported, not independently verified.

The 2026-11-07 catalog covers all 87 historical identifiers plus new clients and
profiles. It is documentation evidence, **not runtime certification**. The
maintainer-only `docs/research/catalog-2026-11-07.json` records coverage and sources;
`evals/client-matrix.json` is the pending acceptance queue, not an executable registry.
Historical notes under docs/history remain unverified clues, not active contracts.

## When asked to run the tests

1. Run `bash validate-all.sh` for structural/examples checks. Record command, exit
   code, count and revision; distinguish missing optional skills-ref from a pass.
   Do not call this a client migration test or weaken checks to obtain green results.
2. Read `evals/cases.json`, `evals/catalog-cases.json` and `evals/workflow-cases.json`.
   Use isolated fixture roots, safe synthetic content and the actual host agent
   with the Skill loaded. The rubrics are inputs, not completed behavior runs.
3. Record actual installed clients/harnesses/versions. Do not install products or
   touch the operator's real HOME without separate authorization.
4. Execute available rows in `evals/client-matrix.json` using client-tests.md.
   Every requested category must be present/absent/unknown/not-applicable with
   evidence. Unavailable clients are `blocked-environment`, never `pass`.
5. For each run save a redacted trace, before/after diff, native discovery evidence,
   activation negative case, unchanged neighbors and repeat-run outcome. Use
   [result template](references/result-template.md). Never publish private data.
6. Fix the smallest guidance/fixture issue. Re-run the failed case and its nearby
   negative case. Do not build a converter engine instead of explaining semantics.
7. Summarize passed, failed, blocked and not-run separately. Update the queue and
   remaining-work evidence only for checks actually performed.

## Editing and review rules

- Select product/profile/version/OS/harness before choosing a path. Use primary
  vendor docs and installed schemas; a third-party installer is discovery only.
- Preserve all context categories, not just those a previous script understood.
  Unknown native formats get a precise evidence gap, not a guessed file or blanket
  unsupported label. Cloud/UI objects need supported reconstruction instructions.
- Preserve instruction scope/activation, invocation IDs, imports, environment-name
  mapping, package identity and target neighbors. Never transfer credentials,
  grants, raw history or generated state by default. Executable content stays parked.
- Product references are progressively loaded. Keep the main Skill below 150 lines;
  do not make agents read the entire catalog. New family docs require package
  allowlist, routing, source/evidence and coverage tests in the same change.
- Small deterministic helpers require a measured repeated need and owner agreement
  before they become runtime dependencies. Maintainer checks are not user runtime.
- Never count product Cartesian pairs as tested compatibility. No fake enabled flags,
  fake native support, or simulated Linux roots described as native Windows proof.
- Preserve established authorization; do not ask again for the same safe scoped edit.
- Delivery must reconcile logical object outcomes, including unchanged and failed;
  distinguish syntax, discovery, activation and runtime evidence. No transaction
  guarantee follows from a report template or a historic engine test.

## Done / publication

A real migration case improves, source/format evidence is explicit, intended diffs
are small, structural checks pass and real-client results are reported honestly.
Unverified rows stay pending. Publication, tags, marketplace uploads, account/payment
changes and schedules require their own authorization; repository updates are not
proof of a released or installed Skill.
