# PR1：Runtime Foundation for One-Sentence Migration

- **Date:** 2026-08-15
- **Baseline:** `27f52ae21baaf803e6b595dba5532b653fc840da` (skill 0.8.2)
- **Audit references:**
  - `docs/agent-skills-setup/roadmap.md`
  - Audit report and implementation backlog (kept outside the repository
    under `~/Documents/skills-repo-0.8.2-*.md`; referenced by name only
    here so the spec carries no private path).

## 1. Motivation and audit findings

Audit confirms 0.8.2 is a sound transaction core but cannot yet honor a
"one-sentence" user request. Four P0 gaps block that goal:

1. `Registry.profile()` does not follow `alias_of`; natural-language selectors
   like "vscode" never resolve to `copilot/vscode`.
2. Any single `status != ready` item causes `apply` to reject the entire plan,
   even when unrelated items are safe.
3. No high-level `migrate` command: users must hand-compose `plan` / `apply` /
   `verify`, contradicting the natural-language UX.
4. Directory-style instructions emit `migrated-N.md` placeholders that lose
   source identity and break repeat-run stability.

PR1 fixes only these four. PR2 (ACB), PR3 (detection), PR4–PR5 (profiles),
PR6 (IR), and PR7 (freshness) are out of scope here and follow after PR1
lands.

## 2. Goals

| ID | Goal | Acceptance signal |
| --- | --- | --- |
| G1 | Alias selectors resolve transitively with cycle detection | `vscode == copilot/vscode`, with `requested` + `resolved` + `chain` preserved |
| G2 | Apply can consume safe subset while keeping non-ready items out of writes | Skills land, Hooks drafts disabled, OAuth MCP only in manifest |
| G3 | Single `migrate` command orchestrates detect→inventory→plan→apply→verify | One CLI invocation; no manual plan/apply glue |
| G4 | Object IDs are stable across re-runs; basenames preserved | `object_id = sha256(product+profile+scope+canonical_relative_path)[:16]` |

## 3. Non-goals (YAGNI)

- ACB bundle schema, snapshot, restore, doctor (PR2).
- New detection probes or platform/path resolver (PR3).
- New product profiles; profile content is unchanged (PR4–PR5).
- New IR types beyond instructions/mcp/skills (PR6).
- Freshness automation or stale demotion (PR7).
- Relaxing existing source/target digest, Git HEAD lock, or backup invariants.
- Introducing network access, OAuth re-auth automation, or auto-approval
  inheritance. All existing redaction invariants remain in force.

## 4. Architecture overview

```
skill entry (SKILL.md "one-sentence" path)
        │
        ▼
┌────────────────────────────┐
│ smart-ide-migration.sh     │  ← new top-level "migrate" subcommand
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ alias_resolver.py          │  ← recursive resolve + cycle guard
│ (Registry.profile → resolve│
│  then load)                │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ migration_core.py          │  ← partial safe apply (8 statuses)
│ - planner                  │  ← stable object_id
│ - apply_ready              │
│ - apply_ready_lossy        │
│ - apply_draft_disabled     │
│ - manifest_writer          │
└────────────────────────────┘
```

The four pieces above are additive. Existing `inventory`, `plan`, `apply`,
`verify`, `rollback`, `legacy` entry points remain available; new behavior is
gated by explicit CLI flags or by the new `migrate` subcommand.

## 5. Component design

### 5.1 Alias resolver (`A1`)

- New module: `skills/agent-skills-setup/scripts/registry/alias_resolver.py`.
- Public surface:

  ```python
  @dataclass(frozen=True)
  class ResolvedSelector:
      requested: str          # user input, e.g. "vscode"
      resolved_product: str
      resolved_profile: str
      chain: tuple[str, ...]  # ["vscode", "copilot/vscode"]
      deprecated: bool
      cycles: tuple[str, ...] # populated only on AliasCycleError

  def resolve(selector: str, registry: Registry) -> ResolvedSelector: ...
  def resolve_profile(product: str, profile: str, registry: Registry) -> ResolvedSelector: ...
  ```

- Recursion bound: 16 hops. Each hop checks `visited`; on revisit, raise
  `AliasCycleError(cycles=tuple(visited))`.
- Resolution failure modes (each raises a typed exception):
  - `UnknownSelectorError` — product or profile not in registry.
  - `AliasCycleError` — recursive alias returns to a visited node.
  - `AliasDepthExceededError` — chain length > 16.
- `Registry.profile(requested_product, requested_profile)` is updated to call
  `resolve(...)` first, then `Registry._load_profile(resolved)` internally.
