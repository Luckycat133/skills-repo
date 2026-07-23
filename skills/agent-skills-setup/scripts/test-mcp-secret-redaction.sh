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

run bash "$MIG" --source claude --target cursor --objects mcp --strategy overwrite
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

# ===========================================================================
echo ""
echo "== 2. Honest count: secret-free mcp config -> NO [SECURITY] warning =="
S2="$HOME/.claude.json"
cat > "$S2" <<'EOF'
{ "mcpServers": { "demo-server": { "command": "echo", "args": [] } } }
EOF
run bash "$MIG" --source claude --target cursor --objects mcp --strategy overwrite
assert_valid_json "$HOME/.cursor/mcp.json" "2: destination is valid JSON"
if grep -Fq "demo-server" "$HOME/.cursor/mcp.json"; then check_pass "2: demo-server migrated"; else check_fail "2: demo-server missing"; fi
if grep -Fq "[SECURITY]" "$OUT_FILE"; then check_fail "2: [SECURITY] should NOT print for secret-free config"; else check_pass "2: no false [SECURITY] warning"; fi

# ===========================================================================
echo ""
echo "== 3. YAML fallback redaction (goose-cli -> cursor, mcp) =="
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
run bash "$MIG" --source goose-cli --target cursor --objects mcp --strategy overwrite
if grep -Fq 'API_KEY: ""' "$HOME/.cursor/mcp.json"; then check_pass "3: YAML API_KEY blanked"; else check_fail "3: YAML API_KEY not redacted"; fi
if grep -Fq 'NORMAL_VAR: "keep-this-value"' "$HOME/.cursor/mcp.json"; then check_pass "3: YAML NORMAL_VAR preserved"; else check_fail "3: YAML NORMAL_VAR lost"; fi
if grep -Fq 'DB_URL: ""' "$HOME/.cursor/mcp.json"; then check_pass "3: YAML DB_URL (postgres cred) blanked"; else check_fail "3: YAML DB_URL not redacted"; fi
if grep -Fq "[SECURITY]" "$OUT_FILE"; then check_pass "3: [SECURITY] warning printed for YAML fallback"; else check_fail "3: [SECURITY] missing for YAML fallback"; fi

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
run bash "$MIG" --source claude --target cursor
if [[ -f "$HOME/.cursor/demo-skill/SKILL.md" ]]; then check_pass "4: low-risk skill migrated by default"; else check_fail "4: default migration did not move skills"; fi
if [[ -e "$HOME/.cursor/mcp.json" ]]; then
    if grep -Fq "EXAMPLE_API_KEY_VALUE" "$HOME/.cursor/mcp.json"; then
        check_fail "4: DEFAULT scope copied a live secret (mcp must be opt-in)"
    else
        check_pass "4: secret mcp not copied by default (no live secret present)"
    fi
else
    check_pass "4: secret mcp NOT migrated by default (file absent)"
fi
if grep -Fq "默认仅迁移低风险类型" "$OUT_FILE"; then check_pass "4: default-scope security notice printed"; else check_fail "4: default-scope notice missing"; fi

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
run bash "$MIG" --source claude --target cursor --objects mcp --strategy overwrite
assert_valid_json "$HOME/.cursor/mcp.json" "5: destination is valid JSON"
if grep -Fq "EXAMPLE_ARRAY_KEY_1" "$HOME/.cursor/mcp.json"; then check_fail "5: API_KEYS[0] leaked"; else check_pass "5: API_KEYS[0] blanked"; fi
if grep -Fq "EXAMPLE_ARRAY_KEY_2" "$HOME/.cursor/mcp.json"; then check_fail "5: API_KEYS[1] leaked"; else check_pass "5: API_KEYS[1] blanked"; fi
if grep -Fq "EXAMPLE_ARGV_TOKEN" "$HOME/.cursor/mcp.json"; then check_fail "5: --token argv value leaked"; else check_pass "5: --token argv value blanked"; fi
if grep -Fq "EXAMPLE_EQ_TOKEN" "$HOME/.cursor/mcp.json"; then check_fail "5: --api-key=... value leaked"; else check_pass "5: --api-key=... value blanked"; fi
if grep -Fq '"--token"' "$HOME/.cursor/mcp.json"; then check_pass "5: --token flag itself preserved"; else check_fail "5: --token flag lost"; fi
if grep -Fq '"8080"' "$HOME/.cursor/mcp.json"; then check_pass "5: benign argv (8080) preserved"; else check_fail "5: benign argv lost"; fi

