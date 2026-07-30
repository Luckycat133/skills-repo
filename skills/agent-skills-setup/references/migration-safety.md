# Migration safety and conflicts

Use this reference when a migration may write configuration. It offers
practical defaults for keeping the plan reviewable; explain any intentional
departure to the user.

## Path and input boundaries

- Prefer the two IDEs and optional workspace named by the user over broad
  discovery. This keeps the plan understandable and limits incidental data.
- Treat source and target paths that resolve to the same file, including
  symlinks, as a reason to discuss intent before continuing.
- When JSON, JSONC, TOML, YAML, or a transport is unsupported, describe the
  manual option rather than presenting an unvalidated copy as equivalent.
- Excluding copied `.env` and `.env.*` files usually avoids moving unrelated
  credentials; preserve the source copy regardless of the target strategy.

## Credentials and destructive operations

- A dry run is useful because it parses the selected source without creating
  target output or exposing raw configuration values.
- The bundled script blanks literal credentials. It can preserve or translate
  an exact documented environment reference; mixed, default, and command-
  substitution syntax benefit from manual review.
- If redaction cannot establish a safe result, explain that outcome and offer a
  manual reconstruction. The script limits target-tree removal to containment
  and symlink-guarded paths.

## Conflict strategies

| Strategy | Existing selected object |
|---|---|
| `skip` | Preserve it and leave that object unchanged. |
| `backup` (default) | Create `.bak.<timestamp>`, then merge; same-name source entries become active. |
| `overwrite` | Replace only the selected object, without a backup. |

For MCP in a shared configuration file, every strategy preserves unrelated
top-level settings. `overwrite` replaces the selected server map, not the whole
file. For directory-backed skills or projects, the selected same-name directory
or tree is the object. When another strategy is requested, clarify its desired
semantics before resolving or writing; a renamed `<name>_migrated` entry is not
part of the built-in strategies.

## Preview and consent

An effective first response restates source, target, objects, scope, and
workspace; calls out manual boundaries or credential risk; and offers an exact
`--dry-run` command. Keep the distinction between a preview and an apply clear.

After approval, the bundled script uses `--yes` for writes and `--json` is often
the clearest reporting mode. Share resolved paths, parse result, source
integrity, target evidence, backup path, and any manual follow-ups.
