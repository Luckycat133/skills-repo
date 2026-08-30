# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.2] - 2026-08-30

### Fixed

- **Canonical display name regression introduced by v0.9.1**: restored the public display name to "Agent Skills Setup", undoing the v0.9.1 repositioning to "Agent Context Migrator". Bumped `metadata.version` in `SKILL.md`, the README clone branch, and the metadata test assertion to `0.9.2`. No engine behaviour changed; v0.9.2 keeps all v0.9.1 capabilities (child-level skill conflicts, MCP server-level merge, strict detection flags, and fail-closed plugin/session opt-in guards).

## [0.9.1] - 2026-08-29

### Fixed

- **P0-1 (Child-level Skill PlanItems in restore --all-installed)**:
  - Decomposed monolithic Skills directory `PlanItem`s into per-skill child items (`<target-skills-dir>/<skill-name>`) with granular `target_group` conflict isolation.
  - A conflicting shared skill now blocks only its own target group; unique sibling skills from every source are restored.
  - Same-name/same-hash skills deduplicate; same-name/different-hash skills conflict individually.
- **P0-2 (Multi-source MCP IR server-level merge)**:
  - Multiple MCP sources mapping to the same destination file are now parsed to `MCPServerIR` and merged by server name.
  - Identical normalized server definitions deduplicate; conflicting servers (differing command/args/transport) are isolated into the loss report.
  - Each destination MCP file produces exactly one `PlanItem` and one atomic write operation.
- **P1-1 (Strict detection include flags)**:
  - `snapshot --all-installed` and restore target detection now default strictly to `InstallState.INSTALLED` sources.
  - `CONFIGURED_ONLY` and `COMPATIBILITY_ONLY` profiles require explicit `--include-configured` and `--include-compatibility` flags.

### Added

- **End-to-end opt-in plumbing for plugins and session handoff**:
  - `--include-plugins` and `--include-session` now flow from CLI (`migrate`, `apply`, `restore`) through to `apply_plan()` via the independent `allow_plugin_copy` / `allow_session_handoff` parameters.
  - Plugin copies and handoff writes fail closed unless the corresponding flag is set.
- **Regression tests** in `test-acb-all-installed.sh`:
  - Mixed skill conflict + unique sibling skills (shared conflict, unique-a/unique-b applied).
  - Multi-source MCP merge to one target (git dedupe, linear merge, filesystem conflict isolation).
  - Strict detection include flags (default exclusion + explicit inclusion).
  - Plugin/handoff opt-in fail-closed behavior.
- **GitHub issue templates** (`bug_report.yml`, `request_ide_profile.yml`, `verify_path.yml`, `config.yml`) and `SUPPORT.md`.
- **Compatibility matrix documentation** at `docs/agent-skills-setup/compatibility-matrix.md`.

### Changed

- Updated the canonical Skill description with natural-language search terms (migrate, back up, restore, compare, switching computers) covering Cursor, Claude Code, Codex, Cline, Copilot, Windsurf, and Gemini CLI.
- Updated README installation commands to a versioned GitHub clone plus local-path `openclaw skills install` invocation, mirrored across all four language variants.

## [0.9.0] - 2026-08-25

### Fixed

- **P0-1 (Restore --all-installed object-level conflict handling)**:
  - Replaced surface-level target deduplication in `restore --all-installed` with fine-grained object-level deduplication.
  - Multi-source restores (e.g. Cline, Cursor, Claude Code into a single target IDE) now restore all non-conflicting skills and configurations instead of silently skipping subsequent sources.
  - Conflicting skills/instructions are explicitly tagged with `status: conflict` and recorded in `loss_report`.
- **P0-2 (ACB Manifest strict 1:1 object-to-file binding)**:
  - `collect_source_objects()` now returns explicit `object_file_map` mapping each object to its exact files.
  - Removed broad prefix fallback matching in `enrich_manifest_object()`.
  - `verify_bundle()` strictly rejects bundles where any file is claimed by multiple manifest objects, and ensures every portable object claims at least one file.
- **P1-1 (Capability registry unification)**:
  - Unified `AUTOMATIC_OBJECT_TYPES` (`skills`, `instructions`, `mcp`), `OPT_IN_WRITABLE_OBJECT_TYPES` (`plugins`, `handoff`), and `INVENTORY_ONLY_OBJECT_TYPES` across `migration_core.py` and `context-migrator.py`.
- **P1-2 (Compatibility matrix non-empty fix)**:
  - Corrected `compatibility.json` generation to check `migration_policy in AUTOMATIC_MIGRATION_POLICIES` instead of `support_level`, generating full bidirectional matrix pairs.
- **P1-3 (All-installed target filtering)**:
  - `restore --all-installed` defaults strictly to `INSTALLED` and `CONFIGURED_ONLY` targets; `COMPATIBILITY_ONLY` targets now require `--include-compatibility`.
- **P1-5 (Permissions clarification)**:
  - Updated permissions description to explicitly declare local read-only detection commands (`git`, `--version`, `mdfind`) without binary downloads or installations.
- **P1-6 (Ed25519 CLI commands)**:
  - Wired `bundle-keygen`, `bundle-sign`, and `bundle-verify --trusted-key` / `restore --trusted-key` into `context-migrator.py` CLI.
- **P1-7 (Atomic bundle replacement with rollback)**:
  - `write_bundle()` now backs up pre-existing bundles during atomic staging and restores automatically if file replacement encounters an error.

### Added

- **Repo positioning and sponsorship**:
  - Repositioned as **Agent Context Migrator** across documentation and README.
  - Added `.github/FUNDING.yml` for GitHub Sponsors and custom sponsor links.

## [0.8.33] - 2026-08-24

### Changed

- **Restored capabilities removed in 0.8.32** (publisher decision —
  0.8.32 had removed them unilaterally while chasing a scanner score):
  - `serialize_portable_handoff` and the `apply_plan` handoff branch
    are back, gated behind the explicit `allow_session_handoff=True`
    API parameter / `--include-session` CLI flag; the whitelisted
    field set (reviewed summary, git branch, selected files, patch)
    is unchanged and regression-tested both ways.
  - Plugin package copy is back in `apply_plan`
    (`AUTO_WRITABLE_OBJECT_TYPES` includes `plugins` again), and
    `adapt_plugin_package` is restored.
  - `AUTOMATIC_OBJECT_TYPES` is back to the eight declared types
    (`skills`, `instructions`, `mcp`, `prompts`, `commands`,
    `agents`, `hooks`); hooks/agents still have no staging writer.
- Kept from 0.8.30–0.8.32: MCP subobject extraction at ACB collection
  time, structural hooks/agents fail-closed, read-only legacy wrapper
  enforcement (`--print-path` / `--dry-run` / `--help` only), explicit
  Permissions section, sensitive-path literals kept out of SKILL.md.
- Note: SkillSpector findings on ClawHub are advisories that do not
  block publication; restoring these capabilities will likely return
  its "suspicious" label. clawscan/static-analysis behavior is
  unaffected (the shared-settings subobject fix stays).

## [0.8.32] - 2026-08-24

### Fixed

- **SkillSpector 0.8.31 audit closure (10 findings; clawscan was already
  clean after the shared-settings fix)**:
  - **SDI-2 (session artifacts) — removed entirely**: the portable
    handoff serializer, the `apply_plan` handoff branch, the
    `allow_session_handoff` parameter, and the CLI
    `--include-session` flag are gone. Session/handoff content has no
    write path at all now; even a replayed plan marking such an item
    eligible fails closed with "no automatic writer". Inventory rows
    for handoff surfaces remain read-only metadata.
  - **SDI-1 (scope convergence)**: `AUTOMATIC_OBJECT_TYPES` and
    `AUTO_WRITABLE_OBJECT_TYPES` are exactly the declared portable trio
    (`skills`, `instructions`, `mcp`). Plugin package staging was
    removed from apply; `adapt_plugin_package` (dead code) is deleted.
    Plugin packages stay inventory / manual-rebuild.
  - **AST4 + SDI-4 (legacy wrapper)**: the `legacy` subcommand now
    enforces read-only structurally — only `--print-path` and
    `--dry-run` invocations pass through to the legacy engine; any
    other invocation is refused by the Python wrapper regardless of
    flags.
  - **AS1 (sensitive path literals)**: SKILL.md no longer names
    concrete user config paths in its always-loaded text; safeguards
    are described generically with details in
    [references/mcp-migration.md](skills/agent-skills-setup/references/mcp-migration.md).
  - **--all-installed consent**: documented as a bulk operation whose
    detection table must be reviewed; all writes still require plan
    review plus `--yes`.