- Old behavior preserved by `Registry.profile_raw()` for tests and legacy
  callers (deprecated, not removed).
- Logs (stderr) include `requested → resolved`, and a deprecation notice when
  the chain contains any `deprecated: true` entry.

#### Tests

`tests/test-alias-resolution.sh` covers:

| Selector | Resolved | Chain length | Notes |
| --- | --- | --- | --- |
| `vscode` | `copilot/vscode` | 1 | basic |
| `visual-studio` | `copilot/visual-studio` | 1 | basic |
| `claude-desktop` | `claude/desktop-chat` | 1 | basic |
| `trae-cn` | `trae/cn-ide` | 1 | basic |
| `jetbrains-ai` | `jetbrains/ai-assistant` | 1 | basic |
| `codeium` | `windsurf/ide` | 1 | basic |

Additional fixtures: chained alias `a → b → copilot/vscode` (chain length 2),
cycle fixture `c1 → c2 → c1` (must raise `AliasCycleError`), unknown selector
(must raise `UnknownSelectorError`), deprecated alias (must surface warning).

### 5.2 Partial safe apply (`A2`)

- Replace the single "ready" status with an explicit `ItemStatus` enum:

  ```python
  class ItemStatus(str, Enum):
      READY = "ready"
      READY_LOSSY = "ready-lossy"
      DRAFT_DISABLED = "draft-disabled"
      MANUAL_REBUILD = "manual-rebuild"
      FORBIDDEN = "forbidden"
      CONFLICT = "conflict"
      INVALID = "invalid"
  ```

- `apply_plan` is restructured into four cooperating flows driven by status:

  | Status | Apply path | Manifest entry | Atomic? |
  | --- | --- | --- | --- |
  | `ready` | `apply_ready` (existing staged write) | `applied`, with checksums | yes |
  | `ready-lossy` | gated by `--accept-loss`; else skip | `lossy-skipped` or `applied-lossy` with loss_report | yes |
  | `draft-disabled` | write file/entry with `enabled=false` | `draft-written` | yes |
  | `manual-rebuild` | none | `manual-rebuild` | n/a |
  | `forbidden` | none | `forbidden`, with `reason` | n/a |
  | `conflict` | none; **only the conflicting target group is blocked** | `conflict` | n/a |
  | `invalid` | none | `invalid`, with `reason` | n/a |

- Conflict semantics: the planner tags each item with a `target_group`
  derived from its resolved target path. A `conflict`/`invalid` status blocks
  only its own `target_group`; other groups proceed if their own items are
  eligible.
- New CLI flags on `apply`:

  | Flag | Effect |
  | --- | --- |
  | `--apply-safe` (default true) | Apply `ready` + `draft-disabled`; manifest the rest |
  | `--include lossy` | Also apply `ready-lossy` items |
  | `--accept-loss <id>[,<id>...]` | Apply only named lossy items |
  | `--strict` | Reject if any item is non-`ready` (preserves old behavior) |

- Apply manifest schema (additive, fields optional for backward compat):

  ```json
  {
    "items": [
      {"object_id": "...", "status": "applied", "target_path": "...", "sha256": "..."},
      {"object_id": "...", "status": "draft-written", "target_path": "...", "enabled": false},
      {"object_id": "...", "status": "manual-rebuild", "reason": "OAuth re-auth required"},
      {"object_id": "...", "status": "forbidden", "reason": "generated memory"},
      {"object_id": "...", "status": "lossy-skipped", "loss_report": [...]}
    ],
    "blockers": [
      {"target_group": "...", "status": "conflict", "object_ids": [...]}
    ]
  }
  ```

- All existing safety invariants (source digest lock, Registry digest lock,
  Git HEAD lock, atomic staging, full rollback, secret redaction) remain
  enforced for `ready` and `ready-lossy` flows.

#### Tests

`tests/test-partial-safe-apply.sh` covers a fixture plan with:

- Skills (ready, skills/agent-skills-setup fixture).
- Hooks (draft-disabled).
- OAuth MCP (manual-rebuild).
- Instructions (ready-lossy).
- One `conflict` between Skills names.
- One `forbidden` (generated memory).

Assertions:

1. Skills land with checksum; source digest unchanged.
2. Hooks files exist on disk with `enabled=false` and are NOT auto-enabled.
3. OAuth MCP absent from target; rebuild.json contains the item with reason.
4. Instructions write runs only when `--include lossy` is set; otherwise
   manifest reports `lossy-skipped` with loss_report.
