#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/agent-skills-runtime-package.XXXXXX)"
PACKAGE_ROOT="$TMP_ROOT/release-package"
FIXTURE_SKILL="$TMP_ROOT/fixture-skill"
FIXTURE_PACKAGE="$TMP_ROOT/fixture-package"
FAKE_BIN="$TMP_ROOT/bin"
FAKE_CLAWHUB_LOG="$TMP_ROOT/clawhub-publish.log"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/clawhub" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == "whoami" ]] && exit 0
if [[ "${1:-}" == "publish" ]]; then
    printf '%s\n' "$*" >> "$FAKE_CLAWHUB_LOG"
    exit 0
fi
exit 1
EOF
chmod +x "$FAKE_BIN/clawhub"
export FAKE_CLAWHUB_LOG

PATH="$FAKE_BIN:$PATH" bash "$REPO_ROOT/scripts/prepare-clawhub-release.sh" \
    --skill-dir "$REPO_ROOT/skills/agent-skills-setup" \
    --package-dir "$PACKAGE_ROOT" \
    --slug agent-skills-setup \
    --name "Agent Skills Setup" \
    --version 0.0.0 >"$TMP_ROOT/release.log"

[[ -f "$PACKAGE_ROOT/SKILL.md" ]] || {
    echo "FAIL: release helper did not stage the runtime Skill" >&2
    exit 1
}
[[ -f "$PACKAGE_ROOT/LICENSE" ]] || {
    echo "FAIL: ClawHub package omitted the MIT-0 license" >&2
    exit 1
}
grep -Fq 'MIT No Attribution' "$PACKAGE_ROOT/LICENSE" || {
    echo "FAIL: ClawHub package license is not MIT-0" >&2
    exit 1
}
if grep -Eq '^license:' "$PACKAGE_ROOT/SKILL.md"; then
    echo "FAIL: ClawHub package contains a conflicting per-Skill license" >&2
    exit 1
fi
grep -Fq '        - bash' "$PACKAGE_ROOT/SKILL.md" || {
    echo "FAIL: ClawHub package does not require bash" >&2
    exit 1
}
grep -Fq '        - python3' "$PACKAGE_ROOT/SKILL.md" || {
    echo "FAIL: ClawHub package does not require python3" >&2
    exit 1
}
[[ -f "$PACKAGE_ROOT/scripts/smart-ide-migration.sh" ]] || {
    echo "FAIL: runtime package omitted the agent-facing migration script" >&2
    exit 1
}
[[ -f "$PACKAGE_ROOT/scripts/scan-skill-secrets.py" ]] || {
    echo "FAIL: runtime package omitted the source credential scanner" >&2
    exit 1
}
[[ ! -e "$PACKAGE_ROOT/evals" ]] || {
    echo "FAIL: release helper staged maintainer evals" >&2
    exit 1
}
if find "$PACKAGE_ROOT/scripts" -name 'test-*' -print -quit | grep -q .; then
    echo "FAIL: release helper staged regression tests" >&2
    exit 1
fi

find "$PACKAGE_ROOT/scripts" -maxdepth 1 -type f -exec basename {} \; \
    | LC_ALL=C sort >"$TMP_ROOT/runtime-scripts.actual"
printf '%s\n' \
    common.sh \
    context-migrator.py \
    ide-paths.tsv \
    legacy-smart-ide-migration.sh \
    migration_core.py \
    scan-skill-secrets.py \
    smart-ide-migration.sh \
    | LC_ALL=C sort >"$TMP_ROOT/runtime-scripts.expected"
if ! diff -u "$TMP_ROOT/runtime-scripts.expected" "$TMP_ROOT/runtime-scripts.actual"; then
    echo "FAIL: package contains scripts that are not agent runtime dependencies" >&2
    exit 1
fi

if find "$PACKAGE_ROOT" -type l -print -quit | grep -q .; then
    echo "FAIL: runtime package contains a symbolic link" >&2
    exit 1
fi
if find "$PACKAGE_ROOT" \( -name 'skills-lock.json' -o -name 'package-lock.json' \) -print -quit | grep -q .; then
    echo "FAIL: runtime package contains a lock file" >&2
    exit 1
fi
grep -F "$PACKAGE_ROOT" "$TMP_ROOT/release.log" >/dev/null || {
    echo "FAIL: release command does not publish the staged runtime package" >&2
    exit 1
}

if PATH="$FAKE_BIN:$PATH" bash "$REPO_ROOT/scripts/prepare-clawhub-release.sh" \
    --skill-dir "$REPO_ROOT/skills/agent-skills-setup" \
    --package-dir "$TMP_ROOT/no-consent-package" \
    --slug agent-skills-setup \
    --name "Agent Skills Setup" \
    --version 0.0.0 \
    --publish >"$TMP_ROOT/no-consent.log" 2>&1; then
    echo "FAIL: ClawHub publish proceeded without MIT-0 authorization" >&2
    exit 1
fi
grep -Fq 'contributor authorization' "$TMP_ROOT/no-consent.log" || {
    echo "FAIL: MIT-0 authorization blocker was not explained" >&2
    exit 1
}
[[ ! -e "$FAKE_CLAWHUB_LOG" ]] || {
    echo "FAIL: ClawHub executable was called for publish before authorization" >&2
    exit 1
}

PATH="$FAKE_BIN:$PATH" bash "$REPO_ROOT/scripts/prepare-clawhub-release.sh" \
    --skill-dir "$REPO_ROOT/skills/agent-skills-setup" \
    --package-dir "$TMP_ROOT/consented-package" \
    --slug agent-skills-setup \
    --name "Agent Skills Setup" \
    --version 0.0.0 \
    --publish \
    --acknowledge-mit0 >"$TMP_ROOT/consented.log"
grep -Fq "publish $TMP_ROOT/consented-package" "$FAKE_CLAWHUB_LOG" || {
    echo "FAIL: authorized ClawHub publish did not use the staged package" >&2
    exit 1
}

cp -R "$REPO_ROOT/skills/agent-skills-setup" "$FIXTURE_SKILL"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$FIXTURE_SKILL/scripts/maintenance-only.sh"
bash "$REPO_ROOT/scripts/stage-runtime-skill.sh" "$FIXTURE_SKILL" "$FIXTURE_PACKAGE" 0.0.0
[[ ! -e "$FIXTURE_PACKAGE/scripts/maintenance-only.sh" ]] || {
    echo "FAIL: runtime staging copied an unapproved maintainer script" >&2
    exit 1
}
if bash "$REPO_ROOT/scripts/stage-runtime-skill.sh" \
    "$FIXTURE_SKILL" "$FIXTURE_SKILL/runtime-package" \
    0.0.0 \
    >"$TMP_ROOT/nested-package.log" 2>&1; then
    echo "FAIL: runtime staging accepted an output inside the source Skill" >&2
    exit 1
fi

echo "Runtime package test passed"
