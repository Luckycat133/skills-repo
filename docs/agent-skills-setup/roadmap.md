# Roadmap

This document organizes the current state of the Agent Skills Setup into
fixed, verifiable buckets. The shape is intentionally different from the
old "Completed / Next / Engineering backlog" split — that layout hid
experimental capabilities behind neutral-sounding "Next" milestones and
made it easy to misrepresent product-path support as production-ready.

## Production

These capabilities are self-contained, offline-safe, and covered by the
exact-release CI matrix on `ubuntu-latest`, `macos-latest`, and
`windows-latest`.

- `Registry v2` is the sole source of product / profile / version /
  surface / scope / evidence-backed support levels. No profile is
  advertised as `full`.
- Plan / apply / verify / rollback are profile-aware, replayable, and
  checksummed. Every plan item carries a stable `object_id`.
- ACB (`snapshot`, `bundle-verify`, `restore`, `doctor`) writes a
  closed-world, atomic-staged bundle with a 1:1 manifest-to-object
  binding validated by SHA256.
- Bundles are signed with HMAC-SHA256 over `checksums.json`. Ed25519 is
  deferred to a vendor of `cryptography` or `nacl`.
- `--all-installed` snapshot and restore use real detection results as
  the only source of truth (no `inventory.exists` fallback) and
  iterate plan items, not inventory rows.
- MCP / Instructions / Skills use explicit adapter registries. JSONC
  uses a reviewed parser; JSON5 / TOML / YAML / XML / Lua / ambiguous
  UUID+JSON fail to a dedicated manual adapter.
- Apply uses a seven-status partial safe flow (`ready`, `ready-lossy`,
  `draft-disabled`, `manual-rebuild`, `forbidden`, `conflict`,
  `invalid`).
- Alias resolver follows `alias_of` chains iteratively with cycle,
  depth, and unknown-selector guards.
- macOS path expansion and `~` resolution are deterministic.
- `secrets.required.json` and `reauth.json` are non-secret metadata only.

## Experimental

These work in restricted environments but are not yet ready for
production-grade cross-platform guarantees.

- Windows / WSL / Remote-SSH / Dev-Container / Codespaces path
  resolution. The CI matrix now runs on `windows-latest` but path
  expansion tests do not yet cover WindowsPath, drive roots, UNC,
  junction / reparse points, or WSL host/guest `HOME` interaction.
- `--all-installed` end-to-end on those host classes. Plan build,
  parse, and atomic apply have been verified on macOS / Linux; the
  Windows smoke test is limited.
- ACB signed bundle cross-device handoff. HMAC is symmetric, so the
  security boundary remains "self-generated, self-transferred,
  self-restored" — third-party ACBs are not yet verifiable.
- Maintainer-side documentation freshness via `--max-age-days 30` to
  60. The 365-day window in `doc-freshness-checks.json` is too lax for
  products that ship schema changes monthly.

## Known limitations

- `cryptography` 50.0.0 is vendored at runtime via `pip install
  cryptography` for ACB sign / verify. It is not committed to the
  repo and the bundle path does not require it at snapshot time
  unless `--sign` is requested.
- `doctor` still surfaces requirements as a list of `executables` and
  `packages` parsed from MCP server configs. It does not run an
  install planner; it does not validate that the listed package
  actually exists.
- The OS / profile locations wiring covers `darwin`, `linux`, and
  `windows` deeply. `wsl`, `remote-ssh`, `dev-container`,
  `codespaces`, `vscode-profile`, and `extension-host` are stored on
  profiles but not yet lazy-evaluated at apply time.
- `Inventory_only` object types (`workflows`, `plugins`, `handoff`,
  `config`, `policy`, `trust`, `user_memory`, `automation`, `cron`,
  `personas`, `modes`) emit inventory rows but no automatic
  migration.

## Next milestone

Captured here so they are visible without being mistaken for
Production. Each item lists the test or evidence required to promote
itself.

- Vendor `cryptography` (or `nacl`) and replace HMAC-SHA256 with
  Ed25519. Acceptance: `sign_bundle` produces a SSH-format signature;
  `verify_bundle_signature` accepts a `--trusted-key <id_ed25519.pub>`
  flag and a third-party bundle can be verified end-to-end.
- Implementation tests for `wsl`, `remote-ssh`, `dev-container`,
  `codespaces`, `vscode-profile`, `extension-host`. Acceptance: every
  profile harness has at least three fixture paths each.
- A `--prune-stale` apply flag that reconciles `verify.json`
  drift against the live registry. Acceptance: `apply --prune-stale`
  is a non-destructive dry-run by default; `--yes` confirms.
- Real `doctor` install planner. Acceptance: doctor proposes a
  per-platform install command list derived from each product's
  declared installer, not just a guessed package name.
- A true `compatibility.json` matrix. Acceptance: each entry has
  `source_profile`, `target_profile`, `evidence`, and `verified_at`.

## Rejected / out of scope

- Sniffing the host registry at startup to discover installed
  products. The audit explicitly forbids this — it both leaks
  information and produces false positives.
- Bundles that mutate OpenClaw config, tools, models, cron,
  heartbeat, or approval. Clover is a read-only control plane
  (consent fail-closed).
- Auto-grant of `operator.write` or tool-event observation scope
  without explicit user opt-in.
- Saving or transmitting test private keys. CI and dev run on
  per-commit ephemeral keys; no key is ever embedded in the repo
  or in a fixture bundle.
- Modify the OpenClaw `dist/` tree to accept additional client
  identities. The audit verdict is that this is an upstream
  responsibility; downstream forks must not patch installed code.