5. Conflict blocks its own target_group; other ready groups still apply.
6. Forbidden items never appear in target tree.

### 5.3 High-level `migrate` command (`A3`)

- New top-level subcommand in `smart-ide-migration.sh` (the existing wrapper;
  wrapper rename is out of scope for PR1):

  ```text
  bash scripts/smart-ide-migration.sh migrate
      --source <product>/<profile>
      --target <product>/<profile>
      --workspace <path>
      --objects <list|all-portable|all-inventory>
      [--scope user,project]
      [--plan-only]
      [--apply-safe]            # default true
      [--include lossy]
      [--accept-loss <ids>]
      [--plan-out <path>]       # default: <workspace>/.migration/migrate-plan.json
      [--manifest-out <path>]   # default: <workspace>/.migration/migrate-manifest.json
      [--verify-out <path>]
      [--yes]
  ```

- Internal pipeline, executed in one process invocation:

  1. `detect --json --installed` (PR1 uses existing path-based detection;
     platform probes arrive in PR3).
  2. `inventory --json --installed --scope user,project --workspace`.
  3. `plan --json` reusing the existing planner with `ItemStatus` upgrades.
  4. `apply <plan> --apply-safe [--include lossy] --yes`.
  5. `verify --manifest <manifest>`.

- Default behavior: the natural-language phrase "迁移到 X" triggers
  `bash scripts/smart-ide-migration.sh migrate` with `--apply-safe` and the
  default scope `user,project`. The Skill MUST still individually confirm
  any action in the danger list:

  - enabling or executing Hooks;
  - writing literal secrets / OAuth state / trust grants;
  - cross-workspace destructive overwrite with unresolved conflicts;
  - enterprise policy / cloud sync changes.

- Each `--objects` value:
  - `<list>` — comma-separated subset of `skills,instructions,mcp` plus the
    enumerated `prompts,commands,workflows,agents,hooks,cron,automation,
    user_memory,generated_memory,cloud_knowledge,config,policy,trust`
    inventory-only surfaces, which appear in `inventory.json` and in manifest
    as `manual-rebuild` or `forbidden` entries but never as writes.
  - `all-portable` — `ready` + `ready-lossy` + `draft-disabled` +
    `manual-rebuild` items (default).
  - `all-inventory` — `all-portable` plus `forbidden` / generated memory /
    cloud state metadata, recorded but never copied.

- Default scope: `user,project`. The CLI accepts `--scope user,project`,
  `--scope project`, or `--scope user`; full-disk scans require an explicit
  `--roots <path>[,<path>...]` and remain out of scope for the default
  `migrate` invocation.

#### Tests

`tests/test-migrate-command.sh`:

- Fixture: Cline → Cursor (Skills + Instructions + stdio MCP).
- Assertion: a single `bash smart-ide-migration.sh migrate …` invocation
  produces plan.json + manifest.json + verify.json; Skills and Instructions
  land; MCP entries appear in manifest as `applied` or `manual-rebuild` as
  appropriate.
- Negative: with `--plan-only`, no target files are written.
- Negative: a danger item (e.g. Hooks) appears as `draft-disabled`, never
  enabled.

### 5.4 Stable object IDs (`A4`)

- Object identity:

  ```text
  object_id = sha256(
      f"{product}|{profile}|{scope}|{canonical_relative_path}"
  )[:16]      # lowercase hex
  ```

  - `canonical_relative_path` is normalized: forward slashes, no leading `/`,
    trailing slash stripped.
  - `scope` ∈ {`user`, `project`, `repo`, `host`}.
  - `product` / `profile` are **resolved** (post-alias), not raw user input.
  - Two object descriptions that differ only in alias produce the same
    `object_id`.

- Naming for directory-style instructions:

  1. Default: preserve source basename, append `.md` (or target extension).
  2. On basename collision, append `-<object_id[:6]>` before extension.
  3. Last-resort `migrated-N.md` names remain a fallback only; the
     `source_object_id → target_path` mapping is recorded in the manifest.

- Manifests and plans reference objects by `object_id`; `target_path` is
  derived at apply time and may change on collision.

- Stale-target policy: targets that no longer correspond to any source object
  are reported in `verify.json` as `stale-target` with their previous
  `object_id`. Default behavior is to leave stale files in place; removal
  requires an explicit `--prune-stale` flag (not introduced in PR1; tracked
  for a later PR).

#### Tests

`tests/test-stable-object-ids.sh`:

- Repeat-run idempotency: two runs of the same plan produce identical
  `object_id`s and identical target paths.
