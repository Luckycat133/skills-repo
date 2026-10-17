#!/usr/bin/env python3
"""Plan, merge, verify and roll back explicitly mapped captured context files.

This writes configuration only. It never executes captured code, installs an
application, starts MCP, changes native trust or claims native acceptance.
"""
from __future__ import annotations

import argparse
import copy
import datetime
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path, PurePosixPath
import re
import stat
import sys
import tempfile
from typing import Any

sys.dont_write_bytecode = True
SCRIPTS = Path(__file__).resolve().parent
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))
from acb.bundle import ACBError, MAX_FILE_SIZE, scan_object_bytes
from acb.preferences import _decode_preferences, valid_review_fields
from migration_core import _strip_jsonc, preflight_skill_source


class RestoreError(ValueError):
    """A stable explanation written by this helper, never a parser fragment."""


def fail(message: str) -> None:
    raise RestoreError(message)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_json(path: Path) -> Any:
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                fail("duplicate JSON key")
            result[key] = value
        return result
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique)


def encoded(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False) + "\n").encode()


def private_write(path: Path, data: bytes, *, fresh: bool = False, mode: int = 0o600) -> None:
    no_links(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    if fresh and path.exists():
        fail("output already exists")
    descriptor, temporary = tempfile.mkstemp(prefix=".context-write-", dir=path.parent)
    try:
        os.fchmod(descriptor, mode)
        with os.fdopen(descriptor, "wb") as writer:
            writer.write(data)
            writer.flush()
            os.fsync(writer.fileno())
        no_links(path)
        if fresh and path.exists():
            fail("output appeared during staging")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def no_links(path: Path) -> None:
    for part in (path, *path.parents):
        if part.is_symlink() and not (sys.platform == "darwin" and str(part) in {"/tmp", "/var", "/etc"}):
            fail("path contains a symlink")


def absolute(value: Any) -> Path:
    if not isinstance(value, str) or not value or "\0" in value:
        fail("path must be explicit text")
    path = Path(value).expanduser()
    if not path.is_absolute():
        fail("path must be absolute or home-relative")
    no_links(path)
    return path.resolve()


def beneath(path: Path, root: Path) -> bool:
    return path != root and root in path.parents


def relative(value: Any) -> str:
    if not isinstance(value, str) or not value or "\\" in value or "\0" in value:
        fail("invalid relative path")
    p = PurePosixPath(value)
    if p.is_absolute() or any(part in {"", ".", ".."} for part in value.split("/")) or ":" in value:
        fail("unsafe relative path")
    return value


def file_state(path: Path) -> dict:
    no_links(path)
    if not path.exists():
        return {"exists": False, "sha256": None, "mode": None}
    if not path.is_file() or path.stat().st_size > MAX_FILE_SIZE:
        fail("target is not a bounded ordinary file")
    return {"exists": True, "sha256": sha(path.read_bytes()), "mode": stat.S_IMODE(path.stat().st_mode)}


def packet_identity(packet: Path) -> str:
    spec = importlib.util.spec_from_file_location("context_device_restore", SCRIPTS / "device-restore.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    _, identity = module.verify_packet(packet)
    return identity


def path_remap(value: Any, mappings: dict[str, str]) -> Any:
    if isinstance(value, dict):
        return {key: path_remap(item, mappings) for key, item in value.items()}
    if isinstance(value, list):
        return [path_remap(item, mappings) for item in value]
    if isinstance(value, str):
        for old, new in sorted(mappings.items(), key=lambda row: -len(row[0])):
            if value == old or value.startswith(old.rstrip("/") + "/"):
                return new.rstrip("/") + value[len(old.rstrip("/")):]
    return value


def get(data: dict, parts: list[str]) -> tuple[bool, Any]:
    value = data
    for part in parts:
        if not isinstance(value, dict) or part not in value:
            return False, None
        value = value[part]
    return True, value


def put(data: dict, parts: list[str], value: Any, replace: bool) -> None:
    parent = data
    for part in parts[:-1]:
        if part not in parent:
            parent[part] = {}
        if not isinstance(parent[part], dict):
            fail("field parent conflicts with existing scalar")
        parent = parent[part]
    key = parts[-1]
    if key in parent and parent[key] != value and not replace:
        fail("selected field conflicts; review and explicitly choose conflict=replace")
    parent[key] = copy.deepcopy(value)


def merge_server(document: dict, container: str, name: str, incoming: dict, replace: bool) -> None:
    exists, previous = get(document, [container, name])
    if exists and not isinstance(previous, dict):
        fail("existing MCP server is not an object")
    previous = previous if exists else {}
    bound_auth = any(previous.get(key) for key in ("env", "headers", "http_headers", "env_headers", "env_http_headers", "env_vars"))
    bound_auth = bound_auth or any(key.endswith("_env_var") and value for key, value in previous.items())
    if bound_auth and any(key in incoming and incoming[key] != previous.get(key)
                          for key in ("command", "args", "url", "httpUrl")):
        fail("MCP endpoint or executable changes require separate native authentication review")
    if ((incoming.get("command") and any(previous.get(key) for key in ("url", "httpUrl")))
            or (any(incoming.get(key) for key in ("url", "httpUrl")) and previous.get("command"))):
        fail("MCP transport conflicts; review the target server before conversion")
    def merge(row, value, parts):
        for key, item in value.items():
            if isinstance(item, dict):
                if key not in row:
                    row[key] = {}
                if not isinstance(row[key], dict):
                    fail("MCP field type conflicts with existing target")
                merge(row[key], item, parts + [key])
            else:
                put(row, [key], item, replace)
    result = copy.deepcopy(previous)
    merge(result, incoming, [])
    put(document, [container, name], result, True)


def toml_encode(data: dict) -> str:
    def atom(value):
        if isinstance(value, str):
            return json.dumps(value, ensure_ascii=False)
        if isinstance(value, bool):
            return "true" if value else "false"
        if type(value) in {int, float}:
            if isinstance(value, float) and not math.isfinite(value):
                fail("nonfinite TOML value")
            return str(value)
        if isinstance(value, (datetime.datetime, datetime.date, datetime.time)):
            return value.isoformat()
        if isinstance(value, list) and not any(isinstance(x, dict) for x in value):
            return "[" + ", ".join(atom(x) for x in value) + "]"
        fail("unsupported TOML value")
    lines = []
    def table(row, prefix, header=""):
        if header:
            lines.append(header)
        for key, value in row.items():
            if not isinstance(value, dict) and not (isinstance(value, list) and value and all(isinstance(x, dict) for x in value)):
                lines.append(json.dumps(key, ensure_ascii=False) + " = " + atom(value))
        for key, value in row.items():
            path = prefix + [key]
            name = ".".join(json.dumps(x, ensure_ascii=False) for x in path)
            if isinstance(value, dict):
                table(value, path, "[" + name + "]")
            elif isinstance(value, list) and value and all(isinstance(x, dict) for x in value):
                for item in value:
                    table(item, path, "[[" + name + "]]")
    table(data, [])
    return "\n".join(lines) + "\n"


def yaml_encode(data: dict) -> str:
    def scalar(value):
        if value is None:
            return "null"
        if isinstance(value, (str, bool, int, float)):
            return json.dumps(value, ensure_ascii=False, allow_nan=False)
        if value == {}:
            return "{}"
        if value == []:
            return "[]"
        fail("unsupported YAML value")
    def lines(value, indent):
        result = []
        if isinstance(value, dict) and value:
            for key, item in value.items():
                lead = " " * indent + json.dumps(key, ensure_ascii=False) + ":"
                if isinstance(item, (dict, list)) and item:
                    result.append(lead)
                    result.extend(lines(item, indent + 2))
                else:
                    result.append(lead + " " + scalar(item))
        elif isinstance(value, list) and value:
            for item in value:
                if isinstance(item, (dict, list)) and item:
                    result.append(" " * indent + "-")
                    result.extend(lines(item, indent + 2))
                else:
                    result.append(" " * indent + "- " + scalar(item))
        else:
            result.append(" " * indent + scalar(value))
        return result
    return "\n".join(lines(data, 0)) + "\n"


def render(data: dict, format_name: str) -> bytes:
    if format_name in {"json", "jsonc"}:
        output = encoded(data)
    elif format_name == "toml":
        output = toml_encode(data).encode()
    elif format_name in {"yaml", "yml"}:
        output = yaml_encode(data).encode()
    else:
        fail("unsupported target format")
    if _decode_preferences(output, format_name) != data:
        fail("target format cannot round-trip all existing sibling values")
    return output


def merge_preferences(document: dict, payload: dict, entry: dict, pending: list) -> None:
    replace = entry.get("conflict", "error") == "replace"
    for field in payload.get("fields", []):
        if not valid_review_fields([field["path"]]):
            fail("unsafe preference field")
        put(document, field["path"], field["value"], replace)
    for record in payload.get("records", []):
        parts = record["path"]
        if not valid_review_fields([parts]):
            fail("unsafe record field")
        exists, items = get(document, parts)
        if exists and not isinstance(items, list):
            fail("target model catalog is not an array")
        if not exists:
            items = []
            put(document, parts, items, replace)
            _, items = get(document, parts)
        source_identities = set()
        for item in record["items"]:
            fields = item["fields"]
            if any(not valid_review_fields([field["path"]]) for field in fields):
                fail("unsafe record field")
            candidate = {}
            for field in fields:
                put(candidate, field["path"], field["value"], True)
            identity = next(([key] for key in ("id", "name", "path") if isinstance(candidate.get(key), (str, int))
                             and not isinstance(candidate.get(key), bool) and candidate.get(key) != ""), None)
            if identity is None and isinstance(candidate.get("model"), str) and candidate["model"]:
                identity = [key for key in ("model", "provider") if key in candidate]
            if not identity:
                pending.append({"reason": "model-item-without-stable-identity", "source_index": item["index"]})
                continue
            source_identity = tuple((key, candidate[key]) for key in identity)
            if source_identity in source_identities:
                fail("ambiguous source model identity")
            source_identities.add(source_identity)
            matches = [existing for existing in items if isinstance(existing, dict)
                       and all(existing.get(key) == candidate[key] for key in identity)]
            if len(matches) > 1:
                fail("ambiguous target model identity")
            target = matches[0] if matches else {}
            for field in fields:
                put(target, field["path"], field["value"], replace)
            if not matches:
                items.append(target)
        if len(record["items"]) != record.get("source_length", len(record["items"])):
            pending.append({"reason": "excluded-source-model-items", "path": parts})


def build_plan(packet: Path, mapping_path: Path) -> tuple[dict, dict[str, bytes]]:
    identity = packet_identity(packet)
    mapping = read_json(mapping_path)
    if mapping.get("schema_version") != 1 or not isinstance(mapping.get("entries"), list):
        fail("mapping requires schema_version 1 and entries")
    roots = [absolute(row) for row in mapping.get("roots", [])]
    if not roots or any(not root.is_dir() for root in roots):
        fail("explicit existing destination roots are required")
    if any(packet == root or packet in root.parents or root in packet.parents for root in roots):
        fail("destination roots must not overlap the packet")
    review = read_json(packet / "review/index.json")
    sources = {(c["id"], s["id"]): s for c in review["clients"] for s in c["sources"]}
    operations, pending, output_bytes, reference_checks = [], [], {}, []
    selected = set()
    for entry in mapping["entries"]:
        key = (entry["client"], entry["source"])
        if key in selected or key not in sources:
            fail("duplicate or unknown client/source mapping")
        selected.add(key)
        source = sources[key]
        target_root = absolute(entry["target"])
        if not any(beneath(target_root, root) for root in roots):
            fail("target escaped explicitly authorized roots")
        if entry.get("conflict", "error") not in {"error", "replace"}:
            fail("unknown conflict strategy")
        remap = entry.get("path_map", {})
        if not isinstance(remap, dict) or any(not isinstance(k, str) or not k or not isinstance(v, str) for k, v in remap.items()):
            fail("path_map must map literal source prefixes to destination text")
        captured = []
        for item in source["files"]:
            name = relative(item["path"])
            path = packet / "review" / name
            no_links(path)
            data = path.read_bytes()
            if sha(data) != item["sha256"]:
                fail("captured source hash mismatch")
            scan_object_bytes(data, path.name)
            captured.append((name, path, data))
        for exclusion in source.get("exclusions", []):
            # A materialized, sanitized package is a successful capture with
            # its own detailed report, not an excluded source. Evaluate its
            # actual omissions/references below instead of duplicating a task.
            if exclusion.get("reason") == "sanitized-review-source-materialized":
                continue
            pending.append({"client": key[0], "source": key[1], "reason": exclusion.get("reason", "capture-exclusion")})
        if not captured:
            pending.append({"client": key[0], "source": key[1], "reason": "no-captured-payload"})
            continue
        kind = source["kind"]
        if kind in {"preferences", "mcp", "mcp-sqlite", "hooks"}:
            if kind == "hooks" and entry.get("activation_reviewed") is not True:
                pending.append({"client": key[0], "source": key[1], "reason": "hook-definition-captured-needs-native-review"})
                continue
            if kind == "hooks" and any(row.get("reason") in {"hook-field-secret-rejected", "hook-field-invalid", "hook-dynamic-reference-needs-review", "hook-relative-reference-needs-review", "hook-command-static-parse-failed"} for row in source.get("exclusions", [])):
                pending.append({"client": key[0], "source": key[1], "reason": "hook-source-exclusions-require-reconstruction"})
                continue
            format_name = entry.get("format")
            if format_name not in {"json", "jsonc", "toml", "yaml", "yml"}:
                fail("structured restore needs an explicit target format")
            before = file_state(target_root)
            original = target_root.read_bytes() if before["exists"] else b""
            previous = next((row for row in operations if row["target"] == str(target_root)), None)
            if previous and (previous["kind"] not in {"preferences", "mcp", "mcp-sqlite", "hooks"} or previous["format"] != format_name):
                fail("incompatible sources target the same configuration file")
            current_bytes = output_bytes[str(target_root)] if previous else original
            document = _decode_preferences(current_bytes, format_name) if current_bytes else {}
            document = copy.deepcopy(document)
            original_document = _decode_preferences(original, format_name) if original else {}
            if kind == "hooks":
                from acb.hook_review import _management_key
                definitions = [(path, data) for _, path, data in captured if path.name == "hooks-review.json"]
                if len(definitions) != 1:
                    fail("hook source needs one bound definition payload")
                definition_path, raw_definition = definitions[0]
                payload = json.loads(raw_definition)
                dependency_targets = entry.get("dependency_targets", {})
                if not isinstance(dependency_targets, dict):
                    fail("hook dependency targets must be an explicit path mapping")
                staged_dependencies = []
                dependency_replacements = {}
                missing_dependency = False
                for dependency in payload.get("dependencies", []):
                    source_path = dependency["source_path"]
                    target_value = dependency_targets.get(source_path)
                    if not target_value:
                        pending.append({"client": key[0], "source": key[1], "reason": "hook-dependency-target-review-required", "dependency": source_path})
                        missing_dependency = True
                        continue
                    destination = absolute(target_value)
                    no_links(destination)
                    dependency_replacements[source_path] = str(destination)
                    if dependency.get("reference"):
                        dependency_replacements[dependency["reference"]] = str(destination)
                    if dependency.get("status") != "captured-review-only":
                        if not destination.is_file():
                            pending.append({"client": key[0], "source": key[1], "reason": "hook-external-dependency-not-installed", "dependency": source_path})
                            missing_dependency = True
                        continue
                    if not any(beneath(destination, root) for root in roots):
                        fail("hook dependency target escaped explicitly authorized roots")
                    dependency_path = definition_path.parent / relative(dependency["payload_path"])
                    available = next((data for _, path, data in captured if path == dependency_path), None)
                    if available is None or sha(available) != dependency["sha256"]:
                        fail("hook dependency payload is missing or differs from its definition")
                    for old, new in sorted(remap.items(), key=lambda row: -len(row[0])):
                        available = available.replace(old.encode(), new.encode())
                    before_dependency = file_state(destination)
                    if before_dependency["exists"] and before_dependency["sha256"] != sha(available) and entry.get("conflict") != "replace":
                        fail("existing hook dependency conflicts; review conflict=replace")
                    staged_dependencies.append((destination, available, before_dependency, dependency.get("mode", 0o600)))
                if missing_dependency:
                    continue
                def check_hook_value(value):
                    if isinstance(value, dict):
                        if any(_management_key(str(name)) for name in value):
                            fail("captured hooks cannot transport management or trust state")
                        for nested in value.values():
                            check_hook_value(nested)
                    elif isinstance(value, list):
                        for nested in value:
                            check_hook_value(nested)
                def remap_hook_value(value):
                    if isinstance(value, dict):
                        return {name: remap_hook_value(nested) for name, nested in value.items()}
                    if isinstance(value, list):
                        return [remap_hook_value(nested) for nested in value]
                    if isinstance(value, str):
                        # File installation and command references share the
                        # exact same reviewed binding, including custom targets.
                        replacements = {**remap, **dependency_replacements}
                        for old, new in sorted(replacements.items(), key=lambda row: -len(row[0])):
                            if old not in value:
                                continue
                            if any(char.isspace() for char in new) and value != old and ('"' + old + '"') not in value and ("'" + old + "'") not in value:
                                fail("hook command path mapping needs explicit quoting review")
                            value = value.replace(old, new)
                    return value
                for field in payload.get("fields", []):
                    parts = field["path"]
                    if parts not in (["hooks"], ["notify"]):
                        fail("unsupported captured hook field")
                    check_hook_value(field["value"])
                    value = remap_hook_value(field["value"])
                    # Keep destination-only hook events and trust state.
                    if parts == ["hooks"] and isinstance(value, dict):
                        for event, hooks in value.items():
                            exists, existing = get(document, ["hooks", event])
                            if exists and isinstance(existing, list) and isinstance(hooks, list):
                                merged_hooks = copy.deepcopy(existing)
                                for hook in hooks:
                                    if hook not in merged_hooks:
                                        merged_hooks.append(hook)
                                put(document, ["hooks", event], merged_hooks, True)
                            else:
                                put(document, ["hooks", event], hooks, entry.get("conflict") == "replace")
                    else:
                        put(document, parts, value, entry.get("conflict") == "replace")
                for destination, data, observed, mode in staged_dependencies:
                    operations.append({"client": key[0], "source": key[1], "target": str(destination), "kind": "hook-dependency",
                                       "before": observed, "after_sha256": sha(data), "mode": observed["mode"] or (mode & 0o777),
                                       "status": "unchanged" if observed["sha256"] == sha(data) else "ready"})
                    output_bytes[str(destination)] = data
            for _, _, data in captured:
                if kind == "hooks":
                    # Dependencies are separate payloads, never JSON config.
                    continue
                payload = path_remap(json.loads(data), remap)
                if kind == "preferences":
                    merge_preferences(document, payload, entry, pending)
                else:
                    container = entry.get("container")
                    if container not in {"mcpServers", "servers", "mcp", "mcp_servers"}:
                        fail("MCP restore requires an explicit native container")
                    if payload.get("required_credentials") or payload.get("omitted_fields"):
                        pending.append({"client": key[0], "source": key[1], "server": payload["server_name"],
                                        "reason": "mcp-needs-authentication-or-omitted-fields", "required_credentials": payload.get("required_credentials", [])})
                        if not entry.get("include_incomplete_mcp", False):
                            continue
                    if entry.get("include_incomplete_mcp", False):
                        fail("incomplete MCP must be reconstructed with native authentication; placeholders are not activated")
                    merge_server(document, container, payload["server_name"], payload["definition"], entry.get("conflict") == "replace")
            if not original and document == {}:
                continue
            if document == original_document:
                data = original
            else:
                if original and format_name in {"jsonc", "toml", "yaml", "yml"} and not entry.get("allow_reformat", False):
                    fail("non-JSON serialization requires explicit allow_reformat after reviewing format/comment loss")
                data = render(document, format_name)
            if previous:
                previous["after_sha256"] = sha(data)
                previous["status"] = "unchanged" if before["sha256"] == sha(data) else "ready"
                previous["sources"].append({"client": key[0], "source": key[1]})
            else:
                operations.append({"client": key[0], "source": key[1], "sources": [{"client": key[0], "source": key[1]}],
                                   "target": str(target_root), "kind": kind, "format": format_name,
                                   "before": before, "after_sha256": sha(data), "mode": before["mode"] or 0o600,
                                   "status": "unchanged" if before["sha256"] == sha(data) else "ready"})
            output_bytes[str(target_root)] = data
        elif kind in {"skills", "text"}:
            source_path = Path(source.get("canonical") or source.get("source_root") or "")
            activation_path = (source.get("classification") == "activation-bearing"
                               or bool(set(source_path.parts) & {"hooks", "automations", ".hooks"})
                               or source_path.name in {"hooks.json", "automation.toml"})
            if kind == "text" and (activation_path or "hooks" in source["id"] or "automation" in source["id"]):
                pending.append({"client": key[0], "source": key[1], "reason": "activation-bearing-source-needs-separate-native-review"})
                continue
            package_modes, blocked_files = {}, set()
            if kind == "skills":
                report_path = packet / "review" / relative(source["report"])
                packages = read_json(report_path.parent / "skill-packages.json")
                for package in packages["entries"]:
                    if package.get("redactions"):
                        pending.append({"client": key[0], "source": key[1], "package": package["name"],
                                        "reason": "sanitized-package-redactions-need-review"})
                    skill_document = next((row["path"] for row in package.get("files", [])
                                           if Path(row["path"]).name == "SKILL.md"), None)
                    invalid_metadata = skill_document is None
                    if skill_document:
                        try:
                            preflight_skill_source(report_path.parent / "payload" / Path(skill_document).parent)
                        except (OSError, ValueError, RuntimeError):
                            invalid_metadata = True
                    if invalid_metadata:
                        blocked_files.update(file["path"] for file in package.get("files", []))
                        pending.append({"client": key[0], "source": key[1], "package": package["name"], "reason": "invalid-skill-metadata-needs-reviewed-repair"})
                    omissions = [row for row in package.get("omissions", []) if row.get("reason") not in {"environment-file-excluded", "generated-cache-excluded"}]
                    # References can legitimately address another selected
                    # package or a directory. Resolve them after all mappings;
                    # a per-package file dictionary cannot prove them missing.
                    for reference in package.get("missing_references", []):
                        reference_checks.append({"client": key[0], "source": key[1],
                                                 "package": package["name"],
                                                 "target": str((target_root / reference["path"]).resolve())})
                    unexplained_partial = (not package.get("complete", True)
                                           and not package.get("omissions") and not package.get("missing_references"))
                    incomplete = bool(omissions) or unexplained_partial
                    if incomplete and not entry.get("accept_partial", False):
                        blocked_files.update(file["path"] for file in package.get("files", []))
                        pending.append({"client": key[0], "source": key[1], "package": package["name"], "reason": "partial-package-needs-review"})
                    for file in package.get("files", []):
                        package_modes[file["path"]] = file.get("mode", 0o600)
            for name, path, data in captured:
                if kind == "skills":
                    relative_name = name.split("/payload/", 1)[1]
                    if relative_name in blocked_files:
                        continue
                    mode = package_modes.get(relative_name, 0o600) & 0o777
                else:
                    custom = entry.get("files", {})
                    if name in custom:
                        relative_name = relative(custom[name])
                    elif entry.get("layout") == "file" and len(captured) == 1:
                        relative_name = ""
                    elif entry.get("layout") == "directory":
                        marker = "/command/"
                        if marker not in name:
                            fail("text layout needs explicit files mapping")
                        relative_name = name.split(marker, 1)[1].split("/", 1)[1]
                    else:
                        fail("text source requires explicit layout=file/directory or files mapping")
                    mode = next((item.get("mode", 0o600) for item in source["files"] if item["path"] == name), 0o600) & 0o777
                    if remap:
                        text = data.decode("utf-8")
                        for old, new in sorted(remap.items(), key=lambda row: -len(row[0])):
                            text = text.replace(old, new)
                        data = text.encode()
                target = target_root / relative(relative_name) if relative_name else target_root
                no_links(target)
                if not any(beneath(target, root) for root in roots):
                    fail("target escaped destination roots")
                scan_object_bytes(b"", target.name)
                before = file_state(target)
                if before["exists"] and before["sha256"] != sha(data) and entry.get("conflict") != "replace":
                    fail("existing file conflicts; review and explicitly choose conflict=replace")
                operations.append({"client": key[0], "source": key[1], "target": str(target), "kind": kind,
                                   "before": before, "after_sha256": sha(data), "mode": before["mode"] or mode,
                                   "status": "unchanged" if before["sha256"] == sha(data) else "ready"})
                output_bytes[str(target)] = data
        else:
            fail("unsupported captured kind")
    deduplicated = {}
    for operation in operations:
        previous = deduplicated.get(operation["target"])
        if previous is not None:
            if any(previous[name] != operation[name] for name in ("before", "after_sha256", "mode")):
                fail("overlapping mappings disagree about target content or permissions")
            continue
        deduplicated[operation["target"]] = operation
    operations = list(deduplicated.values())
    targets = [row["target"] for row in operations]
    if len(targets) != len(set(targets)):
        fail("overlapping mappings target the same file; consolidate source fields before applying")
    target_paths = {Path(value) for value in targets}
    for target in target_paths:
        if any(parent in target_paths for parent in target.parents):
            fail("target file paths overlap")
    planned_directories = {parent for target in target_paths for parent in target.parents}
    for reference in reference_checks:
        target = Path(reference["target"])
        resolved_reference = target in target_paths or target in planned_directories
        if not resolved_reference and any(beneath(target, root) for root in roots):
            try:
                no_links(target)
                resolved_reference = target.exists()
            except (OSError, ValueError):
                pass
        if not resolved_reference:
            pending.append({**reference, "reason": "unresolved-package-reference"})
    unselected = [{"client": client, "source": source_id, "reason": "source-not-selected-for-this-plan"}
                  for client, source_id in sources if (client, source_id) not in selected]
    plan = {"schema_version": 1, "packet_sha256": identity, "mapping_sha256": sha(mapping_path.read_bytes()),
            "roots": [str(root) for root in roots], "operations": operations,
            "remaining_work": pending + unselected, "native_discovery": "not-run", "runtime_connectivity": "not-run"}
    return plan, output_bytes


def verify_manifest(state: Path) -> dict:
    no_links(state)
    manifest = read_json(state / "manifest.json")
    mismatches = []
    for operation in manifest["operations"]:
        current = file_state(Path(operation["target"]))
        if current["sha256"] != operation["after_sha256"] or current["mode"] != operation["mode"]:
            mismatches.append(operation["target"])
    return {"ok": not mismatches, "stage": "verify", "mismatches": mismatches,
            "files": len(manifest["operations"]), "native_discovery": "not-run", "runtime_connectivity": "not-run"}


def backup_bytes(state: Path, number: int, operation: dict) -> bytes:
    backup = state / "backups" / str(number)
    observed = file_state(backup)
    if not observed["exists"] or observed["sha256"] != operation["before"]["sha256"]:
        fail("rollback backup is missing, unsafe or changed")
    data = backup.read_bytes()
    if sha(data) != operation["before"]["sha256"]:
        fail("rollback backup changed while reading")
    no_links(backup)
    return data


def apply_plan(packet: Path, mapping: Path, plan_path: Path, state: Path) -> dict:
    if state.exists():
        fail("state must be fresh; do not replay an attempted transaction")
    saved = read_json(plan_path)
    current, outputs = build_plan(packet, mapping)
    if saved != current:
        fail("packet, mapping or destination changed; create a new reviewed plan")
    if not current["operations"]:
        fail("plan has no eligible files; resolve its remaining work before applying")
    if state == packet or packet in state.parents or state in packet.parents:
        fail("state overlaps the packet")
    if any(state == Path(op["target"]) or state in Path(op["target"]).parents or Path(op["target"]) in state.parents for op in current["operations"]):
        fail("state overlaps a target")
    state.mkdir(parents=True, mode=0o700)
    state.chmod(0o700)
    applied = []
    manifest = {"schema_version": 1, "status": "attempted", "plan_sha256": sha(plan_path.read_bytes()), "operations": current["operations"]}
    private_write(state / "manifest.json", encoded(manifest), fresh=True)
    try:
        for number, op in enumerate(current["operations"]):
            target = Path(op["target"])
            if file_state(target) != op["before"]:
                fail("target changed during apply")
            if op["status"] == "unchanged":
                continue
            if op["before"]["exists"]:
                private_write(state / "backups" / str(number), target.read_bytes(), fresh=True)
            private_write(target, outputs[op["target"]], mode=op["mode"])
            applied.append((number, op))
        manifest["status"] = "applied"
        private_write(state / "manifest.json", encoded(manifest))
        verified = verify_manifest(state)
        if not verified["ok"]:
            fail("post-write manifest verification failed")
        return {**verified, "stage": "apply", "configuration_status": "files-applied" if applied else "unchanged", "files_written": len(applied), "remaining_work": current["remaining_work"], "state": str(state)}
    except Exception:
        rollback_errors = []
        backups = {}
        # Validate every backup before restoring any file. Preserve evidence
        # and the current targets if a local backup has been lost or damaged.
        for number, op in applied:
            if op["before"]["exists"]:
                try:
                    backups[number] = backup_bytes(state, number, op)
                except (OSError, ValueError):
                    rollback_errors.append({"target": op["target"], "reason": "invalid-backup"})
        if rollback_errors:
            manifest["status"] = "failed-rollback-required"
            manifest["rollback_errors"] = rollback_errors
            private_write(state / "manifest.json", encoded(manifest))
            raise
        for number, op in reversed(applied):
            target = Path(op["target"])
            try:
                observed = file_state(target)
            except (OSError, ValueError):
                rollback_errors.append({"target": op["target"], "reason": "destination-drift-preserved"})
                continue
            if observed == op["before"]:
                continue
            if observed["sha256"] != op["after_sha256"] or observed["mode"] != op["mode"]:
                rollback_errors.append({"target": op["target"], "reason": "destination-drift-preserved"})
                continue
            try:
                if op["before"]["exists"]:
                    private_write(target, backups[number], mode=op["before"]["mode"])
                else:
                    target.unlink()
            except (OSError, ValueError):
                rollback_errors.append({"target": op["target"], "reason": "rollback-write-failed"})
        manifest["status"] = "failed-rollback-required" if rollback_errors else "failed-restored-previous-files"
        manifest["rollback_errors"] = rollback_errors
        private_write(state / "manifest.json", encoded(manifest))
        raise


def rollback(state: Path) -> dict:
    manifest = read_json(state / "manifest.json")
    if manifest.get("status") != "applied":
        fail("only an applied transaction can be rolled back")
    if not verify_manifest(state)["ok"]:
        fail("destination changed since apply; refusing destructive rollback")
    backups = {number: backup_bytes(state, number, operation)
               for number, operation in enumerate(manifest["operations"])
               if operation["status"] != "unchanged" and operation["before"]["exists"]}
    for number, operation in reversed(list(enumerate(manifest["operations"]))):
        if operation["status"] == "unchanged":
            continue
        target = Path(operation["target"])
        observed = file_state(target)
        if observed["sha256"] != operation["after_sha256"] or observed["mode"] != operation["mode"]:
            manifest["status"] = "rollback-required"
            private_write(state / "manifest.json", encoded(manifest))
            fail("destination changed during rollback; preserved its current contents")
        if operation["before"]["exists"]:
            private_write(target, backups[number], mode=operation["before"]["mode"])
        else:
            target.unlink()
    manifest["status"] = "rolled-back"
    private_write(state / "manifest.json", encoded(manifest))
    return {"ok": True, "stage": "rollback", "native_discovery": "not-run"}


def mapping_template(packet: Path, home: Path, workspace_map: Path | None) -> dict:
    packet_identity(packet)
    if not home.is_dir():
        fail("destination home must be an existing directory")
    scope = read_json(packet / "scope.json")
    review = read_json(packet / "review/index.json")
    supplied = read_json(workspace_map) if workspace_map else {}
    if not isinstance(supplied, dict):
        fail("workspace map must map source workspace IDs to existing destination directories")
    projects = []
    roots = [str(home)]
    for row in scope.get("workspaces", []):
        if row["id"] in supplied:
            target = absolute(supplied[row["id"]])
            if not target.is_dir():
                fail("mapped destination workspace must exist")
            projects.append((row["path"], target))
            roots.append(str(target))
    originals = {(c["id"], s["id"]): s for c in scope.get("review", {}).get("clients", []) for s in c["sources"]}
    home_replacements = {}
    for client in review["clients"]:
        for source in client["sources"]:
            raw = originals.get((client["id"], source["id"]), {}).get("path", "")
            expanded = source.get("source_root", "")
            if raw.startswith("~/") and expanded.startswith("/") and expanded.endswith(raw[1:]):
                old_home = expanded[:-len(raw[1:])]
                if old_home:
                    home_replacements[old_home] = str(home)
    entries, pending = [], []
    for client in review["clients"]:
        for source in client["sources"]:
            original = originals.get((client["id"], source["id"]), {})
            raw = original.get("path", source.get("canonical", ""))
            target = home / raw[2:] if raw.startswith("~/") else None
            if target is None:
                for old, destination in sorted(projects, key=lambda row: -len(row[0])):
                    if raw == old or raw.startswith(old.rstrip("/") + "/"):
                        target = destination / raw[len(old.rstrip("/")):].lstrip("/")
                        break
            if target is None or source["kind"] == "mcp-sqlite":
                pending.append({"client": client["id"], "source": source["id"], "reason": "explicit-native-target-or-project-mapping-required"})
                continue
            entry = {"client": client["id"], "source": source["id"], "target": str(target), "conflict": "error"}
            if source["kind"] in {"preferences", "hooks"}:
                entry["format"] = original.get("format")
                if source["kind"] == "hooks":
                    entry["activation_reviewed"] = False
                    entry["dependency_targets"] = {}
                    for captured in source["files"]:
                        if Path(captured["path"]).name != "hooks-review.json":
                            continue
                        payload = read_json(packet / "review" / relative(captured["path"]))
                        for dependency in payload.get("dependencies", []):
                            value = dependency["source_path"]
                            replacements = {**home_replacements, **{old: str(destination) for old, destination in projects}}
                            entry["dependency_targets"][value] = path_remap(value, replacements)
            elif source["kind"] == "mcp":
                entry["format"] = "toml" if original.get("container") == "mcp_servers" else "jsonc" if str(target).endswith("settings.json") else "json"
                entry["container"] = original.get("container", "mcpServers")
            elif source["kind"] == "text":
                entry["layout"] = original.get("layout", "file" if Path(raw).suffix else "directory")
            replacements = {**home_replacements, **{old: str(destination) for old, destination in projects}}
            if replacements:
                entry["path_map"] = replacements
            entries.append(entry)
    jsonc_targets = {row["target"] for row in entries if row.get("format") == "jsonc"}
    for row in entries:
        if row["target"] in jsonc_targets and row.get("format") == "json":
            row["format"] = "jsonc"
    return {"schema_version": 1, "roots": list(dict.fromkeys(roots)), "entries": entries,
            "pending_mappings": pending, "review_required": True,
            "note": "Review target roots, conflicts, path mappings and source exclusions. Set allow_reformat only after accepting format/comment changes. This template performs no writes to clients."}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("template", "plan", "apply", "verify", "rollback"))
    parser.add_argument("--packet", type=Path)
    parser.add_argument("--mapping", type=Path)
    parser.add_argument("--plan-out", type=Path)
    parser.add_argument("--plan-in", type=Path)
    parser.add_argument("--state-dir", type=Path)
    parser.add_argument("--yes", action="store_true")
    parser.add_argument("--destination-home", type=Path)
    parser.add_argument("--workspace-map", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        if args.action == "template":
            if not args.packet or not args.destination_home or not args.output:
                fail("template requires packet, destination-home and fresh output")
            packet = absolute(str(args.packet))
            output = absolute(str(args.output))
            if output == packet or packet in output.parents:
                fail("mapping output must stay outside the packet")
            value = mapping_template(packet, absolute(str(args.destination_home)), args.workspace_map)
            private_write(output, encoded(value), fresh=True)
            result = {"ok": True, "stage": "template", "mapping": str(output), "entries": len(value["entries"]), "pending_mappings": value["pending_mappings"], "review_required": True}
        elif args.action in {"verify", "rollback"}:
            if not args.state_dir:
                fail("state directory is required")
            state = absolute(str(args.state_dir))
            if args.action == "rollback" and not args.yes:
                fail("rollback requires existing authorization recorded by --yes")
            result = verify_manifest(state) if args.action == "verify" else rollback(state)
        else:
            if not args.packet or not args.mapping:
                fail("packet and explicit destination mapping are required")
            packet, mapping = absolute(str(args.packet)), absolute(str(args.mapping))
            if args.action == "plan":
                if not args.plan_out:
                    fail("plan-out is required")
                plan, _ = build_plan(packet, mapping)
                output = absolute(str(args.plan_out))
                if output == packet or packet in output.parents or any(output == Path(op["target"]) for op in plan["operations"]):
                    fail("plan output overlaps source or target")
                private_write(output, encoded(plan), fresh=True)
                result = {"ok": True, "stage": "plan", "plan": str(output), "files": len(plan["operations"]), "remaining_work": plan["remaining_work"], "review_required": True}
            else:
                if not args.plan_in or not args.state_dir or not args.yes:
                    fail("apply requires plan-in, fresh state-dir and --yes")
                result = apply_plan(packet, mapping, absolute(str(args.plan_in)), absolute(str(args.state_dir)))
    except (OSError, ValueError, KeyError, TypeError, RuntimeError, ImportError, ACBError) as error:
        # Never echo source fragments, parser errors or existing target values.
        reason = str(error) if isinstance(error, RestoreError) else "missing-parser-use-python-3.11-or-newer" if isinstance(error, ImportError) else "configuration operation rejected; inspect the reviewed mapping, supported formats and captured source reports"
        result = {"ok": False, "error_type": type(error).__name__, "error": reason}
        print(json.dumps(result))
        return 1
    print(json.dumps(result, ensure_ascii=False))
    return 0 if result.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
