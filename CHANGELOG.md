# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.3] - 2026-08-04

### Added

- Added a pre-copy scan across every regular Skill source file. Skills containing likely literal credentials or links outside their source root are skipped before any target backup, overwrite, or copy.

### Changed

- Limited the runtime package to the migration script, its path data, shared helper, and source scanner; maintainer tests and repository-only tools remain excluded.
- Narrowed Skill activation to migration between two named supported IDE or agent products and declared only local file-read, file-write, and shell capabilities.

### Fixed

- Rejected external Skill symlinks and unreadable source subtrees before copying, while preserving existing source and target content.
- Made focused test scripts portable on systems without `rg` and removed an obsolete installer check from CI.

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
