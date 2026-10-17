#!/usr/bin/env python3
"""Verify a device packet and run one reviewed same-product restore recipe."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Any

sys.dont_write_bytecode = True
CHECKSUMS = "PACKET-SHA256.json"
AUTOMATIC = {"skills", "instructions", "mcp", "plugins", "handoff"}


def fail(message: str) -> None:
    raise ValueError(message)


def read_json(path: Path) -> Any:
    def unique(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in pairs:
            if key in result:
                fail("duplicate JSON key")
            result[key] = value
        return result

    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique)


def digest(path: Path) -> str:
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def relative_file(value: Any) -> str:
    if not isinstance(value, str) or not value or "\\" in value or "\0" in value:
        fail("invalid packet relative path")
    path = PurePosixPath(value)
    if path.is_absolute() or any(part in {"", ".", ".."} for part in value.split("/")):
        fail("packet path traversal or noncanonical path")
    if ":" in value or str(path) != value:
        fail("invalid portable packet path")
    return value


def overlap(left: Path, right: Path) -> bool:
    return left == right or left in right.parents or right in left.parents


def verify_packet(packet: Path) -> tuple[dict[str, Any], str]:
    if packet.is_symlink() or not packet.is_dir():
        fail("packet must be a real directory")
    checksum_path = packet / CHECKSUMS
    if checksum_path.is_symlink() or not checksum_path.is_file():
        fail("packet checksum index is missing or unsafe")
    checksums = read_json(checksum_path)
    if not isinstance(checksums, dict):
        fail("packet checksums must be a relative-file to SHA256 object")
    for name, expected in checksums.items():
        relative_file(name)
        if name == CHECKSUMS or not isinstance(expected, str) or not re.fullmatch(r"[a-f0-9]{64}", expected):
            fail("invalid packet checksum entry")
    observed: set[str] = set()
    for directory, directories, files in os.walk(packet, followlinks=False):
        for name in [*directories, *files]:
            path = Path(directory) / name
            mode = path.lstat().st_mode
            if stat.S_ISLNK(mode) or not (stat.S_ISDIR(mode) or stat.S_ISREG(mode)):
                fail("packet contains a symlink or nonregular entry")
            if stat.S_ISREG(mode):
                relative = path.relative_to(packet).as_posix()
                if relative != CHECKSUMS:
                    observed.add(relative)
    if observed != set(checksums):
        fail("packet file inventory does not match checksum index")
    for name, expected in checksums.items():
        if digest(packet / name) != expected:
            fail("packet file checksum mismatch: " + name)
    for runtime_file in ("skill/scripts/context-migrator.py", "skill/scripts/acb/bundle.py"):
        if runtime_file not in checksums:
            fail("packet is missing its bundled migration/verification runtime")
    index = read_json(packet / "device-index.json")
    if not isinstance(index, dict) or type(index.get("schema_version")) is not int or index["schema_version"] != 1:
        fail("unsupported device index schema")
    if not isinstance(index.get("recipes"), list):
        fail("device index recipes must be an array")
    if "captures" in index:
        if not isinstance(index["captures"], list):
            fail("device index captures must be an array")
        for capture in index["captures"]:
            if not isinstance(capture, dict):
                fail("device index capture must be an object")
            relative = relative_file(capture.get("bundle"))
            if not (packet / relative).is_dir():
                fail("capture bundle directory is missing")
    seen: set[str] = set()
    for recipe in index["recipes"]:
        validate_recipe(recipe, packet)
        if recipe["id"] in seen:
            fail("duplicate recipe ID")
        seen.add(recipe["id"])
    return index, digest(checksum_path)


def parse_template(argv: Any, action: str) -> dict[str, Any]:
    command = "verify" if action == "verify" else "restore"
    prefix = ["<PYTHON>", "-B", "<MIGRATOR>", command]
    if command == "restore":
        prefix.append("<BUNDLE>")
    if not isinstance(argv, list) or argv[:len(prefix)] != prefix or not all(isinstance(arg, str) for arg in argv):
        fail("recipe must invoke only the bundled Python migrator with -B")
    valued = {"--manifest"} if command == "verify" else {
        "--source", "--target", "--workspace", "--scope", "--objects",
        "--plan-out", "--plan-in", "--manifest-out",
    }
    flags = {"--json"} if command == "verify" else {
        "--plan-only", "--yes", "--json", "--include-plugins", "--include-session",
    }
    parsed: dict[str, Any] = {}
    offset = len(prefix)
    while offset < len(argv):
        option = argv[offset]
        if option in parsed or option not in valued | flags:
            fail("unknown or duplicate recipe option")
        if option in flags:
            parsed[option] = True
            offset += 1
        else:
            if offset + 1 >= len(argv):
                fail("recipe option lacks a value")
            parsed[option] = argv[offset + 1]
            offset += 2
    return parsed


def state_template(value: Any) -> str:
    if not isinstance(value, str) or not value.startswith("<STATE_DIR>/"):
        fail("recipe output must use STATE_DIR")
    suffix = relative_file(value[len("<STATE_DIR>/"):])
    if "/" in suffix:
        fail("recipe state output must be a direct file")
    return value


def validate_recipe(recipe: Any, packet: Path) -> None:
    if not isinstance(recipe, dict) or not isinstance(recipe.get("id"), str) or not recipe["id"]:
        fail("recipe requires an ID")
    if recipe.get("kind") not in {"user-global", "project"}:
        fail("recipe kind must be user-global or project")
    selector = recipe.get("source")
    if (not isinstance(selector, str) or not re.fullmatch(r"[a-z0-9][a-z0-9_.-]*/[a-z0-9][a-z0-9_.-]*", selector)
            or selector != recipe.get("target")):
        fail("only explicit same-product source=target recipes are supported")
    for key in ("bundle", "registry"):
        relative = relative_file(recipe.get(key))
        expected = packet / relative
        if key == "bundle" and not expected.is_dir():
            fail("recipe bundle directory is missing")
        if key == "registry" and not expected.is_file():
            fail("recipe registry file is missing")
    for key, allowed in (("scopes", {"user", "project", "local"}), ("objects", AUTOMATIC)):
        values = recipe.get(key)
        if (not isinstance(values, list) or not values or not all(isinstance(value, str) for value in values)
                or len(set(values)) != len(values) or not set(values) <= allowed):
            fail("invalid recipe " + key)
    if recipe["kind"] == "user-global" and "project" in recipe["scopes"]:
        fail("user-global recipe cannot contain project scope")
    plan = parse_template(recipe.get("plan_only"), "plan")
    apply = parse_template(recipe.get("apply_saved"), "apply")
    verify = parse_template(recipe.get("verify"), "verify")
    for options in (plan, apply):
        if options.get("--source") != selector or options.get("--target") != selector:
            fail("recipe argv source/target mismatch")
        if options.get("--workspace") != "<WORKSPACE>":
            fail("recipe workspace must be explicitly mapped")
        for option, key in (("--scope", "scopes"), ("--objects", "objects")):
            if options.get(option) != ",".join(recipe[key]):
                fail("recipe argv scope/object selection mismatch")
        for kind, flag in (("plugins", "--include-plugins"), ("handoff", "--include-session")):
            if bool(options.get(flag)) != (kind in recipe["objects"]):
                fail("recipe object opt-in mismatch")
        if options.get("--json") is not True:
            fail("recipe must request JSON output")
    if not plan.get("--plan-only") or any(key in plan for key in ("--plan-in", "--manifest-out", "--yes")):
        fail("plan recipe must only save a preview")
    if not apply.get("--yes") or any(key in apply for key in ("--plan-only", "--plan-out")):
        fail("apply recipe must replay a saved plan")
    if state_template(plan.get("--plan-out")) != state_template(apply.get("--plan-in")):
        fail("apply must replay the exact saved plan path")
    if state_template(apply.get("--manifest-out")) != state_template(verify.get("--manifest")):
        fail("verify must inspect the applied manifest")
    if not verify.get("--json"):
        fail("verify recipe must request JSON output")
    if plan["--plan-out"] == apply["--manifest-out"]:
        fail("plan and manifest paths must differ")


def write_new(path: Path, data: Any) -> None:
    with path.open("x", encoding="utf-8") as stream:
        json.dump(data, stream, ensure_ascii=False, indent=2, sort_keys=True)
        stream.write("\n")


def run(argv: list[str], workspace: Path) -> dict[str, Any]:
    result = subprocess.run(argv, shell=False, cwd=workspace, capture_output=True,
                            text=True, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
    try:
        output = json.loads(result.stdout)
    except json.JSONDecodeError:
        output = {"stdout": result.stdout}
    return {"ok": result.returncode == 0 and isinstance(output, dict) and output.get("ok") is True,
            "returncode": result.returncode, "output": output, "stderr": result.stderr}


def operate(args: argparse.Namespace) -> dict[str, Any]:
    raw_packet = Path(args.packet).expanduser()
    if raw_packet.is_symlink():
        fail("packet root cannot be a symlink")
    packet = raw_packet.resolve()
    index, packet_hash = verify_packet(packet)
    if args.action in {"verify", "list"}:
        output: dict[str, Any] = {"ok": True, "stage": args.action,
                                  "packet_integrity": "verified", "recipes": index["recipes"]}
        if args.action == "verify":
            sys.path.insert(0, str(packet / "skill/scripts"))
            from acb.bundle import verify_bundle

            bundles = {item["bundle"] for item in index["recipes"]}
            bundles.update(item["bundle"] for item in index.get("captures", []))
            errors = {name: verify_bundle(packet / name) for name in sorted(bundles)}
            output["bundle_errors"] = errors
            output["ok"] = not any(errors.values())
        return output
    if not args.recipe or not args.state_dir:
        fail("plan/apply require --recipe and an explicit absolute --state-dir")
    matches = [recipe for recipe in index["recipes"] if recipe["id"] == args.recipe]
    if not matches:
        fail("recipe ID is not in the packet")
    recipe = matches[0]
    state = Path(args.state_dir).expanduser()
    if not state.is_absolute() or state.is_symlink():
        fail("state directory must be an explicit absolute directory without a root symlink")
    state = state.resolve()
    if overlap(state, packet):
        fail("state directory must be outside and must not overlap the packet")
    if recipe["kind"] == "project" and not args.workspace:
        fail("project restore requires an explicit existing --workspace")
    workspace = Path(args.workspace).expanduser().resolve() if args.workspace else state / "operation-workspace"
    if overlap(workspace, packet):
        fail("workspace must not overlap the packet")
    if args.workspace and not workspace.is_dir():
        fail("workspace must be an existing directory")
    if args.action == "apply" and not args.yes:
        fail("apply requires --yes recording existing user authorization")
    identity = hashlib.sha256((recipe["id"] + "\0" + recipe["bundle"] + "\0" + recipe["source"]).encode()).hexdigest()[:24]
    operation = state / ("recipe-" + identity)
    if operation.is_symlink():
        fail("recipe state directory cannot be a symlink")
    for path in (state, operation):
        path.mkdir(parents=True, exist_ok=True)
    if not args.workspace:
        workspace.mkdir(exist_ok=True)
    replacements = {"<PYTHON>": sys.executable, "<MIGRATOR>": str(packet / "skill/scripts/context-migrator.py"),
                    "<BUNDLE>": str(packet / recipe["bundle"]), "<WORKSPACE>": str(workspace), "<STATE_DIR>": str(operation)}

    def replace(value: str) -> str:
        for token, replacement in replacements.items():
            if value == token:
                return replacement
            if value.startswith(token + "/") and token == "<STATE_DIR>":
                return replacement + value[len(token):]
        if "<" in value or ">" in value:
            fail("unresolved recipe placeholder")
        return value

    def command(key: str) -> list[str]:
        argv = [replace(value) for value in recipe[key]]
        if key != "verify":
            argv.extend(["--registry", str(packet / recipe["registry"])])
        return argv

    plan_options = parse_template(recipe["plan_only"], "plan")
    plan_path = Path(replace(plan_options["--plan-out"]))
    record_path = operation / "planned.json"
    attempt_path = operation / "apply-attempt.json"
    binding = {"packet_sha256": packet_hash, "recipe": recipe, "workspace": str(workspace)}
    if args.action == "plan":
        if plan_path.exists() or record_path.exists() or attempt_path.exists():
            fail("plan/state already exists; use an explicit new state directory to create another plan")
        result = run(command("plan_only"), workspace)
        write_new(operation / "plan-result.json", result)
        if not result["ok"] or not plan_path.is_file() or plan_path.is_symlink():
            return {"ok": False, "stage": "plan", "state": str(operation), "result": result}
        write_new(record_path, {**binding, "plan_sha256": digest(plan_path)})
        return {"ok": True, "stage": "plan", "state": str(operation), "plan": str(plan_path), "review_required": True, "result": result}
    if not record_path.is_file() or record_path.is_symlink() or not plan_path.is_file() or plan_path.is_symlink():
        fail("apply requires a saved plan and its original state record")
    saved = read_json(record_path)
    if (not isinstance(saved, dict) or any(saved.get(key) != value for key, value in binding.items())
            or saved.get("plan_sha256") != digest(plan_path)):
        fail("saved plan, packet, recipe, or workspace changed; create and review a new plan")
    if attempt_path.exists():
        fail("apply was already attempted; review existing evidence before using a new state")
    write_new(attempt_path, {**binding, "status": "started", "plan_sha256": saved["plan_sha256"]})
    applied = run(command("apply_saved"), workspace)
    write_new(operation / "apply-result.json", applied)
    verified = run(command("verify"), workspace) if applied["ok"] else {"ok": False, "status": "not-run"}
    write_new(operation / "verify-result.json", verified)
    return {"ok": applied["ok"] and verified["ok"], "stage": "apply", "state": str(operation),
            "configuration_apply": applied, "manifest_verify": verified,
            "native_discovery": "not-run", "runtime_and_connectivity": "not-run"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("verify", "list", "plan", "apply"))
    parser.add_argument("--packet", required=True)
    parser.add_argument("--recipe")
    parser.add_argument("--state-dir")
    parser.add_argument("--workspace")
    parser.add_argument("--yes", action="store_true", help="Record authorization already given; does not grant it.")
    args = parser.parse_args()
    try:
        output = operate(args)
    except (ValueError, OSError, ImportError) as error:
        output = {"ok": False, "stage": args.action, "error": str(error)}
    print(json.dumps(output, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if output["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
