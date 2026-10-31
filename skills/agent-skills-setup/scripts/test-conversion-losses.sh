#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$SCRIPT_DIR" <<'PY'
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

script_dir = Path(sys.argv[1])
migrator = script_dir / "context-migrator.py"
raw_registry = json.loads((script_dir.parent / "references/registry-v2.json").read_text())
environment = {**os.environ, "AGENT_SKILLS_PLATFORM": "linux", "PYTHONDONTWRITEBYTECODE": "1"}
sys.path.insert(0, str(script_dir))
from acb.bundle import ACBManifest, ACB_SCHEMA_VERSION, make_bundle_id, write_bundle
from migration_core import compute_object_id


def hashes(root: Path) -> dict[str, str]:
    return {
        str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in root.rglob("*") if path.is_file()
    }


def run(*arguments: object, success: bool = True) -> dict:
    result = subprocess.run(
        [sys.executable, str(migrator), *(str(argument) for argument in arguments)],
        capture_output=True, text=True, env=environment, check=False,
    )
    if not success:
        assert result.returncode != 0, (arguments, result.stdout, result.stderr)
        assert "non-applicable items" in result.stderr, result.stderr
        return {}
    assert result.returncode == 0, (arguments, result.stdout, result.stderr)
    return json.loads(result.stdout)


