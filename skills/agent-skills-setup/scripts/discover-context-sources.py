#!/usr/bin/env python3
"""Discover bounded, explicitly selected client context and write an export draft.

Discovery never installs, activates or executes source material. Configuration
values stay in their source files: the export draft names field-aware readers.
"""

from __future__ import annotations

import argparse
import hashlib
from itertools import islice
import json
import os
from pathlib import Path
import re
import sqlite3
import stat
import sys
from typing import Any

sys.dont_write_bytecode = True
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)
from acb.bundle import ACBError, MAX_BUNDLE_FILES, MAX_DIR_DEPTH, MAX_FILE_SIZE, MAX_TOTAL_SIZE, scan_object_bytes
from acb.preferences import _decode_preferences, valid_review_fields
from acb.recovery import _safe_metadata
from migration_core import FRONTMATTER, SKILL_NAME, _skill_metadata

SKILL = Path(__file__).resolve().parent.parent
CATALOG = SKILL / "assets/client-source-catalog.json"
CLIENTS = ("trae", "codex", "antigravity", "claude-code", "tuanjie", "workbuddy")
SCOPES = {"user", "project", "local"}
SKIP_DIRECTORIES = {".git", "node_modules", "__pycache__", ".pytest_cache", ".cache"}
CONTAINERS = ("mcpServers", "servers", "mcp", "mcp_servers")
JSON_CONTAINERS = CONTAINERS[:3]
SENSITIVE_KEY = re.compile(r"(?i)(chat|session|history|prompt|secret|oauth|token|password|trust|permission|approval|autorun|alwaysrun)")


def safe(value: Any) -> Any:
    return _safe_metadata(value)


def identifier(value: str) -> str:
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,99}", value):
        raise ValueError("invalid-identifier")
    return value


def overlaps(left: Path, right: Path) -> bool:
    return left == right or left in right.parents or right in left.parents


def path_name(path: Path, home: Path) -> str:
    try:
        return "~/" + path.absolute().relative_to(home).as_posix()
    except ValueError:
        return str(path.absolute())


def source_id(path: Path, kind: str, workspace: str | None = None) -> str:
    digest = hashlib.sha256((kind + "\0" + str(path)).encode()).hexdigest()[:14]
    return (workspace[:24] + "-" if workspace else "user-") + kind.replace("-sqlite", "") + "-" + digest


def linked(path: Path) -> bool:
    return any(p.is_symlink() for p in (path, *path.parents)
               if str(p) not in {"/tmp", "/var", "/etc"})


def children(path: Path) -> list[Path]:
    entries = list(islice(path.iterdir(), MAX_BUNDLE_FILES + 1))
    if len(entries) > MAX_BUNDLE_FILES:
        raise ValueError("directory-entry-limit")
    return sorted(entries)


def read_document(path: Path, format_name: str) -> dict[str, Any]:
    if not path.is_file() or path.stat().st_size > MAX_FILE_SIZE:
        raise ValueError("source-not-bounded-file")
    with path.open("rb") as reader:
        return _decode_preferences(reader.read(MAX_FILE_SIZE + 1), format_name)


def locate(data: Any, path: list[str]) -> tuple[bool, Any]:
    current = data
    for part in path:
        if not isinstance(current, dict) or part not in current:
            return False, None
        current = current[part]
    return True, current


def skill_metadata(path: Path) -> str:
    """Check only bounded metadata; actual capture performs the content scan."""
    try:
        document = path / "SKILL.md"
        if document.stat().st_size > MAX_FILE_SIZE:
            return "metadata-too-large"
        with document.open("rb") as reader:
            text = reader.read(MAX_FILE_SIZE + 1).decode("utf-8")
        match = FRONTMATTER.match(text)
        if not match:
            return "invalid-metadata"
        metadata = _skill_metadata(match.group(1))
        name, description = metadata.get("name", ""), metadata.get("description", "")
        if not SKILL_NAME.fullmatch(name) or len(name) > 64 or not description.strip() or len(description) > 1024:
            return "invalid-metadata"
        return "valid-metadata-not-content-scanned"
    except (OSError, UnicodeError, ValueError):
        return "invalid-or-unreadable-metadata"