# ===========================================================================
echo ""
echo "== 6. Array secrets: line-based fallback (YAML-ish copy path) =="
mkdir -p "$HOME/.config/goose"
cat > "$HOME/.config/goose/config.yaml" <<'EOF'
extensions:
  arr:
    command: npx
    api_keys: ["EXAMPLE_YAML_ARR_KEY_1", "EXAMPLE_YAML_ARR_KEY_2"]
    args: ["--token", "EXAMPLE_YAML_ARGV_TOKEN"]
    keep: ["normal-item"]
EOF
run bash "$MIG" --source goose-cli --target cursor --objects mcp --strategy overwrite
if grep -Fq "EXAMPLE_YAML_ARR_KEY_1" "$HOME/.cursor/mcp.json"; then check_fail "6: api_keys[0] leaked (line path)"; else check_pass "6: api_keys[0] blanked (line path)"; fi
if grep -Fq "EXAMPLE_YAML_ARR_KEY_2" "$HOME/.cursor/mcp.json"; then check_fail "6: api_keys[1] leaked (line path)"; else check_pass "6: api_keys[1] blanked (line path)"; fi
if grep -Fq "EXAMPLE_YAML_ARGV_TOKEN" "$HOME/.cursor/mcp.json"; then check_fail "6: --token value leaked (line path)"; else check_pass "6: --token value blanked (line path)"; fi
if grep -Fq "normal-item" "$HOME/.cursor/mcp.json"; then check_pass "6: benign array preserved (line path)"; else check_fail "6: benign array lost (line path)"; fi

# ===========================================================================
echo ""
echo "== 7. Config migration also redacts secrets =="
mkdir -p "$HOME/.cursor"
cat > "$HOME/.cursor/settings.json" <<'EOF'
{
  "editor.fontSize": 14,
  "apiKey": "EXAMPLE_SETTINGS_API_KEY",
  "telemetry": "off"
}
EOF
run bash "$MIG" --source cursor --target windsurf --objects config --strategy overwrite
if [[ -f "$HOME/.windsurf/settings.json" ]]; then
    if grep -Fq "EXAMPLE_SETTINGS_API_KEY" "$HOME/.windsurf/settings.json"; then
        check_fail "7: config migration leaked apiKey"
    else
        check_pass "7: config apiKey blanked"
    fi
    if grep -Fq '"editor.fontSize": 14' "$HOME/.windsurf/settings.json"; then check_pass "7: benign settings preserved"; else check_fail "7: benign settings lost"; fi
    assert_valid_json "$HOME/.windsurf/settings.json" "7: migrated config is valid JSON"
    if grep -Fq "[SECURITY]" "$OUT_FILE"; then check_pass "7: [SECURITY] warning printed for config redaction"; else check_fail "7: [SECURITY] warning missing for config redaction"; fi
else
    check_fail "7: config migration produced no target file"
fi

# ===========================================================================
echo ""
echo "== 8. copilot/vscode MCP paths wired (no silent skip) =="
S8="$HOME/.claude.json"
cat > "$S8" <<'EOF'
{ "mcpServers": { "demo-server": { "command": "echo" } } }
EOF
run bash "$MIG" --source claude --target copilot --objects mcp --strategy overwrite
if [[ -f "$HOME/.copilot/mcp-config.json" ]] && grep -Fq "demo-server" "$HOME/.copilot/mcp-config.json"; then
    check_pass "8: claude -> copilot mcp migrated to ~/.copilot/mcp-config.json"
else
    check_fail "8: claude -> copilot mcp still skipped"
fi
run bash "$MIG" --source claude --target vscode --objects mcp --strategy overwrite
VSCODE_MCP="$HOME/Library/Application Support/Code/User/mcp.json"
[[ -f "$VSCODE_MCP" ]] || VSCODE_MCP="$HOME/.config/Code/User/mcp.json"
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
if [[ $FAIL -eq 0 ]]; then
    echo "ALL $CHECKS MCP SECRET-REDACTION CHECKS PASSED"
    exit 0
else
    echo "$FAIL / $CHECKS MCP SECRET-REDACTION CHECKS FAILED" >&2
    exit 1
fi
