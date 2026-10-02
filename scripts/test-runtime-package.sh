#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/agent-skills-runtime-package.XXXXXX)"
PACKAGE_ROOT="$TMP_ROOT/release-package"
FIXTURE_SKILL="$TMP_ROOT/fixture/agent-skills-setup"
FIXTURE_PACKAGE="$TMP_ROOT/fixture-package"
FAKE_BIN="$TMP_ROOT/bin"
FAKE_CLAWHUB_LOG="$TMP_ROOT/clawhub-publish.log"
FAKE_CLAWHUB_AUTH_LOG="$TMP_ROOT/clawhub-auth.log"
SMOKE_WORKSPACE="$TMP_ROOT/smoke-workspace"
SMOKE_REGISTRY="$TMP_ROOT/smoke-registry.json"
SOURCE_REPO="https://github.com/example/skills-repo"
SOURCE_COMMIT="0123456789abcdef0123456789abcdef01234567"
SOURCE_REF="main"
SOURCE_PATH="skills/agent-skills-setup"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/clawhub" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "whoami" ]]; then
    printf '%s\n' 'whoami' >> "$FAKE_CLAWHUB_AUTH_LOG"
    exit 0
fi
if [[ "${1:-}" == "publish" ]]; then
    printf '%s\n' "$*" >> "$FAKE_CLAWHUB_LOG"
    exit 0
fi
exit 1
EOF
chmod +x "$FAKE_BIN/clawhub"
export FAKE_CLAWHUB_LOG FAKE_CLAWHUB_AUTH_LOG

PATH="$FAKE_BIN:$PATH" bash "$REPO_ROOT/scripts/prepare-clawhub-release.sh" \
    --skill-dir "$REPO_ROOT/skills/agent-skills-setup" \
    --package-dir "$PACKAGE_ROOT" \
    --slug agent-skills-setup \
    --name "Agent Skills Setup" \
    --version 0.0.0 \
    --source-repo "$SOURCE_REPO" \
    --source-commit "$SOURCE_COMMIT" \
    --source-ref "$SOURCE_REF" \
    --source-path "$SOURCE_PATH" >"$TMP_ROOT/release.log"

