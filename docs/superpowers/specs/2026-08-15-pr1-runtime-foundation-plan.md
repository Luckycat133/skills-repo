# PR1：Runtime Foundation Implementation Plan

- **Date:** 2026-08-15
- **Spec:** `docs/superpowers/specs/2026-08-15-pr1-runtime-foundation-design.md`
  (commit `e67c8d8`)
- **Baseline:** `27f52ae21baaf803e6b595dba5532b653fc840da` (skill 0.8.2)

This plan is the executable decomposition of the PR1 spec. Each phase ends
with green tests and `bash validate-all.sh` exiting 0 before the next phase
starts. No phase may relax the existing source digest, Registry digest,
Git HEAD lock, atomic staging, full-rollback, or secret redaction
invariants.

## Phase 0 — Pre-flight reconnaissance (no code change)

Goal: confirm the runtime entry points, Registry class shape, and existing
planner status semantics before editing.

- Read `skills/agent-skills-setup/scripts/migration_core.py` end-to-end and
  identify:
  - the `Registry.profile()` method;
  - the existing status / item-state field used by the planner;
  - the existing `apply_plan` / staged-write / backup / rollback functions;
  - the existing instruction file naming function for directory outputs.
- Read `skills/agent-skills-setup/scripts/smart-ide-migration.sh` and map:
  - current subcommands and their flag parsers;
  - where to plug in a new `migrate` subcommand;
  - where to add `--apply-safe`, `--include lossy`, `--accept-loss`,
    `--strict` flags to `apply`.
- Read at least one existing test script
  (`scripts/test-registry-v2.sh`, `scripts/test-partial-safe-apply.sh` if
  it exists, or a peer) to mirror its setup, fixture, and assertion style.
- Read `scripts/scan-skill-secrets.py` to confirm redaction helper APIs.
- Capture findings inline in the PR description; do not commit a doc.

Exit criteria: confirmed understanding of every existing function that
PR1 must extend.

## Phase 1 — `A1` Alias resolver

Goal: alias selectors resolve transitively with cycle guard; existing
behavior preserved via `Registry.profile_raw()`.

### Files

- New: `skills/agent-skills-setup/scripts/registry/__init__.py`
- New: `skills/agent-skills-setup/scripts/registry/alias_resolver.py`
- New: `skills/agent-skills-setup/scripts/registry/exceptions.py`
- Modify: `skills/agent-skills-setup/scripts/migration_core.py`
  - `Registry.profile()` calls `alias_resolver.resolve(...)` first.
  - Add `Registry.profile_raw()` (current behavior) marked deprecated.
  - Log `requested → resolved` to stderr.
- New: `skills/agent-skills-setup/scripts/test-alias-resolution.sh`

### Implementation order

1. Define exceptions in `exceptions.py`:
   `UnknownSelectorError`, `AliasCycleError`, `AliasDepthExceededError`.
2. Implement `ResolvedSelector` dataclass and `resolve(selector, registry)`
   with iterative (stack-based) traversal, visited set, depth limit 16,
   and the three typed exceptions.
3. Implement `resolve_profile(product, profile, registry)` for explicit
   `product/profile` pairs.
4. Wire `Registry.profile()` to call `resolve_profile(...)`.
5. Keep `Registry.profile_raw()` returning the legacy result.
6. Add stderr log on every successful resolution:
   `alias: <requested> → <resolved_product>/<resolved_profile>`
   and a `WARN alias: <x> is deprecated` line when chain has
   `deprecated: true`.
7. Verify the alias entries in `references/registry-v2.json` already cover
   all spec test fixtures (`vscode`, `visual-studio`, `claude-desktop`,
   `trae-cn`, `jetbrains-ai`, `codeium`). Add fixtures to a local
   registry test fixture if any alias is missing.

### Tests (`test-alias-resolution.sh`)

- Six positive cases from spec §5.1 table.
- Chained alias (chain length 2) resolves and preserves chain.
- Cycle fixture raises `AliasCycleError` with cycle trace.
- Unknown selector raises `UnknownSelectorError`.
- Depth > 16 raises `AliasDepthExceededError`.
- Deprecated alias surfaces a stderr warning and `deprecated: true`.
- `Registry.profile_raw()` still returns legacy alias id unchanged.

