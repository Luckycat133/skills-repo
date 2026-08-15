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
- Alias resolver follows `alias_of` chains iteratively with cycle, depth, and
  unknown-selector guards; `Registry.profile()` resolves `vscode` →
  `copilot/vscode`, `claude-desktop` → `claude/desktop-chat`, etc. at runtime.
- Apply uses a seven-status partial safe flow (`ready`, `ready-lossy`,
  `draft-disabled`, `manual-rebuild`, `forbidden`, `conflict`, `invalid`) so
  OAuth MCP, forbidden memory, and lossy instructions no longer block safe
  Skills in the same plan. Conflict and invalid items block only their own
  target group.
- `PlanItem` carries a stable `object_id` so repeated runs and alias-equivalent
  selectors produce identical identifiers; directory-style instruction targets
  use basename-first naming with a short `object_id` suffix on collision.
- High-level `migrate` subcommand orchestrates `detect → inventory → plan →
  apply → verify`; portable Agent Context Bundle (`.acb`) `snapshot`,
  `bundle-verify`, `restore`, and `doctor` subcommands carry a credential-free
  portable snapshot of installed products and per-object migration metadata.

## Next

- Wire per-product `detection` configs from Registry v2 into
  `detect_profile()` so `detect` and `inventory` return real installation
  states instead of `exists: bool`.
- Persist source bytes into `bundle/objects/` during `snapshot` and replay
  them on the new device during `restore` so ACB truly survives a device
  handoff end-to-end.
- Fill in the remaining empty profiles (Copilot CLI / VS Code / Visual
  Studio, Gemini CLI, Kiro, OpenCode, TRAE, JetBrains, Zed, Continue,
  Amp, OpenHands) and add the remaining PR5 products (Hermes, GitLab Duo,
  Jules, Letta, Zencoder, Gemini Code Assist).

## Engineering backlog

- Promote a manual profile only after official, versioned schema evidence and a
  dedicated adapter/fixture contract exist.
- Retire the internal compatibility engine after downstream legacy callers have
  migrated to saved plans.
- Harden temporary cleanup, copy errors, timestamp collisions, and missing dependencies.
- Extend malformed-input, read-only-target, and non-MCP-object tests.
- Emit adapters for PromptIR / CommandIR / AgentIR / HookIR.
- Wire OS / profile locations (darwin, linux, windows, wsl, remote-ssh,
  dev-container, codespaces, vscode-profile, extension-host) into the
  Registry v2 schema.
- Add stale-target detection in `verify.json` with an explicit
  `--prune-stale` apply flag.
- Add an optional encrypted secret envelope (age recipient) on top of ACB
  with a CI gate that prevents default bundles from carrying it.

Completed path single-sourcing and the compatibility boundary are recorded in
[HI-001](HI-001-ide-paths-single-source.md).
