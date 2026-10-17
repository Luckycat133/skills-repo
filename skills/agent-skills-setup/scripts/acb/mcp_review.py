"""Extract redacted MCP definitions as inert material for manual native rebuild.

The automatic MCP adapters deliberately cover fewer formats/transports. This
reader does not broaden their writers or copy shared configuration siblings.
"""

from __future__ import annotations

import hashlib
import importlib
import json
import os
import re
import stat
import urllib.parse
from pathlib import Path
from typing import Any

from acb import bundle
from acb.review import _canonical, _segment
from migration_core import (
    LossReport, _safe_args, _safe_secret_value, _safe_url, _strip_jsonc,
    ensure_no_symlink_components,
)

_STRING_FIELDS = frozenset({"command", "cwd", "type", "transport"})
_LIST_FIELDS = frozenset({
    "env_vars", "enabled_tools", "disabled_tools", "allowed_tools", "denied_tools",
    "includeTools", "excludeTools", "tools",
})
_BOOL_FIELDS = frozenset({
    "enabled", "disabled", "required", "defer_loading", "auto_start", "enabled_by_default",
})
_NUMBER_FIELDS = frozenset({
    "timeout", "timeout_ms", "timeoutMs", "startup_timeout_sec", "startup_timeout_ms",
    "tool_timeout_sec", "tool_timeout_ms", "connectionTimeout", "requestTimeout",
})
_MAP_FIELDS = frozenset({"env", "headers", "http_headers"})
_ENV_MAP_FIELDS = frozenset({"env_http_headers", "env_headers"})
_ENV_NAME = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
_FIELD_NAME = re.compile(r"^[A-Za-z][A-Za-z0-9_.-]{0,149}$")
_ENV_FIELD = re.compile(r"^[A-Za-z][A-Za-z0-9_]*_env_var$")
_PLACEHOLDER_NAME = re.compile(r"\$\{(?:env:)?([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Z][A-Z0-9_]*)")
_REVIEW_REFERENCE = re.compile(
    r"^(?P<bearer>bearer\s+)?(?:\$(?P<plain>[A-Za-z_][A-Za-z0-9_]*)"
    r"|\$\{(?:env:)?(?P<braced>[A-Za-z_][A-Za-z0-9_]*)\})$", re.IGNORECASE,
)


def _label(value: str) -> str:
    """Names are metadata too: never echo a credential-looking name."""
    try:
        bundle.scan_object_bytes(value.encode("utf-8"), "metadata.txt")
        if len(value) <= 150 and _FIELD_NAME.fullmatch(value):
            return value
    except bundle.ACBSecretLeak:
        pass
    return "item-" + hashlib.sha256(value.encode("utf-8")).hexdigest()[:16]


def _reference_name(value: str) -> str:
    normalized = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", _label(value))
    normalized = re.sub(r"[^A-Za-z0-9_]", "_", normalized).upper()
    return normalized if _ENV_NAME.fullmatch(normalized) else "MCP_VALUE_" + hashlib.sha256(value.encode()).hexdigest()[:12].upper()


def _safe_review_value(name: str, value: str) -> tuple[str, bool]:
    """Retain explicit variable references; replace every literal map value.

    Header/env names are open-ended. Their values cannot safely be classified
    by a token-shaped regex or a finite list of credential field spellings.
    """
    sanitized, redacted = _safe_secret_value(name, value)
    reference = _REVIEW_REFERENCE.fullmatch(value)
    if reference:
        variable = reference.group("plain") or reference.group("braced")
        normalized = ("Bearer " if reference.group("bearer") else "") + "${" + variable + "}"
        return normalized, normalized != value
    if redacted:
        return sanitized, True
    return "${" + _reference_name(name) + "}", True


def _safe_review_url(value: str, name: str, report: LossReport) -> tuple[str, list[str], list[str]]:
    """Remove userinfo and all query values, retaining names for reconstruction.

    Arbitrary providers can put authentication under authToken, sig or an
    unknown parameter. The review copy never assumes a query value is public.
    """
    sanitized = _safe_url(value, name, report)
    parsed = urllib.parse.urlsplit(sanitized)
    credentials = set()
    if parsed.username is not None or parsed.password is not None:
        credentials.update({"MCP_USER", "MCP_PASSWORD"})
    query_fields = []
    for field, item in urllib.parse.parse_qsl(parsed.query, keep_blank_values=True):
        query_fields.append(_label(field))
        credentials.add(_reference_name(field))
        for match in _PLACEHOLDER_NAME.finditer(item):
            credentials.add(match.group(1) or match.group(2))
    result = urllib.parse.urlunsplit((
        parsed.scheme, parsed.netloc.rsplit("@", 1)[-1], parsed.path, "", parsed.fragment,
    ))
    return result, sorted(set(query_fields)), sorted(credentials)


