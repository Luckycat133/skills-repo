#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_ROOT="$(mktemp -d /tmp/agent-skills-migration-test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

TEST_HOME="$TMP_ROOT/home"
VALID_SKILL="$TEST_HOME/.agents/skills/demo-skill"
NON_SKILL="$TEST_HOME/.agents/skills/not-a-skill"
PRIVATE_STATE="$TEST_HOME/.codex/sessions"
OUTPUT="$TMP_ROOT/dry-run.txt"

# Codeium is a legacy product name, not a standalone Skills/MCP/config target.
# A generic .codeium directory must remain manual/unsupported rather than being
# interpreted as a project Skills tree or copied as opaque project config.
assert_codeium_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path codeium "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: codeium/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_codeium_path global ""
assert_codeium_path project ""
assert_codeium_path project-skills ""
assert_codeium_path rules ""
assert_codeium_path mcp ""
assert_codeium_path project-mcp ""
assert_codeium_path project-config ""
assert_codeium_path config ""

mkdir -p "$TMP_ROOT/codeium-project/.codeium/skills/legacy-skill"
printf '%s\n' '---' 'name: legacy-skill' 'description: legacy fixture' '---' > "$TMP_ROOT/codeium-project/.codeium/skills/legacy-skill/SKILL.md"
CODEIUM_SKILLS_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source codeium --target cursor --workspace "$TMP_ROOT/codeium-project" --objects skills --dry-run 2>&1)"
grep -Fq 'source directory does not exist:' <<< "$CODEIUM_SKILLS_OUTPUT"

CODEIUM_PROJECT_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source codeium --target cursor --workspace "$TMP_ROOT/codeium-project" --objects project --dry-run 2>&1)"
grep -Fq 'source IDE does not support project-level configuration' <<< "$CODEIUM_PROJECT_OUTPUT"

# Pieces is a PiecesOS-backed MCP server/provider, not a file-backed IDE
# configuration host. Exercise every path object and the unsupported object
# boundary against stale-looking ~/.pieces/.pieces fixtures containing a fake
# skill, rules, MCP JSON, and a secret. Nothing may be copied or created.
assert_pieces_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path pieces "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: pieces/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

for pieces_object in global project project-skills rules mcp project-mcp project-config config; do
    assert_pieces_path "$pieces_object" ""
done

PIECES_PROJECT="$TMP_ROOT/pieces-project"
mkdir -p "$TEST_HOME/.pieces/skills/legacy-skill" "$PIECES_PROJECT/.pieces/rules"
printf '%s\n' '---' 'name: legacy-pieces-skill' 'description: stale fixture' '---' > "$TEST_HOME/.pieces/skills/legacy-skill/SKILL.md"
printf '%s\n' 'Use this stale Pieces rule.' > "$PIECES_PROJECT/.pieces/rules/legacy.md"
printf '%s\n' '{"mcpServers":{"legacy":{"command":"node","env":{"API_KEY":"__pieces_do_not_copy_fixture__"}}}}' > "$PIECES_PROJECT/.pieces/mcp.json"
PIECES_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source pieces --target cursor --workspace "$PIECES_PROJECT" \
    --objects skills,rules,prompts,mcp,config,project --yes --strategy overwrite 2>&1)"
for pieces_object in skills rules prompts mcp config project; do
    grep -Fq "${pieces_object}:" <<< "$PIECES_OUTPUT" || {
        echo "FAIL: Pieces ${pieces_object} boundary did not report a status"
        exit 1
    }
done
grep -Fq 'Pieces' <<< "$PIECES_OUTPUT"
[[ ! -e "$PIECES_PROJECT/.cursor" ]] || {
    echo "FAIL: unsupported Pieces fixture created a Cursor target"
    exit 1
}
grep -Fq '__pieces_do_not_copy_fixture__' "$PIECES_PROJECT/.pieces/mcp.json"

PIECES_TARGET_HOME="$TMP_ROOT/pieces-target-home"
PIECES_TARGET_PROJECT="$TMP_ROOT/pieces-target-project"
mkdir -p "$PIECES_TARGET_PROJECT/.codex" "$PIECES_TARGET_HOME"
PIECES_TARGET_OUTPUT="$(HOME="$PIECES_TARGET_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source codex --target pieces --workspace "$PIECES_TARGET_PROJECT" \
    --objects skills,rules,prompts,mcp,config,project --yes --strategy overwrite 2>&1)"
grep -Fq 'Pieces' <<< "$PIECES_TARGET_OUTPUT"
[[ ! -e "$PIECES_TARGET_HOME/.pieces" && ! -e "$PIECES_TARGET_PROJECT/.pieces" ]] || {
    echo "FAIL: unsupported Pieces target created a guessed path"
    exit 1
}

mkdir -p "$VALID_SKILL" "$NON_SKILL" "$PRIVATE_STATE"

printf '%s\n' '---' 'name: demo-skill' 'description: Isolated migration fixture.' '---' > "$VALID_SKILL/SKILL.md"
printf '%s\n' 'must not migrate' > "$NON_SKILL/state.txt"
printf '%s\n' 'private session fixture' > "$PRIVATE_STATE/session.jsonl"

assert_path() {
    local object="$1"
    local expected="$2"
    local actual

    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path codex "$object")"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: codex/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_path project-skills ".agents/skills"
assert_path mcp "~/.codex/config.toml"
assert_path config "~/.codex/config.toml"

# Replit keeps project Agent Skills and Agent instructions separate from app
# configuration. Runtime files (.replit/replit.nix) must never be treated as
# skills or copied by the generic project/config migration.
assert_replit_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path replit "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: replit/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_replit_path global ""
assert_replit_path project ".replit"
assert_replit_path project-skills ".agents/skills"
assert_replit_path rules "replit.md"
assert_replit_path project-mcp ""
assert_replit_path project-config ".replit"
assert_replit_path mcp ""
assert_replit_path config ""

REPLIT_PROJECT="$TMP_ROOT/replit-project"
mkdir -p "$REPLIT_PROJECT/.agents/skills/demo-skill"
printf '%s\n' '---' 'name: demo-skill' 'description: Replit fixture skill.' '---' > "$REPLIT_PROJECT/.agents/skills/demo-skill/SKILL.md"
printf '%s\n' '# Replit fixture instructions' > "$REPLIT_PROJECT/replit.md"
printf '%s\n' 'run = "npm start"' > "$REPLIT_PROJECT/.replit"
printf '%s\n' '{ pkgs }: { deps = []; }' > "$REPLIT_PROJECT/replit.nix"

