# Code Review — `skills/` directory (pending diff)

**Branch:** `main` (working tree, 26 files / +435 / −123)
**Scope:** Entire `skills/` directory at deep/adversarial depth
**Methodology:** Discovery (3 explore + 1 plan) → Adversarial verification (5 reproduction agents) → Surface-area finders (3) → Synthesis
**Date:** 2026-07-27

---

## Summary

This PR introduces a new `--scope {global|project|both}` selector and project-scope skill/MCP migration paths to `smart-ide-migration.sh` (the core engine that distributes AI assistant capabilities across 40+ IDEs). The intent is sound — explicit scope selection closes a long-standing gap — but the implementation ships with **at least four confirmed 🔴 blockers** plus **eight failing tests** and **a broken CI pipeline**.

The most serious findings, all reproduced in live fixtures:

1. **Project skill copy at `smart-ide-migration.sh:1365` calls plain `cp -R`** instead of the existing `redact_project_copy` used by global skills. A live fixture with `api_key="sk-test-12345"` in `scripts/check.sh` showed the secret copied verbatim to the destination.
2. **No source==target guard** for project skills. antigravity/codex/zed all resolve to `.agents/skills`. Running `--source antigravity --target codex --scope project --strategy backup` in a fixture **destroyed** the source directory (`test-skill/` was renamed to `.bak.<ts>` before the copy failed).
3. **Same hazard for project MCP.** Claude/Copilot/tencent-codebuddy all map to `.mcp.json`; Trae/Trae-CN to `.trae/mcp.json`. Overwrite strategy permanently `rm -f`'d the source file before conversion. Backup strategy preserved a `.bak` but rewrote the live file in place.
4. **CI is broken.** `validate-all.sh` exits 1 because `test-ide-paths.sh` fails on the new `cursor/project_mcp` resolver path. Plus 8 of 17 tests fail in the working tree.

Two blockers come from partial fixes: the global-skills path was made fail-closed in commit `7cb8cfc` but the new project-skills path reuses the same vulnerable `cp -R` pattern. The `--scope` flag was added to the parser but the dispatcher doesn't gate a long-standing unconditional `vscode` workspace override, so `--scope global` writes the workspace path.

There are several non-blocking issues worth raising (47 Chinese strings remaining in production scripts — including security-critical redaction messages; `verify-ide-config.sh` is a tautology check; multiple registry drift items; pre-existing test discipline inconsistency). The diff also has genuine praise points — the cursor `project_mcp` JSON addition, the typo + URL fixes in `ide-registry.md`, the coordinated `~/.gemini/config/skills` path fix across `openclaw.md` + `update-openclaw-skills.sh`, and a new fail-closed regression test (MED-T3).

The blockers are concrete and reproducible. **This PR must not merge as-is.**

---

## Strengths

- 🎉 **`cursor` JSON `project_mcp` addition is correct.** The new key matches what the script's resolver emits and what `ide-registry.md` already narratively described.
- 🎉 **Coordinated `~/.gemini/config/skills` path flip.** `references/openclaw.md` (lines 64, 78, 232), `update-openclaw-skills.sh:5`, and `ide-registry.md` all now agree.
- 🎉 **`ide-registry.md` narrative corrections.** Antigravity skills typo fix ("remains supported.."), Trae CN Memory URL fix (`ide/memories` → `ide_memories`), Kiro CLI vs IDE agents split, Kimi agents YAML→Markdown update, CodeBuddy CLI vs IDE split, WorkBuddy memory entry, ZCode user-only agents restriction. Real documentation hygiene work.
- 🎉 **`test-mcp-secret-redaction.sh` MED-T3 case (lines 552–574)** is a well-designed regression guard for malformed-JSON source preservation. Two-sided assertions (content unchanged AND exit code numeric) cover both fail-open-safe and hang prevention.
- 🎉 **README path consistency** across all 4 locales (`README.md`, `README.es.md`, `README.ja-JP.md`, `README.zh-CN.md`) — single coordinated change.
- 🎉 **Root `SKILL.md` mirror** is in sync with canonical (`bash scripts/sync-root-mirror.sh --check` passes).
- 🎉 **`test-vscode-mapping.sh` new blocks** (4 new test cases for project-skills, project-mcp, manual objects, invalid scope) are well-structured: deterministic fixtures, positive and negative assertions, proper failure messages.