def _decode(data: bytes, source_format: str) -> dict[str, Any]:
    family, _, container = source_format.partition(":")
    if family in {"json", "jsonc"} and container in {"mcpServers", "servers", "mcp"}:
        text = data.decode("utf-8")
        value = json.loads(_strip_jsonc(text) if family == "jsonc" else text)
    elif source_format == "toml:mcp_servers":
        # Import lazily so JSON remains supported on Python < 3.11. No parser
        # installation or unofficial TOML fallback is attempted.
        value = importlib.import_module("tomllib").loads(data.decode("utf-8"))
    else:
        raise NotImplementedError("unsupported-format")
    if not isinstance(value, dict) or not isinstance(value.get(container), dict):
        raise ValueError("missing-server-map")
    return value[container]


def _redact_server(name: str, raw: dict[str, Any]) -> dict[str, Any]:
    command = raw.get("command")
    urls = [key for key in ("url", "httpUrl") if key in raw]
    if command is not None and not isinstance(command, str):
        raise ValueError("invalid-command")
    if not command and not urls:
        raise ValueError("missing-command-or-url")
    if command and urls:
        raise ValueError("ambiguous-transport")
    if any(not isinstance(raw[key], str) for key in urls):
        raise ValueError("invalid-url")
    report = LossReport()
    definition: dict[str, Any] = {}
    omitted: list[str] = []
    credentials: set[str] = set()

    def references(value: str) -> None:
        for match in _PLACEHOLDER_NAME.finditer(urllib.parse.unquote(value)):
            credentials.add(match.group(1) or match.group(2))

    for key, value in raw.items():
        if not isinstance(key, str):
            raise ValueError("invalid-field-name")
        if key in _STRING_FIELDS and isinstance(value, str):
            definition[key] = value
        elif key == "args" and isinstance(value, list) and all(isinstance(arg, str) for arg in value):
            definition[key] = _safe_args(value, name, report)
            for argument in definition[key]:
                references(argument)
        elif key in {"url", "httpUrl"} and isinstance(value, str):
            sanitized, query_fields, query_credentials = _safe_review_url(value, name, report)
            definition[key] = sanitized
            omitted.extend(f"{key}.query.{field}" for field in query_fields)
            credentials.update(query_credentials)
            references(sanitized)
        elif key in _MAP_FIELDS and isinstance(value, dict) and all(
            isinstance(item_key, str) and isinstance(item_value, str)
            for item_key, item_value in value.items()
        ):
            safe_map = {}
            for item_key, item_value in value.items():
                safe_value, redacted = _safe_review_value(item_key, item_value)
                safe_map[item_key] = safe_value
                references(safe_value)
                if redacted:
                    report.add("mcp", f"{key}.{_label(item_key)}", "literal secret removed", None)
            definition[key] = safe_map
        elif key in _ENV_MAP_FIELDS and isinstance(value, dict) and all(
            isinstance(item_key, str) and isinstance(item_value, str) and _ENV_NAME.fullmatch(item_value)
            for item_key, item_value in value.items()
        ):
            definition[key] = value
            credentials.update(value.values())
        elif _ENV_FIELD.fullmatch(key) and isinstance(value, str) and _ENV_NAME.fullmatch(value):
            definition[key] = value
            credentials.add(value)
        elif key in _LIST_FIELDS and isinstance(value, list) and all(isinstance(item, str) for item in value):
            definition[key] = value
            if key == "env_vars":
                if not all(_ENV_NAME.fullmatch(item) for item in value):
                    raise ValueError("invalid-environment-name")
                credentials.update(value)
        elif key in _BOOL_FIELDS and type(value) is bool:
            definition[key] = value
        elif key in _NUMBER_FIELDS and type(value) in {int, float} and 0 <= value <= 2147483647:
            definition[key] = value
        else:
            # Never serialize an unknown field's value, even for apparently
            # harmless nested provider/account/trust objects.
            omitted.append(_label(key))
    payload = {
        "schema_version": 1, "server_name": name, "definition": definition,
        "automatic_restore": False, "status": "manual-rebuild",
        "omitted_fields": sorted(omitted), "required_credentials": sorted(credentials),
        "redacted_fields": sorted({_label(item.field) for item in report.items}),
        "paths_need_remapping": True,
        "path_note": "Command, cwd and argument paths are source data and have not been rewritten; remap them on the destination before use.",
        "value_note": "Literal environment/header values and all URL query values were omitted. The agent reconstructs non-secret values locally; the user supplies credentials through native authentication or environment variables.",
    }
    # This catches credentials in commands, cwd, server names, malformed
    # references and any retained field the explicit redactors did not cover.
    bundle.scan_object_bytes(_encode(payload), "mcp-review.json")
    return payload


def _encode(payload: dict[str, Any]) -> bytes:
    return (json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True, allow_nan=False) + "\n").encode("utf-8")