REPLIT_PROJECT_OUTPUT="$(bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source replit --target claude --workspace "$REPLIT_PROJECT" --objects project --dry-run 2>&1)"
grep -Fq 'Replit project app/runtime files (.replit, replit.nix) are manual' <<< "$REPLIT_PROJECT_OUTPUT"
REPLIT_CONFIG_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source replit --target claude --workspace "$REPLIT_PROJECT" --objects config --dry-run 2>&1)"
grep -Fq 'Replit app configuration (.replit/replit.nix) is project-scoped and manual' <<< "$REPLIT_CONFIG_OUTPUT"
REPLIT_MCP_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source replit --target claude --workspace "$REPLIT_PROJECT" --objects mcp --dry-run 2>&1)"
grep -Fq 'Replit MCP connections are cloud/UI-managed through Integrations; no local MCP file is migrated' <<< "$REPLIT_MCP_OUTPUT"
printf '%s' '# source instructions' > "$REPLIT_PROJECT/CLAUDE.md"
REPLIT_RULE_OUTPUT="$(bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target replit --workspace "$REPLIT_PROJECT" \
    --objects rules --yes --strategy overwrite 2>&1)"
grep -Fq 'Replit replit.md is a project-root living document maintained by Agent; automatic overwrite is disabled' <<< "$REPLIT_RULE_OUTPUT"
grep -Fq '# Replit fixture instructions' "$REPLIT_PROJECT/replit.md"
! grep -Fq '# source instructions' "$REPLIT_PROJECT/replit.md"

assert_continue_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path continue "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: continue/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

# Continue documents YAML config/block directories, not generic skills or a
# root CONTINUE.md rules file. Its MCP block directory is diagnostic-only;
# the generic JSON converter must not copy JSON into YAML or vice versa.
assert_continue_path global ""
assert_continue_path project ".continue"
assert_continue_path project-skills ""
assert_continue_path rules ".continue/rules"
assert_continue_path project-mcp ".continue/mcpServers"
assert_continue_path config "~/.continue/config.yaml"

CONTINUE_OUTPUT="$(bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target continue --objects mcp,config --dry-run 2>&1)"
grep -Fq 'Continue uses YAML/array configuration; automatic MCP/config migration is unsupported' <<< "$CONTINUE_OUTPUT"

# PearAI's official repositories document VS Code/Continue provenance, but no
# PearAI-owned portable object paths or MCP root/schema. Every automatic
# object must therefore fail closed; in particular, do not invent ~/.pearai,
# .pearai, .pearairules, config.json, or a mcpServers root.
assert_pearai_path() {
    local object="$1"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path pearai "$object" 2>/dev/null || true)"
    if [[ -n "$actual" ]]; then
        echo "FAIL: pearai/${object} must be unsupported, got '${actual}'" >&2
        exit 1
    fi
}

for pearai_object in global project project-skills rules mcp project-mcp project-config config; do
    assert_pearai_path "$pearai_object"
done

PEARAI_SOURCE="$TMP_ROOT/pearai-source"
mkdir -p "$PEARAI_SOURCE/.agents/skills/demo-skill"
printf '%s\n' '{"mcpServers":{"fixture":{"command":"node","args":["server.js"]}}}' > "$TEST_HOME/.claude.json"
printf '%s\n' '{"provider":"fixture"}' > "$TEST_HOME/.codex/config.toml"
PEARAI_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source codex --target pearai --workspace "$PEARAI_SOURCE" \
    --objects skills,rules,prompts,mcp,config,project --yes --strategy overwrite 2>&1)"
grep -Fq 'mcp:' <<< "$PEARAI_OUTPUT"
grep -Fq 'config:' <<< "$PEARAI_OUTPUT"
[[ ! -e "$TEST_HOME/.pearai" ]] || {
    echo "FAIL: PearAI fixture created an undocumented ~/.pearai target" >&2
    exit 1
}
[[ ! -e "$PEARAI_SOURCE/.pearai" ]] || {
    echo "FAIL: PearAI fixture created an undocumented .pearai target" >&2
    exit 1
}

# Supermaven is a host-editor completion plugin, not a portable agent
# configuration surface. The first-party maintainer-described ~/.supermaven
# tree is runtime/binary storage and .supermavenignore only excludes files
# from repository indexing; neither is a Skills/rules/config target.
assert_supermaven_path() {
    local object="$1"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path supermaven "$object" 2>/dev/null || true)"
    if [[ -n "$actual" ]]; then
        echo "FAIL: supermaven/${object} must be unsupported/empty, got '${actual}'" >&2
        exit 1
    fi
}

for supermaven_object in global project project-skills rules mcp project-mcp project-config config; do
    assert_supermaven_path "$supermaven_object"
done

SUPERMAVEN_HOME="$TMP_ROOT/supermaven-home"
SUPERMAVEN_PROJECT="$TMP_ROOT/supermaven-project"
mkdir -p "$SUPERMAVEN_HOME/.supermaven/binary/fixture/darwin-arm64" "$SUPERMAVEN_PROJECT/.supermaven"
printf '%s\n' 'runtime binary fixture' > "$SUPERMAVEN_HOME/.supermaven/binary/fixture/darwin-arm64/sm-agent"
printf '%s\n' '*.secret' > "$SUPERMAVEN_PROJECT/.supermavenignore"
printf '%s\n' 'legacy project state' > "$SUPERMAVEN_PROJECT/.supermaven/state.json"

SUPERMAVEN_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source codex --target supermaven --workspace "$SUPERMAVEN_PROJECT" \
    --objects skills,rules,prompts,mcp,config,project --yes --strategy overwrite 2>&1)"
for supermaven_message in \
    'Supermaven has no documented portable Agent Skills directory' \
    'Supermaven has no documented portable instruction/rules file' \
    'Supermaven has no documented portable prompt-template directory' \
    'Supermaven has no documented portable MCP file or server schema' \
    'Supermaven has no documented portable standalone config file' \
    'Supermaven has no documented portable project configuration namespace'; do
    grep -Fq "$supermaven_message" <<< "$SUPERMAVEN_OUTPUT" || {
        echo "FAIL: missing Supermaven manual boundary: $supermaven_message"
        exit 1
    }
