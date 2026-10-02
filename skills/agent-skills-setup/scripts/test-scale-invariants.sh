#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$SCRIPT_DIR" <<'PY'
import hashlib
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import tracemalloc

scripts = Path(sys.argv[1])
sys.path.insert(0, str(scripts))
from acb.bundle import sha256_file
from migration_core import hash_path

benchmark_path = scripts.parents[2] / "scripts" / "benchmark-scale.py"
benchmark = runpy.run_path(str(benchmark_path))
with tempfile.TemporaryDirectory(prefix="scale-invariants-") as temporary:
    root = Path(temporary).resolve()
    registry = root / "registry.json"
    benchmark["create_registry"](registry)
    result = benchmark["run_case"](12, root, registry)
    assert result["source_files"] == 49, result
    assert result["source_intact"] and result["migrate_roundtrip"] and result["restore_roundtrip"]
    snapshot = json.loads((root / "size-12" / "snapshot.stdout.json").read_text())
    objects = json.loads((root / "size-12" / "project.acb" / "manifest.json").read_text())["objects"]
    assert snapshot["objects_captured"] == sum(bool(item["files"]) for item in objects) == 3
    assert snapshot["files_captured"] == sum(len(item["files"]) for item in objects) == 49
    print("OK multi-package migration/restore counts, exact bytes, rule contents and rollback")

    # Same-name changes must be visible without copying any credential value
    # into the plan, including changes caused by safe redaction.
    project = root / "preview"
    (project / ".cursor").mkdir(parents=True)
    (project / ".cline").mkdir()
    credential = "synthetic" + "credentialvalue" * 2
    source = {"mcpServers": {
        "new": {"command": "node"},
        "edit": {"command": "python3", "args": ["new"], "env": {"LOG_LEVEL": "info"}},
        "stable": {"command": "node", "args": [], "env": {}},
        "redacted": {"command": "node", "env": {"API_KEY": credential}},
    }}
    target = {"theme": "dark", "mcpServers": {
        "removed": {"command": "node"},
        "edit": {"command": "python3", "args": ["old"], "disabled": None},
        "stable": {"command": "node"},
        "redacted": {"command": "node", "env": {"API_KEY": credential}},
    }}
    source_path = project / ".cursor" / "mcp.json"
    target_path = project / ".cline" / "mcp.json"
    source_path.write_text(json.dumps(source), encoding="utf-8")
    target_path.write_text(json.dumps(target), encoding="utf-8")
    original = benchmark["file_hashes"](project)
    environment = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", TMPDIR=str(root / "size-12" / "tmp"))
    preview = subprocess.run(
        [sys.executable, str(scripts / "context-migrator.py"), "plan", "--registry", str(registry),
         "--source", "cursor/ide", "--target", "cline/ide", "--workspace", str(project),
         "--scope", "project", "--objects", "mcp", "--json"],
        capture_output=True, text=True, env=environment, check=True,
    )
    document = json.loads(preview.stdout)
    assert document["items"][0]["status"] == "ready-lossy", document
    change = document["items"][0]["review_preview"]["changes"][0]
    assert change["added"] == ["new"] and change["removed"] == ["removed"], change
    assert change["updated"] == ["edit", "redacted"] and change["unchanged"] == ["stable"], change
    assert change["changed_fields"] == {"edit": ["args", "disabled", "env"], "redacted": ["env"]}, change
    assert credential not in preview.stdout + preview.stderr
    assert benchmark["file_hashes"](project) == original
    assert not (project / ".agent-context-migration").exists()
    print("OK zero-write semantic MCP preview reports updated fields without credential values")

    # Bounded Python allocation is an observable resource invariant, not a
    # timing threshold. The expected digests use independent known bytes.
    asset_directory = root / "large-package"
    asset_directory.mkdir()
    asset = asset_directory / "asset.bin"
    block = b"\0" * (1024 * 1024)
    file_digest = hashlib.sha256()
    tree_digest = hashlib.sha256(b"asset.bin\0")
    with asset.open("wb") as writer:
        for _ in range(32):
            writer.write(block)
            file_digest.update(block)
            tree_digest.update(block)
    for name, operation, expected in (
        ("file", lambda: hash_path(asset), file_digest.hexdigest()),
        ("directory", lambda: hash_path(asset_directory), tree_digest.hexdigest()),
        ("bundle", lambda: sha256_file(asset), file_digest.hexdigest()),
    ):
        tracemalloc.start()
        try:
            actual = operation()
            _, peak = tracemalloc.get_traced_memory()
        finally:
            tracemalloc.stop()
        assert actual == expected, (name, actual, expected)
        assert peak < 8 * 1024 * 1024, (name, peak)
    print("OK large-file and directory digests retain SHA-256 semantics with bounded memory")

    # Invalid benchmark inputs and used report paths refuse before any case.
    used_report = root / "report.json"
    used_report.write_text("existing report\n", encoding="utf-8")
    for arguments in (("--sizes", "0"), ("--sizes", "1,1"),
                      ("--sizes", "1", "--report", str(used_report))):
        failed = subprocess.run([sys.executable, str(benchmark_path), *arguments],
                                capture_output=True, text=True, check=False)
        assert failed.returncode != 0, arguments
        assert "1: plan" not in failed.stderr, failed.stderr
        assert used_report.read_text() == "existing report\n"
    print("OK benchmark input/report preflight preserves existing outputs")

print("Scale invariants passed")
PY
