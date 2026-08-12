#!/usr/bin/env python3
"""Typed migration core for instructions, Agent Skills, and MCP profiles."""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import tempfile
import urllib.parse
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SENSITIVE_NAME = re.compile(
    r"(?:^|[_-])(token|secret|password|passwd|api[_-]?key|authorization|cookie)(?:$|[_-])",
    re.IGNORECASE,
)
PLACEHOLDER = re.compile(r"^(?:\$\{[^}]+\}|\$[A-Za-z_][A-Za-z0-9_]*|<[^>]+>)$")
URL_CREDENTIAL = re.compile(r"(?i)://[^/?#\s]+:[^/@\s]+@")
BEARER_LITERAL = re.compile(r"(?i)\bbearer\s+(?!\$\{|<)[A-Za-z0-9._~+/=-]{8,}")
SAFE_BEARER_REFERENCE = re.compile(
    r"(?i)^bearer\s+\$\{(?:env:)?[A-Za-z_][A-Za-z0-9_]*\}$"
)
FRONTMATTER = re.compile(r"\A---\s*\n(.*?)\n---\s*\n?", re.DOTALL)
KNOWN_COMMANDS = {"detect", "inventory", "plan", "apply", "verify", "rollback"}


@dataclass
class InstructionIR:
    text: str
    scope: str = "project"
    activation: str = "always"
    globs: list[str] = field(default_factory=list)
    priority: int = 0
    hierarchy: str = "flat"
    imports: list[str] = field(default_factory=list)
    source_format: str = "plain-markdown"


@dataclass
class MCPServerIR:
    name: str
    transport: str = "stdio"
    command: str | None = None
    args: list[str] = field(default_factory=list)
    env: dict[str, str] = field(default_factory=dict)
    url: str | None = None
    headers: dict[str, str] = field(default_factory=dict)
    source_format: str = "json:mcpServers"


@dataclass
class LossItem:
    object_type: str
    field: str
    reason: str
    value: Any = None


@dataclass
class LossReport:
    items: list[LossItem] = field(default_factory=list)

    @property
    def lossy(self) -> bool:
        return bool(self.items)

    def add(self, object_type: str, field_name: str, reason: str, value: Any) -> None:
        self.items.append(LossItem(object_type, field_name, reason, value))

    def to_dict(self) -> dict[str, Any]:
        return {"lossy": self.lossy, "items": [asdict(item) for item in self.items]}


@dataclass
class SurfacePath:
    product: str
    profile: str
    object_type: str
    scope: str
    storage: str
    path: str
    resolved_path: Path
    boundary: Path
    source_format: str
    policy: str

    def to_dict(self) -> dict[str, Any]:
        value = asdict(self)
        value["resolved_path"] = str(self.resolved_path)
        value["boundary"] = str(self.boundary)
        return value


@dataclass
class PlanItem:
    object_type: str
    status: str
    reason: str
    source: SurfacePath | None = None
    target: SurfacePath | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "object_type": self.object_type,
            "status": self.status,
            "reason": self.reason,
            "source": self.source.to_dict() if self.source else None,
            "target": self.target.to_dict() if self.target else None,
        }