def skill_packages(root: Path) -> tuple[list[Path], list[dict[str, Any]]]:
    """Find nested namespace packages only beneath an explicit Skill root."""
    packages: list[Path] = []
    issues: list[dict[str, Any]] = []
    visited: set[Path] = set()
    nodes = 0

    def walk(path: Path, depth: int) -> None:
        nonlocal nodes
        nodes += 1
        if nodes > MAX_BUNDLE_FILES or depth > MAX_DIR_DEPTH:
            raise ValueError("skill-discovery-resource-limit")
        if path.name in SKIP_DIRECTORIES:
            return
        try:
            if not path.is_dir():
                return
            resolved = path.resolve(strict=True)
            if resolved in visited:
                issues.append({"relative_path": path.relative_to(root).as_posix(), "status": "duplicate-or-cyclic-container"})
                return
            # A package link is explicit source evidence; do not traverse an
            # external namespace/container link without a package marker.
            if (path / "SKILL.md").is_file():
                packages.append(path)
                return
            if path.is_symlink() and path != root:
                issues.append({"relative_path": path.relative_to(root).as_posix(), "status": "linked-container-not-followed"})
                return
            visited.add(resolved)
            for child in children(path):
                if child.is_dir():
                    walk(child, depth + 1)
        except (OSError, RuntimeError):
            issues.append({"relative_path": path.relative_to(root).as_posix(), "status": "unreadable-or-unresolvable"})

    try:
        walk(root, 0)
    except ValueError:
        issues.append({"status": "skill-discovery-resource-limit"})
    return packages, issues


def skill_links(package: Path, home: Path, workspaces: list[dict[str, str]]) -> tuple[list[str], list[dict[str, Any]], bool]:
    """Name exact link targets; never widen a grant to a parent directory."""
    roots: set[str] = set()
    evidence: list[dict[str, Any]] = []
    visiting: set[Path] = set()
    nodes = 0
    complete = True
    broad_roots = {home.resolve(), *(Path(row["path"]).resolve() for row in workspaces)}

    def walk(path: Path, depth: int, relative: str) -> None:
        nonlocal nodes, complete
        nodes += 1
        if nodes > MAX_BUNDLE_FILES or depth > MAX_DIR_DEPTH:
            complete = False
            return
        if path.name in SKIP_DIRECTORIES:
            return
        try:
            resolved = path.resolve(strict=True)
            if path.is_symlink():
                broad = resolved in broad_roots or len(resolved.parts) < 3
                record = {"relative_path": relative or ".", "target": path_name(resolved, home),
                          "reason": "package-source-link" if path == package else "package-referenced-link",
                          "status": "broad-link-target-not-approved" if broad else "review-required-exact-target"}
                evidence.append(record)
                if broad:
                    complete = False
                    return
                roots.add(str(resolved))
            mode = resolved.stat().st_mode
            if stat.S_ISDIR(mode):
                if resolved in visiting:
                    complete = False
                    evidence.append({"relative_path": relative or ".", "status": "link-cycle"})
                    return
                visiting.add(resolved)
                for child in children(path):
                    walk(child, depth + 1, (relative + "/" if relative else "") + child.name)
                visiting.remove(resolved)
            elif not stat.S_ISREG(mode):
                complete = False
                evidence.append({"relative_path": relative, "status": "non-regular-source"})
        except (OSError, RuntimeError, ValueError):
            complete = False
            evidence.append({"relative_path": relative or ".", "status": "unreadable-or-unresolvable-link"})

    walk(package, 0, "")
    return sorted(roots), evidence, complete


