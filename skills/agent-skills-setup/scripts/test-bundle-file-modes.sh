#!/usr/bin/env bash
# ACB file permission metadata survives each restore path; content is never run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/acb-file-modes.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

native_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$1"
    else
        printf '%s' "$1"
    fi
}

python3 - "$(native_path "$SCRIPT_DIR")" "$(native_path "$TMP_ROOT")" <<'PY'
import base64
import hashlib
import json
import os
import shutil
import stat
import subprocess
import sys
from pathlib import Path

scripts, root = map(Path, sys.argv[1:])
sys.path.insert(0, str(scripts))
from acb.bundle import (ACBIntegrityError, load_manifest, restore_bundle_objects,
                        verify_bundle, write_bundle)

posix = os.name == "posix"
os.umask(0o022)
home = root / "home"
temporary = root / "tmp"
home.mkdir()
temporary.mkdir()
environment = dict(os.environ)
environment.update(HOME=str(home), USERPROFILE=str(home), TMPDIR=str(temporary),
                   AGENT_SKILLS_PLATFORM="linux")
registry_data = json.loads((scripts.parent / "references/registry-v2.json").read_text())
registry_data["products"] = {
    name: registry_data["products"][name] for name in ("cursor", "cline")
}
for product in registry_data["products"].values():
    profile = product["profiles"]["ide"]
    product["profiles"] = {"ide": profile}
    profile["detection"] = []
    profile["platforms"] = {}
    profile["surfaces"] = {
        "skills": [surface for surface in profile["surfaces"]["skills"]
                   if surface["scope"] == "project"]
    }
registry = root / "registry.json"
registry.write_text(json.dumps(registry_data))
command_index = 0


def run(*args, status=0):
    global command_index
    command_index += 1
    command = [sys.executable, str(scripts / "context-migrator.py"), *map(str, args)]
    result = subprocess.run(command, env=environment, text=True, capture_output=True)
    (root / f"command-{command_index}.json").write_text(json.dumps({
        "command": command, "returncode": result.returncode,
        "stdout": result.stdout, "stderr": result.stderr,
    }, ensure_ascii=False, indent=2))
    assert result.returncode == status, (command, result.returncode, result.stdout, result.stderr)
    return json.loads(result.stdout)


def evidence(directory):
    return {
        path.relative_to(directory).as_posix():
        (hashlib.sha256(path.read_bytes()).hexdigest(), stat.S_IMODE(path.stat().st_mode))
        for path in sorted(directory.rglob("*")) if path.is_file()
    }


source_workspace = root / "source"
source = source_workspace / ".cursor/skills/build-helper"
source_files = {
    "SKILL.md": b"---\nname: build-helper\ndescription: Offline build fixture.\n---\n"
                b"Read [environment](assets/.environment-spec) and [guide](references/"
                + "指南.md".encode() + b"). Use scripts/check.sh.\n",
    "assets/.environment-spec": b"Build fixture resource.\n",
    "assets/pixel.png": base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6"
        "fQAAAABJRU5ErkJggg=="),
    "references/指南.md": "辅助脚本只复制，不执行。\n".encode(),
    "scripts/check.sh": b"#!/usr/bin/env bash\nexit 0\n",
    "scripts/special.sh": b"#!/usr/bin/env bash\nexit 0\n",
    ".env": b"FIXTURE_ONLY=value\n",
}
source_modes = {
    "SKILL.md": 0o644, "assets/.environment-spec": 0o640,
    "assets/pixel.png": 0o644, "references/指南.md": 0o600,
    "scripts/check.sh": 0o755, "scripts/special.sh": 0o7755, ".env": 0o600,
}
for relative, data in source_files.items():
    file = source / relative
    file.parent.mkdir(parents=True, exist_ok=True)
    file.write_bytes(data)
    file.chmod(source_modes[relative])
original_source = evidence(source)
expected = {relative: (digest, mode & 0o777)
            for relative, (digest, mode) in original_source.items() if relative != ".env"}