class Registry:
    """Resolve registry v2 products, profiles, and concrete surface paths."""

    def __init__(self, path: Path, workspace: Path, home: Path | None = None) -> None:
        self.path = path
        self.workspace = workspace.resolve()
        self.home = (home or Path.home()).resolve()
        self.data = json.loads(path.read_text(encoding="utf-8"))
        if self.data.get("schema_version") != 2:
            raise ValueError("registry schema_version must be 2")

    @property
    def products(self) -> dict[str, Any]:
        return self.data["products"]

    def split_selector(self, selector: str) -> tuple[str, str | None]:
        product_id, separator, profile_id = selector.partition("/")
        if product_id not in self.products:
            raise ValueError(f"unknown product: {product_id}")
        return product_id, profile_id if separator else None

    def profile(self, selector: str) -> tuple[str, str, dict[str, Any]]:
        product_id, requested_profile = self.split_selector(selector)
        product = self.products[product_id]
        template_id = product.get("template")
        if template_id:
            template = dict(self.data["profile_templates"][template_id])
            profile_id = str(template.get("profile", template_id))
            if requested_profile and requested_profile != profile_id:
                raise ValueError(
                    f"{product_id} is a {template_id} profile, not {requested_profile}"
                )
            return product_id, profile_id, template

        profiles = product.get("profiles", {})
        profile_id = requested_profile or product.get("default_profile")
        if profile_id not in profiles:
            raise ValueError(f"unknown profile: {product_id}/{profile_id}")
        return product_id, profile_id, self._resolve_profile(profiles, profile_id, ())

    def _resolve_profile(
        self,
        profiles: dict[str, Any],
        profile_id: str,
        stack: tuple[str, ...],
    ) -> dict[str, Any]:
        if profile_id in stack:
            raise ValueError(f"profile inheritance cycle at {profile_id}")
        profile = dict(profiles[profile_id])
        parent_id = profile.pop("inherits", None)
        if not parent_id:
            return profile
        if parent_id not in profiles:
            raise ValueError(f"unknown inherited profile: {parent_id}")
        parent = self._resolve_profile(profiles, parent_id, stack + (profile_id,))
        parent.update(profile)
        return parent

    @staticmethod
    def _absolute(path: Path) -> Path:
        return Path(os.path.abspath(path))

    def resolve_path(self, entry: dict[str, Any]) -> tuple[Path, Path]:
        raw_path = str(entry["path"])
        override = entry.get("override_env")
        if override and os.environ.get(str(override)):
            base = Path(os.environ[str(override)]).expanduser()
            if not base.is_absolute():
                raise ValueError(f"{override} must be an absolute path")
            relative = entry.get("override_relative_path")
            boundary = self._absolute(base)
            path = boundary / str(relative) if relative else boundary
            return self._absolute(path), boundary
        if raw_path == "~":
            return self.home, self.home
        if raw_path.startswith("~/"):
            return self._absolute(self.home / raw_path[2:]), self.home
        return self._absolute(self.workspace / raw_path), self.workspace

    def surfaces(self, selector: str, object_type: str) -> list[SurfacePath]:
        product_id, profile_id, profile = self.profile(selector)
        entries = profile.get("surfaces", {}).get(object_type, [])
        surfaces: list[SurfacePath] = []
        for entry in entries:
            resolved_path, boundary = self.resolve_path(entry)
            surfaces.append(SurfacePath(
                product=product_id,
                profile=profile_id,
                object_type=object_type,
                scope=str(entry["scope"]),
                storage=str(entry["storage"]),
                path=str(entry["path"]),
                resolved_path=resolved_path,
                boundary=boundary,
                source_format=str(entry.get("format", "unknown")),
                policy=str(entry["policy"]),
            ))
        return surfaces

    def inventory(self, selector: str | None = None) -> list[dict[str, Any]]:
        selectors: Iterable[str]
        if selector:
            selectors = (selector,)
        else:
            expanded: list[str] = []
            for product_id, product in self.products.items():
                profiles = product.get("profiles", {})
                if profiles:
                    expanded.extend(
                        f"{product_id}/{profile_id}" for profile_id in profiles
                    )
                else:
                    expanded.append(product_id)
            selectors = expanded
        rows: list[dict[str, Any]] = []
        for candidate in selectors:
            product_id, profile_id, profile = self.profile(candidate)
            surfaces = profile.get("surfaces", {})
            if not surfaces:
                rows.append(
                    {
                        "product": product_id,
                        "profile": profile_id,
                        "kind": profile.get("kind"),
                        "migration_policy": profile.get("migration_policy"),
                        "object_type": None,
                        "exists": False,
                    }
                )
                continue
            for object_type in surfaces:
                for surface in self.surfaces(f"{product_id}/{profile_id}", object_type):
                    row = surface.to_dict()
                    row["kind"] = profile.get("kind")
                    row["migration_policy"] = profile.get("migration_policy")
                    row["exists"] = surface.resolved_path.exists()
                    rows.append(row)
        return rows