---

## Required Changes (🔴 blocking)

### 🔴 BLOCKING #1 — Project skill copy leaks secrets (security)

**File:** `skills/agent-skills-setup/scripts/smart-ide-migration.sh`
**Line:** 1365 (in `migrate_project_skills`)

```bash
if cp -R "$skill_dir" "$target_path/$skill_name" 2>/dev/null; then
    echo "  [OK] 迁移项目技能: $skill_name"
```

**Problem:** Global skills (`migrate_global_skills`) wrap every successful `cp -r` in `if redact_project_copy ... else rm -rf ... fi` (fail-closed). The new `migrate_project_skills` uses plain `cp -R` with no redaction.

**Live reproduction:** Created `/tmp/review-v1/.cursor/skills/myskill/scripts/check.sh` containing `api_key="sk-test-12345"`. Ran `bash smart-ide-migration.sh --source cursor --target antigravity --objects skills --scope project --yes`. The destination `/tmp/review-v1/.agents/skills/myskill/scripts/check.sh` contained the literal `sk-test-12345` string.

**Suggested fix:** Mirror the global pattern. After successful `cp -R`, call `redact_project_copy "$target_path/$skill_name"`, and `rm -rf` if redaction fails.

**Confidence:** HIGH (reproduced in fixture; agent verdict CONFIRMED).

---

### 🔴 BLOCKING #2 — Project skill migration destroys source when target==source (data loss)

**File:** `skills/agent-skills-setup/scripts/smart-ide-migration.sh`
**Lines:** 1344–1363 (in `migrate_project_skills`)

**Problem:** No `realpath`/`readlink` guard before the strategy switch. Multiple IDEs share project-skill paths:

- antigravity, codex, zed → all `.agents/skills`

For `backup` strategy (lines 1350–1354):
```bash
mv "$target_path/$skill_name" "$target_path/$skill_name.bak.$timestamp"
```
The source is renamed to a backup name **in the same directory**. The subsequent `cp -R` fails because the source no longer exists at the original path.

For `overwrite` strategy (lines 1355–1361):
```bash
safe_remove_skill_dir "$target_path" "$skill_name"
```
The source is permanently `rm -rf`'d with no backup.

The top-level same-IDE guard at line 4534 only catches literal `--source X --target X`, not same-path-different-IDE.

**Live reproduction:** Created `/tmp/review-v2/WORKSPACE/.agents/skills/test-skill/{SKILL.md, SENTINEL.txt with 'BEFORE_BACKUP'}`. Ran `--source antigravity --target codex --objects skills --scope project --strategy backup --workspace /tmp/review-v2/WORKSPACE --yes`. AFTER: `test-skill/` is **gone**; only `test-skill.bak.20260727231107.40333/` remains. The live `SKILL.md` directory was destroyed; only the `.bak` survives.

**Suggested fix:** Before the strategy switch, canonicalize both paths with `realpath -m --` and abort if equal. Same fix is needed for `migrate_mcp`'s project-scope path.

**Confidence:** HIGH (reproduced in fixture; agent verdict CONFIRMED).

---

### 🔴 BLOCKING #3 — Project MCP migration destroys source when target==source (data loss)

**File:** `skills/agent-skills-setup/scripts/smart-ide-migration.sh`
**Lines:** 3491–3512 (in `migrate_mcp`)

**Problem:** Same shape as #2, but for MCP. Conflicting project-MCP paths:

- claude, copilot, tencent-codebuddy → all `.mcp.json`
- trae, trae-cn → both `.trae/mcp.json`

For `overwrite`: `rm -f "$target_mcp"` (line 3507) deletes the only copy when target==source.
For `backup`: `cp -r ...bak` saves a copy, but `convert_mcp_file` then **writes to and redacts the live source path** (the backup holds the original; the live file is overwritten).

**Live reproduction:** Seeded `/tmp/review-v3/WORKSPACE2/.mcp.json` with valid MCP fixture. Ran `bash smart-ide-migration.sh --source claude --target copilot --objects mcp --scope project --strategy overwrite --yes`. Hooked `/bin/rm` via PATH shim; `rm.log` recorded `rm -f /tmp/review-v3/WORKSPACE2/.mcp.json`. Final state: `.mcp.json` permanently deleted; report logs `[X] mcp: 源MCP配置不可读`; conversion failed.

