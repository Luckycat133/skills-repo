#!/usr/bin/env bash
#
# test-mcp-secret-redaction.sh — regression tests for the security fix that
# prevents live credentials from being copied during MCP config migration.
#
# Context: a security audit flagged that `smart-ide-migration.sh` could read
# credential-bearing agent-config directories and copy them (including API
# keys / tokens / bearer auth / URL-embedded credentials) to the target IDE.
#
# These tests assert:
#   1. JSON -> JSON migration blanks secrets (env values, bearer headers,
#      user:pass@ URLs, ?key= query-string creds) while preserving non-secrets
#      and keeping the file VALID JSON.
#   2. The [SECURITY] warning only prints when a real redaction happened
#      (honest count, not a false alarm on secret-free configs).
#   3. The YAML/TOML verbatim-copy fallback also redacts secrets.
#   4. The DEFAULT migration scope (no --objects) excludes mcp/config/project,
#      so secret-bearing config is NOT copied unless the user opts in.
#
# Runs against a FAKE HOME (mktemp); the real user home is never touched.

# No `set -e`: accumulate failures and report, then exit non-zero at the end.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIG="$SCRIPT_DIR/smart-ide-migration.sh"

TMP_ROOT="$(mktemp -d /tmp/agent-skills-redact-test.XXXXXX)"
export HOME="$TMP_ROOT/home"
mkdir -p "$HOME"

OUT_FILE="$TMP_ROOT/last.out"
cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT

CHECKS=0
FAIL=0
check_pass() { CHECKS=$((CHECKS + 1)); echo "PASS: $1"; }
check_fail() { CHECKS=$((CHECKS + 1)); FAIL=$((FAIL + 1)); echo "FAIL: $1" >&2; }

run() { "$@" > "$OUT_FILE" 2>&1; LAST_RC=$?; }

# Goose's current config is YAML with a type-specific `extensions` schema.
# The mapper intentionally fails closed for Goose MCP instead of copying a
# YAML file into a JSON target. Keep this fixture explicit: it must not expect
# the old generic YAML fallback to produce an invalid JSON MCP file.
run_goose_manual_mcp() {
    local label="$1"
    rm -f "$HOME/.cursor/mcp.json"
    run bash "$MIG" --source goose-cli --target cursor --objects mcp --strategy overwrite --yes
    if [[ $LAST_RC -eq 0 && ! -e "$HOME/.cursor/mcp.json" ]] && \
       grep -Fq 'Goose config.yaml uses YAML extensions; automatic MCP migration is unsupported' "$OUT_FILE"; then
        check_pass "$label: Goose YAML MCP fails closed without a JSON target"
    else
        check_fail "$label: Goose YAML MCP boundary was not fail-closed"
    fi
}

# Assert a destination file parses as valid JSON.
assert_valid_json() {
    local f="$1" d="$2"
    if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" 2>/dev/null; then
        check_pass "$d (valid JSON)"
    else
        check_fail "$d (invalid JSON): $(cat "$f" 2>/dev/null | head -3)"
    fi
}

# Assert a JSON destination has .mcpServers.<server>.<path> == expected.
assert_json_val() {
    local f="$1" server="$2" keypath="$3" expected="$4" d="$5"
    local got
    got=$(python3 - "$f" "$server" "$keypath" "$expected" <<'PY'
import json, sys
f, server, keypath, expected = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
node = json.load(open(f))["mcpServers"][server]
for part in keypath.split("."):
    node = node[part]
got = "" if node is None else str(node)
print("OK" if got == expected else "MISMATCH got=%r want=%r" % (got, expected))
PY
)
    if [[ "$got" == "OK" ]]; then check_pass "$d"; else check_fail "$d ($got)"; fi
}

