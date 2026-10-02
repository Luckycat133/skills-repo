#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$SCRIPT_DIR" <<'PY'
from __future__ import annotations

import copy
import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile

script_dir = Path(sys.argv[1])
sys.path.insert(0, str(script_dir))
generator_path = script_dir / "generate-compatibility-matrix.py"
matrix = runpy.run_path(str(generator_path))
adapter = matrix["TIER_ADAPTER"]
e2e = matrix["TIER_E2E"]
manual = matrix["TIER_MANUAL"]

def profile() -> dict:
    return {
        "migration_policy": "bidirectional-reviewed",
        "surfaces": {
            kind: [
                {"scope": scope, "path": f".{kind}", "storage": storage,
                 "format": format_name, "policy": policy}
                for scope in ("user", "project")
            ]
            for kind, storage, format_name, policy in (
                ("skills", "directory", "agent-skill", "validate-then-atomic-copy"),
                ("instructions", "file", "plain-markdown", "semantic-ir-with-loss-report"),
                ("mcp", "file", "json:mcpServers", "profile-version-adapter"),
            )
        },
    }

source = profile()
target = profile()
coverage = {("a/cli", "b/cli", "project"): {"skills"}}

def tier(
    object_type: str,
    target_profile: dict = target,
    overrides: dict | None = None,
) -> str:
    return matrix["classify_pair"](
        source, target_profile, object_type, "project", "a/cli", "b/cli",
        coverage, overrides or {},
    )

assert tier("skills") == e2e
assert tier("instructions") == adapter
assert tier("mcp") == adapter
assert matrix["classify_pair"](
    target, source, "skills", "project", "b/cli", "a/cli", coverage, {},
) == adapter, "forward test evidence must not imply reverse coverage"

for native_format in ("toml:mcp_servers", "yaml:mcpServers", "json5:mcpServers", "json:unsupported"):
    unsupported = copy.deepcopy(target)
    unsupported["surfaces"]["mcp"][1]["format"] = native_format
    assert tier("mcp", unsupported) == manual, native_format
    assert tier("mcp", unsupported, {"b/cli": {"project:mcp": e2e}}) == manual
    assert tier("skills", unsupported) == e2e, "one manual object must not demote others"
for field, value in (("policy", "manual-template"), ("transport", "http"), ("storage", "directory")):
    unsupported = copy.deepcopy(target)
    unsupported["surfaces"]["mcp"][1][field] = value
    assert tier("mcp", unsupported) == manual, (field, value)
assert tier("skills", target, {"a/cli": {"skills": manual}}) == manual
assert tier("skills", target, {"a/cli": {"skills": e2e}, "b/cli": {"skills": manual}}) == manual
unsupported = copy.deepcopy(target)
unsupported["surfaces"]["instructions"][1]["format"] = "unknown-rule"
assert tier("instructions", unsupported) == manual

real_registry = json.loads((script_dir.parent / "references" / "registry-v2.json").read_text(encoding="utf-8"))
claude = real_registry["products"]["claude"]["profiles"]["code-cli"]
codex = real_registry["products"]["codex"]["profiles"]["cli"]
assert matrix["classify_pair"](
    claude, codex, "mcp", "project", "claude/code-cli", "codex/cli",
    {("claude/code-cli", "codex/cli", "project"): {"mcp"}}, {},
) == manual, "Codex TOML must remain manual even with pair-level MCP test evidence"

with tempfile.TemporaryDirectory(prefix="compatibility-matrix-") as task_dir:
    root = Path(task_dir)
    scripts = root / "scripts"
    scripts.mkdir()
    (scripts / "test-scoped.sh").write_text('''bash tool migrate --source a/cli --target b/cli --scope project --objects skills --yes
bash tool migrate --source c/cli --target d/cli --scope user --objects mcp --yes
bash tool plan --source a/cli --target b/cli --scope project --objects instructions
bash tool migrate --source a/cli --target b/cli --scope user --objects mcp --plan-only --yes
bash tool legacy --source a/cli --target b/cli --scope project --objects mcp --yes
if bash tool migrate --source a/cli --target b/cli --scope project --objects mcp --yes; then exit 1; fi
bash tool migrate --source a/cli --target b/cli --scope project --objects hooks --yes
bash tool migrate --source a/cli --target b/cli --scope project --objects instructions --yes || true
# bash tool migrate --source a/cli --target d/cli --scope all --objects all-portable --yes
''', encoding="utf-8")
    registry = {
        "products": {
            name: {"default_profile": "cli", "profiles": {"cli": profile()}}
            for name in ("a", "b", "c", "d", "toml")
        }
    }
    registry["products"]["toml"]["profiles"]["cli"]["surfaces"]["mcp"][1]["format"] = "toml:mcp_servers"
    scanned = matrix["scan_test_scripts"](scripts, registry)
    assert scanned == {
        ("a/cli", "b/cli", "project"): {"skills"},
        ("c/cli", "d/cli", "user"): {"mcp"},
    }, scanned
    fixtures = matrix["build_fixture_index"](scripts, registry)
    assert set(fixtures) == {("a/cli", "b/cli"), ("c/cli", "d/cli")}, fixtures

    registry_path = root / "registry.json"
    registry_path.write_text(json.dumps(registry), encoding="utf-8")
    paths = root / "paths.tsv"
    paths.write_text("product\tsurface_type\tscope\tpath\n", encoding="utf-8")
    overrides = root / "overrides.json"
    overrides.write_text('{"tiers":{}}', encoding="utf-8")
    output = root / "matrix.md"
    command = [sys.executable, str(generator_path), "--registry", str(registry_path),
               "--paths", str(paths), "--overrides", str(overrides),
               "--scripts-dir", str(scripts), "--output", str(output)]
    subprocess.run(command, capture_output=True, text=True, check=True)
    generated = output.read_text(encoding="utf-8")
    assert "| `a/cli` | `toml/cli` | project | Adapter-Compatible | Adapter-Compatible | Manual / Rebuild |" in generated
    assert "| source_profile | target_profile | scope | skills | instructions | mcp | evidence | test_fixture |" in generated
    subprocess.run([*command, "--check"], capture_output=True, text=True, check=True)
    output.write_text(generated + "stale\n", encoding="utf-8")
    stale = subprocess.run([*command, "--check"], capture_output=True, text=True, check=False)
    assert stale.returncode == 1
    assert output.read_text(encoding="utf-8").endswith("stale\n"), "--check must never rewrite output"

print("Compatibility matrix test passed (per-object adapters, directional coverage, overrides, freshness)")
PY
