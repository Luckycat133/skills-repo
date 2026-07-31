#!/usr/bin/env bash
#
# test-migration.sh — isolated tests for the migration engine.
#
# Exercises smart-ide-migration.sh using fake data and a temporary HOME. The
# real user home is never touched: HOME is pointed at a mktemp tree for the
# entire run.
#
# Isolation guarantees:
#   - temp HOME (mktemp)
#   - cleanup trap
#   - clear per-check PASS/FAIL
#   - non-zero exit on any failure

# No `set -e`: we want to ACCUMULATE failures across checks and report them,
# then exit non-zero at the end. The scripts-under-test carry their own
# `set -euo pipefail` internally.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Isolation: TEMP HOME ----------------------------------------------------
# Everything the engines write (via ${HOME}/...) lands here. The real ~ is never
# referenced because we export HOME to this tree before invoking the scripts.
TMP_ROOT="$(mktemp -d /tmp/agent-skills-migration-test.XXXXXX)"
export HOME="$TMP_ROOT/home"
mkdir -p "$HOME"

# Temp output capture for the last script invocation.
OUT_FILE="$TMP_ROOT/last.out"

safe_remove_fixture_path() {
    local candidate="$1"

    case "$candidate" in
        "$TMP_ROOT"/*) ;;
        *) return 1 ;;
    esac
    [[ -e "$candidate" || -L "$candidate" ]] || return 0
    find "$candidate" -depth -delete
}

cleanup() {
    [[ -d "$TMP_ROOT" && "$TMP_ROOT" == /tmp/agent-skills-migration-test.* ]] || return 0
    find "$TMP_ROOT" -depth -delete
}
trap cleanup EXIT

# --- Check accounting ---------------------------------------------------------
CHECKS=0
FAIL=0

check_pass() { CHECKS=$((CHECKS + 1)); echo "PASS: $1"; }
check_fail() { CHECKS=$((CHECKS + 1)); FAIL=$((FAIL + 1)); echo "FAIL: $1" >&2; }

assert_file() {
    local p="$1" d="$2"
    if [[ -e "$p" ]]; then check_pass "$d"; else check_fail "$d (missing: $p)"; fi
}
assert_dir() {
    local p="$1" d="$2"
    if [[ -d "$p" ]]; then check_pass "$d"; else check_fail "$d (missing dir: $p)"; fi
}
assert_not_exists() {
    local p="$1" d="$2"
    if [[ ! -e "$p" ]]; then check_pass "$d"; else check_fail "$d (unexpected path exists: $p)"; fi
}
assert_contains() {
    local f="$1" pat="$2" d="$3"
    if grep -Fq "$pat" "$f"; then check_pass "$d"; else check_fail "$d (no '$pat' in $f)"; fi
}
assert_eq() {
    local a="$1" b="$2" d="$3"
    if [[ "$a" == "$b" ]]; then check_pass "$d"; else check_fail "$d (got '$a', want '$b')"; fi
}
assert_not_contains() {
    local f="$1" pat="$2" d="$3"
    if grep -Fq "$pat" "$f"; then check_fail "$d (unexpected '$pat' in $f)"; else check_pass "$d"; fi
}

# Run a script, capturing stdout+stderr and its exit code.
run() {
    "$@" > "$OUT_FILE" 2>&1
    LAST_RC=$?
}

# ===========================================================================
# Fake source fixtures
# ===========================================================================

# A rich fake skill: SKILL.md + scripts/ + references/ (tests subdir preservation).
SRC_SKILL="$HOME/.claude/skills/demo-skill"
mkdir -p "$SRC_SKILL/scripts" "$SRC_SKILL/references"
cat > "$SRC_SKILL/SKILL.md" <<'EOF'
---
name: demo-skill
description: Fake skill used by migration tests.
---
# Demo Skill
EOF
cat > "$SRC_SKILL/scripts/run.sh" <<'EOF'
#!/usr/bin/env bash
echo hi
EOF
cat > "$SRC_SKILL/references/notes.md" <<'EOF'
Reference content.
EOF

# A workspace root (for the rules object) and source rule/config/mcp files so the
# dry-run plan exercises all four object kinds.
WS="$TMP_ROOT/workspace"
mkdir -p "$WS"
cat > "$WS/CLAUDE.md" <<'EOF'
# Project rules
EOF
cat > "$HOME/.claude/settings.json" <<'EOF'
{ "foo": "bar" }
EOF
cat > "$HOME/.claude.json" <<'EOF'
{
  "mcpServers": {
    "demo-server": {
      "command": "echo",
      "args": [],
      "autoApprove": ["shell"],
      "enabledTools": ["read"],
      "disabledTools": ["write"]
    }
  }
}
EOF

# ===========================================================================
# A. smart-ide-migration.sh
# ===========================================================================

echo ""
echo "== A. smart-ide-migration.sh =="

# --- A1. Dry-run plan assertion (source claude -> target kimiai) ------------
run bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target kimiai \
    --workspace "$WS" \
    --objects skills,rules,mcp,config \
    --dry-run
assert_eq "$LAST_RC" "0" "A1: dry-run exits 0"

# Target path must be registry-correct: ~/.kimi-code/skills
assert_contains "$OUT_FILE" ".kimi-code/skills" "A1: dry-run target path is registry-correct (~/.kimi-code/skills)"

# Plan must mention all four object kinds.
assert_contains "$OUT_FILE" "skills"  "A1: plan mentions skills"
assert_contains "$OUT_FILE" "rules"   "A1: plan mentions rules"
assert_contains "$OUT_FILE" "mcp"     "A1: plan mentions mcp"
assert_contains "$OUT_FILE" "config"  "A1: plan mentions config"

# MCP: dry-run must print a PLAN, never a (false) success. The fixed logic sets
# status "skipped" for mcp in dry-run; the success wording only appears on a real
# conversion. Whole-IDE config is intentionally manual for every target, so
# the config object must report the manual boundary instead of pretending to be
# a copy plan.
assert_contains "$OUT_FILE" "DRY-RUN: converting MCP config" "A1: mcp plan printed in dry-run"
assert_not_contains "$OUT_FILE" "MCP config converted"     "A1: mcp NOT marked success in dry-run (C1)"
assert_contains "$OUT_FILE" "automatic whole-IDE config migration is unsupported" "A1: config manual boundary printed"
assert_not_contains "$OUT_FILE" "config file copied"       "A1: config NOT marked success in dry-run (C2)"

# --- A2. Real execution lands in correct locations (3 targets) --------------
for target in kimiai copilot codex; do
    run bash "$SCRIPT_DIR/smart-ide-migration.sh" \
        --source claude --target "$target" \
        --workspace "$WS" \
        --objects skills --yes
    assert_eq "$LAST_RC" "0" "A2: real migration to $target exits 0"
done

assert_file "$HOME/.kimi-code/skills/demo-skill/SKILL.md"   "A2: kimiai  -> ~/.kimi-code/skills/demo-skill/"
assert_file "$HOME/.copilot/skills/demo-skill/SKILL.md"     "A2: copilot -> ~/.copilot/skills/demo-skill/"
assert_file "$HOME/.agents/skills/demo-skill/SKILL.md"      "A2: codex   -> ~/.agents/skills/demo-skill/"

# --- A3. Copilot preserves subdirs (H4) ------------------------------------
assert_dir "$HOME/.copilot/skills/demo-skill/scripts"    "A3: copilot preserves scripts/ subdir (H4)"
assert_dir "$HOME/.copilot/skills/demo-skill/references" "A3: copilot preserves references/ subdir (H4)"

# --- A4. MCP honest status (C1) --------------------------------------------
# Source claude has a real MCP file; target kimiai supports mcpServers JSON.
run bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target kimiai \
    --workspace "$WS" \
    --objects mcp --yes
assert_eq "$LAST_RC" "0" "A4: mcp migration exits 0"

# The fixed logic NEVER reports success/copied without actually writing the file.
# So: status must be success/copied AND the target file must exist + be non-empty
# AND contain the converted server.
assert_file "$HOME/.kimi-code/mcp.json" "A4: mcp target file was written"
assert_contains "$HOME/.kimi-code/mcp.json" "demo-server" "A4: mcp server present in target file"
assert_not_contains "$OUT_FILE" "[✗] mcp" "A4: mcp not failed"
assert_contains "$OUT_FILE" "mcp" "A4: mcp reported in output"

# Approval lists grant tool execution privileges in some IDEs. MCP migration
# may transfer endpoint metadata, but it must never carry these grants across
# products.
assert_not_contains "$HOME/.kimi-code/mcp.json" "autoApprove" "A4: MCP strips autoApprove grants"
assert_not_contains "$HOME/.kimi-code/mcp.json" "enabledTools" "A4: MCP strips enabledTools grants"
assert_not_contains "$HOME/.kimi-code/mcp.json" "disabledTools" "A4: MCP strips disabledTools grants"

# --- A5. Generic whole-config migration is fail-closed --------------------
CONFIG_TGT="$HOME/.cursor/settings.json"
run bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target cursor \
    --workspace "$WS" \
    --objects config --yes
assert_eq "$LAST_RC" "0" "A5: config boundary exits 0"
assert_not_exists "$CONFIG_TGT" "A5: generic config boundary creates no target config"
assert_contains "$OUT_FILE" "automatic whole-IDE config migration is unsupported" "A5: generic config boundary explains manual review"

# ===========================================================================
# C. Confirmation gate (--yes) — script must never write without approval
# ===========================================================================

echo ""
echo "== C. confirmation gate (--yes) =="

# --- C1. Non-interactive without --yes: abort (rc=2) and ZERO writes --------
GATE_TGT="$HOME/.codeium/windsurf"
safe_remove_fixture_path "$GATE_TGT"
run bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target windsurf \
    --workspace "$WS" \
    --objects skills </dev/null
assert_eq "$LAST_RC" "2" "C1: non-interactive without --yes aborts with rc=2"
assert_not_exists "$GATE_TGT" "C1: gate abort leaves zero writes (no target dir created)"

# --- C2. With --yes: proceeds and writes ------------------------------------
run bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target windsurf \
    --workspace "$WS" \
    --objects skills --yes </dev/null
assert_eq "$LAST_RC" "0" "C2: --yes proceeds (rc=0)"
assert_file "$GATE_TGT/skills/demo-skill/SKILL.md" "C2: --yes migration wrote target skill"

# --- C3. --dry-run without --yes: previews with ZERO writes ------------------
safe_remove_fixture_path "$GATE_TGT"
run bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target windsurf \
    --workspace "$WS" \
    --objects skills --dry-run </dev/null
assert_eq "$LAST_RC" "0" "C3: dry-run exits 0 without --yes"
assert_not_exists "$GATE_TGT" "C3: dry-run performs zero writes (no target dir created)"

# ===========================================================================
# D. project object — whole-tree migration is fail-closed
# ===========================================================================
# Source project lives under WORKSPACE_ROOT ($WS): source=claude -> .claude
# Target project (codex) -> .agents (codex project config lives under .agents; .codex is its own credential-bearing CLI dir).

echo ""
echo "== D. project object (manual boundary) =="

SRC_PROJ="$WS/.claude"
safe_remove_fixture_path "$SRC_PROJ"
mkdir -p "$SRC_PROJ"
# These representative files must never be copied as an opaque project tree.
printf 'API_KEY=EXAMPLE_SECRET_VALUE_1234567890\nPASSWORD=example-password-xyz\n' > "$SRC_PROJ/.env"
printf '{ "token": "example-token-value-1234567890", "name": "ok" }\n' > "$SRC_PROJ/svc.json"
printf 'name: demo\n' > "$SRC_PROJ/notes.yaml"

D_TGT="$WS/.agents"
safe_remove_fixture_path "$D_TGT"
for backup_path in "$WS"/.agents.bak.*; do
    [[ -e "$backup_path" || -L "$backup_path" ]] || continue
    safe_remove_fixture_path "$backup_path"
done

# --- D1. dry-run: zero writes, manual boundary printed --------------------
run bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target codex \
    --workspace "$WS" \
    --objects project --dry-run
assert_eq "$LAST_RC" "0" "D1: project dry-run exits 0"
assert_not_exists "$D_TGT" "D1: project dry-run performs ZERO writes"
assert_contains "$OUT_FILE" "automatic whole-project configuration migration is unsupported" "D1: project dry-run explains manual boundary"

# --- D2. real execution is also a manual boundary -------------------------
run bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target codex \
    --workspace "$WS" \
    --objects project --yes
assert_eq "$LAST_RC" "0" "D2: project migration exits 0"
assert_not_exists "$D_TGT" "D2: project boundary creates no target tree"
assert_contains "$OUT_FILE" "automatic whole-project configuration migration is unsupported" "D2: project boundary explains manual review"
assert_contains "$SRC_PROJ/.env" "EXAMPLE_SECRET_VALUE_1234567890" "D2: SOURCE secret untouched"
assert_contains "$SRC_PROJ/svc.json" "example-token-value-1234567890" "D2: SOURCE json secret untouched"

# Recursive cleanup of variables plus a glob can delete an unintended tree.
# Keep this test pattern-specific so other isolated test fixtures can retain
# their independently reviewed cleanup helpers.
if grep -Eq 'rm[[:space:]]+-r[f][[:space:]]+"\$D_TGT"[[:space:]]+"\$WS"/.agents.bak.\*' "$0"; then
    check_fail "D3: project-fixture cleanup avoids recursive variable/glob deletion"
else
    check_pass "D3: project-fixture cleanup avoids recursive variable/glob deletion"
fi

# Skill cleanup after redaction failure must use the same guarded deletion
# helper as overwrite handling. Direct recursive deletion of computed paths is
# the TM1 pattern reported by SkillSpector.
if grep -Eq 'rm -rf "\$\{target_(global|path):\?\}/\$\{skill_name:\?\}"' "$SCRIPT_DIR/smart-ide-migration.sh"; then
    check_fail "D6: redaction failure cleanup bypasses safe_remove_skill_dir"
else
    check_pass "D6: redaction failure cleanup uses guarded deletion"
fi
if grep -Fq 'rm -rf "$target_path"' "$SCRIPT_DIR/smart-ide-migration.sh"; then
    check_fail "D7: project overwrite or failure cleanup bypasses containment guard"
else
    check_pass "D7: project tree deletion uses containment guard"
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
if [[ $FAIL -eq 0 ]]; then
    echo "ALL CHECKS PASSED ($CHECKS checks)"
    exit 0
else
    echo "$FAIL / $CHECKS checks FAILED" >&2
    exit 1
fi