FORMAT_FEATURES: dict[str, set[str]] = {
    "agents-md": {"text", "hierarchy", "imports"},
    "cursor-mdc": {"text", "activation", "globs", "priority"},
    "continue-rule": {"text", "activation", "globs"},
    "kiro-steering": {"text", "activation", "globs", "imports"},
    "copilot-instructions": {"text"},
    "claude-rule": {"text", "activation", "globs", "imports"},
    "windsurf-rule": {"text", "activation"},
    "plain-markdown": {"text"},
}


def parse_scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1]
    return value


def parse_list(value: str) -> list[str]:
    value = value.strip()
    if value.startswith("[") and value.endswith("]"):
        value = value[1:-1]
    if not value:
        return []
    return [parse_scalar(item.strip()) for item in value.split(",") if item.strip()]


def parse_instruction(
    text: str,
    source_format: str,
    scope: str = "project",
) -> InstructionIR:
    metadata: dict[str, str] = {}
    match = FRONTMATTER.match(text)
    body = text
    if match:
        body = text[match.end() :]
        for line in match.group(1).splitlines():
            if ":" not in line or line.startswith((" ", "\t")):
                continue
            key, value = line.split(":", 1)
            metadata[key.strip()] = value.strip()
    activation = parse_scalar(
        metadata.get("activation", metadata.get("alwaysApply", "always"))
    )
    globs = parse_list(metadata.get("globs", metadata.get("paths", "")))
    imports = parse_list(metadata.get("imports", ""))
    hierarchy = parse_scalar(metadata.get("hierarchy", "flat"))
    try:
        priority = int(parse_scalar(metadata.get("priority", "0")))
    except ValueError:
        priority = 0
    return InstructionIR(
        text=body.rstrip() + "\n",
        scope=scope,
        activation=activation,
        globs=globs,
        priority=priority,
        hierarchy=hierarchy,
        imports=imports,
        source_format=source_format,
    )


def emit_instruction(
    instruction: InstructionIR,
    target_format: str,
) -> tuple[str, LossReport]:
    features = FORMAT_FEATURES.get(target_format, {"text"})
    report = LossReport()
    values: dict[str, Any] = {
        "activation": instruction.activation,
        "globs": instruction.globs,
        "priority": instruction.priority,
        "hierarchy": instruction.hierarchy,
        "imports": instruction.imports,
    }
    meaningful = {
        "activation": instruction.activation not in ("", "always", "true"),
        "globs": bool(instruction.globs),
        "priority": instruction.priority != 0,
        "hierarchy": instruction.hierarchy not in ("", "flat", "none"),
        "imports": bool(instruction.imports),
    }
    for field_name, present in meaningful.items():
        if present and field_name not in features:
            report.add(
                "instructions",
                field_name,
                f"{target_format} cannot represent this field",
                values[field_name],
            )

    frontmatter: list[str] = []
    if "activation" in features and instruction.activation:
        frontmatter.append(f"activation: {instruction.activation}")
    if "globs" in features and instruction.globs:
        frontmatter.append(f"globs: [{', '.join(instruction.globs)}]")
    if "priority" in features and instruction.priority:
        frontmatter.append(f"priority: {instruction.priority}")
    if "imports" in features and instruction.imports:
        frontmatter.append(f"imports: [{', '.join(instruction.imports)}]")
    if "hierarchy" in features and instruction.hierarchy:
        frontmatter.append(f"hierarchy: [{', '.join(instruction.hierarchy)}]")
    prefix = ""
    if frontmatter:
        prefix = "---\n" + "\n".join(frontmatter) + "\n---\n"
    return prefix + instruction.text, report


def _server_container(value: dict[str, Any]) -> tuple[str, dict[str, Any]]:
    for key in ("mcpServers", "servers", "mcp"):
        servers = value.get(key)
        if isinstance(servers, dict):
            return key, servers
    raise ValueError("MCP JSON must contain an mcpServers, servers, or mcp object")