Exit criteria: all cases pass; `bash scripts/test-alias-resolution.sh`
exits 0; existing `scripts/test-registry-v2.sh` still passes
(`Registry.profile_raw()` compatibility).

## Phase 2 — `A2` Partial safe apply with `ItemStatus` enum

Goal: 8 status states drive four apply paths; conflict/invalid block only
their target group; manifest records every non-applied item with reason.

### Files

- Modify: `skills/agent-skills-setup/scripts/migration_core.py`
  - Add `ItemStatus` enum (8 values).
  - Refactor `apply_plan` into:
    `apply_ready`, `apply_ready_lossy`, `apply_draft_disabled`,
    `manifest_non_writes`.
  - Add `target_group` derivation for each planner output.
  - New per-item `conflict`/`invalid` → only block their target group.
- Modify: `skills/agent-skills-setup/scripts/smart-ide-migration.sh`
  - Add flags to `apply`:
    `--apply-safe` (default true),
    `--include lossy`,
    `--accept-loss <id>[,<id>...]`,
    `--strict`.
- Modify: manifest writer to emit items in the spec §5.2 schema
  (additive fields; existing fields preserved).
- New: `skills/agent-skills-setup/scripts/test-partial-safe-apply.sh`

### Implementation order

1. Introduce `ItemStatus` enum without changing existing string values
   where they already appear (use `str` mixin for backward compat).
2. Refactor planner to assign one of the 8 statuses plus `target_group`
   on each item; keep existing status strings mapped to the new enum.
3. Implement per-status handlers:
   - `ready` → existing staged write path.
   - `ready-lossy` → new path gated by `--accept-loss` / `--include lossy`.
   - `draft-disabled` → write with `enabled=false`, never activate.
   - `manual-rebuild` / `forbidden` / `conflict` / `invalid` →
     manifest only.
4. Conflict/invalid isolation:
   - `target_group` derived from the resolved target path prefix.
   - If any item in a `target_group` has status `conflict` or `invalid`,
     the entire group is skipped; other groups proceed.
6. Manifest writer: add `items[].status`, `items[].reason`,
   `items[].loss_report`, `blockers[]` (additive, not destructive).
7. `--strict` flag restores old "any non-ready → reject" semantics for
   callers that want it.
8. Preserve existing atomic-staging, full-rollback, source-digest,
   Registry-digest, Git HEAD, and backup invariants for all write paths.

### Tests (`test-partial-safe-apply.sh`)

Fixture plan containing:
- Skills (`ready`).
- Hooks (`draft-disabled`).
- OAuth MCP (`manual-rebuild`).
- Instructions (`ready-lossy`).
- One Skills name conflict (`conflict`).
- One generated-memory entry (`forbidden`).

Assertions (per spec §5.2):
1. Skills land with checksum; source digest unchanged.
2. Hooks files exist with `enabled=false`; never auto-enabled.
3. OAuth MCP absent from target; rebuild manifest entry present.
4. `--apply-safe` (default) skips lossy instructions and records
   `lossy-skipped` with loss_report.
5. `--include lossy` then runs the lossy instructions.
6. Conflict blocks its target group; unrelated ready groups still apply.
7. Forbidden entries never appear in target tree.
8. `--strict` rejects the fixture plan (existing semantics preserved).
9. `bash scripts/test-mcp-secret-redaction.sh` and
   `bash scripts/test-migration-default-scope.sh` still pass.

Exit criteria: all assertions pass; existing apply tests still pass;
manifest schema validates round-trip.

## Phase 3 — `A3` High-level `migrate` command

Goal: single `bash smart-ide-migration.sh migrate …` invocation chains
`detect → inventory → plan → apply → verify` and emits plan, manifest,
verify artifacts.

### Files

- Modify: `skills/agent-skills-setup/scripts/smart-ide-migration.sh`
  - Add `migrate` subcommand with all spec §5.3 flags.
  - Internal sequencing reuses existing subcommand functions; no
    behavior change in `detect`, `inventory`, `plan`, `apply`, `verify`.