done
[[ ! -e "$TEST_HOME/.supermaven/SKILL.md" ]] || {
    echo "FAIL: unsupported Supermaven target created a Skills file"
    exit 1
}
[[ -f "$SUPERMAVEN_HOME/.supermaven/binary/fixture/darwin-arm64/sm-agent" ]] || {
    echo "FAIL: Supermaven runtime fixture was altered"
    exit 1
}
[[ "$(cat "$SUPERMAVEN_PROJECT/.supermavenignore")" == '*.secret' ]] || {
    echo "FAIL: .supermavenignore fixture was altered"
    exit 1
}

printf '%s\n' '{"mcpServers":{"sensitive":{"command":"node","args":[],"env":{"API_KEY":"__supermaven_inert_fixture__"}}}}' > "$TEST_HOME/.claude.json"
SUPERMAVEN_MCP_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target supermaven --objects mcp --yes --strategy overwrite 2>&1)"
grep -Fq 'Supermaven has no documented portable MCP file or server schema' <<< "$SUPERMAVEN_MCP_OUTPUT"
grep -Fq '__supermaven_inert_fixture__' "$TEST_HOME/.claude.json" || {
    echo "FAIL: unsupported Supermaven MCP boundary modified the source secret"
    exit 1
}
[[ ! -e "$TEST_HOME/.supermaven" ]] || {
    echo "FAIL: unsupported Supermaven MCP boundary created ~/.supermaven"
    exit 1
}

SUPERMAVEN_SOURCE_OUTPUT="$(HOME="$SUPERMAVEN_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source supermaven --target cursor --workspace "$SUPERMAVEN_PROJECT" \
    --objects skills,rules,prompts,mcp,config,project --yes --strategy overwrite 2>&1)"
grep -Fq 'Supermaven has no documented portable Agent Skills directory' <<< "$SUPERMAVEN_SOURCE_OUTPUT"
[[ ! -e "$SUPERMAVEN_PROJECT/.cursor" ]] || {
    echo "FAIL: unsupported Supermaven source created a Cursor target"
    exit 1
}

# Blackbox's current first-party CLI docs document only project Skills at
# .blackbox/skills/<name>/SKILL.md. There is no published global Skills path,
# rules/prompts directory, MCP file/root, or configure-file path. Exercise the
# one supported diagnostic object and verify every unsupported boundary stays
# manual without copying secrets or the mixed .blackbox namespace.
assert_blackbox_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path blackbox "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: blackbox/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_blackbox_path global ""
assert_blackbox_path project ".blackbox"
assert_blackbox_path project-skills ".blackbox/skills"
assert_blackbox_path rules ""
assert_blackbox_path mcp ""
assert_blackbox_path project-mcp ""
assert_blackbox_path project-config ""
assert_blackbox_path config ""

BLACKBOX_HOME="$TMP_ROOT/blackbox-home"
BLACKBOX_PROJECT="$TMP_ROOT/blackbox-project"
BLACKBOX_TARGET="$TMP_ROOT/blackbox-target"
mkdir -p "$BLACKBOX_HOME/.agents/skills/from-codex" "$BLACKBOX_HOME/.codex" "$BLACKBOX_PROJECT/.blackbox/skills/from-blackbox"
printf '%s\n' '---' 'name: from-codex' 'description: source fixture' '---' > "$BLACKBOX_HOME/.agents/skills/from-codex/SKILL.md"
printf '%s\n' '---' 'name: from-blackbox' 'description: Blackbox project fixture' '---' > "$BLACKBOX_PROJECT/.blackbox/skills/from-blackbox/SKILL.md"
# NOTE: Placeholder strings use clearly-fake values (not real provider prefixes
# or "secret" / "key" keywords) so that secret-pattern scanners do not flag the
# fixtures as exposed credentials. The redactor still matches these values via
# the SECRET_KEY_RE keyword check on the KEY NAME; the VALUE side is inert.
printf '%s\n' '{"apiKey":"__test_placeholder_value__"}' > "$BLACKBOX_PROJECT/.blackbox/private-state.json"
printf '%s\n' 'provider = "codex-fixture"' 'apiKey = "__test_placeholder_value__"' > "$BLACKBOX_HOME/.codex/config.toml"

BLACKBOX_TARGET_OUTPUT="$(HOME="$BLACKBOX_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source codex --target blackbox --workspace "$BLACKBOX_TARGET" \
    --objects skills,rules,prompts,mcp,config,project --yes --strategy overwrite 2>&1)"
grep -Fq 'Blackbox' <<< "$BLACKBOX_TARGET_OUTPUT"
grep -Fq 'project .blackbox/skills' <<< "$BLACKBOX_TARGET_OUTPUT"
[[ ! -e "$BLACKBOX_TARGET/.blackbox" ]] || {
    echo "FAIL: unsupported Blackbox target created an opaque .blackbox namespace"
    exit 1
}

BLACKBOX_SOURCE_OUTPUT="$(HOME="$BLACKBOX_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source blackbox --target codex --workspace "$BLACKBOX_PROJECT" \
    --objects skills,project --yes --strategy overwrite 2>&1)"
grep -Fq 'Blackbox' <<< "$BLACKBOX_SOURCE_OUTPUT"
[[ ! -e "$BLACKBOX_HOME/.agents/skills/from-blackbox" ]] || {
    echo "FAIL: Blackbox source project Skills were copied as global Skills"
    exit 1
}
grep -Fq '__test_placeholder_value__' "$BLACKBOX_PROJECT/.blackbox/private-state.json" || {
    echo "FAIL: Blackbox placeholder fixture was modified (redactor must blank only the value, not the key)"
    exit 1
}

# Gemini CLI uses dedicated Skills paths but a mixed .gemini project namespace.
# MCP is JSON at both user and project scope; the generic mapper converts only
# the user file, validates Gemini's endpoint/alias schema, and redacts secrets.
# Commands are TOML and whole settings/project namespaces are target-specific,
# so prompt/config/project transfers must remain manual.
assert_gemini_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path gemini-cli "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: gemini-cli/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_gemini_path global "~/.gemini/skills"
assert_gemini_path project ".gemini"
assert_gemini_path project-skills ".gemini/skills"
assert_gemini_path rules "GEMINI.md"
assert_gemini_path mcp "~/.gemini/settings.json"
assert_gemini_path project-mcp ".gemini/settings.json"
assert_gemini_path project-config ".gemini/settings.json"
assert_gemini_path config "~/.gemini/settings.json"

