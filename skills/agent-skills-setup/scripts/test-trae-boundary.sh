#!/usr/bin/env bash

# test-trae-boundary.sh — regression guard for the Trae IDE vs Trae Agent
# product boundary.
#
# Trae IDE (docs.trae.ai / docs.trae.cn) and Trae Agent (bytedance/trae-agent)
# are separate products with different filesystem shapes:
#
#   - Trae IDE:        user namespace `~/.trae/` / `~/.trae-cn/`,
#                      project namespace `.trae/`. No published global CLI
#                      or argv/settings file.
#   - Trae Agent:      repo-local `trae_config.yaml`/`trae_config.json`,
#                      `trae-cli` binary on PATH, MCP inline under
#                      `mcp_servers:` YAML key.
#
# The migration mapper must never write `~/.trae/argv.json`, never promote
# a Trae-Agent `trae_config.yaml` to a global `.trae` path, and the IDE
# registry must keep the boundary visible.
#
# No `set -e`: accumulated failures are reported at the end.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGISTRY="$SCRIPT_DIR/../references/ide-registry.md"
MIGRATION="$SCRIPT_DIR/smart-ide-migration.sh"
WORKSPACE="$(mktemp -d /tmp/agent-skills-trae-boundary.XXXXXX)"
trap 'rm -rf "$WORKSPACE"' EXIT

CHECKS=0
FAIL=0

pass() { CHECKS=$((CHECKS + 1)); echo "PASS: $1"; }
fail() { CHECKS=$((CHECKS + 1)); FAIL=$((FAIL + 1)); echo "FAIL: $1" >&2; }

# 1. Registry must document Trae Agent as a separate product under both
#    `trae` and `trae-cn` sections, and must link the bytedance/trae-agent repo.
if grep -Fq 'bytedance/trae-agent' "$REGISTRY"; then
    pass "registry cites bytedance/trae-agent as a separate product"
else
    fail "registry does not mention bytedance/trae-agent; users may confuse Trae IDE with Trae Agent"
fi

# 2. Registry must NOT claim a global Trae-IDE CLI/argv/settings file exists.
#    The wording must be a *negative* prescription (do not infer) rather than
#    a positive claim (no CLI exists).
if grep -Eq '`?~/.trae(-cn)?/argv\.json`?:? +(still |also |is |are )?(published|documented|valid|supported)|Trae +IDE +has +a +(global|published) +(CLI|argv|settings)' "$REGISTRY"; then
    fail "registry claims a global Trae-IDE CLI/argv/settings path exists"
else
    pass "registry does not assert a global Trae-IDE CLI/argv/settings file"
fi

# 3. Registry must NOT list trae-agent's `trae_config.yaml` as a portable
#    global config under either the Trae IDE or Trae CN entries.
if grep -Eq 'global +`?~/.trae(-cn)?/(trae_config\.yaml|trae_config\.json|settings\.json)`?' "$REGISTRY"; then
    fail "registry promotes a Trae-Agent repo-local config file to global ~/.trae/ status"
else
    pass "registry does not promote trae_config.yaml to a global Trae IDE path"
fi

# 4. Migration script must not register any IDE key named like a Trae Agent
#    surface ("trae-cli", "trae-agent", "trae_agent").
grep -Eq 'trae-agent|trae-cli|trae_agent' "$MIGRATION" \
    && fail "smart-ide-migration.sh references a Trae-Agent-specific key (trae-cli/trae-agent/trae_agent)" \
    || pass "smart-ide-migration.sh does not register a Trae-Agent surface as a mapper target"

# 5. Running the mapper with a target that doesn't exist must NOT silently
#    invent a path; it must report manual/unsupported.
mkdir -p "$WORKSPACE/.claude/skills/demo"
printf '%s\n' '---' 'name: demo' 'description: demo' '---' '# demo' > "$WORKSPACE/.claude/skills/demo/SKILL.md"
OUTPUT="$(HOME="$WORKSPACE" bash "$MIGRATION" \
    --source claude --target trae-cli --workspace "$WORKSPACE" \
    --objects skills --dry-run 2>&1 || true)"
if grep -Eq 'manual|unsupported|not +(a |an )(supported|registered)|unknown +target|invalid +target' <<< "$OUTPUT"; then
    pass "trae-cli is rejected as an unknown target (no path invention)"
else
    fail "trae-cli target output did not emit a manual/unsupported marker; got: $OUTPUT"
fi

# 6. Trae IDE empty config slot must continue to resolve to empty (fail-closed,
#    not a guessed path).
OUTPUT2="$(HOME="$WORKSPACE" bash "$MIGRATION" \
    --source claude --target trae --workspace "$WORKSPACE" \
    --print-path trae config 2>/dev/null || true)"
if [[ -z "$OUTPUT2" ]]; then
    pass "trae|config resolves to empty (no fake global config file path)"
else
    fail "trae|config produced a non-empty path: '$OUTPUT2' (registry says no global config file exists)"
fi

echo ""
if [[ $FAIL -eq 0 ]]; then
    echo "ALL CHECKS PASSED ($CHECKS checks)"
    exit 0
else
    echo "$FAIL / $CHECKS checks FAILED" >&2
    exit 1
fi
