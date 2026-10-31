#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$SCRIPT_DIR" <<'PY'
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

scripts = Path(sys.argv[1])
sys.path.insert(0, str(scripts))
from migration_core import resolve_output_path

if sys.platform == "darwin" and Path("/tmp").is_symlink():
    assert resolve_output_path(Path("/tmp/output-fixture")) == Path("/private/tmp/output-fixture")
    with patch("migration_core.sys.platform", "linux"):
        try:
            resolve_output_path(Path("/tmp/output-fixture"))
        except ValueError as error:
            assert "symbolic" in str(error)
        else:
            raise AssertionError("non-macOS output allowed an arbitrary system-root symlink")
with tempfile.TemporaryDirectory(prefix="migrate-artifacts-") as temporary:
    root = Path(temporary).resolve()
    home = root / "home"
    workspace = root / "workspace"
    workspace.mkdir()
    source = home / ".cline" / "skills" / "fixture-skill"
    source.mkdir(parents=True)
    source_file = source / "SKILL.md"
    source_file.write_text("---\nname: fixture-skill\ndescription: Artifact fixture.\n---\n# Fixture\n", encoding="utf-8")
    registry_path = root / "registry.json"
    data = json.loads((scripts.parent / "references" / "registry-v2.json").read_text(encoding="utf-8"))
    data["products"] = {key: data["products"][key] for key in ("cline", "forge", "cursor")}
    registry_path.write_text(json.dumps(data), encoding="utf-8")
    unrelated = home / ".cursor" / "skills"
    unrelated.mkdir(parents=True)
    environment = dict(os.environ, HOME=str(home), AGENT_SKILLS_PLATFORM="linux")
    def command(*arguments):
        return subprocess.run(
            [sys.executable, str(scripts / "context-migrator.py"), "migrate",
             "--registry", str(registry_path), "--workspace", str(workspace),
             "--source", "cline/ide", "--target", "forge/cli", "--scope", "user",
             "--objects", "skills", "--json", *arguments],
            capture_output=True, text=True, env=environment, check=False,
        )
    source_hash = hashlib.sha256(source_file.read_bytes()).hexdigest()
    plan_path = root / "review-plan.json"
    for arguments in (
        ["--plan-out", str(source_file)],
        ["--manifest-out", str(source_file)],
        ["--verify-out", str(source_file)],
        ["--plan-out", str(plan_path), "--manifest-out", str(plan_path)],
        ["--plan-out", str(plan_path), "--verify-out", str(plan_path)],
        ["--verify-out", str(registry_path)],
    ):
        result = command("--yes", *arguments)
        assert result.returncode != 0, result
        assert "overlap" in result.stderr, result.stderr
        assert hashlib.sha256(source_file.read_bytes()).hexdigest() == source_hash
        assert not (home / "forge").exists()
        assert not (workspace / ".migration").exists()
        assert not plan_path.exists()
    print("PASS: every migration output is checked before plan or target writes")

    linked = root / "linked-report.json"
    try:
        linked.symlink_to(source_file)
    except OSError:
        print("SKIP: host does not permit fixture symlinks")
    else:
        result = command("--yes", "--verify-out", str(linked))
        assert result.returncode != 0 and "symbolic" in result.stderr, result
        assert hashlib.sha256(source_file.read_bytes()).hexdigest() == source_hash
        assert not (home / "forge").exists()

    result = command("--plan-only", "--scope", "all", "--plan-out", str(plan_path))
    assert result.returncode == 0, result.stderr
    assert json.loads(plan_path.read_text(encoding="utf-8"))["scope"] == "all"
    result = command("--plan-only", "--scope", "user+project", "--objects", "skills,prompts,trust", "--plan-out", str(plan_path))
    assert result.returncode == 0, result.stderr
    document = json.loads(plan_path.read_text(encoding="utf-8"))
    assert document["scope"] == "user,project"
    assert document["objects"] == ["skills", "prompts", "trust"]
    assert {item["object_type"] for item in document["items"]} == {"skills", "prompts", "trust"}
    assert not (home / "forge").exists()
    print("PASS: preview accepts all scopes without apply consent and retains requested manual objects")

    result = command("--yes")
    assert result.returncode == 0, result.stderr
    output = json.loads(result.stdout)
    assert {row["product"] for row in output["detected"]} <= {"cline", "forge"}, output
    assert (home / "forge" / "skills" / "fixture-skill" / "SKILL.md").read_bytes() == source_file.read_bytes()
    verify = json.loads(Path(output["verify"]).read_text(encoding="utf-8"))
    assert verify["ok"] is True
    saved_plan = Path(output["plan"]).read_bytes()
    result = command("--yes")
    assert result.returncode != 0 and "manifest path already exists" in result.stderr, result
    assert Path(output["plan"]).read_bytes() == saved_plan
    print("PASS: migrate reports only named products, verifies output and preserves reviewed artifacts on rerun")
PY
