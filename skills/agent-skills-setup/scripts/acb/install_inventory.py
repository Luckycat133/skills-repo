"""Collect bounded installation identities as inert, selected scalar records.

This reader never installs anything or writes native configuration. Wildcards
are local to inventory selection, not the general migration/restore language.
"""

from __future__ import annotations

import importlib
import json
import math
import os
import re
import stat
from pathlib import Path
from typing import Any

from acb.bundle import ACBSecretLeak, MAX_FILE_SIZE, scan_object_bytes
from acb.mcp_review import _safe_review_url
from migration_core import LossReport, _strip_jsonc

MAX_SELECTORS = 128
MAX_RECORDS = 4096
MAX_STEPS = 65536
MAX_DEPTH = 32
_URL = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*://")
_SECRET_FIELD = re.compile(r"(?i)^(?:token|secret|password|passwd|authorization|api[_-]?key|client[_-]?secret|private[_-]?key)$")


def _encode(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2,
                       allow_nan=False) + "\n").encode("utf-8")


def collect_install_inventory(
    path: Path, source: dict[str, Any]
) -> tuple[dict[str, bytes], list[dict[str, Any]]]:
    """Return ``install-inventory.json`` and secret-free stable omission tasks."""
    tasks: list[dict[str, Any]] = []

    def task(reason: str, selector: int | None = None) -> None:
        item: dict[str, Any] = {"reason": reason, "inventory_only": True,
                                "native_installation": "not-run"}
        if selector is not None:
            item["selector_index"] = selector
        if item not in tasks:
            tasks.append(item)

    def safe_text(value: str, *, url: bool = False) -> str:
        if len(value) > 4096 or any(ord(char) < 32 for char in value):
            raise ValueError("unsafe-inventory-scalar")
        original = value
        if _URL.match(value):
            value, _, _ = _safe_review_url(value, "installation", LossReport())
            # A fragment is not needed for installation identity and may carry
            # credentials even when its name is not recognizable.
            value = value.split("#", 1)[0]
        elif url and ("?" in value or "@" in value and ":" in value):
            raise ValueError("invalid-inventory-url")
        scan_object_bytes(_encode({"identity": value}), "installation-scalar.json")
        if original != value:
            task("installation-url-redacted")
        return value

    def valid_path(value: Any, *, wildcard: bool) -> bool:
        return (isinstance(value, list) and (0 if wildcard else 1) <= len(value) <= MAX_DEPTH
                and all((isinstance(part, str) and 0 < len(part) <= 4096
                         and (wildcard or part != "*")
                         and not _SECRET_FIELD.fullmatch(part))
                        or (type(part) is int and 0 <= part <= MAX_RECORDS)
                        for part in value))

    selectors = source.get("selectors") if isinstance(source, dict) else None
    if (not isinstance(selectors, list) or not 0 < len(selectors) <= MAX_SELECTORS
            or any(not isinstance(item, dict)
                   or not valid_path(item.get("path"), wildcard=True)
                   or not isinstance(item.get("fields"), list)
                   or not 0 < len(item["fields"]) <= MAX_SELECTORS
                   or any(not valid_path(field, wildcard=False) for field in item["fields"])
                   for item in selectors)):
        task("invalid-installation-selectors")
        return {}, tasks
    try:
        for item in selectors:
            for parts in [item["path"]] + item["fields"]:
                for part in parts:
                    if isinstance(part, str) and part != "*":
                        safe_text(part)
        flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0)
        if path.is_symlink():
            raise ValueError("unsafe-source")
        descriptor = os.open(path, flags)
        with os.fdopen(descriptor, "rb") as reader:
            before = os.fstat(reader.fileno())
            if not stat.S_ISREG(before.st_mode) or before.st_size > MAX_FILE_SIZE:
                task("installation-source-not-regular-or-too-large")
                return {}, tasks
            raw = reader.read(MAX_FILE_SIZE + 1)
            after = os.fstat(reader.fileno())
        if len(raw) > MAX_FILE_SIZE:
            task("installation-source-too-large")
            return {}, tasks
        if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
            task("installation-source-changed-during-read")
            return {}, tasks
        family = source.get("format")
        text = raw.decode("utf-8")
        if family == "toml":
            document = importlib.import_module("tomllib").loads(text)
        elif family in {"json", "jsonc"}:
            document = json.loads(_strip_jsonc(text) if family == "jsonc" else text)
        else:
            task("unsupported-installation-format")
            return {}, tasks
        if not isinstance(document, (dict, list)):
            raise ValueError("invalid-root")
    except ModuleNotFoundError:
        task("tomllib-unavailable")
        return {}, tasks
    except (OSError, ValueError, UnicodeError, RecursionError, ACBSecretLeak):
        task("installation-source-unreadable-unsafe-or-invalid")
        return {}, tasks

    records: dict[tuple[Any, ...], dict[str, Any]] = {}
    steps = 0

    def traverse(value: Any, parts: list[Any], actual: list[Any]):
        nonlocal steps
        steps += 1
        if steps > MAX_STEPS:
            raise OverflowError
        if not parts:
            yield actual, value
            return
        part = parts[0]
        if part == "*":
            if not isinstance(value, (dict, list)):
                raise TypeError
            if len(value) > MAX_RECORDS:
                raise OverflowError
            iterable = value.items() if isinstance(value, dict) else enumerate(value)
            for key, child in iterable:
                try:
                    safe_key = safe_text(key) if isinstance(key, str) else key
                except (ValueError, ACBSecretLeak):
                    task("unsafe-installation-map-key")
                    continue
                try:
                    yield from traverse(child, parts[1:], actual + [safe_key])
                except TypeError:
                    task("installation-selector-path-not-present-or-container")
        elif isinstance(value, dict) and part in value:
            safe_part = safe_text(part) if isinstance(part, str) else part
            yield from traverse(value[part], parts[1:], actual + [safe_part])
        elif isinstance(value, list) and type(part) is int and part < len(value):
            yield from traverse(value[part], parts[1:], actual + [part])
        else:
            raise TypeError

    for index, selector in enumerate(selectors):
        try:
            for actual, selected in traverse(document, selector["path"], []):
                key = tuple(actual)
                if key not in records and len(records) >= MAX_RECORDS:
                    raise OverflowError
                fields = records.get(key, {"source_path": actual, "fields": []})
                for leaf in selector["fields"]:
                    steps += 1
                    if steps > MAX_STEPS:
                        raise OverflowError
                    value = selected
                    try:
                        for component in leaf:
                            if isinstance(value, dict) and component in value:
                                value = value[component]
                            elif isinstance(value, list) and type(component) is int:
                                value = value[component]
                            else:
                                raise KeyError
                        if (type(value) not in (str, bool, int, float)
                                or isinstance(value, float) and not math.isfinite(value)):
                            task("installation-field-not-finite-scalar", index)
                            continue
                        safe_leaf = [safe_text(p) if isinstance(p, str) else p for p in leaf]
                        if isinstance(value, str):
                            value = safe_text(value, url=str(leaf[-1]).lower() in {"url", "registry"})
                        item = {"path": safe_leaf, "value": value}
                        scan_object_bytes(_encode(item), "installation-field.json")
                        if item not in fields["fields"]:
                            fields["fields"].append(item)
                    except (KeyError, IndexError, TypeError):
                        task("installation-field-not-present", index)
                    except (ValueError, ACBSecretLeak):
                        task("unsafe-installation-field", index)
                if fields["fields"]:
                    records[key] = fields
        except TypeError:
            task("installation-selector-path-not-present-or-container", index)
        except (ValueError, ACBSecretLeak):
            task("unsafe-installation-selector", index)
        except OverflowError:
            task("installation-inventory-limit-exceeded")
            return {}, tasks
    if not records:
        task("no-safe-installation-records")
        return {}, tasks
    try:
        payload = _encode({"schema_version": 1, "inventory_only": True,
                           "native_installation": "not-run", "records": list(records.values())})
        if len(payload) > MAX_FILE_SIZE:
            task("installation-inventory-limit-exceeded")
            return {}, tasks
        scan_object_bytes(payload, "install-inventory.json")
    except (ValueError, ACBSecretLeak):
        task("unsafe-installation-inventory")
        return {}, tasks
    return {"install-inventory.json": payload}, tasks
