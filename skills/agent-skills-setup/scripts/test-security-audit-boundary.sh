#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

for repo_only_file in \
    scripts/auto-configure-openclaw-skills.sh \
    scripts/export-public-skill.sh \
    scripts/prepare-clawhub-release.sh \
    scripts/sync-global-skills.sh \
    scripts/update-openclaw-skills.sh \
    references/publishing.md \
    assets/public-repo-readme-template.md; do
    [[ ! -e "$SKILL_ROOT/$repo_only_file" ]] || \
        fail "publishable Skill still includes repository-only utility: $repo_only_file"
done

if grep -Eq '^  - (install|network):' "$SKILL_ROOT/SKILL.md"; then
    fail "publishable Skill still declares install/network authority"
fi

[[ ! -e "$SKILL_ROOT/references/openclaw.md" ]] || \
    fail "OpenClaw-specific guidance must live in the selected IDE reference"

if rg -n --glob '!test-security-audit-boundary.sh' \
    -- '--env\)|--env-file\)|install\.sh|install -g|curl -fsSL|metadata\.openclaw\.install' \
    "$SKILL_ROOT/scripts" "$SKILL_ROOT/SKILL.md" \
    "$SKILL_ROOT/references/ides/openclaw.md" >/dev/null; then
    fail "publishable Skill still exposes installation or literal-secret ingestion paths"
fi

if rg -n 'rm[[:space:]]+-[^[:space:]]*r[^[:space:]]*f|rm[[:space:]]+-[^[:space:]]*f[^[:space:]]*r' \
    "$SCRIPT_DIR/smart-ide-migration.sh" >/dev/null; then
    fail "migration script still contains raw recursive force deletion"
fi

python3 - "$SKILL_ROOT/SKILL.md" <<'PY'
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
heading = text.find("## Workflow")
dry_run = text.find("--dry-run", heading)
apply = text.find("--yes", heading)
if heading < 0 or dry_run < 0 or apply < 0 or dry_run > apply:
    raise SystemExit(
        "FAIL: migration workflow must put an explicit dry-run before the approved apply"
    )
PY

echo "Security audit boundary test passed"
