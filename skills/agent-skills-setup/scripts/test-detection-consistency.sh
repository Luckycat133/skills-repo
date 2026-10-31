#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$SCRIPT_DIR" <<'PY'
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

scripts = Path(sys.argv[1])
sys.path.insert(0, str(scripts))
from migration_core import Registry

spec = importlib.util.spec_from_file_location("context_migrator", scripts / "context-migrator.py")
cli = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cli)

with tempfile.TemporaryDirectory(prefix="detection-consistency-") as temporary:
    root = Path(temporary).resolve()
    home = root / "home"
    workspace = home / "project"
    skill = workspace / ".fixture" / "skills" / "fixture-skill"
    skill.mkdir(parents=True)
    (skill / "SKILL.md").write_text(
        "---\nname: fixture-skill\ndescription: Isolated fixture.\n---\n# Fixture\n",
        encoding="utf-8",
    )
    (workspace / "AGENTS.md").write_text("Shared guidance\n", encoding="utf-8")
    (workspace / ".mcp.json").write_text('{"mcpServers": {}}\n', encoding="utf-8")
    (home / ".environment-proof").write_text("proof\n", encoding="utf-8")
    profile = {
        "kind": "ide",
        "migration_policy": "bidirectional-reviewed",
        "detection": [{"type": "file-signature", "paths": ["AGENTS.md"]}],
        "surfaces": {"skills": [{
            "scope": "project", "storage": "directory", "path": ".fixture/skills",
            "format": "agent-skills", "policy": "copy-review",
        }]},
    }
    data = {
        "schema_version": 2,
        "profile_templates": {"manual-reference": {
            "profile": "manual", "kind": "ide", "migration_policy": "manual-reference",
            "surfaces": {},
        }},
        "products": {
            "fixture": {"default_profile": "base", "profiles": {
                "base": profile,
                "child": {"inherits": "base"},
            }},
            "destination": {"default_profile": "cli", "profiles": {"cli": {
                **profile, "surfaces": {},
            }}},
            "environment": {"default_profile": "cli", "profiles": {"cli": {
                **profile, "surfaces": {},
                "detection": [{"type": "file-signature", "paths": ["$AGENT_SKILLS_TEST_DETECTION_HOME/.environment-proof"]}],
            }}},
            "fixture-alias": {"alias_of": {"product": "fixture", "profile": "child"}},
            "shared-mcp": {"default_profile": "cli", "profiles": {"cli": {
                **profile,
                "detection": [],
                "surfaces": {"mcp": [{
                    "scope": "project", "storage": "file", "path": ".mcp.json",
                    "format": "json:mcpServers", "policy": "profile-version-adapter",
                }]},
            }}},
            "manual": {"template": "manual-reference"},
        },
    }
    registry_path = root / "registry.json"
    registry_path.write_text(json.dumps(data), encoding="utf-8")
    previous = os.environ.get("AGENT_SKILLS_TEST_DETECTION_HOME")
    os.environ["AGENT_SKILLS_TEST_DETECTION_HOME"] = str(home)
    try:
        registry = Registry(registry_path, workspace, home)
        detected, statuses = cli._select_installed_profiles(registry)
        assert detected == {"fixture/base", "fixture/child", "environment/cli"}, detected
        restored, restore_statuses = cli._detect_target_profiles_for_restore(registry, workspace)
        assert (restored, restore_statuses) == (detected, statuses)
        compatible, _ = cli._select_installed_profiles(registry, include_compatibility=True)
        assert "destination/cli" in compatible
        assert "shared-mcp/cli" in compatible
        assert statuses["destination/cli"] == "compatibility-only"
        assert statuses["shared-mcp/cli"] == "compatibility-only"
        assert statuses["manual/manual"] == "not-detected"
        alias = cli._registry_profile_detections(registry, "fixture-alias")
        assert len(alias) == 1 and alias[0].profile == "child", alias

        environment = dict(os.environ, HOME=str(home))
        def command(*arguments):
            return subprocess.run(
                [sys.executable, str(scripts / "context-migrator.py"), *arguments],
                capture_output=True, text=True, env=environment, check=False,
            )
        options = ["--registry", str(registry_path), "--workspace", str(workspace), "--json"]
        result = command("detect", *options)
        assert result.returncode == 0, result.stderr
        reported = json.loads(result.stdout)["detections"]
        assert {f"{row['product']}/{row['profile']}": row["state"] for row in reported} == statuses
        result = command("detect", *options, "--product", "fixture-alias")
        assert result.returncode == 0, result.stderr
        assert json.loads(result.stdout)["detections"][0]["profile"] == "child"
        result = command("detect", *options, "--product", "fixture/child")
        assert result.returncode == 0, result.stderr
        assert len(json.loads(result.stdout)["detections"]) == 1
        result = command("detect", *options, "--product", "fixture/child", "--profile", "base")
        assert result.returncode != 0 and "conflicting profiles" in result.stderr
        result = command("detect", *options, "--product", "not-a-product")
        assert result.returncode != 0
        assert "unknown" in result.stderr.lower(), result
        result = command("snapshot", *options, "--all-installed", "--scope", "project", "--objects", "skills", "--output", str(root / "device.acb"))
        assert result.returncode == 0, result.stderr
        summary = json.loads(result.stdout)["summary"]
        assert summary["detection_status"] == statuses
        assert set(summary["installed_products"]) == detected
        assert summary.get("failed_products") == [], summary
        print("PASS: detect, snapshot and restore share resolved profiles and detection states")
        print("PASS: inherited/alias profiles, environment paths and projects under HOME remain detectable")
        print("PASS: shared compatibility paths stay opt-in and unknown products fail")
    finally:
        if previous is None:
            os.environ.pop("AGENT_SKILLS_TEST_DETECTION_HOME", None)
        else:
            os.environ["AGENT_SKILLS_TEST_DETECTION_HOME"] = previous
PY
