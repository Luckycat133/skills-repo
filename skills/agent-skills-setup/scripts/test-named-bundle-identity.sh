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

import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Any

script_dir = Path(sys.argv[1])
test_root = Path(sys.argv[2]).resolve()
sys.path.insert(0, str(script_dir))
from migration_core import _plan_hash_payload, json_sha256

registry = json.loads((script_dir.parent / "references" / "registry-v2.json").read_text(encoding="utf-8"))
selected = {"cursor": "ide", "claude": "code-cli"}
products = {}
for product_name, profile_name in selected.items():
    product = copy.deepcopy(registry["products"][product_name])
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
    products[product_name] = product
registry["products"] = products
registry_path = test_root / "registry.json"
registry_path.write_text(json.dumps(registry), encoding="utf-8")
old = test_root / "old-project"
skill = old / ".cursor" / "skills" / "lint-helper"
(skill / "references").mkdir(parents=True)
(skill / "SKILL.md").write_text(
    "---\nname: lint-helper\ndescription: Review lint output.\n---\n"
    "Read [rules](references/rules.md).\n", encoding="utf-8"
)
(skill / "references" / "rules.md").write_text("Report file paths and diagnostics.\n", encoding="utf-8")
rules = old / ".cursor" / "rules"
rules.mkdir()
(rules / "review.mdc").write_text(
    "---\ndescription: Project review\nalwaysApply: true\n---\nReview changes.\n",
    encoding="utf-8",
)
mcp = {"mcpServers": {"fixture": {"command": "python3", "args": ["-m", "fixture_module"]}}}
(old / ".cursor" / "mcp.json").write_text(json.dumps(mcp), encoding="utf-8")
temporary_dir = test_root / "tmp"
temporary_dir.mkdir()
environment = dict(os.environ)
environment["AGENT_SKILLS_PLATFORM"] = "linux"
environment["PYTHONDONTWRITEBYTECODE"] = "1"
environment["TMPDIR"] = str(temporary_dir)


def run(*arguments: object, failure: str | None = None) -> dict[str, Any]:
    result = subprocess.run(
        [sys.executable, str(script_dir / "context-migrator.py"),
         *(str(argument) for argument in arguments)],
        cwd=test_root, env=environment, capture_output=True, text=True, check=False,
    )
    assert result.returncode == (1 if failure else 0), (arguments, result.returncode, result.stdout, result.stderr)
    if failure:
        assert failure in result.stdout + result.stderr, (result.stdout, result.stderr)
        output = json.loads(result.stdout) if result.stdout.strip() else {"error": result.stderr}
        assert output.get("ok") is not True, output
    else:
        output = json.loads(result.stdout)
    return output


def scoped(workspace: Path) -> list[object]:
    return ["--registry", registry_path, "--source", "cursor/ide", "--target", "claude/code-cli",
            "--workspace", workspace, "--scope", "project", "--objects", "skills,instructions,mcp"]


def tree_state(root: Path) -> dict[str, tuple[str, str | None]]:
    return {
        str(path.relative_to(root)): (
            "file" if path.is_file() else "directory",
            hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None,
        )
        for path in sorted(root.rglob("*"))
    }


def save_plan(path: Path, document: dict[str, Any]) -> None:
    document["plan_sha256"] = json_sha256(_plan_hash_payload(document))
    path.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")


bundle = test_root / "original.acb"
captured = run("snapshot", *scoped(old), "--output", bundle, "--json")
assert captured["objects_captured"] == 3, captured
manifest_bytes = (bundle / "manifest.json").read_bytes()
bundle_manifest = json.loads(manifest_bytes)
objects = {obj["object_id"]: obj for obj in bundle_manifest["objects"]}
# A distinct genuine snapshot has the same object content. Binding only source
# hashes would accept it even though it is a different reviewed backup.
wrong_bundle = test_root / "wrong.acb"
run("snapshot", *scoped(old), "--output", wrong_bundle, "--json")
plans = {}
for name in ("restore", "apply", "legacy"):
    destination = test_root / f"{name}-project"
    destination.mkdir()
    plan_path = test_root / f"{name}-plan.json"
    result = run("restore", bundle, *scoped(destination), "--plan-only", "--plan-out", plan_path, "--json")
    document = json.loads(plan_path.read_text(encoding="utf-8"))
    assert result["plan_document"] == document, result
    assert document.get("bundle_source") == {
        "bundle_id": bundle_manifest["bundle_id"],
        "manifest_sha256": hashlib.sha256(manifest_bytes).hexdigest(),
    }, document
    assert len(document["items"]) == 3, document
    for item in document["items"]:
        obj = objects[item["object_id"]]
        assert item["acb_uri"] == f"acb://{bundle_manifest['bundle_id']}#{obj['object_id']}", item
        for field in ("product", "profile", "scope"):
            assert item["source"][field] == obj[field], item
        assert item["object_type"] == item["source"]["object_type"] == obj["surface"], item
        assert not Path(item["source"]["boundary"]).exists(), "planning staging leaked"
    assert tree_state(destination) == {}, "plan-only wrote product targets"
    plans[name] = (destination, plan_path, document, plan_path.read_bytes())

source_before = tree_state(old)
old.rename(test_root / "held-old-project")
assert not old.exists()
moved = test_root / "moved" / "device.acb"
moved.parent.mkdir()
shutil.move(str(bundle), str(moved))
assert not bundle.exists()
bundle_before = tree_state(moved)
destination, plan_path, document, reviewed_bytes = plans["restore"]