with tempfile.TemporaryDirectory(prefix="conversion-losses-") as task_name:
    task_root = Path(task_name)
    fixture_registry = copy.deepcopy(raw_registry)
    fixture_registry["products"] = {}
    for product_name in ("cursor", "cline"):
        product = copy.deepcopy(raw_registry["products"][product_name])
        profile = product["profiles"]["ide"]
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
        product["profiles"] = {"ide": profile}
        fixture_registry["products"][product_name] = product
    registry_path = task_root / "registry.json"
    registry_path.write_text(json.dumps(fixture_registry), encoding="utf-8")

    def fixture(name: str) -> tuple[Path, Path, dict[str, str], bytes]:
        workspace = task_root / name
        source = workspace / ".cursor"
        skill = source / "skills" / "portable"
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text(
            "---\nname: portable\ndescription: Conversion fixture.\n---\nKeep packages intact.\n",
            encoding="utf-8",
        )
        (skill / ".env.example").write_text("PUBLIC_HINT=fixture\n", encoding="utf-8")
        rules = source / "rules" / "nested"
        rules.mkdir(parents=True)
        (rules / "review.mdc").write_text(
            "---\ndescription: Review migrations\nalwaysApply: true\nfutureField: review\n---\nKeep changes atomic.\n",
            encoding="utf-8",
        )
        (source / "mcp.json").write_text(json.dumps({
            "mcpServers": {"demo": {
                "command": "python3", "args": ["-m", "demo_mcp"],
                "env": {"API_TOKEN": "fixture-literal-credential", "MODE": "safe"},
                "autoApprove": ["query"], "disabled": True,
            }},
        }), encoding="utf-8")
        target = workspace / ".cline" / "mcp.json"
        target.parent.mkdir()
        target.write_text('{"theme":"dark","mcpServers":{"old":{"command":"old"}}}\n', encoding="utf-8")
        return workspace, source, hashes(source), target.read_bytes()

    def scoped(command: str, workspace: Path, objects: str = "skills,instructions,mcp") -> list[object]:
        return [command, "--registry", registry_path, "--workspace", workspace,
                "--source", "cursor/ide", "--target", "cline/ide",
                "--scope", "project", "--objects", objects]

    def planned(workspace: Path) -> Path:
        path = task_root / f"{workspace.name}-plan.json"
        plan = run(*scoped("plan", workspace), "--output", path, "--json")
        assert [item["status"] for item in plan["items"]] == ["ready", "ready-lossy", "ready-lossy"], plan
        fields = {item["field"] for item in plan["loss_report"]["items"]}
        assert {"description", "hierarchy", "futureField", "demo.autoApprove", "demo.disabled", "demo.env.API_TOKEN"} <= fields, fields
        assert "portable/.env.example" in fields, fields
        assert "fixture-literal-credential" not in json.dumps(plan)
        assert all(item["review_preview"] for item in plan["items"]), plan
        assert not (workspace / ".agent-context-migration").exists()
        return path

    for name, flags, accepted in (
        ("default", [], set()),
        ("accept-instructions", ["--accept-loss", "1:instructions"], {"instructions"}),
        ("accept-mcp", ["--accept-loss", "2:mcp"], {"mcp"}),
        ("include-lossy", ["--include", "lossy"], {"instructions", "mcp"}),
    ):
        workspace, source, source_hashes, target_bytes = fixture(name)
        plan = planned(workspace)
        manifest_path = task_root / f"{name}-manifest.json"
        run("apply", plan, "--registry", registry_path, "--manifest", manifest_path,
            "--yes", *flags, "--json")
        manifest = json.loads(manifest_path.read_text())
        assert manifest["summary"].get("applied", 0) == 1, manifest
        assert manifest["summary"].get("applied-lossy", 0) == len(accepted), manifest
        assert manifest["summary"].get("lossy-skipped", 0) == 2 - len(accepted), manifest
        copied = workspace / ".cline" / "skills" / "portable"
        assert (copied / "SKILL.md").read_bytes() == (source / "skills" / "portable" / "SKILL.md").read_bytes()
        assert not (copied / ".env.example").exists()
        rule_files = list((workspace / ".cline" / "rules").rglob("*.md"))
        assert bool(rule_files) == ("instructions" in accepted), rule_files
        if rule_files:
            assert len(rule_files) == 1 and rule_files[0].read_text() == "Keep changes atomic.\n", rule_files
        target = workspace / ".cline" / "mcp.json"
        if "mcp" in accepted:
            output = json.loads(target.read_text())
            assert output["theme"] == "dark" and set(output["mcpServers"]) == {"demo"}, output
            server = output["mcpServers"]["demo"]
            assert server["env"] == {"API_TOKEN": "${API_TOKEN}", "MODE": "safe"}, server
            assert "autoApprove" not in server and "disabled" not in server, server
        else:
            assert target.read_bytes() == target_bytes
        loss_fields = {item["field"] for item in manifest["loss_report"]["items"]}
        assert ("description" in loss_fields) == ("instructions" in accepted), manifest
        assert ("demo.autoApprove" in loss_fields) == ("mcp" in accepted), manifest
        assert "portable/.env.example" in loss_fields
        assert "fixture-literal-credential" not in json.dumps(manifest)
        assert run("verify", "--manifest", manifest_path, "--json")["ok"] is True
        assert hashes(source) == source_hashes
        print(f"PASS {name}: applied safe package, accepted {sorted(accepted)}, deferred {2 - len(accepted)} conversions")

    workspace, source, source_hashes, target_bytes = fixture("strict")
    plan = planned(workspace)
    for name, flags in (("strict", ["--strict"]), ("no-apply-safe", ["--no-apply-safe"]),
                        ("strict-with-lossy", ["--strict", "--include", "lossy"])):
        manifest_path = task_root / f"{name}-refused.json"
        run("apply", plan, "--registry", registry_path, "--manifest", manifest_path,
            "--yes", *flags, "--json", success=False)
        assert not manifest_path.exists()
        assert not (workspace / ".cline" / "skills").exists()
        assert not (workspace / ".cline" / "rules").exists()
        assert (workspace / ".cline" / "mcp.json").read_bytes() == target_bytes
        assert hashes(source) == source_hashes
    print("PASS strict and no-apply-safe refuse lossy plans before all target writes")

    # Lossless stdio conversion still follows the ordinary ready path.
    clean = task_root / "clean"
    (clean / ".cursor").mkdir(parents=True)
    (clean / ".cursor" / "mcp.json").write_text(
        '{"mcpServers":{"demo":{"command":"python3","args":["-m","demo"],"env":{"MODE":"safe"}}}}',
        encoding="utf-8",
    )
    migrated = run(*scoped("migrate", clean, "mcp"), "--plan-out", task_root / "clean-plan.json",
                   "--manifest-out", task_root / "clean-manifest.json", "--verify-out", task_root / "clean-verify.json",
                   "--yes", "--json")
    assert migrated["summary"]["applied"] == 1, migrated
    assert json.loads((task_root / "clean-plan.json").read_text())["items"][0]["status"] == "ready"
    assert (clean / ".cline" / "mcp.json").is_file()
    print("PASS lossless MCP remains ready and migrates by default")

    # Bundle-backed planning and cross-process replay must keep the same gate.
    old, source, source_hashes, _ = fixture("bundle-source")
    bundle = task_root / "rules.acb"
    run(*scoped("snapshot", old, "skills,instructions"), "--output", bundle, "--json")
    assert run("bundle-verify", bundle, "--json")["ok"] is True
    new = task_root / "bundle-target"
    new.mkdir()
    restore_plan = task_root / "restore-plan.json"
    restore_args = scoped("restore", new, "skills,instructions")[1:]
    run("restore", bundle, *restore_args, "--plan-only", "--plan-out", restore_plan, "--json")
    assert [item["status"] for item in json.loads(restore_plan.read_text())["items"]] == ["ready", "ready-lossy"]
    deferred = run("restore", bundle, *restore_args, "--plan-in", restore_plan,
                   "--manifest-out", task_root / "restore-deferred.json", "--yes", "--json")
    assert deferred["summary"].get("applied") == 1, deferred
    assert deferred["summary"].get("lossy-skipped") == 1, deferred
    assert not (new / ".cline" / "rules").exists()
    restore_plan = task_root / "restore-accepted-plan.json"
    run("restore", bundle, *restore_args, "--plan-only", "--plan-out", restore_plan, "--json")
    accepted = run("restore", bundle, *restore_args, "--plan-in", restore_plan,
                   "--manifest-out", task_root / "restore-accepted.json", "--include", "lossy", "--yes", "--json")
    assert accepted["summary"].get("applied-lossy") == 1, accepted
    assert any((new / ".cline" / "rules").rglob("*.md"))
    accepted_manifest = json.loads((task_root / "restore-accepted.json").read_text())
    assert {"description", "hierarchy", "futureField"} <= {item["field"] for item in accepted_manifest["loss_report"]["items"]}
    assert hashes(source) == source_hashes
    print("PASS bundle restore defers conversion loss until explicitly accepted and retains manifest loss evidence")

    # External bundles can retain native MCP metadata that normal snapshot
    # collection removes. Exercise the real bulk merge/replay path with one.
    bulk_registry = task_root / "bulk-registry.json"

    def bulk_profile(product: str, instruction_format: str) -> dict:
        return {"default_profile": "cli", "profiles": {"cli": {
            "migration_policy": "bidirectional-reviewed",
            "detection": [{"type": "file-signature", "paths": [f".{product}-installed"]}],
            "surfaces": {
                "skills": [{"path": f".{product}/skills", "scope": "project", "storage": "directory",
                            "format": "agent-skill", "policy": "validate-then-atomic-copy"}],
                "instructions": [{"path": f".{product}/rules" if product != "destination" else ".destination/rules.md",
                                  "scope": "project", "storage": "directory" if product != "destination" else "file",
                                  "format": instruction_format, "policy": "semantic-ir-with-loss-report"}],
                "mcp": [{"path": f".{product}/mcp.json", "scope": "project", "storage": "file",
                         "format": "json:mcpServers", "policy": "profile-version-adapter"}],
            },
        }}}

    bulk_registry.write_text(json.dumps({"schema_version": 2, "products": {
        "source-a": bulk_profile("source-a", "cursor-mdc"),
        "source-b": bulk_profile("source-b", "cline-rule"),
        "destination": bulk_profile("destination", "agents-md"),
    }}), encoding="utf-8")
    external_objects = []
    external_files = {}

    def external_object(kind: str, product: str, canonical: str, contents: dict[str, bytes]) -> None:
        external_objects.append({
            "object_id": compute_object_id(product=product, profile="cli", scope="project", canonical_path=canonical),
            "object_type": kind, "surface": kind, "product": product, "profile": "cli", "scope": "project",
            "canonical_path": canonical, "status": "ready",
        })
        for relative, data in contents.items():
            external_files[f"{kind}/{product}/cli/project/{canonical}{relative}"] = data

    external_object("skills", "source-a", ".source-a/skills", {
        "/portable/SKILL.md": b"---\nname: portable\ndescription: External bundle fixture.\n---\nKeep packages intact.\n",
    })
    external_object("instructions", "source-a", ".source-a/rules", {
        "/review.mdc": b"---\ndescription: Review migrations\nalwaysApply: true\n---\nKeep changes atomic.\n",
    })
    external_object("mcp", "source-a", ".source-a/mcp.json", {
        "": b'{"mcpServers":{"alpha":{"command":"node","args":["alpha.js"],"autoApprove":["query"]}}}',
    })
    external_object("mcp", "source-b", ".source-b/mcp.json", {
        "": b'{"mcpServers":{"beta":{"command":"python3","args":["-m","beta"],"disabled":true}}}',
    })
    external_bundle = task_root / "external.acb"
    write_bundle(
        bundle_root=external_bundle,
        manifest=ACBManifest(ACB_SCHEMA_VERSION, make_bundle_id(), "2026-08-17T00:00:00Z",
                             {"system": "linux"}, {}, external_objects),
        inventory_rows=[], compatibility={}, requirements={}, secrets_required=[], reauth=[], rebuild=[],
        objects_dir_files=external_files,
    )
    assert run("bundle-verify", external_bundle, "--json")["ok"] is True
    bundle_hashes = hashes(external_bundle)
    bulk_workspace = task_root / "bulk-target"
    destination = bulk_workspace / ".destination"
    destination.mkdir(parents=True)
    (bulk_workspace / ".destination-installed").mkdir()
    old_mcp = b'{"theme":"dark","mcpServers":{"old":{"command":"old"}}}\n'
    old_rules = b"# Existing destination rule\n"
    (destination / "mcp.json").write_bytes(old_mcp)
    (destination / "rules.md").write_bytes(old_rules)
    bulk_args = ["--registry", bulk_registry, "--workspace", bulk_workspace,
                 "--scope", "project", "--objects", "skills,instructions,mcp", "--all-installed"]
    bulk_plan = task_root / "bulk-plan.json"
    run("restore", external_bundle, *bulk_args, "--plan-only", "--plan-out", bulk_plan, "--json")
    bulk_document = json.loads(bulk_plan.read_text())
    assert [item["status"] for item in bulk_document["items"]] == ["ready", "ready-lossy", "ready-lossy"], bulk_document
    bulk_fields = {item["field"] for item in bulk_document["loss_report"]["dropped_fields"]}
    assert {"description", "hierarchy", "alpha.autoApprove", "beta.disabled"} <= bulk_fields, bulk_document
    merged = bulk_document["items"][2]
    assert len(merged["acb_merge_sources"]) == 2 and merged["review_preview"], merged
    assert not Path(merged["source"]["resolved_path"]).exists()
    strict_manifest = task_root / "bulk-strict.json"
    run("apply", bulk_plan, "--registry", bulk_registry, "--bundle", external_bundle,
        "--manifest", strict_manifest, "--strict", "--yes", "--json", success=False)
    assert not strict_manifest.exists() and not (destination / "skills").exists()
    assert (destination / "mcp.json").read_bytes() == old_mcp
    assert (destination / "rules.md").read_bytes() == old_rules
    bulk_default = run("restore", external_bundle, *bulk_args, "--plan-in", bulk_plan,
                       "--manifest-out", task_root / "bulk-default.json", "--yes", "--json")
    assert bulk_default["summary"].get("applied") == 1 and bulk_default["summary"].get("lossy-skipped") == 2, bulk_default
    assert (destination / "mcp.json").read_bytes() == old_mcp
    assert (destination / "rules.md").read_bytes() == old_rules
    bulk_plan = task_root / "bulk-accepted-plan.json"
    run("restore", external_bundle, *bulk_args, "--plan-only", "--plan-out", bulk_plan, "--json")
    accepted_path = task_root / "bulk-accepted.json"
    run("apply", bulk_plan, "--registry", bulk_registry, "--bundle", external_bundle,
        "--manifest", accepted_path, "--accept-loss", "2:mcp", "--yes", "--json")
    accepted_manifest = json.loads(accepted_path.read_text())
    assert accepted_manifest["summary"].get("applied-lossy") == 1 and accepted_manifest["summary"].get("lossy-skipped") == 1, accepted_manifest
    applied_fields = {item["field"] for item in accepted_manifest["loss_report"]["items"]}
    assert {"alpha.autoApprove", "beta.disabled"} <= applied_fields, accepted_manifest
    assert "description" not in applied_fields
    output = json.loads((destination / "mcp.json").read_text())
    assert output["theme"] == "dark" and set(output["mcpServers"]) == {"alpha", "beta"}, output
    assert "autoApprove" not in output["mcpServers"]["alpha"] and "disabled" not in output["mcpServers"]["beta"]
    assert (destination / "rules.md").read_bytes() == old_rules
    assert run("verify", "--manifest", accepted_path, "--json")["ok"] is True
    assert hashes(external_bundle) == bundle_hashes
    print("PASS external bulk replay preserves plan/manifest losses, defers by default, refuses strict writes, and accepts only the selected MCP conversion")

print("Conversion loss CLI regression tests passed")
PY
