#!/usr/bin/env bash

# Maintainer-test helpers only; never included in the published runtime.

native_path() {
    if command -v cygpath >/dev/null 2>&1; then
        # Forward slashes work in both Git Bash and native Windows Python.
        cygpath -m "$1"
    else
        printf '%s' "$1"
    fi
}

legacy_fixture_init() {
    local root="$1"
    local host

    mkdir -p "$root/home" "$root/tmp"
    export HOME="$(native_path "$root/home")"
    export USERPROFILE="$HOME"
    export APPDATA="$HOME/AppData/Roaming"
    export LOCALAPPDATA="$HOME/AppData/Local"
    export XDG_CONFIG_HOME="$HOME/.config"
    export TMPDIR="$(native_path "$root/tmp")"
    export TMP="$TMPDIR"
    export TEMP="$TMPDIR"
    export PYTHONUTF8=1
    export PYTHONDONTWRITEBYTECODE=1
    unset CLINE_DATA_DIR CLINE_MCP_PATH AGENT_SKILLS_PLATFORM
    mkdir -p "$APPDATA" "$LOCALAPPDATA" "$XDG_CONFIG_HOME"

    host="$(uname -s)"
    case "$host" in
        MINGW*|MSYS*|CYGWIN*)
            python3 - <<'PY'
import os
import sys

assert os.name == "nt", "Windows Git Bash fixtures require native Windows Python"
assert sys.platform == "win32", "a WSL/Cygwin Python cannot validate native Windows behavior"
PY
            ;;
    esac
    printf 'Fixture host: %s; ' "$host"
    python3 -c 'import os,sys; print(f"Python {sys.platform}/{os.name}")'
}

legacy_fixture_tree_state() {
    python3 - "$@" <<'PY'
import hashlib
import json
from pathlib import Path
import stat
import sys

result = []
for index, value in enumerate(sys.argv[1:]):
    root = Path(value)
    rows = []
    for path in sorted(root.rglob("*")):
        mode = path.lstat().st_mode
        kind = "symlink" if path.is_symlink() else "file" if path.is_file() else "directory"
        content = hashlib.sha256(path.read_bytes()).hexdigest() if kind == "file" else None
        rows.append((path.relative_to(root).as_posix(), kind, stat.S_IMODE(mode), content))
    result.append((index, root.exists(), rows))
sys.stdout.reconfigure(newline="")
print(json.dumps(result, ensure_ascii=True, separators=(",", ":")))
PY
}

legacy_fixture_assert_public_boundary() {
    local scripts="$1"
    local root="$2/public-legacy"
    local fixture_home="$root/home"
    local workspace="$root/workspace with spaces"
    local before
    local after
    local output

    mkdir -p \
        "$fixture_home/.cursor/skills/fixture-skill/assets" \
        "$fixture_home/.claude/skills/fixture-skill" \
        "$workspace"
    printf '%s\n' '---' 'name: fixture-skill' 'description: Public legacy fixture.' '---' \
        > "$fixture_home/.cursor/skills/fixture-skill/SKILL.md"
    printf '%s\n' 'preserve the whole source package' \
        > "$fixture_home/.cursor/skills/fixture-skill/assets/payload.txt"
    printf '%s\n' 'preserve the existing target' \
        > "$fixture_home/.claude/skills/fixture-skill/sentinel.txt"
    before="$(legacy_fixture_tree_state "$fixture_home" "$workspace")"

    output="$(HOME="$(native_path "$fixture_home")" bash "$scripts/smart-ide-migration.sh" legacy \
        --source cursor --target claude --workspace "$workspace" \
        --objects skills --strategy overwrite --dry-run 2>&1)"
    grep -Fq 'successfully migrated 1 skills' <<< "$output" || {
        echo "FAIL: public legacy preview did not discover its source Skill" >&2
        return 1
    }
    after="$(legacy_fixture_tree_state "$fixture_home" "$workspace")"
    [[ "$after" == "$before" ]] || {
        echo "FAIL: public legacy dry-run changed the source, target, or workspace" >&2
        return 1
    }

    if output="$(HOME="$(native_path "$fixture_home")" bash "$scripts/smart-ide-migration.sh" legacy \
        --source cursor --target claude --workspace "$workspace" \
        --objects skills --strategy overwrite --dry-run --yes 2>&1)"; then
        echo "FAIL: public legacy accepted a write authorization" >&2
        return 1
    fi
    grep -Fq 'legacy writes are disabled' <<< "$output" || {
        echo "FAIL: public legacy write refusal did not explain the saved-plan boundary" >&2
        return 1
    }
    after="$(legacy_fixture_tree_state "$fixture_home" "$workspace")"
    [[ "$after" == "$before" ]] || {
        echo "FAIL: rejected public legacy command changed the source, target, or workspace" >&2
        return 1
    }
    echo "PASS: public legacy discovers Skills in a zero-write preview and rejects --yes"
}