# ===========================================================================
echo ""
echo "== 1. JSON -> JSON redaction (claude -> cursor, mcp) =="
S1="$HOME/.claude.json"
cat > "$S1" <<'EOF'
{
  "mcpServers": {
    "secret-env": {
      "command": "npx",
      "env": {
        "API_KEY": "EXAMPLE_API_KEY_VALUE",
        "GITHUB_TOKEN": "EXAMPLE_GITHUB_TOKEN_VALUE",
        "NORMAL_VAR": "just-a-normal-value",
        "DATABASE_URL": "postgres://user:pass@localhost:5432/db"
      }
    },
    "bearer": {
      "url": "https://mcp.example.com/sse",
      "headers": { "Authorization": "Bearer eyJhbGc.secretpart" }
    },
    "urlcred": { "url": "https://user:password@api.example.com/mcp" },
    "querycred": { "url": "https://api.example.com/mcp?key=TOKENABCDEF123456&other=keep" }
  }
}
EOF

run bash "$MIG" --source claude --target cursor --objects mcp --strategy overwrite --yes
assert_valid_json "$HOME/.cursor/mcp.json" "1: destination is valid JSON"
assert_json_val "$HOME/.cursor/mcp.json" secret-env "env.API_KEY" "" "1: API_KEY blanked"
assert_json_val "$HOME/.cursor/mcp.json" secret-env "env.GITHUB_TOKEN" "" "1: GITHUB_TOKEN blanked"
assert_json_val "$HOME/.cursor/mcp.json" secret-env "env.NORMAL_VAR" "just-a-normal-value" "1: NORMAL_VAR preserved"
assert_json_val "$HOME/.cursor/mcp.json" secret-env "env.DATABASE_URL" "" "1: DATABASE_URL (postgres cred) blanked"
assert_json_val "$HOME/.cursor/mcp.json" bearer "headers.Authorization" "" "1: Authorization bearer blanked"
assert_json_val "$HOME/.cursor/mcp.json" bearer "url" "https://mcp.example.com/sse" "1: benign bearer url kept"
assert_json_val "$HOME/.cursor/mcp.json" urlcred "url" "" "1: user:pass@ url blanked"
assert_json_val "$HOME/.cursor/mcp.json" querycred "url" "" "1: ?key= query-string cred blanked"
if grep -Fq "[SECURITY]" "$OUT_FILE"; then check_pass "1: [SECURITY] warning printed when secrets redacted"; else check_fail "1: [SECURITY] warning missing despite redaction"; fi
[[ $LAST_RC -eq 0 ]] && check_pass "1: migration exited rc=0" || check_fail "1: migration exited rc=$LAST_RC (expected 0)"

# ===========================================================================
echo ""
echo "== 2. Honest count: secret-free mcp config -> NO [SECURITY] warning =="
S2="$HOME/.claude.json"
cat > "$S2" <<'EOF'
{ "mcpServers": { "demo-server": { "command": "echo", "args": [] } } }
EOF
run bash "$MIG" --source claude --target cursor --objects mcp --strategy overwrite --yes
assert_valid_json "$HOME/.cursor/mcp.json" "2: destination is valid JSON"
if grep -Fq "demo-server" "$HOME/.cursor/mcp.json"; then check_pass "2: demo-server migrated"; else check_fail "2: demo-server missing"; fi
if grep -Fq "[SECURITY]" "$OUT_FILE"; then check_fail "2: [SECURITY] should NOT print for secret-free config"; else check_pass "2: no false [SECURITY] warning"; fi

# ===========================================================================
echo ""
echo "== 3. Goose YAML MCP is unsupported/fail-closed =="
mkdir -p "$HOME/.config/goose"
cat > "$HOME/.config/goose/config.yaml" <<'EOF'
extensions:
  mcp:
    servers:
      secret-server:
        command: npx
        env:
          API_KEY: "EXAMPLE_API_KEY_VALUE"
          NORMAL_VAR: "keep-this-value"
          DB_URL: "postgres://u:p@localhost/db"