- Modify: `skills/agent-skills-setup/SKILL.md` (Phase 5 covers this in
  full; here only update the `Commands` section to mention `migrate`).
- New: `skills/agent-skills-setup/scripts/test-migrate-command.sh`

### Implementation order

1. Parse new flags `--source`, `--target`, `--workspace`, `--objects`,
   `--scope`, `--plan-only`, `--apply-safe`, `--include lossy`,
   `--accept-loss`, `--plan-out`, `--manifest-out`, `--verify-out`,
   `--yes`.
2. Validate `--source` and `--target` are `<product>/<profile>` form;
   resolve aliases (Phase 1 module) before persisting them to the plan.
3. Default `--scope` to `user,project`; reject full-disk scans in the
   default path (require `--roots` for that).
4. Execute internal pipeline by calling the existing subcommand
   functions in-process or shelling out per the wrapper's existing
   pattern (mirror how `apply` already invokes `plan`).
5. `--plan-only` short-circuits before any apply step.
6. `--yes` only bypasses interactive prompts; it does not bypass the
   danger list (see Phase 5).
7. Write plan/manifest/verify to `--plan-out`, `--manifest-out`,
   `--verify-out` (defaults: `<workspace>/.migration/*.json`).

### Tests (`test-migrate-command.sh`)

- Fixture: Cline → Cursor (Skills + Instructions + stdio MCP).
- Positive: one CLI invocation produces plan.json + manifest.json +
  verify.json; Skills and Instructions land on disk.
- Negative: `--plan-only` writes plan.json but no target files.
- Negative: a Hooks entry appears as `draft-disabled`, never enabled.
- Negative: omitting `--yes` triggers interactive prompt (mocked).
- Regression: existing `test-migration-core.sh` and
  `test-migration-evidence.sh` still pass.

Exit criteria: end-to-end run against the fixture pair passes;
manifest matches spec §5.2 schema; verify round-trips.

## Phase 4 — `A4` Stable object IDs

Goal: object_id stable across re-runs; basenames preserved; alias-
equivalent inputs collide on the same id.

### Files

- Modify: `skills/agent-skills-setup/scripts/migration_core.py`
  - Add `compute_object_id(product, profile, scope, canonical_path)`
    helper using `hashlib.sha256(...).hexdigest()[:16]`.
  - Replace `migrated-N.md` directory instruction naming with the
    spec §5.4 policy: basename-first, hash-suffix on collision,
    `migrated-N.md` only as last resort.
  - Add `source_object_id → target_path` mapping to manifest.
- Modify: planner output to include `object_id` on every item.
- Modify: verify to report `stale-target` entries using stored
  `object_id`.
- New: `skills/agent-skills-setup/scripts/test-stable-object-ids.sh`

### Implementation order

1. Implement `compute_object_id(...)` and unit-test the helper.
2. Add `canonical_relative_path` normalization (forward slashes,
   no leading `/`, no trailing `/`).
3. Thread `object_id` through planner output.
4. Update directory-style instruction writer:
   - default `basename + target_ext`;
   - on collision, `<basename>-<object_id[:6]><ext>`;
   - on second collision, fall back to `migrated-N.md` with a
     comment in the manifest.
5. Update manifest writer to record the `source_object_id → target_path`
   map.
6. Verify path: compare current target tree against the map and emit
   `stale-target` entries in verify.json.
7. Stale-target files are left in place by default; no `--prune-stale`
   flag yet.

### Tests (`test-stable-object-ids.sh`)

- Repeat-run idempotency on the same fixture pair.
- Same-basename collision across distinct source files produces
  distinct object_ids and distinct target paths.
- Alias equivalence: `vscode/...` and `copilot/vscode/...` collide on
  the same object_id (post-Phase-1 alias resolution).
- Cross-scope separation: `user` vs `project` produce different ids.
- After source deletion, verify reports `stale-target` but does not
  delete.

Exit criteria: all assertions pass; existing
`test-migration-default-scope.sh` still passes.