GEMINI_PROJECT="$TMP_ROOT/gemini-project"
mkdir -p "$GEMINI_PROJECT/.gemini/skills/demo-skill" "$GEMINI_PROJECT/.gemini/commands" "$GEMINI_PROJECT/.gemini/agents"
mkdir -p "$TEST_HOME/.gemini/skills/demo-skill"
printf '%s\n' '---' 'name: demo-skill' 'description: Gemini CLI fixture skill.' '---' > "$TEST_HOME/.gemini/skills/demo-skill/SKILL.md"
printf '%s\n' '# Gemini CLI fixture context' > "$GEMINI_PROJECT/GEMINI.md"
printf '%s\n' 'description = "fixture command"' 'prompt = "Review {{args}}"' > "$GEMINI_PROJECT/.gemini/commands/review.toml"
printf '%s\n' '---' 'name: fixture-agent' 'description: fixture subagent' '---' 'Review the fixture.' > "$GEMINI_PROJECT/.gemini/agents/fixture-agent.md"
printf '%s\n' '---' 'name: demo-skill' 'description: project fixture skill.' '---' > "$GEMINI_PROJECT/.gemini/skills/demo-skill/SKILL.md"

GEMINI_SKILLS_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source gemini-cli --target cursor --workspace "$GEMINI_PROJECT" --objects skills --dry-run 2>&1)"
grep -Fq 'successfully migrated 1 skills' <<< "$GEMINI_SKILLS_OUTPUT"
grep -Fq "$TEST_HOME/.gemini/skills/demo-skill" <<< "$GEMINI_SKILLS_OUTPUT"

GEMINI_RULE_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source gemini-cli --target openclaw --workspace "$GEMINI_PROJECT" --objects rules --dry-run 2>&1)"
grep -Fq 'GEMINI.md' <<< "$GEMINI_RULE_OUTPUT"
grep -Fq 'AGENTS.md' <<< "$GEMINI_RULE_OUTPUT"

for gemini_manual_object in prompts config project; do
    GEMINI_MANUAL_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
        --source gemini-cli --target cursor --workspace "$GEMINI_PROJECT" --objects "$gemini_manual_object" --dry-run 2>&1)"
    grep -Fq '[WARN]' <<< "$GEMINI_MANUAL_OUTPUT"
done
GEMINI_TARGET_MANUAL_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target gemini-cli --workspace "$GEMINI_PROJECT" --objects prompts --dry-run 2>&1)"
grep -Fq 'Gemini CLI commands use TOML' <<< "$GEMINI_TARGET_MANUAL_OUTPUT"

mkdir -p "$TEST_HOME/.gemini"
printf '%s\n' '{"mcpServers":{"local-server":{"command":"node","args":["server.js","--token","do-not-copy"],"env":{"GEMINI_API_KEY":"do-not-copy"}},"http-server":{"httpUrl":"https://example.invalid/mcp","headers":{"Authorization":"Bearer do-not-copy"},"includeTools":["safe"],"timeout":5000}}}' > "$TEST_HOME/.claude.json"
HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target gemini-cli --workspace "$GEMINI_PROJECT" --objects mcp --yes --strategy overwrite >/dev/null
python3 - "$TEST_HOME/.gemini/settings.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert set(data["mcpServers"]) == {"local-server", "http-server"}
assert data["mcpServers"]["local-server"]["env"]["GEMINI_API_KEY"] == ""
assert data["mcpServers"]["local-server"]["args"][-1] == ""
assert data["mcpServers"]["http-server"]["headers"]["Authorization"] == ""
assert data["mcpServers"]["http-server"]["httpUrl"] == "https://example.invalid/mcp"
PY

# Invalid input must be rejected before overwrite mutates the last valid
# shared settings file.
GEMINI_TARGET_BEFORE="$TMP_ROOT/gemini-settings-before.json"
cp "$TEST_HOME/.gemini/settings.json" "$GEMINI_TARGET_BEFORE"
printf '%s\n' '{"mcpServers":{"bad_server":{"command":"node","args":[]}}}' > "$TEST_HOME/.claude.json"
GEMINI_INVALID_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target gemini-cli --workspace "$GEMINI_PROJECT" --objects mcp --yes --strategy overwrite 2>&1)"
grep -Fq 'Gemini CLI MCP schema is invalid or ambiguous' <<< "$GEMINI_INVALID_OUTPUT"
cmp -s "$GEMINI_TARGET_BEFORE" "$TEST_HOME/.gemini/settings.json" || {
    echo "FAIL: invalid Gemini MCP alias mutated the existing settings file"
    exit 1
}

printf '%s\n' '{"mcpServers":{"fixture-server":{"command":"node","args":[]}}}' > "$TEST_HOME/.gemini/settings.json"
HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source gemini-cli --target cursor --workspace "$GEMINI_PROJECT" --objects mcp --yes --strategy overwrite >/dev/null
python3 - "$TEST_HOME/.cursor/mcp.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert set(data["mcpServers"]) == {"fixture-server"}
PY

mkdir -p "$TEST_HOME/.config/goose"
printf '%s\n' 'extensions:' '- fixture:' '-   name: fixture' > "$TEST_HOME/.config/goose/config.yaml"
NON_JSON_GEMINI_PROJECT="$TMP_ROOT/non-json-gemini"
mkdir -p "$NON_JSON_GEMINI_PROJECT"
NON_JSON_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source goose-cli --target gemini-cli --workspace "$NON_JSON_GEMINI_PROJECT" --objects mcp --yes --strategy overwrite 2>&1 || true)"
grep -Fq 'Goose config.yaml uses YAML extensions; automatic MCP migration is unsupported' <<< "$NON_JSON_OUTPUT"
[[ ! -e "$NON_JSON_GEMINI_PROJECT/.gemini/settings.json" ]] || {
    echo "FAIL: unsupported non-JSON Gemini MCP conversion created a target"
    exit 1
}

# Goose CLI current docs separate Agent Skills, context hints, recipes,
# prompt templates, Memory, and YAML extension configuration. Verify every
# mapper object path and exercise the safe Skills/rules paths plus the
# YAML/secrets fail-closed boundaries. No Goose binary or live IDE is used.
assert_goose_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path goose-cli "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: goose-cli/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_goose_path global "~/.agents/skills"
assert_goose_path project ".goose"
assert_goose_path project-skills ".agents/skills"
assert_goose_path rules ".goosehints"
assert_goose_path mcp "~/.config/goose/config.yaml"
assert_goose_path project-mcp ""
assert_goose_path project-config ""
assert_goose_path config "~/.config/goose/config.yaml"