def sqlite_mcp(path: Path) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    """Inspect schema/keys and only MCP-related bounded JSON values.

    immutable read-only mode cannot create journal/shm files. A live WAL makes
    the view incomplete, so no operational source is emitted until closed.
    """
    result: dict[str, Any] = {"status": "sqlite-no-mcp-definition", "table": "ItemTable", "keys": []}
    sources: list[dict[str, Any]] = []
    if linked(path):
        return [], {"status": "sqlite-symlink-not-read"}
    if path.with_name(path.name + "-wal").exists():
        return [], {"status": "sqlite-live-wal-requires-closed-client", "next_action": "Close the source client and rediscover; do not checkpoint or copy its database."}
    try:
        connection = sqlite3.connect(path.resolve().as_uri() + "?mode=ro&immutable=1", uri=True, timeout=2)
        try:
            connection.execute("PRAGMA query_only=ON")
            connection.set_progress_handler(lambda: 1, 200000)
            columns = [(row[1], row[2]) for row in connection.execute("PRAGMA table_info(ItemTable)")]
            result["columns"] = [{"name": name, "type": kind} for name, kind in columns]
            if not {"key", "value"} <= {name for name, _ in columns}:
                result["status"] = "sqlite-unsupported-schema"
                return [], result
            keys = [row[0] for row in connection.execute(
                "SELECT key FROM ItemTable WHERE lower(key) LIKE '%mcp%' OR key LIKE 'currentAgentData_%' ORDER BY key LIMIT ?",
                (MAX_BUNDLE_FILES + 1,))]
            if len(keys) > MAX_BUNDLE_FILES:
                result["status"] = "sqlite-key-count-limit"
                return [], result
            total = 0
            for key in keys:
                if not isinstance(key, str) or len(key) > 512:
                    result["keys"].append({"status": "sqlite-invalid-key"})
                    continue
                entry: dict[str, Any] = {"key": safe(key), "status": "sqlite-unsupported-json-shape"}
                result["keys"].append(entry)
                if safe(key) != key or SENSITIVE_KEY.search(key):
                    entry["status"] = "excluded-sensitive-or-execution-state-key"
                    continue
                row = connection.execute("SELECT value FROM ItemTable WHERE key=? AND length(value)<=?", (key, MAX_FILE_SIZE)).fetchone()
                if row is None:
                    entry["status"] = "sqlite-value-size-limit"
                    continue
                try:
                    raw = row[0].encode() if isinstance(row[0], str) else row[0]
                    total += len(raw)
                    if total > MAX_TOTAL_SIZE:
                        result["status"] = "sqlite-value-total-size-limit"
                        return sources, result
                    data = _decode_preferences(raw, "jsonc")
                except (ValueError, TypeError, UnicodeError):
                    entry["status"] = "sqlite-non-json-object"
                    continue
                if key.startswith("currentAgentData_"):
                    entry["status"] = "sqlite-mcp-binding-references-only" if isinstance(data.get("mcp_list"), list) else "excluded-agent-state"
                    continue
                for container in JSON_CONTAINERS:
                    values = data.get(container)
                    if isinstance(values, dict):
                        entry["status"] = "sqlite-mcp-definition-reader-required"
                        entry.setdefault("containers", []).append(container)
                        sources.append({"kind": "mcp-sqlite", "sqlite_key": key, "container": container})
            if sources:
                result["status"] = "sqlite-mcp-sources-declared-not-captured"
        finally:
            connection.close()
    except (OSError, sqlite3.Error, ValueError):
        result["status"] = "sqlite-unreadable-or-query-limit"
    return sources, result


def identity(value: Any) -> bool:
    """Accept only inert package identity syntax, then run the shared scanner."""
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9@][A-Za-z0-9@._/+-]{0,239}", value):
        return False
    return safe(value) == value


