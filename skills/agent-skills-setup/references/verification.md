# Verify content and behavior separately

Validate syntax, permissions, and containment deterministically; never claim live IDE
discovery or runtime server connectivity from static file checks alone.

## Before writing

- Run `--dry-run` first when previewing; `--dry-run` performs zero target writes and
  creates zero backup directories.
- Reject `..` traversal and symlinks resolving outside `--workspace`, `--home`, or
  `--input`.
- Check Git tracking status before writing literal secrets: refuse silent writes into
  Git-tracked files (or route Claude project secret MCP to `~/.claude.json`
  `projects[workspace].mcpServers`), and warn when a new `0600` secret file is not yet
  matched by `.gitignore`.
- Back up any existing destination file before modification into a `0700` directory
  with `0600` file permissions (`~/.agent-skills-setup-backups/<timestamp>-<pid>/`),
  never inside an auto-loaded rules/skills tree or portable transfer folder.

## After writing

| Check | Evidence |
| --- | --- |
| Syntax | `json.loads` / `load_jsonc` / `tomllib.loads` / frontmatter parse (zero secret values printed) |
| Permissions | Secret-bearing files, backups, and `export-device` outputs have `0600` mode (`0700` dirs) |
| Zero leak | `stdout`, `stderr`, and `MIGRATION.md` contain key names + `sha256[:8]` only, never secret values |
| Scope & neighbors | Representative matching/non-matching paths; sibling keys (`theme`, `approval_policy`) intact |
| Conflict isolation | Divergent same-name objects recorded as `conflict`; independent siblings applied |
| Idempotence | Immediate re-run reports `noop` with zero duplicate sections or needless backups |
| Host discovery | Native client list/UI evidence when available; otherwise `not-run` |
| Runtime | Live MCP connection or hook execution only when separately authorized; otherwise `not-run` |

## Recovery

If validation fails, restore only the files modified in this run from the private
`0600` backup folder (`backups` array in `migrate_context.py` JSON output), provided no
concurrent user edits occurred afterward. Never run `git reset --hard` or delete
unrelated user files.
