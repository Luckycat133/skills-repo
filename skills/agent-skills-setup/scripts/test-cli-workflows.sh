#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$SCRIPT_DIR" <<'PY'
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import runpy
import shlex
import subprocess
import sys
import tempfile

script_dir = Path(sys.argv[1])
skill_root = script_dir.parent
sys.path.insert(0, str(script_dir))
cli = runpy.run_path(str(script_dir / "context-migrator.py"))
from migration_core import Registry

registry_path = skill_root / "references" / "registry-v2.json"
with tempfile.TemporaryDirectory(prefix="cli-workflows-") as task_dir:
    task_root = Path(task_dir)
    registry = Registry(registry_path, task_root, home=task_root)
    parser = cli["create_parser"]()
    checked_commands = 0
    for name in ("cli-workflow.md", "bundle-workflow.md"):
        text = (skill_root / "references" / name).read_text(encoding="utf-8")
        for block in re.findall(r"```bash\n(.*?)\n```", text, re.DOTALL):
            for line in block.replace("\\\n", " ").splitlines():
                tokens = shlex.split(line)
                if tokens[:2] != ["bash", "$migrator"]:
                    continue
                command_args = tokens[2:]
                if command_args[0] == "legacy":
                    cli["reject_legacy_write"](command_args[1:])
                else:
                    args = parser.parse_args(command_args)
                    for field in ("source", "target"):
                        value = getattr(args, field, None)
                        if value and value not in ("auto", "all-installed"):
                            registry.profile(value)
                checked_commands += 1
    assert checked_commands >= 15, checked_commands

    # Preserve real profile semantics while confining every surface to the
    # temporary project trees. No personal configuration or HOME overrides.
    raw = json.loads(registry_path.read_text(encoding="utf-8"))
    selected = {"cursor": "ide", "claude": "code-cli", "cline": "ide"}
    fixture_registry = copy.deepcopy(raw)
    fixture_registry["products"] = {}
    for product_name, profile_name in selected.items():
        product = copy.deepcopy(raw["products"][product_name])
        profile = product["profiles"][profile_name]
        profile["detection"] = []
        profile["platforms"] = {}
        profile["surfaces"] = {
            kind: [
                {key: value for key, value in surface.items()
                 if key not in ("compatibility_paths", "override_env", "override_relative_path")}
                for surface in surfaces if surface.get("scope") == "project"
            ]
            for kind, surfaces in profile["surfaces"].items()
            if kind in ("skills", "instructions", "mcp")
        }
        product["profiles"] = {profile_name: profile}
        product["default_profile"] = profile_name
        fixture_registry["products"][product_name] = product
    fixture_registry_path = task_root / "registry.json"
    fixture_registry_path.write_text(json.dumps(fixture_registry), encoding="utf-8")
    old = task_root / "old-project"
    new = task_root / "new-project"
    old.mkdir()
    new.mkdir()
    skill = old / ".cursor" / "skills" / "fixture"
    skill.mkdir(parents=True)
    (skill / "SKILL.md").write_text(
        "---\nname: fixture\ndescription: Test fixture.\n---\n# Fixture\nReview sources.\n",
        encoding="utf-8",
    )
    rules = old / ".cursor" / "rules"
    rules.mkdir()
    (rules / "review.mdc").write_text(
        "---\ndescription: Review\nalwaysApply: true\n---\nReview sources.\n",
        encoding="utf-8",
    )
    (old / ".cursor" / "mcp.json").write_text(
        '{"mcpServers":{"fixture":{"command":"python3","args":["-c","pass"]}}}',
        encoding="utf-8",
    )
    source_hashes = {
        path.relative_to(old): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in old.rglob("*") if path.is_file()
    }
    environment = dict(os.environ)
    environment["AGENT_SKILLS_PLATFORM"] = "linux"

    def run(*arguments: object) -> dict:
        result = subprocess.run(
            [sys.executable, str(script_dir / "context-migrator.py"),
             *(str(argument) for argument in arguments)],
            capture_output=True, text=True, env=environment, check=False,
        )
        assert result.returncode == 0, (arguments, result.stdout, result.stderr)
        return json.loads(result.stdout)

    def scoped(
        command: str,
        workspace: Path,
        target: str = "claude/code-cli",
        objects: str = "skills,instructions,mcp",
    ) -> list[object]:
        return [command, "--registry", fixture_registry_path,
                "--source", "cursor/ide", "--target", target,
                "--workspace", workspace, "--scope", "project",
                "--objects", objects]

    preview = run(*scoped("plan", old), "--json")
    assert len(preview["items"]) == 3, preview
    assert [item["status"] for item in preview["items"]] == ["ready", "ready-lossy", "ready"], preview
    assert not (old / ".claude").exists()
    assert not (old / ".mcp.json").exists()
    assert not (old / ".agent-context-migration").exists()

    plan = task_root / "migrate-plan.json"
    manifest = task_root / "migrate-manifest.json"
    verification = task_root / "migrate-verify.json"
    migrated = run(*scoped("migrate", old), "--plan-out", plan,
                   "--manifest-out", manifest, "--verify-out", verification,
                   "--accept-loss", "1:instructions", "--yes", "--json")
    assert migrated["summary"]["applied"] == 2, migrated
    assert migrated["summary"]["applied-lossy"] == 1, migrated
    assert json.loads((old / ".mcp.json").read_text())["mcpServers"]
    assert run("verify", "--manifest", manifest, "--json")["ok"] is True
    assert run("rollback", "--manifest", manifest, "--yes", "--json")["restored"] == 3
    assert not (old / ".mcp.json").exists()

    bundle = task_root / "project.acb"
    snapshot_args = scoped("snapshot", old, "cursor/ide", "skills,instructions,mcp")
    captured = run(*snapshot_args, "--output", bundle, "--json")
    assert captured["objects_captured"] == 3, captured
    assert run("bundle-verify", bundle, "--json")["ok"] is True
    assert run("doctor", bundle, "--json")["missing_executables"] == []

    restore_plan = task_root / "restore-plan.json"
    restore_manifest = task_root / "restore-manifest.json"
    reviewed = run("restore", bundle, *scoped("restore", new, "cline/ide", "skills,instructions,mcp")[1:],
                   "--plan-only", "--plan-out", restore_plan, "--json")
    assert reviewed["stage"] == "plan", reviewed
    assert not (new / ".cline").exists()
    restored = run("restore", bundle, *scoped("restore", new, "cline/ide", "skills,instructions,mcp")[1:],
                   "--plan-in", restore_plan, "--manifest-out", restore_manifest,
                   "--include", "lossy", "--yes", "--json")
    assert restored["summary"]["applied"] == 2, restored
    assert restored["summary"]["applied-lossy"] == 1, restored
    assert run("verify", "--manifest", restore_manifest, "--json")["ok"] is True
    assert (new / ".cline" / "skills" / "fixture" / "SKILL.md").read_bytes() == (skill / "SKILL.md").read_bytes()
    assert run("rollback", "--manifest", restore_manifest, "--yes", "--json")["restored"] == 3
    for relative, digest in source_hashes.items():
        assert hashlib.sha256((old / relative).read_bytes()).hexdigest() == digest

print(f"CLI workflow test passed ({checked_commands} documented commands; scoped migrate/restore/verify/rollback)")
PY
