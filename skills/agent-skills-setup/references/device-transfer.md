# Device transfer without a proprietary platform

A single natural-language request ("I'm changing computers, export all my AI coding
configs" or "restore this folder on my new computer") authorizes bounded discovery
and plain-folder export/import. Never create `.acb` archives, signing keys, SQLite
stores, background sync daemons, or auto-running restore scripts.

## Export on the old computer (`export-device`)

Run `scripts/migrate_context.py export-device` to create a `0700` folder with `0600`
files, a SHA-256 `manifest.json`, and a completely redacted `MIGRATION.md`:

```bash
python3 "<SKILL_DIR>/scripts/migrate_context.py" export-device \
  --profiles antigravity,claude-code,codex --scope all --workspace . --output ~/context-transfer
```

- **Optional `--output` & clobber refusal**: Defaults to `~/context-transfer-<UTC>` if omitted; exits with code `2` if `--output` already exists or sits inside an auto-loaded Skills/rules directory.
- **Full-copy bundle (`0700`/`0600`)**: Copies complete files by value (never symlinks) including `.env*`, extracted `mcpServers` / `[mcp_servers]`, and portable `settings` (with `env`/`model_providers` secrets in `0600`, stripping `permissions`/`approval_policy`/`sandbox_mode`/OAuth state) without printing secret values to `stdout`, `stderr`, or `MIGRATION.md` (which records only logical `$HOME`/`$WORKSPACE` paths, variable names, and `sha256[:8]` fingerprints). Pass `--redact-secrets` when transferring over an untrusted channel or when the user asks to omit keys.
- **Bundle layout** (only `export-device` creates a bundle directory):
  ```text
  context-transfer/          # 0700
    MIGRATION.md             # 0600, human-readable, zero secret values + restore command
    manifest.json            # 0600, per-file SHA-256 checksums and logical scopes
    files/<profile>/<scope>/ # 0700 dirs, 0600 files (0700 on skill scripts/*)
    review/{hooks,sidecars,rules}/ # 0700/0600 segregated executable/hook payloads
  ```
- **Always excluded**: Chat histories, `*.jsonl` transcripts, SQLite/LevelDB databases (`state.vscdb`, `*.db`), Codex `memories`/`memories_v2`, plugin caches, vector indexes, cookies, JWT/OAuth tokens, built-in system skills, and approval/trust/permission grants.

## Restore or cross-migrate on the new computer (`import-device`)

Treat the incoming folder as untrusted data: never execute bundled scripts or follow
symlinks escaping the folder. `import-device` validates path containment and verifies
every file's SHA-256 against `manifest.json` before writing:

```bash
# Restore only selected tools on the new machine (rebinds $HOME and $WORKSPACE):
python3 "<SKILL_DIR>/scripts/migrate_context.py" import-device \
  --input ~/context-transfer --target same --profiles antigravity,claude-code,codex --workspace .

# Or cross-migrate exported context directly into different tools on the new machine:
python3 "<SKILL_DIR>/scripts/migrate_context.py" import-device \
  --input ~/context-transfer --target claude-code,codex --workspace .
```

- **Strict scoping & zero stray directories**: Use `--profiles` to restore only the requested IDEs when the bundle holds multiple profiles. Neither `migrate` nor `import-device` creates `.migration-review/` or `~/.agent-skills-setup-backups/` — overwrite backups are written only when `--backup-dir <dir>` is explicitly supplied, and unactivated hooks, sidecars, or incompatible items are returned cleanly as structured `agent_handoff` entries in stdout JSON (pass `--activate-hooks` when you want compatible hooks/sidecars restored live).
- Merges root instructions idempotently and merges MCP per server name without clobbering unrelated settings on the new computer, isolating divergent items as `conflict`.
- Report restored paths, conflicts, `agent_handoff` items, unverified live connections, and re-authentication steps honestly; do not claim "fully restored" when OAuth or runtime checks remain.

## Existing legacy `.acb` backups

Do not delete old `.acb` backups or resurrect the retired engine. If a user asks to
salvage an old backup, inspect its files read-only (rejecting `..` and escaping
symlinks), extract only reviewed safe content into a fresh folder, and apply the normal
workflow above. Report unknown legacy fields explicitly rather than guessing.