bundle = root / "helper.acb"
run("snapshot", "--registry", registry, "--source", "cursor/ide", "--target", "cursor/ide",
    "--workspace", source_workspace, "--scope", "project", "--objects", "skills",
    "--output", bundle, "--json")
manifest = json.loads((bundle / "manifest.json").read_text())
entries = [entry for obj in manifest["objects"] for entry in obj.get("files", [])]
assert len(entries) == len(expected), entries
for entry in entries:
    relative = entry["path"].split("build-helper/", 1)[1]
    assert entry.get("mode") == expected[relative][1], (relative, entry, expected[relative])
    assert entry["sha256"] == expected[relative][0], (relative, entry)
assert run("bundle-verify", bundle, "--json")["ok"]
assert evidence(source) == original_source
print("OK snapshot records ordinary file modes and preserves source bytes/modes")


def destination_case(name):
    workspace = root / name
    destination = workspace / ".cline/skills/build-helper"
    old = destination / "scripts/check.sh"
    old.parent.mkdir(parents=True)
    old.write_bytes(b"#!/usr/bin/env bash\n# Old target, never executed.\nexit 0\n")
    old.chmod(0o740)
    skill = destination / "SKILL.md"
    skill.write_bytes(b"---\nname: build-helper\ndescription: Original target.\n---\nOld.\n")
    skill.chmod(0o640)
    return workspace, destination, evidence(destination)


def check_package(destination, modes=True):
    actual = evidence(destination)
    assert set(actual) == set(expected), actual
    assert {key: value[0] for key, value in actual.items()} == {
        key: value[0] for key, value in expected.items()}, actual
    if posix and modes:
        assert actual == expected, (actual, expected)
    text = (destination / "SKILL.md").read_text()
    assert "assets/.environment-spec" in text and "references/指南.md" in text
    assert not (destination / ".env").exists()


for name in ("named", "generic", "bulk"):
    workspace, destination, original_target = destination_case(name)
    plan = root / f"{name}-plan.json"
    transaction = root / f"{name}-manifest.json"
    selection = (["--all-installed", "--include-configured"] if name == "bulk" else
                 ["--source", "cursor/ide", "--target", "cline/ide"])
    common = ["--registry", registry, "--workspace", workspace,
              "--scope", "project", "--objects", "skills"]
    extraction = root / f"{name}-extracted"
    extraction_args = ["--restore-root", extraction] if name == "named" else []
    planned = run("restore", bundle, *common, *selection, *extraction_args,
                  "--plan-only", "--plan-out", plan, "--json")
    assert planned["ok"], planned
    assert not extraction.exists()
    assert evidence(destination) == original_target
    assert not list(temporary.glob("acb-*-stage-*")), list(temporary.iterdir())
    if name == "generic":
        applied = run("apply", plan, "--bundle", bundle, "--registry", registry,
                      "--manifest", transaction, "--yes", "--json")
        assert len(applied["changes"]) == 1, applied
    else:
        applied = run("restore", bundle, *common, *selection, *extraction_args,
                      "--plan-in", plan, "--manifest-out", transaction, "--yes", "--json")
        assert applied["summary"]["applied"] == 1, applied
    check_package(destination)
    assert run("verify", "--manifest", transaction, "--json")["ok"]
    assert evidence(source) == original_source
    if name == "named":
        extracted = extraction / "skills/cursor/ide/project/.cursor/skills/build-helper"
        check_package(extracted)
        print("OK opt-in extraction preserves file bytes and ordinary modes")
    rolled_back = run("rollback", "--manifest", transaction, "--yes", "--json")
    assert rolled_back["restored"] == 1, rolled_back
    assert evidence(destination) == original_target, evidence(destination)
    assert evidence(source) == original_source
    assert not list(temporary.glob("acb-*-stage-*"))
    print(f"OK {name} cross-process restore/apply and rollback preserve bytes/modes")