## Phase 5 — SKILL.md authorization update

Goal: SKILL.md reflects the new one-sentence trigger and the explicit
danger list; the canonical Skill is updated first, root pointer
regenerated second.

### Files

- Modify: `skills/agent-skills-setup/SKILL.md`:
  - broaden trigger description (spec §6 paragraph 1);
  - add the new authorization clause (spec §6 paragraph 2);
  - update Commands section to mention `migrate` alongside
    `plan`, `apply`, `verify`, `rollback`, `legacy`.
- After SKILL.md is updated, run:
  `bash scripts/sync-root-mirror.sh`
  to regenerate the root `SKILL.md` mirror.

### Implementation order

1. Edit `skills/agent-skills-setup/SKILL.md` per spec §6.
2. Run `bash scripts/sync-root-mirror.sh --check` and confirm green;
   then `bash scripts/sync-root-mirror.sh` to write.
3. Verify the root `SKILL.md` is regenerated and contains the new
   clauses.

Exit criteria: `bash scripts/sync-root-mirror.sh --check` exits 0;
root SKILL.md diff contains only the expected changes.

## Phase 6 — End-to-end validation and release gate

Goal: every PR1 gate from spec §8 is green.

### Steps

1. `bash validate-all.sh` exits 0.
2. Run the four new test scripts and confirm exit 0:
   - `test-alias-resolution.sh`
   - `test-partial-safe-apply.sh`
   - `test-migrate-command.sh`
   - `test-stable-object-ids.sh`
3. Run the regression set:
   - `test-mcp-secret-redaction.sh`
   - `test-skill-secret-preflight.sh`
   - `test-migration-default-scope.sh`
   - `test-profile-contracts.sh`
   - `test-registry-v2.sh`
4. Manual end-to-end: Cline → Cursor fixture with
   `bash scripts/smart-ide-migration.sh migrate … --apply-safe --yes`.
5. Confirm manifest schema round-trips: every item has a status from
   the 8-value enum; verify reports match manifest.
6. Re-run the same `migrate` invocation; confirm target tree is
   byte-identical (object_id stability).
7. Confirm no literal secret in any artifact via
   `test-mcp-secret-redaction.sh` and a manual grep on bundle outputs.
8. Confirm SKILL.md danger list is unchanged for hook enablement,
   literal secret writes, OAuth re-auth, and cross-workspace
   destructive overwrites.
9. Run `bash scripts/test-doc-freshness.sh` to confirm no freshness
   regression in the doc layer.

Exit criteria: all gates green; commit and open PR.

## Out of scope (deferred)

The following are explicitly deferred per spec §10 and PR1 non-goals:

- ACB bundle schema, snapshot, restore, doctor (PR2).
- Platform-aware detection probes (PR3).
- Filling empty profiles (PR4).
- New product profiles (PR5).
- PromptIR / CommandIR / WorkflowIR / AgentIR / HookIR / richer MCP IR
  (PR6).
- Full freshness automation and stale demotion (PR7).
- Wrapper rename from `smart-ide-migration.sh` to `agent-context`.

## Risks tracked from spec §9

- Alias resolution regression → `Registry.profile_raw()` retained; logs
  surface every resolution.
- Partial apply bypassing safety checks → `--strict` mode retained;
  manifest records every non-ready item.
- `migrate` becoming a backdoor → danger list still requires explicit
  per-item confirmation.
- Stable ID collisions → 64-bit prefix + short-hash suffix + collision
  test in fixture.
- Forward compat with PR2 (ACB) → object IDs and ItemStatus enum are
  designed for reuse.

## Completion checklist

- [ ] Phase 0 reconnaissance complete.
- [ ] Phase 1 alias resolver + tests green.
- [ ] Phase 2 partial safe apply + tests green.
- [ ] Phase 3 migrate command + tests green.
- [ ] Phase 4 stable object IDs + tests green.
- [ ] Phase 5 SKILL.md updated and root mirror regenerated.
- [ ] Phase 6 all validation gates green.
- [ ] PR opened against `main` referencing the spec doc and this plan.