GOOSE_PROJECT="$TMP_ROOT/goose-project"
mkdir -p "$GOOSE_PROJECT/.goose/recipes" "$GOOSE_PROJECT/.goose/memory" "$GOOSE_PROJECT/.agents/skills/goose-project-skill" "$GOOSE_PROJECT/.claude/commands"
printf '%s\n' 'title: Goose fixture' 'description: Recipe is not a skill.' 'instructions: Use the fixture.' > "$GOOSE_PROJECT/.goose/recipes/fixture.yaml"
printf '%s\n' '{"category":"fixture","data":"review manually"}' > "$GOOSE_PROJECT/.goose/memory/fixture.json"
printf '%s\n' '---' 'name: goose-project-skill' 'description: Goose project skill fixture.' '---' > "$GOOSE_PROJECT/.agents/skills/goose-project-skill/SKILL.md"
printf '%s\n' '# Claude fixture command' > "$GOOSE_PROJECT/.claude/commands/fixture.md"
printf '%s\n' '# Goose fixture rules' > "$GOOSE_PROJECT/.goosehints"
printf '%s\n' '# Source rules fixture' > "$GOOSE_PROJECT/CLAUDE.md"

# A global Skills migration to Goose must land in ~/.agents/skills, never in
# ~/.config/goose or the mixed local .goose namespace. Keep this fixture in a
# separate HOME so the later Codex isolation assertion remains one-skill-only.
GOOSE_SKILL_HOME="$TMP_ROOT/goose-skill-home"
mkdir -p "$GOOSE_SKILL_HOME/.cursor/skills/goose-global-skill"
printf '%s\n' '---' 'name: goose-global-skill' 'description: Goose global skill fixture.' '---' > "$GOOSE_SKILL_HOME/.cursor/skills/goose-global-skill/SKILL.md"
HOME="$GOOSE_SKILL_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source cursor --target goose-cli --objects skills --yes --strategy overwrite >/dev/null
[[ -f "$GOOSE_SKILL_HOME/.agents/skills/goose-global-skill/SKILL.md" ]] || {
    echo "FAIL: Goose global Agent Skill was not written to ~/.agents/skills" >&2
    exit 1
}
[[ ! -e "$GOOSE_SKILL_HOME/.config/goose/goose-global-skill" ]] || {
    echo "FAIL: Goose global Skill leaked into ~/.config/goose" >&2
    exit 1
}

# Local .goose is a mixed recipes/memory namespace, so the generic project
# object must fail closed and leave the target untouched.
GOOSE_PROJECT_OUTPUT="$(bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source goose-cli --target cursor --workspace "$GOOSE_PROJECT" --objects project --dry-run 2>&1)"
grep -Fq 'Goose .goose contains scoped recipes and memory, not a portable project config tree' <<< "$GOOSE_PROJECT_OUTPUT"

# Local hint files are the supported low-risk Goose rules object. A source
# Markdown rules file can be prepared for Goose's .goosehints target.
GOOSE_RULE_OUTPUT="$(bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target goose-cli --workspace "$GOOSE_PROJECT" --objects rules --dry-run 2>&1)"
grep -Fq '.goosehints' <<< "$GOOSE_RULE_OUTPUT"

# Goose prompt templates are global config files and slash commands are YAML
# config entries; the project prompt copier must report manual and create no
# .goose/prompts directory.
GOOSE_PROMPT_OUTPUT="$(bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target goose-cli --workspace "$GOOSE_PROJECT" --objects prompts --dry-run 2>&1)"
grep -Fq 'Goose prompt templates are global files and slash commands are config.yaml entries' <<< "$GOOSE_PROMPT_OUTPUT"
[[ ! -e "$GOOSE_PROJECT/.goose/prompts" ]] || {
    echo "FAIL: Goose prompt boundary created unsupported project prompt directory" >&2
    exit 1
}

# Goose MCP/config are YAML and must not receive JSON root-key conversion or
# verbatim JSON copied into config.yaml. Test both directions and preserve the
# source sensitive-key YAML untouched while no target file is created.
# NOTE: fixture VALUES are inert placeholders (no "secret"/"key"/"live"
# substrings) so secret-pattern scanners do not flag them; the sensitive-key
# semantics come from the KEY NAMES (API_KEY / OPENAI_API_KEY) only.
mkdir -p "$TEST_HOME/.config/goose"
printf '%s\n' 'extensions:' '  fixture:' '    type: stdio' '    cmd: node' '    args: [server.js]' '    envs:' '      API_KEY: __goose_inert_fixture__' '    enabled: true' > "$TEST_HOME/.config/goose/config.yaml"
printf '%s\n' 'OPENAI_API_KEY: __goose_file_inert_fixture__' > "$TEST_HOME/.config/goose/secrets.yaml"
printf '%s\n' '{"mcpServers":{"fixture":{"command":"node","args":["server.js"],"env":{"API_KEY":"__json_inert_fixture__"}}}}' > "$TEST_HOME/.claude.json"
GOOSE_MCP_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target goose-cli --objects mcp --yes --strategy overwrite 2>&1)"
grep -Fq 'Goose config.yaml uses YAML extensions; automatic MCP migration is unsupported' <<< "$GOOSE_MCP_OUTPUT"
[[ "$(cat "$TEST_HOME/.config/goose/config.yaml")" == *'__goose_inert_fixture__'* ]] || {
    echo "FAIL: Goose source config was modified during fail-closed MCP audit" >&2
    exit 1
}
[[ ! -e "$TEST_HOME/.config/goose/config.yaml.bak."* ]] || {
    echo "FAIL: Goose MCP boundary unexpectedly created a config backup" >&2
    exit 1
}
GOOSE_CONFIG_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target goose-cli --objects config --yes --strategy overwrite 2>&1)"
grep -Fq 'Goose config.yaml is YAML and combines provider/extensions/settings; automatic config migration is unsupported' <<< "$GOOSE_CONFIG_OUTPUT"
[[ "$(cat "$TEST_HOME/.config/goose/secrets.yaml")" == *'__goose_file_inert_fixture__'* ]] || {
    echo "FAIL: Goose secrets fixture was modified during config audit" >&2
    exit 1
}

# Roo Code has native skill directories and a documented project MCP file, but
# global MCP is extension-storage/UI managed and therefore manual-only.
assert_roo_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path roo-code "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: roo-code/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_roo_path global "~/.roo/skills"
assert_roo_path project ".roo"
assert_roo_path project-skills ".roo/skills"
assert_roo_path project-mcp ".roo/mcp.json"
assert_roo_path mcp ""
assert_roo_path rules ".roorules"