def parse_mcp_document(text: str, source_format: str) -> list[MCPServerIR]:
    value = json.loads(text)
    if not isinstance(value, dict):
        raise ValueError("MCP document root must be an object")
    _, servers = _server_container(value)
    parsed: list[MCPServerIR] = []
    for name, raw_server in servers.items():
        if not isinstance(name, str) or not isinstance(raw_server, dict):
            raise ValueError("MCP servers must be named objects")
        command = raw_server.get("command")
        url = raw_server.get("url")
        transport = str(raw_server.get("transport", "http" if url else "stdio"))
        if command is not None and not isinstance(command, str):
            raise ValueError(f"MCP server {name}: command must be a string")
        if url is not None and not isinstance(url, str):
            raise ValueError(f"MCP server {name}: url must be a string")
        args = raw_server.get("args", [])
        env = raw_server.get("env", {})
        headers = raw_server.get("headers", {})
        if not isinstance(args, list) or not all(isinstance(arg, str) for arg in args):
            raise ValueError(f"MCP server {name}: args must be strings")
        if not isinstance(env, dict) or not all(
            isinstance(key, str) and isinstance(item, str) for key, item in env.items()
        ):
            raise ValueError(f"MCP server {name}: env must be a string map")
        if not isinstance(headers, dict) or not all(
            isinstance(key, str) and isinstance(item, str)
            for key, item in headers.items()
        ):
            raise ValueError(f"MCP server {name}: headers must be a string map")
        parsed.append(
            MCPServerIR(
                name=name,
                transport=transport,
                command=command,
                args=list(args),
                env=dict(env),
                url=url,
                headers=dict(headers),
                source_format=source_format,
            )
        )
    return parsed


PROVIDER_SECRET = re.compile(
    r"(?:sk-[A-Za-z0-9_-]{16,}"
    r"|gh[pousr]_[A-Za-z0-9]{20,}"
    r"|AKIA[0-9A-Z]{16}"
    r"|ASIA[0-9A-Z]{16}"
    r"|xox[baprs]-[A-Za-z0-9-]{10,}"
    r"|ya29\.[A-Za-z0-9_-]+"
    r"|AIza[0-9A-Za-z_-]{35}"
    r"|sk_live_[A-Za-z0-9]{16,})"
)
SECRET_FLAGS = {
    "-k": "API_KEY",
    "-p": "PASSWORD",
    "-t": "TOKEN",
    "--api-key": "API_KEY",
    "--apikey": "API_KEY",
    "--auth": "AUTHORIZATION",
    "--password": "PASSWORD",
    "--secret": "SECRET",
    "--token": "TOKEN",
}


def _safe_secret_value(name: str, value: str) -> tuple[str, bool]:
    if (
        not SENSITIVE_NAME.search(name)
        and not PROVIDER_SECRET.search(value)
        and not URL_CREDENTIAL.search(value)
        and not BEARER_LITERAL.search(value)
    ) or PLACEHOLDER.fullmatch(value) or SAFE_BEARER_REFERENCE.fullmatch(value):
        return value, False
    placeholder_name = re.sub(r"[^A-Za-z0-9_]", "_", name).upper()
    return f"${{{placeholder_name}}}", True


def _safe_args(args: list[str], server_name: str, report: LossReport) -> list[str]:
    safe = list(args)
    index = 0
    while index < len(safe):
        argument = safe[index]
        flag, separator, inline_value = argument.partition("=")
        normalized_flag = flag.lower()
        if normalized_flag in SECRET_FLAGS:
            placeholder = f"${{{SECRET_FLAGS[normalized_flag]}}}"
            if separator:
                if inline_value and not PLACEHOLDER.fullmatch(inline_value):
                    safe[index] = f"{flag}={placeholder}"
                    report.add(
                        "mcp", f"{server_name}.args[{index}]", "literal secret removed", None
                    )
            elif index + 1 < len(safe) and not PLACEHOLDER.fullmatch(safe[index + 1]):
                safe[index + 1] = placeholder
                report.add(
                    "mcp", f"{server_name}.args[{index + 1}]", "literal secret removed", None
                )
                index += 1
        elif (
            PROVIDER_SECRET.search(argument)
            or URL_CREDENTIAL.search(argument)
            or BEARER_LITERAL.search(argument)
        ):
            safe[index] = "${SECRET}"
            report.add(
                "mcp", f"{server_name}.args[{index}]", "provider credential removed", None
            )
        index += 1
    return safe