def rewrite_manifest(copy, transform):
    path = copy / "manifest.json"
    document = json.loads(path.read_text())
    transform(document)
    path.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n")
    checksums = json.loads((copy / "checksums.json").read_text())
    checksums["manifest.json"] = hashlib.sha256(path.read_bytes()).hexdigest()
    (copy / "checksums.json").write_text(json.dumps(checksums, indent=2, sort_keys=True) + "\n")


legacy = root / "legacy.acb"
shutil.copytree(bundle, legacy)
rewrite_manifest(legacy, lambda document: [entry.pop("mode", None)
    for obj in document["objects"] for entry in obj.get("files", [])])
assert not verify_bundle(legacy), verify_bundle(legacy)
workspace, destination, original_target = destination_case("legacy")
transaction = root / "legacy-manifest.json"
run("restore", legacy, "--registry", registry, "--workspace", workspace,
    "--source", "cursor/ide", "--target", "cline/ide", "--scope", "project",
    "--objects", "skills", "--manifest-out", transaction, "--yes", "--json")
check_package(destination, modes=False)
run("rollback", "--manifest", transaction, "--yes", "--json")
assert evidence(destination) == original_target
print("OK older mode-less bundles remain readable and restorable")

for index, value in enumerate((True, "0755", None, -1, 0o1000, 0o4755, 0.5, [], {})):
    invalid_output = root / f"invalid-write-{index}" / "helper.acb"
    relative = entries[0]["path"][len("objects/"):]
    try:
        write_bundle(bundle_root=invalid_output, manifest=load_manifest(bundle),
                     inventory_rows=[], compatibility={}, requirements={},
                     secrets_required=[], reauth=[], rebuild=[],
                     objects_dir_files={relative: (bundle / entries[0]["path"]).read_bytes()},
                     object_file_modes={relative: value})
    except ACBIntegrityError:
        pass
    else:
        raise AssertionError(f"writer accepted malformed mode {value!r}")
    assert not invalid_output.parent.exists(), invalid_output
    malformed = root / f"malformed-{index}.acb"
    shutil.copytree(bundle, malformed)
    def tamper(document):
        # Put the bad metadata after valid files to detect partial extraction.
        all_entries = [entry for obj in document["objects"] for entry in obj.get("files", [])]
        all_entries[-1]["mode"] = value
    rewrite_manifest(malformed, tamper)
    errors = verify_bundle(malformed)
    assert errors and any("mode" in error for error in errors), (value, errors)
    for dry_run in (False, True):
        extraction = root / f"invalid-extraction-{index}-{dry_run}"
        try:
            restore_bundle_objects(malformed, extraction, dry_run=dry_run)
        except ACBIntegrityError:
            pass
        else:
            raise AssertionError(f"accepted malformed mode {value!r}")
        assert not extraction.exists(), extraction
workspace, destination, original_target = destination_case("invalid-target")
extraction = root / "invalid-cli-extraction"
rejected = run("restore", malformed, "--registry", registry, "--workspace", workspace,
               "--source", "cursor/ide", "--target", "cline/ide", "--scope", "project",
               "--objects", "skills", "--restore-root", extraction, "--yes", "--json", status=1)
assert rejected["stage"] == "verify", rejected
assert evidence(destination) == original_target and not extraction.exists()
invalid_transaction = root / "invalid-apply-manifest.json"
rejected = run("apply", root / "generic-plan.json", "--bundle", malformed,
               "--registry", registry, "--manifest", invalid_transaction,
               "--yes", "--json", status=1)
assert rejected["stage"] == "verify" and not invalid_transaction.exists(), rejected
assert evidence(root / "generic/.cline/skills/build-helper") == original_target
assert evidence(source) == original_source
print("OK malformed mode metadata fails verification before destination writes")
if not posix:
    print("SKIP POSIX permission equality on Windows; byte, metadata, rejection and rollback checks passed")
print("Bundle file mode tests passed")
PY
