# Review the actual checkout and its delivery contract

Use when a maintenance request cites a passing CLI/Registry v2/transaction suite,
or when reviewing CLI guidance, product evidence or delivery templates.

## Reconcile versions before changing architecture

Record remote branch/commit, local HEAD and dirty state, loaded Skill path/version,
and the exact validation command. Never reset or discard local changes to align them.
A local test log belongs to its recorded checkout, not automatically to remote main.
If the source/log is unavailable, preserve the user's statement as user-reported,
state what is independently observable and continue on the pinned available baseline.

On main at `4f7b343ac0e909119ecc07efe1e98ec219136b11`, the 2026-11-13 merge of PR #31
retired the migration CLI and runtime transactions. `validate-all.sh` discovers
unittest structural/example checks and optionally invokes skills-ref. That baseline
contains 22 unittest methods, not the former engine suites. This is a historical
baseline observation, not a permanent expected test count.

Do not recreate retired scripts to make a stale checklist look green. Read the
canonical `references/cli-workflow.md`, `references/registry-v2.md` and
`references/verification.md`. The archived Registry is research input, not a current
executor/schema authority. Preserve historical files rather than silently updating
old evidence dates or importing old policies as permission to write.

## Review code and checks at the right level

- Inspect the package allowlist and its budget; add selected Markdown references
  explicitly. No dev/eval/history material or runtime code enters the user package.
- Confirm all live references resolve, SKILL.md stays under 150 lines, and commands
  in prose exist in the selected checkout/client. Generic terminal syntax is not
  evidence of a vendor command contract.
- Check structural tests and fixtures for false certainty: string presence and
  parsed examples are not agent runs. Keep case definitions unrun; record execution
  evidence separately, not by changing expected examples into alleged outputs.
- For catalog updates, record sources/dates/version boundaries per affected profile.
  Do not refresh all dates because one contract was edited. No Cartesian support count.
- For delivery, require per-object outcomes and separate syntax/discovery/activation/
  runtime results. Keep unchanged, failed and deferred objects visible.

## Validation procedure

1. Record `git rev-parse HEAD`, `git status --short`, loaded Skill digest/version,
   Python version and exact command in a private or redacted run report.
2. Run `bash validate-all.sh` in the actual checkout. Capture exit code and counts;
   if skills-ref is absent, report its NOT RUN separately. CI requires it.
3. Verify that packaging includes only allowlisted guidance, and that no executable
   migrator or historic Registry is introduced by this change.
4. Execute `evals/workflow-cases.json` with a real host agent in isolated fixtures,
   alongside affected cases in the existing eval files. Do not give the agent the
   expected rubric. Review its file edits and tool trace, not only its final claim.
5. Test at least a preview with no artifacts, an authorized safe conversion, a
   stale saved diff, a shared-settings subobject and a result with native checks
   blocked. Preserve unrelated content and re-run for idempotence.
6. Record actual results via result-template.md. Update client-matrix only for
   installed clients actually observed; do not mark unavailable clients pass.
7. For a PR, record its exact head SHA and CI job results. A previous green head
   does not validate later edits. No tag, marketplace upload or merge is implied.

## Acceptance

The Skill helps the agent choose native tools without recreating an application;
old Registry claims cannot authorize writes; all selected objects are accounted for;
outputs preserve scope/restrictions and neighbors; unsupported checks remain explicit.
The test result identifies what ran, at which revision and with which host/client.

Primary guidance: [Agent Skills specification](https://agentskills.io/specification)
and [authoring best practices](https://agentskills.io/skill-creation/best-practices),
reviewed 2026-11-14. They support focused instructions, conditional reference loading
and real execution feedback; they do not certify this repository's product catalog.