def _safe_url(url: str, server_name: str, report: LossReport) -> str:
    provider_redacted_url, provider_count = PROVIDER_SECRET.subn("${MCP_SECRET}", url)
    if provider_count:
        report.add("mcp", f"{server_name}.url", "provider credential removed", None)
    url = provider_redacted_url
    parsed = urllib.parse.urlsplit(url)
    changed = False
    hostname = parsed.hostname or ""
    netloc = hostname
    if parsed.port is not None:
        netloc += f":{parsed.port}"
    if parsed.username is not None or parsed.password is not None:
        netloc = f"${{MCP_USER}}:${{MCP_PASSWORD}}@{netloc}"
        changed = True
    query_items = urllib.parse.parse_qsl(parsed.query, keep_blank_values=True)
    safe_query: list[tuple[str, str]] = []
    for name, value in query_items:
        safe_value, redacted = _safe_secret_value(name, value)
        safe_query.append((name, safe_value))
        changed = changed or redacted
    if changed:
        report.add("mcp", f"{server_name}.url", "literal URL credential removed", None)
    return urllib.parse.urlunsplit(
        (parsed.scheme, netloc or parsed.netloc, parsed.path, urllib.parse.urlencode(safe_query), parsed.fragment)
    )


def emit_mcp_document(
    servers: list[MCPServerIR],
    target_format: str,
    existing_text: str | None = None,
) -> tuple[str, LossReport]:
    key = target_format.split(":", 1)[1] if target_format.startswith("json:") else "mcpServers"
    existing: dict[str, Any] = {}
    if existing_text:
        decoded = json.loads(existing_text)
        if not isinstance(decoded, dict):
            raise ValueError("target MCP JSON root must be an object")
        existing = decoded
    output_servers: dict[str, Any] = {}
    report = LossReport()
    for server in servers:
        item: dict[str, Any] = {"transport": server.transport}
        if server.command is not None:
            if (
                PROVIDER_SECRET.search(server.command)
                or URL_CREDENTIAL.search(server.command)
                or BEARER_LITERAL.search(server.command)
            ):
                raise ValueError(f"MCP server {server.name}: command contains a credential")
            item["command"] = server.command
        if server.args:
            item["args"] = _safe_args(server.args, server.name, report)
        if server.url is not None:
            item["url"] = _safe_url(server.url, server.name, report)
        if server.env:
            env: dict[str, str] = {}
            for name, value in server.env.items():
                env[name], redacted = _safe_secret_value(name, value)
                if redacted:
                    report.add("mcp", f"{server.name}.env.{name}", "literal secret removed", None)
            item["env"] = env
        if server.headers:
            headers: dict[str, str] = {}
            for name, value in server.headers.items():
                headers[name], redacted = _safe_secret_value(name, value)
                if redacted:
                    report.add(
                        "mcp", f"{server.name}.headers.{name}", "literal secret removed", None
                    )
            item["headers"] = headers
        output_servers[server.name] = item
    existing[key] = output_servers
    return json.dumps(existing, indent=2, sort_keys=True) + "\n", report


def scope_matches(surface_scope: str, requested_scope: str) -> bool:
    if requested_scope == "all":
        return surface_scope not in {"runtime"}
    if requested_scope == "user":
        return "user" in surface_scope
    if requested_scope == "project":
        return "project" in surface_scope or surface_scope in {"workspace", "repository"}
    return surface_scope == requested_scope


def choose_surface(surfaces: list[SurfacePath], scope: str) -> SurfacePath | None:
    for surface in surfaces:
        if scope_matches(surface.scope, scope):
            return surface
    return None