def plugin_inventory(client_id: str, path: Path, candidate: dict[str, Any], home: Path) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    report: dict[str, Any] = {"path": safe(path_name(path, home)), "kind": "plugins", "scope": "user", "status": "missing", "tasks": []}
    if not path.exists():
        return rows, report
    if linked(path):
        report["status"] = "inventory-symlink-not-read"
        report["tasks"].append({"reason": report["status"]})
        return rows, report
    try:
        data = read_document(path, candidate["format"])
        exists, entries = locate(data, candidate["container"])
        if not exists:
            report["status"] = "inventory-container-missing"
            return rows, report
        if not isinstance(entries, dict) or len(entries) > MAX_BUNDLE_FILES:
            report["status"] = "inventory-container-invalid-or-over-limit"
            report["tasks"].append({"reason": report["status"]})
            return rows, report
        for index, (name, raw) in enumerate(entries.items()):
            if not identity(name):
                report["tasks"].append({"item_index": index, "reason": "unsafe-plugin-identity-not-exported"})
                continue
            row: dict[str, Any] = {"client": client_id, "id": name, "source": path_name(path, home),
                                    "status": "inventory-only-not-activated"}
            if candidate.get("enabled_field") == "$value":
                if not isinstance(raw, bool):
                    report["tasks"].append({"item_index": index, "reason": "plugin-enabled-value-not-boolean"})
                    continue
                row["enabled"] = raw
            elif isinstance(raw, dict):
                enabled = raw.get(candidate.get("enabled_field", "enabled"))
                if isinstance(enabled, bool):
                    row["enabled"] = enabled
                installed = raw.get(candidate.get("installed_from_field", "installedFrom"))
                if isinstance(installed, dict):
                    chosen: dict[str, str] = {}
                    for key in ("id", "marketplace", "version"):
                        if key in installed:
                            if identity(installed[key]):
                                chosen[key] = installed[key]
                            else:
                                report["tasks"].append({"item_index": index, "reason": "unsafe-installed-identity-field-not-exported", "field": key})
                    if chosen:
                        row["installed_from"] = chosen
            else:
                report["tasks"].append({"item_index": index, "reason": "plugin-record-not-supported-object"})
                continue
            if safe(row) == row:
                rows.append(row)
            else:
                report["tasks"].append({"item_index": index, "reason": "unsafe-plugin-metadata-not-exported"})
        report["status"] = "partial-inventory-not-activated" if report["tasks"] else "inventory-only-not-activated"
        report["items"] = len(rows)
    except ModuleNotFoundError:
        report["status"] = "inventory-missing-parser"
        report["tasks"].append({"reason": report["status"], "next_action": "Use Python 3.11+ to read this TOML inventory; no parser was installed."})
    except (OSError, ValueError, UnicodeError, TypeError):
        report["status"] = "inventory-unreadable-or-invalid-format"
        report["tasks"].append({"reason": report["status"]})
    return rows, report


def extension_inventory(client_id: str, path: Path, home: Path) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    report: dict[str, Any] = {"path": safe(path_name(path, home)), "kind": "extensions", "scope": "user", "status": "missing", "tasks": []}
    if not path.exists():
        return rows, report
    if not path.is_dir():
        report["status"] = "inventory-source-not-directory"
        report["tasks"].append({"reason": report["status"]})
        return rows, report
    if linked(path):
        report["status"] = "inventory-symlink-not-read"
        report["tasks"].append({"reason": report["status"]})
        return rows, report
    try:
        for index, child in enumerate(children(path)):
            if child.is_symlink():
                report["tasks"].append({"item_index": index, "reason": "extension-link-not-read"})
                continue
            if not child.is_dir():
                continue
            package = child / "package.json"
            if package.is_symlink():
                report["tasks"].append({"item_index": index, "reason": "extension-manifest-link-not-read"})
                continue
            try:
                data = read_document(package, "json")
            except (OSError, ValueError, UnicodeError, TypeError):
                report["tasks"].append({"item_index": index, "reason": "extension-manifest-unreadable-or-invalid"})
                continue
            if not all(identity(data.get(key)) for key in ("publisher", "name", "version")):
                report["tasks"].append({"item_index": index, "reason": "extension-identity-unsafe-or-missing"})
                continue
            row = {"client": client_id, "source_root": path_name(path, home),
                   **{key: data[key] for key in ("publisher", "name", "version")}}
            if safe(row) == row:
                rows.append(row)
            else:
                report["tasks"].append({"item_index": index, "reason": "unsafe-extension-metadata-not-exported"})
        report["status"] = "partial-inventory-not-installed" if report["tasks"] else "inventory-only-not-installed"
        report["items"] = len(rows)
    except (OSError, ValueError, RuntimeError):
        report["status"] = "inventory-unreadable-or-resource-limited"
        report["tasks"].append({"reason": report["status"]})
    return rows, report


