# Roadmap

## Next

- Automate release provenance and security-report retention.
- Support reviewed multi-skill imports.
- Add a non-intrusive OpenClaw validation mode.
- Add `skills.sh` compatibility checks and reusable release assets.

## Engineering backlog

- Make remaining per-IDE manual guards data-driven.
- Share redaction and copy/strategy logic without weakening fail-closed behavior.
- Harden temporary cleanup, copy errors, timestamp collisions, and missing dependencies.
- Extend malformed-input, read-only-target, and non-MCP-object tests.

Completed path single-sourcing is recorded in [HI-001](HI-001-ide-paths-single-source.md). Version 0.7.1 completed explicit permission metadata, exact-target/copy-root cleanup guards, and MCP symlink-target regression coverage.