[[ ! -e "$FAKE_CLAWHUB_AUTH_LOG" ]] || {
    echo "FAIL: offline release preparation attempted ClawHub authentication" >&2
    exit 1
}

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
[[ -f "$PACKAGE_ROOT/scripts/skill_secret_scanner.py" ]] || {
    echo "FAIL: runtime package omitted the shared source credential scanner" >&2
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
    skill_secret_scanner.py \
    smart-ide-migration.sh \
    | LC_ALL=C sort >"$TMP_ROOT/runtime-scripts.expected"
if ! diff -u "$TMP_ROOT/runtime-scripts.expected" "$TMP_ROOT/runtime-scripts.actual"; then
    echo "FAIL: package contains scripts that are not agent runtime dependencies" >&2
    exit 1
fi

find "$PACKAGE_ROOT/scripts" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; \
    | LC_ALL=C sort >"$TMP_ROOT/runtime-packages.actual"
printf '%s\n' \
    acb \
    detect \
    registry \
    | LC_ALL=C sort >"$TMP_ROOT/runtime-packages.expected"
if ! diff -u "$TMP_ROOT/runtime-packages.expected" "$TMP_ROOT/runtime-packages.actual"; then
    echo "FAIL: package subpackages do not match runtime requirements (acb, detect, registry)" >&2
    exit 1
fi

for pkg in acb detect registry; do
    [[ -f "$PACKAGE_ROOT/scripts/$pkg/__init__.py" ]] || {
        echo "FAIL: package $pkg is missing __init__.py" >&2
        exit 1
    }
done

# Inventory resolves only fixture project paths. User-scoped configuration
# and environmental MCP overrides never enter this smoke test.
mkdir -p "$SMOKE_WORKSPACE"
python3 - "$PACKAGE_ROOT/references/registry-v2.json" "$SMOKE_REGISTRY" <<'PY'
import json
from pathlib import Path
import sys

registry = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
profile = registry["products"]["cline"]["profiles"]["ide"]
profile["surfaces"] = {
    name: [row for row in rows if row.get("scope") == "project"]
    for name, rows in profile["surfaces"].items()
}
profile["detection"] = []
Path(sys.argv[2]).write_text(json.dumps(registry), encoding="utf-8")
PY

# Execute isolated CLI smoke test inside the staged package.
(
    cd "$PACKAGE_ROOT"
    unset PYTHONPATH
    export PYTHONPATH=""
    export PYTHONDONTWRITEBYTECODE=1
    python3 -I -B scripts/context-migrator.py --help >/dev/null || {
        echo "FAIL: staged context-migrator.py failed to run in isolated environment" >&2
        exit 1
    }
    bash scripts/smart-ide-migration.sh --help >/dev/null || {
        echo "FAIL: staged smart-ide-migration.sh --help failed" >&2
        exit 1
    }
    bash scripts/smart-ide-migration.sh inventory --product cline --profile ide \
        --workspace "$SMOKE_WORKSPACE" --registry "$SMOKE_REGISTRY" --json >/dev/null || {
        echo "FAIL: staged smart-ide-migration.sh inventory failed" >&2
        exit 1
    }
    bash scripts/smart-ide-migration.sh snapshot --help >/dev/null || {
        echo "FAIL: staged smart-ide-migration.sh snapshot --help failed" >&2
        exit 1
    }
    bash scripts/smart-ide-migration.sh restore --help >/dev/null || {
        echo "FAIL: staged smart-ide-migration.sh restore --help failed" >&2
        exit 1
    }
)

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
for expected in \
    "--source-repo $SOURCE_REPO" \
    "--source-commit $SOURCE_COMMIT" \
    "--source-ref $SOURCE_REF" \
    "--source-path $SOURCE_PATH"; do
    grep -F -- "$expected" "$TMP_ROOT/release.log" >/dev/null || {
        echo "FAIL: release command omitted source attribution: $expected" >&2
        exit 1
    }
done

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
[[ ! -e "$TMP_ROOT/no-consent-package" ]] || {
    echo "FAIL: rejected publish created a package before authorization" >&2
    exit 1
}

if PATH="$FAKE_BIN:$PATH" bash "$REPO_ROOT/scripts/prepare-clawhub-release.sh" \
    --skill-dir "$REPO_ROOT/skills/agent-skills-setup" \
    --package-dir "$TMP_ROOT/no-provenance-package" \
    --slug agent-skills-setup \
    --name "Agent Skills Setup" \
    --version 0.0.0 \
    --publish \
    --acknowledge-mit0 >"$TMP_ROOT/no-provenance.log" 2>&1; then
    echo "FAIL: ClawHub publish proceeded without source attribution" >&2
    exit 1
fi
grep -Fq 'complete source attribution' "$TMP_ROOT/no-provenance.log" || {
    echo "FAIL: source attribution blocker was not explained" >&2
    exit 1
}
[[ ! -e "$FAKE_CLAWHUB_LOG" ]] || {
    echo "FAIL: ClawHub executable was called for publish without source attribution" >&2
    exit 1
}
[[ ! -e "$TMP_ROOT/no-provenance-package" ]] || {
    echo "FAIL: rejected publish created a package without provenance" >&2
    exit 1
}

PATH="$FAKE_BIN:$PATH" bash "$REPO_ROOT/scripts/prepare-clawhub-release.sh" \
    --skill-dir "$REPO_ROOT/skills/agent-skills-setup" \
    --package-dir "$TMP_ROOT/consented-package" \
    --slug agent-skills-setup \
    --name "Agent Skills Setup" \
    --version 0.0.0 \
    --source-repo "$SOURCE_REPO" \
    --source-commit "$SOURCE_COMMIT" \
    --source-ref "$SOURCE_REF" \
    --source-path "$SOURCE_PATH" \
    --publish \
    --acknowledge-mit0 >"$TMP_ROOT/consented.log"
grep -Fq "publish $TMP_ROOT/consented-package" "$FAKE_CLAWHUB_LOG" || {
    echo "FAIL: authorized ClawHub publish did not use the staged package" >&2
    exit 1
}
for expected in \
    "--source-repo $SOURCE_REPO" \
    "--source-commit $SOURCE_COMMIT" \
    "--source-ref $SOURCE_REF" \
    "--source-path $SOURCE_PATH"; do
    grep -F -- "$expected" "$FAKE_CLAWHUB_LOG" >/dev/null || {
        echo "FAIL: authorized ClawHub publish omitted source attribution: $expected" >&2
        exit 1
    }
done

mkdir -p "$(dirname "$FIXTURE_SKILL")"
cp -R "$REPO_ROOT/skills/agent-skills-setup" "$FIXTURE_SKILL"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$FIXTURE_SKILL/scripts/maintenance-only.sh"
mkdir -p "$FIXTURE_SKILL/scripts/acb/__pycache__"
printf '%s\n' 'bytecode fixture' > "$FIXTURE_SKILL/scripts/acb/__pycache__/module.pyc"
printf '%s\n' 'bytecode fixture' > "$FIXTURE_SKILL/scripts/acb/module.pyc"
printf '%s\n' 'API_KEY=your_api_key_placeholder' > "$FIXTURE_SKILL/assets/.env.example"
printf '%s\n' 'configuration fixture' > "$FIXTURE_SKILL/assets/.environment-profile"
printf '%s\n' '[configuration](../assets/.environment-profile)' > "$FIXTURE_SKILL/references/environment-fixture.md"
bash "$REPO_ROOT/scripts/stage-runtime-skill.sh" "$FIXTURE_SKILL" "$FIXTURE_PACKAGE" 0.0.0
[[ ! -e "$FIXTURE_PACKAGE/scripts/maintenance-only.sh" ]] || {
    echo "FAIL: runtime staging copied an unapproved maintainer script" >&2
    exit 1
}
if find "$FIXTURE_PACKAGE" \( -name '__pycache__' -o -name '*.pyc' \) -print -quit | grep -q .; then
    echo "FAIL: runtime staging copied interpreter caches" >&2
    exit 1
fi
[[ ! -e "$FIXTURE_PACKAGE/assets/.env.example" ]]
[[ -f "$FIXTURE_PACKAGE/assets/.environment-profile" ]]
[[ -f "$FIXTURE_PACKAGE/references/environment-fixture.md" ]]
if bash "$REPO_ROOT/scripts/stage-runtime-skill.sh" \
    "$FIXTURE_SKILL" "$FIXTURE_SKILL/runtime-package" \
    0.0.0 \
    >"$TMP_ROOT/nested-package.log" 2>&1; then
    echo "FAIL: runtime staging accepted an output inside the source Skill" >&2
    exit 1
fi

mv "$FIXTURE_SKILL/scripts/registry" "$TMP_ROOT/registry.saved"
if bash "$REPO_ROOT/scripts/stage-runtime-skill.sh" "$FIXTURE_SKILL" "$TMP_ROOT/incomplete-package" 0.0.0 \
    >"$TMP_ROOT/incomplete.log" 2>&1; then
    echo "FAIL: runtime staging accepted missing required Python modules" >&2
    exit 1
fi
[[ ! -e "$TMP_ROOT/incomplete-package" ]]
mv "$TMP_ROOT/registry.saved" "$FIXTURE_SKILL/scripts/registry"

cp "$FIXTURE_SKILL/SKILL.md" "$TMP_ROOT/valid-skill.md"
printf '%s\n' '---' 'name: incorrect-name' 'description: Fixture.' '---' > "$FIXTURE_SKILL/SKILL.md"
if PATH="$FAKE_BIN:$PATH" bash "$REPO_ROOT/scripts/prepare-clawhub-release.sh" \
    --skill-dir "$FIXTURE_SKILL" --package-dir "$TMP_ROOT/invalid-package" \
    --slug fixture --name Fixture --version 0.0.0 >"$TMP_ROOT/invalid-source.log" 2>&1; then
    echo "FAIL: release helper accepted invalid Skill metadata" >&2
    exit 1
fi
[[ ! -e "$TMP_ROOT/invalid-package" ]]
cp "$TMP_ROOT/valid-skill.md" "$FIXTURE_SKILL/SKILL.md"

printf '%s\n' 'PASSWORD=literalCredential123456' > "$FIXTURE_SKILL/assets/config.payload"
if bash "$REPO_ROOT/scripts/stage-runtime-skill.sh" "$FIXTURE_SKILL" "$TMP_ROOT/credential-package" 0.0.0 \
    >"$TMP_ROOT/credential.log" 2>&1; then
    echo "FAIL: runtime staging accepted a credential in an unknown file extension" >&2
    exit 1
fi
[[ ! -e "$TMP_ROOT/credential-package" ]]
rm "$FIXTURE_SKILL/assets/config.payload"

# Source maintainer tests are excluded, but a test-named copied runtime asset
# cannot bypass the final package scan.
printf '%s\n' 'PASSWORD=literalCredential123456' > "$FIXTURE_SKILL/assets/test-runtime.payload"
if bash "$REPO_ROOT/scripts/stage-runtime-skill.sh" "$FIXTURE_SKILL" "$TMP_ROOT/test-credential-package" 0.0.0 \
    >"$TMP_ROOT/test-credential.log" 2>&1; then
    echo "FAIL: a test-named runtime asset bypassed the final credential scan" >&2
    exit 1
fi
[[ ! -e "$TMP_ROOT/test-credential-package" ]]
rm "$FIXTURE_SKILL/assets/test-runtime.payload"

# A source link cannot introduce files outside the reviewed package.
python3 - "$FIXTURE_SKILL" "$TMP_ROOT" <<'PY'
from pathlib import Path
import sys

source, root = map(Path, sys.argv[1:])
outside = root / "outside-fixture.txt"
outside.write_text("outside source", encoding="utf-8")
try:
    (source / "references/outside-link.txt").symlink_to(outside)
except (OSError, NotImplementedError):
    print("SKIP: host cannot create symlinks")
PY
if [[ -L "$FIXTURE_SKILL/references/outside-link.txt" ]]; then
    if bash "$REPO_ROOT/scripts/stage-runtime-skill.sh" "$FIXTURE_SKILL" "$TMP_ROOT/linked-package" 0.0.0 \
        >"$TMP_ROOT/linked.log" 2>&1; then
        echo "FAIL: runtime staging accepted a symbolic link" >&2
        exit 1
    fi
    [[ ! -e "$TMP_ROOT/linked-package" ]]
    rm "$FIXTURE_SKILL/references/outside-link.txt"
fi

# A failure after copying the staged payload must also leave no partial package.
cp "$FIXTURE_SKILL/scripts/context-migrator.py" "$TMP_ROOT/context-migrator.saved"
printf '%s\n' 'raise RuntimeError("injected staging smoke failure")' > "$FIXTURE_SKILL/scripts/context-migrator.py"
if bash "$REPO_ROOT/scripts/stage-runtime-skill.sh" "$FIXTURE_SKILL" "$TMP_ROOT/broken-cli-package" 0.0.0 \
    >"$TMP_ROOT/broken-cli.log" 2>&1; then
    echo "FAIL: runtime staging accepted a broken isolated CLI" >&2
    exit 1
fi
[[ ! -e "$TMP_ROOT/broken-cli-package" ]]
cp "$TMP_ROOT/context-migrator.saved" "$FIXTURE_SKILL/scripts/context-migrator.py"

python3 "$REPO_ROOT/scripts/skill_package.py" version '1.2.3-alpha.1+build.7'
for invalid in 01.2.3 1.2.3.4 1.2.3-01 1.2.3+; do
    if python3 "$REPO_ROOT/scripts/skill_package.py" version "$invalid" >"$TMP_ROOT/semver.log" 2>&1; then
        echo "FAIL: release helper accepted invalid SemVer: $invalid" >&2
        exit 1
    fi
done
if find "$TMP_ROOT" -maxdepth 1 -name '*.stage-*' -print -quit | grep -q .; then
    echo "FAIL: runtime staging left an intermediate directory" >&2
    exit 1
fi

echo "Runtime package test passed"
