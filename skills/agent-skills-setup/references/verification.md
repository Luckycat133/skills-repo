# Verify content and behavior separately

Use the host agent's existing tools. Do not install a verification service or run
imported commands. Validate the smallest representative change before expanding.

## Before writing

Resolve every final destination and scope; inspect current content and imports.
Do not place a backup under an auto-loaded rules/skills directory. A project Git
diff is useful, but do not stage, commit, reset or discard unrelated user changes.
For untracked/global settings, make an exact private backup of only the files to
be changed; never put credential-bearing backups into a portable transfer folder.

Re-read the target immediately before editing. If it changed, recompute the diff
instead of overwriting concurrent edits. Reject unknown symlink destinations or
path traversal; resolve the actual environment rather than mixing OS paths.

## After writing

| Check | Evidence to keep |
| --- | --- |
| Syntax | JSON/TOML/YAML/frontmatter parser result, with secret values omitted |
| Content | Same intended instructions, Skill assets and approved server definitions |
| Scope | Representative matching and non-matching files; user/project boundaries |
| Imports | Referenced files exist and remain within approved roots |
| Existing state | Unrelated keys, other Skills, disabled state and restrictions preserved |
| Conflict handling | Conflicting objects left untouched; independent objects applied |
| Idempotence | A repeat review finds no duplicate sections or needless overwrite |
| Host discovery | Actual target UI/list evidence, when safely available |
| Runtime | Only an explicitly approved execution/connection test can prove this |

Do not equate a valid config with host discovery, or discovery with a successful
connection. Do not report simulated fixtures as real IDE tests. Status/list commands
can start servers; inspect their side effects first.

## Report

Use the report template when requested or when deferred work needs to travel.
Otherwise a short summary is enough: changed paths, conversions, conflicts/losses,
manual/auth steps, exact checks, and checks not run. Never say "all migrated" when
requested prompts/agents/memory were not even inventoried.

## Recovery

If an edit fails validation, restore only the files changed in this task from the
reviewed backup, and only if they have not subsequently changed. Do not restore an
entire config tree or run `git reset --hard`. Explain any concurrent-edit conflict.
The Skill teaches careful recovery; it does not claim a universal atomic rollback.