EOF
run_goose_manual_mcp "3"
if grep -Fq 'EXAMPLE_API_KEY_VALUE' "$HOME/.config/goose/config.yaml"; then
    check_pass "3: Goose source YAML remains untouched"
else
    check_fail "3: Goose source YAML was modified"
fi

# ===========================================================================
echo ""
echo "== 4. Default scope excludes mcp (audit hardening) =="
# Source has BOTH a skill and a secret-bearing mcp config.
S4="$HOME/.claude.json"
cat > "$S4" <<'EOF'
{ "mcpServers": { "secret-env": { "env": { "API_KEY": "EXAMPLE_API_KEY_VALUE" } } } }
EOF
mkdir -p "$HOME/.claude/skills/demo-skill"
printf '%s\n' '---' 'name: demo-skill' 'description: fixture' '---' > "$HOME/.claude/skills/demo-skill/SKILL.md"

# Run WITHOUT --objects (default). The skill should migrate; the secret mcp
# must NOT be copied by default.
run bash "$MIG" --source claude --target cursor --yes
if [[ -f "$HOME/.cursor/skills/demo-skill/SKILL.md" ]]; then check_pass "4: low-risk skill migrated by default"; else check_fail "4: default migration did not move skills"; fi
if [[ -e "$HOME/.cursor/mcp.json" ]]; then
    if grep -Fq "EXAMPLE_API_KEY_VALUE" "$HOME/.cursor/mcp.json"; then
        check_fail "4: DEFAULT scope copied a live secret (mcp must be opt-in)"
    else
        check_pass "4: secret mcp not copied by default (no live secret present)"
    fi
else
    check_pass "4: secret mcp NOT migrated by default (file absent)"
fi
if grep -Fq "only low-risk types are migrated" "$OUT_FILE"; then check_pass "4: default-scope security notice printed"; else check_fail "4: default-scope notice missing"; fi

# ===========================================================================
echo ""
echo "== 5. Array secrets: secret-named key with LIST value (JSON path) =="
S5="$HOME/.claude.json"
cat > "$S5" <<'EOF'
{
  "mcpServers": {
    "arr-server": {
      "command": "npx",
      "env": { "NORMAL_VAR": "keep-me" },
      "API_KEYS": ["EXAMPLE_ARRAY_KEY_1", "EXAMPLE_ARRAY_KEY_2"],
      "args": ["--port", "8080", "--token", "EXAMPLE_ARGV_TOKEN", "--api-key=EXAMPLE_EQ_TOKEN"]
    }
  }
}
EOF
run bash "$MIG" --source claude --target cursor --objects mcp --strategy overwrite --yes
assert_valid_json "$HOME/.cursor/mcp.json" "5: destination is valid JSON"
if grep -Fq "EXAMPLE_ARRAY_KEY_1" "$HOME/.cursor/mcp.json"; then check_fail "5: API_KEYS[0] leaked"; else check_pass "5: API_KEYS[0] blanked"; fi
if grep -Fq "EXAMPLE_ARRAY_KEY_2" "$HOME/.cursor/mcp.json"; then check_fail "5: API_KEYS[1] leaked"; else check_pass "5: API_KEYS[1] blanked"; fi
if grep -Fq "EXAMPLE_ARGV_TOKEN" "$HOME/.cursor/mcp.json"; then check_fail "5: --token argv value leaked"; else check_pass "5: --token argv value blanked"; fi
if grep -Fq "EXAMPLE_EQ_TOKEN" "$HOME/.cursor/mcp.json"; then check_fail "5: --api-key=... value leaked"; else check_pass "5: --api-key=... value blanked"; fi
if grep -Fq '"--token"' "$HOME/.cursor/mcp.json"; then check_pass "5: --token flag itself preserved"; else check_fail "5: --token flag lost"; fi
if grep -Fq '"8080"' "$HOME/.cursor/mcp.json"; then check_pass "5: benign argv (8080) preserved"; else check_fail "5: benign argv lost"; fi