- Same-name collision fixture: two different instructions with the same
  basename resolve to distinct `object_id`s and distinct target paths (using
  short hash suffix).
- Alias equivalence: `vscode/instructions/foo.md` and
  `copilot/vscode/instructions/foo.md` produce the same `object_id`.
- Cross-scope separation: `user` vs `project` scopes do not collide.

## 6. Skill frontmatter and authorization update

`skills/agent-skills-setup/SKILL.md` updates:

- "Use only when a user names two supported IDEs or agent products, identifies
  specific skills, instructions, prompts, commands, or MCP objects, and asks
  to plan or perform a migration" — broaden the trigger to also match
  one-sentence migration intents that name only a source and target.
- Add a new authorization clause:

  > A natural-language phrase that explicitly contains an action verb such as
  > "apply", "restore", or "直接应用" is treated as combined authorization
  > for `ready` and `draft-disabled` items under `--apply-safe`. The Skill
  > still requires explicit per-item confirmation for: enabling or executing
  > Hooks; writing literal secrets, OAuth state, or trust/approval grants;
  > unresolved destructive overwrites; and enterprise or cloud policy
  > changes.

- Update the "Commands" section to mention the new `migrate` subcommand and
  keep `plan` / `apply` / `verify` / `rollback` / `legacy` listed.

## 7. Test plan

| Script | Scope | Acceptance |
| --- | --- | --- |
| `test-alias-resolution.sh` | A1 | All alias fixtures resolve; cycles/depth/unknown raise typed errors |
| `test-partial-safe-apply.sh` | A2 | Mixed-status plan applies safe subset, manifest records the rest |
| `test-migrate-command.sh` | A3 | Single CLI invocation produces plan + manifest + verify |
| `test-stable-object-ids.sh` | A4 | Object IDs stable across runs; alias-equivalent paths collide correctly |

Existing scripts remain required to pass:

- `test-mcp-secret-redaction.sh`
- `test-skill-secret-preflight.sh`
- `test-migration-default-scope.sh`
- `test-profile-contracts.sh`
- `test-registry-v2.sh`
- `validate-all.sh`

## 8. Validation gates

Before any PR1 change is proposed for merge:

1. `bash validate-all.sh` exits 0.
2. All new test scripts above pass.
3. New `migrate` flow is exercised end-to-end against at least one
   fixture pair (Cline → Cursor) with `--apply-safe --yes`.
4. Manifest example from §5.2 round-trips through `verify`.
5. Re-running `migrate` on the same source/target is idempotent at the
   target-tree level (object_id stability).
6. SKILL.md safety rules remain stricter than the audit baseline (no
   literal-secret writes, no OAuth re-auth without per-item approval, no
   hook enablement).

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Alias resolution regresses old behavior (users relied on the raw alias id) | Preserve `Registry.profile_raw()`; emit `requested → resolved` in logs and in plan metadata |
| Partial apply silently bypasses required safety checks | Keep `--strict` mode; manifest records every non-ready item with reason; existing source-digest / Git HEAD / backup invariants unchanged |
| `migrate` becomes a backdoor for destructive actions | Danger list still requires explicit per-item confirmation; default is `--apply-safe` without hooks; hooks always emitted as `draft-disabled` |
| Stable IDs cause collisions for legitimate duplicates | 16-hex (64 bits) collision probability is negligible; short-hash suffixing handles basenames; collision test in fixture |
| Forward compat with PR2 (ACB) | Object IDs and ItemStatus enum are designed to be reused by ACB manifest; no PR2 work is started in PR1 |

## 10. Out of scope, deferred to later PRs

- ACB bundle schema, snapshot, restore, doctor (PR2).
- Platform-aware detection probes and OS/path resolver (PR3).
- Filling empty profiles (Cursor, Claude Code, Copilot/VS Code, etc.) (PR4).
- New product profiles (Rovo Dev, IBM Bob, Hermes, GitLab Duo, Jules,
  Letta, Zencoder, Gemini Code Assist) (PR5).
- PromptIR / CommandIR / WorkflowIR / AgentIR / HookIR / richer MCP IR (PR6).
- Full freshness automation and stale demotion (PR7).

## 11. Open questions for owner review

1. Confirm alias depth limit of 16 is sufficient (current real chains ≤ 2).
2. Confirm `--strict` should remain available for callers who want the old
   all-or-nothing semantics.
3. Confirm `migrated-N.md` fallback remains acceptable as a last resort; if
   not, every collision must use `<basename>-<short>.md` instead.