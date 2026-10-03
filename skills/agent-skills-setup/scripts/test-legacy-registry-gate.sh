#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Native Windows Python ignores MSYS-style env values; convert HOME
# fixtures so $HOME resolution sees a real directory on every platform.

# Pin surface resolution to the POSIX layout the fixtures create;
# otherwise windows-latest would resolve $APPDATA-style overrides.
export AGENT_SKILLS_PLATFORM=linux

native_path() {
    if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi
}
CLI="$SCRIPT_DIR/smart-ide-migration.sh"
LEGACY="$SCRIPT_DIR/legacy-smart-ide-migration.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

TEST_HOME="$TMP_ROOT/home"
WORKSPACE="$TMP_ROOT/workspace"
mkdir -p \
    "$TEST_HOME/.cline/skills/demo" \
    "$WORKSPACE/.cursor" \
    "$WORKSPACE/.cline/skills/project-demo"
printf '%s\n' '---' 'name: demo' 'description: Gate fixture.' '---' '# Demo' \
    > "$TEST_HOME/.cline/skills/demo/SKILL.md"
printf '%s\n' '---' 'name: project-demo' 'description: Gate fixture.' '---' '# Demo' \
    > "$WORKSPACE/.cline/skills/project-demo/SKILL.md"
printf '%s\n' '{"mcpServers":{"demo":{"command":"demo"}}}' \
    > "$WORKSPACE/.cursor/mcp.json"

if HOME="$(native_path "$TEST_HOME")" bash "$CLI" --print-path cline mcp \
    > "$TMP_ROOT/implicit.out" 2>"$TMP_ROOT/implicit.err"; then
    echo "FAIL: implicit legacy flags were accepted" >&2
    exit 1
fi
grep -Fq "implicit legacy flags are disabled" "$TMP_ROOT/implicit.err"

if HOME="$(native_path "$TEST_HOME")" bash "$CLI" legacy \
    --source cline --target windsurf --objects skills --dry-run --yes \
    > "$TMP_ROOT/mixed.out" 2>"$TMP_ROOT/mixed.err"; then
    echo "FAIL: legacy --yes was accepted when combined with --dry-run" >&2
    exit 1
fi
grep -Fq 'legacy writes are disabled' "$TMP_ROOT/mixed.err"

if HOME="$(native_path "$TEST_HOME")" bash "$CLI" \
    legacy --source cline --target windsurf --objects skills --yes --strategy overwrite \
    > "$TMP_ROOT/skills.out" 2>"$TMP_ROOT/skills.err"; then
    echo "FAIL: public legacy write reached the compatibility engine" >&2
    exit 1
fi
grep -Fq 'legacy writes are disabled' "$TMP_ROOT/skills.err"
[[ ! -e "$TEST_HOME/.codeium/windsurf/skills/demo/SKILL.md" ]]

mkdir -p "$WORKSPACE/.cline/rules"
printf '%s\n' '# reviewed project rule' > "$WORKSPACE/.cline/rules/reviewed.md"
HOME="$(native_path "$TEST_HOME")" bash "$CLI" \
    legacy --source cline --target windsurf --workspace "$WORKSPACE" \
    --objects rules --strategy overwrite --dry-run >"$TMP_ROOT/rules.log"
grep -Fq 'Windsurf rules use scoped files' "$TMP_ROOT/rules.log"
[[ ! -e "$WORKSPACE/.windsurf/rules/reviewed.md" ]]

mkdir -p "$WORKSPACE/.cline"
printf '%s\n' '{"mcpServers":{"demo":{"command":"demo"}}}' \
    > "$WORKSPACE/.cline/mcp.json"
if HOME="$(native_path "$TEST_HOME")" bash "$CLI" \
    legacy --source cline --target windsurf --workspace "$WORKSPACE" \
    --objects project-mcp --scope project --strategy overwrite --yes \
    >"$TMP_ROOT/project-mcp.out" 2>"$TMP_ROOT/project-mcp.err"; then
    echo "FAIL: project MCP was authorized from unrelated user-scope surfaces" >&2
    exit 1
fi
grep -Fq 'legacy writes are disabled' "$TMP_ROOT/project-mcp.err"

