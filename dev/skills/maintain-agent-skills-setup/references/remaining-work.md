# Remaining work after the 2026-11-16 script & reference upgrade

## Completed in this branch

- Agent-first scope reset preserved: no `.acb` engine, signing service, SQLite store,
  background daemon, auto-installer, telemetry, or fake Cartesian matrix.
- Added `skills/agent-skills-setup/scripts/migrate_context.py` (Python 3.11+ stdlib,
  PEP 723 metadata) supporting `inspect`, `migrate`, `export-device`, `import-device`,
  and `patch-mcp` with zero-context-leak `0700`/`0600` out-of-band secret handling,
  `--redact-secrets`, Git-tracked secret protection, JSONC/TOML/MDC parsers, idempotent
  Markdown section markers, and private `0600` backups.
- Enriched `references/` and all 30 `references/products/*.md` family docs with concrete
  candidate paths, root keys, frontmatter fields, and env interpolation rules while
  keeping the packaged Skill comfortably under `260,000` bytes.

## Pending: real native-client runs

1. Run [client-tests.md](client-tests.md) with `skills/agent-skills-setup/` loaded in
   available native clients from `evals/client-matrix.json`. Keep unavailable GUI/IDE
   clients marked `blocked-environment` or `not-run` — never `pass`.
2. Resolve `discovery-required` contracts (`iflycode`, `raccoon-ai`, `vecli`/`ark-cli`,
   International `trae`, `pearai`, `coder-xum`, `claude-desktop`) on actual installed builds.
3. Confirm version-sensitive local surfaces (`amazon-q` global MCP path, `forge` home
   root, `windsurf`/Devin Local harness, `kiro` CLI v2 vs v3, `opencode` v1 vs v2,
   active VS Code harness, `kimi-code` `KIMI_CODE_HOME`, `ibm-bob` IDE vs Shell).
4. Run native Windows/WSL/SSH-remote home and cloud/UI cases on real machines.
5. Before any separately authorized release, recheck vendor URLs, run `validate-all.sh`
   including `skills-ref`, build and inspect the zip archive, and obtain explicit owner
   approval for tagging or marketplace upload.