def build_plan(
    registry: Registry,
    source_selector: str,
    target_selector: str,
    object_types: list[str],
    scope: str,
) -> tuple[list[PlanItem], LossReport]:
    _, _, target_profile = registry.profile(target_selector)
    target_policy = target_profile.get("migration_policy", "manual-rebuild")
    blocked_target = target_policy in {
        "source-only",
        "manual-rebuild",
        "official-api-or-rebuild-checklist",
        "configure-consuming-client",
        "alias-only",
    }
    items: list[PlanItem] = []
    losses = LossReport()
    for object_type in object_types:
        source = choose_surface(registry.surfaces(source_selector, object_type), scope)
        target = choose_surface(registry.surfaces(target_selector, object_type), scope)
        if source is None:
            items.append(PlanItem(object_type, "blocked", "source surface is not mapped"))
            continue
        if target is None:
            items.append(
                PlanItem(object_type, "manual", "target surface is not mapped", source=source)
            )
            continue
        try:
            ensure_no_symlink_components(source.resolved_path, source.boundary)
            ensure_no_symlink_components(target.resolved_path, target.boundary)
            if source.resolved_path.exists():
                ensure_no_symlinks(source.resolved_path)
        except ValueError as error:
            items.append(
                PlanItem(object_type, "blocked", str(error), source, target)
            )
            continue
        if not source.resolved_path.exists():
            items.append(
                PlanItem(
                    object_type,
                    "blocked",
                    f"source path does not exist: {source.resolved_path}",
                    source,
                    target,
                )
            )
            continue
        if blocked_target or target.policy in {
            "source-only",
            "manual-rebuild",
            "manual-template",
            "disabled-draft-only",
            "forbidden-regenerate",
            "official-api-or-rebuild-checklist",
        }:
            items.append(
                PlanItem(
                    object_type,
                    "blocked",
                    f"target policy is {target_policy}/{target.policy}",
                    source,
                    target,
                )
            )
            continue
        if object_type == "instructions":
            instruction_paths = _instruction_sources(source)
            if not instruction_paths:
                items.append(
                    PlanItem(
                        object_type,
                        "blocked",
                        "source contains no instruction files",
                        source,
                        target,
                    )
                )
                continue
            try:
                for instruction_path in instruction_paths:
                    instruction = parse_instruction(
                        instruction_path.read_text(encoding="utf-8"),
                        source.source_format,
                        source.scope,
                    )
                    _, report = emit_instruction(instruction, target.source_format)
                    losses.items.extend(report.items)
            except (OSError, UnicodeError) as error:
                items.append(
                    PlanItem(
                        object_type,
                        "blocked",
                        f"instruction validation failed: {error}",
                        source,
                        target,
                    )
                )
                continue
        if object_type == "mcp" and not target.source_format.startswith("json:"):
            items.append(
                PlanItem(
                    object_type,
                    "manual",
                    f"target MCP format {target.source_format} requires a profile adapter",
                    source,
                    target,
                )
            )
            continue
        if object_type == "mcp":
            if not source.resolved_path.is_file():
                items.append(
                    PlanItem(object_type, "blocked", "MCP source must be a file", source, target)
                )
                continue
            try:
                servers = parse_mcp_document(
                    source.resolved_path.read_text(encoding="utf-8"),
                    source.source_format,
                )
                existing = (
                    target.resolved_path.read_text(encoding="utf-8")
                    if target.resolved_path.is_file()
                    else None
                )
                _, report = emit_mcp_document(servers, target.source_format, existing)
                losses.items.extend(report.items)
            except (OSError, UnicodeError, ValueError, json.JSONDecodeError) as error:
                items.append(
                    PlanItem(
                        object_type,
                        "blocked",
                        f"MCP validation failed: {error}",
                        source,
                        target,
                    )
                )
                continue
        items.append(PlanItem(object_type, "ready", "review before apply", source, target))
    return items, losses


def hash_path(path: Path) -> str:
    digest = hashlib.sha256()
    if path.is_file():
        digest.update(path.read_bytes())
        return digest.hexdigest()
    if path.is_dir():
        for child in sorted(path.rglob("*")):
            if child.is_symlink():
                raise ValueError(f"symbolic links are not allowed: {child}")
            if child.is_file():
                digest.update(str(child.relative_to(path)).encode("utf-8"))
                digest.update(b"\0")
                digest.update(child.read_bytes())
        return digest.hexdigest()
    raise ValueError(f"cannot hash missing path: {path}")


