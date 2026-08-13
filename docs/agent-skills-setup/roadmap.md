# Roadmap

## Completed audit remediation

- Registry v2 is authoritative for product/profile/version/surface/scope and
  evidence-backed support levels; no profile is advertised as `full`.
- The public wrapper keeps legacy lookup/dry-run compatibility but blocks every
  legacy write; all public writes require a saved Registry v2 plan.
- Profile-aware migration uses a replayable, checksummed plan, credential-free
  diff or cloud rebuild manifest, Git provenance, atomic apply, verification,
  and guarded rollback.
- Instructions and MCP use explicit adapter registries. JSONC has a reviewed
  parser; JSON5, TOML, YAML, XML, Lua, and ambiguous UUID/JSON storage fail to a
  dedicated manual adapter rather than a generic JSON fallback.
- Profile contracts cover minimal, complete, legacy, invalid, secret, and alias
  conflict fixtures. Scheduled documentation freshness checks track curated
  official sources.

## Next

- Automate release provenance and security-report retention.
- Support reviewed multi-skill imports.
- Add a non-intrusive OpenClaw validation mode.

## Engineering backlog

- Promote a manual profile only after official, versioned schema evidence and a
  dedicated adapter/fixture contract exist.
- Retire the internal compatibility engine after downstream legacy callers have
  migrated to saved plans.
- Harden temporary cleanup, copy errors, timestamp collisions, and missing dependencies.
- Extend malformed-input, read-only-target, and non-MCP-object tests.

Completed path single-sourcing and the compatibility boundary are recorded in
[HI-001](HI-001-ide-paths-single-source.md).
