#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIGRATION_SCRIPT="$SCRIPT_DIR/legacy-smart-ide-migration.sh"
export AGENT_SKILLS_SETUP_INTERNAL_LEGACY=1
TMP_ROOT="$(mktemp -d /tmp/agent-skills-secret-preflight.XXXXXX)"
TEST_HOME="$TMP_ROOT/home"
SOURCE_ROOT="$TEST_HOME/.claude/skills"
TARGET_ROOT="$TEST_HOME/.agents/skills"

cleanup() {
    chmod -R u+rwx "$TMP_ROOT" 2>/dev/null || true
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

make_skill() {
    local name="$1"
    mkdir -p "$SOURCE_ROOT/$name"
    printf '%s\n' \
        '---' \
        "name: $name" \
        'description: Secret-preflight fixture.' \
        '---' \
        '' \
        'Fixture.' > "$SOURCE_ROOT/$name/SKILL.md"
}

make_skill safe-skill
printf '%s\n' \
    'parent_secret = bool(secret_key_pattern.search(key))' \
    'print(parent_secret)' > "$SOURCE_ROOT/safe-skill/tool.py"
printf '%s\n' \
    '#!/usr/bin/env bash' \
    'token=$(status_token "$status")' > "$SOURCE_ROOT/safe-skill/report.sh"

make_skill markdown-secret
printf '%s\n' 'Temporary token: ghp_a1B2c3D4e5F6g7H8i9J0' \
    > "$SOURCE_ROOT/markdown-secret/README.md"

make_skill python-secret
printf '%s\n' 'SERVICE_TOKEN = "sk-live-a1B2c3D4e5F6g7H8i9J0"' \
    > "$SOURCE_ROOT/python-secret/tool.py"

make_skill extensionless-secret
printf '%s\n' \
    '-----BEGIN PRIVATE KEY-----' \
    'cHJpdmF0ZS1rZXktZml4dHVyZS1kYXRh' \
    '-----END PRIVATE KEY-----' \
    > "$SOURCE_ROOT/extensionless-secret/credentials"

make_skill external-link-secret
printf '%s\n' 'external private material' > "$TMP_ROOT/private-credentials"
ln -s "$TMP_ROOT/private-credentials" \
    "$SOURCE_ROOT/external-link-secret/credentials-link"

make_skill unreadable-skill
mkdir -p "$SOURCE_ROOT/unreadable-skill/private"
printf '%s\n' 'unreadable material' \
    > "$SOURCE_ROOT/unreadable-skill/private/credentials"
chmod 000 "$SOURCE_ROOT/unreadable-skill/private"

mkdir -p "$TARGET_ROOT/markdown-secret"
printf '%s\n' 'preserve existing target' > "$TARGET_ROOT/markdown-secret/sentinel.txt"
mkdir -p "$TARGET_ROOT/unreadable-skill"
printf '%s\n' 'preserve unreadable target' \
    > "$TARGET_ROOT/unreadable-skill/sentinel.txt"

HOME="$TEST_HOME" bash "$MIGRATION_SCRIPT" \
    --source claude --target codex --objects skills \
    --strategy overwrite --yes > "$TMP_ROOT/migration.log" 2>&1

[[ -f "$TARGET_ROOT/safe-skill/tool.py" ]] || {
    echo "FAIL: a credential-free Skill was not migrated" >&2
    exit 1
}
[[ -f "$TARGET_ROOT/markdown-secret/sentinel.txt" ]] || {
    echo "FAIL: preflight did not preserve an existing target before rejecting its source" >&2
    exit 1
}
[[ ! -e "$TARGET_ROOT/markdown-secret/README.md" ]] || {
    echo "FAIL: Markdown credential reached the target" >&2
    exit 1
}
[[ ! -e "$TARGET_ROOT/python-secret" ]] || {
    echo "FAIL: Python credential reached the target" >&2
    exit 1
}
[[ ! -e "$TARGET_ROOT/extensionless-secret" ]] || {
    echo "FAIL: extensionless private key reached the target" >&2
    exit 1
}
[[ ! -e "$TARGET_ROOT/external-link-secret" ]] || {
    echo "FAIL: a Skill containing an external symbolic link reached the target" >&2
    exit 1
}
[[ -f "$TARGET_ROOT/unreadable-skill/sentinel.txt" ]] || {
    echo "FAIL: an unreadable source subtree was not rejected before overwrite" >&2
    exit 1
}
grep -Fq 'source credential preflight failed' "$TMP_ROOT/migration.log" || {
    echo "FAIL: rejected Skills were not reported" >&2
    exit 1
}
grep -Fq 'ghp_a1B2c3D4e5F6g7H8i9J0' "$SOURCE_ROOT/markdown-secret/README.md" || {
    echo "FAIL: source Skill was modified" >&2
    exit 1
}

echo "Skill secret preflight test passed"
