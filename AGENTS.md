# Repository instructions

This repository maintains an Agent-First Skill (`skills/agent-skills-setup/`) that
helps an existing coding agent migrate, compare, or transfer AI coding context across
tools and devices. It is not a standalone migration platform. Read
[the development Skill](dev/skills/maintain-agent-skills-setup/SKILL.md) before changing it.

The publishable directory is `skills/agent-skills-setup/`. It contains concise
instructions (`SKILL.md`), on-demand references (`references/`), templates (`assets/`),
`LICENSE`, and one authorized zero-dependency Python 3.11+ stdlib helper script
(`scripts/migrate_context.py`). Do not reintroduce the retired `.acb` archive engine,
signing/key service, SQLite transaction store, background sync daemon, auto-installer,
telemetry, fake 90x90 compatibility matrix, or bulk self-copy.

`scripts/migrate_context.py` exists so a host agent can satisfy single-sentence
migration and device-transfer requests (including out-of-band secret migration by
default, or `--redact-secrets` when requested) without reading raw secret values into
LLM prompt context, `stdout`, `stderr`, or `MIGRATION.md`. Secret-bearing files,
private backups, and transfer folders must use `0700` directories and `0600` files,
protect Git-tracked project files against silent secret writes, and always exclude
chat histories, transcripts, databases, caches, indexes, and approval/trust grants.

Keep the migration script current. When a client adds a new profile, a path, or a
conversion, fix `scripts/migrate_context.py` in the same change instead of
describing the workaround in prose, and bump `metadata.version` in the published
Skill when published behavior changes. Users should verify the latest stable,
reviewed release and its immutable revision before use. Never run a migrator from
an unverified checkout.

Agents must not read `.env` files or other secret-bearing sources themselves. To
pack a device archive or migrate context on this machine, run
`scripts/migrate_context.py`; it moves credentials disk-to-disk without exposing
values to the prompt. Reading a secret file to move it by hand defeats the point of
the script.

Keep every requested context type in the inventory. Unknown formats require source
verification, not fabricated paths or a blanket unsupported label. Preserve scope,
activation, restrictions, user-authored memory, and unrelated target files. Never
equate a listed product in `references/products.md` with runtime certification.

Validation: `bash validate-all.sh` (or the Python commands inside it).
Maintainer tooling and behavior evals live outside the published Skill. Structural
and script tests do not prove real native IDE/GUI loading. Record unrun checks honestly.

Make focused commits on a branch; preserve `main` protection. Do not publish a
release, upload a marketplace package, change account settings, or request payment
unless separately authorized. Do not reintroduce the retired engine to fix a test.