ROO_MCP_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target roo-code --objects mcp --yes --strategy overwrite 2>&1)"
grep -Fq 'Roo Code global MCP is extension-storage/UI managed' <<< "$ROO_MCP_OUTPUT"

# Aider has YAML config and conventions, not native skills or MCP paths.
assert_aider_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path aider "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: aider/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_aider_path global ""
assert_aider_path project ".aider.conf.yml"
assert_aider_path project-skills ""
assert_aider_path rules "CONVENTIONS.md"
assert_aider_path mcp ""
assert_aider_path project-mcp ""
assert_aider_path project-config ""
assert_aider_path config "~/.aider.conf.yml"

mkdir -p "$TMP_ROOT/aider-project"
printf '%s\n' 'Follow the fixture conventions.' > "$TMP_ROOT/aider-project/CLAUDE.md"
AIDER_RULE_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target aider --workspace "$TMP_ROOT/aider-project" --objects rules --dry-run 2>&1)"
grep -Fq 'CONVENTIONS.md' <<< "$AIDER_RULE_OUTPUT"
grep -Fq 'read:' <<< "$AIDER_RULE_OUTPUT"

AIDER_CONFIG_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target aider --workspace "$TMP_ROOT/aider-project" --objects config --dry-run 2>&1)"
grep -Fq 'Aider .aider.conf.yml' <<< "$AIDER_CONFIG_OUTPUT"
[[ ! -e "$TMP_ROOT/aider-project/.aider.conf.yml" ]] || {
    echo "FAIL: Aider YAML config boundary created a file during dry-run" >&2
    exit 1
}

# Cline stores MCP settings in the VS Code extension globalStorage
# (cline_mcp_settings.json under saoudrizwan.claude-dev/settings/). A legacy
# ~/.cline/mcp.json CLI alternative may exist; when both are present without
# CLINE_MCP_PATH, global migration is manual. Project MCP is .cline/mcp.json.
case "$(uname -s)" in
    Darwin) CLINE_MCP_EXPECTED="~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
            CLINE_MCP_TARGET="$TEST_HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json" ;;
    Linux)  CLINE_MCP_EXPECTED="~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
            CLINE_MCP_TARGET="$TEST_HOME/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json" ;;
    *)      CLINE_MCP_EXPECTED="~/AppData/Roaming/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
            CLINE_MCP_TARGET="$TEST_HOME/AppData/Roaming/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json" ;;
esac

assert_cline_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path cline "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: cline/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_cline_path global "~/.cline/skills"
assert_cline_path project ""
assert_cline_path project-skills ".cline/skills"
assert_cline_path rules ".clinerules"
assert_cline_path project-mcp ".cline/mcp.json"
assert_cline_path config ""
assert_cline_path mcp "$CLINE_MCP_EXPECTED"

printf '%s\n' '{"mcpServers":{"local":{"command":"node","args":["server.js"],"env":{"API_KEY":"do-not-copy"}},"remote":{"url":"https://example.invalid/mcp","transportType":"sse"}}}' > "$TEST_HOME/.claude.json"
HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target cline --objects mcp --yes --strategy overwrite >/dev/null
python3 - "$CLINE_MCP_TARGET" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert set(data["mcpServers"]) == {"local", "remote"}
assert data["mcpServers"]["local"]["command"] == "node"
assert data["mcpServers"]["local"]["env"]["API_KEY"] == ""
assert data["mcpServers"]["remote"]["transportType"] == "sse"
PY

CLINE_TARGET_BEFORE="$TMP_ROOT/cline-mcp-before.json"
cp "$CLINE_MCP_TARGET" "$CLINE_TARGET_BEFORE"
printf '%s\n' '{"mcpServers":{"ambiguous":{"args":["server.js"]}}}' > "$TEST_HOME/.claude.json"
INVALID_CLINE_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target cline --objects mcp --yes --strategy overwrite 2>&1)"
grep -Fq 'Cline MCP mcpServers schema is invalid or ambiguous' <<< "$INVALID_CLINE_OUTPUT" || {
    echo "FAIL: invalid Cline mcpServers entry was not rejected" >&2
    exit 1
}
cmp -s "$CLINE_TARGET_BEFORE" "$CLINE_MCP_TARGET" || {
    echo "FAIL: invalid Cline MCP conversion mutated the existing target" >&2
    exit 1
}

# When both the globalStorage MCP settings and the legacy ~/.cline/mcp.json CLI
# alternative exist, the mapper refuses an ambiguous global migration.
rm -f "$CLINE_MCP_TARGET"
mkdir -p "$(dirname "$CLINE_MCP_TARGET")"
CLINE_ALT_TARGET="$TEST_HOME/.cline/mcp.json"
mkdir -p "$TEST_HOME/.cline"
printf '%s\n' '{"mcpServers":{}}' > "$CLINE_MCP_TARGET"
printf '%s\n' '{"mcpServers":{}}' > "$CLINE_ALT_TARGET"
AMBIGUOUS_CLINE_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target cline --objects mcp --yes --strategy overwrite 2>&1)"
grep -Fq 'Cline has both the globalStorage MCP settings' <<< "$AMBIGUOUS_CLINE_OUTPUT" || {
    echo "FAIL: Cline globalStorage+alternative ambiguity was not reported" >&2
    exit 1
}
rm -f "$CLINE_MCP_TARGET" "$CLINE_ALT_TARGET"

# The CLI reference also documents project .cline/mcp.json. Exercise the
# explicit project scope separately from the global/CLI ambiguity above.
CLINE_PROJECT="$TMP_ROOT/cline-project"
mkdir -p "$CLINE_PROJECT"
printf '%s\n' '{"mcpServers":{"project-server":{"command":"node","args":["server.js"],"env":{"PROJECT_TOKEN":"do-not-copy"}}}}' > "$CLINE_PROJECT/.mcp.json"
HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target cline --workspace "$CLINE_PROJECT" \
    --scope project --objects mcp --yes --strategy overwrite >/dev/null
python3 - "$CLINE_PROJECT/.cline/mcp.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["mcpServers"]["project-server"]["env"]["PROJECT_TOKEN"] == ""
PY

