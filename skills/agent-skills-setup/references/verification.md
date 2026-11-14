# Verify content and behavior separately

Use the host agent's existing tools. Do not install a verification service or run
imported commands. Validate the smallest representative change before expanding.
For native command side effects, use [CLI workflow](cli-workflow.md).

## Before writing

Resolve every final destination and scope; inspect current content and imports.
Do not place a backup under an auto-loaded rules/skills directory. A project Git
diff is useful, but do not stage, commit, reset or discard unrelated user changes.
For untracked/global settings, make an exact private backup of only the files to
be changed; never put credential-bearing backups into a portable transfer folder.

Re-read source and target immediately before editing. If either changed, recompute
the diff instead of overwriting concurrent edits. Reject unknown symlink destinations
or path traversal; resolve the actual execution environment rather than mixing OS paths.
A preview-only request must not create backups, reports or temporary files unless
that particular output was requested. A saved review is not a license to ignore drift.

## Evidence levels

| Level | Required evidence | Does not prove |
| --- | --- | --- |
| Structure/example | Package/link checks or a deterministic fixture expectation | Actual Agent behavior or IDE compatibility |
| Syntax | Parser/tool, selected output and redacted result | Discovery, activation or connection |
| Content/semantics | Approved body, imports, scope, matching and nonmatching cases | That the live target loaded it |
| Native discovery | Installed target version/harness/OS and observed loader/UI result | Successful invocation or server connection |
| Activation | Actual positive and negative invocation/trigger observations | Broad version or platform compatibility |
| Runtime/connection | Separately authorized execution and its observed result | Safety or compatibility for every server |

Mark each check `pass`, `fail`, `not-run` or `blocked` with a reason. An unavailable
client is not a syntax failure; a parse success is not native discovery. Status/list
commands can start servers: verify side effects and authorization before running.

## Delivery checklist

- [ ] Every requested category is inventoried as present, absent, unknown or
      not-applicable with evidence; prompts/agents/memory were not silently omitted.
- [ ] Each selected logical object has one outcome: `copied`, `converted`,
      `unchanged`, `conflict`, `draft`, `deferred`, `excluded`, or `failed`.
- [ ] Counts reconcile to selected logical objects, not files or alias occurrences;
      directories/servers are counted consistently. Conflicts do not hide siblings.
- [ ] Final source/target paths, profile, scope and semantic losses are explicit;
      executable drafts and backups are outside every live auto-load path.
- [ ] Syntax, content, scope/imports and unchanged neighbors have recorded checks.
      Repeat review does not append duplicates or overwrite newer unrelated edits.
- [ ] Native discovery, activation and runtime checks are independently reported;
      failed, blocked and not-run checks cannot be summarized as fully verified.
- [ ] Credential values, trust grants, raw history and unrelated settings are absent
      from portable outputs; variable names and re-authentication actions suffice.
- [ ] Remaining conflicts, approvals, dependencies and concrete next actions are
      listed. No install, hook execution or server connection occurred implicitly.
- [ ] Recovery covers only this task's edits, private backups and concurrent-change
      limits; do not claim a universal atomic transaction or rollback engine.

## Report

Use [the report template](../assets/migration-report.md) when requested or when
remaining work must travel; otherwise use the same compact fields in conversation.
Separate completion from verification: `converted` can still have native discovery
`not-run`. A mixed result is `partial`, not "all migrated". Retain failed objects
in the report rather than omitting them from a success count. A no-op needs a
comparison proving unchanged content, not merely a zero exit code.

A private local report may identify approved backup paths. A portable/public report
must use logical roots such as `<source-user>` and `<target-workspace>`, never home
usernames, private repository identities, credential-bearing backups or raw logs.
Review redaction manually; neither a scanner nor an Issue form guarantees secrecy.

## Recovery

If an edit fails validation, identify edits already completed. Restore only the
files changed in this task from the reviewed backup, and only if their contents
still match this task's last write. Preserve concurrent edits and report the conflict.
Do not restore an entire config tree or run `git reset --hard`. Resume by re-reading
current state and making a fresh scoped diff; never replay stale shell commands.