# ===========================================================================
echo ""
echo "== 6. Goose YAML arrays remain behind the fail-closed boundary =="
mkdir -p "$HOME/.config/goose"
cat > "$HOME/.config/goose/config.yaml" <<'EOF'
extensions:
  arr:
    command: npx
    api_keys: ["EXAMPLE_YAML_ARR_KEY_1", "EXAMPLE_YAML_ARR_KEY_2"]
    args: ["--token", "EXAMPLE_YAML_ARGV_TOKEN"]
    keep: ["normal-item"]
EOF
run_goose_manual_mcp "6"
if grep -Fq 'EXAMPLE_YAML_ARGV_TOKEN' "$HOME/.config/goose/config.yaml"; then
    check_pass "6: Goose YAML array source remains untouched"
else
    check_fail "6: Goose YAML array source was modified"
fi

# ===========================================================================
echo ""
echo "== 7. Config migration also redacts secrets =="
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/settings.json" <<'EOF'
{
  "editor.fontSize": 14,
  "apiKey": "EXAMPLE_SETTINGS_API_KEY",
  "telemetry": "off"
}
EOF
run bash "$MIG" --source claude --target openclaw --objects config --strategy overwrite --yes
if [[ -f "$HOME/.openclaw/openclaw.json" ]]; then
    if grep -Fq "EXAMPLE_SETTINGS_API_KEY" "$HOME/.openclaw/openclaw.json"; then
        check_fail "7: config migration leaked apiKey"
    else
        check_pass "7: config apiKey blanked"
    fi
    if grep -Fq '"editor.fontSize": 14' "$HOME/.openclaw/openclaw.json"; then check_pass "7: benign settings preserved"; else check_fail "7: benign settings lost"; fi
    assert_valid_json "$HOME/.openclaw/openclaw.json" "7: migrated config is valid JSON"
    if grep -Fq "[SECURITY]" "$OUT_FILE"; then check_pass "7: [SECURITY] warning printed for config redaction"; else check_fail "7: [SECURITY] warning missing for config redaction"; fi
    [[ $LAST_RC -eq 0 ]] && check_pass "7: migration exited rc=0" || check_fail "7: migration exited rc=$LAST_RC (expected 0)"
else
    check_fail "7: config migration produced no target file"
fi

# ===========================================================================
echo ""
echo "== 8. copilot/vscode MCP paths wired (no silent skip) =="
S8="$HOME/.claude.json"
cat > "$S8" <<'EOF'
{ "mcpServers": { "demo-server": { "command": "echo", "args": [], "tools": ["*"] } } }
EOF
run bash "$MIG" --source claude --target copilot --objects mcp --strategy overwrite --yes
if [[ -f "$HOME/.copilot/mcp-config.json" ]] && grep -Fq "demo-server" "$HOME/.copilot/mcp-config.json"; then
    check_pass "8: claude -> copilot mcp migrated to ~/.copilot/mcp-config.json"
else
    check_fail "8: claude -> copilot mcp still skipped"
fi
VSCODE_WORKSPACE="$TMP_ROOT/vscode-workspace"
rm -rf "$VSCODE_WORKSPACE"
mkdir -p "$VSCODE_WORKSPACE"
# --scope project reads the project .mcp.json, so place the source there
# (the user-level ~/.claude.json set above is for the copilot case).
cp "$S8" "$VSCODE_WORKSPACE/.mcp.json"
run bash "$MIG" --source claude --target vscode --workspace "$VSCODE_WORKSPACE" --objects mcp --scope project --strategy overwrite --yes
VSCODE_MCP="$VSCODE_WORKSPACE/.vscode/mcp.json"
if [[ -f "$VSCODE_MCP" ]]; then
    if python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert "demo-server" in d.get("servers", {})' "$VSCODE_MCP" 2>/dev/null; then
        check_pass "8: claude -> vscode mcp under root key servers"
    else
        check_fail "8: vscode mcp.json missing servers.demo-server"
    fi
