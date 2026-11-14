# Native-client run result

- Run ID/date:
- Repository branch / commit SHA / dirty state:
- Loaded Skill path / metadata.version / digest:
- Product/profile/version and exact harness:
- Host agent/model/version:
- OS, local/remote execution environment and isolated logical roots:
- Catalog entry / evidence date / official or installed schema source:
- Case ID / actual user request / authorization boundary:
- Overall status: not-run | pass | fail | blocked-environment | blocked-documentation | not-applicable
- Provenance: independently observed | user-reported (identify which statements)

## Repository checks (not client tests)

| Exact command | Exit code | Test count and coverage kind | Log/evidence path |
| --- | --- | --- | --- |

Record official skills-ref separately; missing means not-run, not pass. Do not copy
an older run's counts or describe example assertions as runtime transactions.

## Category inventory

| Native name / category | Present/absent/unknown/N-A | Scope/loader | Evidence |
| --- | --- | --- | --- |

## Object outcomes

| Logical object | Target | copied/converted/unchanged/conflict/draft/deferred/excluded/failed | Reason |
| --- | --- | --- | --- |

Count selected logical objects once; total must reconcile. Unknown inventory is not
an excluded object. A partial migration cannot become pass by omitting failures.

## Actual behavior evidence

| Check | pass/fail/not-run/blocked | Redacted evidence and reason |
| --- | --- | --- |
| Source unchanged / authorized paths only | | |
| Syntax | | |
| Content / imports / neighbors preserved | | |
| Matching and nonmatching scope | | |
| Native discovery | | |
| Activation | | |
| Explicitly authorized runtime / connection | | |
| Repeat review / concurrency | | |
| Device move / different roots, when selected | | |

Attach synthetic before/after files, redacted tool trace and diff. Record command
side effects; no unrequested hook execution, server connection, install or auth.

## Failure or remaining action

Exact mismatch, reproduction, version, proposed minimal guidance fix and rerun case.
Recovery must be limited to this task's edits and checked against concurrent edits.
Never attach raw HOME config, secret values, private paths, real history or account
identifiers. Use logical roots in portable evidence. A success applies only to the
recorded case/profile/version/OS; no brand-wide or transaction guarantee follows.
