#!/usr/bin/env python3
"""Exercise isolated context migrations at increasing sizes and report timings."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

REPOSITORY = Path(__file__).resolve().parent.parent
SKILL = REPOSITORY / "skills" / "agent-skills-setup"
CLI = SKILL / "scripts" / "context-migrator.py"


def file_hashes(directory: Path) -> dict[str, str]:
    result = {}
    for path in sorted(directory.rglob("*")):
        if path.is_file():
            digest = hashlib.sha256()
            with path.open("rb") as reader:
                for chunk in iter(lambda: reader.read(1024 * 1024), b""):
                    digest.update(chunk)
            result[path.relative_to(directory).as_posix()] = digest.hexdigest()
    return result


def create_registry(destination: Path) -> None:
    raw = json.loads((SKILL / "references" / "registry-v2.json").read_text(encoding="utf-8"))
    fixture = copy.deepcopy(raw)
    fixture["products"] = {}
    for name, profile_name in {"cursor": "ide", "cline": "ide"}.items():
        product = copy.deepcopy(raw["products"][name])
        profile = product["profiles"][profile_name]
        profile["detection"] = []
        profile["platforms"] = {}
        profile["surfaces"] = {
            kind: [
                {key: value for key, value in surface.items()
                 if key not in {"compatibility_paths", "override_env", "override_relative_path"}}
                for surface in surfaces if surface.get("scope") == "project"
            ]
            for kind, surfaces in profile["surfaces"].items()
            if kind in {"skills", "instructions", "mcp"}
        }
        product["profiles"] = {profile_name: profile}
        product["default_profile"] = profile_name
        fixture["products"][name] = product
    destination.write_text(json.dumps(fixture, indent=2), encoding="utf-8")


def create_source(project: Path, count: int) -> Path:
    source = project / ".cursor"
    source.mkdir(parents=True)
    for index in range(count):
        name = f"helper-{index:05d}"
        skill = source / "skills" / name
        (skill / "references").mkdir(parents=True)
        (skill / "assets").mkdir()
        (skill / "SKILL.md").write_text(
            f"---\nname: {name}\ndescription: Review project diagnostics {index}.\n"
            "---\nRead [rules](references/rules.md).\n", encoding="utf-8",
        )
        (skill / "references" / "rules.md").write_text(
            f"Review artifact {index} and report file paths.\n", encoding="utf-8",
        )
        (skill / "assets" / "template.txt").write_bytes(
            (f"fixture row {index}\n" * 256).encode("utf-8"),
        )
    rules = source / "rules"
    rules.mkdir()
    for index in range(count):
        (rules / f"rule-{index:05d}.mdc").write_text(
            f"---\ndescription: Rule {index}\nalwaysApply: true\n"
            f"---\nReview artifact {index}.\n", encoding="utf-8",
        )
    servers = {
        f"server-{index:05d}": {
            "command": "python3", "args": ["-m", f"fixture_{index}"],
            "env": {"LOG_LEVEL": "info"},
        }
        for index in range(count)
    }
    (source / "mcp.json").write_text(json.dumps({"mcpServers": servers}), encoding="utf-8")
    return source


def check_targets(source: Path, target: Path, count: int) -> None:
    if file_hashes(target / "skills") != file_hashes(source / "skills"):
        raise AssertionError("migrated Skill package bytes differ from source")
    actual = json.loads((target / "mcp.json").read_text(encoding="utf-8"))
    expected = json.loads((source / "mcp.json").read_text(encoding="utf-8"))
    if actual["mcpServers"] != expected["mcpServers"]:
        raise AssertionError("MCP definitions differ from source")
    rules = list((target / "rules").glob("*.md"))
    if len(rules) != count:
        raise AssertionError(f"expected {count} converted rules, got {len(rules)}")
    for index in range(count):
        text = (target / "rules" / f"rule-{index:05d}.md").read_text(encoding="utf-8")
        if text != f"Review artifact {index}.\n":
            raise AssertionError(f"converted rule {index} differs from reviewed output")


def run_case(count: int, root: Path, registry: Path) -> dict[str, Any]:
    case = root / f"size-{count}"
    case.mkdir()
    project = case / "project"
    destination = case / "new-project"
    destination.mkdir()
    source = create_source(project, count)
    original = file_hashes(source)
    seconds: dict[str, float] = {}
    temporary = case / "tmp"
    temporary.mkdir()
    environment = dict(os.environ, TMPDIR=str(temporary), PYTHONDONTWRITEBYTECODE="1")

    def run(stage: str, *arguments: object) -> dict[str, Any]:
        started = time.perf_counter()
        result = subprocess.run(
            [sys.executable, str(CLI), *map(str, arguments), "--json"],
            capture_output=True, text=True, env=environment, check=False,
        )
        elapsed = time.perf_counter() - started
        seconds[stage] = round(elapsed, 4)
        (case / f"{stage}.stdout.json").write_text(result.stdout, encoding="utf-8")
        (case / f"{stage}.stderr.txt").write_text(result.stderr, encoding="utf-8")
        if result.returncode:
            raise RuntimeError(f"{stage} failed ({result.returncode}): {result.stderr.strip()}")
        print(f"{count}: {stage} {elapsed:.3f}s", file=sys.stderr, flush=True)
        return json.loads(result.stdout)

    common = ["--registry", registry, "--source", "cursor/ide", "--target", "cline/ide",
              "--workspace", project, "--scope", "project", "--objects", "skills,instructions,mcp"]
    plan = case / "plan.json"
    manifest = case / "manifest.json"
    preview = run("plan", "plan", *common, "--output", plan)
    if any(item["status"] not in {"ready", "ready-lossy"} for item in preview["items"]):
        raise AssertionError("scale fixture produced an ineligible plan item")
    if (project / ".cline").exists():
        raise AssertionError("planning wrote a target")
    # The fixture deliberately drops rule descriptions in the target format.
    # Accept that reviewed conversion only; security/default refusal has its
    # own isolated regression suite, without performance thresholds.
    accepted = [f"{index}:{item['object_type']}" for index, item in enumerate(preview["items"])
                if item["status"] == "ready-lossy"]
    run("apply", "apply", plan, "--registry", registry, "--manifest", manifest,
        "--accept-loss", ",".join(accepted), "--yes")
    applied_summary = json.loads(manifest.read_text(encoding="utf-8"))["summary"]
    if applied_summary.get("applied", 0) + applied_summary.get("applied-lossy", 0) != 3:
        raise AssertionError("not every reviewed object was applied")
    check_targets(source, project / ".cline", count)
    if not run("verify", "verify", "--manifest", manifest)["ok"]:
        raise AssertionError("migration verify failed")
    run("rollback", "rollback", "--manifest", manifest, "--yes")
    if file_hashes(project / ".cline"):
        raise AssertionError("rollback retained a migrated target file")

    bundle = case / "project.acb"
    captured = run("snapshot", "snapshot", *common, "--output", bundle)
    if captured["objects_captured"] != 3 or captured["files_captured"] != 4 * count + 1:
        raise AssertionError("snapshot object/file counts do not match the fixture")
    if not run("bundle-verify", "bundle-verify", bundle)["ok"]:
        raise AssertionError("bundle integrity verification failed")
    restore_plan = case / "restore-plan.json"
    restore_manifest = case / "restore-manifest.json"
    restore_args = ["restore", bundle, *common[:common.index("--workspace")],
                    "--workspace", destination, "--scope", "project", "--objects", "skills,instructions,mcp"]
    run("restore-plan", *restore_args, "--plan-only", "--plan-out", restore_plan)
    if (destination / ".cline").exists():
        raise AssertionError("restore planning wrote a target")
    run("restore-apply", *restore_args, "--plan-in", restore_plan,
        "--manifest-out", restore_manifest, "--include", "lossy", "--yes")
    check_targets(source, destination / ".cline", count)
    if not run("restore-verify", "verify", "--manifest", restore_manifest)["ok"]:
        raise AssertionError("restore verify failed")
    run("restore-rollback", "rollback", "--manifest", restore_manifest, "--yes")
    if file_hashes(destination / ".cline"):
        raise AssertionError("restore rollback retained a migrated target file")
    if file_hashes(source) != original:
        raise AssertionError("a source changed during migration or restore")
    return {
        "objects_per_kind": count, "source_files": len(original),
        "source_bytes": sum(path.stat().st_size for path in source.rglob("*") if path.is_file()),
        "seconds": seconds, "total_seconds": round(sum(seconds.values()), 4),
        "source_intact": True, "migrate_roundtrip": True, "restore_roundtrip": True,
    }


def positive_sizes(value: str) -> list[int]:
    try:
        sizes = [int(part.strip()) for part in value.split(",")]
    except ValueError as error:
        raise argparse.ArgumentTypeError("sizes must be comma-separated positive integers") from error
    if any(size <= 0 for size in sizes) or len(set(sizes)) != len(sizes):
        raise argparse.ArgumentTypeError("sizes must be distinct positive integers")
    return sizes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sizes", type=positive_sizes, default=[10, 100, 1000])
    parser.add_argument("--report", type=Path, help="fresh JSON output file; defaults to stdout only")
    parser.add_argument("--keep-workspace", action="store_true", help="retain isolated fixtures and command outputs")
    args = parser.parse_args()
    report = None
    if args.report:
        sys.path.insert(0, str(SKILL / "scripts"))
        from migration_core import resolve_output_path
        try:
            report = resolve_output_path(args.report)
            if report.exists():
                raise ValueError(f"report already exists: {report}")
        except (OSError, ValueError) as error:
            parser.error(str(error))
    root = Path(tempfile.mkdtemp(prefix="context-scale-")).resolve()
    try:
        registry = root / "registry.json"
        create_registry(registry)
        result = {"cases": [run_case(size, root, registry) for size in args.sizes]}
        if args.keep_workspace:
            result["workspace"] = str(root)
        rendered = json.dumps(result, indent=2) + "\n"
        if report is not None:
            report.parent.mkdir(parents=True, exist_ok=True)
            with report.open("x", encoding="utf-8") as writer:
                writer.write(rendered)
        print(rendered, end="")
        return 0
    except (OSError, ValueError, AssertionError, RuntimeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        if args.keep_workspace:
            print(f"Fixtures retained: {root}", file=sys.stderr)
        return 1
    finally:
        if not args.keep_workspace:
            shutil.rmtree(root)


if __name__ == "__main__":
    raise SystemExit(main())