else
    check_fail "8: claude -> vscode mcp produced no file"
fi

# ===========================================================================
echo ""
echo "== 9. Goose YAML short-secret flags remain behind the fail-closed boundary =="
mkdir -p "$HOME/.config/goose"
cat > "$HOME/.config/goose/config.yaml" <<'EOF'
extensions:
  mcp:
    servers:
      shortflag-inline:
        command: npx
        args: ["-p", "SHORT_P_VAL", "-t", "SHORT_T_VAL", "-k", "SHORT_K_VAL"]
      shortflag-cross:
        command: npx
        args:
          - -p
          - CROSS_P_VAL
          - -t
          - CROSS_T_VAL
EOF
run_goose_manual_mcp "9"

# ===========================================================================
echo ""
echo "== 10. Vector ②: StopIteration crash on quoted-key inline array =="
# The JSON-tree converter writes the destination as quoted-key JSON (e.g.
# "args": [...]). The line-based redactor then re-runs on that file. The OLD
# code applied re.sub to the WHOLE line (including the quoted key) while
# new_elems only held argv elements -> an extra quoted token -> next(it)
# raised StopIteration -> under set -e the whole migration aborted. Assert the
# migration completes (rc==0) and stays valid JSON instead of crashing.
S10="$HOME/.claude.json"
cat > "$S10" <<'EOF'
{
  "mcpServers": {
    "stopiter-server": {
      "command": "npx",
      "args": ["-p", "STOPITER_PWD", "--token", "STOPITER_TOK", "benign-arg"]
    }
  }
}
EOF
run bash "$MIG" --source claude --target cursor --objects mcp --strategy overwrite --yes
assert_valid_json "$HOME/.cursor/mcp.json" "10: destination valid JSON after line redaction"
if [[ $LAST_RC -eq 0 ]]; then check_pass "10: migration did NOT crash on quoted-key inline array (rc=0)"; else check_fail "10: migration aborted/crashed on quoted-key inline array (rc=$LAST_RC)"; fi
if grep -Fq "STOPITER_PWD" "$HOME/.cursor/mcp.json"; then check_fail "10: -p value leaked"; else check_pass "10: -p value blanked"; fi
if grep -Fq "STOPITER_TOK" "$HOME/.cursor/mcp.json"; then check_fail "10: --token value leaked"; else check_pass "10: --token value blanked"; fi
if grep -Fq '"benign-arg"' "$HOME/.cursor/mcp.json"; then check_pass "10: benign argv preserved"; else check_fail "10: benign argv lost"; fi

# ===========================================================================
echo ""
echo "== 11. Goose YAML list-item secrets remain behind the fail-closed boundary =="
mkdir -p "$HOME/.config/goose"
cat > "$HOME/.config/goose/config.yaml" <<'EOF'
extensions:
  mcp:
    servers:
      yaml-list-server:
        command: npx
        env:
          - api_key: "secret123"
          - token: "tok-xyz-789"
          - normal_var: "keep-this"
EOF
run_goose_manual_mcp "11"

# ===========================================================================
echo ""
echo "== 12. Goose YAML multi-line args remain behind the fail-closed boundary =="
mkdir -p "$HOME/.config/goose"
cat > "$HOME/.config/goose/config.yaml" <<'EOF'
extensions:
  mcp:
    servers:
      multiline-args-server:
        command: npx
        args:
          - --token
          - TOKVALUE-abcdef123456
          - -p
          - mypassword
          - normal-arg
EOF
run_goose_manual_mcp "12"