# Amazon Q keeps IDE MCP, project rules, prompts, and CLI agents in separate
# scopes. The current IDE guide names default.json and mcp.json as legacy;
# another Q surface names agents/default.json without a version discriminator.
# The mapper uses default.json for fresh installs, preserves an existing legacy
# mcp.json, and fails closed when only agents/default.json is present.
assert_amazon_q_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path amazon-q "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: amazon-q/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_amazon_q_path global ""
assert_amazon_q_path project ".amazonq"
assert_amazon_q_path project-skills ""
assert_amazon_q_path rules ".amazonq/rules"
assert_amazon_q_path mcp "~/.aws/amazonq/default.json"
assert_amazon_q_path project-mcp ".amazonq/default.json"
assert_amazon_q_path config ""

mkdir -p "$TMP_ROOT/project/.amazonq/rules" "$TEST_HOME/.aws/amazonq"
printf '%s\n' 'Use the fixture rule.' > "$TMP_ROOT/project/.amazonq/rules/style.md"
Q_RULE_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --source amazon-q --target cursor --workspace "$TMP_ROOT/project" --objects rules --dry-run 2>&1)"
grep -Fq 'Amazon Q rules use .amazonq/rules/*.md; manual migration required' <<< "$Q_RULE_OUTPUT"
Q_PROJECT_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --source amazon-q --target cursor --workspace "$TMP_ROOT/project" --objects project --dry-run 2>&1)"
grep -Fq 'Amazon Q project namespace .amazonq is manual' <<< "$Q_PROJECT_OUTPUT"
Q_MCP_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --source amazon-q --target cursor --workspace "$TMP_ROOT/project" --objects mcp --dry-run 2>&1)"
grep -Fq 'Amazon Q: standard IDE MCP uses' <<< "$Q_MCP_OUTPUT"

# Existing legacy configuration is selected instead of creating a second
# default.json store; an agents/default.json-only installation is manual.
printf '%s\n' '{"mcpServers":{}}' > "$TEST_HOME/.aws/amazonq/mcp.json"
assert_amazon_q_path mcp "~/.aws/amazonq/mcp.json"
rm -f "$TEST_HOME/.aws/amazonq/mcp.json"
mkdir -p "$TEST_HOME/.aws/amazonq/agents"
printf '%s\n' '{"mcpServers":{}}' > "$TEST_HOME/.aws/amazonq/agents/default.json"
Q_AGENT_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --source amazon-q --target cursor --workspace "$TMP_ROOT/project" --objects mcp --dry-run 2>&1)"
grep -Fq 'agents/default.json exists but its IDE/CLI surface is ambiguous' <<< "$Q_AGENT_OUTPUT"
rm -f "$TEST_HOME/.aws/amazonq/agents/default.json"

# Neovim is an editor, not a native skills/MCP IDE. Only its documented
# init.lua location is diagnostic; automatic config migration must fail closed.
assert_neovim_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path neovim "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: neovim/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_neovim_path global ""
assert_neovim_path project ""
assert_neovim_path project-skills ""
assert_neovim_path rules ""
assert_neovim_path mcp ""
assert_neovim_path config "~/.config/nvim/init.lua"

NEOVIM_CONFIG_FIXTURE="$TEST_HOME/.config/nvim/init.lua"
mkdir -p "$(dirname "$NEOVIM_CONFIG_FIXTURE")"
printf '%s\n' 'return {}' > "$NEOVIM_CONFIG_FIXTURE"
NEOVIM_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source codex --target neovim --objects config --yes --strategy overwrite 2>&1)"
grep -Fq 'Neovim init.lua' <<< "$NEOVIM_OUTPUT"
[[ "$(cat "$NEOVIM_CONFIG_FIXTURE")" == 'return {}' ]] || {
    echo "FAIL: Neovim config fail-closed path modified the fixture" >&2
    exit 1
}

assert_trae_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path trae "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: trae/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_trae_path global "~/.trae/skills"
assert_trae_path project ".trae"
assert_trae_path project-skills ".trae/skills"
assert_trae_path project-mcp ".trae/mcp.json"
assert_trae_path mcp ""
assert_trae_path config ""
assert_trae_path rules ".trae/rules"
assert_trae_path prompts ".trae/commands"
TRAE_MCP_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target trae --objects mcp --dry-run 2>&1)"
grep -Fq 'TRAE global MCP has an official settings/raw-JSON method' <<< "$TRAE_MCP_OUTPUT"

assert_trae_cn_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path trae-cn "$object" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: trae-cn/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    fi
}

assert_trae_cn_path global "~/.trae-cn/skills"
assert_trae_cn_path project ".trae"
assert_trae_cn_path project-skills ".trae/skills"
assert_trae_cn_path project-mcp ".trae/mcp.json"
assert_trae_cn_path rules ".trae/rules"
assert_trae_cn_path mcp ""
assert_trae_cn_path config ""
TRAE_CN_MCP_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target trae-cn --objects mcp --dry-run 2>&1)"
grep -Fq 'TRAE global MCP has an official settings/raw-JSON method' <<< "$TRAE_CN_MCP_OUTPUT"

# TRAE Skills must remain a real Skills migration. A previous regression put
# the Commands manual guard inside migrate_skills(), causing this copy to
# return early without touching the documented global Skills root.
mkdir -p "$TEST_HOME/.trae/skills/trae-regression"
printf '%s\n' '---' 'name: trae-regression' 'description: TRAE skill regression.' '---' > "$TEST_HOME/.trae/skills/trae-regression/SKILL.md"
HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source trae --target cursor --workspace "$TMP_ROOT/project" \
    --objects skills --yes --strategy overwrite >/dev/null 2>&1
[[ -f "$TEST_HOME/.cursor/skills/trae-regression/SKILL.md" ]] || {
    echo "FAIL: TRAE Skills migration was intercepted by Commands handling" >&2
    exit 1
}

# Cody is current only as an Enterprise extension/UI surface. Its old-looking
# .cody, .codyrules, ~/.config/cody, and cody.json paths are not automatic
# targets. Exercise a fixture containing those stale names and verify every
# migration object fails closed without creating a target file.
assert_cody_path() {
    local object="$1"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path cody "$object" 2>/dev/null || true)"
    if [[ -n "$actual" ]]; then
        echo "FAIL: cody/${object} must be unsupported/empty, got '${actual}'" >&2
        exit 1
    fi
}

for cody_object in global project project-skills rules mcp project-mcp project-config config; do
    assert_cody_path "$cody_object"
done

