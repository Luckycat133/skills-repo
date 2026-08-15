# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