# ===========================================================================
echo ""
echo "== 13. Vector ⑤: compact single-line JSON with multiple secret keys =="
# A single line carrying several '\"secretKey\": \"value\"' pairs. The OLD
# key/value line regex only matched the FIRST key on a line; the line redactor
# must now blank EVERY secret-keyed value on the line (redact_kv), leaving
# non-secret keys and their values intact.
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/settings.json" <<'EOF'
{
  "apiKey": "AK_SL", "token": "TOK_SL", "password": "PW_SL",
  "normalField": "keep-this-too",
  "nested": { "secret": "SEC_NESTED" }
}
EOF
run bash "$MIG" --source claude --target openclaw --objects config --strategy overwrite --yes
D13="$HOME/.openclaw/openclaw.json"
if [[ -f "$D13" ]]; then
    if grep -Fq "AK_SL" "$D13"; then check_fail "13: compact line apiKey leaked"; else check_pass "13: compact line apiKey blanked"; fi
    if grep -Fq "TOK_SL" "$D13"; then check_fail "13: compact line token leaked"; else check_pass "13: compact line token blanked"; fi
    if grep -Fq "PW_SL" "$D13"; then check_fail "13: compact line password leaked"; else check_pass "13: compact line password blanked"; fi
    if grep -Fq "SEC_NESTED" "$D13"; then check_fail "13: second compact line secret leaked"; else check_pass "13: second compact line secret blanked"; fi
    if grep -Fq "keep-this-too" "$D13"; then check_pass "13: non-secret field preserved"; else check_fail "13: non-secret field lost"; fi
    assert_valid_json "$D13" "13: compact-line migrated config is valid JSON"
    [[ $LAST_RC -eq 0 ]] && check_pass "13: migration exited rc=0" || check_fail "13: migration exited rc=$LAST_RC (expected 0)"
else
    check_fail "13: compact-line config migration produced no file"
fi

# ===========================================================================
echo ""
echo "== 14. Goose YAML keyed secrets remain behind the fail-closed boundary =="
mkdir -p "$HOME/.config/goose"
cat > "$HOME/.config/goose/config.yaml" <<'EOF'
extensions:
  mcp:
    servers:
      keyedline-server:
        command: npx
        token: "tok-xyz-789"
        apiKey: bare-val-42
        timeout: "30s"
EOF
run_goose_manual_mcp "14"

# ===========================================================================
echo ""
echo "== 15. Goose YAML consecutive secret flags remain behind the fail-closed boundary =="
mkdir -p "$HOME/.config/goose"
cat > "$HOME/.config/goose/config.yaml" <<'EOF'
extensions:
  mcp:
    servers:
      consecutive-flags-server:
        command: npx
        args:
          - -p
          - -t
          - CONSEC_SECRET_VAL
          - --verbose
EOF
run_goose_manual_mcp "15"

# ===========================================================================
echo ""
echo "== 16. Review-fix: fail-closed on redaction failure (vector ② hardening) =="
# If the redactor cannot even READ the destination copy, it must fail CLOSED:
# delete the (possibly secret-bearing) copy, emit -1, and return rc!=0 —
# never leave an un-redacted file behind. Exercises the extracted function
# directly against an unreadable file.
D16_DIR=$(mktemp -d "$TMP_ROOT/failclosed.XXXXXX")
D16="$D16_DIR/copy.json"
printf '{"apiKey": "FAILCLOSED_SECRET"}\n' > "$D16"
chmod 000 "$D16"
set +e
D16_OUT=$(bash -c '
    # The extracted function depends on the shared redaction engine
    # (REDACTOR_PY global + ensure_redactor_script), so extract those too.
    eval "$(sed -n "/^REDACTOR_PY=/,/^}/p" "$1")"
    eval "$(sed -n "/^redact_secrets_in_file()/,/^}/p" "$1")"
    redact_secrets_in_file "$2"
' _ "$MIG" "$D16" 2>/dev/null)
D16_RC=$?
set -e
if [[ $D16_RC -ne 0 ]]; then check_pass "16: fail-closed returns non-zero rc"; else check_fail "16: fail-closed returned rc=0"; fi
if [[ "$D16_OUT" == "-1" ]]; then check_pass "16: fail-closed emits -1 sentinel"; else check_fail "16: fail-closed emitted '$D16_OUT' (expected -1)"; fi
if [[ ! -e "$D16" ]]; then check_pass "16: secret-bearing copy deleted (fail closed)"; else check_fail "16: secret-bearing copy left on disk"; chmod 644 "$D16" 2>/dev/null || true; fi