def ensure_no_symlinks(path: Path) -> None:
    if path.is_symlink():
        raise ValueError(f"symbolic links are not allowed: {path}")
    if path.is_dir():
        for child in path.rglob("*"):
            if child.is_symlink():
                raise ValueError(f"symbolic links are not allowed: {child}")


def ensure_no_symlink_components(path: Path, boundary: Path) -> None:
    try:
        relative = path.relative_to(boundary)
    except ValueError as error:
        raise ValueError(f"path escapes its migration boundary: {path}") from error
    candidate = boundary
    if candidate.is_symlink():
        raise ValueError(f"symbolic links are not allowed: {candidate}")
    for part in relative.parts:
        candidate = candidate / part
        if candidate.is_symlink():
            raise ValueError(f"symbolic links are not allowed: {candidate}")


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def backup_path(target: Path, backup_root: Path, sequence: int) -> Path | None:
    if not target.exists():
        return None
    ensure_no_symlinks(target)
    backup = backup_root / f"{sequence:04d}-{hashlib.sha256(str(target).encode()).hexdigest()[:12]}"
    backup.parent.mkdir(parents=True, exist_ok=True)
    if target.is_dir():
        shutil.copytree(target, backup)
    else:
        shutil.copy2(target, backup)
    return backup


def record_change(
    changes: list[dict[str, Any]],
    target: Path,
    backup: Path | None,
    boundary: Path,
) -> None:
    if target == boundary:
        raise ValueError(f"refusing to record a migration boundary as a target: {target}")
    changes.append(
        {
            "path": str(target),
            "boundary": str(boundary),
            "kind": "directory" if target.is_dir() else "file",
            "backup": str(backup) if backup else None,
            "created": backup is None,
            "post_sha256": hash_path(target),
        }
    )


def _instruction_sources(surface: SurfacePath) -> list[Path]:
    source = surface.resolved_path
    if source.is_file():
        return [source]
    if source.is_dir():
        return sorted(path for path in source.rglob("*.md*") if path.is_file())
    return []


def _instruction_target_is_file(surface: SurfacePath) -> bool:
    if surface.storage in {"file", "precedence-files", "config-subobject"}:
        return True
    return surface.resolved_path.suffix.lower() in {".md", ".mdc", ".txt"}


