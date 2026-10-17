"""Collect selected hook definitions and inert, explicitly bounded dependencies.

Nothing is installed, enabled, executed, or written here. The result is review
material; native trust and activation must be established on the destination.
"""
from __future__ import annotations

import hashlib
import json
import re
import shlex
import stat
from pathlib import Path
from typing import Any

from acb.bundle import ACBSecretLeak, MAX_FILE_SIZE, MAX_TOTAL_SIZE, scan_object_bytes
from acb.preferences import _decode_preferences

_SCRIPT_SUFFIXES = {".py", ".sh", ".js", ".mjs", ".cjs", ".rb", ".pl"}
_MANAGEMENT = {
    "state", "trust", "trusted", "trustedhash", "trustedhashes", "truststate",
    "approval", "approvals", "approvalstate", "permission", "permissions",
    "permissionstate", "account", "accounts", "auth", "authentication",
    "authorization", "credentials", "token", "tokens", "secret", "password",
}
_DYNAMIC = re.compile(r"\$|`|\*|\?|\[|\]|[<>]|\x00")
_BINARY_SUFFIXES = {".app", ".node", ".dylib", ".so", ".dll", ".exe"}
_MAGIC = (b"\x7fELF", b"MZ", b"\xfe\xed\xfa\xce", b"\xfe\xed\xfa\xcf",
          b"\xce\xfa\xed\xfe", b"\xcf\xfa\xed\xfe", b"\xca\xfe\xba\xbe")


def _management_key(key: str) -> bool:
    normalized = re.sub(r"[^a-z0-9]", "", key.lower())
    # PermissionRequest is a documented event name, unlike permission policy
    # and trust/account/auth bookkeeping embedded beside event definitions.
    if normalized == "permissionrequest":
        return False
    return normalized in _MANAGEMENT or normalized.startswith(
        ("trust", "approval", "permission", "account", "auth", "credential"))


def _has_symlink(path: Path) -> bool:
    return any(item.is_symlink() for item in (path, *path.parents))


