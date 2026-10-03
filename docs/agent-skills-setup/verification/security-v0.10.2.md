# v0.10.2 local candidate security review

This records a local MIT-0 candidate review before final release CI. It does
not claim publication or a new registry verdict. Final native CI and publication
results must be recorded separately when available.

The 120-file package matches its frozen manifest by path, SHA256, size and mode
before and after scanning. All 16 runtime artifacts are bound to the reviewed
source. Against v0.10.1, 117 files are byte/mode identical; changes are limited
to the version, CLI-workflow guidance and the legacy engine's help/footer.

Package tree SHA256:
`f968b7a59ff9e5a4ee7c0969bf35ab652a98897376108d1fb8e9c9ffb77ef16e`.
The tree hashes path-sorted manifest rows serialized as compact JSON with sorted
keys, including each file's path, SHA256, size and mode.

## Official raw scan

Exactly one NVIDIA/SkillSpector 2.12.0 scan ran from clean pinned source revision
`2226747e4ca97198bb82faf5085b8a75f2e1dc02`, using
`scan <staged-runtime-directory> --no-llm --format json`.
No baseline, suppression or inference was requested.

| Raw measure | Result |
|---|---|
| Findings | 101: 68 HIGH, 30 MEDIUM, 3 LOW |
| Risk / severity / recommendation | 100 / CRITICAL / DO_NOT_INSTALL |
| CLI exit / suppressed findings | 1 / 0 |
| Text components | 115 full, 4 partial, 0 entirely uninspected, of 119 |
| Coverage / degraded static analyzers | 96.6% / 13 |
| LLM / meta analysis / inference | Disabled / disabled / none |

Execution succeeded; analysis remains incomplete. Review retains every original
rating and the warning-bearing recommendation. The GIF is outside static text
coverage. Raw report SHA256:
`5980401f56dd3fe9de318bc330d586b775b4a75438fe98349b81f863700bc858`.

All 101 v0.10.1 findings pair one-to-one by rule, relative file, pattern and
matched content, with duplicate locations preserved. Every raw issue field
except report-local finding IDs is unchanged. There are no added, removed,
location-shifted or semantically changed findings. Prior scoped review carries
forward only for unchanged contexts; the changed footer was reviewed separately.
Reviewer interpretations do not replace the official raw verdict.

## Correction and regression scope

The shared legacy footer now honors dry-run for an explicit `--report` path:
preview reports remain on stdout without creating or overwriting that file.
The notice uses stderr, preserving JSON stdout. Lookup still exits before the
footer, and authorized internal non-dry-run report saving is retained.
The correction is supported by control-path review and matching behavioral
checks, not by a reduction in deterministic warning counts.

Local macOS validation passed 69 unique suites with zero skips, including
12 public-entry regressions. An independent reviewer passed 32 actual macOS
calls covering prior failures, source-asset preservation, truly absent Python
on PATH, JSON output and explicit internal report saving. These checks were
executed separately from the scan.

## Analysis limits

Partial files remain `scripts/acb/key_security.py` (obfuscation),
`scripts/detect/probes.py` and `scripts/skill_secret_scanner.py` (parser bounds),
and `scripts/legacy-smart-ide-migration.sh` (obfuscation, parser bounds and a
supply-chain runtime limit). The runtime-limit entry reappeared in this run and
is retained without retry. The version-label reference exception remains;
all 14 actual local root Markdown targets exist. Manual inspection does not
complete the affected analyzers, and dormant legacy writers were not exhaustively
audited.

This pre-CI snapshot does not establish native Windows or three-platform
v0.10.2 acceptance, a new platform security result, native IDE/MCP/network
behavior, effective sandboxing, model eval or binary safety. Prior WinAPI
simulations remain simulations. The no-Python Skill secret preflight limitation
is unchanged. File end-state checks do not prove absence of transient private
status-file writes. Final release evidence must retain these boundaries and
report native CI results separately.
