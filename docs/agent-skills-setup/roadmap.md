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
- Bundles are signed with **Ed25519** over `checksums.json` (P1-5, 0.8.27).
  `sign_bundle` / `verify_bundle_signature` accept `--trusted-key <id_ed25519.pub>`.
  HMAC-SHA256 is retained for backward compatibility.
- `--all-installed` snapshot and restore use real detection results as
  the only source of truth (no `inventory.exists` fallback) and
  iterate plan items, not inventory rows (P0-3, 0.8.27).
- MCP / Instructions / Skills use explicit adapter registries. JSONC
  uses a reviewed parser; JSON5 / TOML / YAML / XML / Lua / ambiguous
  UUID+JSON fail to a dedicated manual adapter.
- Apply uses a seven-status partial safe flow (`ready`, `ready-lossy`,
  `draft-disabled`, `manual-rebuild`, `forbidden`, `conflict`,
  `invalid`).
- Apply stages `skills` / `instructions` / `mcp` plus opaque plugin
  package copies; session `handoff` transfer exists behind the explicit
  `--include-session` opt-in with a field whitelist. Executable
  surfaces (hooks, agents) have no staging writer — a replayed plan
  marking them eligible fails closed, and the legacy wrapper admits
  only read-only `--print-path` / `--dry-run` invocations (0.8.33).
- Alias resolver follows `alias_of` chains iteratively with cycle,
  depth, and unknown-selector guards.
- macOS path expansion and `~` resolution are deterministic.
- `secrets.required.json`, `reauth.json`, `rebuild.json`, and
  `collection_summary` are non-secret metadata only.
- Parse failures are surfaced explicitly in `requirements.json` and
  `collection_summary` (P1-2, 0.8.27); no silent exception swallowing.
- Manifest objects carry rich metadata: `object_path`, `files[]` with
  SHA256/size, `adapter_version`, `source_format_version`,
  `portability_mode`, `content_hash`.

## Experimental

These work in restricted environments but are not yet ready for
production-grade cross-platform guarantees.

- WSL / Remote-SSH / Dev-Container / Codespaces host classes. The
  `windows-latest` matrix job now runs the full suite (ACB E2E, plan /
  apply / verify, detection, mapping assertions) with MSYS-aware test
  harnesses; the remaining host classes have no CI coverage yet.
- ACB signed bundle cross-device handoff. Ed25519 is asymmetric, so
  the security boundary is now "self-generated + trusted-key verified".
  Third-party ACBs can be verified with `--trusted-key`.
- Maintainer-side documentation freshness via online checks (monthly
  `maintainer-online-checks.yml`). The 365-day window in
  `doc-freshness-checks.json` applies only to the offline runtime
  check; maintainer online checks use a 30-day window.

## Known limitations

- `cryptography` is required at runtime for `sign_bundle` /
  `verify_bundle_signature`. It is not committed to the repo and the
  bundle path does not require it at snapshot time unless `--sign` is
  requested.
- `doctor` surfaces requirements as a list of `executables` and
  `packages` parsed from MCP server configs. It does not run an
  install planner; it does not validate that the listed package
  actually exists on the target platform.
- The OS / profile locations wiring covers `darwin`, `linux`, and
  `windows` deeply. `wsl`, `remote-ssh`, `dev-container`,
  `codespaces`, `vscode-profile`, and `extension-host` are stored on
  profiles but not yet lazy-evaluated at apply time.
- `Inventory_only` object types (`workflows`, `plugins`, `handoff`,
  `config`, `policy`, `trust`, `user_memory`, `automation`, `cron`,
  `personas`, `modes`) emit inventory rows but no automatic
  migration.
- ACB verify re-scans object bytes with the strict secret/binary
  scanner, but third-party bundles without a trusted Ed25519 public
  key cannot be verified.

## Next milestone

Captured here so they are visible without being mistaken for
Production. Each item lists the test or evidence required to promote
itself.

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
- WSL / Remote-SSH / Dev-Container / Codespaces E2E tests covering
  host/guest `HOME` interaction, actual file apply/rollback, and
  cross-OS ACB handoff (Windows↔macOS).

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