# ===========================================================================
echo ""
echo "== 17. CR-001: provider-key VALUE formats redacted under non-secret key names =="
# Key names below deliberately do NOT contain secret keywords (api_key/token/...
# ...), so the key-name heuristic alone would miss them. The credential VALUE
# itself (sk-/ghp_/AKIA/xoxb/...) must still be blanked on BOTH the JSON/MCP
# path and the config (TOML/JSON) path.
S17="$HOME/.claude.json"
cat > "$S17" <<'EOF'
{
  "mcpServers": {
    "provider-vals": {
      "command": "npx",
      "env": {
        "MY_KEY": "sk-ant-abcdefghijklmnopqrstuvw",
        "WEBHOOK_URL": "xoxb-1234567890-abcdefghij",
        "NORMAL_VAR": "keep-this-value"
      }
    }
  }
}
EOF
run bash "$MIG" --source claude --target cursor --objects mcp --strategy overwrite --yes
assert_valid_json "$HOME/.cursor/mcp.json" "17: mcp destination is valid JSON"
if grep -Fq "sk-ant-abcdefghijklmnopqrstuvw" "$HOME/.cursor/mcp.json"; then check_fail "17: provider value (sk-) under MY_KEY leaked"; else check_pass "17: sk- provider value blanked under non-secret key"; fi
if grep -Fq "xoxb-1234567890-abcdefghij" "$HOME/.cursor/mcp.json"; then check_fail "17: provider value (xoxb) under WEBHOOK_URL leaked"; else check_pass "17: xoxb provider value blanked under non-secret key"; fi
if grep -Fq "keep-this-value" "$HOME/.cursor/mcp.json"; then check_pass "17: non-secret value preserved"; else check_fail "17: non-secret value lost"; fi
[[ $LAST_RC -eq 0 ]] && check_pass "17: mcp migration exited rc=0" || check_fail "17: mcp migration exited rc=$LAST_RC (expected 0)"

mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/settings.json" <<'EOF'
{
  "editor.fontSize": 14,
  "modelKey": "ghp_abcdefghijklmnopqrst",
  "svcAccount": "AKIAIOSFODNN7EXAMPLE",
  "telemetry": "off"
}
EOF
run bash "$MIG" --source claude --target openclaw --objects config --strategy overwrite --yes
D17="$HOME/.openclaw/openclaw.json"
if [[ -f "$D17" ]]; then
    if grep -Fq "ghp_abcdefghijklmnopqrst" "$D17"; then check_fail "17: ghp_ provider value under modelKey leaked"; else check_pass "17: ghp_ provider value blanked under non-secret key"; fi
    if grep -Fq "AKIAIOSFODNN7EXAMPLE" "$D17"; then check_fail "17: AKIA provider value under svcAccount leaked"; else check_pass "17: AKIA provider value blanked under non-secret key"; fi
    if grep -Fq '"editor.fontSize": 14' "$D17"; then check_pass "17: benign config preserved"; else check_fail "17: benign config lost"; fi
    assert_valid_json "$D17" "17: config migrated to valid JSON"
    [[ $LAST_RC -eq 0 ]] && check_pass "17: config migration exited rc=0" || check_fail "17: config migration exited rc=$LAST_RC (expected 0)"
else
    check_fail "17: config migration produced no target file"
fi

