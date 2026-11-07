# Remaining work after the 2026-11-07 reset

Baseline inspected: `880c5f58d310f5964963c88e685e0530a60e1757` (canonical 0.10.2).
This file records what still needs access/evidence. It is not a proposal to rebuild
ACB or a multi-IDE automation platform.

## R1 — Actual agent and IDE evaluation (release blocker)

Status: NOT RUN. This editing environment has no authenticated local Cursor,
Claude Code, Codex, VS Code or Gemini session and cannot observe their UI loading.
Run the cases in root `evals/` using two real agent clients, first in fixture roots,
then verify target discovery. Record model/client versions and tool traces without
private data. Fix guidance when a case fails; do not add an engine as a shortcut.
Acceptance: scenario evidence in `docs/validation-status.md`, including failures,
positive/negative scopes, no target writes on preview, and no secret execution.

## R2 — Reverify the historical product catalogue

Status: NOT COMPLETED. The old `docs/history/profile-notes/` and registry snapshot
are retained only as leads, not shipped or declared supported. Work one requested
product/profile at a time. Locate current official source, inspect all context
families and host-specific scope/precedence, add a small source-backed recipe and
one fixture. Never turn all old rows into a generated green matrix.
Acceptance: evidence URL/date, actual tested version or clearly marked docs-only,
and per-surface migration decision. No unverified path becomes a default target.

## R3 — Native Windows and remote hosts

Status: NOT RUN on native hosts. Validate USERPROFILE/APPDATA, case collisions,
symlinks/junctions, WSL/remote extension host roots and workspace remapping using
the host agent's file tools. Linux fixture tests must not count as Windows evidence.
Acceptance: a reviewed cross-device fixture with exact destination discovery,
no old absolute paths, preserved context and unchanged unrelated settings.

## R4 — Skill retrieval/trigger evaluation

Status: RUBRIC ONLY. Test the installed package with Chinese and English natural
requests: direct migration, scoped preview, export without a target, device restore,
unknown IDE and irrelevant conversation. Verify relevant reference loading rather
than the entire package. No duplicate approval questions after explicit scoped
consent. Acceptance: observed traces and false-positive/false-negative results.

## R5 — Marketplace replacement and user transition

Status: NOT PUBLISHED. GitHub changes do not update ClawHub or installed copies.
After R1, stage only the canonical Skill, inspect the exact file list, check the
current marketplace license/metadata rules and prior MIT-0 authorization, then
publish only with owner approval. Verify the downloaded package, not only source.
No automatic marketplace authentication, license reassignment, tag, or release.
Warn existing users that the old CLI is retired and preserve their old backups.

## R6 — New recipes only when demand/evidence exists

Commands, agents, hooks and memory now have a migration procedure but not every
vendor's native template. Add concrete examples for actual user requests; retain
unsupported fields and do not activate executable drafts. A tiny parser helper is
permitted only after repeated fixture evidence and explicit scope review.

## Not backlog

Do not add a daemon, cloud sync, signing service, proprietary bundle protocol,
enterprise dashboard, paid control plane, automatic app installation, product-count
marketing, or repository-star prompts inside the runtime Skill. Those were scope
creep, not missing acceptance criteria.