def collect_mcp_review(
    rows: list[dict], *, selected_profiles: set[str], scopes: set[str]
) -> tuple[dict[str, bytes], list[dict], dict[str, list[str]], list[dict]]:
    """Return inert redacted definitions, grouped review manifests and tasks."""
    files: dict[str, bytes] = {}
    manifests: dict[str, dict] = {}
    mapping: dict[str, list[str]] = {}
    tasks: list[dict] = []
    total_size = 0
    examined = 0
    seen: set[tuple[str, str, str]] = set()
    for row in rows:
        product, profile, scope = (str(row.get(key) or "") for key in ("product", "profile", "scope"))
        if (row.get("object_type") != "mcp" or f"{product}/{profile}" not in selected_profiles
                or scope not in scopes):
            continue
        canonical = _canonical(row)
        group = "/".join(("review", _segment(product), _segment(profile), _segment(scope)))
        base = {
            "product": product, "profile": profile, "scope": scope, "object_type": "mcp",
            "canonical_path": canonical, "status": "manual-rebuild", "automatic_restore": False,
            "next_action": "The destination agent must review these definitions, install required runtimes and scripts, remap old paths, and recreate same-product native MCP configuration. The user must authenticate or supply credentials locally when needed. Verify native discovery and an actual tool request separately; do not execute backup commands automatically.",
        }

        def record(reason: str, *, name: str = "", payload: str = "", credentials: list[str] | None = None, omitted: list[str] | None = None) -> None:
            task = {**base, "reason": reason, "payload_path": payload}
            if name:
                task["server_name"] = _label(name)
            if credentials is not None:
                task["required_credentials"] = credentials
            if omitted is not None:
                task["omitted_fields"] = omitted
            tasks.append(task)

        source_format = row.get("source_format") or row.get("format") or ""
        family, _, container = source_format.partition(":")
        if source_format != "toml:mcp_servers" and not (
            family in {"json", "jsonc"} and container in {"mcpServers", "servers", "mcp"}
        ):
            record("unhandled-format")
            continue
        if row.get("policy") in bundle.FORBIDDEN_SNAPSHOT_POLICIES or row.get("storage") not in {"file", "config-subobject"}:
            record("excluded-by-policy-or-storage")
            continue
        resolved, boundary = row.get("resolved_path"), row.get("boundary")
        if not resolved or not boundary:
            record("source-unavailable")
            continue
        source = Path(resolved)
        identity = (group, str(source), source_format)
        if identity in seen:
            continue
        seen.add(identity)
        try:
            source.relative_to(Path(boundary))
            if source.is_symlink():
                record("symlink-not-captured")
                continue
            ensure_no_symlink_components(source, Path(boundary))
            descriptor = os.open(source, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0))
            with os.fdopen(descriptor, "rb") as reader:
                info = os.fstat(reader.fileno())
                if not stat.S_ISREG(info.st_mode):
                    record("nonregular-file-not-captured")
                    continue
                if info.st_size > bundle.MAX_FILE_SIZE:
                    record("file-size-limit")
                    continue
                data = reader.read(bundle.MAX_FILE_SIZE + 1)
            if len(data) > bundle.MAX_FILE_SIZE:
                record("file-size-limit")
                continue
            servers = _decode(data, source_format)
        except ModuleNotFoundError:
            record("missing-tomllib-parser")
            continue
        except FileNotFoundError:
            record("source-missing")
            continue
        except OSError:
            record("source-unreadable")
            continue
        except (ValueError, TypeError, NotImplementedError, RecursionError):
            record("source-invalid-or-symlink")
            continue
        if not servers:
            record("server-map-empty")
            continue
        source_tag = hashlib.sha256((canonical + "\0" + str(source)).encode()).hexdigest()[:16]
        for name, raw in servers.items():
            if examined >= bundle.MAX_BUNDLE_FILES:
                record("server-count-limit")
                break
            examined += 1
            if not isinstance(name, str) or not isinstance(raw, dict):
                record("invalid-server-definition", name=name if isinstance(name, str) else "")
                continue
            server_tag = hashlib.sha256(name.encode()).hexdigest()[:16]
            destination = f"{group}/mcp/{source_tag}/{server_tag}.json"
            if len(Path(destination).parts) > bundle.MAX_DIR_DEPTH:
                record("directory-depth-limit", name=name)
                continue
            try:
                payload = _redact_server(name, raw)
                payload["source_format"] = source_format
                encoded = _encode(payload)
                bundle.scan_object_bytes(encoded, destination)
            except bundle.ACBSecretLeak:
                record("server-secret-not-captured", name=name)
                continue
            except (ValueError, TypeError, OverflowError, RecursionError):
                record("invalid-server-definition", name=name)
                continue
            if len(encoded) > bundle.MAX_FILE_SIZE or total_size + len(encoded) > bundle.MAX_TOTAL_SIZE:
                record("payload-size-limit", name=name)
                continue
            files[destination] = encoded
            total_size += len(encoded)
            mapping.setdefault(group, []).append(destination)
            manifests.setdefault(group, {
                "surface": "review", "object_type": "review", "product": product,
                "profile": profile, "scope": scope, "status": "manual-rebuild",
                "source_format": "inert-reviewed-text", "automatic_restore": False,
            })
            record("mcp-review-definition-captured", name=name, payload=f"objects/{destination}",
                   credentials=payload["required_credentials"], omitted=payload["omitted_fields"])
    return files, list(manifests.values()), mapping, tasks