def rejected(plan: Path, supplied_bundle: Path, error: str, label: str) -> None:
    output_path = test_root / f"rejected-{label}.json"
    before = tree_state(destination)
    run("restore", supplied_bundle, *scoped(destination), "--plan-in", plan,
        "--manifest-out", output_path, "--include", "lossy", "--yes", "--json", failure=error)
    assert tree_state(destination) == before and not output_path.exists(), label


rejected(plan_path, wrong_bundle, "bundle source identity", "wrong-bundle")
for field, value in (("product", "claude"), ("profile", "other"), ("scope", "local"), ("object_type", "mcp")):
    tampered = copy.deepcopy(document)
    tampered["items"][0]["source"][field] = value
    path = test_root / f"tampered-{field}.json"
    save_plan(path, tampered)
    rejected(path, moved, "bundle source", field)
tampered = copy.deepcopy(document)
tampered["items"][0]["acb_uri"] = "acb://wrong-bundle#" + tampered["items"][0]["object_id"]
path = test_root / "tampered-uri.json"
save_plan(path, tampered)
rejected(path, moved, "bundle source URI", "uri")
tampered = copy.deepcopy(document)
tampered["items"][0]["object_id"] = next(obj_id for obj_id in objects if obj_id != tampered["items"][0]["object_id"])
tampered["items"][0]["acb_uri"] = f"acb://{bundle_manifest['bundle_id']}#{tampered['items'][0]['object_id']}"
path = test_root / "tampered-object.json"
save_plan(path, tampered)
rejected(path, moved, "bundle source", "object")
tampered = copy.deepcopy(document)
tampered["items"][0]["acb_uri"] = None
path = test_root / "tampered-missing-uri.json"
save_plan(path, tampered)
rejected(path, moved, "bundle source URI", "missing-uri")
missing_manifest = test_root / "missing-bundle-manifest.json"
run("apply", plan_path, "--registry", registry_path, "--manifest", missing_manifest,
    "--include", "lossy", "--yes", "--json", failure="bundle-backed plans require --bundle")
assert tree_state(destination) == {} and not missing_manifest.exists()
print("OK wrong bundles, altered source identities and missing --bundle fail before target writes")

empty_id_bundle = test_root / "empty-id.acb"
shutil.copytree(moved, empty_id_bundle)
empty_manifest = copy.deepcopy(bundle_manifest)
empty_manifest["objects"][0]["object_id"] = ""
empty_manifest_path = empty_id_bundle / "manifest.json"
empty_manifest_path.write_text(
    json.dumps(empty_manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8",
)
checksums_path = empty_id_bundle / "checksums.json"
checksums = json.loads(checksums_path.read_text(encoding="utf-8"))
checksums["manifest.json"] = hashlib.sha256(empty_manifest_path.read_bytes()).hexdigest()
checksums_path.write_text(json.dumps(checksums, indent=2, sort_keys=True) + "\n", encoding="utf-8")
assert run("bundle-verify", empty_id_bundle, "--json")["ok"] is True
empty_plan = test_root / "empty-id-plan.json"
before = tree_state(destination)
run("restore", empty_id_bundle, *scoped(destination), "--plan-only", "--plan-out", empty_plan,
    "--json", failure="bundle source object identity must be a non-empty string")
assert tree_state(destination) == before and not empty_plan.exists()
print("OK checksum-valid empty captured IDs fail before plan or target writes")

restore_manifest = test_root / "restore-manifest.json"
restored = run("restore", moved, *scoped(destination), "--plan-in", plan_path,
               "--manifest-out", restore_manifest, "--include", "lossy", "--yes", "--json")
assert sum(restored["summary"].get(key, 0) for key in ("applied", "applied-lossy")) == 3, restored
assert restored["plan_sha256"] == document["plan_sha256"], restored
assert plan_path.read_bytes() == reviewed_bytes, "restore modified the exact reviewed plan"
assert run("verify", "--manifest", restore_manifest, "--json")["ok"] is True
assert (destination / ".claude" / "skills" / "lint-helper" / "SKILL.md").read_bytes() == (test_root / "held-old-project" / ".cursor" / "skills" / "lint-helper" / "SKILL.md").read_bytes()
assert (destination / "CLAUDE.md").read_text(encoding="utf-8") == "Review changes.\n"
assert json.loads((destination / ".mcp.json").read_text(encoding="utf-8")) == mcp
assert run("rollback", "--manifest", restore_manifest, "--yes", "--json")["restored"] == 3
assert not any(path.is_file() for path in destination.rglob("*"))
print("OK source-absent cross-process named restore preserves plan bytes/hash and rolls back")

for name in ("apply", "legacy"):
    target, apply_plan, reviewed, original_bytes = plans[name]
    if name == "legacy":
        legacy = copy.deepcopy(reviewed)
        legacy.pop("bundle_source")
        for item in legacy["items"]:
            item["acb_uri"] = None
        save_plan(apply_plan, legacy)
        reviewed = legacy
        original_bytes = apply_plan.read_bytes()
    applied_manifest = test_root / f"{name}-manifest.json"
    result = run("apply", apply_plan, "--registry", registry_path, "--bundle", moved,
                 "--manifest", applied_manifest, "--include", "lossy", "--yes", "--json")
    assert result["plan_sha256"] == reviewed["plan_sha256"] and len(result["changes"]) == 3, result
    assert apply_plan.read_bytes() == original_bytes
    assert run("verify", "--manifest", applied_manifest, "--json")["ok"] is True
    assert run("rollback", "--manifest", applied_manifest, "--yes", "--json")["restored"] == 3
    assert not any(path.is_file() for path in target.rglob("*"))
assert tree_state(moved) == bundle_before
assert tree_state(test_root / "held-old-project") == source_before
print("OK generic --bundle apply preserves modern and legacy named plans without changing source bytes")
print("Named bundle identity tests passed")
PY
