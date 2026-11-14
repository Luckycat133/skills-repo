# CLI, Registry v2 and delivery review — 2026-11-14

## Pinned baseline and scope

Repository: Luckycat133/skills-repo. Inspected main:
`4f7b343ac0e909119ecc07efe1e98ec219136b11`, merged on 2026-11-13.
Canonical metadata: `0.11.0-dev`. This review changes guidance and maintainer tests,
not product capabilities, client paths, archived evidence dates or a public release.

The request reported a local passing suite including 52 Skill-format checks, more
than 50 IDE mappings, compact manifests and runtime transactions. That local source
revision and log were not uploaded. Preserve the result as user-reported; do not
reject it, attribute it to current main or recreate an engine to match the wording.

Current main has the agent-first reset: no user runtime CLI, ACB or transaction
engine. Its validate-all.sh discovers two unittest modules with 22 test methods and
optionally runs skills-ref. GitHub reports the baseline's three Validate jobs and
Python/Actions analysis as successful. Real-client results in the committed catalog
remain not-run. A possible unpushed local branch is outside this review's evidence.

## Findings and changes

| Finding | Change in this PR | Boundary retained |
| --- | --- | --- |
| Old CLI/test terminology can be mistaken for the current architecture | Add native/maintainer/retired CLI distinctions and exact-checkout review instructions | No runtime script restored |
| Archived Registry v2 policies and paths can look authoritative | Add field interpretation, current catalog routing and per-surface evidence requirements | Archive and its dates remain unchanged |
| Delivery template omitted explicit unchanged/failed outcomes and precise evidence levels | Add reconciled object outcomes and syntax/discovery/activation/runtime results | No state database or transaction claim |
| Preview and recovery guidance did not explicitly cover all artifacts/concurrent edits | Require preview without unrequested files and conditional task-only recovery | No broad reset or hidden installs |
| Local test reports lacked required revision and provenance fields | Expand developer result template with commit, dirty state, command, count and evidence | Local assertions are not automatically published as observed results |

The package helper keeps its existing explicit allowlist and 220 KB budget. Only
cli-workflow.md and registry-v2.md are admitted; the user package has 43 guidance/
LICENSE files. Existing package security/overwrite/reproducibility tests are retained.
The core Skill is 123 lines. No engine code, dependencies or automatic schedules added.

## Validation evidence for this change

- Local: 10 new tests in tests/test_workflow_contract.py passed against the prepared
  changed-file set. They validate wording/routing/allowlist/rubric contracts, not
  host-agent behavior. Modified Python files also compiled successfully.
- Local full checkout/official validator: not run; container GitHub DNS access failed.
  The previous preview ZIP was not used as a substitute for the current checkout.
- Full remote CI: consult the PR's exact head checks. Baseline green results do not
  apply to later commits. No full-suite pass is asserted in advance in this document.
- New evals/workflow-cases.json: 10 cases, all behavior-not-run. They join the existing
  15 + 21 scenario definitions, without altering the 90-entry native-client queue.
- This review did not re-verify every vendor's current docs or run a native IDE.

## Reproduce after pulling

Record the branch, HEAD and dirty state, then run:

```bash
bash validate-all.sh
python3 -m unittest discover -s tests -p 'test_workflow_contract.py' -v
```

The full unittest suite is expected to discover the existing 22 plus the new 10
checks on this revision; record the actual count and exit status, not this expectation
as evidence. CI separately validates both Skill directories with pinned skills-ref.

Run real agent cases using the developer Skill, not a homemade conversion engine.
Start with a scoped Cursor-to-Claude rule, a selected MCP JSON-to-Codex TOML mapping,
and ordinary-folder device transfer. Include a nonmatching trigger, preserved target
settings, a duplicate/no-op, and a blocked native-discovery result. These are proposed
acceptance priorities, not new claims of compatibility.

## Remaining acceptance work

1. Associate the user's local test log with its actual commit and loaded Skill path.
2. Run available real host-agent scenarios and capture redacted tool traces/diffs.
3. Observe native discovery and positive/negative activation independently of parsing.
4. Record unavailable clients/hosts as blocked; do not convert pending rows to pass.
5. Only after those results, revise the smallest affected conversion guidance.

No merge, tag, Release, marketplace upload or account setting change is authorized
by this PR. Main protection and the guidance-only product boundary are unchanged.

## Sources used for guidance standards

- Agent Skills specification: https://agentskills.io/specification
- Authoring best practices: https://agentskills.io/skill-creation/best-practices

Reviewed 2026-11-14. Product-family research retains its own 2026-11-07 dates; this
workflow review does not refresh vendor compatibility evidence.