CODY_PROJECT="$TMP_ROOT/cody-project"
mkdir -p "$CODY_PROJECT/.cody" "$CODY_PROJECT/.vscode"
printf '%s\n' 'legacy cody project state' > "$CODY_PROJECT/.cody/state.json"
printf '%s\n' 'legacy cody rules' > "$CODY_PROJECT/.codyrules"
printf '%s\n' '{"commands":{"legacy":{"prompt":"stale"}}}' > "$CODY_PROJECT/.vscode/cody.json"
CODY_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source cody --target cursor --workspace "$CODY_PROJECT" \
    --objects skills,rules,prompts,mcp,config,project --yes --strategy overwrite 2>&1)"
grep -Fq 'Cody' <<< "$CODY_OUTPUT"
grep -Fq 'manual' <<< "$CODY_OUTPUT"
[[ ! -e "$CODY_PROJECT/.cursor" ]] || {
    echo "FAIL: Cody unsupported fixture created a Cursor target" >&2
    exit 1
}

mkdir -p "$TMP_ROOT/project/.trae/commands" "$TMP_ROOT/project/.trae/rules"
printf '%s\n' '---' 'description: fixture command' '---' 'Summarize the fixture.' > "$TMP_ROOT/project/.trae/commands/summary.md"
printf '%s\n' '---' 'alwaysApply: true' '---' 'Use the fixture rule.' > "$TMP_ROOT/project/.trae/rules/fixture.md"
CN_PROMPT_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --source trae-cn --target cursor --workspace "$TMP_ROOT/project" --objects prompts,rules --dry-run 2>&1)"
grep -Fq '.trae/commands/*' <<< "$CN_PROMPT_OUTPUT"
grep -Eq '(Cursor rules|Trae CN rules)' <<< "$CN_PROMPT_OUTPUT"

CN_CONFIG_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --source trae-cn --target cursor --workspace "$TMP_ROOT/project" --objects config --dry-run 2>&1)"
grep -Fq 'target IDE has no specific config file' <<< "$CN_CONFIG_OUTPUT"

if ! grep -Fq '**config**: unsupported' "$SCRIPT_DIR/../references/ide-registry.md"; then
    echo "FAIL: Trae registry must mark config unsupported" >&2
    exit 1
fi

OPENCLAW_HOME_PATH="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path openclaw global)"
[[ "$OPENCLAW_HOME_PATH" == "~/.openclaw/skills" ]] || { echo "FAIL: OpenClaw global skills path" >&2; exit 1; }
OPENCLAW_PROJECT_SKILLS="$(bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path openclaw project-skills)"
[[ "$OPENCLAW_PROJECT_SKILLS" == "skills" ]] || { echo "FAIL: OpenClaw project skills path" >&2; exit 1; }
OPENCLAW_RULES="$(bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path openclaw rules)"
[[ "$OPENCLAW_RULES" == "AGENTS.md" ]] || { echo "FAIL: OpenClaw AGENTS.md path" >&2; exit 1; }
if bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path openclaw project >/dev/null 2>&1; then
    echo "FAIL: OpenClaw fixed project config root must be unsupported" >&2
    exit 1
fi

printf '%s\n' '{"mcpServers":{"fixture":{"command":"node","args":["server.js"]},"remote":{"url":"https://example.invalid/mcp","transport":"streamable-http"}}}' > "$TEST_HOME/.claude.json"
HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source claude --target openclaw --objects mcp --yes --strategy overwrite >/dev/null
python3 - "$TEST_HOME/.openclaw/openclaw.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert set(data["mcp"]["servers"]) == {"fixture", "remote"}
assert data["mcp"]["servers"]["remote"]["transport"] == "streamable-http"
PY

# Tabnine is file-backed for documented MCP, but has no documented Agent
# Skills directory and its guidelines/project MCP are scoped directories/files.
assert_tabnine_path() {
    local object="$1"
    local expected="$2"
    local actual
    actual="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --print-path tabnine "$object" 2>/dev/null || true)"
    [[ "$actual" == "$expected" ]] || {
        echo "FAIL: tabnine/${object} expected '${expected}', got '${actual}'" >&2
        exit 1
    }
}

assert_tabnine_path global ""
assert_tabnine_path project-skills ""
assert_tabnine_path rules ".tabnine/guidelines"
assert_tabnine_path mcp "~/.tabnine/mcp_servers.json"
assert_tabnine_path project-mcp ".tabnine/mcp_servers.json"
assert_tabnine_path config ""

mkdir -p "$TMP_ROOT/tabnine-project/.tabnine/guidelines"
printf '%s\n' 'Follow the Tabnine guideline fixture.' > "$TMP_ROOT/tabnine-project/.tabnine/guidelines/style.md"
TABNINE_RULE_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --source tabnine --target cursor --workspace "$TMP_ROOT/tabnine-project" --objects rules --dry-run 2>&1)"
grep -Fq 'Tabnine guidelines use scoped .tabnine/guidelines/*.md files; automatic migration is unsupported' <<< "$TABNINE_RULE_OUTPUT"

printf '%s\n' '{"mcpServers":{"local":{"command":"node","args":["server.js"],"env":{"TABNINE_TOKEN":"do-not-copy"}},"remote":{"url":"https://example.invalid/mcp"}}}' > "$TEST_HOME/.claude.json"
HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --source claude --target tabnine --objects mcp --yes --strategy overwrite >/dev/null
python3 - "$TEST_HOME/.tabnine/mcp_servers.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert set(data["mcpServers"]) == {"local", "remote"}
assert data["mcpServers"]["local"]["env"]["TABNINE_TOKEN"] == ""
assert data["mcpServers"]["remote"]["url"] == "https://example.invalid/mcp"
PY

TABNINE_PROJECT_OUTPUT="$(HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" --source tabnine --target cursor --workspace "$TMP_ROOT/tabnine-project" --objects project --dry-run 2>&1)"
grep -Fq 'Tabnine .tabnine is a mixed guideline/MCP namespace; automatic whole-directory migration is unsupported' <<< "$TABNINE_PROJECT_OUTPUT"

HOME="$TEST_HOME" bash "$SCRIPT_DIR/smart-ide-migration.sh" \
    --source codex \
    --target openclaw \
    --objects skills \
    --dry-run > "$OUTPUT"

grep -Fq "$VALID_SKILL" "$OUTPUT"

if grep -Fq "$NON_SKILL" "$OUTPUT"; then
    echo "FAIL: directory without SKILL.md was treated as a skill" >&2
    exit 1
fi

if grep -Fq "$PRIVATE_STATE" "$OUTPUT"; then
    echo "FAIL: private Codex state was treated as a skill" >&2
    exit 1
fi

grep -Fq 'successfully migrated 1 skills' "$OUTPUT"
echo "Smart IDE migration isolation test passed"