**Suggested fix:** Same realpath guard as #2. Additionally, the `backup` strategy for MCP should write to a sibling tmp path and `mv` into place, not overwrite in place.

**Confidence:** HIGH (reproduced in fixture; agent verdict CONFIRMED).

---

### 🔴 BLOCKING #4 — CI is broken; 8/17 tests fail

**Files:** multiple test scripts + `validate-all.sh` + `.github/workflows/validate.yml`

**Phase 0 result:** 9 passed, 8 failed.

| Test | Exit | Cause |
|------|------|-------|
| `test-codex-migration.sh` | 1 | `grep -Fq '需手动迁移'` (Chinese) fails; script now emits English `manual migration required`. Two assertions fail silently under `set -e`. |
| `test-copilot-mapping.sh` | 1 | `grep -Fq 'MCP配置迁移失败'` (Chinese) fails; script now emits `MCP config migration failed`. |
| `test-cursor-mapping.sh` | 1 | Python dict assertion missing new `project_mcp` key. **Exact-dict comparison** fails. |
| `test-ide-paths.sh` | 1 | 1/446 drift check FAILs: `cursor/project_mcp` resolver exits non-zero. **This blocks `validate-all.sh` (exit 1), which blocks CI.** |
| `test-mcp-secret-redaction.sh` | 1 | 1/70: case 4 grep on Chinese string fails; script emits English. |
| `test-migration.sh` | 1 | 1/80: `grep -Fq '转换MCP配置'` fails; script emits English. |
| `test-remaining-ide-mappings.sh` | 1 | Silent failure: `grep -Fq` on Chinese `Void: .voidrules 是规则文件...`; script emits English. |
| `test-smart-ide-migration.sh` | 1 | Silent failure on first assertion; most/all subsequent Chinese-literal grep assertions will fail for the same i18n reason. |

**Three tests fail silently** (no stdout/stderr) because of `grep -Fq <Chinese>` under `set -e`. This is a separate test-discipline issue — `set -euo pipefail` on test scripts that accumulate silently-degrading assertions makes failures invisible.

**The CI blocker:** `validate-all.sh` is invoked by `.github/workflows/validate.yml:18`. `validate-all.sh` exits 1 because `test-ide-paths.sh` fails on `cursor/project_mcp`. **This PR cannot merge as-is.**

**Suggested fix:** Two paths, pick one:

(a) **Fix the resolver.** The cursor/project_mcp entry was added to `ide-paths.json` but the script's `--print-path cursor project-mcp` exits non-zero (per `test-ide-paths.sh` output). Likely a missing case in `get_project_mcp_path` or the `--print-path` dispatch. Inspect the test failure tail: `cursor/project_mcp - script exited non-zero resolving object project-mcp`.

