#!/usr/bin/env python3
"""Capture explicitly selected supplemental client sources as inert review data."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import re
import sqlite3
import stat
import sys
import tempfile
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)
from acb.bundle import ACBError, ACBSecretLeak, MAX_BUNDLE_FILES, MAX_FILE_SIZE, MAX_TOTAL_SIZE, scan_object_bytes
from acb.mcp_review import _safe_review_url, collect_mcp_review
from acb.preferences import UnsupportedYAML, _decode_preferences, valid_review_fields, valid_review_map_key, valid_review_value
from acb.recovery import _safe_metadata
from acb.review import collect_review_materials
from migration_core import LossReport

IDENTIFIER = re.compile(r"[a-z0-9][a-z0-9_-]{0,79}")
NEXT_ACTION = (
    "The destination AI reviews this inert source material, repairs supported native "
    "formats, remaps paths and dependencies, and verifies same-client discovery and "
    "runtime behavior. Keep exclusions visible. Use the mature migrator for supported "
    "native restoration. Never execute or activate captured commands automatically; "
    "the user supplies authentication and required native trust decisions."
)


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as reader:
        for block in iter(lambda: reader.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def expand(value: Any) -> Path:
    if not isinstance(value, str) or not value or "\0" in value:
        raise ValueError("source path must be nonempty text")
    path = Path(value).expanduser()
    if not path.is_absolute():
        raise ValueError("source paths must be absolute or home-relative")
    return path.absolute()


def resolved(path: Path) -> Path:
    try:
        return path.resolve()
    except (OSError, RuntimeError):
        return path.absolute()


def overlaps(left: Path, right: Path) -> bool:
    return left == right or left in right.parents or right in left.parents


def linked(path: Path) -> bool:
    return any(part.is_symlink() for part in (path, *path.parents)
               if str(part) not in {"/var", "/tmp", "/etc"})


def write_json(path: Path, value: Any) -> None:
    data = (json.dumps(_safe_metadata(value), ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode()
    scan_object_bytes(data, path.name)
    with path.open("xb") as writer:
        writer.write(data)


def validate_spec(spec: Any) -> list[dict[str, Any]]:
    if not isinstance(spec, dict) or type(spec.get("schema_version")) is not int or spec["schema_version"] != 1:
        raise ValueError("unsupported spec schema")
    clients = spec.get("clients")
    if not isinstance(clients, list):
        raise ValueError("clients must be an array")
    seen: set[str] = set()
    for client in clients:
        if (not isinstance(client, dict) or not isinstance(client.get("id"), str)
                or not IDENTIFIER.fullmatch(client["id"]) or client["id"] in seen
                or not isinstance(client.get("label"), str)):
            raise ValueError("client requires a unique safe ID and label")
        seen.add(client["id"])
        if not isinstance(client.get("sources"), list):
            raise ValueError("sources must be an array")
        source_ids: set[str] = set()
        for source in client["sources"]:
            if (not isinstance(source, dict) or not isinstance(source.get("id"), str)
                    or not IDENTIFIER.fullmatch(source["id"]) or source["id"] in source_ids
                    or source.get("kind") not in {"skills", "text", "mcp", "mcp-sqlite", "preferences", "hooks", "installation-inventory", "shell-context"}):
                raise ValueError("source requires a unique safe ID and supported kind")
            source_ids.add(source["id"])
            expand(source.get("path"))
            roots = source.get("linked_roots", [])
            if not isinstance(roots, list) or (roots and source["kind"] != "skills"):
                raise ValueError("linked_roots is an optional Skills-only path array")
            for root in roots:
                expand(root)
            if source["kind"] == "hooks":
                if source.get("format") not in {"json", "jsonc", "toml"} or not source.get("fields") or not set(source["fields"]) <= {"hooks", "notify"}:
                    raise ValueError("hooks require an explicit native format and hooks/notify fields")
                for root in source.get("dependency_roots", []):
                    expand(root)
            if source["kind"] == "preferences":
                fields, records = source.get("fields", []), source.get("records", [])
                arrays, maps = source.get("string_arrays", []), source.get("maps", [])
                if (source.get("format") not in {"json", "jsonc", "toml", "yaml", "yml"}
                        or not isinstance(fields, list) or (fields and not valid_review_fields(fields))
                        or not isinstance(records, list) or not isinstance(maps, list)
                        or not isinstance(arrays, list) or (arrays and not valid_review_fields(arrays))
                        or not (fields or records or arrays or maps)):
                    raise ValueError("preferences require a format and explicit safe field-path arrays")
                map_paths: set[tuple[str, ...]] = set()
                for selected_map in maps:
                    if (not isinstance(selected_map, dict)
                            or set(selected_map) - {"path", "scalar_values", "fields"}
                            or (selected_map.get("path") != [] and not valid_review_fields([selected_map.get("path")]))
                            or (selected_map.get("scalar_values") is not True
                                and not valid_review_fields(selected_map.get("fields")))
                            or (selected_map.get("scalar_values") is True
                                and ("fields" in selected_map or selected_map.get("path") == []))):
                        raise ValueError("maps require a safe path and explicit scalar values or leaf fields")
                    identity = tuple(selected_map["path"])
                    if identity in map_paths:
                        raise ValueError("duplicate preference map path")
                    map_paths.add(identity)
                record_paths: set[tuple[str, ...]] = set()
                for record in records:
                    if (not isinstance(record, dict) or not valid_review_fields([record.get("path")])
                            or not valid_review_fields(record.get("fields"))):
                        raise ValueError("records require safe array paths and explicit scalar field paths")
                    identity = tuple(record["path"])
                    if identity in record_paths:
                        raise ValueError("duplicate preference record path")
                    record_paths.add(identity)
            if source["kind"] in {"mcp", "mcp-sqlite"}:
                if source.get("container", "mcpServers") not in {"mcpServers", "servers", "mcp", "mcp_servers"}:
                    raise ValueError("unsupported MCP container")
                if source["kind"] == "mcp-sqlite":
                    key = source.get("sqlite_key")
                    if not isinstance(key, str) or not key or "\0" in key or len(key) > 2000:
                        raise ValueError("SQLite MCP capture requires an explicit exact key")
                    if source.get("container", "mcpServers") == "mcp_servers":
                        raise ValueError("SQLite MCP review accepts only JSON server containers")
            elif "container" in source:
                raise ValueError("container applies only to MCP sources")
    return clients


def prepare_helper() -> Any:
    location = Path(__file__).with_name("prepare-skill-source.py")
    spec = importlib.util.spec_from_file_location("review_prepare_skill_source", location)
    if spec is None or spec.loader is None:
        raise ValueError("bundled Skill preparation helper unavailable")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.prepare


def preferences(path: Path, source: dict[str, Any], payload: Path, report: dict[str, Any]) -> tuple[list[dict[str, Any]], bool]:
    if not path.is_file() or path.stat().st_size > MAX_FILE_SIZE:
        raise ValueError("preference source must be an ordinary bounded file")
    source_bytes = path.read_bytes()
    report["source_content_sha256"] = hashlib.sha256(source_bytes).hexdigest()
    document = _decode_preferences(source_bytes, source["format"])
    if source["format"] in {"json", "jsonc"}:
        from migration_core import _strip_jsonc

        def unique_keys(pairs: list) -> dict:
            result = {}
            for key, value in pairs:
                if key in result:
                    raise ValueError("duplicate-preference-key")
                result[key] = value
            return result

        text = source_bytes.decode("utf-8")
        json.loads(_strip_jsonc(text) if source["format"] == "jsonc" else text,
                   object_pairs_hook=unique_keys)
    tasks: list[dict[str, Any]] = []

    def locate(data: Any, field: list[str]) -> tuple[bool, Any]:
        value = data
        for part in field:
            if not isinstance(value, dict) or part not in value:
                return False, None
            value = value[part]
        return True, value

    def select(data: dict[str, Any], wanted: list[list[str]], context: dict[str, Any], allow_arrays: bool = False) -> tuple[list[dict[str, Any]], bool]:
        selected: list[dict[str, Any]] = []
        invalid = False
        for field in wanted:
            exists, value = locate(data, field)
            if not exists:
                tasks.append({**context, "path": field, "reason": "field-not-present"})
                continue
            if not valid_review_value(value, field, allow_string_array=allow_arrays and field in source.get("string_arrays", [])):
                tasks.append({**context, "path": field, "reason": "field-not-scalar-or-finite"})
                invalid = True
                continue
            if field[-1].lower().replace("_", "").endswith(("url", "endpoint", "apibase")):
                if not isinstance(value, str):
                    tasks.append({**context, "path": field, "reason": "url-field-not-text"})
                    invalid = True
                    continue
                losses = LossReport()
                try:
                    value, query_names, credentials = _safe_review_url(value, field[-1], losses)
                except (ValueError, TypeError, OverflowError):
                    tasks.append({**context, "path": field, "reason": "invalid-url"})
                    invalid = True
                    continue
                if query_names or credentials or losses.items:
                    tasks.append({**context, "path": field, "reason": "url-components-redacted",
                                  "omitted_query_fields": query_names, "required_credentials": credentials,
                                  "userinfo_omitted": bool({"MCP_USER", "MCP_PASSWORD"} & set(credentials)),
                                  "next_action": "The destination AI reconstructs reviewed endpoint options locally; the user supplies authentication. Original URL credential/query values were not retained."})
            candidate = {"path": field, "value": value}
            try:
                scan_object_bytes(json.dumps(candidate, ensure_ascii=False, allow_nan=False).encode(), "preferences.json")
            except ACBSecretLeak:
                tasks.append({**context, "path": field, "reason": "secret-not-captured"})
                invalid = True
                continue
            selected.append(candidate)
        return selected, invalid

    wanted = source.get("fields", []) + [p for p in source.get("string_arrays", []) if p not in source.get("fields", [])]
    fields, _ = select(document, wanted, {}, allow_arrays=True)
    records: list[dict[str, Any]] = []
    examined = 0
    for requested in source.get("records", []):
        record_path = requested["path"]
        exists, raw_items = locate(document, record_path)
        if not exists:
            tasks.append({"record_path": record_path, "reason": "record-array-not-present"})
            continue
        if not isinstance(raw_items, list):
            tasks.append({"record_path": record_path, "reason": "record-source-not-array"})
            continue
        items: list[dict[str, Any]] = []
        records.append({"path": record_path, "source_length": len(raw_items), "items": items})
        for index, raw in enumerate(raw_items):
            context = {"record_path": record_path, "index": index}
            if examined >= MAX_BUNDLE_FILES:
                tasks.append({**context, "reason": "record-item-count-limit"})
                break
            examined += 1
            if not isinstance(raw, dict):
                tasks.append({**context, "reason": "record-item-not-object"})
                continue
            selected, invalid = select(raw, requested["fields"], context)
            if invalid or not selected:
                tasks.append({**context, "reason": "record-item-rejected", "next_action": "Review this omitted array item separately; other array entries retain their original indexes."})
                continue
            items.append({"index": index, "fields": selected})
    maps: list[dict[str, Any]] = []
    for requested in source.get("maps", []):
        parts = requested["path"]
        if not parts and requested.get("scalar_values") is True:
            raise ValueError("root preference maps require explicit safe leaf fields")
        exists, raw_map = locate(document, parts)
        if not exists or not isinstance(raw_map, dict):
            tasks.append({"map_path": parts, "reason": "map-not-present" if not exists else "map-source-not-object"})
            continue
        entries: list[dict[str, Any]] = []
        maps.append({"path": parts, "entries": entries})
        for index, (key, raw) in enumerate(raw_map.items()):
            context = {"map_path": parts, "index": index}
            if examined >= MAX_BUNDLE_FILES:
                tasks.append({**context, "reason": "map-item-count-limit"})
                break
            examined += 1
            if not valid_review_map_key(key, root=not parts):
                tasks.append({**context, "reason": "unsafe-map-identity-not-captured"})
                continue
            if requested.get("scalar_values") is True:
                if isinstance(raw, (dict, list)):
                    tasks.append({**context, "reason": "map-value-not-scalar"})
                    continue
                selected, _ = select({"value": raw}, [["value"]], context)
                if selected:
                    entries.append({"key": key, "value": selected[0]["value"]})
            elif not isinstance(raw, dict):
                tasks.append({**context, "reason": "map-entry-not-object"})
            else:
                selected, _ = select(raw, requested["fields"], context)
                if selected:
                    entries.append({"key": key, "fields": selected})
    if fields or records or maps:
        payload.mkdir(mode=0o700)
        write_json(payload / "preferences.json", {"schema_version": 1, "review_only": True, "fields": fields,
                                                   "records": records, "maps": maps,
                                                   "string_arrays": source.get("string_arrays", []),
                                                   "source_content_sha256": report["source_content_sha256"],
                                                   "next_action": "The destination AI manually merges only reviewed field paths into the matching native client, preserving siblings, then checks native settings and runtime. This is not an importable replacement settings file."})
    return tasks, bool(fields or records or maps)


def sqlite_mcp(path: Path, source: dict[str, Any], client_id: str,
               report: dict[str, Any]) -> tuple[dict[str, bytes], list[dict[str, Any]]]:
    """Read exactly one explicit ItemTable key; never copy or execute the DB."""
    if not path.is_file():
        return {}, [{"reason": "sqlite-source-not-file"}]
    report["sqlite_key_sha256"] = hashlib.sha256(source["sqlite_key"].encode()).hexdigest()

    def inspect(file: Path) -> tuple[int, int, str] | None:
        if file.is_symlink():
            raise ValueError("sqlite-source-unsafe-or-too-large")
        try:
            descriptor = os.open(file, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0))
        except FileNotFoundError:
            return None
        digest = hashlib.sha256()
        with os.fdopen(descriptor, "rb") as reader:
            before = os.fstat(reader.fileno())
            if not stat.S_ISREG(before.st_mode) or before.st_size > MAX_TOTAL_SIZE:
                raise ValueError("sqlite-source-unsafe-or-too-large")
            total = 0
            for block in iter(lambda: reader.read(1024 * 1024), b""):
                total += len(block)
                if total > MAX_TOTAL_SIZE:
                    raise ValueError("sqlite-source-unsafe-or-too-large")
                digest.update(block)
            after = os.fstat(reader.fileno())
            if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
                raise ValueError("sqlite-source-changed-during-capture")
        return total, after.st_mtime_ns, digest.hexdigest()

    sources = {"database": path, "wal": Path(str(path) + "-wal")}
    with tempfile.TemporaryDirectory(prefix="mcp-review-sqlite-") as temporary:
        root = Path(temporary).resolve()
        root.chmod(0o700)
        # SQLite read-only WAL readers may update shared-memory reader slots.
        # Query only a stable private main+WAL copy, never the source SHM.
        staged_database = root / "source.sqlite"
        targets = {"database": staged_database, "wal": Path(str(staged_database) + "-wal")}
        try:
            before = {name: inspect(file) for name, file in sources.items()}
            if before["database"] is None or sum(item[0] for item in before.values() if item) > MAX_TOTAL_SIZE:
                raise ValueError("sqlite-source-unsafe-or-too-large")
            for name, file in sources.items():
                if before[name] is None:
                    continue
                descriptor = os.open(file, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0))
                copied_hash = hashlib.sha256()
                written = 0
                target_descriptor = os.open(targets[name], os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
                with os.fdopen(descriptor, "rb") as reader, os.fdopen(target_descriptor, "wb") as writer:
                    if not stat.S_ISREG(os.fstat(reader.fileno()).st_mode):
                        raise ValueError("sqlite-source-unsafe-or-too-large")
                    for block in iter(lambda: reader.read(1024 * 1024), b""):
                        written += len(block)
                        if written > MAX_TOTAL_SIZE:
                            raise ValueError("sqlite-source-unsafe-or-too-large")
                        copied_hash.update(block)
                        writer.write(block)
                if (written, copied_hash.hexdigest()) != (before[name][0], before[name][2]):
                    raise ValueError("sqlite-source-changed-during-capture")
            after = {name: inspect(file) for name, file in sources.items()}
            if before != after:
                raise ValueError("sqlite-source-changed-during-capture")
        except OSError:
            return {}, [{"reason": "sqlite-source-changed-or-unreadable", "next_action": "Retry after the source client reaches a stable state. No partial database snapshot was accepted."}]
        except ValueError as error:
            return {}, [{"reason": str(error), "next_action": "Retry a stable bounded source snapshot or explicitly defer it. Only stable copies are queried; original database/WAL/SHM are never opened by SQLite."}]
        report["source_content_sha256"] = before["database"][2]
        report["source_wal_sha256"] = before["wal"][2] if before["wal"] else None
        report["sqlite_capture"] = "stable-private-main-and-wal-copy; source-shm-untouched"
        try:
            connection = sqlite3.connect(staged_database.as_uri() + "?mode=ro", uri=True, timeout=2)
            try:
                connection.execute("PRAGMA query_only=ON")
                rows = connection.execute('SELECT "value" FROM "ItemTable" WHERE "key" = ? LIMIT 2',
                                          (source["sqlite_key"],)).fetchmany(2)
            finally:
                connection.close()
        except sqlite3.Error:
            return {}, [{"reason": "sqlite-read-failed", "next_action": "Review the selected client's exact storage key/schema separately; no database contents or error text were exported."}]
        if not rows:
            return {}, [{"reason": "sqlite-key-not-present", "next_action": "Confirm the explicitly selected key on the original client; no other keys were queried."}]
        if len(rows) != 1 or not isinstance(rows[0][0], (str, bytes)):
            return {}, [{"reason": "sqlite-value-not-unique-json-text"}]
        data = rows[0][0].encode("utf-8") if isinstance(rows[0][0], str) else rows[0][0]
        if len(data) > MAX_FILE_SIZE:
            return {}, [{"reason": "sqlite-value-size-limit"}]
        report["source_value_sha256"] = hashlib.sha256(data).hexdigest()
        selected = root / "selected.json"
        descriptor = os.open(selected, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(descriptor, "wb") as writer:
            writer.write(data)
        row = {"product": client_id, "profile": "manual", "scope": "user", "object_type": "mcp",
               "path": source["path"], "canonical_path": source["path"],
               "resolved_path": str(selected), "boundary": str(root),
               "policy": "manual-rebuild", "storage": "file",
               "source_format": "json:" + source.get("container", "mcpServers")}
        files, _, _, tasks = collect_mcp_review([row], selected_profiles={client_id + "/manual"}, scopes={"user"})
    return files, tasks


def capture(spec_path: Path, output: Path) -> dict[str, Any]:
    if output.exists() or output.is_symlink():
        raise ValueError("output must be fresh")
    clients = validate_spec(json.loads(spec_path.read_text(encoding="utf-8")))
    output = output.expanduser().absolute()
    protected = [expand(source["path"]) for client in clients for source in client["sources"]]
    protected.extend(expand(root) for client in clients for source in client["sources"]
                     for root in source.get("linked_roots", []))
    protected.extend(expand(root) for client in clients for source in client["sources"]
                     for root in source.get("dependency_roots", []))
    if any(overlaps(resolved(output), resolved(source)) for source in protected):
        raise ValueError("output must not overlap any source or reviewed linked root")
    output.mkdir(parents=True, mode=0o700)
    output.chmod(0o700)
    index: dict[str, Any] = {"schema_version": 1, "inert_review_only": True,
                             "automatic_restore": False, "clients": [], "next_actions": [NEXT_ACTION]}
    prepare = prepare_helper()
    for client in clients:
        client_report: dict[str, Any] = {"id": client["id"], "label": client["label"], "sources": []}
        index["clients"].append(client_report)
        for source in client["sources"]:
            path = expand(source["path"])
            directory = output / "clients" / client["id"] / "sources" / source["id"]
            directory.mkdir(parents=True, mode=0o700)
            payload = directory / "payload"
            report: dict[str, Any] = {
                "schema_version": 1, "client_id": client["id"], "id": source["id"],
                "kind": source["kind"], "source_canonical": source["path"],
                "path_usage": "source identity data only; never a command or default destination",
                "automatic_restore": False, "status": "excluded", "payloads": [],
                "tasks": [], "next_actions": [NEXT_ACTION],
            }
            try:
                if (source["kind"] != "mcp-sqlite" and path.is_file() and not linked(path)
                        and path.stat().st_size <= MAX_FILE_SIZE):
                    report["source_content_sha256"] = sha(path)
                if source["kind"] != "skills" and linked(path):
                    report["tasks"].append({"reason": "symlink-not-captured", "next_action": "Review the real source separately; links are not followed for text or MCP."})
                elif not path.exists():
                    report["status"] = "missing"
                    report["tasks"].append({"reason": "source-missing", "next_action": "Locate or explicitly defer this source before retiring the old computer."})
                elif source["kind"] == "skills":
                    preparation = prepare(path, payload, directory / "skill-packages.json",
                                          [expand(root) for root in source.get("linked_roots", [])], sanitize_review=True)
                    report["tasks"] = preparation["entries"]
                    report["status"] = "captured-review" if preparation["files_staged"] else "excluded"
                    if any(entry["status"] != "staged" for entry in preparation["entries"]) and preparation["files_staged"]:
                        report["status"] = "partial"
                elif source["kind"] == "preferences":
                    tasks, saved = preferences(path, source, payload, report)
                    report["tasks"] = tasks
                    if saved:
                        report["status"] = "partial" if tasks else "captured-review"
                elif source["kind"] == "hooks":
                    from acb.hook_review import collect_hook_review
                    files, tasks = collect_hook_review(path, source)
                    for name, data in files.items():
                        relative = Path(name)
                        if relative.is_absolute() or ".." in relative.parts:
                            raise ValueError("invalid captured hook payload path")
                        target = payload / relative
                        target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
                        with target.open("xb") as writer:
                            writer.write(data)
                    report["tasks"] = tasks
                    report["status"] = ("partial" if tasks else "captured-review") if files else "excluded"
                elif source["kind"] in {"installation-inventory", "shell-context"}:
                    if source["kind"] == "installation-inventory":
                        from acb.install_inventory import collect_install_inventory
                        files, tasks = collect_install_inventory(path, source)
                    else:
                        from acb.shell_context import collect_shell_context
                        files, tasks = collect_shell_context(path, source)
                    for name, data in files.items():
                        relative = Path(name)
                        if relative.is_absolute() or ".." in relative.parts:
                            raise ValueError("invalid inert payload path")
                        target = payload / relative
                        target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
                        with target.open("xb") as writer:
                            writer.write(data)
                    report["tasks"] = tasks
                    report["status"] = ("partial" if tasks else "captured-review") if files else "excluded"
                else:
                    row = {"product": client["id"], "profile": "manual", "scope": "user",
                           "object_type": "mcp" if source["kind"] in {"mcp", "mcp-sqlite"} else "command",
                           "path": source["path"], "canonical_path": source["path"],
                           "resolved_path": str(path), "boundary": str(path.parent),
                           "policy": "manual-rebuild", "storage": "directory" if path.is_dir() else "file"}
                    if source["kind"] == "mcp-sqlite":
                        files, tasks = sqlite_mcp(path, source, client["id"], report)
                    elif source["kind"] == "mcp":
                        container = source.get("container", "mcpServers")
                        row["source_format"] = "toml:mcp_servers" if container == "mcp_servers" else "jsonc:" + container
                        files, _, _, tasks = collect_mcp_review([row], selected_profiles={client["id"] + "/manual"}, scopes={"user"})
                    else:
                        files, _, _, tasks = collect_review_materials([row], selected_profiles={client["id"] + "/manual"}, scopes={"user"})
                    for name, data in files.items():
                        target = payload / name
                        target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
                        with target.open("xb") as writer:
                            writer.write(data)
                    prefix = payload.relative_to(output).as_posix() + "/"
                    for task in tasks:
                        if task.get("payload_path"):
                            task["payload_path"] = prefix + task["payload_path"].removeprefix("objects/")
                    report["tasks"] = tasks
                    if files:
                        successful = {"review-material-captured", "mcp-review-definition-captured"}
                        report["status"] = "partial" if any(task["reason"] not in successful for task in tasks) else "captured-review"
            except ModuleNotFoundError:
                report["tasks"].append({"reason": "missing-tomllib-parser", "next_action": "Use Python 3.11+ for TOML review capture; no parser is installed automatically."})
            except UnsupportedYAML:
                report["tasks"].append({"reason": "yaml-unsupported-or-invalid", "next_action": "The bounded data-only YAML reader rejected complex or invalid syntax. The AI must review the original and export selected values as JSON separately; tags, anchors, aliases and other unsupported constructs are never evaluated."})
            except (OSError, ValueError, RuntimeError, ACBError) as error:
                report["tasks"].append({"reason": "source-unreadable-unsafe-or-invalid", "error_type": type(error).__name__, "next_action": "The destination AI must resolve this exclusion from the preserved original source."})
            if payload.is_dir():
                file_modes = {}
                for task in report["tasks"]:
                    for name, mode in task.get("file_modes", {}).items():
                        file_modes[payload.relative_to(output).as_posix() + "/" + name.removeprefix("objects/")] = mode
                report["payloads"] = [{"path": item.relative_to(output).as_posix(), "sha256": sha(item)}
                                      for item in sorted(payload.rglob("*")) if item.is_file()]
                for item in report["payloads"]:
                    if item["path"] in file_modes:
                        item["mode"] = file_modes[item["path"]]
            write_json(directory / "report.json", report)
            successful = {"review-material-captured", "mcp-review-definition-captured"}
            exclusions = [task for task in report["tasks"]
                          if task.get("status") not in {"staged"} and task.get("reason") not in successful]
            client_report["sources"].append({"id": source["id"], "kind": source["kind"],
                                             "canonical": source["path"], "source_root": str(path),
                                             "status": report["status"], "files": report["payloads"],
                                             "source_content_sha256": report.get("source_content_sha256"),
                                             "source_value_sha256": report.get("source_value_sha256"),
                                             "source_wal_sha256": report.get("source_wal_sha256"),
                                             "exclusions": exclusions, "next_actions": report["next_actions"],
                                             "report": (directory / "report.json").relative_to(output).as_posix()})
            for metadata in ("scope", "workspace", "classification", "activation"):
                if metadata in source:
                    client_report["sources"][-1][metadata] = source[metadata]
    write_json(output / "index.json", index)
    checksums = {path.relative_to(output).as_posix(): sha(path)
                 for path in sorted(output.rglob("*")) if path.is_file()}
    write_json(output / "checksums.json", checksums)
    total = 0
    for count, path in enumerate(sorted(output.rglob("*")), 1):
        if path.is_symlink() or not (path.is_dir() or path.is_file()):
            raise ValueError("unsafe output entry")
        if path.is_file():
            size = path.stat().st_size
            total += size
            if count > MAX_BUNDLE_FILES or size > MAX_FILE_SIZE or total > MAX_TOTAL_SIZE:
                raise ValueError("supplemental capture exceeds bundle limits")
            scan_object_bytes(path.relative_to(output).as_posix().encode(), "filename-metadata.txt")
            scan_object_bytes(path.read_bytes(), path.name)
    return {"ok": True, "inert_review_only": True, "automatic_restore": False,
            "output": str(output), "index": str(output / "index.json"),
            "clients": len(clients), "source_unchanged": "read-only-operation"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        result = capture(args.spec, args.output)
    except (OSError, ValueError, RuntimeError, ACBError) as error:
        result = {"ok": False, "error_type": type(error).__name__, "status": "capture-incomplete"}
    print(json.dumps(result, ensure_ascii=False))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
