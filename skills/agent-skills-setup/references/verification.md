# Verify content and behavior separately

Use existing host tools. Do not install verification services or run imported
commands. Check a representative case first; see [CLI workflow](cli-workflow.md).

## Before writing

Confirm destinations, scope, imports and current contents; re-read if concurrent
edits appear. Refuse traversal, out-of-root links and mixed host paths. Back up
only affected files, privately and outside auto-load trees. Never include
credential-bearing backups in transfer output. A preview writes no files or
reports unless requested. Preserve unrelated Git changes and config.

| Evidence | Requires | Does not prove |
| --- | --- | --- |
| Structure/example | Package checks or deterministic fixtures | Agent/IDE behavior |
| Syntax | Actual parser and redacted result | Discovery, activation or connection |
| Content | Body, imports, scope and matching/nonmatching cases | Native loading |
| Native discovery | Observed loader/UI, version, host and OS | Invocation or connection |
| Activation | Positive and negative native invocation | Broad compatibility |
| Runtime/connection | Separately authorized execution and observed outcome | Safety for every server |

Mark `pass`, `fail`, `not-run` or `blocked` with reasons. Unavailable clients do
not imply syntax failure; syntax success is not discovery. Even status/list
commands can start servers: check side effects and authorization first.

Check fixture-level no-op proofs, no preview or outside-root writes, rejection of
tracked secret writes, private backups, and permissions (0700 directory, 0600
secret files). Output names/fingerprints only, never raw values.

## Delivery and recovery

Account for all selected logical objects, including prompts/agents/memory.
Mark each copied, converted, unchanged, conflict, draft, deferred, excluded or
failed. Reconcile counts without double-counting aliases or hiding siblings.
Report source/target, scope, semantic loss, dependencies, unchanged neighbors,
repeat-run result, residual risks and approvals. A mixed result is partial.
Report syntax, native discovery, activation and runtime separately, never call
not-run fully verified. Do not imply an implicit install, connection or hook run.

Use the [report template](../assets/migration-report.md) when requested or when work
must travel. Use logical roots in a portable/public report, never private paths,
usernames, identities or raw logs. Review redaction manually. Keep executable
drafts and backups outside auto-load paths; omit credentials, trust and history.

Recover only this task's edits from reviewed backups, only if current contents
still match the last write. Preserve concurrent edits and report conflicts.
Never claim universal atomic rollback, restore an entire tree, or hard-reset
Git. Re-read and recompute before another attempt.
