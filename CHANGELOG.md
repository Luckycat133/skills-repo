# Changelog

All notable changes to this repository are documented in this file.
This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] (0.11.0-dev)

Metadata remains `0.11.0-dev` (unreleased candidate; not a published `0.11.0` release).

### Added

- Add rule/MCP worked conversions, all-context inventory, conflict/scope guidance,
  authored-memory distinctions, and plain-folder device transfer to the guidance-only Skill.
- Add 30 on-demand family references routing all 87 historical product identifiers
  (90 profile/category sections) alongside the 2026-11-07 research ledger and a
  repository-only development Skill (`dev/skills/maintain-agent-skills-setup/`).
- Add two on-demand Markdown references to the user package without adding any runtime or
  dependency: native CLI guidance (`references/cli-workflow.md`) and historical Registry v2
  interpretation rules (`references/registry-v2.md`).
- Add per-object delivery outcomes, explicit separation of syntax/discovery/activation/runtime
  verification levels, preview zero-artifact rules, concurrent-edit checks, private recovery
  handling, and checkout/version provenance requirements for local validation reports.
- Add 10 pending host-agent workflow scenarios (`evals/workflow-cases.json`) and 10
  structural/rubric contract checks (`tests/test_workflow_contract.py`); these remain
  unrun behavior scenarios rather than native-client passes.

### Changed

- Replace the standalone migration engine with an agent-first, guidance-only Skill
  (`skills/agent-skills-setup/`) executed through host-agent tools.
- Separate structural/package checks (`validate-all.sh`) from real host-agent and
  native-IDE behavior evaluation; retain older unverified validation logs as user-reported
  until checkout revision and evidence are attached.

### Fixed

- Detect an available Python 3.11+ interpreter or `uv` automatically in `validate-all.sh`
  so `tomllib`-dependent structural tests run cleanly when the default `python3` is older.

### Removed

- Remove runtime CLI, ACB/signing orchestration, and generated compatibility claims from the
  active user package; the full former implementation remains preserved in Git history.

## [0.10.3] - 2026-11-11

Pre-reset maintenance on the `0.10.x` line prior to the `0.11.0-dev` agent-first scope reset.

### Fixed

- Persist recovery journals before migration or Skill installation replaces directories,
  retaining complete old trees across the rename gap and enforcing conservative recovery
  for interrupted installs (`#28`).
- Bind migration plans, verification, and rollback guards to file/directory modes
  separately from unchanged content hashes so mode-only target or backup drift is detected (`#28`).
- Refresh 16 stale/broken vendor documentation URLs (19 failing source links) in the
  product catalog freshness checks.

### Docs

- Add `llms.txt` and `llms-full.txt` aligned with the `llmstxt.org` specification, plus a
  generative-engine FAQ section in `README.md` (`#32`, `#33`).

### Changed

- Bump GitHub Actions workflow dependencies and `actions/setup-python` (`#21`, `#30`).

Earlier release history (`<= 0.10.2`) is preserved untouched in
[the historical changelog](docs/history/CHANGELOG-before-agent-first.md).
