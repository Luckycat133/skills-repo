# v0.10.0 security verification

Reviewed on 2026-10-03 using the published ClawHub MIT-0 runtime and preserved
release evidence. This records finding review and its limits; it is not a
complete security audit or a finding suppression baseline.

## Artifact and report identity

The published source is commit
`12d56c84407ff91847b0c9afe1c970f90818a102`, tree
`e8a433b70b98faa8cf8baa018800b99f45a519a9`. ClawHub's 120 source-file paths,
sizes and SHA-256 digests match the prepared package and local scan input.
All 120 local files also match that scan input's modes; the 16 runtime files
match the published source's bytes and modes. The registry fingerprint covers
paths and content digests, not executable permissions or sandbox enforcement.

The official CLI's pure local hashing helper independently reproduces:

```text
ccf408776355aaf8cdca6a5124916caa07738d5892cde9742ce3f758eb65ac8d
```

ClawHub verification returns `ok=true`, `decision=pass`, no reasons, a generated
card, and security `clean` / `benign` / `high`. Its embedded SkillSpector report
retains the warning results below. Provenance is unavailable and the registry
envelope is unsigned; neither establishes an independently authenticated signer.

| Preserved report | ClawHub | Local runtime |
| --- | --- | --- |
| SkillSpector version | 2.11.2 | 2.12.0 |
| LLM / meta analysis | Requested and applied; 401 inference records | Disabled with `--no-llm` |
| Findings | 112: 72 HIGH, 32 MEDIUM, 8 LOW | 100: 68 HIGH, 29 MEDIUM, 3 LOW |
| Raw risk / severity / recommendation | 100 / CRITICAL / DO_NOT_INSTALL | 100 / CRITICAL / DO_NOT_INSTALL |
| Completeness | 116 full, 3 partial, 97.5% | 115 full, 4 partial, 96.6% |
| Execution | Successful; incomplete | Successful; incomplete; CLI exit 1 |
| Suppressed findings | 0 | 0 |

The local raw scan is from source commit
`3025996de14970eb27e9ee21b1337e8c9021a380`, at NVIDIA/SkillSpector revision
`2226747e4ca97198bb82faf5085b8a75f2e1dc02`. Exact payload binding connects that
scan to v0.10.0; it is not relabeled as a scan of the later source commit.

## Finding comparison

All 112 platform rows were reviewed individually. Matching uses rule, relative
file, start line and occurrence count, then checks severity, category,
confidence, explanation and remediation against the bound local report.
Finding IDs are report-local. The platform omits columns and some snippets or
fingerprints, so two tokens on the same line cannot be distinguished there.

- 98 rows match with identical severity and semantic messages. Their earlier
  per-finding review carries forward after file digest/mode verification. The
  platform adds `llm-unconfirmed` to each; this does not downgrade the finding.
- 14 platform-only rows require additional contextual review, summarized below.
- Two extra local rows share already represented rule/file/line anchors:
  AS1 in `references/ides/antigravity.md:24` and RA2 in
  `scripts/detect/probes.py:179`. They remain in the local raw report.

| Platform-only warnings | Review basis and remaining concern |
| --- | --- |
| 5 TP4 HIGH: signing keys, probes, alias resolver, typed exceptions, secret scanner | These modules support CLI migration, detection, signing and secret preflight. A supporting module need not independently implement every capability in the root description. No hidden operational feature was established by these messages. |
| 2 SDI-1 MEDIUM: plugin preparation and plugin/handoff writers | The short description lists the three core objects; the body explicitly names opt-in plugins and whitelisted handoff. Writers refuse missing opt-ins. The description can name these additional objects more precisely; the original advisories remain. |
| 2 SQP-2 MEDIUM: Jules reference and rollback | Jules is a documented cloud/manual profile, not a skill upload implementation. Public rollback checks `--yes` before its core writer; target and backup validation precedes deletion. Caller authorization and recovery are documented. |
| 2 SQP-2 LOW: apply examples and signing-key helper | Root permissions, migration safety and signing guidance disclose named writes. `--yes` records existing authorization. Function-local prompts are not the caller's authorization boundary; transaction error-path safety is examined separately. |
| 3 SQP-3 LOW: CN product/profile entries | Explicit selectors resolve `trae` to `trae/ide`, `trae-cn` to `trae/cn-ide`, `qoder` to `qoder/cli`, and `qoder-cn` to `qoder/cn-ide`. These are selected profile routes, not forced response language or silent locale changes. |

