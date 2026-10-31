#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

native_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$1"
    else
        printf '%s' "$1"
    fi
}

PYTHONDONTWRITEBYTECODE=1 python3 - "$(native_path "$SCRIPT_DIR")" "$(native_path "$TEST_ROOT")" <<'PY'
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
from typing import Any

script_dir = Path(sys.argv[1])
test_root = Path(sys.argv[2])
sys.path.insert(0, str(script_dir))
from acb.bundle import ACBManifest, ACB_SCHEMA_VERSION, write_bundle

binary_dir = test_root / "bin"
binary_dir.mkdir()
module_dir = test_root / "modules"
module_dir.mkdir()
temporary_dir = test_root / "tmp"
temporary_dir.mkdir()
marker = test_root / "dependency-executed"
tool_name = "fixture-doctor-tool.cmd" if os.name == "nt" else "fixture-doctor-tool"
guard_program = (
    f"@echo off\r\necho unexpected > \"{marker}\"\r\nexit /b 99\r\n"
    if os.name == "nt"
    else f"#!/bin/sh\nprintf 'unexpected' > '{marker}'\nexit 99\n"
)
guard_paths = {}
for name in (tool_name, "npm", "pip", "uv", "curl"):
    executable_name = name + ".cmd" if os.name == "nt" and not name.endswith(".cmd") else name
    program = binary_dir / executable_name
    program.write_text(guard_program, encoding="utf-8")
    program.chmod(0o755)
    guard_paths[name] = program
manual_script = test_root / "scripts" / "local-tool.js"
manual_script.parent.mkdir()
manual_script.write_text("throw new Error('doctor must not run this script');\n", encoding="utf-8")
(module_dir / "doctor_fixture_package.py").write_text(
    "from pathlib import Path\n"
    "(Path(__file__).parent.parent / 'dependency-executed').write_text('imported')\n"
    "raise RuntimeError('doctor must not import dependency packages')\n",
    encoding="utf-8",
)
environment = dict(os.environ)
environment["PATH"] = str(binary_dir) + os.pathsep + environment.get("PATH", "")
environment["PYTHONPATH"] = str(module_dir)
environment["PYTHONDONTWRITEBYTECODE"] = "1"
environment["TMPDIR"] = str(temporary_dir)
for name, program in guard_paths.items():
    discovered = shutil.which(name, path=environment["PATH"])
    assert discovered and Path(discovered).resolve() == program.resolve(), (name, discovered, program)
reauth = [{"server": "fixture-server", "action": "reauth"}]
rebuild = [{"object_type": "mcp", "reason": "manual reconstruction"}]


def make_bundle(name: str, requirements: dict[str, Any]) -> Path:
    bundle = test_root / name
    write_bundle(
        bundle_root=bundle,
        manifest=ACBManifest(
            schema_version=ACB_SCHEMA_VERSION,
            bundle_id="doctor-requirements-fixture",
            created_at="2026-08-15T00:00:00Z",
            source_platform={},
            inventory_summary={},
            objects=[],
        ),
        inventory_rows=[],
        compatibility={},
        requirements=requirements,
        secrets_required=[],
        reauth=reauth,
        rebuild=rebuild,
    )
    return bundle


def tree_state() -> dict[str, tuple[str, int, str | None]]:
    result = {}
    for path in sorted(test_root.rglob("*")):
        mode = stat.S_IMODE(path.stat().st_mode)
        digest = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
        result[str(path.relative_to(test_root))] = (
            "file" if path.is_file() else "directory", mode, digest
        )
    return result


def doctor(bundle: Path, expected_status: int) -> dict[str, Any]:
    before = tree_state()
    process = subprocess.run(
        [sys.executable, str(script_dir / "context-migrator.py"), "doctor", str(bundle), "--json"],
        cwd=test_root,
        env=environment,
        capture_output=True,
        text=True,
        check=False,
    )
    assert process.returncode == expected_status, (process.returncode, process.stdout, process.stderr)
    assert not marker.exists(), "doctor executed a dependency or imported a package"
    assert tree_state() == before, "doctor mutated the isolated fixture"
    return json.loads(process.stdout)


requirements = {
    "executables": [tool_name],
    "extensions": ["fixture.extension"],
    "packages": [
        {"manager": "npm", "name": "@fixture/mcp-server"},
        {"manager": "pip", "name": "doctor_fixture_package"},
    ],
    "manual_installs": ["./scripts/local-tool.js", "./scripts/missing-tool.js"],
    "platform_notes": ["Recorded product requirement; installation is unverified"],
}
assert shutil.which(tool_name, path=environment["PATH"]), "fixture executable must be discoverable"
complete = make_bundle("complete.acb", requirements)
result = doctor(complete, 0)
assert result["ok"] is True and result["missing_executables"] == [], result
assert result.get("requirements") == requirements, result
assert result["executable_checks"] == [{"executable": tool_name, "found_on_path": True}], result
assert result["unresolved_requirements"] == {**requirements, "executables": []}, result
assert result["platform_notes"] == requirements["platform_notes"], result
assert result["reauth_actions"] == reauth and result["rebuild_actions"] == rebuild, result
print("OK doctor reports every recorded category without claiming dependency readiness")

missing_name = "doctor-no-such-tool-7f218ee"
assert shutil.which(missing_name, path=environment["PATH"]) is None
missing_requirements = {**requirements, "executables": [tool_name, missing_name]}
missing = make_bundle("missing.acb", missing_requirements)
result = doctor(missing, 1)
assert result["ok"] is False and result["missing_executables"] == [missing_name], result
assert result["requirements"] == missing_requirements, result
assert result["executable_checks"] == [
    {"executable": tool_name, "found_on_path": True},
    {"executable": missing_name, "found_on_path": False},
], result
assert result["unresolved_requirements"] == {**requirements, "executables": [missing_name]}, result
print("OK missing executables retain exit 1 while manual requirements stay visible")

empty = make_bundle("empty.acb", {})
result = doctor(empty, 0)
assert result["ok"] is True and result["requirements"] == {}, result
assert result["executable_checks"] == [] and result["missing_executables"] == [], result
assert result["unresolved_requirements"] == {"executables": []}, result
print("OK empty requirements preserve the successful executable-check result")

invalid = make_bundle("invalid.acb", requirements)
(invalid / "requirements.json").write_text("{}\n", encoding="utf-8")
result = doctor(invalid, 1)
assert result["ok"] is False and result["stage"] == "verify" and result["errors"], result
assert "requirements" not in result and "executable_checks" not in result, result
print("OK invalid bundles fail verification before reporting untrusted requirements")
print("Doctor requirements tests passed; every invocation left fixtures unchanged")
PY