(b) **Restore Chinese or finish the translation.** All 8 failing tests expect Chinese strings; the diff translates tests selectively but not the production scripts. The cleanest fix is one of:
- Revert the test translations and emit Chinese from production (no functional change, but loses the i18n goal).
- Translate the production scripts (see Suggestion #1 below) and confirm all tests pass.

Plus **fix `test-cursor-mapping.sh`** to include `project_mcp` in its expected dict.

**Confidence:** HIGH (verified by running all 17 tests).

---

### 🔴 BLOCKING #5 — Void project MCP uses wrong root key (correctness)

**File:** `skills/agent-skills-setup/scripts/smart-ide-migration.sh`
**Line:** 397 (`get_project_mcp_path void-editor`) and lines 732–733 (`get_mcp_root_key void-editor`)

```bash
# Line 397
void-editor) echo ".vscode/mcp.json" ;;

# Lines 732-733
claude|cursor|...|void-editor|...|jetbrains) echo "mcpServers" ;;

# Line 741
vscode) echo "servers" ;;
```

**Problem:** `get_project_mcp_path void-editor` returns `.vscode/mcp.json` (inherited VS Code workspace path), but `get_mcp_root_key void-editor` returns `mcpServers` (the Void-global convention, not the VS Code convention). VS Code's `.vscode/mcp.json` uses root key `servers` — confirmed in `ide-registry.md:370`.

**Caveat:** This combo is only triggered via `--print-path void-editor project-mcp`. The `migrate_mcp` flow doesn't currently invoke it for project scope (it uses `get_mcp_path` for user-scope MCP). But the inconsistency is real and will bite when project-scope MCP for Void is wired up.

**Suggested fix:** Add a scope-aware branch in `get_mcp_root_key`: if scope==project and IDE is `void-editor`, return `servers`. Or treat `void-editor` project MCP as aliasing the vscode resolver entirely.

**Confidence:** HIGH (consistent across JSON/registry/resolver; agent verdict CONFIRMED).

---

### 🔴 BLOCKING #6 — `vscode` workspace MCP override is unconditional (regression risk with `--scope`)

**File:** `skills/agent-skills-setup/scripts/smart-ide-migration.sh`
**Lines:** 3250–3251 (in `migrate_mcp`)

```bash
if [[ "$target_ide" == "vscode" ]]; then
    target_mcp="$WORKSPACE_ROOT/.vscode/mcp.json"
fi
```

**Problem:** With the new `--scope global` flag, a global MCP migration to vscode will still write to the workspace path (the override is unconditional). This is the existing pre-diff behavior, but the new scope selector makes the mismatch visible: `--scope global` to vscode should write to the user-global MCP path, not the workspace path.

**Note:** Reviewer (V4) initially refuted this finding because `--scope` was not present in the parser they examined — but `--scope` IS in the working tree (verified by V1 successfully running `--scope project`). The peer's claim was about behavior under `--scope=global`, which has not yet been independently reproduced but is logically consistent with the unconditional override.

**Suggested fix:** Gate the override on `scope == project`:
```bash
if [[ "$target_ide" == "vscode" && "$scope" == "project" ]]; then
    target_mcp="$WORKSPACE_ROOT/.vscode/mcp.json"
fi
```

**Confidence:** MEDIUM (logically consistent; live reproduction under `--scope global` was not attempted in the verification phase because the override lives at 3250–3251, not the 3394–3395 the peer cited — see "Verifier discrepancy" below).

---

## Suggestions (🟡 important + 💡)

### 🟡 IMPORTANT #1 — Translation is selective, not systemic

The diff translates test scripts from Chinese to English but leaves ~47 Chinese strings in production scripts (per F2 scan). Highlights:

**Security-critical strings (still Chinese):**
- `smart-ide-migration.sh:3045-3065` — `[SECURITY]` redaction engine error messages
- `smart-ide-migration.sh:4312-4320` — `SECURITY: 本次迁移包含 mcp/config/project` warning
- `auto-configure-openclaw-skills.sh:248` — WARNING about `--env` secret-leak
- `auto-configure-openclaw-skills.sh:353-374` — die() guards for external OpenClaw install + supply-chain SHA256 check
- `auto-configure-openclaw-skills.sh:430-433` — ClawHub install die() / WARNING
- `auto-configure-openclaw-skills.sh:643-647` — external-dep download die()

**Status / help / banner (still Chinese):**
- `smart-ide-migration.sh:760-833` — full usage banner
- `smart-ide-migration.sh:1071-1072, 1106-1107, 1138, ...` — dozens of `set_message` calls in IDE-specific branches
- `smart-ide-migration.sh:4108-4164` — entire migration report header/sections
- `verify-ide-config.sh:3-7, 258, 284, 313, 317` — comments and banners

**Control case:** `update-openclaw-skills.sh` has zero Chinese strings (already fully translated by this diff), proving the diff CAN translate completely when it tries.

**Suggested fix:** Decide a policy — either translate everything (and update tests to expect new strings) or revert test translations to match current Chinese. The current state (some English tests, mostly Chinese production) is the worst of both worlds and is the direct cause of the 8 test failures above.

### 🟡 IMPORTANT #2 — `verify-ide-config.sh` is misnamed and gapful

**File:** `skills/agent-skills-setup/scripts/verify-ide-config.sh`

The header claims "real path validation" and `SKILL.md` Step 8 promises parse checks, filesystem stats, and live MCP commands. The implementation only string-compares the resolver output against a hand-maintained `EXPECTED` table — both of which live in this repo. It's a tautology check.

**Other gaps:**
- Cline's macOS-only path (`~/Library/Application Support/...`) is hardcoded at line 138. **Will FAIL on Linux/Windows CI hosts.**
- No `prompts`/`commands` validation.
- No `agents`/`hooks`/`memory` negative-path tests (verifier should confirm these return empty, not silently ignore).
- `EXPECTED` table is hand-maintained and can drift from `ide-paths.json` without detection.

**Suggested fix:** Either rename the script to `verify-resolver-consistency.sh` and document its true scope, or extend it to do what `SKILL.md` already promises (real filesystem stats, JSON/TOML/YAML parse, MCP runtime checks).

### 🟡 IMPORTANT #3 — Multiple stale claims in `ide-registry.md`

Per F1 + peer review, the registry has not been updated to match the new scope/project-path work in the script. Confirmed stale:

- `ide-registry.md:248` — Antigravity "only global handlers / no workspace-MCP" (F1 confirmed; script now provides workspace-MCP, workspace-skills, workspace-rules resolvers).

The peer also flagged (not yet independently re-verified):
- `:22` Claude project-mcp diagnostic
- `:85` Copilot only-global
- `:153` Zed project diagnostic/manual
- `:163` Trae project MCP manual/diagnostic
- `:231` Gemini no scope selector
- `:370` Void project diagnostic/manual
- `:459` CodeBuddy only user
- `:495` ZCode user-only agents (vs `smart-ide-migration.sh:4227` reference to project `.zcode/agents`)

**Suggested fix:** Either update the registry to reflect what the script now does, or remove the new script capabilities to match the registry. Pick one source of truth.

### 💡 SUGGESTION #4 — `install.sh` doesn't apply `sync-root-mirror` rewrites

**File:** `install.sh:53`

`install.sh` does verbatim `cp -R` — it doesn't apply the same path rewrites that `scripts/sync-root-mirror.sh` applies to root `SKILL.md`. Install targets retain `skills/agent-skills-setup/...` paths in installed copies.

This contradicts SKILL.md's documented mirror contract. Not strictly a bug (canonical paths may be intentional for installs), but the divergence should be intentional and documented.

### 💡 SUGGESTION #5 — `migrate_project_skills` reimplements strategy logic

**File:** `smart-ide-migration.sh:1293-1384`

`apply_skill_strategy()` (around line 1030) already encapsulates strategy handling for the global case. The new project handler reimplements it inline, causing behavioral divergence (no `safe_remove_skill_dir` symmetry, different symlink handling, no return-code convention). Refactor to reuse.

### 💡 SUGGESTION #6 — `list_available_objects` is not scope-aware

**File:** `smart-ide-migration.sh:915-969`

`list_available_objects()` still detects Skills/MCP/config from global paths only. `--scope project` without explicit `--objects` won't auto-discover project Skills or project MCP. The user is forced to specify `--objects` explicitly, which is surprising.

### 💡 SUGGESTION #7 — `project-mcp` ignores selected `--scope`

`project-mcp` always forces project scope internally (always calls `migrate_mcp ... "project"`). `--objects project-mcp --scope global` is accepted by the parser but the operation runs at project scope, while the summary reports `global`. Either reject the combination or honor the user's scope choice.

### 💡 SUGGESTION #8 — Generated report omits scope

`generate_report()` (line 4317-4321) records source/target/workspace/strategy/time but not `SCOPE`. This is particularly problematic when `--scope both` runs two operations under one object name and the user can't tell which output belongs to which.

---

## Nits (🟢)

- **Two production scripts have no test:** `export-public-skill.sh` and `prepare-clawhub-release.sh`. Their diffs are small but their absence from CI is a coverage gap.
- **Test discipline inconsistency:** `test-smart-ide-migration.sh`, `test-vscode-mapping.sh`, and `test-remaining-ide-mappings.sh` use `set -euo pipefail` and abort on first failure. The accumulating pattern in `test-mcp-secret-redaction.sh` and `test-migration.sh` is better. Pre-existing; not introduced by this diff.
- **Mktemp prefix collision risk:** `test-migration.sh` and `test-smart-ide-migration.sh` both use `/tmp/agent-skills-migration-test.XXXXXX`. Birthday-paradox risk in shared CI caches. Pre-existing.
- **`SKILL.md` narrative drift:** the new scope selector is documented in `SKILL.md` (lines 43, 100) but the script does not implement `--scope` in some flows (per V4/V5 evidence). Worth re-checking the docs once the implementation stabilizes.
- **`auto-configure-openclaw-skills.sh` install-kind coverage is thin:** only `node` and `download` installer kinds are tested; `brew`, `go`, `uv`, `--api-key-env` negative path, and `extract_skill_metadata` parser fallbacks are not exercised.
- **`update-openclaw-skills.sh` test coverage is thin:** only the happy-path mirror step. `--skip-runtime`, `--skip-clawhub`, no-`--yes` reject, `clawhub update --all --workdir`, and `openclaw doctor` are not covered.

---

## Questions

1. **Translation policy.** The diff translates some tests to English but not the corresponding production strings. Is the intent (a) full English-i18n of the suite, (b) revert test translations and keep Chinese, or (c) leave the suite as-is? The current state (mixed) is what causes the 8 test failures.
2. **`--scope` semantics.** Is `--scope both` intended to (a) run global+project and report both, or (b) prefer one with a fallback? The current code runs both and concatenates statuses, hiding the first scope's result.
3. **Registry updates.** Will the registry updates needed to match the new scope support (Antigravity, Claude, Copilot, Zed, Trae, Gemini, Void, CodeBuddy, ZCode) be in this PR or follow-up?
4. **Verifier scope.** Should `verify-ide-config.sh` be renamed (it doesn't validate real paths) or extended (to do what `SKILL.md` promises)?

---

## Verifier Discrepancy (meta-note for the team)

Two Phase 2 verifiers (V4, V5) appeared to read `git show HEAD:skills/...` instead of the working tree. Specifically:
- V5 reported "Script defines no `--scope` flag" — but V1 successfully ran `--scope project`.
- V4 reported `--scope` was rejected with "未知参数" — but `--scope` is in the working tree.

In both cases, the verifier's refutes were based on the pre-diff file. **The Plan agent's demote-to-important rule caught this implicitly:** instead of a clean refute killing the security findings, the discrepancy surfaced as a reading-target issue. **Take-away for future deep reviews:** explicitly instruct adversarial verifiers to read the **working tree** (`git diff HEAD` first, then read the post-diff file), not just the committed HEAD.

---

## Verdict

🔄 **Request Changes**

Six 🔴 blockers. The most serious (secret leak, source-destruction data loss, broken CI) must be addressed before merge. The translation drift is the proximate cause of the CI failure and must be resolved one way or the other. The pre-existing `verify-ide-config.sh` gap and the unconditional vscode override are smaller but should be in this PR while the relevant code is open.

Estimated remediation effort:
- Fix #1 (project skill redaction): 30 min
- Fix #2 + #3 (source==target guards): 1 hour (incl. tests)
- Fix #4 (test failures): 2-4 hours depending on translation policy
- Fix #5 (Void root key): 30 min
- Fix #6 (vscode override gate): 15 min
- Total: ~half a day to land a clean, blocking-issue-free PR.

---

## Methodology Appendix

This review used the **code-review-excellence** skill at deep/adversarial depth. Architecture:

- **Phase 1 (discovery):** 3 parallel Explore agents (smart-ide-migration.sh diff mapper, IDE registry schema auditor, test coverage + bash hygiene scanner) + 1 Plan agent (architecture validator).
- **Phase 0 (test execution):** 1 agent ran all 17 test scripts and captured per-test results.
- **Phase 1 (security verification):** 3 parallel agents, each attempting to refute the three core security findings via live fixture reproduction.
- **Phase 2 (correctness verification):** 2 parallel agents (V4, V5).
- **Phase 3 (surface-area finders):** 3 parallel agents (F1 schema, F2 localization, F3 mirror+CI+install).
- **Phase 4 (synthesis):** deduplication + severity ranking + this document.

Total agent spend: 14. Agent transcripts are at `~/.claude/agents/...` for audit. Live fixture reproductions are at `/tmp/review-v1/`, `/tmp/review-v2/`, `/tmp/review-v3/` (cleaned up after review).