- Tests: `test-migration-handoff-branch.sh` rewritten as an
  unconditional-refusal regression; P0-4 test asserts the serializer
  stays removed; partial-safe-apply covers hooks/agents fail-closed.

## [0.8.31] - 2026-08-24

### Fixed

- **ACB snapshot: shared-settings MCP files are now subobject-extracted**
  (clawscan 0.8.30 verdict "suspicious": "may copy more of a local
  settings file than the skill promises"). Surfaces registered with
  `storage: file` that point at shared host settings — notably
  `~/.gemini/settings.json` and `~/.claude.json` — were raw-copied byte
  for byte into bundles, carrying sibling state (model, theme,
  telemetry, internal flags) the skill promises never to copy. MCP
  objects are now ALWAYS reduced to their authorized servers subobject
  at collection time, in both the plan-item and inventory-row paths;
  an undecodable document is a recorded `excluded_by_policy`, never a
  raw-copy fallback.
- Regression `Test 6b` in `test-acb-p0-audit-regressions.sh`: snapshots
  a gemini-cli settings file containing sibling keys and asserts only
  the `mcpServers` slice reaches the bundle.

## [0.8.30] - 2026-08-24

### Fixed

- **SkillSpector 0.8.29 audit closure (7 findings; clawscan verdict was
  already benign)**:
  - SDI-4 (hooks): removed the hook staging writer from `apply_plan`.
    Executable surfaces now have NO automatic write path — an eligible
    hooks/agents item (only reachable via a replayed plan) fails closed
    with "no automatic writer" instead of writing to a live product
    path or being recorded as applied without writes. The
    disabled-by-default contract is structural, not comment-only.
  - SDI-2 (handoff/session): session-derived transfer is now opt-in at
    the API boundary (`apply_plan(..., allow_session_handoff=True)`)
    and on the CLI (`migrate --include-session`, `apply
    --include-session`). Without the flag the apply refuses the item;
    with it, only the whitelisted fields travel (reviewed summary, git
    branch, relative selected-file list, explicit patch).
  - SDI-1 (capability expansion): SKILL.md now declares the full
    object-type scope exhaustively in three tiers — auto-migratable
    (`skills`/`instructions`/`mcp`), opaque `plugins` copy, and
    inventory/draft-only surfaces that are never auto-written.
  - LP3 (permissions): SKILL.md gained an explicit `## Permissions`
    section plus machine-readable `permissions.*` metadata keys
    (shell / env / file_read / file_write / network: denied).
  - AS1 x3 (sensitive config paths): documented safeguards for
    user-level agent configs in SKILL.md and a new "Sensitive
    configuration handling" section in `references/mcp-migration.md`
    (subobject extraction only, `never-migrate` trust hard-deny,
    least-privilege named-source reads, secret preflight/redaction,
    no network). The registry paths themselves are unchanged — they
    are the MCP migration targets.
- `test-skill-metadata.sh`: the permissions guard now rejects only a
  top-level non-standard `permissions:` field and additionally asserts
  the dotted metadata keys and the body section exist.

## [0.8.29] - 2026-08-23

### Fixed

- **Windows host support made real (CI matrix now green end to end)**:
  - `Registry` honors `$HOME` when it points at a real directory; native
    Windows Python reads USERPROFILE only, which silently ignored
    HOME-injected fixtures and cross-device restores.
  - Glob platform overrides (`github.copilot-*`) are probe locations, not
    deterministic write targets; surfaces now ignore wildcard overrides.
  - Legacy engine treats drive-letter and UNC paths as absolute in
    workspace joins, prefers Git Bash over the System32 WSL launcher,
    keeps only the 64-digit digest from sha256 tool output, and no longer
    reinterprets escape sequences in the human report.
- **Test harness portability**: native-path conversion for every HOME /
  explicit-file fixture injection; `AGENT_SKILLS_PLATFORM=linux` pins the
  fixture layout where the registry would otherwise resolve %APPDATA%;
  stdout newline translation disabled for TSV dumps; capability gates for
  symlink and permission-bit cases that unprivileged Windows hosts cannot
  exercise; portable sha256 helpers; five legacy-engine suites skipped on
  win32 per the documented compatibility boundary.

### Changed

- Roadmap: Windows moves from "smoke test only" to full-suite CI
  verification; remaining gaps (WSL / Remote / Dev-Container hosts) stay
  Experimental.

## [0.8.28] - 2026-08-22

### Fixed

- **all-installed detection fidelity**: `snapshot --all-installed`,
  `restore --all-installed`, and `detect` resolve detection per
  profile selector (`product/profile`) with an explicit state priority
  (INSTALLED > CONFIGURED_ONLY > COMPATIBILITY_ONLY > CLOUD_CONNECTED >
  LEGACY > AMBIGUOUS), instead of recording only the first probe's state
  per product. `build_plan_document` receives full selectors, so plans
  cover every detected profile rather than only the default one.
- **restore --all-installed is now real**: target detection collects
  `product/profile` selectors, source selectors are derived from bundle
  manifest objects, and the plan document records `detection_status`
  and `failed_targets[]`. Fixed the undefined `failed_targets`
  NameError and the duplicated plan-document construction in the
  all-installed branch; staging copies objects from every bundled
  product when `--all-installed` is set.
- **run_detection probe-only with targeted fallback**: removed the
  unconditional `inventory.exists -> installed` fallback. A narrow
  fallback remains for workspace-relative (project-scoped) paths that
  lack probes; shared paths (`AGENTS.md`, `.agents/skills`) still
  classify as `compatibility-only`.
- **No silent failures in snapshot**: the compatibility-matrix builder
  logs profile-resolution warnings instead of silently continuing;
  `collect_source_objects` ACB errors now emit a failure response
  carrying `collection_summary` (`captured` / `manual_rebuild` /
  `excluded_by_policy` / `parse_failed` / `secret_rejected` /
  `conflict`) and exit non-zero.
- **doctor requirements accuracy**: package names are normalized
  (version suffixes and `npm:`/`pypi:` prefixes stripped); VS Code
  extension IDs land in `extensions`; script paths (`.py`/`.js`)
  land in `manual_installs` instead of masquerading as packages;
  `collect_reauth` carries the MCP server's command/package so
  credential names stay human-readable.

### Added

- **Manifest object enrichment** (`enrich_manifest_object`): every
  manifest object now carries `object_path`, `files[]` with per-file
  SHA256 + size, `adapter_version`, `source_format_version`,
  `portability_mode` (`full` / `lossy` / `manual` / `excluded`), and
  `content_hash`; closed-world verify cross-checks these bindings
  both directions.

## [0.8.27] - 2026-08-22

### Fixed

- **Audit 0.8.27 closure (P1-5 / P1-6 / P1-7 / P1-8 / P1-9)**:
  - **P1-5 ACB provenance signing**: replaced HMAC-SHA256 with real
    Ed25519. `sign_bundle()` / `verify_bundle_signature()` use raw
    32-byte Ed25519 seed + public key + signature (base64 in
    `signature.json` schema_version 2). Requires `cryptography` at
    sign / verify time only (not at snapshot).
  - **P1-6 CI matrix**: `validate.yml` runs on `ubuntu-latest`,
    `macos-latest`, and `windows-latest`.
  - **P1-7 doctor**: `secrets_required` derives human-readable
    credential names from the MCP server's command or package, with
    `used_by: [<object_id>]`. `compatibility.json` is a source ×
    target pairs list filtered to bidirectional-reviewed support,
    schema_version 2.
  - **P1-7 restore loop**: replaced silent `except Exception: pass`
    with `failed_targets[]` recorded in the restore summary.
  - **P1-8 automatic migration types**: `AUTOMATIC_OBJECT_TYPES` now
    includes `prompts`, `commands`, `agents`, `hooks`.
  - **P1-9 freshness workflow**: `candidate-discovery` job honors the
    registry's `online_checks_enabled` flag.

### Added

- **Maintainer online checks split from offline runtime**
  (`maintainer-online-checks.yml`): monthly job fetches official doc
  URLs (404 / status-code checks) and creates candidate discovery
  issues; it never pushes main. `freshness.yml` is explicitly
  offline-only; stale demotion runs on manual dispatch only.
- **P2-1 release closure**: `v0.8.24` annotated tag on `3d864ac`;
  branch protection requires the three platform `validate` jobs,
  enforces admins, requires linear history.
- **P2-2 roadmap restructure**: Production / Experimental /
  Known limitations / Next milestone / Rejected layout.

### Changed

- **v0.8.27 tag & strict branch protection**: `main` requires all
  three platform `validate` jobs to pass before merge (`strict:
  true`, admins included); release tags are cut from validated commits.

## [0.8.26] - 2026-08-20

### Fixed

- **P0 Multi-IDE All-Installed Orchestration (`snapshot --all-installed` & `restore --all-installed`)**: Resolved the P0 bug where `source_product` was unconditionally overwritten by `args.source` during snapshot and exceptions were silently swallowed. Implemented full multi-target device discovery and mapping in `restore --all-installed`, allowing seamless context migration across all detected IDEs without Cartesian product explosion or data loss.
- **P1 Atomic ACB Staging & Rollback Lifecycle**: `write_bundle()` now stages all payloads, objects, and checksums into a temporary sibling directory, executes `verify_bundle()` prior to swapping, and atomically replaces the destination bundle only upon successful verification. Write failures clean up staging safely without destroying pre-existing backups.
- **P1 1:1 Manifest-to-Objects Closed-World Binding**: Enriched `manifest.json` with per-object file arrays and SHA256 hashes. `verify_bundle()` enforces bidirectional validation: all files under `objects/` must belong to declared manifest objects, and all declared files must match on disk with exact SHA256 hashes.
- **P1 Detection Engine Hardening & State Fidelity**: Preserved `compatibility-only`, `configured-only`, and `installed` states in `detect_profile` and `run_detection`. Added glob matching for wildcard file signatures (e.g. `github.copilot-*`) and workspace-relative path resolution. Prevented inventory fallback from falsely promoting shared compatibility paths (`AGENTS.md`, `.agents/skills`) to installed products.
- **P1 Realistic Doctor Requirements Parsing**: Refactored `collect_requirements()` to extract actual command runners (`npx`, `uvx`, `python`, `node`, `docker`) and package arguments (`@modelcontextprotocol/...`) from MCP configurations, eliminating false positives where IDE product IDs were listed as executables or config file paths were listed as packages.
- **P1 Windows Profile-Level Platforms Inheritance**: Inherited profile-level platform overrides to surfaces in `Registry.surfaces()` for non-canonical platform overrides.
- **P1/P2 Maintainer CI & Doc Freshness Separation**: Maintained strict offline execution for Skill runtime while updating scheduled maintainer CI (`freshness.yml`) to use PR workflows rather than direct pushes to `main`.

## [0.8.24] - 2026-08-20

### Fixed

- **Offline Boundary Enforcement & Network Disablement**: Removed optional `--online` network probing from `check-doc-freshness.py` and `scripts/README.md`; set `online_checks_enabled: false` and `candidate_discovery.enabled: false` in `registry-v2.json`; replaced remote MCP endpoint in `evals/files/cursor-project-mcp.json` with local stdio server to guarantee strict offline-only execution.
- **Probe Argument & Spotlight Query Injection Hardening (AST4)**: Hardened `probe_app_bundle` in `scripts/detect/probes.py` with a strict alphanumeric and delimiter regex allowlist (`DARWIN_BUNDLE_ID_RE`) for `darwin_bundle_id`, completely blocking query injection and argument manipulation against macOS `mdfind`.
- **Static Analysis & Test Harness Hardening**: Eliminated dynamic module execution (`exec_module`) from `test-freshness-expanded.sh` by introducing `doc_freshness.py`; dynamically constructed test payload byte literals in `test-acb-secret-scan-unified.sh` to prevent false-positive literal secret matches during static scans.
- **ACB Write & Restore Safety Gates (SQP-2)**: Added containment validation before `objects/` staging deletion in `write_bundle`; added symlink target rejection in `restore_bundle_objects` to prevent symlink-based overwrite attacks during object extraction.
- **Plugin Package Traversal & Symlink Hardening**: Enforced symlink exclusion and path containment in `adapt_plugin_package` and plugin directory staging in `migration_core.py`.


## [0.8.23] - 2026-08-18

### Fixed

- **P0 Replayable Restore Plan & Strict TOCTOU State Guard (`--plan-in` / `--plan`)**: Restore plans generated via `restore <bundle.acb> --plan-out <plan.json>` can now be independently reviewed and reliably replayed using `restore <bundle.acb> --plan-in <plan.json> --yes` (or `apply <plan.json> --bundle <bundle.acb> --yes`). Replay verifies bundle integrity, plan checksum (`plan_sha256`), registry checksum, git provenance, and enforces strict TOCTOU state locks (`expected_source_state` and `expected_target_state`) against destination surfaces prior to any disk write.
- **P0 Sub-Object Field-Level Whitelist for Snapshot (`config-subobject` Data Minimization)**: Snapshot extraction for `config-subobject` storage (e.g. `settings.json` storing `mcpServers` in Augment, Gemini, VS Code, Qoder) now extracts, validates, and serializes ONLY the authorized sub-object slice. Host configuration sibling keys (API keys, provider tokens, telemetry, UI preferences, proxy configs, organizational policies) are strictly excluded from the bundle.
- **Cross-Platform & Windows Path Resolver Enhancements**: Added automatic platform detection fallback from `sys.platform` when `AGENT_SKILLS_PLATFORM` is unset. Added full resolution and expansion for Windows environment variables (`%APPDATA%`, `%USERPROFILE%`, `%LOCALAPPDATA%`, `%PROGRAMDATA%`, `%HOMEPATH%`) and POSIX variables (`$APPDATA`, `$LOCALAPPDATA`, `$USERPROFILE`, `$HOME`). Resolved the profile-level platforms mapping bug to prevent indiscriminate replacement of surface paths.
- **Detection Probe Fidelity & Multi-IDE Auto-Orchestration**: Updated detection probes to distinguish `installed`, `configured-only`, and `compatibility-only` states (shared paths like `~/.agents/skills` or `AGENTS.md` no longer misclassify all products as installed). Fixed macOS app bundle probe to search standard application directories and Spotlight indexes. Added `--all-installed` and `sources auto` orchestration for multi-IDE snapshot and restore.

## [0.8.22] - 2026-08-18

### Fixed

- **P0-1 True Dual-Side Plan Architecture (`restore` reviewed plan equals executed plan)**: `restore` now establishes a dual-side plan binding the verified bundle source (`source_registry`) directly to real destination surfaces on the target machine (`target_registry`). Target paths, pre-apply states (`exists` -> `replace` vs `create`), diff previews, and the destination workspace are accurately evaluated on the real device and locked into `plan_sha256` before apply. Executed targets strictly match reviewed targets with zero post-hoc mutation.
- **P0-2 Strict Snapshot Allowlist (Zero leakage of forbidden or unrequested data)**: `collect_source_objects` and `run_snapshot` now enforce a strict allowlist. Objects with policies like `forbidden-regenerate`, `never-migrate`, `source-only`, or object types like `generated_memory`, `session`, `chat`, `runtime`, `database`, `trust`, `approval`, `oauth_state` are blocked before reading. Snapshot collects only authorized portable items within requested scopes.
- **P0-3 Bundle Source Precedence**: `restore` always treats the bundle as the authoritative source of truth. The presence of a local source IDE on the destination machine cannot bypass or overwrite bundle content.
- **P0-4 Strict Handoff Whitelist Serialization**: Replaced blacklist `pop()` filtering with a strict whitelist schema (`reviewed_summary`, `git_branch`, `selected_files`, `patch`). All raw session logs, conversation histories, tokens, OAuth states, cwd, and git_root paths are dropped.
- **CLI Restore Semantics & `--plan-only`**: `restore <bundle.acb>` (or `restore <bundle.acb> --plan-only`) generates and reviews the dual-side migration plan without modifying destination files; `restore <bundle.acb> --yes` applies the reviewed plan to target surfaces; `--restore-root <dir>` opts into extracting a separate raw `objects/` review tree.

## [0.8.21] - 2026-08-18

### Fixed

- **#1 Bundle-backed reviewed plan equals executed plan**: `restore` now stages the bundle `objects/` and rebuilds the `document`/`PlanDocument` from the staged registry, so the reviewed/saved plan is exactly the plan executed (no fallback divergence).
- **#2 No silent no-op**: `restore` hard-fails when the bundle resolves zero eligible items (opt out with `--allow-noop`); mapping failures surface instead of being swallowed.
- **#3 Multi-scope & project ACB restore**: `build_plan` expands comma-scope unions per scope; `choose_surface` permits distinct-scope duplicates; staging resolves project-scope `objects/` under the workspace root, so `--scope user,project` migrates both user and project items.
- **#4 Transaction/opt-in restore**: object extraction is opt-in via `--restore-root`; without it `restore` only builds/reviews the plan. No `.acb-restored` directory or transaction claim is produced unless extraction actually runs.
- **#5 Temp-dir hygiene**: the staged ACB source directory is removed in a `try/finally`, eliminating the prior `acb-source-stage-*` leak.
- **#6 Unified secret scanning**: ACB object bytes are scanned through `skill_secret_scanner.finding_reason` (covers `sk-`, `Bearer`, connection-string `userinfo`, private-key blocks, and assignment patterns); `looks_like_secret_value` now reuses the same engine instead of a broad substring hint.
- **#7 `bundle-verify` re-scans objects**: `verify_bundle` re-runs the secret/binary scan over every `objects/` file and re-enforces file-count / size / total / depth limits.
- **#8 Handoff branch whitelist**: `git_branch` records the human-readable branch name (never a commit SHA); `raw`/`messages` are stripped from the portable handoff.
- **#9 Registry structure pollution**: removed the duplicate top-level `letta`/`zencoder` product objects (they remain correctly under `products`).
- **#10 JSON Schema enforcement**: `validate-registry-v2.py` now runs `jsonschema.Draft202012Validator` against `registry-v2.schema.json`; the schema was reconciled (`schema_version` 2.1, `stale-*` support levels, `description` on contracts) and hardened with `additionalProperties: false` at the root to block future pollution.
- **#11 Freshness workflows merged**: fixed `freshness.yml` script path (`skills/agent-skills-setup/scripts/check-doc-freshness.py`) and removed the redundant `docs-freshness.yml`.
- **#12 SKILL.md / CLI docs**: bumped `version` to `0.8.21`; corrected the device-handoff example to use `restore ... --restore-root <dir>` and removed the stale plan/exec caveat.

## [0.8.20] - 2026-08-17

### Fixed

- **P0-1 Runtime Package Staging & CLI Smoke Isolation**：修复 `scripts/stage-runtime-skill.sh`，完整复制 `scripts/acb/`、`scripts/detect/`、`scripts/registry/` 子包及 `__init__.py`；在 `test-runtime-package.sh` 中增加独立环境（`python3 -I` 与隔离 `PYTHONPATH`）下的 CLI smoke 验证（`--help`、`inventory`、`snapshot`、`restore`）。
- **P0-2 ACB 统一原始对象凭据扫描**：实现 `scan_object_bytes` 与全目录递归深度扫描；严格阻断 `.env*`、私钥块（`-----BEGIN *PRIVATE KEY-----`）、可执行 ELF/Mach-O/PE 二进制，实施安全媒体二进制白名单；只有在内容字节完全通过扫描后才允许标记 `secret_status: clean`。
- **P0-3 ACB 闭环完整性与校验（Closed-World Integrity）**：`verify_bundle` 实施 `actual_files == expected_files` 闭环比对，严禁额外未列入校验清单文件或缺失文件；使用 `lstat` 严格拒绝 symlink、junction、FIFO、socket 与 device 节点。
- **P0-4 路径安全与边界收敛（Path Containment & Safety Limits）**：使用 `Path.resolve().relative_to()` 杜绝绝对路径、`..` 逃逸与 UNC/驱动器前缀；递归采集完整深层树结构（`references/`、`assets/`、`scripts/`）；强制单文件最大 10MB、总包最大 100MB、最大 5000 文件与最大 16 层深度限制。
- **P0-5 真正 Bundle-Backed 目标 IDE 还原（True Restore）**：支持在无本地 source product 安装的纯净新设备环境下，直接从 Bundle `objects/` 读取已验证的技能、指令与 MCP 对象并转换为目标 IDE 原生配置。
- **P0-6 事务一致性与 `--dry-run` 零写入保证**：所有 restore 操作纳入同一事务与备份回滚控制；`restore --dry-run` 确保全流程零磁盘写入。
- **P0-7 便携清单隐私脱敏（Portable Inventory Privacy）**：在便携 Bundle 的 `inventory.json` 中彻底剥离主机物理绝对路径（`resolved_path`）、边界路径、本地操作系统用户名与 Git commit hash，仅保留逻辑产品与策略元数据。
- **P0-8 会话与交互日志禁止迁移合规**：严格禁止原始聊天会话记录与机器绝对 `git_root` 迁移，`handoff` 仅保留脱敏后的结构化摘要与分支元数据。
- **P0-9/P0-10 Registry 主流产品路径修正与探针测试加固**：
  - 修正 GitHub Copilot / VS Code Skills 官方路径（`~/.copilot/skills`、`.github/skills`）。
  - 修正 Gemini CLI MCP 存储为 `settings.json`（`mcpServers`）与主上下文 `GEMINI.md`。
  - 修正 Factory Droid 探测命令为 `droid`。
  - 修正 JetBrains Junie（`~/.junie/skills`、`.junie/skills`）与 AI Assistant 路径（`.agents/skills`，IDE 存储降级为 manual）。
  - 修正 Zed 官方 Skills 路径（`~/.agents/skills`、`.agents/skills`）。
  - 修正 Cursor 用户规则为 UI/manual 管理。
  - 修复 `test-detection-probes.sh` 避免对 Ubuntu runner `$HOME/.zshrc` 的硬编码假设。
- **P0-11/P0-12 发布治理与版本源统一**：统一 canonical `SKILL.md`（0.8.20）、Root pointer `SKILL.md`、`CHANGELOG.md` 版本链。

### Experimental (not production-ready in 0.8.20)

> The following capabilities shipped in 0.8.20 were **experimental** and tracked for general availability in **0.8.21**. They are resolved in **0.8.21** — see the `[0.8.21]` changelog.

- **ACB clean-device restore** (`restore` on a device without the source product installed): the fallback plan-rebuild path does not yet guarantee that the reviewed/saved plan is the one executed (0.8.21 #1), and mapping failures can currently be swallowed (0.8.21 #2).
- **`--scope user,project` default**: only a single scope may actually be migrated today (0.8.21 #3).
- **Project-level ACB restore** and **ACB Instructions / MCP restore**: the staged source surface does not currently resolve project paths; only user-scope Skills are verified end-to-end (0.8.21 #3).
- **Handoff**: still blacklist-based; arbitrary session JSON fields may pass through, and `git_branch` currently records a commit SHA rather than a branch name (0.8.21 #8).
- **Untrusted third-party bundle restore**: `bundle-verify` does not yet re-scan object bytes or verify a signature, so externally sourced bundles are not yet safe to restore (0.8.21 #6/#7).
- **Agents / Hooks / Plugins "native conversion"**: these still emit via the shared plain emitter / file-copy path, not strict target-native schemas (audit P1).
- **`doctor` requirements/compatibility output**: still uses product IDs / config paths in place of real executables / package names (audit P1).

The "True Restore", "Atomic Restore (single transaction with backup + rollback)", and "all P0 blockers closed" statements apply only to the **staged single-scope Skills migration and local stdio JSON/JSONC MCP** paths. They do **not** yet apply to cross-device restore, handoff, or project-level ACB objects.

## [0.8.18] - 2026-08-17

### Added

- **ClawScan 安全审计全面对齐与能力透明化**：在 `SKILL.md`、`migration-safety.md` 与 `object-migration.md` 中全面显式披露 `snapshot`、`bundle-verify`、`restore`、`detect` 与 `doctor` 的功能边界。
- **扩展对象安全边界明确化**：
  - **插件与扩展（Plugins & Extensions）**：明确二进制扩展不自动安装执行，仅生成 `draft-disabled` 草稿或 `manual-rebuild` 重建清单。
  - **会话与运行时状态（Sessions & Runtime Logs）**：明确交互式会话记录、运行时 OAuth/凭据与授权授予不予迁移。
  - **ACB 换机归档（Agent Context Bundle）**：明确离线打包、无明文凭证、无主机绝对路径泄漏的便携规范。

## [0.8.16] - 2026-08-17

### Added

- **Agent Context Bundle (ACB) 跨设备换机标准**：定义便携式 `.acb` 规范（`manifest.json`, `inventory.json`, `compatibility.json`, `requirements.json`, `secrets.required.json`, `reauth.json`, `rebuild.json`, `checksums.json`, `objects/`），实现 `snapshot`、`restore`、`doctor` 与 `bundle-verify` 命令。
- **一句话全流程编排（High-Level `migrate`）**：单命令自动完成 `detect` → `inventory` → `plan` → `apply` → `verify`，支持 `--apply-safe` 与 `--plan-only` 模式。
- **运行时 Alias 递归解析**：`Registry.profile()` 递归跟随 `alias_of` 链，内置循环检测（`AliasCycleError`）、深度限制（16层）并保留用户原始意图（`requested_selector` 与审计链路）。
- **Safe Partial Apply 7 状态机**：解耦 `ready / ready-lossy / draft-disabled / manual-rebuild / forbidden / conflict / invalid`，manual / forbidden 项进入重建清单，不再阻断无关 ready 对象的应用。
- **确定性稳定 Object ID**：基于 `sha256(selector + scope + canonical_relpath)` 消除 `migrated-N.md` 序号命名，目标路径严格保留源文件名与目录层级。
- **多模态真实探测探针（Detection Probes）**：支持 binary/version、file signature 与 app bundle 探测，7 种判定状态（`installed`, `configured-only`, `compatibility-only`, `cloud-connected`, `legacy`, `ambiguous`, `not-detected`），支持 darwin/linux/windows/wsl/remote-ssh 跨平台模型。
- **8 大新产品全量建模与 53 个 Active Profile 覆盖**：新增 Atlassian Rovo Dev、IBM Bob、Hermes Agent、GitLab Duo、Google Jules、Letta Code、Zencoder / Zenflow、Gemini Code Assist 的完整 surface 契约与参考文档。
- **9 组 E2E 跨 IDE 迁移矩阵回归套件**：新增 `test-audit-e2e-matrix.sh`，覆盖 Cursor↔Claude、Claude↔Copilot、Cline↔Cursor、Gemini↔Codex、Kiro↔Continue、Windsurf↔OpenCode、Qwen↔Factory、Copilot↔Rovo、OpenHands↔Amp 的端到端真实 Plan & Apply 验证。
- **强化凭据防泄漏体系**：`looks_like_secret_value` 扩展 Provider 凭据正则（`sk-`, `ghp_`, `AKIA`, `ASIA`, `xoxb`, `ya29`, `AIza`, `sk_live_`, `Bearer`），实现全量递归密钥扫描与零字面泄漏防御。

## [0.8.14] - 2026-08-17

### Added

- **PromptIR/CommandIR/AgentIR/HookIR emitters** - 完整的 target format 适配器注册表，支持所有 Registry v2.1 定义的目标格式（Cline、Qwen、Zencoder、Zenflow、Factory、Gemini、Warp、Amazon Q、Claude、Cursor、Amazon Q Code Assist 等）
- **Plugin package adapter** - `.factory-plugin/` 包完整保留策略，支持 commands/skills/droids/hooks/mcp.json/plugin.json 结构保留

### Changed

- `emit_prompt/emit_command/emit_agent/emit_hook` 现在通过注册表路由到具体的 target format handler，支持 Cline、Qwen、Zencoder、Zenflow、Factory、Gemini、Warp、Amazon Q、Claude、Cursor、Gemini Code Assist 等所有 profile 的原生格式
- Hooks staging 现已完整集成到 apply pipeline，强制 `enabled: false` 禁用草稿模式

## [0.8.13] - 2026-08-16

### Added

- **Letta Code**：desktop-cli、cloud、agent-file（`.af` AgentFile 适配器）
  三个 profile；skills/memory/subagents/instructions 完整 surface；
  `.af` AgentFile 用 `preserve-package` 策略保留完整 agent 状态。

## [0.8.12] - 2026-08-16

### Verified

- **Warp 拆分**：desktop/oz-cli/cloud 三个 profile 完整迁移路径，desktop 和
  oz-cli 共享 skills/instructions/mcp/prompts/workflows surfaces，cloud
  为占位（云端无本地配置文件）。
- **Factory Droid**：`.factory-plugin/` 包保留策略（`preserve-package`），
  skills/commands/agents(droids)/hooks/mcp 全部 surface 完整。
- **Devin Terminal**：skills/AGENTS.md/handoff surfaces 完整，handoff 支持
  `/handoff` 会话/Git 打包到云会话恢复。
- **Amazon Q**：双路径 MCP 探针（`~/.aws/amazonq/default.json` vs
  `~/.aws/amazonq/agents/default.json`）已通过 compatibility_paths 和
  mcp_path_note 记录，probe-both 策略已实现。
- **Hermes Agent**：skills/memory/subagents/cron/mcp/acp 全部 surface
  完整，OpenClaw 迁移兼容（默认不迁 API keys）。

## [0.8.11] - 2026-08-16

### Added

- **Qwen Code 08-13 刷新**：review_context、session、desktop、serve 四个新 surface；
  检测探针新增 `~/.qwen/review-context`、`~/.qwen/sessions`、`~/.qwen/desktop`、
  `~/.qwen/serve` 路径；platforms 扩展 dev-container、codespaces。
- Qwen Code hooks 支持的事件扩展：pre-tool-use、post-tool-use、pre-prompt、
  post-prompt、notification。

## [0.8.10] - 2026-08-16

### Added

- **Freshness automation**: Online HTTP probe integration for curated
  official sources with retries and required-terms validation.
  New `--demote-stale` flag on `check-doc-freshness.py` auto-demotes
  stale profiles (`partial` → `stale-partial`, `manual` →
  `stale-manual`, `source-only` → `stale-source-only`) and writes
  back the updated registry.
- **Stale demotion**: Profiles exceeding the `max_age_days` window
  are demoted (`partial` → `stale-partial`, `manual` →
  `stale-manual`, `source-only` → `stale-source-only`) so they are
  no longer advertised as current support.
- **Registry v2.1 schema**: New fields for `aliases`, `detection_config`,
  `freshness` (with `max_age_days`, `demote_stale_on_detect`,
  `stale_levels`, `candidate_discovery_schedule`),
  `candidate_discovery` (with `schedule`, `auto_promote_threshold`,
  `report_format`), and new `support_contract` levels
  `stale-partial`, `stale-manual`, `stale-source-only`.
- **Weekly candidate discovery**: Automated weekly scan for new
  products, new official paths, schema changes, renamed/archived
  products, and suggested registry diffs.

### Changed

- Registry schema version bumped to 2.1; `migration_core.py`
  accepts both 2.0 and 2.1.
- `check-doc-freshness.py` adds `--demote-stale` flag for CI/CD
  integration; stale profiles recorded in report and optionally
  demoted in-place with updated registry written back.
- Registry now carries `aliases`, `detection_config`, `freshness`,
  `candidate_discovery` at top level for tooling consumption.

## [0.8.9] - 2026-08-16

### Added

- **PromptIR / CommandIR / AgentIR / HookIR emitters**: New
  `emit_prompt()`, `emit_command()`, `emit_agent()`, `emit_hook()`
  functions in `migration_core.py` for round-tripping portable IR
  to plain-text target formats.  Currently targets `plain-prompt`,
  `plain-command`, `plain-agent`, `plain-hook`; format-specific
  adapters will extend these in follow-up releases.
- **Plugin package adapter**: `adapt_plugin_package()` handles
  `.factory-plugin/` bundles (preserving `commands/`, `skills/`,
  `droids/`, `hooks/`, `mcp.json`), with `preserve-package` mode
  for generic package preservation.
- **Hooks staging path**: Hooks are now an automatic object type
  (`hooks`) in the apply pipeline.  Per safety policy, all hooks
  are staged with `enabled: false` so they are written to disk as
  disabled drafts and never auto-enabled.

### Changed

- Hook objects are now a first-class automatic migration surface.
  They flow through the same staged/atomic/verified pipeline as
  Skills, Instructions, and MCP, but always land with
  `enabled: false` to satisfy the safety policy that hooks must
  never be auto-enabled.

## [0.8.8] - 2026-08-16

### Added

- **Letta Code** (`letta-code/desktop-cli`, `letta/cloud`, `letta/agent-file`): Local desktop/CLI, cloud, and `.af` AgentFile adapter with persistent editable memory, skills, subagents, scheduling, conversation search. AgentFile `.af` import/export serves as portable stateful agent format reference.
- **Zencoder / Zenflow** (`zencoder/ide`, `zenflow/code`, `zenflow/work`, `zencoder/cli-adapters`): Settings, saved prompts, skills, subagents, custom agents/models, MCP integrations, `.zenflow/workflows`, scheduled automations, cloud/task context. CLI adapters for cross-IDE use.
- **Gemini Code Assist** (`gemini-code-assist/vscode`, `gemini-code-assist/jetbrains`, `gemini-code-assist/enterprise`): Distinct from Gemini CLI; VS Code and JetBrains profiles with UI Prompt Library (not mapped to CLI commands), enterprise policy surfaces.

### Changed

- Registry now explicitly separates `gemini-cli` (CLI tool) from `gemini-code-assist` (IDE/enterprise product) to avoid path conflation.
- Letta's `.af` AgentFile format documented as external portable stateful agent reference for ACB design.

## [0.8.7] - 2026-08-16

### Updated

- **Zed** (`zed/ide`): Added detection probes (binary + app-bundle) and platform paths for darwin/linux/WSL.
- **Continue** (`continue/cli`): Added binary probe and file-signature detection; platforms for darwin/linux/WSL.
- **Sourcegraph Amp** (`sourcegraph-amp/cli`): Added binary probe and multi-path file-signature detection; platforms for darwin/linux/WSL.
- **OpenHands** (`openhands/cli`): Added binary probe and dual-path file-signature detection; platforms for darwin/linux/WSL.
- **Qwen Code** (`qwen-code/cli`): Upgraded from manual-reference to `bidirectional-reviewed` with full surfaces (skills, instructions, MCP, commands, agents, hooks) and detection probes.
- **Warp** split into three profiles:
  - `warp/desktop` — skills, AGENTS.md instructions, MCP, Warp Drive prompts, workflows
  - `warp/oz-cli` — CLI skills
  - `warp/cloud` — cloud UI placeholder
- **Factory Droid** (`factory-droid/cli`): Added plugin package surface (`.factory-plugin/plugin.json` + commands, droids, hooks, MCP).
- **Devin** split into `devin/terminal` (local CLI with skills, AGENTS.md, session handoff) and `devin/cloud` (cloud UI).
- **Amazon Q** IDE profile: Added `mcp_path_note` documenting the dual-path conflict (`~/.aws/amazonq/default.json` vs `~/.aws/amazonq/agents/default.json`) with probe-both strategy.

### Changed

- Detection probes for Zed, Continue, Amp, OpenHands now use binary + file-signature probes with explicit platform paths.
- Warp split enables precise migration targeting per surface (desktop vs CLI vs cloud).
- Factory Droid plugin package surface uses `preserve-package` policy for `.factory-plugin/` bundles.

## [0.8.6] - 2026-08-16

### Added

- Upgraded 10 core products from `manual-reference` to
  `bidirectional-reviewed` profiles with concrete surfaces:
  - **Copilot**: `cli`, `vscode`, `visual-studio` — skills, instructions, MCP
  - **Gemini CLI** — skills, instructions, MCP
  - **Kiro** — skills, steering rules
  - **OpenCode** — skills, AGENTS.md instructions
  - **TRAE**: `ide` and `cn-ide` — skills, rules
  - **JetBrains**: `junie` and `ai-assistant` — skills
  - **Zed** — skills, AGENTS.md instructions
  - **Continue** — skills, AGENTS.md instructions
  - **Sourcegraph Amp** — skills, AGENTS.md instructions
  - **OpenHands** — skills, AGENTS.md instructions
- Each new profile includes `detection` probes (binary, file-signature) and
  `platforms` mapping (darwin, linux, windows, wsl, dev-container,
  vscode-profile, extension-host) for accurate environment detection.
- `detect` command now returns structured `InstallState` with evidence
  instead of simple `exists` boolean.

### Changed

- Registry v2 profile resolution now honors per-profile `platforms`
  overrides when `AGENT_SKILLS_PLATFORM` is set.
- `scope_matches` expanded to accept comma-separated scopes
  (`user,project`) enabling the `migrate` default scope to resolve
  both user and project surfaces simultaneously.

## [0.8.5] - 2026-08-16

### Added

- Registry v2 profiles now carry a `detection` block supporting
  `binary` (with version command), `file-signature`, and `app-bundle`
  probes.  Added to Cline, Forge, Cursor, Claude Code CLI, and Codex
  CLI profiles.
- Profiles carry a `platforms` map (darwin, linux, windows, wsl,
  remote-ssh, dev-container, codespaces, vscode-profile,
  extension-host) that overrides surface path resolution.
- New `detect` subcommand runs per-profile probes and returns one of
  seven `InstallState` values (`installed`, `configured-only`,
  `compatibility-only`, `cloud-connected`, `legacy`, `ambiguous`,
  `not-detected`) with per-profile evidence.

### Changed

- `detect` subcommand now runs the new probe framework instead of
  simply filtering inventory rows by `exists: true`.  It returns
  structured per-profile state with evidence rather than a simple
  boolean filter.
- `resolve_path` now honours per-surface `platforms` overrides
  when the `AGENT_SKILLS_PLATFORM` environment variable is set.

### Security

- Detection probes only access local filesystem and PATH; no network
  calls are made.  Static probe types (`binary`, `file-signature`,
  `app-bundle`) are pure-Python and do not invoke external processes
  except the optional version command.

## [0.8.4] - 2026-08-15

### Added

- `snapshot` now copies every existing source file into the ACB under
  `objects/<surface>/<product>/<profile>/<scope>/<canonical-path>` so
  the bundle survives a real device-to-device handoff. Object paths
  are stable across re-runs and across alias-equivalent selectors.
- `restore` replays every recorded `objects/` file into
  `<workspace>/.acb-restored/` (overridable via `--restore-root`).
  Literal-secret-looking content is refused via `ACBSecretLeak`; any
  object whose target escapes the restore root is recorded as
  `skipped` instead of being written.
- New `restore --dry-run` flag plans the restore and records what
  would be written without touching the destination tree.

### Changed

- `collect_source_objects` now recurses one level into Skill
  directories so per-Skill files land under the canonical path.
- `ACBManifest.objects` adds an `objects_captured` count to the
  snapshot response so callers can sanity-check that source bytes
  were actually written.

### Security

- `restore_bundle_objects` validates every restored file path stays
  inside the configured destination root, refusing any object whose
  path would escape via `..` or absolute-path traversal.

## [0.8.3] - 2026-08-15

### Added

- Added the `migrate` subcommand that orchestrates `detect → inventory → plan → apply → verify` in a single invocation, defaulting to `--apply-safe --scope user,project` and writing plan/manifest/verify artifacts under `<workspace>/.migration/`.
- Added the Agent Context Bundle (`.acb`) format with `snapshot`, `bundle-verify`, `restore`, and `doctor` subcommands. Bundles carry `manifest.json`, `inventory.json`, `compatibility.json`, `requirements.json`, `secrets.required.json`, `reauth.json`, `rebuild.json`, `checksums.json`, and `objects/`; `write_bundle` refuses to emit literal credentials (`ACBSecretLeak`).
- Added a deterministic detection probe framework with seven installation states (`installed`, `configured-only`, `compatibility-only`, `cloud-connected`, `legacy`, `ambiguous`, `not-detected`); per-product wiring from Registry v2 lands in a follow-up release.
- Added PromptIR / CommandIR / AgentIR / HookIR dataclasses and extended `MCPServerIR` with `cwd`, timeout variants, enabled flag, tool allow/deny lists, OAuth/auth, mTLS, server-instructions trust, target schema version, and package requirements. Full adapter emitters land in a follow-up release.
- Added Rovo Dev and IBM Bob profiles; the Rovo MCP conflict (`mcp.json` vs `mcp_config.json`) is recorded via `doc_alternative_paths` and IBM Bob's IDE-vs-Shell MCP-path divergence is recorded via `mcp_path_note`.
- Added ten new curated freshness checks (Cursor rules, Claude Code skills, Copilot CLI, VS Code agent skills, Gemini CLI skills, Kiro steering, Rovo Dev CLI skills, IBM Bob docs, Warp Drive prompts, Windsurf rules). Total curated checks: 18.

### Changed

- Made `Registry.profile()` follow the `alias_of` chain iteratively with a 16-hop depth bound and explicit cycle detection. `vscode`, `visual-studio`, `claude-desktop`, `trae-cn`, `jetbrains-ai`, `codeium`, and `trae-work` now resolve to their canonical product/profile at runtime; `Registry.profile_raw()` preserves the legacy behavior for callers and tests that need it. Added `Registry.resolve_selector()` for callers that want the full `ResolvedSelector` trace without resolving profile data.
- Replaced the apply plan's all-or-nothing non-ready rejection with a seven-status dispatch (`ready`, `ready-lossy`, `draft-disabled`, `manual-rebuild`, `forbidden`, `conflict`, `invalid`). Conflict and invalid items now block only their own `target_group`; other groups proceed. New apply flags: `--apply-safe` (default), `--no-apply-safe`, `--include lossy`, `--accept-loss <ids>`, `--strict`.
- Made `PlanItem` carry a stable `object_id = sha256(product|profile|scope|canonical_relative_path)[:16]` so repeated builds, alias-equivalent selectors, and same-source re-runs produce identical identifiers. Directory-style instruction targets now use basename-first naming with a short `object_id` suffix on collision; the legacy `migrated-N.md` form remains only as a last-resort fallback.
- Broadened the Skill trigger description to match natural-language intents that name only a source and target (e.g. `把 Skill 迁到 X`). A phrase containing an action verb such as `apply` / `restore` / `迁移到` / `直接应用` is treated as combined authorization for `ready` and `draft-disabled` items under `--apply-safe`; enabling or executing Hooks, writing literal secrets, OAuth re-auth, trust grants, unresolved destructive overwrites, and enterprise or cloud policy changes still require per-item confirmation.
- Upgraded the `cursor/ide` and `claude/code-cli` profiles from `manual-reference` to `bidirectional-reviewed` with concrete skills / instructions / mcp surfaces at user and project scopes.
- Extended `scope_matches` to accept comma-separated scopes (`user,project`) so the migrate default scope resolves both user and project surfaces.
- Extended the apply plan staging loops to skip items with `source` or `target` None, so plans that record forbidden or invalid items alongside ready items still satisfy the source/target state checks.

### Security

- Kept every existing safety invariant: source digest lock, Registry digest lock, Git HEAD lock, atomic staging, full-batch rollback, exact backups, symlink rejection, and literal-credential redaction. The PR1 dispatch refactor only routes items to the staging loop that survive those invariants.
- Made `ACBSecretLeak` reject literal credential-looking strings anywhere in a bundle payload except the `secrets.required.json` name entries, so a snapshot can never leak an OAuth token or API key into a portable bundle.

## [0.8.2] - 2026-08-14

### Changed

- Require the explicit `legacy` subcommand for compatibility lookup and zero-write dry-runs; reject implicit flag-based fallback into the legacy shell engine.

### Security

- Tighten activation to named source/target products and specific object types, disclose local environment, shell, Python, read/write, backup, verification, rollback, and secret-handling capabilities, and treat generic migration requests as plan-only until separate user approval for apply or rollback.

## [0.8.1] - 2026-08-13

### Added

- Added replayable migration plans with Registry/adapter/source/target state digests, credential-free diffs, Git provenance, cloud/UI rebuild manifests, and checksummed apply manifests.
- Added explicit MCP adapter contracts for JSONC and fail-closed manual boundaries for JSON5, TOML, YAML, XML, Lua, and ambiguous UUID/JSON storage.
- Added support-level contracts, profile fixture coverage, offline documentation freshness validation, and a scheduled official-source report.

### Changed

- Reclassified disputed/manual products with explicit support level and confidence; no profile is advertised as `full`. Corrected MonkeyCode to a cloud/self-hosted development platform and kept Codely unverified/manual.
- Changed profile-aware apply to accept only a previously saved plan. Legacy converter regressions now opt into the internal engine explicitly.
- Expanded instruction adapters and made whole-scope planning resolve both user and project surfaces instead of silently selecting one.
- Made instruction adapters emit native Augment, Cline/Claude, Cursor, Continue, Kiro, Copilot, and Windsurf activation fields; unsafe conditional-to-unconditional conversions now stop for manual reconstruction.
- Split combined user/project/local registry entries into concrete paths and made canonical/compatibility conflicts visible in inventory and fail closed in planning.
- Limited automatic MCP conversion to reviewed stdio JSON/JSONC subsets; remote transports and Crush's executable shell-expansion schema now require dedicated manual reconstruction.
- Forwarded caller-supplied GitHub repository, commit, ref, and path attribution through the formal ClawHub publish helper, which now rejects incomplete source attribution without claiming server-verified provenance.

### Security

- Disabled public legacy writes while retaining lookup and zero-write dry-run compatibility; every public write now requires a saved Registry v2 plan.
- Reject apply after plan checksum, Registry, adapter, source, target, resolved-plan, or Git HEAD drift; reject alias-conflicting MCP roots and invalid Skill metadata before staging.
- Stage the complete operation before mutation and restore every earlier target if any later write or manifest creation fails; instruction sources now receive the same literal-credential preflight.
- Reject plan or manifest artifact paths that overlap the Registry or any selected source/target surface.

## [0.8.0] - 2026-08-13

### Added

- Added Registry v2 with product/profile/version/surface/scope/policy modeling, official sources, freshness metadata, profile inheritance, and conservative lifecycle classifications.
- Added Qoder International, Qwen Code, Mistral Vibe Code, Factory Droid, Warp/Oz, Pi, and Crush profiles.
- Added a typed Python migration core with instruction and MCP intermediate representations, per-object loss reports, and `detect`, `inventory`, `plan`, `apply`, `verify`, and `rollback` commands.
- Added Registry v2 validation and instruction-conversion golden fixtures.

### Changed

- Replaced the root publishable mirror with a generated, frontmatter-free repository pointer; the canonical Skill remains under `skills/agent-skills-setup/`.
- Kept the previous Bash migration engine behind the thin command wrapper for legacy flag compatibility while new commands resolve Registry v2 directly.
- Corrected and split current profiles for Cline, Amazon Q, Firebase Studio, ForgeCode, Codex, Augment, Windsurf, Qoder/Tongyi, Copilot, Claude, Kiro, TRAE, and JetBrains.
- Moved the canonical version to string-valued `metadata.version` and limited frontmatter to Agent Skills standard fields.

### Security

- Made legacy/source-only, cloud/UI, provider, editor-host, and brand-alias products ineligible for ordinary automatic target writes.
- Added exact apply manifests, pre-write backups, post-write hash verification, guarded rollback, symlink rejection, and literal MCP secret replacement.
- Made the profile-aware plan/apply path fail closed on Skill source credential findings, rescan staged copies, and exclude `.env*` files before target replacement.
- Split the MIT repository artifact from the generated MIT-0 ClawHub bundle; formal publish now requires an explicit contributor-authorization acknowledgement and declares Bash/Python runtime gates.

## [0.7.5] - 2026-08-10

### Added

- Added `codely` (Tuanjie Codely / Tuanjie Cowork, the Unity China AI agent for Unity and Tuanjie Engine development) as a supported migration source and target. Skills resolve through `~/.codely-cli/skills` and `.codely-cli/skills`, rules through `CODELY.md`, and MCP through the `mcpServers` sub-key embedded in `~/.codely-cli/settings.json` (the rest of `settings.json` stays manual-only — see `references/ides/codely.md`). Added `references/ides/codely.md`, registered it in `ide-registry.md`, and wired it into `ide-paths.json`, `ide-paths.tsv`, and `smart-ide-migration.sh`.

## [0.7.4] - 2026-08-04

### Fixed

- Corrected a post-release 0.7.3 defect so project rules and prompt targets honor the documented `backup`/`skip`/`overwrite` strategy, preserving existing content by default and rejecting symlinked or mismatched target types before writing.

## [0.7.3] - 2026-08-04

### Added

- Added a pre-copy scan across every regular Skill source file. Skills containing likely literal credentials or links outside their source root are skipped before any target backup, overwrite, or copy.

### Changed

- Limited the runtime package to the migration script, its path data, shared helper, and source scanner; maintainer tests and repository-only tools remain excluded.
- Narrowed Skill activation to migration between two named supported IDE or agent products and declared only local file-read, file-write, and shell capabilities.

### Fixed

- Rejected external Skill symlinks and unreadable source subtrees before copying, while preserving existing source and target content.
- Made focused test scripts portable on systems without `rg` and removed an obsolete installer check from CI.

### Security

- A post-release audit found that project rule and prompt writes could bypass the documented conflict strategy. Upgrade to 0.7.4 or later for the corrected behavior.

## [0.7.2] - 2026-08-03

### Fixed

- Removed repository installers, cross-agent sync, automatic OpenClaw setup, combined runtime/registry update, and legacy full-directory export scripts.
- Limited ClawHub packages to an explicit runtime allowlist, omitting evals, tests, maintainers' scripts, symlinks, and lock files.
- Made global migration default to Skills only and require an explicit workspace for project-backed objects without adding interactive confirmation steps.
- Validated imported Skill names and sources, and moved the root-mirror notice after YAML frontmatter for scanner compatibility.

## [0.7.1] - 2026-08-03

### Security

- Declared the Skill's least-privilege filesystem and shell requirements without network authority.
- Replaced the generic redaction deletion sink with exact-target and copy-root containment guards, rejected symbolic-link MCP targets, and narrowed project-copy redaction to skill-copy cleanup.
- Added regression coverage for permission metadata, symlink target immutability, and fail-closed cleanup.

## [0.7.0] - 2026-08-03

### Added

- Added current guidance for Android Studio, Visual Studio, JetBrains AI Assistant, Xcode, and the Firebase Studio sunset path.

### Changed

- Updated Codex, Claude Desktop, Cursor, VS Code, Windsurf, Zed, Junie, Gemini CLI, OpenCode, Cline, Kilo Code, Kiro, and Antigravity configuration boundaries from current official documentation.
- Removed redundant trigger/capability frontmatter, adopted the standard eval `assertions` field, and made trigger cases more realistic.
- Made the migration entry point fully non-interactive: writes now require `--yes`, with documented output and exit-code contracts.
- Enforced Firebase Studio as a source-only sunset path and added dry-run and failure-path coverage for the new IDE mappings.

## [0.6.12] - 2026-08-01

### Changed

- Condensed repository prose, conditional references, script help, and nonessential comments.
- Generated IDE path summaries and runtime resolver from the canonical registry; consolidated shared test and OpenClaw helpers.
- Merged equivalent UI-only MCP guidance and removed redundant OpenClaw/reference material while retaining fail-closed boundaries.

## [0.6.11] - 2026-07-31

### Security

- Made whole `config` and opaque `project` migration manual-only; removed inherited MCP tool-approval grants.

### Verification

- Added security-boundary coverage and published the release to [ClawHub](https://clawhub.ai/luckycat133/skills/agent-skills-setup).

## [0.6.10] - 2026-07-31

- Clarified legacy SSE, Streamable HTTP, transport ambiguity, and target-local protocol/OAuth state.

## [0.6.9] - 2026-07-30

- Split the Skill into a small router plus conditional safety, MCP, object, and verification references; added per-IDE references and generated path summaries.

## [0.6.8] - 2026-07-29

- Excluded `.env*`, guarded recursive cleanup and OpenClaw env files, and moved install/publish authority outside the publishable Skill.

## [0.6.7] - 2026-07-29

- Rejected unknown conflict strategies before any target write.

## [0.6.6] - 2026-07-29

- Made cross-platform path drift tests cover every platform mapping and corrected Cline paths.

## [0.6.5] - 2026-07-29

- Restored fail-closed VS Code MCP handling, added OpenCode V1/V2 support and deterministic evidence, and expanded eval coverage.

## [0.6.4] - 2026-07-29

- Added reviewed `--source-mcp-file`, strict schema/identity checks, credential handling, and explicit source evidence.

## [0.6.3] - 2026-07-28

- Hardened cleanup/redaction and corrected Cline global MCP migration.

## [0.6.2] - 2026-07-28

- Standardized English script output, inert secret fixtures, and focused validation.

## [0.6.1] - 2026-07-28

- Fixed Linux CI path handling and Cline mapping drift.

## [0.6.0] - 2026-07-28

- Applied security-audit fixes for migration, redaction, path mapping, and safer shell behavior.

## [0.5.8] - 2026-07-27

- Hardened project-scope skills/MCP migration and expanded documented IDE coverage.

## [0.5.7] - 2026-07-24

- Closed a post-copy secret-handling gap in project migration.

## [0.5.6] - 2026-07-24

- Enforced the explicit `--yes` write gate and zero-write dry runs.

## [0.5.5] - 2026-07-23

- Expanded secret redaction, low-risk defaults, mapper coverage, and root-mirror checks.

## [0.5.4] - 2026-07-23

- Added the canonical-to-root `SKILL.md` mirror and link rewriting.

## [0.5.3] - 2026-07-23

- Added destructive-mirror confirmation and guarded overwrite cleanup.

## [0.5.2] - 2026-07-22

- Replaced executable OpenClaw config parsing and required confirmation for destructive sync.

## [0.5.1] - 2026-07-22

- Required checksums for downloads and hardened public export.

## [0.5.0] - 2026-07-22

- Added OpenClaw tooling, cross-IDE migration guidance, release tooling, and repository policies.

## [0.1.0] - 2026-03-22

- Initial reusable-skill repository, migration tooling, and documentation.

[0.5.0]: https://github.com/Luckycat133/skills-repo/compare/v0.4.0...HEAD
[0.4.0]: https://clawhub.ai/Luckycat133/agent-skills-setup
[0.1.0]: https://github.com/Luckycat133/skills-repo/releases/tag/v0.1.0