def apply_plan(
    plan: list[PlanItem],
    workspace: Path,
    manifest_path: Path | None = None,
) -> tuple[dict[str, Any], Path]:
    blocked = [item for item in plan if item.status != "ready"]
    if blocked:
        summary = ", ".join(f"{item.object_type}:{item.status}" for item in blocked)
        raise ValueError(f"plan contains non-applicable items: {summary}")
    workspace = workspace.resolve()
    operation_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + f"-{os.getpid()}"
    state_root = workspace / ".agent-context-migration"
    ensure_no_symlink_components(state_root, workspace)
    backup_root = state_root / "backups" / operation_id
    manifest_path = manifest_path or state_root / "manifests" / f"{operation_id}.json"
    changes: list[dict[str, Any]] = []
    loss_report = LossReport()
    for item in plan:
        assert item.source is not None and item.target is not None
        source = item.source
        target = item.target
        ensure_no_symlink_components(source.resolved_path, source.boundary)
        ensure_no_symlink_components(target.resolved_path, target.boundary)
        ensure_no_symlinks(source.resolved_path)
        if not source.resolved_path.exists():
            raise ValueError(f"source does not exist: {source.resolved_path}")
        if item.object_type == "skills":
            ensure_no_symlinks(source.resolved_path)
            if not source.resolved_path.is_dir():
                raise ValueError("skills source must be a directory")
            target.resolved_path.mkdir(parents=True, exist_ok=True)
            for child in sorted(source.resolved_path.iterdir()):
                if not child.is_dir() or not (child / "SKILL.md").is_file():
                    continue
                destination = target.resolved_path / child.name
                backup = backup_path(destination, backup_root, len(changes))
                temporary = target.resolved_path / f".{child.name}.migration-{operation_id}"
                shutil.copytree(child, temporary)
                if destination.exists():
                    if destination.is_dir():
                        shutil.rmtree(destination)
                    else:
                        destination.unlink()
                os.replace(temporary, destination)
                record_change(changes, destination, backup, target.boundary)
        elif item.object_type == "instructions":
            sources = _instruction_sources(source)
            if not sources:
                raise ValueError(f"no instruction files found: {source.resolved_path}")
            for index, instruction_path in enumerate(sources):
                instruction = parse_instruction(
                    instruction_path.read_text(encoding="utf-8"),
                    source.source_format,
                    source.scope,
                )
                rendered, report = emit_instruction(instruction, target.source_format)
                loss_report.items.extend(report.items)
                if _instruction_target_is_file(target):
                    destination = target.resolved_path
                    if len(sources) > 1:
                        raise ValueError("multiple instructions cannot be merged into one target file")
                else:
                    suffix = ".mdc" if target.source_format == "cursor-mdc" else ".md"
                    destination = target.resolved_path / f"migrated-{index + 1}{suffix}"
                backup = backup_path(destination, backup_root, len(changes))
                atomic_write(destination, rendered)
                record_change(changes, destination, backup, target.boundary)
        elif item.object_type == "mcp":
            source_text = source.resolved_path.read_text(encoding="utf-8")
            servers = parse_mcp_document(source_text, source.source_format)
            existing = (
                target.resolved_path.read_text(encoding="utf-8")
                if target.resolved_path.is_file()
                else None
            )
            rendered, report = emit_mcp_document(servers, target.source_format, existing)
            loss_report.items.extend(report.items)
            backup = backup_path(target.resolved_path, backup_root, len(changes))
            atomic_write(target.resolved_path, rendered)
            record_change(changes, target.resolved_path, backup, target.boundary)
        else:
            raise ValueError(f"unsupported automatic object: {item.object_type}")

    manifest = {
        "schema_version": 1,
        "operation_id": operation_id,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "workspace": str(workspace),
        "changes": changes,
        "loss_report": loss_report.to_dict(),
    }
    atomic_write(manifest_path, json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    return manifest, manifest_path


def load_manifest(path: Path) -> dict[str, Any]:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(manifest, dict) or manifest.get("schema_version") != 1:
        raise ValueError("unsupported manifest")
    changes = manifest.get("changes")
    if not isinstance(changes, list):
        raise ValueError("manifest changes must be an array")
    return manifest


def verify_manifest(path: Path) -> list[str]:
    manifest = load_manifest(path)
    errors: list[str] = []
    for change in manifest["changes"]:
        target = Path(change["path"])
        boundary = Path(change.get("boundary", ""))
        if not boundary.is_absolute() or target == boundary:
            errors.append(f"unsafe manifest boundary for: {target}")
            continue
        try:
            ensure_no_symlink_components(target, boundary)
        except ValueError as error:
            errors.append(str(error))
            continue
        if not target.exists():
            errors.append(f"missing: {target}")
            continue
        try:
            current = hash_path(target)
        except ValueError as error:
            errors.append(str(error))
            continue
        if current != change.get("post_sha256"):
            errors.append(f"changed after apply: {target}")
    return errors


def rollback_manifest(path: Path) -> int:
    manifest = load_manifest(path)
    errors = verify_manifest(path)
    if errors:
        raise ValueError("rollback refused: " + "; ".join(errors))
    restored = 0
    for change in reversed(manifest["changes"]):
        target = Path(change["path"])
        backup_value = change.get("backup")
        if target.is_dir():
            shutil.rmtree(target)
        else:
            target.unlink(missing_ok=True)
        if backup_value:
            backup = Path(backup_value)
            if not backup.exists():
                raise ValueError(f"missing rollback backup: {backup}")
            target.parent.mkdir(parents=True, exist_ok=True)
            if backup.is_dir():
                shutil.copytree(backup, target)
            else:
                shutil.copy2(backup, target)
        restored += 1
    return restored