for target in codely roo-code bolt-new pieces emacs codeium; do
    if HOME="$(native_path "$TEST_HOME")" bash "$CLI" \
        legacy --source cline --target "$target" --workspace "$WORKSPACE" \
        --objects skills --scope project --yes --strategy overwrite \
        > "$TMP_ROOT/$target.log" 2>&1; then
        echo "FAIL: Registry-restricted legacy target was writable: $target" >&2
        exit 1
    fi
    grep -Fq 'legacy writes are disabled' "$TMP_ROOT/$target.log"
done

if HOME="$(native_path "$TEST_HOME")" bash "$CLI" \
    legacy --source cursor --target codely --workspace "$WORKSPACE" \
    --objects project-mcp --scope project --yes --strategy overwrite \
    > "$TMP_ROOT/codely-mcp.log" 2>&1; then
    echo "FAIL: unverified Codely MCP target bypassed Registry v2" >&2
    exit 1
fi
[[ ! -e "$WORKSPACE/.codely-cli/settings.json" ]]

if bash "$LEGACY" --help > "$TMP_ROOT/direct.log" 2>&1; then
    echo "FAIL: internal legacy engine was directly executable" >&2
    exit 1
fi
grep -Fq 'is internal' "$TMP_ROOT/direct.log"

# Exercise the public call chain, including its no-Python compatibility path.
# A report path must not turn a read-only preview into a configuration write.
python3 - "$CLI" "$TMP_ROOT" "$(command -v bash)" <<'PYTEST'
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

cli = Path(sys.argv[1]).resolve()
root = Path(sys.argv[2]).resolve() / "report-boundary"
bash = sys.argv[3]
root.mkdir()
hook = root / "without-python.bash"
hook.write_text(
    "command() {\n"
    '    if [[ "${1:-}" == "-v" && "${2:-}" == "python3" ]]; then return 1; fi\n'
    '    builtin command "$@"\n'
    "}\n",
    encoding="utf-8",
)

def snapshot(directory: Path) -> dict[str, str]:
    return {
        str(path.relative_to(directory)): (
            hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else "directory"
        )
        for path in sorted(directory.rglob("*"))
    }

for fallback in (False, True):
    for output_json in (False, True):
        for report_kind in ("existing", "new", "source"):
            case = root / f"{fallback}-{output_json}-{report_kind}"
            home = case / "home"
            workspace = case / "workspace"
            skill = home / ".cline" / "skills" / "demo"
            skill.mkdir(parents=True)
            workspace.mkdir()
            (skill / "SKILL.md").write_text(
                "---\nname: demo\ndescription: Read-only preview fixture.\n---\n# Demo\n",
                encoding="utf-8",
            )
            payload = skill / "assets" / "payload.txt"
            payload.parent.mkdir()
            payload.write_bytes(b"Source content must survive a preview.\n")
            report = payload if report_kind == "source" else case / "report.json"
            if report_kind == "existing":
                report.write_bytes(b"Existing unrelated content.\n")
            before_report = report.read_bytes() if report.exists() else None
            before_home = snapshot(home)
            before_workspace = snapshot(workspace)
            environment = dict(os.environ)
            environment.update({
                "HOME": str(home),
                "USERPROFILE": str(home),
                "XDG_CONFIG_HOME": str(home / ".config"),
                "XDG_DATA_HOME": str(home / ".local" / "share"),
                "PYTHONDONTWRITEBYTECODE": "1",
                "AGENT_SKILLS_PLATFORM": "linux",
            })
            if fallback:
                environment["BASH_ENV"] = str(hook)
            else:
                environment.pop("BASH_ENV", None)
            arguments = [
                bash, str(cli), "legacy", "--source", "cline", "--target", "windsurf",
                "--workspace", str(workspace), "--objects", "skills", "--dry-run",
                "--report", str(report),
            ]
            if output_json:
                arguments.append("--json")
            result = subprocess.run(arguments, env=environment, capture_output=True, timeout=30)
            assert result.returncode == 0, (arguments, result.stderr.decode(errors="replace"))
            if before_report is None:
                assert not report.exists(), f"dry-run created report: {arguments}"
            else:
                assert report.read_bytes() == before_report, f"dry-run overwrote report: {arguments}"
            assert snapshot(home) == before_home, f"dry-run changed source/target files: {arguments}"
            assert snapshot(workspace) == before_workspace, f"dry-run changed workspace files: {arguments}"
            if output_json:
                document = json.loads(result.stdout)
                assert document["mode"] == "dry-run", document
            else:
                assert b"DRY-RUN" in result.stdout
print("Legacy dry-run report boundary: 12 public-entry cases passed")
PYTEST

echo "Legacy Registry authorization test passed"