def collect_hook_review(path: Path, source: dict) -> tuple[dict[str, bytes], list[dict]]:
    """Return inert payload bytes and stable, non-secret-bearing review tasks."""
    files: dict[str, bytes] = {}
    tasks: list[dict] = []
    fields: list[dict] = []
    dependencies: list[dict] = []

    def task(reason: str, field: list[str] | None = None, **extra: Any) -> None:
        entry: dict[str, Any] = {"status": "pending-agent-review", "reason": reason}
        if field is not None:
            entry["path"] = field
        entry.update(extra)
        tasks.append(entry)

    def finish() -> tuple[dict[str, bytes], list[dict]]:
        payload = {"schema_version": 1, "review_only": True, "fields": fields,
                   "dependencies": dependencies, "activation": "pending-native-review"}
        files["hooks-review.json"] = (json.dumps(payload, ensure_ascii=False,
            sort_keys=True, indent=2, allow_nan=False) + "\n").encode("utf-8")
        return files, tasks

    selected = source.get("fields")
    if (not isinstance(selected, list) or not selected
            or any(not isinstance(item, str) or item not in {"hooks", "notify"} for item in selected)
            or len(set(selected)) != len(selected)):
        task("invalid-hook-review-fields")
        return finish()
    format_name = source.get("format", "")
    if format_name not in {"json", "jsonc", "toml"}:
        task("unsupported-hook-review-format")
        return finish()
    try:
        if _has_symlink(path) or not path.is_file() or path.stat().st_size > MAX_FILE_SIZE:
            task("hook-source-not-regular-or-too-large")
            return finish()
        document = _decode_preferences(path.read_bytes(), format_name)
    except ModuleNotFoundError:
        task("tomllib-unavailable")
        return finish()
    except (OSError, ValueError, UnicodeError, RecursionError):
        task("hook-source-unreadable-or-invalid")
        return finish()

    def prune(value: Any, location: list[str], depth: int = 0) -> Any:
        if depth > 32:
            raise ValueError("too-deep")
        if isinstance(value, dict):
            cleaned: dict[str, Any] = {}
            for key, item in value.items():
                if _management_key(key):
                    task("hook-management-state-excluded", location + [key])
                else:
                    cleaned[key] = prune(item, location + [key], depth + 1)
            return cleaned
        if isinstance(value, list):
            if len(value) > 10000:
                raise ValueError("too-many-items")
            return [prune(item, location + [str(index)], depth + 1)
                    for index, item in enumerate(value)]
        if isinstance(value, str):
            # Scan unescaped command strings too; JSON escaping must not hide
            # assignments such as API_KEY="literal" from the shared scanner.
            scan_object_bytes(value.encode("utf-8"), "hook-command.txt")
            return value
        if value is None or isinstance(value, (bool, int, float)):
            return value
        raise ValueError("unsupported-value")

    for name in selected:
        if name not in document:
            task("hook-field-not-present", [name])
            continue
        try:
            cleaned = prune(document[name], [name])
            if name == "hooks" and not isinstance(cleaned, (dict, list)):
                raise ValueError("invalid-hooks")
            if name == "notify" and not (isinstance(cleaned, str) or (
                    isinstance(cleaned, list) and all(isinstance(item, str) for item in cleaned))):
                raise ValueError("invalid-notify")
            candidate = {"path": [name], "value": cleaned}
            scan_object_bytes(json.dumps(candidate, ensure_ascii=False, allow_nan=False).encode(), "hooks-review.json")
        except ACBSecretLeak:
            task("hook-field-secret-rejected", [name])
            continue
        except (ValueError, TypeError, RecursionError):
            task("hook-field-invalid", [name])
            continue
        fields.append(candidate)

    roots: list[Path] = []
    root_values = source.get("dependency_roots", [])
    if not isinstance(root_values, list):
        task("invalid-hook-dependency-roots")
        root_values = []
    for raw in root_values:
        try:
            if not isinstance(raw, str) or _DYNAMIC.search(raw):
                raise ValueError("unsafe-root")
            candidate = Path(raw).expanduser()
            if not candidate.is_absolute() or _has_symlink(candidate) or not candidate.is_dir():
                raise ValueError("unsafe-root")
            roots.append(candidate)
        except (OSError, ValueError, RuntimeError):
            task("invalid-hook-dependency-root")

    references: dict[str, None] = {}

    def words(text: str, depth: int = 0) -> None:
        if depth > 16:
            task("hook-command-static-parse-failed")
            return
        try:
            tokens = shlex.split(text, posix=True)
        except ValueError:
            task("hook-command-static-parse-failed")
            return
        for token in tokens:
            if _DYNAMIC.search(token):
                task("hook-dynamic-reference-needs-review")
                continue
            # Also handle literal --script=/absolute/path arguments. Neither
            # bare interpreter names nor ordinary flags identify local files.
            possible = token.split("=", 1)[1] if "=" in token else token
            if possible.startswith(("/", "~/")):
                references[possible] = None
            elif " " in possible and ("/" in possible or "~" in possible):
                # sh -c / quoted command strings are parsed as inert text.
                words(possible, depth + 1)
            elif (not possible.startswith("-") and "://" not in possible
                    and ("/" in possible or Path(possible).suffix.lower() in _SCRIPT_SUFFIXES)):
                # Resolving against this process's cwd would silently bind a
                # different script on the new machine. Keep the unresolved
                # dependency explicit so review cannot activate it by accident.
                task("hook-relative-reference-needs-review")

    def commands(value: Any, command_context: bool = False) -> None:
        if isinstance(value, dict):
            for key, item in value.items():
                commands(item, key in {"command", "args", "argv", "notify"})
        elif isinstance(value, list):
            for item in value:
                if command_context and isinstance(item, str) and item.startswith(("/", "~/")):
                    if _DYNAMIC.search(item):
                        task("hook-dynamic-reference-needs-review")
                    else:
                        references[item] = None
                else:
                    commands(item, command_context)
        elif command_context and isinstance(value, str):
            words(value)

    for field in fields:
        commands(field["value"], field["path"] == ["notify"])
    total = 0
    for raw in references:
        try:
            candidate = Path(raw).expanduser()
            if not candidate.is_absolute():
                raise ValueError("non-absolute")
            record: dict[str, Any] = {"source_path": str(candidate), "reference": raw}
            dependencies.append(record)
            if len(dependencies) > 128:
                record["status"] = "dependency-count-limit"
            elif _has_symlink(candidate):
                record["status"] = "dependency-symlink-not-captured"
            elif candidate.suffix.lower() in _BINARY_SUFFIXES or any(
                    part.lower().endswith(".app") for part in candidate.parts):
                record["status"] = "external-native-binary-not-captured"
            elif not candidate.exists():
                record["status"] = "dependency-not-present"
            elif not candidate.is_file():
                record["status"] = "dependency-not-regular-file"
            elif not roots or not any(candidate.is_relative_to(root) for root in roots):
                record["status"] = "dependency-outside-explicit-roots"
            elif candidate.stat().st_size > MAX_FILE_SIZE:
                record["status"] = "dependency-file-too-large"
            else:
                with candidate.open("rb") as stream:
                    data = stream.read(MAX_FILE_SIZE + 1)
                if len(data) > MAX_FILE_SIZE:
                    record["status"] = "dependency-file-too-large"
                elif data.startswith(_MAGIC) or b"\0" in data:
                    record["status"] = "external-native-binary-not-captured"
                elif candidate.suffix.lower() not in _SCRIPT_SUFFIXES:
                    record["status"] = "dependency-script-type-not-allowlisted"
                elif total + len(data) > MAX_TOTAL_SIZE:
                    record["status"] = "dependency-total-size-limit"
                else:
                    try:
                        data.decode("utf-8")
                        scan_object_bytes(data, candidate.name)
                    except (UnicodeError, ACBSecretLeak):
                        record["status"] = "dependency-secret-or-nontext-rejected"
                    else:
                        digest = hashlib.sha256(data).hexdigest()
                        relative = "dependencies/" + hashlib.sha256(str(candidate).encode()).hexdigest()[:20] + "/" + candidate.name
                        files[relative] = data
                        total += len(data)
                        record.update(status="captured-review-only", sha256=digest,
                                      mode=stat.S_IMODE(candidate.stat().st_mode) & 0o777,
                                      payload_path=relative)
            if record.get("status") != "captured-review-only":
                task(record["status"], source_path=str(candidate))
        except (OSError, ValueError, RuntimeError):
            task("dependency-unreadable-or-unsafe")
    return finish()
