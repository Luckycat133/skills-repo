# v0.10.1 security verification

Reviewed on 2026-10-03 against a frozen MIT-0 runtime candidate, unpublished at
the time of review. This records local candidate verification before final
release CI, including the correction and original scanner verdict. Three-platform
CI had not run at this snapshot; see the [v0.10.1 GitHub Release](https://github.com/Luckycat133/skills-repo/releases/tag/v0.10.1)
for the actual release CI results.

## Correction and regressions

Failed key generation previously cleaned up a created output by pathname. A
concurrent local replacement could therefore be removed when creating the second
output failed. The correction keeps both original creation descriptors open
through writing, fsync and output checks, and removes pathname-based cleanup.

POSIX failed outputs are retained with owner-private creation permissions and
reported in `outputs_requiring_review`. Check current contents and ownership
before manual cleanup: a listed path may now refer to a replacement. Windows
retains CREATE_NEW/share-mode-0 ownership and deletes through the original held
handle only. Original errors stay primary; cleanup/close failures are separate
diagnostics. Failed opens do not claim existing files. Generation is not atomic
pair publication; do not use a failed keypair.

The changed [caller](../../../skills/agent-skills-setup/scripts/context-migrator.py)
and [helper](../../../skills/agent-skills-setup/scripts/acb/key_security.py) were
reviewed against the fixed payload. All **16 runtime artifacts** match the review
snapshot's bytes/modes; the other 14 retain their previous bytes/modes and review
evidence.

| Executed checks | Evidence and boundary |
| --- | --- |
| [Transaction regression](../../../skills/agent-skills-setup/scripts/test-keygen-transaction.sh) | 11 checks passed on macOS with real Ed25519 generation: collisions/replacements, short writes, no progress, write/cleanup/close errors, descriptor release and identity checks. |
| Independent caller fault injection | 8 cases passed, including partial writes, fsync failure, combined secondary errors and two replacement paths forbidding pathname unlink. |
| Independent creation-stage fault injection | 8 cases passed for guard/cleanup/close errors, CRT transfer, non-inheritance and failed-open ownership. WinAPI/CRT control flow is simulated with temporary files/FDs; native Windows remains unverified. |

The release task separately recorded **69 local suites passed**. Close-error
fixtures close their FD before reporting an error; they do not prove release on
every OS close failure. Production attempts each close once, avoiding reuse races.
Tests use isolated synthetic keys and do not emit key values.

## Payload and raw scan

The **120-file** manifest matches paths, sizes, SHA-256 digests and modes before
and after scanning. Its tree digest hashes path-sorted `path`/`sha256`/`size`/`mode`
rows as compact JSON with sorted keys; it is not a Git tree or registry fingerprint.

| Evidence | SHA-256 |
| --- | --- |
| Candidate manifest tree | `287716fb68180576410d5b52b544829a975e5e3f59bf2393ab2faf58008b8240` |
| Raw candidate scan JSON | `6068298333a094e371f170a8b063dff9f1dc72b6f439f4ff6b5643f1490ee490` |

Official NVIDIA/SkillSpector **2.12.0**, revision
`2226747e4ca97198bb82faf5085b8a75f2e1dc02`, ran **once** in isolation with
`--no-llm`. No baseline or suppression was applied. LLM/meta analysis were disabled;
inference usage was empty.

| Original scanner result | Value |
| --- | --- |
| Findings | **101: 68 HIGH, 30 MEDIUM, 3 LOW** |
| Risk / severity / recommendation | **100 / CRITICAL / DO_NOT_INSTALL** |
| CLI exit / execution | **1** / successful execution, incomplete analysis |
| Text components / coverage | **115 full, 4 partial, 0 uninspected** of 119 / 96.6% |
| Degraded static analyzers / suppressed findings | **13 / 0** |

All 101 rows have individual review entries. Rule/file/pattern/matched-content
multisets pair all **100 prior findings** one-to-one: none removed, no severity
or semantic-message changes, six location shifts. The one new EA2 MEDIUM row
matches `without checking` in `never delete a listed path without checking` in
the failure-recovery guidance. Review identifies a negation-context match that
restricts deletion. Its original active rating remains; review does not replace
the scanner's CRITICAL recommendation or establish a clean scan.

## Remaining coverage

Four components under `scripts/` remain partial: `acb/key_security.py`
(obfuscated-instruction limit across 13 analyzers), `detect/probes.py` and
`skill_secret_scanner.py` (tool-misuse parser spans), and
`legacy-smart-ide-migration.sh` (obfuscation/parser spans). The entire helper
and caller diff were reviewed; unchanged probe/secret-scanner reviews carry
forward by digest. Legacy guards, matched cleanup and redaction were checked;
dormant writers were not exhaustively audited. No triggering spans were supplied.

The old legacy supply-chain runtime limit did not recur, but identical legacy
bytes still have partial coverage. Linking the concrete profile index removed
the directory-placeholder exception; all 14 actual root Markdown destinations
resolve to files. A version-label reference exception remains. The demo GIF is
excluded from static text analysis. Raw limitations remain unchanged by review.

This local candidate review preceded final release CI. It did not execute the
changed candidate on native Windows or establish native IDE/MCP/network
acceptance, host sandbox policy, binary safety or exhaustive filesystem
concurrency. See the [v0.10.1 GitHub Release](https://github.com/Luckycat133/skills-repo/releases/tag/v0.10.1)
for the actual release CI results; the local WinAPI simulations above are separate
evidence. Raw reports, the 101-row matching table, artifact binding and
fault-injection evidence are retained outside the repository; this public record
contains no machine-specific paths or key material.
