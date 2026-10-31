#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$SCRIPT_DIR" <<'PYEOF'
import plistlib
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, sys.argv[1])
import detect.probes as probes
from detect.probes import InstallState, detect_profile, probe_app_bundle, probe_binary, probe_file_signature

with tempfile.TemporaryDirectory(prefix="detection-probes-") as temporary:
    root = Path(temporary).resolve()
    home = root / "home"
    home.mkdir()
    fixture_file = home / ".config-fixture"
    fixture_file.write_text("dummy", encoding="utf-8")

    with patch.object(probes.shutil, "which", return_value=None):
        assert probe_binary("missing", "cli", ["mock"]).state is InstallState.NOT_DETECTED
        assert detect_profile("fixture", "ide", binaries=["mock"], file_signatures=[fixture_file], home=home).state is InstallState.INSTALLED
    version = subprocess.CompletedProcess(["mock", "--version"], 0, "mock 1.0\n", "")
    with patch.object(probes.shutil, "which", return_value=str(root / "mock")), patch.object(probes.subprocess, "run", return_value=version):
        result = probe_binary("fixture", "cli", ["mock"], version_command=["mock", "--version"])
        assert result.state is InstallState.INSTALLED
        assert result.evidence[-1] == "version:mock 1.0"
    missing_extension = subprocess.CompletedProcess(["gh", "copilot", "--version"], 1, "", "unknown command copilot")
    with patch.object(probes.shutil, "which", return_value=str(root / "gh")), patch.object(probes.subprocess, "run", return_value=missing_extension):
        assert probe_binary("fixture", "cli", ["gh"], version_command=["gh", "copilot", "--version"], require_version=True).state is InstallState.NOT_DETECTED
    print("PASS: isolated binary/version detection rejects missing subcommands")

    shared = home / "AGENTS.md"
    shared.write_text("Shared instructions\n", encoding="utf-8")
    assert probe_file_signature("fixture", "ide", [shared], home=home).state is InstallState.COMPATIBILITY_ONLY
    assert probe_file_signature("fixture", "ide", [shared, fixture_file], home=home).state is InstallState.INSTALLED
    assert probe_file_signature("fixture", "ide", ["~/.config-*"], home=home).state is InstallState.INSTALLED
    apps = home / "Applications"
    apps.mkdir()
    matches = []
    for name, identifier, fmt in (
        ("Prefix.app", "com.example.app.beta", plistlib.FMT_XML),
        ("Exact.app", "com.example.app", plistlib.FMT_BINARY),
    ):
        app = apps / name
        contents = app / "Contents"
        contents.mkdir(parents=True)
        (contents / "Info.plist").write_bytes(plistlib.dumps({"CFBundleIdentifier": identifier}, fmt=fmt))
        matches.append(app)
    broken = apps / "Broken.app"
    (broken / "Contents").mkdir(parents=True)
    (broken / "Contents" / "Info.plist").write_bytes(b"<?xml version='1.0'?><unclosed>")
    denied = apps / "Denied.app"
    denied.mkdir()

    original_read = Path.read_bytes
    original_glob = Path.glob
    original_is_dir = Path.is_dir
    def guarded_read(path):
        if path.parent.parent == denied:
            raise PermissionError("fixture denied")
        return original_read(path)
    def guarded_glob(path, pattern):
        if path == Path("/Applications"):
            return iter(())
        return original_glob(path, pattern)
    def guarded_is_dir(path):
        if path == denied:
            raise PermissionError("fixture denied")
        return original_is_dir(path)
    spotlight = subprocess.CompletedProcess(["mdfind"], 0, "", "")
    with patch.object(probes.sys, "platform", "darwin"), patch.object(Path, "glob", guarded_glob), patch.object(Path, "read_bytes", guarded_read), patch.object(Path, "is_dir", guarded_is_dir), patch.object(probes.subprocess, "run", return_value=spotlight):
        result = probe_app_bundle("fixture", "ide", darwin_bundle_id="com.example.app", home=home)
        assert result.state is InstallState.INSTALLED, result
        assert result.evidence == (f"app-bundle:{apps / 'Exact.app'}",), result
        assert probe_app_bundle("fixture", "ide", darwin_bundle_id="com.example", home=home).state is InstallState.NOT_DETECTED
        assert probe_app_bundle("fixture", "ide", darwin_bundle_id="com.example.app' || malicious", home=home).state is InstallState.NOT_DETECTED
        result = detect_profile("fixture", "ide", file_signatures=[shared], app_bundle_id="com.example.app", home=home)
        assert result.state is InstallState.INSTALLED
    print("PASS: exact binary/XML plist detection survives malformed and inaccessible applications")

    # Spotlight may contain stale or unrelated paths before the correct app.
    indexed = subprocess.CompletedProcess(["mdfind"], 0, f"{apps / 'Prefix.app'}\n{apps / 'Exact.app'}\n", "")
    with patch.object(probes.sys, "platform", "darwin"), patch.object(Path, "glob", return_value=iter(())), patch.object(probes.subprocess, "run", return_value=indexed):
        result = probe_app_bundle("fixture", "ide", darwin_bundle_id="com.example.app", home=home)
        assert result.evidence == (f"app-bundle:{apps / 'Exact.app'}",), result
    print("PASS: Spotlight results require verified bundle identifiers")

assert len({state.value for state in InstallState}) == 7
print("Detection probe tests passed")
PYEOF
