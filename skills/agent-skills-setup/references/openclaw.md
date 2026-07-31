# OpenClaw Migration Reference

Use this reference only when OpenClaw is the named source or target of a
cross-IDE migration. It describes file-backed migration boundaries; it does not
authorize software management, registry publication, dependency execution, or
unrelated changes to the user's OpenClaw state.

## 1. Supported paths

| Object | Supported path | Boundary |
|---|---|---|
| Managed Skills | `~/.openclaw/skills/` | Named directories only |
| Workspace Skills | `<active-workspace>/skills/` | Requires the explicit workspace |
| Project-agent Skills | `<active-workspace>/.agents/skills/` | Requires the explicit workspace |
| Rules/context | `<active-workspace>/AGENTS.md` | Review before merging |
| MCP/config | `~/.openclaw/openclaw.json` | Explicit opt-in; shared JSON file |

OpenClaw has no fixed project configuration root. The active workspace is a
runtime choice, so never infer it from the current directory or search the home
directory for candidates. Ask the user for the workspace when project scope is
needed.

## 2. MCP schema

OpenClaw stores MCP servers under the nested JSON path `mcp.servers`.

- Local servers use `command` plus optional `args`.
- Remote servers require `url` and `transport: "streamable-http"`. This is a
  client configuration choice, not a license to relabel a legacy SSE endpoint:
  use a Streamable HTTP URL supplied by the server owner and let OpenClaw
  negotiate protocol details at runtime.
- Reject entries that mix local and remote endpoint shapes.
- Blank literal credentials before writing. Preserve only an exact symbolic
  environment reference whose target syntax is documented.
- Preserve unrelated top-level keys in `openclaw.json` for every strategy.
- Treat invalid existing JSON as a hard stop; never replace it with a guessed
  structure.

The mapper performs static conversion and validation only. Runtime connectivity,
OAuth state, and server permissions remain manual verification steps.

## 3. Skills and rules

Copy only the named Skill directories selected by the user. Preserve each
directory as a unit, including `SKILL.md`, `scripts/`, `references/`, and
`assets/`. Do not mirror every discovered directory.

For workspace rules, treat `AGENTS.md` as living user content. Preview the
proposed merge and preserve the existing file under `skip` or `backup` as
selected. Hooks, generated memory, session history, and workspace databases are
outside the migration boundary.

## 4. Secret and deletion boundaries

- MCP and config are never part of the default object set.
- Exclude `.env` and `.env.*` files from copied trees; leave the source intact.
- Redact supported copied configuration before the target write.
- If redaction fails, remove only the copy created for the selected object.
- Resolve the selected parent path, reject traversal and symlink escapes, and
  refuse cleanup outside that parent.
- Do not accept literal secret values as migration parameters.

## 5. Safe migration workflow

The first command is always a value-free preview. It parses the selected source
but creates no target output:

```bash
bash scripts/smart-ide-migration.sh \
  --source cursor \
  --target openclaw \
  --workspace /reviewed/workspace \
  --objects skills,rules \
  --dry-run
```

Review the resolved paths, selected objects, conflict strategy, and any manual
boundaries. Only after the user explicitly approves that exact plan may the
same migration be applied:

```bash
bash scripts/smart-ide-migration.sh \
  --source cursor \
  --target openclaw \
  --workspace /reviewed/workspace \
  --objects skills,rules \
  --strategy backup \
  --yes
```

An apply can create or replace only the reviewed migration objects. Existing
objects follow `skip`, `backup`, or `overwrite`; `backup` is the default.
Unsupported schemas remain manual, and no fallback copies an unvalidated input.

## 6. Verification

Prefer `--json` for deterministic evidence. Confirm:

1. the resolved source and target match the reviewed paths;
2. the source digest is unchanged;
3. the target exists and parses as the documented format;
4. any backup path is reported and confined to the selected parent;
5. secret-bearing copied values are blank and `.env*` files are absent.

Static validation does not prove live service connectivity. Report that boundary
instead of running unrelated runtime commands automatically.