def discover(selected: list[str], workspaces: list[dict[str, str]], scopes: set[str], output: Path) -> dict[str, Any]:
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    if not selected or len(set(selected)) != len(selected) or set(selected) - set(CLIENTS):
        raise ValueError("clients-require-explicit-unique-supported-ids")
    if not scopes or not scopes <= SCOPES:
        raise ValueError("invalid-scopes")
    if output.exists() or output.is_symlink():
        raise ValueError("output-must-be-fresh")
    home = Path.home().absolute()
    output = output.expanduser().absolute()
    protected: list[Path] = [SKILL.resolve(), *(Path(row["path"]).resolve() for row in workspaces)]
    scope: dict[str, Any] = {"schema_version": 1, "clients": [], "workspaces": workspaces,
                            "review": {"schema_version": 1, "clients": []}, "shared_source_mappings": [],
                            "explicit_exclusions": [], "discovery_report": str(output / "discovery.json"),
                            "selected_plugin_inventory": [], "selected_extension_inventory": []}
    discovery: dict[str, Any] = {"schema_version": 1, "selected_clients": selected,
                                "selected_scopes": sorted(scopes), "source_unchanged": True,
                                "configuration_values_exported": False, "automatic_restore_verified": False,
                                "selection_basis": "explicit-client-arguments-not-installation-detection",
                                "scope_draft": "scope.json", "clients": []}
    for client_id in selected:
        client = catalog["clients"][client_id]
        scope["clients"].append({"id": client_id, "label": client["label"],
                                  "native_profiles": [{"selector": selector, "scopes": sorted(scopes)}
                                                      for selector in client["native_profiles"]]})
        review: dict[str, Any] = {"id": client_id, "label": client["label"], "sources": []}
        scope["review"]["clients"].append(review)
        report: dict[str, Any] = {"id": client_id, "label": client["label"], "sources": [],
                                  "inventories": [], "routing_notes": client.get("routing_notes", []), "exclusions": client["exclusions"]}
        discovery["clients"].append(report)
        scope["explicit_exclusions"].append({"client": client_id, "categories": client["exclusions"]})
        if "user" in scopes:
            for inventory in client.get("inventories", []):
                path = Path(inventory["path"]).expanduser().absolute()
                protected.append(path.resolve())
                if inventory["kind"] == "plugins":
                    rows, finding = plugin_inventory(client_id, path, inventory, home)
                    scope["selected_plugin_inventory"].extend(rows)
                else:
                    rows, finding = extension_inventory(client_id, path, home)
                    scope["selected_extension_inventory"].extend(rows)
                report["inventories"].append(finding)
        for candidate in client["sources"]:
            if candidate["scope"] not in scopes:
                continue
            contexts = [(None, home)] if candidate["scope"] == "user" else [(row["id"], Path(row["path"])) for row in workspaces]
            for workspace, boundary in contexts:
                path = Path(candidate["path"]).expanduser() if candidate["scope"] == "user" else boundary / candidate["path"]
                path = path.absolute()
                protected.append(path.resolve())
                name = path_name(path, home)
                entry: dict[str, Any] = {"path": safe(name), "kind": candidate["kind"], "scope": candidate["scope"],
                                          "status": "missing", "workspace": workspace}
                report["sources"].append(entry)
                if safe(name) != name:
                    entry["status"] = "unsafe-source-metadata"
                    continue
                if not path.exists():
                    entry["status"] = "unresolvable-source-link" if path.is_symlink() else "missing"
                    continue
                kind = candidate["kind"]
                if kind == "skills":
                    if not path.is_dir():
                        entry["status"] = "not-a-skill-directory"
                        continue
                    packages, issues = skill_packages(path)
                    entry["packages"] = []
                    entry["issues"] = issues
                    entry["status"] = "discovered-not-captured" if packages else "no-skill-package-markers"
                    if issues:
                        entry["status"] = "partial-discovery"
                    for package in packages:
                        source_name = path_name(package, home)
                        row = {"path": safe(source_name), "relative_package": safe(package.relative_to(path).as_posix()),
                               "metadata_status": skill_metadata(package)}
                        entry["packages"].append(row)
                        if safe(source_name) != source_name:
                            row["status"] = "unsafe-source-metadata"
                            continue
                        roots, evidence, complete = skill_links(package, home, workspaces)
                        protected.extend(Path(root) for root in roots)
                        row["linked_roots_review"] = evidence
                        row["status"] = "discovered-not-captured" if complete else "incomplete-link-discovery"
                        spec = {"id": source_id(package, "skills", workspace), "kind": "skills", "path": source_name,
                                "scope": candidate["scope"], "workspace": workspace, "layout": "skill-package-root",
                                "restore_target": {"client": client_id, "scope": candidate["scope"], "workspace": workspace,
                                                   "source_root": candidate["path"],
                                                   "package_relative_path": package.relative_to(path).as_posix(),
                                                   "requires_path_mapping": True}}
                        if roots:
                            spec["linked_roots"] = roots
                        review["sources"].append(spec)
                    continue
                if linked(path):
                    entry["status"] = "symlink-source-requires-explicit-review"
                    continue
                if kind == "authored-automations":
                    entry["authored_sources"] = []
                    if not path.is_dir():
                        entry["status"] = "automation-root-not-directory"
                        continue
                    try:
                        for child in children(path):
                            if child.is_symlink() or not child.is_dir():
                                continue
                            authored = child / "automation.toml"
                            if (not authored.is_file() or authored.is_symlink()
                                    or authored.stat().st_size > MAX_FILE_SIZE):
                                continue
                            authored_name = path_name(authored, home)
                            if safe(authored_name) != authored_name:
                                entry["authored_sources"].append({"status": "unsafe-automation-source-metadata"})
                                continue
                            review["sources"].append({"id": source_id(authored, "text", workspace), "kind": "text", "path": authored_name,
                                                       "scope": candidate["scope"], "workspace": workspace,
                                                       "classification": "activation-bearing", "activation": "pending-agent-review"})
                            entry["authored_sources"].append({"path": authored_name, "status": "activation-bearing-pending-agent-review"})
                        entry["status"] = "authored-files-declared-not-activated"
                    except (OSError, ValueError, RuntimeError):
                        entry["status"] = "automation-enumeration-incomplete"
                    continue
                if kind in {"embedded-hooks", "management-state"}:
                    entry["status"] = "embedded-hooks-requires-field-reader" if kind == "embedded-hooks" else "management-state-requires-safe-field-adapter"
                    entry["next_action"] = "Review supported subobjects with a dedicated inert reader; never capture the shared file as text or activate settings."
                    continue
                base: dict[str, Any] = {"id": source_id(path, kind, workspace), "kind": kind, "path": name,
                                        "scope": candidate["scope"], "workspace": workspace}
                for metadata in ("classification", "activation", "layout"):
                    if metadata in candidate:
                        base[metadata] = candidate[metadata]
                if kind == "hooks":
                    review["sources"].append({**base, "format": candidate.get("format", "jsonc"),
                                              "fields": candidate.get("fields", ["hooks"]),
                                              "dependency_roots": candidate.get("dependency_roots", []),
                                              "classification": "activation-bearing", "activation": "pending-native-review"})
                    entry["status"] = "hook-fields-declared-for-inert-capture"
                    continue
                if kind == "mcp-sqlite":
                    found, database = sqlite_mcp(path)
                    entry.update(database)
                    for definition in found:
                        digest = hashlib.sha256((definition["sqlite_key"] + definition["container"]).encode()).hexdigest()[:12]
                        review["sources"].append({**base, **definition, "id": base["id"] + "-" + digest})
                    continue
                if kind in {"preferences", "mcp"}:
                    format_name = candidate.get("format", "toml" if candidate.get("container") == "mcp_servers" else "jsonc")
                    try:
                        document = read_document(path, format_name)
                    except ModuleNotFoundError:
                        entry["status"] = "missing-parser"
                        continue
                    except (OSError, ValueError, UnicodeError, TypeError):
                        entry["status"] = "unsupported-or-invalid-configuration-format"
                        continue
                    if kind == "mcp":
                        containers = [candidate["container"]] if candidate.get("container") else list(JSON_CONTAINERS)
                        found = [key for key in containers if isinstance(document.get(key), dict)]
                        entry["containers"] = found
                        if not found:
                            entry["status"] = "no-supported-mcp-container"
                            continue
                        for container in found:
                            review["sources"].append({**base, "id": base["id"] + "-" + container.lower().replace("_", "-"), "container": container})
                    else:
                        fields = [field for field in candidate.get("fields", []) if locate(document, field)[0]]
                        # Product-defined maps (such as model_providers) have
                        # user-chosen keys. Expand only reviewed leaf names;
                        # never copy an entire provider/shared configuration.
                        for selection in candidate.get("map_fields", []):
                            exists, mapping = locate(document, selection["path"])
                            if not exists or not isinstance(mapping, dict):
                                continue
                            for key in sorted(mapping):
                                for leaf in selection["fields"]:
                                    field = [*selection["path"], key, *leaf]
                                    if valid_review_fields([field]) and locate(document, field)[0] and field not in fields:
                                        fields.append(field)
                        records = [row for row in candidate.get("records", []) if locate(document, row["path"])[0]]
                        entry["present_field_paths"] = fields
                        entry["present_record_paths"] = [row["path"] for row in records]
                        if not fields and not records:
                            entry["status"] = "no-selected-preference-fields"
                            continue
                        review["sources"].append({**base, "format": format_name, **({"fields": fields} if fields else {}),
                                                  **({"records": records} if records else {})})
                elif kind == "text":
                    review["sources"].append(base)
                else:
                    entry["status"] = "unsupported-catalog-kind"
                    continue
                entry["status"] = "declared-not-captured"
    if any(overlaps(output.resolve(), source) for source in protected):
        raise ValueError("output-overlaps-source-or-workspace")
    if any(linked(parent) for parent in [output.parent]):
        raise ValueError("output-has-symbolic-link-parent")
    discovery["next_actions"] = [
        "Review source identities and exact linked_roots before exporting this draft; do not infer installation or native loading from existence.",
        "Run device-export with the discovered scope, then inspect exclusions and verify same-client discovery/runtime on the destination.",
        "Preserve unresolved sources as agent review tasks. The user supplies login, credentials, 2FA and native trust decisions.",
    ]
    discovery["inventory_fields_exported"] = ["client", "id", "enabled", "installed_from.id", "installed_from.marketplace", "installed_from.version", "publisher", "name", "version", "source"]
    discovery["configuration_values_exported"] = bool(scope["selected_plugin_inventory"] or scope["selected_extension_inventory"])
    discovery["configuration_value_policy"] = "Only identity and enabled-state inventory fields are exported by discovery; preference/MCP values remain delegated to the capture readers."
    output.mkdir(parents=True, mode=0o700)
    for name, payload in (("scope.json", scope), ("discovery.json", discovery)):
        data = (json.dumps(safe(payload), ensure_ascii=False, indent=2) + "\n").encode()
        scan_object_bytes(data, name)
        descriptor = os.open(output / name, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(descriptor, "wb") as writer:
            writer.write(data)
    return {"ok": True, "status": "scope-draft-created-not-captured", "selected_clients": selected,
            "scope": str(output / "scope.json"), "discovery": str(output / "discovery.json"),
            "source_unchanged": True, "review_sources": sum(len(row["sources"]) for row in scope["review"]["clients"])}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--clients", required=True, help="Comma-separated exact IDs: " + ",".join(CLIENTS))
    parser.add_argument("--workspace", action="append", default=[], metavar="ID=PATH")
    parser.add_argument("--scopes", default="user", help="User configuration by default; project/local require explicit selection")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        workspaces = []
        for value in args.workspace:
            name, separator, raw_path = value.partition("=")
            if not separator:
                raise ValueError("workspace-requires-id-and-path")
            identifier(name)
            path = Path(raw_path).expanduser().absolute()
            if (not path.is_dir() or any(row["id"] == name for row in workspaces)
                    or safe(str(path)) != str(path) or safe(name) != name):
                raise ValueError("invalid-or-duplicate-workspace")
            workspaces.append({"id": name, "path": str(path)})
        result = discover(args.clients.split(","), workspaces, set(args.scopes.split(",")), args.output)
    except (OSError, ValueError, RuntimeError, ACBError) as error:
        result = {"ok": False, "status": "discovery-incomplete", "error_type": type(error).__name__}
    print(json.dumps(safe(result), ensure_ascii=False))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