The shared warnings cover selected agent-path access, generated comments,
credential-exclusion/manual-review text, temporary cleanup, local subprocesses,
public path tables, approval-field removal, private-key permission refusal,
fixed WinAPI bindings and opt-in attribute access. Each retains its original
severity. LP3 remains a declaration advisory: the ClawHub header contains
OpenClaw binary requirements, while the Permissions body describes local
capabilities and denies network access. Prose declarations do not enforce host
permissions.

## Coverage limits and manual review

Both reports mark 13 static analyzers degraded. Their reported totals concern
119 text components; `assets/demo.gif` is excluded from static text inspection.
Successful scanner execution does not make these analyzers complete.

| Component | Raw limitation | Manual scope |
| --- | --- | --- |
| `references/ides/cursor.md` | Platform: tool-misuse parse-span limit | Entire 21-line reference: paths, environment placeholder and manual hooks/plugins guidance; no executed tool program. |
| `scripts/acb/key_security.py` | Both: obfuscated-instruction limitation across 13 analyzers | Entire frozen helper and integrations: DLL/ABI/buffer ownership, private ACLs, exclusive creation, regular-file checks, bounded reads and handle cleanup. The scanner gives no triggering span; its limitation remains. |
| `scripts/legacy-smart-ide-migration.sh` | Both: obfuscation and tool-misuse parse limit; local also has supply-chain runtime limit | Entry/write guards, dry-run authorization, matched cleanup, redaction and execution/network primitive search. Dormant legacy writers were not exhaustively reviewed line by line. |
| `scripts/detect/probes.py` | Local: tool-misuse parse-span limit | Entire module: local probes, fixed argv with `shell=False`, two-second bounds, bundle-ID validation and plist comparison. Platform completion does not erase the local gap. |
| `scripts/skill_secret_scanner.py` | Local: tool-misuse parse-span limit | Entire module: AST parsing without evaluation, reason/path-only reporting, symlink restrictions and unreadable-input refusal. |

Platform reference-resolution exceptions cover 11 ledger entries; local has
two. Actual root Markdown destinations, including the profile-reference
directory, exist. Version labels and slash-delimited prose are not missing
executable artifacts. The original unresolved-reference ledger is preserved.

This review does not attest binary safety, all dormant legacy branches,
every concurrent filesystem change, native product discovery, network behavior,
authentication, or effective host sandbox policy. Follow-up transaction
failure-interleaving checks require their own closeout before broader acceptance.

## Checks and retained evidence

Independent isolated checks passed for rollback without `--yes` retaining
sentinel files, explicit CN/international selector routing, and all root
Markdown destinations. The comparison asserts 112 reviewed rows, 98 semantic
matches and exact 120-file payload binding. No new scan request, runtime edit,
policy rewrite, finding suppression or risk baseline was used for this review.

Full raw reports, a 112-row CSV/JSON matching table, partial-component review,
artifact manifest and isolated checks are retained outside the repository.
Snapshot SHA-256 digests:

| Evidence | SHA-256 |
| --- | --- |
| Platform verification JSON | `ba8c826a42cb518958a79f106db56efe5addada61f5c5e18aa4c5eb1c1b85ebc` |
| Local MIT-0 runtime JSON | `79e822623db8b6506b49e8704ccb73eb0043327bc00f988b0ec30772eeb9bfd6` |

Useful follow-up regressions cover key-pair creation collisions/replacements,
rollback target or backup drift, plugin/session opt-in refusals, indirect MCP
targets, and probe/scanner parser boundaries. Run native Windows ACL/handle
tests on Windows; POSIX tests cannot substitute for them. Recheck an immutable
changed runtime with the fixed scanner revision after a behavioral fix.