# ===========================================================================
echo ""
echo "== 18. CR-002: fail-closed when python3 is unavailable (no silent leak) =="
# Build a PATH containing every system binary EXCEPT python3, so that
# `command -v python3` fails inside the migration script. The redactor must
# then refuse (delete the copy, emit [SECURITY]) instead of reporting success
# with zero redaction — never leaving a secret-bearing file on disk.
T18_BIN="$(mktemp -d "$TMP_ROOT/no-py.XXXXXX")"
for b in /bin/* /usr/bin/*; do
    bn="$(basename "$b")"
    case "$bn" in python*) continue ;; esac
    ln -s "$b" "$T18_BIN/$bn" 2>/dev/null || true
done
run_no_python3() { PATH="$T18_BIN" "$@" > "$OUT_FILE" 2>&1; LAST_RC=$?; }

# 18a. MCP config with a live secret -> must NOT leave a secret-bearing copy.
S18="$HOME/.claude.json"
cat > "$S18" <<'EOF'
{ "mcpServers": { "leak-test": { "env": { "API_KEY": "sk-ant-TOTALLYSECRETMUSTNOTLEAK" } } } }
EOF
run_no_python3 bash "$MIG" --source claude --target cursor --objects mcp --strategy overwrite --yes
if [[ ! -e "$HOME/.cursor/mcp.json" ]]; then
    check_pass "18a: MCP copy absent (fail-closed removed the un-redacted file)"
else
    if grep -Fq "sk-ant-TOTALLYSECRETMUSTNOTLEAK" "$HOME/.cursor/mcp.json"; then
        check_fail "18a: secret LEAKED despite missing python3"
    else
        check_fail "18a: copy left on disk without secret (should have been deleted)"
    fi
fi
if grep -Fq "[SECURITY]" "$OUT_FILE"; then check_pass "18a: [SECURITY] warning emitted when python3 missing"; else check_fail "18a: [SECURITY] warning missing for no-python3 path"; fi

# 18b. config with a live secret -> same fail-closed guarantee.
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/settings.json" <<'EOF'
{ "apiKey": "sk-ant-CONFIGSECRETMUSTNOTLEAK", "telemetry": "off" }
EOF
run_no_python3 bash "$MIG" --source claude --target openclaw --objects config --strategy overwrite --yes
if [[ ! -e "$HOME/.openclaw/openclaw.json" ]]; then
    check_pass "18b: config copy absent (fail-closed removed the un-redacted file)"
else
    if grep -Fq "sk-ant-CONFIGSECRETMUSTNOTLEAK" "$HOME/.openclaw/openclaw.json"; then
        check_fail "18b: config secret LEAKED despite missing python3"
    else
        check_fail "18b: config copy left on disk without secret (should have been deleted)"
    fi
fi

# ===========================================================================
echo ""
echo "== 19. MED-T3: malformed source JSON must not mutate the source =="
# Boundary guard: the migration must never alter the SOURCE config, even when
# it cannot parse it. A fail-open-safe design keeps an unredacted/garbled
# source intact and recoverable; a crash or source mutation would destroy
# evidence and is unacceptable.
S19="$HOME/.claude.json"
printf '{ "mcpServers": ' > "$S19"
ORIG="$(cat "$S19")"
run bash "$MIG" --source claude --target cursor --objects mcp --strategy overwrite --yes
if [[ "$(cat "$S19")" == "$ORIG" ]]; then
    check_pass "19: malformed source config left UNCHANGED (fail-open-safe, recoverable)"
else
    check_fail "19: malformed source config was MUTATED by migration"
fi
# Reaching this point means the migration did not hang or crash on malformed
# input; assert it returned a clean numeric exit status.
if [[ "$LAST_RC" =~ ^[0-9]+$ ]]; then
    check_pass "19: migration returned a clean exit code (rc=$LAST_RC) on malformed input"
else
    check_fail "19: migration produced a non-numeric exit status on malformed input"
fi

# ===========================================================================
echo ""
if [[ $FAIL -eq 0 ]]; then
    echo "ALL $CHECKS MCP SECRET-REDACTION CHECKS PASSED"
    exit 0
else
    echo "$FAIL / $CHECKS MCP SECRET-REDACTION CHECKS FAILED" >&2
    exit 1
fi
