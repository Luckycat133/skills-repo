#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Safe, zero-context-leak AI coding context & secret migration helper.

Moves rules/instructions, Agent Skills, MCP servers, commands, agents, parked hooks,
authored memory, and .env secrets across AI coding tools or plain device-transfer
folders without exposing raw secret values to stdout, stderr, LLM context, or
MIGRATION.md.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass, field
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tomllib
from typing import Any

D = chr(36)  # "$" 占位符前缀，避免在源码里写出会被外层模板吃掉的花括号
SCHEMA_VERSION = "0.11.0-dev"

PROFILE_ALIASES: dict[str, str] = {
    "claude": "claude-code", "claude-code": "claude-code", "cursor": "cursor",
    "codex": "codex", "vscode": "vscode", "copilot": "copilot-cli",
    "copilot-app": "copilot-cli", "copilot-cli": "copilot-cli",
    "gemini": "gemini-cli", "gemini-cli": "gemini-cli", "antigravity": "antigravity",
    "windsurf": "windsurf", "codeium": "windsurf", "cline": "cline",
    "kilocode": "kilocode", "kilo": "kilocode", "zed": "zed", "opencode": "opencode",
    "kimi-code": "kimi-code", "kimiai": "kimi-code", "qwen-code": "qwen-code",
    "qwen": "qwen-code", "pi": "pi",
}
CANONICAL_PROFILES = tuple(dict.fromkeys(PROFILE_ALIASES.values()))
ALL_CATEGORIES = (
    "instructions", "skills", "mcp", "commands", "agents",
    "hooks", "workflows", "env_secrets", "memory",
)

SENSITIVE_KEY_RE = re.compile(
    r"(?:api[_-]?key|secret|token|password|passwd|pwd|auth|bearer|credential|"
    r"private[_-]?key|access[_-]?key|client[_-]?secret|dsn|connection[_-]?string|"
    r"database[_-]?url|postgres[_-]?url|mysql[_-]?url|redis[_-]?url|mongo[_-]?url|"
    r"webhook|cookie|session|pat\b)",
    re.IGNORECASE,
)
SECRET_VALUE_RE = re.compile(
    r"(?:^sk-[A-Za-z0-9_-]{8,}|^gh[pousr]_[A-Za-z0-9_]{8,}|^github_pat_[A-Za-z0-9_]{10,}|"
    r"^xox[baprs]-[A-Za-z0-9-]{8,}|^AIza[0-9A-Za-z_-]{16,}|^AKIA[0-9A-Z]{12,}|"
    r"^Bearer\s+(?!\$\{)\S+|[a-zA-Z][a-zA-Z0-9+.-]*://[^/\s:@]+:[^/\s@]+@)"
)
ENV_PLACEHOLDER_RE = re.compile(r"^\$\{(?:env:)?([A-Za-z_][A-Za-z0-9_]*)\}$")
INPUT_PLACEHOLDER_RE = re.compile(r"^\$\{input:([A-Za-z0-9_.-]+)\}$")
BEARER_ENV_RE = re.compile(r"^Bearer\s+\$\{(?:env:)?([A-Za-z_][A-Za-z0-9_]*)\}$", re.IGNORECASE)
URL_USERINFO_RE = re.compile(r"^([a-zA-Z][a-zA-Z0-9+.-]*://)([^/\s:@]+):([^/\s@]+)@(.*)$")
URL_QUERY_SECRET_RE = re.compile(
    r"([?&](?:token|api_key|apikey|key|secret|password|access_token)=)([^&#\s]+)",
    re.IGNORECASE,
)
ARG_SECRET_RE = re.compile(
    r"^(--?(?:api[-_]?key|token|secret|password|auth[-_]?token|authorization|auth|header|headers)=)(.+)$", re.IGNORECASE
)
HEADER_LITERAL_RE = re.compile(
    r"^([A-Za-z][A-Za-z0-9_-]*)[ \t]*:[ \t]*(\S.*)$"
)
HEADER_SECRET_KEYS = frozenset({
    "authorization", "proxy-authorization", "x-api-key", "api-key", "api_key",
    "access-token", "access_token", "auth-token", "auth_token", "token", "secret",
    "password", "credential", "cookie",
})
INLINE_SECRET_RE = re.compile(
    r"(?<![A-Za-z0-9_-])(?:sk-[A-Za-z0-9_-]{8,}|gh[pousr]_[A-Za-z0-9_]{8,}|"
    r"github_pat_[A-Za-z0-9_]{10,}|xox[baprs]-[A-Za-z0-9-]{8,}|"
    r"AIza[0-9A-Za-z_-]{16,}|AKIA[0-9A-Z]{12,})(?![A-Za-z0-9_-])"
)
BEARER_LITERAL_RE = re.compile(r"\bBearer\s+(?!" + re.escape(D + "{") + r")[^\s'\"\x60]+")
SECTION_RE = re.compile(
    r"<!-- agent-skills-setup:begin id=([A-Za-z0-9_.:-]+) sha256=([0-9a-f]+) -->\n"
    r"(.*?)"
    r"<!-- agent-skills-setup:end id=\1 -->\n?",
    re.DOTALL,
)

EXCLUDED_DIR_NAMES = frozenset({
    ".git", "node_modules", "__pycache__", "cache", "caches", "logs", "sessions",
    "chats", "conversations", "tasks", "checkpoints", "worktrees", "embeddings",
    "vector_store", "indexes", "browser_profile", "cookies",
})
EXCLUDED_FILE_NAMES = frozenset({
    "history.json", "history.jsonl", "state.vscdb", "state.vscdb.backup", "cookies.sqlite", "LOCK",
})
EXCLUDED_SUFFIXES = (".db", ".sqlite", ".sqlite3", ".sqlite-wal", ".sqlite-shm", ".ldb", ".jsonl", ".log")
GRANT_KEYS = frozenset({"alwaysAllow", "autoApprove", "trust", "trusted", "approvedTools", "approval_policy"})
# Command frontmatter keys the destination Skill surface can enforce. Any other
# source restriction (e.g. isolation/context) cannot be represented and must block
# conversion instead of silently installing a less-restricted Skill.
COMMAND_ENFORCEABLE_KEYS = frozenset({"allowed-tools"})


def is_excluded_asset(p: Path, root: Path) -> bool:
    try:
        rel = p.relative_to(root)
    except ValueError:
        rel = p
    if any(part in EXCLUDED_DIR_NAMES for part in rel.parts[:-1]):
        return True
    return p.name in EXCLUDED_FILE_NAMES or p.name.endswith(EXCLUDED_SUFFIXES)
AUTOLOAD_PARTS = (
    (".cursor", "rules"), (".cursor", "skills"),
    (".cursor", "commands"), (".cursor", "agents"),
    (".claude", "rules"), (".claude", "skills"),
    (".claude", "commands"), (".claude", "agents"),
    (".codex", "prompts"),
    (".agents", "skills"), (".agents", "rules"), (".agents", "workflows"),
    (".github", "instructions"), (".github", "skills"),
    (".github", "prompts"), (".github", "agents"),
    (".windsurf", "rules"), (".windsurf", "skills"), (".windsurf", "workflows"),
    (".copilot", "agents"),
    (".gemini", "skills"), (".gemini", "commands"), (".gemini", "agents"),
    (".qwen", "skills"), (".qwen", "commands"), (".qwen", "agents"),
    (".kilo", "skills"), (".kilo", "agents"), (".kilo", "workflows"),
    (".opencode", "commands"), (".opencode", "agents"),
    (".cline", "workflows"),
    (".pi", "prompts"),
)


class SafetyRefusalError(Exception):
    def __init__(self, code: str, message: str, details: dict[str, Any] | None = None) -> None:
        super().__init__(message)
        self.code = code
        self.details = details or {}


def warn_err(msg: str) -> None:
    print(f"[migrate_context] {msg}", file=sys.stderr)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_prefix(val: str) -> str:
    return hashlib.sha256(val.encode("utf-8")).hexdigest()[:8]


def slugify(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9_-]+", "-", name.strip()).strip("-").lower() or "item"


def act(cat: str, item_id: str, outcome: str, dst: Path | str | None = None, **extra: Any) -> dict[str, Any]:
    d: dict[str, Any] = {"category": cat, "id": item_id, "outcome": outcome}
    if dst is not None:
        d["destination"] = str(dst)
    d.update({k: v for k, v in extra.items() if v is not None})
    return d


def resolve_profile(name: str) -> str:
    key = name.strip().lower()
    if key not in PROFILE_ALIASES:
        raise SafetyRefusalError("unknown_profile", f"Unknown profile '{name}'. Supported: {', '.join(sorted(PROFILE_ALIASES))}")
    return PROFILE_ALIASES[key]


def parse_categories(raw: str) -> set[str]:
    if not raw or raw.strip().lower() == "all":
        return set(ALL_CATEGORIES)
    alias_map = {"rules": "instructions", "env": "env_secrets", "secrets": "env_secrets"}
    out: set[str] = set()
    for part in raw.split(","):
        p = alias_map.get(part.strip().lower(), part.strip().lower())
        if p not in ALL_CATEGORIES:
            raise SafetyRefusalError("unknown_category", f"Unknown category '{part}'. Valid: {', '.join(ALL_CATEGORIES)}")
        out.add(p)
    return out


# --- Containment, 0700/0600 Atomic Writes, Private Backups, Git Guard ---


def validate_contained(path: Path, root: Path, label: str = "path") -> None:
    root_res = root.resolve()
    try:
        rel = path.relative_to(root)
    except ValueError:
        # 未解析路径可能只因中间环节有符号链接而前缀不同（如 macOS /var -> /private/var），
        # 此时按解析后的真实路径再判包含关系。
        try:
            rel = path.resolve(strict=False).relative_to(root_res)
        except ValueError as exc:
            raise SafetyRefusalError("path_outside_root", f"{label} escapes authorized root: {path}") from exc
    if ".." in rel.parts:
        raise SafetyRefusalError("path_traversal", f"Rejected '..' traversal in {label}")
    cur = root
    for part in rel.parts:
        cur = cur / part
        if cur.is_symlink() and not cur.resolve().is_relative_to(root_res):
            raise SafetyRefusalError("symlink_escape", f"Symlink escapes authorized root in {label}: {cur.name}", {"entry": str(rel)})
    if (path.exists() or path.is_symlink()) and not path.resolve(strict=False).is_relative_to(root_res):
        raise SafetyRefusalError("symlink_escape", f"Resolved {label} escapes authorized root: {rel}", {"entry": str(rel)})


def is_inside_autoload_dir(candidate: Path, workspace: Path, home: Path) -> bool:
    cand = candidate.resolve(strict=False)
    for base in (workspace.resolve(strict=False), home.resolve(strict=False)):
        for parts in AUTOLOAD_PARTS:
            auto_dir = base.joinpath(*parts)
            if cand == auto_dir or cand.is_relative_to(auto_dir):
                return True
    return False


def ensure_dir(path: Path, private: bool = False, dry_run: bool = False) -> None:
    if dry_run:
        return
    if not private:
        path.mkdir(parents=True, exist_ok=True)
        return
    missing: list[Path] = []
    cur = path
    while not cur.exists():
        missing.append(cur)
        if cur.parent == cur:
            break
        cur = cur.parent
    for d in reversed(missing):
        d.mkdir(mode=0o700, exist_ok=True)
        os.chmod(d, 0o700)
    if path.is_dir():
        os.chmod(path, 0o700)


def atomic_write_bytes(dst: Path, data: bytes, *, mode: int = 0o644, private_parent: bool = False, dry_run: bool = False) -> None:
    if dry_run:
        return
    ensure_dir(dst.parent, private=private_parent, dry_run=False)
    tmp = dst.parent / f".{dst.name}.tmp-{os.getpid()}-{os.urandom(4).hex()}"
    flags = os.O_CREAT | os.O_EXCL | os.O_WRONLY | getattr(os, "O_BINARY", 0)
    fd = os.open(str(tmp), flags, mode)
    try:
        os.write(fd, data)
        os.fsync(fd)
    except Exception:
        os.close(fd)
        if tmp.exists():
            tmp.unlink()
        raise
    os.close(fd)
    os.chmod(tmp, mode)
    os.replace(tmp, dst)
    os.chmod(dst, mode)


def git_path_status(target: Path) -> str:
    resolved_target = target.resolve(strict=False)
    probe = resolved_target.parent
    while not probe.exists() and probe.parent != probe:
        probe = probe.parent
    try:
        res = subprocess.run(["git", "-C", str(probe), "rev-parse", "--is-inside-work-tree"], capture_output=True, text=True, check=False, timeout=5)
    except (OSError, subprocess.SubprocessError):
        return "not-git"
    if res.returncode != 0 or res.stdout.strip() != "true":
        return "not-git"
    rel = resolved_target.relative_to(probe).as_posix()
    tr = subprocess.run(["git", "-C", str(probe), "ls-files", "--error-unmatch", "--", rel], capture_output=True, text=True, check=False, timeout=5)
    if tr.returncode == 0:
        return "tracked"
    ig = subprocess.run(["git", "-C", str(probe), "check-ignore", "-q", "--", rel], capture_output=True, text=True, check=False, timeout=5)
    return "ignored" if ig.returncode == 0 else "untracked-unignored"


class BackupManager:
    def __init__(self, backup_dir: Path | None, home: Path, workspace: Path, dry_run: bool) -> None:
        ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        self.root = backup_dir.expanduser().resolve(strict=False) if backup_dir else (home / ".agent-skills-setup-backups" / f"{ts}-{os.getpid()}")
        if is_inside_autoload_dir(self.root, workspace, home):
            raise SafetyRefusalError("unsafe_backup_dir", f"Backup dir sits inside an auto-loaded context path: {self.root}")
        if git_path_status(self.root) == "tracked":
            raise SafetyRefusalError("unsafe_backup_dir", f"Backup dir must not be Git-tracked: {self.root}")
        self.home = home.resolve(strict=False)
        self.workspace = workspace.resolve(strict=False)
        self.dry_run = dry_run
        self.backed_up: dict[Path, Path] = {}

    def backup_if_exists(self, target: Path) -> str | None:
        resolved = target.resolve(strict=False)
        if not target.exists() or target.is_dir():
            return None
        if resolved in self.backed_up:
            return str(self.backed_up[resolved])
        if resolved.is_relative_to(self.workspace):
            rel = Path("workspace") / resolved.relative_to(self.workspace)
        elif resolved.is_relative_to(self.home):
            rel = Path("home") / resolved.relative_to(self.home)
        else:
            rel = Path("external") / f"{sha256_prefix(str(resolved))}-{resolved.name}"
        bpath = self.root / rel
        if not self.dry_run:
            ensure_dir(self.root, private=True, dry_run=False)
            atomic_write_bytes(bpath, target.read_bytes(), mode=0o600, private_parent=True, dry_run=False)
        self.backed_up[resolved] = bpath
        return str(bpath)


# --- JSONC, Frontmatter, Markdown Section Merge, Secret Inspection ---


def strip_jsonc(text: str) -> str:
    out: list[str] = []
    i, n, in_str, esc = 0, len(text), False, False
    while i < n:
        ch = text[i]
        if in_str:
            out.append(ch)
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
            i += 1
        elif ch == '"':
            in_str = True
            out.append(ch)
            i += 1
        elif ch == "/" and i + 1 < n and text[i + 1] == "/":
            i += 2
            while i < n and text[i] not in "\r\n":
                i += 1
        elif ch == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                if text[i] in "\r\n":
                    out.append(text[i])
                i += 1
            i += 2
        else:
            out.append(ch)
            i += 1
    cleaned = "".join(out)
    res: list[str] = []
    i, m, in_str, esc = 0, len(cleaned), False, False
    while i < m:
        ch = cleaned[i]
        if in_str:
            res.append(ch)
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
        elif ch == '"':
            in_str = True
            res.append(ch)
        elif ch == ",":
            j = i + 1
            while j < m and cleaned[j] in " \t\r\n":
                j += 1
            if j >= m or cleaned[j] not in "]}":
                res.append(ch)
        else:
            res.append(ch)
        i += 1
    return "".join(res)


def load_jsonc(text: str) -> Any:
    s = strip_jsonc(text).strip()
    return json.loads(s) if s else {}


def split_globs(raw: Any) -> list[str]:
    if raw is None or raw is False:
        return []
    if isinstance(raw, list):
        return [g for item in raw for g in split_globs(item)]
    s = str(raw).strip()
    if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
        s = s[1:-1].strip()
    if not s:
        return []
    parts, buf, depth, q = [], [], 0, None
    for ch in s:
        if q:
            if ch == q:
                q = None
            else:
                buf.append(ch)
        elif ch in ('"', "'"):
            q = ch
        elif ch == "{":
            depth += 1
            buf.append(ch)
        elif ch == "}":
            depth = max(0, depth - 1)
            buf.append(ch)
        elif ch == "," and depth == 0:
            tok = "".join(buf).strip()
            if tok:
                parts.append(tok)
            buf = []
        else:
            buf.append(ch)
    tail = "".join(buf).strip()
    if tail:
        parts.append(tail)
    return parts


def parse_scalar_yaml(val: str) -> Any:
    v = val.strip()
    if not v:
        return ""
    if v in ("true", "True"):
        return True
    if v in ("false", "False"):
        return False
    if v in ("null", "None", "~"):
        return None
    if v.startswith("[") and v.endswith("]"):
        return split_globs(v[1:-1]) if v[1:-1].strip() else []
    if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
        return v[1:-1]
    return int(v) if re.fullmatch(r"-?\d+", v) else v


def parse_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    if not text.startswith("---"):
        return {}, text
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        return {}, text
    end_idx = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end_idx is None:
        return {}, text
    body = "".join(lines[end_idx + 1 :]).lstrip("\r\n")
    meta: dict[str, Any] = {}
    cur_key: str | None = None
    cur_list: list[Any] | None = None
    cur_folded: list[str] | None = None
    for raw_line in lines[1:end_idx]:
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(raw_line) - len(raw_line.lstrip(" "))
        if indent > 0 and cur_folded is not None and cur_key is not None:
            cur_folded.append(stripped)
            meta[cur_key] = " ".join(cur_folded)
            continue
        cur_folded = None
        if indent > 0 and stripped.startswith("- ") and cur_key is not None:
            if cur_list is None:
                cur_list = []
                meta[cur_key] = cur_list
            cur_list.append(parse_scalar_yaml(stripped[2:]))
            continue
        if ":" in raw_line and indent == 0:
            key, rest = raw_line.split(":", 1)
            cur_key, cur_list = key.strip(), None
            rs = rest.strip()
            if rs in (">", ">-", "|", "|-"):
                cur_folded, meta[cur_key] = [], ""
            elif rs == "":
                cur_list = []
                meta[cur_key] = cur_list
            else:
                meta[cur_key] = parse_scalar_yaml(rs)
    return meta, body


def yaml_quote(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def render_frontmatter(meta: dict[str, Any], body: str) -> str:
    lines = ["---"]
    for k, v in meta.items():
        if v is None:
            continue
        if isinstance(v, bool):
            lines.append(f"{k}: {'true' if v else 'false'}")
        elif isinstance(v, list):
            if v:
                lines.append(f"{k}:")
                lines.extend(f"  - {yaml_quote(str(x))}" for x in v)
        elif isinstance(v, (int, float)):
            lines.append(f"{k}: {v}")
        else:
            sv = str(v)
            q = any(c in sv for c in '*?[]{}:,#&!|>%@`"') or sv != sv.strip()
            lines.append(f"{k}: {yaml_quote(sv) if q else sv}")
    lines.append("---")
    return "\n".join(lines) + "\n" + (body if body.endswith("\n") else body + "\n")


def merge_markdown_section(existing: str, section_id: str, body: str) -> tuple[str, str]:
    norm_body = body.strip() + "\n"
    digest = sha256_bytes(norm_body.encode("utf-8"))[:12]
    block = f"<!-- agent-skills-setup:begin id={section_id} sha256={digest} -->\n{norm_body}<!-- agent-skills-setup:end id={section_id} -->\n"
    for match in SECTION_RE.finditer(existing):
        fid, fsha, finner = match.group(1), match.group(2), match.group(3)
        if fid == section_id:
            actual = sha256_bytes((finner.strip() + "\n").encode("utf-8"))[:12]
            return (existing, "noop") if (fsha == digest and actual == digest) else (existing, "conflict")
    if norm_body.strip() and norm_body.strip() == existing.strip():
        return existing, "noop"
    if not existing:
        return block, "added"
    sep = "" if existing.endswith("\n\n") else ("\n" if existing.endswith("\n") else "\n\n")
    return existing + sep + block, "added"


BENIGN_ENV_KEYS = frozenset({
    "NODE_ENV", "ENVIRONMENT", "ENV", "PATH", "PORT", "HOST", "HOSTNAME",
    "LOG_LEVEL", "DEBUG", "RUST_LOG", "PYTHONPATH", "PYTHONUNBUFFERED",
    "NODE_OPTIONS", "LANG", "LC_ALL", "TZ", "NO_COLOR", "FORCE_COLOR",
    "CI", "TMPDIR", "TMP", "TEMP",
})


def is_secret_kv(key: str, value: str) -> bool:
    if not value or ENV_PLACEHOLDER_RE.match(value) or INPUT_PLACEHOLDER_RE.match(value) or BEARER_ENV_RE.match(value):
        return False
    if SENSITIVE_KEY_RE.search(key) or SECRET_VALUE_RE.search(value):
        return True
    if key.upper() in BENIGN_ENV_KEYS:
        return False
    if value.lower() in ("true", "false") or re.fullmatch(r"-?\d+(?:\.\d+)?", value):
        return False
    return True


def inspect_url_secrets(url: str) -> tuple[str, list[dict[str, str]]]:
    found: list[dict[str, str]] = []
    redacted = url
    m = URL_USERINFO_RE.match(redacted)
    if m and not ENV_PLACEHOLDER_RE.match(m.group(3)):
        found.append({"name": "url_password", "sha256_prefix": sha256_prefix(m.group(3))})
        redacted = f"{m.group(1)}{m.group(2)}:${{URL_PASSWORD}}@{m.group(4)}"

    def _q_repl(match: re.Match[str]) -> str:
        prefix, val = match.group(1), match.group(2)
        if ENV_PLACEHOLDER_RE.match(val):
            return match.group(0)
        pname = prefix[1:-1]
        found.append({"name": f"url_query:{pname}", "sha256_prefix": sha256_prefix(val)})
        return f"{prefix}${{{pname.upper()}}}"

    return URL_QUERY_SECRET_RE.sub(_q_repl, redacted), found


def inspect_args_secrets(args: list[str]) -> tuple[list[str], list[dict[str, str]]]:
    found: list[dict[str, str]] = []
    redacted_args: list[str] = []
    pending_flag: str | None = None
    for idx, arg in enumerate(args):
        if pending_flag is not None:
            fk = slugify(pending_flag).upper().replace("-", "_")
            if not ENV_PLACEHOLDER_RE.match(arg):
                found.append({"name": f"arg:{fk}", "sha256_prefix": sha256_prefix(arg)})
                redacted_args.append(f"${{{fk}}}")
            else:
                redacted_args.append(arg)
            pending_flag = None
            continue
        if re.fullmatch(
            r"--?(?:api[-_]?key|token|secret|password|auth[-_]?token|authorization|auth|header|headers)",
            arg, re.IGNORECASE,
        ):
            pending_flag = arg.lstrip("-")
            redacted_args.append(arg)
            continue
        header_like = HEADER_LITERAL_RE.match(arg)
        if header_like and header_like.group(1).lower() in HEADER_SECRET_KEYS:
            value = header_like.group(2)
            if not ENV_PLACEHOLDER_RE.match(value):
                fk = slugify(header_like.group(1)).upper().replace("-", "_")
                found.append({"name": f"arg:{fk}", "sha256_prefix": sha256_prefix(value)})
                redacted_args.append(f"{header_like.group(1)}:{D}{{{fk}}}")
                continue
        m = ARG_SECRET_RE.match(arg)
        if m and not ENV_PLACEHOLDER_RE.match(m.group(2)):
            fk = slugify(m.group(1).rstrip("=").lstrip("-")).upper().replace("-", "_")
            found.append({"name": f"arg:{fk}", "sha256_prefix": sha256_prefix(m.group(2))})
            redacted_args.append(f"{m.group(1)}${{{fk}}}")
            continue
        is_url = re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*://", arg) is not None
        if (SECRET_VALUE_RE.search(arg) or is_url) and not ENV_PLACEHOLDER_RE.match(arg):
            r_url, u_sec = inspect_url_secrets(arg)
            if u_sec:
                found.extend(u_sec)
                redacted_args.append(r_url)
            elif is_url:
                redacted_args.append(arg)
            else:
                found.append({"name": f"arg[{idx}]", "sha256_prefix": sha256_prefix(arg)})
                redacted_args.append(f"${{SECRET_ARG_{idx}}}")
            continue
        redacted_args.append(arg)
    return redacted_args, found


def parse_dotenv_secrets(text: str, redact: bool = False) -> tuple[str, list[dict[str, str]]]:
    secrets: list[dict[str, str]] = []
    out_lines: list[str] = []
    pending_quote: str | None = None
    for raw in text.splitlines(keepends=True):
        s = raw.strip()
        if pending_quote is not None:
            if redact:
                out_lines.append("\n" if raw.endswith("\n") else "")
            else:
                out_lines.append(raw)
            if pending_quote in raw:
                pending_quote = None
            continue
        if not s or s.startswith("#") or "=" not in s:
            out_lines.append(raw)
            continue
        lhs, rhs = raw.split("=", 1)
        key = lhs.strip()
        if key.startswith("export "):
            key = key[7:].strip()
        val = rhs.strip()
        unq = val[1:-1] if ((val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'"))) else re.split(r"\s+#", val, maxsplit=1)[0].strip()
        is_dotenv_secret = (
            SENSITIVE_KEY_RE.search(key)
            or SECRET_VALUE_RE.search(unq)
            or key.upper().endswith(("_KEY", "_SECRET", "_TOKEN", "_PASSWORD", "_PWD"))
        )
        if unq and not ENV_PLACEHOLDER_RE.match(unq) and is_dotenv_secret:
            secrets.append({"name": key, "sha256_prefix": sha256_prefix(unq)})
            if redact:
                out_lines.append(f"{lhs.rstrip()}=" + ("\n" if raw.endswith("\n") else ""))
                if (val.startswith('"') and not val.endswith('"')) or (val.startswith("'") and not val.endswith("'")):
                    pending_quote = val[0]
                continue
        out_lines.append(raw)
    return "".join(out_lines), secrets


# --- Normalized MCP & Surgical Readers/Writers ---


@dataclass
class NormalizedMcp:
    name: str
    transport: str
    command: str | None = None
    args: list[str] = field(default_factory=list)
    url: str | None = None
    cwd: str | None = None
    env: dict[str, str] = field(default_factory=dict)
    headers: dict[str, str] = field(default_factory=dict)
    disabled: bool = False
    timeout: int | float | None = None
    tool_allow: list[str] = field(default_factory=list)
    tool_deny: list[str] = field(default_factory=list)
    knob_only: bool = False
    stripped_grants: list[str] = field(default_factory=list)
    source_profile: str = ""

    def secret_summary(self) -> tuple[bool, list[dict[str, str]]]:
        items: list[dict[str, str]] = []
        if self.url:
            items.extend(inspect_url_secrets(self.url)[1])
        if self.args:
            items.extend(inspect_args_secrets(self.args)[1])
        for k, v in sorted(self.env.items()):
            if is_secret_kv(k, v):
                items.append({"name": k, "sha256_prefix": sha256_prefix(v)})
        for k, v in sorted(self.headers.items()):
            if v and not (ENV_PLACEHOLDER_RE.match(v) or BEARER_ENV_RE.match(v) or INPUT_PLACEHOLDER_RE.match(v)):
                items.append({"name": f"header:{k}", "sha256_prefix": sha256_prefix(v)})
        return bool(items), items

    def comparison_signature(self, redact_secrets: bool = False) -> dict[str, Any]:
        url_val = inspect_url_secrets(self.url)[0] if (redact_secrets and self.url) else self.url
        args_val = inspect_args_secrets(self.args)[0] if redact_secrets else list(self.args)
        norm_env = {
            k: (f"${{{ENV_PLACEHOLDER_RE.match(v).group(1)}}}" if ENV_PLACEHOLDER_RE.match(v) else (f"${{{k}}}" if (redact_secrets and is_secret_kv(k, v)) else f"val:{sha256_prefix(v)}"))  # type: ignore[union-attr]
            for k, v in sorted(self.env.items())
        }
        norm_hdr = {
            k: (
                f"Bearer ${{{BEARER_ENV_RE.match(v).group(1)}}}" if BEARER_ENV_RE.match(v)  # type: ignore[union-attr]
                else (f"${{{ENV_PLACEHOLDER_RE.match(v).group(1)}}}" if ENV_PLACEHOLDER_RE.match(v) else (f"redacted:{k}" if redact_secrets else f"val:{sha256_prefix(v)}"))  # type: ignore[union-attr]
            )
            for k, v in sorted(self.headers.items())
        }
        return {
            "transport": self.transport, "command": self.command, "cwd": self.cwd,
            "args": [f"sec:{sha256_prefix(a)}" if SECRET_VALUE_RE.search(a) else a for a in args_val],
            "url": (f"{inspect_url_secrets(url_val)[0]}#{sha256_prefix(url_val)}" if (url_val and inspect_url_secrets(url_val)[1]) else url_val),
            "env": norm_env, "headers": norm_hdr, "disabled": self.disabled, "knob_only": self.knob_only,
            "tool_allow": sorted(self.tool_allow), "tool_deny": sorted(self.tool_deny),
        }


def normalize_mcp_entry(name: str, raw: dict[str, Any], source_style: str = "mcpServers") -> NormalizedMcp:
    grants = [k for k in raw if k in GRANT_KEYS]
    disabled = bool(raw.get("disabled", False) or raw.get("enabled", True) is False)

    if source_style == "opencode" or isinstance(raw.get("command"), list):
        cl = raw.get("command") or []
        cmd, args = (str(cl[0]), [str(x) for x in cl[1:]]) if cl else (None, [])
        url = raw.get("url")
        env_raw = raw.get("environment") or raw.get("env") or {}
        return NormalizedMcp(
            name=name, transport="http" if (raw.get("type") == "remote" or url) else "stdio",
            command=cmd, args=args, url=str(url) if url else None, cwd=raw.get("cwd"),
            env={str(k): str(v) for k, v in env_raw.items()},
            headers={str(k): str(v) for k, v in (raw.get("headers") or {}).items()},
            disabled=disabled, timeout=raw.get("timeout"), stripped_grants=grants, knob_only=not cmd and not url,
        )

    if isinstance(raw.get("command"), dict):
        cd = raw["command"]
        cmd = cd.get("path")
        env_raw = cd.get("env") or raw.get("env") or {}
        return NormalizedMcp(
            name=name, transport="stdio", command=str(cmd) if cmd else None,
            args=[str(x) for x in (cd.get("args") or [])], cwd=raw.get("cwd"),
            env={str(k): str(v) for k, v in env_raw.items()},
            headers={str(k): str(v) for k, v in (raw.get("headers") or {}).items()},
            disabled=disabled, stripped_grants=grants, knob_only=not cmd,
        )

    if source_style == "codex_toml":
        cmd, url = raw.get("command"), raw.get("url")
        env_d = {str(ev): f"${{{ev}}}" for ev in (raw.get("env_vars") or [])}
        env_d.update({str(k): str(v) for k, v in (raw.get("env") or {}).items()})
        hdrs = {str(k): str(v) for k, v in (raw.get("http_headers") or raw.get("headers") or {}).items()}
        if raw.get("bearer_token_env_var"):
            hdrs.setdefault("Authorization", f"Bearer ${{{raw['bearer_token_env_var']}}}")
        for hk, ev_n in (raw.get("env_http_headers") or {}).items():
            hdrs[str(hk)] = f"${{{ev_n}}}"
        return NormalizedMcp(
            name=name, transport="http" if url else "stdio", command=str(cmd) if cmd else None,
            args=[str(x) for x in (raw.get("args") or [])], url=str(url) if url else None, cwd=raw.get("cwd"),
            env=env_d, headers=hdrs, disabled=disabled,
            timeout=raw.get("startup_timeout_sec") or raw.get("tool_timeout_sec"),
            tool_allow=[str(x) for x in (raw.get("enabled_tools") or [])],
            tool_deny=[str(x) for x in (raw.get("disabled_tools") or [])],
            stripped_grants=grants, knob_only=not cmd and not url,
        )

    cmd = raw.get("command")
    url = raw.get("httpUrl") or raw.get("serverUrl") or raw.get("url")
    rt = str(raw.get("type") or raw.get("transport") or "").lower()
    transport = ("sse" if (rt == "sse" or (not rt and "httpUrl" not in raw and str(url).rstrip("/").endswith("/sse"))) else "http") if url else "stdio"
    env_map = {str(k): (f"${{{ENV_PLACEHOLDER_RE.match(str(v)).group(1)}}}" if ENV_PLACEHOLDER_RE.match(str(v)) else str(v)) for k, v in (raw.get("env") or {}).items()}  # type: ignore[union-attr]
    hdr_map: dict[str, str] = {}
    for k, v in (raw.get("headers") or {}).items():
        sv = str(v)
        bm, em = BEARER_ENV_RE.match(sv), ENV_PLACEHOLDER_RE.match(sv)
        hdr_map[str(k)] = f"Bearer ${{{bm.group(1)}}}" if bm else (f"${{{em.group(1)}}}" if em else sv)
    knob_only = not cmd and not url and any(k in raw for k in ("enabled", "disabled", "exposeTools"))
    return NormalizedMcp(
        name=name, transport=transport, command=str(cmd) if cmd else None,
        args=[str(x) for x in (raw.get("args") or [])], url=str(url) if url else None, cwd=raw.get("cwd"),
        env=env_map, headers=hdr_map, disabled=disabled, timeout=raw.get("timeout"),
        tool_allow=[str(x) for x in (raw.get("includeTools") or raw.get("allowedTools") or [])],
        tool_deny=[str(x) for x in (raw.get("excludeTools") or raw.get("disabledTools") or [])],
        stripped_grants=grants, knob_only=knob_only,
    )


class UnrepresentableMcpServer(Exception):
    """目标面无法表达这个 MCP 服务器（例如按服务器的工具允许/拒绝列表）。

    延后而不是安装成更宽松的服务。
    """


def serialize_mcp_for_json_style(srv: NormalizedMcp, target_style: str, redact_secrets: bool) -> tuple[dict[str, Any], list[str]]:
    notes = [f"Excluded non-portable grants: {', '.join(sorted(srv.stripped_grants))}"] if srv.stripped_grants else []
    if srv.knob_only and target_style == "pi":
        return {"enabled": not srv.disabled}, notes
    if srv.knob_only:
        notes.append("Pi knob-only override lacks command/url; preserved enabled flag only")

    url = inspect_url_secrets(srv.url)[0] if (redact_secrets and srv.url) else srv.url
    args = inspect_args_secrets(srv.args)[0] if redact_secrets else list(srv.args)
    vs = target_style == "vscode"

    env_out: dict[str, str] = {}
    for k, v in srv.env.items():
        m = ENV_PLACEHOLDER_RE.match(v)
        if m:
            env_out[k] = f"${{env:{m.group(1)}}}" if vs else f"${{{m.group(1)}}}"
        elif INPUT_PLACEHOLDER_RE.match(v):
            if not vs:
                notes.append(f"VS Code ${{input:...}} in '{k}' requires rebinding on {target_style}")
            env_out[k] = v
        elif redact_secrets and is_secret_kv(k, v):
            env_out[k] = f"${{env:{k}}}" if vs else f"${{{k}}}"
        else:
            env_out[k] = v

    hdr_out: dict[str, str] = {}
    for k, v in srv.headers.items():
        bm, em = BEARER_ENV_RE.match(v), ENV_PLACEHOLDER_RE.match(v)
        if bm:
            hdr_out[k] = f"Bearer ${{env:{bm.group(1)}}}" if vs else f"Bearer ${{{bm.group(1)}}}"
        elif em:
            hdr_out[k] = f"${{env:{em.group(1)}}}" if vs else f"${{{em.group(1)}}}"
        elif redact_secrets:
            ek = f"{slugify(srv.name).upper().replace('-', '_')}_{slugify(k).upper().replace('-', '_')}"
            hdr_out[k] = (f"Bearer ${{env:{ek}}}" if vs else f"Bearer ${{{ek}}}") if v.lower().startswith("bearer ") else (f"${{env:{ek}}}" if vs else f"${{{ek}}}")
        else:
            hdr_out[k] = v

    if target_style == "zed":
        if srv.url:
            entry: dict[str, Any] = {"url": url}
            if hdr_out:
                entry["headers"] = hdr_out
            if srv.disabled:
                entry["disabled"] = True
            return entry, notes
        cobj: dict[str, Any] = {"path": srv.command or "", "args": args}
        if env_out:
            cobj["env"] = env_out
        entry = {"command": cobj}
        if srv.disabled:
            entry["disabled"] = True
        return entry, notes

    if target_style == "opencode":
        if srv.tool_allow or srv.tool_deny:
            raise UnrepresentableMcpServer(
                "opencode 的 MCP 条目没有工具允许/拒绝列表，装上去会变成更宽松的服务"
            )
        if srv.url:
            e: dict[str, Any] = {"type": "remote", "url": url, "enabled": not srv.disabled}
            if hdr_out:
                e["headers"] = hdr_out
            return e, notes
        e = {"type": "local", "command": ([srv.command] if srv.command else []) + args, "enabled": not srv.disabled}
        if env_out:
            e["environment"] = env_out
        return e, notes

    entry: dict[str, Any] = {}
    if srv.url:
        if vs or target_style == "claude-code":
            entry["type"] = "sse" if srv.transport == "sse" else "http"
            entry["url"] = url
        elif target_style == "gemini-cli":
            entry["url" if srv.transport == "sse" else "httpUrl"] = url
        elif target_style in ("antigravity", "windsurf"):
            entry["serverUrl"] = url
        else:
            entry["url"] = url
        if hdr_out:
            entry["headers"] = hdr_out
    else:
        if vs:
            entry["type"] = "stdio"
        if srv.command:
            entry["command"] = srv.command
        if args:
            entry["args"] = args
        if srv.cwd:
            entry["cwd"] = srv.cwd
        if env_out:
            entry["env"] = env_out

    if srv.disabled:
        entry["enabled" if target_style == "pi" else "disabled"] = False if target_style == "pi" else True
    if srv.timeout is not None:
        entry["timeout"] = srv.timeout
    if srv.tool_allow:
        entry["includeTools" if target_style == "gemini-cli" else "allowedTools"] = list(srv.tool_allow)
    if srv.tool_deny:
        entry["excludeTools" if target_style == "gemini-cli" else "disabledTools"] = list(srv.tool_deny)
    return entry, notes


def toml_str(val: str) -> str:
    esc = val.replace("\\", "\\\\").replace('"', '\\"').replace("\b", "\\b").replace("\t", "\\t").replace("\n", "\\n").replace("\f", "\\f").replace("\r", "\\r")
    return f'"{esc}"'


def toml_key(key: str) -> str:
    return key if re.fullmatch(r"[A-Za-z0-9_-]+", key) else toml_str(key)


def render_codex_toml_server_block(srv: NormalizedMcp, redact_secrets: bool) -> tuple[str | None, list[str], bool]:
    notes = [f"Excluded non-portable grants: {', '.join(sorted(srv.stripped_grants))}"] if srv.stripped_grants else []
    if srv.knob_only:
        notes.append(f"Deferred knob-only MCP entry '{srv.name}': Codex requires command or url")
        return None, notes, False

    has_lit = False
    tname = toml_key(srv.name)
    lines = [f"[mcp_servers.{tname}]"]
    url = inspect_url_secrets(srv.url)[0] if (redact_secrets and srv.url) else srv.url
    args = inspect_args_secrets(srv.args)[0] if redact_secrets else list(srv.args)
    if not redact_secrets:
        has_lit = bool((srv.url and inspect_url_secrets(srv.url)[1]) or (srv.args and inspect_args_secrets(srv.args)[1]))

    if url:
        lines.append(f"url = {toml_str(url)}")
    else:
        if srv.command:
            lines.append(f"command = {toml_str(srv.command)}")
        if args:
            lines.append(f"args = [{', '.join(toml_str(a) for a in args)}]")
        if srv.cwd:
            lines.append(f"cwd = {toml_str(srv.cwd)}")
    if srv.disabled:
        lines.append("enabled = false")
    if srv.tool_allow:
        lines.append(f"enabled_tools = [{', '.join(toml_str(x) for x in srv.tool_allow)}]")
    if srv.tool_deny:
        lines.append(f"disabled_tools = [{', '.join(toml_str(x) for x in srv.tool_deny)}]")

    env_vars: list[str] = []
    lit_env: dict[str, str] = {}
    for k, v in srv.env.items():
        m = ENV_PLACEHOLDER_RE.match(v)
        if m:
            if m.group(1) != k:
                notes.append(f"env_rename_requires_rebinding: '{srv.name}' maps '{k}' from '${{{m.group(1)}}}'; Codex env_vars only forwards same-named variables")
                return None, notes, False
            env_vars.append(k)
        elif INPUT_PLACEHOLDER_RE.match(v):
            notes.append(f"input_placeholder_requires_rebinding: '{k}' added to env_vars")
            env_vars.append(k)
        elif is_secret_kv(k, v):
            if redact_secrets:
                env_vars.append(k)
                notes.append(f"Redacted secret '{k}' -> env_vars")
            else:
                lit_env[k] = v
                has_lit = True
        else:
            lit_env[k] = v

    if env_vars:
        lines.append(f"env_vars = [{', '.join(toml_str(x) for x in dict.fromkeys(env_vars))}]")

    bearer_env: str | None = None
    env_hdrs: dict[str, str] = {}
    lit_hdrs: dict[str, str] = {}
    for hk, hv in srv.headers.items():
        bm, em = BEARER_ENV_RE.match(hv), ENV_PLACEHOLDER_RE.match(hv)
        if hk.lower() == "authorization" and bm:
            bearer_env = bm.group(1)
        elif em:
            env_hdrs[hk] = em.group(1)
        elif redact_secrets:
            ek = f"{slugify(srv.name).upper().replace('-', '_')}_{slugify(hk).upper().replace('-', '_')}"
            if hk.lower() == "authorization" and hv.lower().startswith("bearer "):
                bearer_env = f"{slugify(srv.name).upper().replace('-', '_')}_BEARER_TOKEN"
                notes.append(f"Redacted Bearer header -> bearer_token_env_var = {bearer_env}")
            else:
                env_hdrs[hk] = ek
                notes.append(f"Redacted header '{hk}' -> env_http_headers.{hk} = {ek}")
        else:
            lit_hdrs[hk] = hv
            has_lit = True

    if bearer_env:
        lines.append(f"bearer_token_env_var = {toml_str(bearer_env)}")
    if env_hdrs:
        lines.append("env_http_headers = { " + ", ".join(f"{toml_key(k)} = {toml_str(v)}" for k, v in env_hdrs.items()) + " }")
    if lit_hdrs:
        lines.append("http_headers = { " + ", ".join(f"{toml_key(k)} = {toml_str(v)}" for k, v in lit_hdrs.items()) + " }")
    if lit_env:
        lines.extend(["", f"[mcp_servers.{tname}.env]"] + [f"{toml_key(k)} = {toml_str(v)}" for k, v in lit_env.items()])
    return "\n".join(lines) + "\n", notes, has_lit


def split_key_path(key_path: str) -> list[str]:
    s = key_path.strip()
    if not s or s == ".":
        return []
    if s.startswith("/"):
        return [p.replace("~1", "/").replace("~0", "~") for p in s.split("/")[1:] if p]
    parts, buf, esc = [], [], False
    for ch in s:
        if esc:
            buf.append(ch)
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == ".":
            parts.append("".join(buf))
            buf = []
        else:
            buf.append(ch)
    parts.append("".join(buf))
    return [p for p in parts if p]


def get_nested_dict(doc: dict[str, Any], parts: list[str]) -> dict[str, Any]:
    cur: Any = doc
    for p in parts:
        if not isinstance(cur, dict) or p not in cur:
            return {}
        cur = cur[p]
    return cur if isinstance(cur, dict) else {}


def set_nested_dict(doc: dict[str, Any], parts: list[str], value: dict[str, Any]) -> None:
    if not parts:
        doc.clear()
        doc.update(value)
        return
    cur = doc
    for p in parts[:-1]:
        if p not in cur or not isinstance(cur[p], dict):
            cur[p] = {}
        cur = cur[p]
    cur[parts[-1]] = value


# --- Declarative Profile Layout & Bounded Discovery ---


@dataclass
class ProfilePaths:
    profile: str
    proj_doc: Path | None = None
    proj_rules: Path | None = None
    user_doc: Path | None = None
    user_rules: Path | None = None
    proj_skills: Path | None = None
    user_skills: Path | None = None
    proj_cmds: Path | None = None
    user_cmds: Path | None = None
    proj_agents: Path | None = None
    user_agents: Path | None = None
    proj_workflows: Path | None = None
    user_workflows: Path | None = None
    proj_hooks: Path | None = None
    user_hooks: Path | None = None
    proj_mcp: Path | None = None
    proj_mcp_key: str = "mcpServers"
    proj_mcp_style: str = "mcpServers"
    user_mcp: Path | None = None
    user_mcp_key: str = "mcpServers"
    user_mcp_style: str = "mcpServers"
    user_memory: Path | None = None
    legacy: list[tuple[str, str, Path]] = field(default_factory=list)


def get_profile_paths(profile: str, ws: Path, home: Path) -> ProfilePaths:
    p = resolve_profile(profile)
    use_env = home == Path.home()
    chome = Path(os.environ["CODEX_HOME"]) if (use_env and "CODEX_HOME" in os.environ) else (home / ".codex")
    khome = Path(os.environ["KIMI_CODE_HOME"]) if (use_env and "KIMI_CODE_HOME" in os.environ) else (home / ".kimi-code")
    ag_sk = Path(os.environ["ANTIGRAVITY_SKILLS_DIR"]) if (use_env and "ANTIGRAVITY_SKILLS_DIR" in os.environ) else (home / ".gemini/antigravity/skills")

    table: dict[str, ProfilePaths] = {
        "cursor": ProfilePaths(
            p, proj_doc=ws / "AGENTS.md", proj_rules=ws / ".cursor/rules", user_rules=home / ".cursor/rules",
            proj_skills=ws / ".cursor/skills", user_skills=home / ".cursor/skills",
            proj_cmds=ws / ".cursor/commands", user_cmds=home / ".cursor/commands",
            proj_agents=ws / ".cursor/agents", user_agents=home / ".cursor/agents",
            proj_hooks=ws / ".cursor/hooks.json", user_hooks=home / ".cursor/hooks.json",
            proj_mcp=ws / ".cursor/mcp.json", user_mcp=home / ".cursor/mcp.json",
            legacy=[("instructions", "project", ws / ".cursorrules")],
        ),
        "claude-code": ProfilePaths(
            p, proj_doc=ws / "CLAUDE.md", proj_rules=ws / ".claude/rules",
            user_doc=home / ".claude/CLAUDE.md", user_rules=home / ".claude/rules",
            proj_skills=ws / ".claude/skills", user_skills=home / ".claude/skills",
            proj_cmds=ws / ".claude/commands", user_cmds=home / ".claude/commands",
            proj_agents=ws / ".claude/agents", user_agents=home / ".claude/agents",
            proj_hooks=ws / ".claude/settings.json", user_hooks=home / ".claude/settings.json",
            proj_mcp=ws / ".mcp.json", proj_mcp_style="claude-code",
            user_mcp=home / ".claude.json", user_mcp_style="claude-code",
            user_memory=home / ".claude/memory",
            legacy=[("instructions", "project", ws / ".claude/CLAUDE.md"), ("instructions", "project", ws / "CLAUDE.local.md")],
        ),
        "codex": ProfilePaths(
            p, proj_doc=ws / "AGENTS.md", user_doc=chome / "AGENTS.md",
            proj_skills=ws / ".agents/skills", user_skills=home / ".agents/skills", user_cmds=chome / "prompts",
            proj_mcp=ws / ".codex/config.toml", proj_mcp_key="mcp_servers", proj_mcp_style="codex_toml",
            user_mcp=chome / "config.toml", user_mcp_key="mcp_servers", user_mcp_style="codex_toml",
            legacy=[("skills", "project", ws / ".codex/skills"), ("skills", "user", chome / "skills")],
        ),
        "vscode": ProfilePaths(
            p, proj_doc=ws / ".github/copilot-instructions.md", proj_rules=ws / ".github/instructions",
            proj_skills=ws / ".github/skills", user_skills=home / ".copilot/skills",
            proj_cmds=ws / ".github/prompts", proj_agents=ws / ".github/agents",
            proj_mcp=ws / ".vscode/mcp.json", proj_mcp_key="servers", proj_mcp_style="vscode",
        ),
        "copilot-cli": ProfilePaths(
            p, proj_doc=ws / ".github/copilot-instructions.md", proj_rules=ws / ".github/instructions",
            user_doc=home / ".copilot/copilot-instructions.md",
            proj_skills=ws / ".github/skills", user_skills=home / ".copilot/skills",
            proj_agents=ws / ".github/agents", user_agents=home / ".copilot/agents",
            user_mcp=home / ".copilot/mcp-config.json", user_mcp_style="copilot-cli",
        ),
        "gemini-cli": ProfilePaths(
            p, proj_doc=ws / "GEMINI.md", user_doc=home / ".gemini/GEMINI.md",
            proj_skills=ws / ".gemini/skills", user_skills=home / ".gemini/skills",
            proj_cmds=ws / ".gemini/commands", user_cmds=home / ".gemini/commands",
            proj_agents=ws / ".gemini/agents", user_agents=home / ".gemini/agents",
            proj_mcp=ws / ".gemini/settings.json", proj_mcp_style="gemini-cli",
            user_mcp=home / ".gemini/settings.json", user_mcp_style="gemini-cli",
        ),
        "antigravity": ProfilePaths(
            p, proj_doc=ws / "GEMINI.md", proj_rules=ws / ".agents/rules", user_doc=home / ".gemini/GEMINI.md",
            proj_skills=ws / ".agents/skills", user_skills=ag_sk, proj_workflows=ws / ".agents/workflows",
            proj_hooks=ws / ".agents/hooks.json", user_hooks=home / ".gemini/config/hooks.json",
            proj_mcp=ws / ".agents/mcp_config.json", proj_mcp_style="antigravity",
            user_mcp=home / ".gemini/antigravity/mcp_config.json", user_mcp_style="antigravity",
            legacy=[
                ("skills", "project", ws / ".agent/skills"), ("skills", "user", home / ".gemini/config/skills"),
                ("workflows", "project", ws / ".agent/workflows"), ("mcp", "user", home / ".gemini/config/mcp_config.json"),
            ],
        ),
        "windsurf": ProfilePaths(
            p, proj_doc=ws / "AGENTS.md", proj_rules=ws / ".windsurf/rules",
            user_doc=home / ".codeium/windsurf/memories/global_rules.md",
            proj_skills=ws / ".windsurf/skills", user_skills=home / ".codeium/windsurf/skills",
            proj_workflows=ws / ".windsurf/workflows", user_workflows=home / ".codeium/windsurf/workflows",
            user_mcp=home / ".codeium/windsurf/mcp_config.json", user_mcp_style="windsurf",
            legacy=[("instructions", "project", ws / ".windsurfrules")],
        ),
        "cline": ProfilePaths(
            p, proj_rules=ws / ".clinerules", user_rules=home / ".cline/rules",
            proj_skills=ws / ".cline/skills", user_skills=home / ".cline/skills",
            proj_workflows=ws / ".cline/workflows", user_workflows=home / ".cline/workflows",
            proj_hooks=ws / ".cline/hooks", user_hooks=home / ".cline/hooks",
            user_mcp=home / ".cline/data/settings/cline_mcp_settings.json", user_mcp_style="cline",
            legacy=[("instructions", "project", ws / ".cline/rules")],
        ),
        "kilocode": ProfilePaths(
            p, proj_doc=ws / "AGENTS.md", proj_rules=ws / ".kilo/rules", user_rules=home / ".kilo/rules",
            proj_skills=ws / ".kilo/skills", user_skills=home / ".kilo/skills",
            proj_agents=ws / ".kilo/agents", user_agents=home / ".kilo/agents",
            proj_workflows=ws / ".kilo/workflows", user_workflows=home / ".kilo/workflows",
            proj_mcp=ws / ".kilo/mcp.json", user_mcp=home / ".kilo/mcp.json",
            legacy=[("skills", "project", ws / ".kilocode/skills"), ("instructions", "project", ws / ".kilocode/rules"), ("mcp", "project", ws / ".kilocode/mcp.json")],
        ),
        "zed": ProfilePaths(
            p, proj_doc=ws / "AGENTS.md", user_doc=home / ".config/zed/AGENTS.md",
            proj_skills=ws / ".agents/skills", user_skills=home / ".agents/skills",
            proj_mcp=ws / ".zed/settings.json", proj_mcp_key="context_servers", proj_mcp_style="zed",
            user_mcp=home / ".config/zed/settings.json", user_mcp_key="context_servers", user_mcp_style="zed",
        ),
        "opencode": ProfilePaths(
            p, proj_doc=ws / "AGENTS.md", user_doc=home / ".config/opencode/AGENTS.md",
            proj_skills=ws / ".opencode/skills", user_skills=home / ".config/opencode/skills",
            proj_cmds=ws / ".opencode/commands", user_cmds=home / ".config/opencode/commands",
            proj_agents=ws / ".opencode/agents", user_agents=home / ".config/opencode/agents",
            proj_mcp=ws / "opencode.json", proj_mcp_key="mcp", proj_mcp_style="opencode",
            user_mcp=home / ".config/opencode/opencode.json", user_mcp_key="mcp", user_mcp_style="opencode",
        ),
        "kimi-code": ProfilePaths(
            p, proj_doc=ws / "AGENTS.md", user_doc=khome / "AGENTS.md",
            proj_skills=ws / ".kimi-code/skills", user_skills=khome / "skills",
            proj_mcp=ws / ".kimi-code/mcp.json", user_mcp=khome / "mcp.json",
            legacy=[("instructions", "user", home / ".kimi/AGENTS.md"), ("skills", "user", home / ".kimi/skills"), ("mcp", "user", home / ".kimi/mcp.json")],
        ),
        "qwen-code": ProfilePaths(
            p, proj_doc=ws / "QWEN.md", user_doc=home / ".qwen/QWEN.md",
            proj_skills=ws / ".qwen/skills", user_skills=home / ".qwen/skills",
            proj_cmds=ws / ".qwen/commands", user_cmds=home / ".qwen/commands",
            proj_agents=ws / ".qwen/agents", user_agents=home / ".qwen/agents",
            proj_mcp=ws / ".qwen/settings.json", proj_mcp_style="qwen-code",
            user_mcp=home / ".qwen/settings.json", user_mcp_style="qwen-code",
        ),
        "pi": ProfilePaths(
            p, proj_doc=ws / "AGENTS.md", user_doc=home / ".pi/agent/AGENTS.md",
            proj_skills=ws / ".pi/skills", user_skills=home / ".pi/agent/skills",
            proj_cmds=ws / ".pi/prompts", user_cmds=home / ".pi/agent/prompts",
            proj_mcp=ws / ".pi/mcp.json", proj_mcp_style="pi",
            user_mcp=home / ".pi/agent/mcp.json", user_mcp_style="pi",
        ),
    }
    return table[p]


@dataclass
class DiscoveredRule:
    slug: str
    scope: str
    kind: str
    body: str
    globs: list[str] = field(default_factory=list)
    description: str = ""
    source_path: Path = field(default_factory=Path)
    source_profile: str = ""


@dataclass
class DiscoveredSkill:
    name: str
    scope: str
    directory: Path
    meta: dict[str, Any]
    body: str
    digest: str
    source_profile: str
    auth_root: Path | None = None


@dataclass
class DiscoveredDocItem:
    category: str
    name: str
    scope: str
    path: Path
    content: bytes
    source_profile: str


@dataclass
class DiscoveredEnvFile:
    name: str
    scope: str
    path: Path
    raw_text: str
    secrets: list[dict[str, str]]


@dataclass
class ProfileInventory:
    profile: str
    rules: list[DiscoveredRule] = field(default_factory=list)
    skills: list[DiscoveredSkill] = field(default_factory=list)
    mcp_servers: dict[str, list[NormalizedMcp]] = field(default_factory=lambda: {"project": [], "user": []})
    doc_items: list[DiscoveredDocItem] = field(default_factory=list)
    env_files: list[DiscoveredEnvFile] = field(default_factory=list)
    excluded: list[dict[str, str]] = field(default_factory=list)

    def has_any(self) -> bool:
        return bool(self.rules or self.skills or self.mcp_servers["project"] or self.mcp_servers["user"] or self.doc_items or self.env_files)


def logical_path_str(path: Path, workspace: Path, home: Path) -> str:
    r, w, h = path.resolve(strict=False), workspace.resolve(strict=False), home.resolve(strict=False)
    if r.is_relative_to(w):
        rel = r.relative_to(w).as_posix()
        return f"$WORKSPACE/{rel}" if rel != "." else "$WORKSPACE"
    if r.is_relative_to(h):
        rel = r.relative_to(h).as_posix()
        return f"$HOME/{rel}" if rel != "." else "$HOME"
    return path.name


def scan_excluded_nearby(base: Path, workspace: Path, home: Path, out: list[dict[str, str]]) -> None:
    if not base.exists() or base.is_symlink() or not base.is_dir():
        return
    seen = {x["path"] for x in out}
    for entry in sorted(base.iterdir()):
        lp = logical_path_str(entry, workspace, home)
        if lp in seen:
            continue
        if entry.is_dir() and entry.name in EXCLUDED_DIR_NAMES:
            out.append({"path": lp, "reason": "excluded_state_or_history_dir"})
            seen.add(lp)
        elif entry.is_file() and (entry.name in EXCLUDED_FILE_NAMES or entry.name.endswith(EXCLUDED_SUFFIXES)):
            out.append({"path": lp, "reason": "excluded_history_or_db_file"})
            seen.add(lp)


def parse_rule_files(path: Path, scope: str, profile: str) -> list[DiscoveredRule]:
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        return []
    bname = path.name
    for suf in (".instructions.md", ".mdc", ".md"):
        if bname.endswith(suf) and len(bname) > len(suf):
            bname = bname[: -len(suf)]
            break
    slug = slugify(bname)
    root_names = {"AGENTS.md", "CLAUDE.md", "CLAUDE.local.md", "GEMINI.md", "QWEN.md", "copilot-instructions.md", ".cursorrules", ".windsurfrules", "global_rules.md"}
    if path.name in root_names or (path.name == ".clinerules" and path.is_file()):
        base_id = slugify(f"{scope}-{path.name}")
        found_sections = list(SECTION_RE.finditer(text))
        if found_sections:
            out_rules: list[DiscoveredRule] = []
            outside = SECTION_RE.sub("", text).strip()
            if outside:
                out_rules.append(DiscoveredRule(base_id, scope, "always_on", outside + "\n", source_path=path, source_profile=profile))
            for m in found_sections:
                out_rules.append(DiscoveredRule(m.group(1), scope, "always_on", m.group(3).strip() + "\n", source_path=path, source_profile=profile))
            return out_rules
        return [DiscoveredRule(base_id, scope, "always_on", text, source_path=path, source_profile=profile)]

    meta, body = parse_frontmatter(text)
    if not meta and not text.startswith("---"):
        return [DiscoveredRule(slug, scope, "always_on", text, source_path=path, source_profile=profile)]
    always = meta.get("alwaysApply") is True or str(meta.get("trigger", "")).lower() == "always_on"
    globs = split_globs(meta.get("globs") or meta.get("paths") or meta.get("applyTo"))
    desc = str(meta.get("description") or "").strip()
    trigger = str(meta.get("trigger", "")).lower()
    if always:
        kind = "always_on"
    elif globs:
        kind = "glob_scoped"
    elif trigger == "manual":
        kind = "manual"
    elif desc or trigger == "model_decision":
        kind = "model_selected"
    elif path.suffix == ".mdc":
        kind = "manual"
    else:
        kind = "always_on"
    return [DiscoveredRule(slug, scope, kind, body if body.strip() else text, globs=globs, description=desc, source_path=path, source_profile=profile)]


def compute_skill_digest(skill_dir: Path, auth_root: Path) -> str:
    h = hashlib.sha256()
    for p in sorted(skill_dir.rglob("*")):
        validate_contained(p, auth_root, f"skill:{skill_dir.name}")
        if p.is_file() and not is_excluded_asset(p, skill_dir):
            h.update(p.relative_to(skill_dir).as_posix().encode("utf-8") + b"\0" + p.read_bytes() + b"\0")
    return h.hexdigest()


def read_mcp_file(path: Path, key_path: str, style: str, fmt: str = "auto") -> dict[str, NormalizedMcp]:
    if not path.exists() or not path.is_file():
        return {}
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        return {}
    afmt = ("toml" if path.suffix.lower() == ".toml" else "jsonc") if fmt == "auto" else fmt
    if afmt == "toml":
        doc = tomllib.loads(text)
        raw_s = get_nested_dict(doc, split_key_path(key_path or "mcp_servers"))
        return {str(k): normalize_mcp_entry(str(k), v, "codex_toml") for k, v in raw_s.items() if isinstance(v, dict)}
    doc = load_jsonc(text)
    if not isinstance(doc, dict):
        return {}
    if style == "opencode" and key_path == "mcp":
        mv = doc.get("mcp")
        raw_s = mv["servers"] if (isinstance(mv, dict) and isinstance(mv.get("servers"), dict)) else (mv if isinstance(mv, dict) else {})
    else:
        raw_s = get_nested_dict(doc, split_key_path(key_path))
    return {str(k): normalize_mcp_entry(str(k), v, style) for k, v in raw_s.items() if isinstance(v, dict)}


def discover_profile(profile: str, workspace: Path, home: Path, scope: str, categories: set[str]) -> ProfileInventory:
    pp = get_profile_paths(profile, workspace, home)
    inv = ProfileInventory(profile=pp.profile)
    wp, wu = scope in ("project", "all"), scope in ("user", "all")

    for sdir in (workspace / f".{pp.profile.split('-')[0]}", home / f".{pp.profile.split('-')[0]}", home / ".cline/data", home / ".kimi-code", home / ".codeium/windsurf"):
        is_w = sdir.is_relative_to(workspace)
        if (wp and is_w) or (wu and not is_w):
            scan_excluded_nearby(sdir, workspace, home, inv.excluded)
    if wp:
        scan_excluded_nearby(workspace, workspace, home, inv.excluded)

    if "instructions" in categories:
        seen_rp: set[Path] = set()
        cands: list[tuple[str, Path, Path]] = []

        def _collect_rule_path(sc: str, pth: Path | None, root: Path) -> None:
            if pth is None or not (pth.exists() or pth.is_symlink()):
                return
            validate_contained(pth, root, f"rule:{pth.name}")
            if pth.is_file():
                cands.append((sc, pth, root))
            elif pth.is_dir():
                for f in sorted(pth.rglob("*")):
                    validate_contained(f, root, f"rule:{f.name}")
                    if f.is_file() and f.suffix in (".mdc", ".md"):
                        if is_excluded_asset(f, root):
                            lp = logical_path_str(f, workspace, home)
                            if not any(x.get("path") == lp for x in inv.excluded):
                                inv.excluded.append({"path": lp, "reason": "excluded_history_or_db_file"})
                            continue
                        cands.append((sc, f, root))

        if wp:
            _collect_rule_path("project", pp.proj_doc, workspace)
            _collect_rule_path("project", pp.proj_rules, workspace)
        if wu:
            _collect_rule_path("user", pp.user_doc, home)
            _collect_rule_path("user", pp.user_rules, home)
        for lc, ls, lp in pp.legacy:
            if lc == "instructions" and ((ls == "project" and wp) or (ls == "user" and wu)):
                _collect_rule_path(ls, lp, workspace if ls == "project" else home)

        for rsc, rpath, aroot in cands:
            validate_contained(rpath, aroot, f"rule:{rpath.name}")
            rp = rpath.resolve()
            if rp not in seen_rp:
                seen_rp.add(rp)
                ex_slugs = {(x.scope, x.kind, x.slug) for x in inv.rules}
                for pr in parse_rule_files(rpath, rsc, pp.profile):
                    if (pr.scope, pr.kind, pr.slug) not in ex_slugs:
                        inv.rules.append(pr)
                        ex_slugs.add((pr.scope, pr.kind, pr.slug))

    if "skills" in categories:
        sroots: list[tuple[str, Path, Path]] = []
        if wp and pp.proj_skills:
            sroots.append(("project", pp.proj_skills, workspace))
        if wu and pp.user_skills:
            sroots.append(("user", pp.user_skills, home))
        for lc, ls, lp in pp.legacy:
            if lc == "skills" and ((ls == "project" and wp) or (ls == "user" and wu)):
                sroots.append((ls, lp, workspace if ls == "project" else home))
        seen_sk: set[tuple[str, str]] = set()
        for ssc, sroot, aroot in sroots:
            if not (sroot.exists() or sroot.is_symlink()):
                continue
            validate_contained(sroot, aroot, "skills_dir")
            if not sroot.is_dir():
                continue
            for entry in sorted(sroot.iterdir()):
                validate_contained(entry, aroot, f"skill:{entry.name}")
                smd = entry / "SKILL.md"
                if not entry.is_dir() or entry.name == "agent-skills-setup" or not (smd.exists() or smd.is_symlink()):
                    continue
                validate_contained(smd, aroot, f"skill_md:{entry.name}")
                if (ssc, entry.name) in seen_sk:
                    continue
                seen_sk.add((ssc, entry.name))
                meta, body = parse_frontmatter(smd.read_text(encoding="utf-8"))
                inv.skills.append(DiscoveredSkill(entry.name, ssc, entry, meta, body, compute_skill_digest(entry, aroot), pp.profile, auth_root=aroot))

    if "mcp" in categories:
        if wp and pp.proj_mcp and (pp.proj_mcp.exists() or pp.proj_mcp.is_symlink()):
            validate_contained(pp.proj_mcp, workspace, "project_mcp")
            for srv in read_mcp_file(pp.proj_mcp, pp.proj_mcp_key, pp.proj_mcp_style).values():
                srv.source_profile = pp.profile
                inv.mcp_servers["project"].append(srv)
        if wp and pp.profile == "claude-code" and pp.user_mcp and pp.user_mcp.is_file():
            validate_contained(pp.user_mcp, home, "claude_local_mcp")
            ptr = f"/projects/{str(workspace.resolve()).replace('~', '~0').replace('/', '~1')}/mcpServers"
            ex_n = {s.name for s in inv.mcp_servers["project"]}
            for srv in read_mcp_file(pp.user_mcp, ptr, "claude-code").values():
                if srv.name not in ex_n:
                    srv.source_profile = pp.profile
                    inv.mcp_servers["project"].append(srv)
        if wu and pp.user_mcp and (pp.user_mcp.exists() or pp.user_mcp.is_symlink()):
            validate_contained(pp.user_mcp, home, "user_mcp")
            for srv in read_mcp_file(pp.user_mcp, pp.user_mcp_key, pp.user_mcp_style).values():
                srv.source_profile = pp.profile
                inv.mcp_servers["user"].append(srv)
        for lc, ls, lp in pp.legacy:
            if lc == "mcp" and ((ls == "project" and wp) or (ls == "user" and wu)) and (lp.exists() or lp.is_symlink()):
                validate_contained(lp, workspace if ls == "project" else home, "legacy_mcp")
                ex_n = {s.name for s in inv.mcp_servers[ls]}
                for srv in read_mcp_file(lp, "mcpServers", pp.profile).values():
                    if srv.name not in ex_n:
                        srv.source_profile = pp.profile
                        inv.mcp_servers[ls].append(srv)

    document_roots = [
        ("commands", "project", pp.proj_cmds if wp else None, workspace),
        ("commands", "user", pp.user_cmds if wu else None, home),
        ("agents", "project", pp.proj_agents if wp else None, workspace),
        ("agents", "user", pp.user_agents if wu else None, home),
        ("workflows", "project", pp.proj_workflows if wp else None, workspace),
        ("workflows", "user", pp.user_workflows if wu else None, home),
        ("memory", "user", pp.user_memory if wu else None, home),
    ]
    for legacy_category, legacy_scope, legacy_root in pp.legacy:
        if legacy_category == "workflows" and (
            (legacy_scope == "project" and wp) or (legacy_scope == "user" and wu)
        ):
            document_roots.append((
                legacy_category, legacy_scope, legacy_root,
                workspace if legacy_scope == "project" else home,
            ))

    for cat, dsc, dpth, aroot in document_roots:
        if cat not in categories or dpth is None or not (dpth.exists() or dpth.is_symlink()):
            continue
        validate_contained(dpth, aroot, f"{cat}_dir")
        if not dpth.is_dir():
            continue
        for f in sorted(dpth.rglob("*")):
            validate_contained(f, aroot, f"{cat}:{f.name}")
            if not f.is_file():
                continue
            if is_excluded_asset(f, dpth):
                inv.excluded.append({"path": logical_path_str(f, workspace, home), "reason": "excluded_history_or_db_file"})
                continue
            inv.doc_items.append(DiscoveredDocItem(cat, f.relative_to(dpth).as_posix(), dsc, f, f.read_bytes(), pp.profile))

    if "hooks" in categories:
        for hsc, hpth, aroot in (("project", pp.proj_hooks if wp else None, workspace), ("user", pp.user_hooks if wu else None, home)):
            if hpth is None or not (hpth.exists() or hpth.is_symlink()):
                continue
            validate_contained(hpth, aroot, "hooks")
            if hpth.is_file():
                if pp.profile == "claude-code":
                    doc = load_jsonc(hpth.read_text(encoding="utf-8"))
                    if isinstance(doc, dict) and doc.get("hooks"):
                        inv.doc_items.append(DiscoveredDocItem("hooks", "claude-hooks.json", hsc, hpth, (json.dumps({"hooks": doc["hooks"]}, indent=2, ensure_ascii=False) + "\n").encode("utf-8"), pp.profile))
                else:
                    inv.doc_items.append(DiscoveredDocItem("hooks", hpth.name, hsc, hpth, hpth.read_bytes(), pp.profile))
            elif hpth.is_dir():
                for f in sorted(hpth.rglob("*")):
                    validate_contained(f, aroot, f"hook:{f.name}")
                    if f.is_file() and not is_excluded_asset(f, hpth):
                        inv.doc_items.append(DiscoveredDocItem("hooks", f.relative_to(hpth).as_posix(), hsc, f, f.read_bytes(), pp.profile))

    if "env_secrets" in categories and wp and workspace.is_dir():
        for entry in sorted(workspace.iterdir()):
            if (entry.is_file() or entry.is_symlink()) and (entry.name == ".env" or (entry.name.startswith(".env.") and entry.name != ".env.example")):
                validate_contained(entry, workspace, f"dotenv:{entry.name}")
                raw_env = entry.read_text(encoding="utf-8")
                inv.env_files.append(DiscoveredEnvFile(entry.name, "project", entry, raw_env, parse_dotenv_secrets(raw_env)[1]))

    return inv


# --- Migration Writers & Converters ---


def write_managed_file(
    dst: Path, data: bytes, *, has_secrets: bool, executable: bool = False, private_parent: bool = False,
    allow_git_tracked_secrets: bool = False, auth_root: Path | None = None,
    backups: BackupManager, warnings: list[dict[str, Any]], dry_run: bool,
) -> str | None:
    if auth_root is not None:
        validate_contained(dst, auth_root, f"write:{dst.name}")
    if has_secrets:
        gs = git_path_status(dst)
        if gs == "tracked" and not allow_git_tracked_secrets:
            raise SafetyRefusalError(
                "git_tracked_secret_refusal",
                f"Refusing to write literal secrets into Git-tracked file '{dst.name}'. "
                "Use --redact-secrets, --scope user, git rm --cached + .gitignore, or --allow-git-tracked-secrets.",
                {"path": str(dst)},
            )
        if gs == "untracked-unignored":
            msg = f"Wrote 0600 secret-bearing file '{dst.name}' inside a Git worktree; add it to .gitignore before committing."
            warnings.append({"code": "git_unignored_secret_file", "path": str(dst), "message": msg})
            warn_err(msg)
    if dst.exists() and dst.is_file() and dst.read_bytes() == data:
        if not dry_run and has_secrets:
            os.chmod(dst, 0o600)
        return None
    bpath = backups.backup_if_exists(dst)
    mode = (0o700 if executable else 0o600) if has_secrets else (0o755 if executable else 0o644)
    atomic_write_bytes(dst, data, mode=mode, private_parent=(private_parent or has_secrets), dry_run=dry_run)
    return bpath


def apply_rule_to_target(
    rule: DiscoveredRule, tpp: ProfilePaths, *, workspace: Path, home: Path | None = None,
    allow_broaden_scope: bool, redact_secrets: bool = False,
    backups: BackupManager, warnings: list[dict[str, Any]], dry_run: bool,
) -> dict[str, Any]:
    tp, is_p = tpp.profile, rule.scope == "project"
    root = workspace if is_p else (home or workspace)
    rule_body = _redact_document_text(rule.body) if redact_secrets else rule.body
    if tp == "zed" and is_p:
        sh = [c for c in (".rules", ".cursorrules", ".windsurfrules", ".clinerules", "CLAUDE.md", "GEMINI.md") if (workspace / c).exists() and (workspace / c) != rule.source_path]
        if sh:
            warnings.append({"code": "zed_first_match_shadow_check", "profile": "zed", "present_files": sh, "message": f"Zed uses first-match rule loading; check competing files: {', '.join(sh)}"})

    if rule.kind == "always_on":
        dst = tpp.proj_doc if is_p else tpp.user_doc
        if dst is None:
            rdir = tpp.proj_rules if is_p else tpp.user_rules
            if rdir is None:
                return act("instructions", rule.slug, "deferred", reason="no_target_rule_surface")
            dst = rdir / f"{rule.slug}.md"
            if dst.exists():
                return act("instructions", rule.slug, "noop" if dst.read_text(encoding="utf-8").strip() == rule_body.strip() else "conflict", dst)
            write_managed_file(dst, (rule_body.strip() + "\n").encode("utf-8"), has_secrets=_payload_has_secrets((rule_body.strip() + "\n").encode("utf-8")), auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
            return act("instructions", rule.slug, "migrated", dst)
        if dst.resolve(strict=False) == rule.source_path.resolve(strict=False):
            return act("instructions", rule.slug, "noop", dst)
        existing = dst.read_text(encoding="utf-8") if dst.exists() else ""
        merged, st = merge_markdown_section(existing, rule.slug, rule_body)
        if st in ("noop", "conflict"):
            return act("instructions", rule.slug, st, dst, reason="divergent_section_with_same_id" if st == "conflict" else None)
        write_managed_file(dst, merged.encode("utf-8"), has_secrets=_payload_has_secrets(merged.encode("utf-8")), auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
        return act("instructions", rule.slug, "migrated", dst)

    if rule.kind == "glob_scoped":
        rdir = tpp.proj_rules if is_p else tpp.user_rules
        rendered: str | None = None
        dst = None
        if tp == "claude-code" and rdir:
            dst, rendered = rdir / f"{rule.slug}.md", render_frontmatter({"paths": rule.globs}, rule_body)
        elif tp in ("vscode", "copilot-cli") and is_p and tpp.proj_rules:
            dst, rendered = tpp.proj_rules / f"{rule.slug}.instructions.md", render_frontmatter({"applyTo": ", ".join(rule.globs)}, rule_body)
        elif tp == "cursor" and rdir:
            gval: Any = rule.globs[0] if len(rule.globs) == 1 else ", ".join(rule.globs)
            dst, rendered = rdir / f"{rule.slug}.mdc", render_frontmatter({"globs": gval, "alwaysApply": False}, rule_body)
        elif tp == "windsurf" and is_p and tpp.proj_rules:
            dst, rendered = tpp.proj_rules / f"{rule.slug}.md", render_frontmatter({"trigger": "glob", "globs": ", ".join(rule.globs)}, rule_body)
        elif allow_broaden_scope and (tpp.proj_doc if is_p else tpp.user_doc):
            ddoc = (tpp.proj_doc if is_p else tpp.user_doc)
            assert ddoc is not None
            ex = ddoc.read_text(encoding="utf-8") if ddoc.exists() else ""
            merged, st = merge_markdown_section(ex, rule.slug, f"> Scoped guideline (`{', '.join(rule.globs)}`)\n\n{rule_body.strip()}\n")
            if st == "conflict":
                return act("instructions", rule.slug, "conflict", ddoc)
            if st == "added":
                write_managed_file(ddoc, merged.encode("utf-8"), has_secrets=_payload_has_secrets(merged.encode("utf-8")), auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
            return act("instructions", rule.slug, "noop" if st == "noop" else "migrated", ddoc, note="Broadened glob rule (--allow-broaden-scope)")
        else:
            pdst = workspace / ".migration-review" / "rules" / tp / f"{rule.slug}.md"
            write_managed_file(pdst, render_frontmatter({"source_globs": rule.globs, "target": tp}, rule_body).encode("utf-8"), has_secrets=_payload_has_secrets(render_frontmatter({"source_globs": rule.globs, "target": tp}, rule_body).encode("utf-8")), auth_root=workspace, private_parent=True, backups=backups, warnings=warnings, dry_run=dry_run)
            return act("instructions", rule.slug, "parked_draft", pdst, reason=f"{tp} lacks file-glob rule frontmatter; parked instead of widening scope")
        assert dst is not None and rendered is not None
        if dst.exists():
            return act("instructions", rule.slug, "noop" if dst.read_text(encoding="utf-8").strip() == rendered.strip() else "conflict", dst)
        write_managed_file(dst, rendered.encode("utf-8"), has_secrets=_payload_has_secrets(rendered.encode("utf-8")), auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
        return act("instructions", rule.slug, "migrated", dst, note="Converted glob-scoped rule; activation timing is host-specific")

    if rule.kind == "model_selected":
        rdir = tpp.proj_rules if is_p else tpp.user_rules
        if tp == "cursor" and rdir:
            dst, rendered = rdir / f"{rule.slug}.mdc", render_frontmatter({"description": rule.description, "alwaysApply": False}, rule_body)
        elif tp == "windsurf" and is_p and tpp.proj_rules:
            dst, rendered = tpp.proj_rules / f"{rule.slug}.md", render_frontmatter({"trigger": "model_decision", "description": rule.description}, rule_body)
        else:
            sdir = tpp.proj_skills if is_p else tpp.user_skills
            if sdir is None:
                return act("instructions", rule.slug, "deferred", reason="no_on_demand_surface")
            dst, rendered = sdir / rule.slug / "SKILL.md", render_frontmatter({"name": rule.slug, "description": rule.description or f"Rule {rule.slug}"}, rule_body)
        if dst.exists():
            return act("instructions", rule.slug, "noop" if dst.read_text(encoding="utf-8").strip() == rendered.strip() else "conflict", dst)
        write_managed_file(dst, rendered.encode("utf-8"), has_secrets=_payload_has_secrets(rendered.encode("utf-8")), auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
        return act("instructions", rule.slug, "migrated", dst, note="Converted model-selected rule to on-demand surface")

    # Manual rule -> manual-only Skill or explicit command (never always-on)
    if tp in ("claude-code", "cursor", "pi"):
        sdir = tpp.proj_skills if is_p else tpp.user_skills
        assert sdir is not None
        dst = sdir / rule.slug / "SKILL.md"
        rendered = render_frontmatter({"name": rule.slug, "description": f"Manual workflow /{rule.slug} (explicit invocation only).", "disable-model-invocation": True}, rule_body)
        if dst.exists():
            return act("instructions", rule.slug, "noop" if dst.read_text(encoding="utf-8").strip() == rendered.strip() else "conflict", dst)
        write_managed_file(dst, rendered.encode("utf-8"), has_secrets=_payload_has_secrets(rendered.encode("utf-8")), auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
        return act("instructions", rule.slug, "migrated", dst, note="Converted manual rule to manual-only Skill (disable-model-invocation: true)")

    cdir = tpp.proj_cmds if is_p else tpp.user_cmds
    if cdir is not None and tp != "gemini-cli":
        dst = cdir / f"{rule.slug}{'.prompt.md' if tp == 'vscode' else '.md'}"
        rendered = rule_body.strip() + "\n"
        if dst.exists():
            return act("instructions", rule.slug, "noop" if dst.read_text(encoding="utf-8").strip() == rendered.strip() else "conflict", dst)
        write_managed_file(dst, rendered.encode("utf-8"), has_secrets=_payload_has_secrets(rendered.encode("utf-8")), auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
        return act("instructions", rule.slug, "migrated", dst, note="Converted manual rule to explicit command/prompt")

    pdst = workspace / ".migration-review" / "manual-rules" / tp / f"{rule.slug}.md"
    write_managed_file(pdst, (rule_body.strip() + "\n").encode("utf-8"), has_secrets=_payload_has_secrets((rule_body.strip() + "\n").encode("utf-8")), auth_root=workspace, private_parent=True, backups=backups, warnings=warnings, dry_run=dry_run)
    return act("instructions", rule.slug, "parked_draft", pdst, reason=f"{tp} lacks verified manual-only flag; parked instead of making always-on")


def _payload_has_secrets(data: bytes) -> bool:
    """写入前判断这份内容里是否还留着凭据（token / Bearer / 认证头）。"""
    return _document_text_has_secrets(data.decode("utf-8", errors="replace"))


def _resource_contains_secrets(content: bytes) -> bool:
    """Classify a resource as secret-bearing before it is copied or written."""
    text = content.decode("utf-8", errors="replace")
    if parse_dotenv_secrets(text)[1]:
        return True
    return _document_text_has_secrets(text)


def _redact_resource(content: bytes) -> bytes:
    text = content.decode("utf-8", errors="replace")
    redacted, _ = parse_dotenv_secrets(text, redact=True)
    return _redact_document_text(redacted).encode("utf-8")


def apply_skill_to_target(
    skill: DiscoveredSkill, tpp: ProfilePaths, *, workspace: Path, home: Path,
    allow_git_tracked_secrets: bool, backups: BackupManager, warnings: list[dict[str, Any]], dry_run: bool,
    redact_secrets: bool = False,
) -> dict[str, Any]:
    sdir = tpp.proj_skills if skill.scope == "project" else tpp.user_skills
    if sdir is None:
        return act("skills", skill.name, "deferred", reason="no_target_skills_dir")
    dst_dir = sdir / skill.name
    auth_src = skill.auth_root or (workspace if skill.scope == "project" else home)
    if dst_dir.resolve(strict=False) == skill.directory.resolve(strict=False):
        return act("skills", skill.name, "noop", dst_dir)

    notes: list[str] = []
    alt_md: bytes | None = None
    if tpp.profile == "qwen-code" and "allowed-tools" in skill.meta and "allowedTools" not in skill.meta:
        nm = dict(skill.meta)
        tr = nm.pop("allowed-tools")
        nm["allowedTools"] = tr if isinstance(tr, list) else str(tr).split()
        alt_md = render_frontmatter(nm, skill.body).encode("utf-8")
        notes.append("Translated allowed-tools -> Qwen allowedTools; verify tool names")
    elif skill.source_profile == "qwen-code" and tpp.profile != "qwen-code" and "allowedTools" in skill.meta:
        notes.append("Source Skill uses Qwen allowedTools; verify destination tool enforcement")

    src_map: dict[Path, tuple[bytes, bool]] = {}
    for p in sorted(skill.directory.rglob("*")):
        validate_contained(p, auth_src, f"skill:{skill.name}")
        if p.is_file() and not is_excluded_asset(p, skill.directory):
            rel = p.relative_to(skill.directory)
            content = alt_md if (rel.as_posix() == "SKILL.md" and alt_md is not None) else p.read_bytes()
            is_ex = bool(p.stat().st_mode & stat.S_IXUSR) or ("scripts" in rel.parts and p.suffix in (".py", ".sh"))
            has_sec = _resource_contains_secrets(content)
            src_map[rel] = (content, is_ex, has_sec)

    if dst_dir.exists():
        dst_map = {p.relative_to(dst_dir): p.read_bytes() for p in sorted(dst_dir.rglob("*")) if p.is_file()}
        if {k: v[0] for k, v in src_map.items()} == dst_map:
            return act("skills", skill.name, "noop", dst_dir)
        return act("skills", skill.name, "conflict", dst_dir, reason="existing_skill_has_different_content")

    sroot = workspace if skill.scope == "project" else home
    for rel, (content, is_ex, has_sec) in src_map.items():
        data = content
        mark_secrets = has_sec
        if redact_secrets and has_sec:
            data = _redact_resource(content)
            mark_secrets = True
        write_managed_file(dst_dir / rel, data, has_secrets=mark_secrets, executable=is_ex, allow_git_tracked_secrets=allow_git_tracked_secrets, auth_root=sroot, backups=backups, warnings=warnings, dry_run=dry_run)
    return act("skills", skill.name, "migrated", dst_dir, note="; ".join(notes) if notes else None)


def _document_has_secrets(doc: Any) -> bool:
    if isinstance(doc, dict):
        for k, v in doc.items():
            if SENSITIVE_KEY_RE.search(str(k)) and not _looks_like_placeholder(v):
                return True
            if _document_has_secrets(v):
                return True
        return False
    if isinstance(doc, list):
        return any(_document_has_secrets(v) for v in doc)
    if isinstance(doc, str) and doc.strip():
        return bool(
            SECRET_VALUE_RE.search(doc)
            and not ENV_PLACEHOLDER_RE.match(doc)
            and not INPUT_PLACEHOLDER_RE.match(doc)
            and not BEARER_ENV_RE.match(doc),
        )
    return False


def _document_text_has_secrets(text: str) -> bool:
    # 凭据是否仍然留在文本里：token / Bearer 字面量 / 认证头三种形态。
    if INLINE_SECRET_RE.search(text):
        return True
    if BEARER_LITERAL_RE.search(text):
        return True
    for line in text.splitlines():
        m = HEADER_LITERAL_RE.match(line)
        if m is None:
            continue
        if m.group(1).lower() in HEADER_SECRET_KEYS and not ENV_PLACEHOLDER_RE.match(m.group(2)):
            return True
    return False


def _redact_document_text(text: str) -> str:
    # 把文本里的凭据换成占位符。
    out = INLINE_SECRET_RE.sub(D + "{REDACTED_SECRET}", text)
    out = BEARER_LITERAL_RE.sub("Bearer " + D + "{REDACTED_SECRET}", out)

    def _header(m: re.Match[str]) -> str:
        return m.group(1) + D + "{REDACTED_SECRET}"

    out = re.sub(
        r"(?im)^([ \t]*[\"\x27]?(?:authorization|proxy-authorization|x-api-key|api[-_]?key|"
        r"access[-_]?token|auth[-_]?token|token|secret|password|credential|cookie)"
        r"[\"\x27]?[ \t]*[:=][ \t]*[\"\x27]?)([^\"\x27\s,;]+)",
        _header, out,
    )
    return out


def _looks_like_placeholder(v: Any) -> bool:
    if not isinstance(v, str):
        return False
    return bool(
        ENV_PLACEHOLDER_RE.match(v) or INPUT_PLACEHOLDER_RE.match(v) or BEARER_ENV_RE.match(v)
    )


def apply_mcp_servers_to_file(
    servers: list[NormalizedMcp], *, dst_path: Path, dst_key_path: str, dst_style: str, dst_fmt: str,
    redact_secrets: bool, allow_git_tracked_secrets: bool, claude_local_fallback_file: Path | None,
    workspace: Path, auth_root: Path | None = None, backups: BackupManager, warnings: list[dict[str, Any]], dry_run: bool,
) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    if not servers:
        return results

    by_name: dict[str, list[NormalizedMcp]] = {}
    for s in servers:
        by_name.setdefault(s.name, []).append(s)
    incoming: list[NormalizedMcp] = []
    for name, cands in by_name.items():
        sig0 = cands[0].comparison_signature(redact_secrets=redact_secrets)
        if all(c.comparison_signature(redact_secrets=redact_secrets) == sig0 for c in cands[1:]):
            incoming.append(cands[0])
        else:
            hs, sl = cands[0].secret_summary()
            results.append(act("mcp", name, "conflict", dst_path, reason="conflicting_definitions_across_sources", has_secrets=hs, secrets=sl))
    if not incoming:
        return results

    if dst_style == "claude-code" and claude_local_fallback_file and not redact_secrets and not allow_git_tracked_secrets and git_path_status(dst_path) == "tracked":
        sec_srvs = [s for s in incoming if s.secret_summary()[0]]
        plain_srvs = [s for s in incoming if not s.secret_summary()[0]]
        if sec_srvs:
            ptr = f"/projects/{str(workspace.resolve()).replace('~', '~0').replace('/', '~1')}/mcpServers"
            msg = f"Target '{dst_path.name}' is Git-tracked; routed {len(sec_srvs)} secret-bearing MCP server(s) to untracked '{claude_local_fallback_file.name}' (projects[workspace].mcpServers)."
            warnings.append({"code": "routed_git_tracked_secret_mcp", "from": str(dst_path), "to": str(claude_local_fallback_file), "message": msg})
            warn_err(msg)
            routed = apply_mcp_servers_to_file(
                sec_srvs, dst_path=claude_local_fallback_file, dst_key_path=ptr, dst_style="claude-code", dst_fmt="json",
                redact_secrets=redact_secrets, allow_git_tracked_secrets=False, claude_local_fallback_file=None,
                workspace=workspace, auth_root=claude_local_fallback_file.parent, backups=backups, warnings=warnings, dry_run=dry_run,
            )
            for r in routed:
                r["routed_from_git_tracked"] = str(dst_path)
            results.extend(routed)
            incoming = plain_srvs
            if not incoming:
                return results

    afmt = ("toml" if dst_path.suffix.lower() == ".toml" else "json") if dst_fmt == "auto" else dst_fmt
    existing_map = read_mcp_file(dst_path, dst_key_path, "codex_toml" if afmt == "toml" else dst_style, fmt=afmt)
    any_sec = any(es.secret_summary()[0] for es in existing_map.values())
    if afmt == "toml" and dst_path.exists() and not any_sec:
        ex_text_for_scan = dst_path.read_text(encoding="utf-8")
        try:
            if _document_has_secrets(tomllib.loads(ex_text_for_scan)):
                any_sec = True
        except tomllib.TOMLDecodeError:
            if SECRET_VALUE_RE.search(ex_text_for_scan):
                any_sec = True

    if afmt == "toml":
        ex_text = dst_path.read_text(encoding="utf-8") if dst_path.exists() else ""
        blocks: list[str] = []
        for srv in incoming:
            hs, sl = srv.secret_summary()
            if srv.name in existing_map:
                same = existing_map[srv.name].comparison_signature(redact_secrets=redact_secrets) == srv.comparison_signature(redact_secrets=redact_secrets)
                results.append(act("mcp", srv.name, "noop" if same else "conflict", dst_path, reason=None if same else "existing_target_server_differs", has_secrets=hs and (not redact_secrets if same else True), secrets=sl))
                continue
            blk, notes, lit_out = render_codex_toml_server_block(srv, redact_secrets=redact_secrets)
            if blk is None:
                results.append(act("mcp", srv.name, "deferred", dst_path, reason="; ".join(notes) or "unrepresentable_in_codex_toml", has_secrets=hs, secrets=sl))
                continue
            blocks.append(blk)
            any_sec = any_sec or lit_out
            results.append(act("mcp", srv.name, "migrated", dst_path, has_secrets=lit_out, secrets=sl, note="; ".join(notes) if notes else None))
        if blocks:
            sep = "" if not ex_text else ("\n" if ex_text.endswith("\n\n") else ("\n" if ex_text.endswith("\n") else "\n\n"))
            final_toml = ex_text + sep + "\n".join(b.rstrip("\n") + "\n" for b in blocks)
            tomllib.loads(final_toml)
            write_managed_file(dst_path, final_toml.encode("utf-8"), has_secrets=any_sec, allow_git_tracked_secrets=allow_git_tracked_secrets, auth_root=auth_root, backups=backups, warnings=warnings, dry_run=dry_run)
        return results

    doc: dict[str, Any] = {}
    if dst_path.exists() and dst_path.is_file():
        loaded = load_jsonc(dst_path.read_text(encoding="utf-8"))
        if isinstance(loaded, dict):
            doc = loaded
    eff_kp = "mcp.servers" if (dst_style == "opencode" and dst_key_path == "mcp" and isinstance(doc.get("mcp"), dict) and isinstance(doc["mcp"].get("servers"), dict)) else dst_key_path
    parts = split_key_path(eff_kp)
    container = dict(get_nested_dict(doc, parts))
    changed = False
    for srv in incoming:
        hs, sl = srv.secret_summary()
        if srv.name in existing_map:
            same = existing_map[srv.name].comparison_signature(redact_secrets=redact_secrets) == srv.comparison_signature(redact_secrets=redact_secrets)
            results.append(act("mcp", srv.name, "noop" if same else "conflict", dst_path, reason=None if same else "existing_target_server_differs", has_secrets=hs and (not redact_secrets if same else True), secrets=sl))
            continue
        try:
            ed, notes = serialize_mcp_for_json_style(srv, dst_style, redact_secrets=redact_secrets)
        except UnrepresentableMcpServer as exc:
            results.append(act("mcp", srv.name, "deferred", dst_path, reason=str(exc), has_secrets=hs, secrets=sl))
            continue
        container[srv.name] = ed
        changed = True
        wrote_s = hs and not redact_secrets
        any_sec = any_sec or wrote_s or _document_has_secrets(doc)
        results.append(act("mcp", srv.name, "migrated", dst_path, has_secrets=wrote_s, secrets=sl, note="; ".join(notes) if notes else None))
    if changed:
        set_nested_dict(doc, parts, container)
        serialized = json.dumps(doc, indent=2, ensure_ascii=False) + "\n"
        json.loads(serialized)
        write_managed_file(dst_path, serialized.encode("utf-8"), has_secrets=any_sec, allow_git_tracked_secrets=allow_git_tracked_secrets, auth_root=auth_root, backups=backups, warnings=warnings, dry_run=dry_run)
    return results


def apply_doc_item_to_target(
    item: DiscoveredDocItem, tpp: ProfilePaths, *, workspace: Path, home: Path | None = None,
    activate_hooks: bool, redact_secrets: bool = False,
    backups: BackupManager, warnings: list[dict[str, Any]], dry_run: bool,
) -> dict[str, Any]:
    is_p, tp = item.scope == "project", tpp.profile
    doc_text = item.content.decode("utf-8", errors="replace")
    if redact_secrets:
        doc_text = _redact_document_text(doc_text)
    doc_content = doc_text.encode("utf-8")
    doc_has_secrets = _document_text_has_secrets(doc_text)
    root = workspace if is_p else (home or workspace)
    if item.category == "hooks":
        if activate_hooks:
            hd = tpp.proj_hooks if is_p else tpp.user_hooks
            if hd is not None and tp != "claude-code":
                dst = (hd / item.name) if ((hd.exists() and hd.is_dir()) or not hd.suffix) else hd
                if dst.exists():
                    return act("hooks", item.name, "noop" if dst.read_bytes() == doc_content else "conflict", dst)
                write_managed_file(dst, doc_content, has_secrets=doc_has_secrets, auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
                return act("hooks", item.name, "migrated", dst, note="Activated hook via --activate-hooks")
        park = workspace / ".migration-review" / "hooks" / tp / item.scope / item.name
        write_managed_file(park, doc_content, has_secrets=doc_has_secrets, auth_root=workspace, private_parent=True, backups=backups, warnings=warnings, dry_run=dry_run)
        return act("hooks", item.name, "parked_draft", park, reason="Executable hooks stay parked in .migration-review/ until explicitly approved")

    dst_dir: Path | None = None
    if item.category == "commands":
        dst_dir = tpp.proj_cmds if is_p else tpp.user_cmds
        if dst_dir is None or (tp == "gemini-cli" and not item.name.endswith(".toml")) or (item.source_profile == "gemini-cli" and tp != "gemini-cli"):
            sdir = tpp.proj_skills if is_p else tpp.user_skills
            if sdir is not None and item.name.endswith(".md"):
                cslug = slugify(Path(item.name).stem)
                dst = sdir / cslug / "SKILL.md"
                text = doc_text
                src_meta, body = parse_frontmatter(text)
                carry = {k: v for k, v in src_meta.items() if k in COMMAND_ENFORCEABLE_KEYS}
                lost = [k for k in src_meta if k not in carry and k not in ("name", "description")]
                rnd = render_frontmatter({"name": cslug, "description": f"Command /{cslug}", "disable-model-invocation": True, **carry}, body).encode("utf-8")
                if lost:
                    park = workspace / ".migration-review" / "commands" / tp / item.name
                    write_managed_file(park, doc_content, has_secrets=doc_has_secrets, auth_root=workspace, private_parent=True, backups=backups, warnings=warnings, dry_run=dry_run)
                    return act("commands", item.name, "parked_draft", park, reason=f"command restrictions not representable as Skill: {', '.join(sorted(lost))}")
                if dst.exists():
                    return act("commands", item.name, "noop" if dst.read_bytes() == rnd else "conflict", dst)
                write_managed_file(dst, rnd, has_secrets=doc_has_secrets, auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
                return act("commands", item.name, "migrated", dst, note="Mapped command to manual-only Skill")
            park = workspace / ".migration-review" / "commands" / tp / item.name
            write_managed_file(park, doc_content, has_secrets=doc_has_secrets, auth_root=workspace, private_parent=True, backups=backups, warnings=warnings, dry_run=dry_run)
            return act("commands", item.name, "parked_draft", park, reason="Command schema differs across source/target")
    elif item.category == "agents":
        dst_dir = tpp.proj_agents if is_p else tpp.user_agents
    elif item.category == "workflows":
        dst_dir = tpp.proj_workflows if is_p else tpp.user_workflows
        if dst_dir is None:
            sdir = tpp.proj_skills if is_p else tpp.user_skills
            if sdir is not None and item.name.endswith(".md"):
                wslug = slugify(Path(item.name).stem)
                dst = sdir / wslug / "SKILL.md"
                _, body = parse_frontmatter(doc_text)
                rnd = render_frontmatter({"name": wslug, "description": f"Workflow /{wslug}", "disable-model-invocation": True}, body).encode("utf-8")
                if dst.exists():
                    return act("workflows", item.name, "noop" if dst.read_bytes() == rnd else "conflict", dst)
                write_managed_file(dst, rnd, has_secrets=doc_has_secrets, auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
                return act("workflows", item.name, "migrated", dst, note="Mapped workflow to manual-only Skill")
    elif item.category == "memory":
        dst_dir = tpp.user_memory
        if dst_dir is None and tpp.user_doc is not None:
            ex = tpp.user_doc.read_text(encoding="utf-8") if tpp.user_doc.exists() else ""
            merged, st = merge_markdown_section(ex, slugify(f"memory-{Path(item.name).stem}"), doc_text)
            if st == "conflict":
                return act("memory", item.name, "conflict", tpp.user_doc)
            if st == "added":
                write_managed_file(tpp.user_doc, merged.encode("utf-8"), has_secrets=doc_has_secrets, auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
            return act("memory", item.name, "noop" if st == "noop" else "migrated", tpp.user_doc)

    if dst_dir is None:
        park = workspace / ".migration-review" / item.category / tp / item.name
        write_managed_file(park, doc_content, has_secrets=doc_has_secrets, auth_root=workspace, private_parent=True, backups=backups, warnings=warnings, dry_run=dry_run)
        return act(item.category, item.name, "parked_draft", park, reason=f"No direct {item.category} directory on {tp}")

    dst_name = item.name
    if tp == "vscode":
        if item.category == "commands" and not dst_name.endswith(".prompt.md"):
            dst_name = dst_name[:-3] + ".prompt.md" if dst_name.endswith(".md") else dst_name + ".prompt.md"
        elif item.category == "agents" and not dst_name.endswith(".agent.md"):
            dst_name = dst_name[:-3] + ".agent.md" if dst_name.endswith(".md") else dst_name + ".agent.md"
    dst = dst_dir / dst_name
    if dst.resolve(strict=False) == item.path.resolve(strict=False):
        return act(item.category, item.name, "noop", dst)
    if dst.exists():
        return act(item.category, item.name, "noop" if dst.read_bytes() == doc_content else "conflict", dst, reason=None if dst.read_bytes() == doc_content else "existing_target_file_differs")
    write_managed_file(dst, doc_content, has_secrets=doc_has_secrets, auth_root=root, backups=backups, warnings=warnings, dry_run=dry_run)
    return act(item.category, item.name, "migrated", dst)


# --- Subcommands: inspect, migrate, export-device, import-device, patch-mcp ---


def select_profiles(raw: str, workspace: Path, home: Path, scope: str, categories: set[str]) -> list[ProfileInventory]:
    if not raw or raw.strip().lower() == "all":
        return [i for i in (discover_profile(p, workspace, home, scope, categories) for p in CANONICAL_PROFILES) if i.has_any() or i.excluded]
    chosen = list(dict.fromkeys(resolve_profile(p) for p in raw.split(",") if p.strip()))
    return [discover_profile(p, workspace, home, scope, categories) for p in chosen]


def cmd_inspect(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    ws, home = Path(args.workspace).expanduser().resolve(), Path(args.home).expanduser().resolve()
    invs = select_profiles(args.profiles, ws, home, args.scope, parse_categories(args.categories))
    profiles_out = []
    for inv in invs:
        mcp_items = [
            {"name": s.name, "scope": sc, "transport": s.transport, "has_secrets": s.secret_summary()[0], "secrets": s.secret_summary()[1], "stripped_grants": s.stripped_grants}
            for sc in ("project", "user") for s in inv.mcp_servers[sc]
        ]
        profiles_out.append({
            "profile": inv.profile,
            "instructions": [{"id": r.slug, "scope": r.scope, "kind": r.kind, "globs": r.globs, "source": logical_path_str(r.source_path, ws, home)} for r in inv.rules],
            "skills": [{"name": s.name, "scope": s.scope, "sha256_prefix": s.digest[:8], "source": logical_path_str(s.directory, ws, home)} for s in inv.skills],
            "mcp": mcp_items,
            "other_items": [{"category": d.category, "name": d.name, "scope": d.scope, "source": logical_path_str(d.path, ws, home)} for d in inv.doc_items],
            "env_secrets": [{"file": e.name, "scope": e.scope, "has_secrets": bool(e.secrets), "secrets": e.secrets} for e in inv.env_files],
            "excluded": inv.excluded,
        })
    return {"ok": True, "command": "inspect", "version": SCHEMA_VERSION, "scope": args.scope, "profiles": profiles_out}, 0


def execute_inventories_to_targets(
    invs: list[ProfileInventory], target_profiles: list[str], *, workspace: Path, home: Path, scope: str,
    redact_secrets: bool, activate_hooks: bool, allow_broaden_scope: bool, allow_git_tracked_secrets: bool,
    strict_conflicts: bool, backup_dir: Path | None, dry_run: bool, is_bundle_import: bool = False,
) -> tuple[dict[str, Any], int]:
    backups = BackupManager(backup_dir, home=home, workspace=workspace, dry_run=dry_run)
    warnings: list[dict[str, Any]] = []
    actions: list[dict[str, Any]] = []
    excluded_all: list[dict[str, str]] = []
    seen_ex: set[str] = set()
    for inv in invs:
        for ex in inv.excluded:
            if ex["path"] not in seen_ex:
                seen_ex.add(ex["path"])
                excluded_all.append(ex)

    for tprof in target_profiles:
        tpp = get_profile_paths(tprof, workspace, home)
        active = invs if is_bundle_import else ([i for i in invs if i.profile != tprof] if len(invs) > 1 else invs)

        seen_rules: dict[tuple[str, str, str], DiscoveredRule] = {}
        for inv in active:
            for r in inv.rules:
                rk = (r.scope, r.kind, r.slug)
                if rk in seen_rules:
                    if seen_rules[rk].body.strip() != r.body.strip() or seen_rules[rk].globs != r.globs:
                        actions.append(act("instructions", r.slug, "conflict", target_profile=tprof, reason="conflicting_rules_across_sources"))
                    continue
                seen_rules[rk] = r
                res = apply_rule_to_target(r, tpp, workspace=workspace, home=home, allow_broaden_scope=allow_broaden_scope, redact_secrets=redact_secrets, backups=backups, warnings=warnings, dry_run=dry_run)
                res["target_profile"] = tprof
                actions.append(res)

        sk_groups: dict[tuple[str, str], list[DiscoveredSkill]] = {}
        for inv in active:
            for s in inv.skills:
                sk_groups.setdefault((s.scope, s.name), []).append(s)
        for (_, sname), scands in sk_groups.items():
            if any(c.digest != scands[0].digest for c in scands[1:]):
                actions.append(act("skills", sname, "conflict", target_profile=tprof, reason="conflicting_skill_variants_across_sources"))
                continue
            res = apply_skill_to_target(scands[0], tpp, workspace=workspace, home=home, allow_git_tracked_secrets=allow_git_tracked_secrets, backups=backups, warnings=warnings, dry_run=dry_run, redact_secrets=redact_secrets)
            res["target_profile"] = tprof
            actions.append(res)

        for msc in ("project", "user"):
            if scope not in (msc, "all"):
                continue
            in_mcp = [srv for inv in active for srv in inv.mcp_servers[msc]]
            if not in_mcp:
                continue
            dmp = tpp.proj_mcp if msc == "project" else tpp.user_mcp
            dmk = tpp.proj_mcp_key if msc == "project" else tpp.user_mcp_key
            dms = tpp.proj_mcp_style if msc == "project" else tpp.user_mcp_style
            if dmp is None:
                if msc == "project" and tpp.user_mcp is not None and scope == "all":
                    dmp, dmk, dms = tpp.user_mcp, tpp.user_mcp_key, tpp.user_mcp_style
                    warnings.append({"code": "mcp_routed_to_user_scope", "profile": tprof, "message": f"{tprof} stores MCP at user scope ({dmp.name}); merged there."})
                else:
                    for srv in in_mcp:
                        hs, sl = srv.secret_summary()
                        actions.append(act("mcp", srv.name, "deferred", target_profile=tprof, reason=f"{tprof} has no verified {msc}-scope MCP file", has_secrets=hs, secrets=sl))
                    continue
            for r in apply_mcp_servers_to_file(
                in_mcp, dst_path=dmp, dst_key_path=dmk, dst_style=dms, dst_fmt="auto", redact_secrets=redact_secrets,
                allow_git_tracked_secrets=allow_git_tracked_secrets, claude_local_fallback_file=(tpp.user_mcp if (tprof == "claude-code" and msc == "project") else None),
                workspace=workspace, auth_root=(workspace if msc == "project" and dmp == tpp.proj_mcp else home), backups=backups, warnings=warnings, dry_run=dry_run,
            ):
                r["target_profile"] = tprof
                actions.append(r)

        seen_docs: set[tuple[str, str, str]] = set()
        for inv in active:
            for item in inv.doc_items:
                dk = (item.category, item.scope, item.name)
                if dk not in seen_docs:
                    seen_docs.add(dk)
                    res = apply_doc_item_to_target(item, tpp, workspace=workspace, home=home, activate_hooks=activate_hooks, redact_secrets=redact_secrets, backups=backups, warnings=warnings, dry_run=dry_run)
                    res["target_profile"] = tprof
                    actions.append(res)

    seen_env: set[str] = set()
    for inv in invs:
        for ef in inv.env_files:
            if ef.name in seen_env:
                continue
            seen_env.add(ef.name)
            dst_env = workspace / ef.name
            out_env, sec_list = parse_dotenv_secrets(ef.raw_text, redact=redact_secrets)
            hs = bool(sec_list) and not redact_secrets
            if dst_env.resolve(strict=False) == ef.path.resolve(strict=False):
                if not dry_run and hs and dst_env.exists():
                    os.chmod(dst_env, 0o600)
                actions.append(act("env_secrets", ef.name, "noop", dst_env, has_secrets=hs, secrets=sec_list))
            elif dst_env.exists() and dst_env.read_text(encoding="utf-8") != out_env:
                actions.append(act("env_secrets", ef.name, "conflict", dst_env, has_secrets=bool(sec_list), secrets=sec_list))
            else:
                write_managed_file(dst_env, out_env.encode("utf-8"), has_secrets=hs, allow_git_tracked_secrets=allow_git_tracked_secrets, auth_root=workspace, backups=backups, warnings=warnings, dry_run=dry_run)
                actions.append(act("env_secrets", ef.name, "migrated", dst_env, has_secrets=hs, secrets=sec_list))

    unresolved = [a for a in actions if a["outcome"] in ("conflict", "deferred", "parked_draft")]
    counts = {k: sum(1 for a in actions if a["outcome"] == k) for k in ("migrated", "noop", "conflict", "parked_draft", "deferred")}
    return {
        "ok": True, "dry_run": dry_run, "redact_secrets": redact_secrets, "summary": counts,
        "actions": actions, "conflicts": [a for a in actions if a["outcome"] == "conflict"],
        "parked_or_deferred": [a for a in actions if a["outcome"] in ("parked_draft", "deferred")],
        "backups": [str(p) for p in backups.backed_up.values()], "warnings": warnings, "excluded": excluded_all,
        "verification": {"level": "structural_and_syntax_only", "native_ide_runtime": "not-run"},
    }, (3 if (strict_conflicts and unresolved) else 0)


def cmd_migrate(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    ws, home = Path(args.workspace).expanduser().resolve(), Path(args.home).expanduser().resolve()
    targets = [resolve_profile(t) for t in args.target.split(",") if t.strip()]
    if not targets:
        raise SafetyRefusalError("invalid_target", "At least one --target profile is required.")
    invs = select_profiles(args.source, ws, home, args.scope, parse_categories(args.categories))
    payload, code = execute_inventories_to_targets(
        invs, targets, workspace=ws, home=home, scope=args.scope, redact_secrets=args.redact_secrets,
        activate_hooks=args.activate_hooks, allow_broaden_scope=args.allow_broaden_scope,
        allow_git_tracked_secrets=args.allow_git_tracked_secrets, strict_conflicts=args.strict_conflicts,
        backup_dir=Path(args.backup_dir) if args.backup_dir else None, dry_run=args.dry_run,
    )
    payload["command"], payload["version"] = "migrate", SCHEMA_VERSION
    return payload, code


def cmd_export_device(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    ws, home = Path(args.workspace).expanduser().resolve(), Path(args.home).expanduser().resolve()
    out_dir = Path(args.output).expanduser().resolve(strict=False)
    if out_dir.exists() or out_dir.is_symlink():
        raise SafetyRefusalError("output_already_exists", f"Refusing to overwrite existing transfer path: {out_dir}")
    if is_inside_autoload_dir(out_dir, ws, home):
        raise SafetyRefusalError("unsafe_output_dir", f"Transfer folder sits inside an auto-loaded context path: {out_dir}")

    invs = select_profiles(args.profiles, ws, home, args.scope, parse_categories(args.categories))
    entries: list[dict[str, Any]] = []
    excluded_all: list[dict[str, str]] = []
    seen_ex, seen_env = set(), set()

    if not args.dry_run:
        ensure_dir(out_dir / "files", private=True, dry_run=False)

    def _stage(rel: str, data: bytes, meta: dict[str, Any], exec_bit: bool = False) -> None:
        mode = 0o700 if exec_bit else 0o600
        if not args.dry_run:
            atomic_write_bytes(out_dir / rel, data, mode=mode, private_parent=True, dry_run=False)
        entries.append({"bundle_path": rel, "sha256": sha256_bytes(data), "mode": oct(mode), **meta})

    for inv in invs:
        prof = inv.profile
        for ex in inv.excluded:
            if ex["path"] not in seen_ex:
                seen_ex.add(ex["path"])
                excluded_all.append(ex)
        for idx, r in enumerate(inv.rules):
            rule_bytes = r.source_path.read_bytes()
            rule_has_secrets = _resource_contains_secrets(rule_bytes)
            rule_data = _redact_resource(rule_bytes) if (args.redact_secrets and rule_has_secrets) else rule_bytes
            _stage(f"files/{prof}/{r.scope}/instructions/{idx:02d}-{r.slug}-{r.source_path.name}", rule_data, {
                "profile": prof, "category": "instructions", "scope": r.scope, "id": r.slug,
                "rule_kind": r.kind, "globs": r.globs, "description": r.description,
                "logical_source": logical_path_str(r.source_path, ws, home),
                "has_secrets": rule_has_secrets and not args.redact_secrets, "secrets": [],
            })
        for sk in inv.skills:
            auth_s = ws if sk.scope == "project" else home
            for p in sorted(sk.directory.rglob("*")):
                validate_contained(p, auth_s, f"skill:{sk.name}")
                if p.is_file() and not is_excluded_asset(p, sk.directory):
                    irel = p.relative_to(sk.directory).as_posix()
                    is_ex = bool(p.stat().st_mode & stat.S_IXUSR) or ("scripts" in p.relative_to(sk.directory).parts and p.suffix in (".py", ".sh"))
                    content = p.read_bytes()
                    has_sec = _resource_contains_secrets(content)
                    _, dotenv_secrets = parse_dotenv_secrets(content.decode("utf-8", errors="replace"))
                    data = content
                    if args.redact_secrets and has_sec:
                        data = _redact_resource(content)
                    _stage(f"files/{prof}/{sk.scope}/skills/{sk.name}/{irel}", data, {
                        "profile": prof, "category": "skills", "scope": sk.scope, "id": sk.name,
                        "skill_rel_path": irel, "logical_source": logical_path_str(p, ws, home),
                        "has_secrets": has_sec and not args.redact_secrets, "secrets": dotenv_secrets,
                    }, exec_bit=is_ex)
        for msc in ("project", "user"):
            srvs = inv.mcp_servers[msc]
            if not srvs:
                continue
            emap, asec, any_s = {}, [], False
            for srv in srvs:
                hs, sl = srv.secret_summary()
                any_s = any_s or (hs and not args.redact_secrets)
                asec.extend(sl)
                emap[srv.name] = serialize_mcp_for_json_style(srv, "mcpServers", redact_secrets=args.redact_secrets)[0]
            _stage(f"files/{prof}/{msc}/mcp/selected-mcp.json", (json.dumps({"mcpServers": emap}, indent=2, ensure_ascii=False) + "\n").encode("utf-8"), {
                "profile": prof, "category": "mcp", "scope": msc, "id": f"{prof}-{msc}-mcp",
                "server_names": [s.name for s in srvs], "has_secrets": any_s, "secrets": asec,
            })
        for d in inv.doc_items:
            rel = f"review/hooks/{prof}-{d.scope}-{d.name}" if d.category == "hooks" else f"files/{prof}/{d.scope}/{d.category}/{d.name}"
            doc_has_secrets = _resource_contains_secrets(d.content)
            doc_data = _redact_resource(d.content) if (args.redact_secrets and doc_has_secrets) else d.content
            _stage(rel, doc_data, {
                "profile": prof, "category": d.category, "scope": d.scope, "id": d.name,
                "logical_source": logical_path_str(d.path, ws, home),
                "has_secrets": doc_has_secrets and not args.redact_secrets, "secrets": [],
            })
        for ef in inv.env_files:
            if ef.name not in seen_env:
                seen_env.add(ef.name)
                eout, sl = parse_dotenv_secrets(ef.raw_text, redact=args.redact_secrets)
                _stage(f"files/workspace/project/env/{ef.name}", eout.encode("utf-8"), {
                    "profile": "workspace", "category": "env_secrets", "scope": "project", "id": ef.name,
                    "logical_source": f"$WORKSPACE/{ef.name}", "has_secrets": bool(sl) and not args.redact_secrets, "secrets": sl,
                })

    md = [
        "# Context transfer", "",
        "This folder contains reviewed AI coding context, not an installer or auto-run script.",
        "On the destination machine, run `import-device` (or inspect and map manually).",
        "All files in this folder use `0700`/`0600` private permissions; **no raw secret values appear in this document**.", "",
        f"- Schema version: `{SCHEMA_VERSION}`",
        f"- Source profiles: `{', '.join(i.profile for i in invs) or 'none'}`",
        f"- Requested scope: `{args.scope}`",
        f"- Secret policy: `{'redacted (--redact-secrets)' if args.redact_secrets else 'out-of-band in 0600 files (fingerprinted below)'}`", "",
        "## Included items", "",
        "| Bundle file | Profile / Scope | Category | Secret keys (SHA-256[:8] only) |",
        "| --- | --- | --- | --- |",
        *[
            "| `{bp}` | `{pr}` / `{sc}` | `{ct}` | {sec} |".format(
                bp=m["bundle_path"],
                pr=m["profile"],
                sc=m["scope"],
                ct=m["category"],
                sec=", ".join(f"`{s['name']}` (`{s['sha256_prefix']}`)" for s in m.get("secrets", [])) or "none",
            )
            for m in entries
        ],
        "", "## Excluded non-portable state", "",
        *([f"- `{ex['path']}` ({ex['reason']})" for ex in excluded_all] or ["- Chat histories, transcripts, SQLite/LevelDB databases, caches, OAuth cookies, and trust grants."]),
        "", "## Verification", "",
        "- Exported syntax & SHA-256 manifest: verified.",
        "- Destination host discovery & live MCP connection: not-run.", "",
    ]
    manifest = {"schema_version": 1, "tool_version": SCHEMA_VERSION, "scope": args.scope, "redact_secrets": args.redact_secrets, "profiles": [i.profile for i in invs], "entries": entries, "excluded": excluded_all}
    if not args.dry_run:
        atomic_write_bytes(out_dir / "MIGRATION.md", "\n".join(md).encode("utf-8"), mode=0o600, private_parent=True, dry_run=False)
        atomic_write_bytes(out_dir / "manifest.json", (json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode("utf-8"), mode=0o600, private_parent=True, dry_run=False)

    return {
        "ok": True, "command": "export-device", "version": SCHEMA_VERSION, "dry_run": args.dry_run,
        "redact_secrets": args.redact_secrets, "output_dir": str(out_dir), "exported_count": len(entries),
        "profiles": [i.profile for i in invs],
        "entries": [{"bundle_path": m["bundle_path"], "profile": m["profile"], "category": m["category"], "scope": m["scope"], "has_secrets": m["has_secrets"], "secrets": m["secrets"], "sha256_prefix": m["sha256"][:8]} for m in entries],
        "excluded": excluded_all,
    }, 0


def cmd_import_device(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    in_dir = Path(args.input).expanduser().resolve()
    if not in_dir.is_dir() or in_dir.is_symlink():
        raise SafetyRefusalError("invalid_input_dir", f"Transfer input must be an ordinary directory: {in_dir}")
    mpath = in_dir / "manifest.json"
    validate_contained(mpath, in_dir, "manifest.json")
    if not mpath.is_file():
        raise SafetyRefusalError("missing_manifest", f"manifest.json not found in {in_dir}")
    manifest = json.loads(mpath.read_text(encoding="utf-8"))
    entries = manifest.get("entries")
    if not isinstance(entries, list):
        raise SafetyRefusalError("corrupt_manifest", "Invalid entries list in manifest.json")

    ws, home = Path(args.workspace).expanduser().resolve(), Path(args.home).expanduser().resolve()
    verified: dict[str, bytes] = {}
    for e in entries:
        brel = str(e.get("bundle_path", ""))
        bp = in_dir / brel
        validate_contained(bp, in_dir, f"bundle:{brel}")
        if not bp.is_file():
            raise SafetyRefusalError("missing_bundle_file", f"Missing transfer file: {brel}")
        data = bp.read_bytes()
        if e.get("sha256") and sha256_bytes(data) != e["sha256"]:
            raise SafetyRefusalError("checksum_mismatch", f"SHA-256 mismatch for transfer file '{brel}'", {"bundle_path": brel})
        verified[brel] = data

    inv_by_prof: dict[str, ProfileInventory] = {}
    skill_groups: dict[tuple[str, str, str], Path] = {}
    default_prof = manifest["profiles"][0] if manifest.get("profiles") else "cursor"
    for e in entries:
        prof, cat, esc, brel = str(e["profile"]), str(e["category"]), str(e["scope"]), str(e["bundle_path"])
        if args.scope != "all" and esc != args.scope:
            continue
        bp, data = in_dir / brel, verified[brel]
        if cat == "env_secrets":
            rt = data.decode("utf-8")
            inv_by_prof.setdefault(default_prof, ProfileInventory(default_prof)).env_files.append(DiscoveredEnvFile(e["id"], "project", bp, rt, parse_dotenv_secrets(rt)[1]))
            continue
        pinv = inv_by_prof.setdefault(prof, ProfileInventory(prof))
        if cat == "instructions":
            txt = data.decode("utf-8")
            _, bdy = parse_frontmatter(txt) if (e.get("rule_kind") != "always_on" or txt.startswith("---")) else ({}, txt)
            pinv.rules.append(DiscoveredRule(str(e["id"]), esc, str(e.get("rule_kind", "always_on")), bdy if bdy.strip() else txt, list(e.get("globs") or []), str(e.get("description") or ""), bp, prof))
        elif cat == "skills":
            skill_groups[(prof, esc, str(e["id"]))] = in_dir / f"files/{prof}/{esc}/skills/{e['id']}"
        elif cat == "mcp":
            for srv in read_mcp_file(bp, "mcpServers", "mcpServers", fmt="json").values():
                srv.source_profile = prof
                pinv.mcp_servers[esc].append(srv)
        else:
            pinv.doc_items.append(DiscoveredDocItem(cat, str(e["id"]), esc, bp, data, prof))

    for (prof, esc, sname), sk_dir in sorted(skill_groups.items()):
        smd = sk_dir / "SKILL.md"
        if smd.is_file():
            meta, bdy = parse_frontmatter(smd.read_text(encoding="utf-8"))
            inv_by_prof.setdefault(prof, ProfileInventory(prof)).skills.append(DiscoveredSkill(sname, esc, sk_dir, meta, bdy, compute_skill_digest(sk_dir, in_dir), prof, auth_root=in_dir))

    bdir = Path(args.backup_dir) if args.backup_dir else None
    raw_t = (args.target or "same").strip()
    if raw_t.lower() == "same":
        comb_act, comb_warn, comb_bak, fcode = [], [], [], 0
        for prof, pinv in inv_by_prof.items():
            sp, sc = execute_inventories_to_targets(
                [pinv], [prof], workspace=ws, home=home, scope=args.scope, redact_secrets=args.redact_secrets,
                activate_hooks=args.activate_hooks, allow_broaden_scope=args.allow_broaden_scope,
                allow_git_tracked_secrets=args.allow_git_tracked_secrets, strict_conflicts=args.strict_conflicts,
                backup_dir=bdir, dry_run=args.dry_run,
            )
            comb_act.extend(sp["actions"])
            comb_warn.extend(sp["warnings"])
            comb_bak.extend(b for b in sp["backups"] if b not in comb_bak)
            fcode = max(fcode, sc)
        counts = {k: sum(1 for a in comb_act if a["outcome"] == k) for k in ("migrated", "noop", "conflict", "parked_draft", "deferred")}
        return {
            "ok": True, "command": "import-device", "version": SCHEMA_VERSION, "dry_run": args.dry_run,
            "target": "same", "redact_secrets": args.redact_secrets, "summary": counts, "actions": comb_act,
            "conflicts": [a for a in comb_act if a["outcome"] == "conflict"],
            "parked_or_deferred": [a for a in comb_act if a["outcome"] in ("parked_draft", "deferred")],
            "backups": comb_bak, "warnings": comb_warn,
            "verification": {"manifest_sha256": "verified", "native_ide_runtime": "not-run"},
        }, fcode

    targets = [resolve_profile(t) for t in raw_t.split(",") if t.strip()]
    payload, code = execute_inventories_to_targets(
        list(inv_by_prof.values()), targets, workspace=ws, home=home, scope=args.scope, redact_secrets=args.redact_secrets,
        activate_hooks=args.activate_hooks, allow_broaden_scope=args.allow_broaden_scope,
        allow_git_tracked_secrets=args.allow_git_tracked_secrets, strict_conflicts=args.strict_conflicts,
        backup_dir=bdir, dry_run=args.dry_run, is_bundle_import=True,
    )
    payload["command"], payload["version"] = "import-device", SCHEMA_VERSION
    return payload, code


def infer_mcp_style_from_key(key_path: str, fmt: str, path: Path) -> str:
    if fmt == "toml" or path.suffix.lower() == ".toml":
        return "codex_toml"
    parts = split_key_path(key_path)
    leaf = parts[-1] if parts else ""
    if parts == ["mcp", "servers"] or leaf == "mcp" or "opencode" in path.name:
        return "opencode"
    if parts == ["servers"] or (".vscode" in path.parts and leaf == "servers"):
        return "vscode"
    if leaf == "context_servers":
        return "zed"
    if ".gemini" in path.parts and path.name == "settings.json":
        return "gemini-cli"
    if "windsurf" in path.parts:
        return "windsurf"
    if "antigravity" in path.parts:
        return "antigravity"
    return "mcpServers"


def cmd_patch_mcp(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    src_f = Path(args.src_file).expanduser().resolve()
    dst_f = Path(args.dst_file).expanduser().resolve(strict=False)
    ws, home = Path(args.workspace).expanduser().resolve(), Path(args.home).expanduser().resolve()
    if not src_f.is_file():
        raise SafetyRefusalError("missing_src_file", f"Source MCP file does not exist: {src_f}")
    s_style = infer_mcp_style_from_key(args.src_key_path, args.src_format, src_f)
    d_style = infer_mcp_style_from_key(args.dst_key_path, args.dst_format, dst_f)
    selected = list(read_mcp_file(src_f, args.src_key_path, s_style, fmt=args.src_format).values())
    if args.servers:
        wanted = {x.strip() for x in args.servers.split(",") if x.strip()}
        selected = [s for s in selected if s.name in wanted]
    backups = BackupManager(Path(args.backup_dir) if args.backup_dir else None, home=home, workspace=ws, dry_run=args.dry_run)
    warnings: list[dict[str, Any]] = []
    patch_auth_root: Path | None = ws if dst_f.is_relative_to(ws) else (home if dst_f.is_relative_to(home) else None)
    res = apply_mcp_servers_to_file(
        selected, dst_path=dst_f, dst_key_path=args.dst_key_path, dst_style=d_style, dst_fmt=args.dst_format,
        redact_secrets=args.redact_secrets, allow_git_tracked_secrets=args.allow_git_tracked_secrets,
        claude_local_fallback_file=None, workspace=ws, auth_root=patch_auth_root, backups=backups, warnings=warnings, dry_run=args.dry_run,
    )
    bad = [r for r in res if r["outcome"] in ("conflict", "deferred")]
    return {
        "ok": True, "command": "patch-mcp", "version": SCHEMA_VERSION, "dry_run": args.dry_run,
        "redact_secrets": args.redact_secrets, "actions": res,
        "conflicts": [r for r in res if r["outcome"] == "conflict"],
        "backups": [str(p) for p in backups.backed_up.values()], "warnings": warnings,
    }, (3 if (args.strict_conflicts and bad) else 0)


EPILOG_COMMON = """Exit codes:
  0  Success (isolated conflicts, if any, are reported in stdout JSON).
  2  Invalid CLI usage or safety refusal (symlink escape, existing output path,
     unsafe backup path, or Git-tracked secret target refusal).
  3  Unresolved conflicts or deferred items when --strict-conflicts is passed.
"""


def build_parser() -> argparse.ArgumentParser:
    fmt_cls = argparse.RawDescriptionHelpFormatter
    p = argparse.ArgumentParser(
        prog="migrate_context.py", description=__doc__, formatter_class=fmt_cls,
        epilog=(
            "Examples:\n"
            "  python3 scripts/migrate_context.py inspect --workspace . --scope all\n"
            "  python3 scripts/migrate_context.py migrate --source cursor --target claude-code --workspace .\n"
            "  python3 scripts/migrate_context.py migrate --source cursor --target codex --redact-secrets --dry-run\n"
            "  python3 scripts/migrate_context.py export-device --output ~/context-transfer --profiles all\n"
            "  python3 scripts/migrate_context.py import-device --input ~/context-transfer --target same\n"
            "  python3 scripts/migrate_context.py patch-mcp --src-file ~/.junie/mcp/mcp.json --src-key-path mcpServers --dst-file .vscode/mcp.json --dst-key-path servers\n\n"
            + EPILOG_COMMON
        ),
    )
    sub = p.add_subparsers(dest="subcommand", required=True)

    pi = sub.add_parser("inspect", help="Bounded discovery of profiles, context objects, secret key fingerprints, and exclusions.", epilog="Example:\n  python3 scripts/migrate_context.py inspect --workspace . --profiles cursor,claude-code\n\n" + EPILOG_COMMON, formatter_class=fmt_cls)
    pi.add_argument("--workspace", default=".", help="Workspace project directory (default: .).")
    pi.add_argument("--home", default=str(Path.home()), help="User home directory (default: ~).")
    pi.add_argument("--profiles", default="all", help="Comma-separated profile names or 'all'.")
    pi.add_argument("--scope", choices=("project", "user", "all"), default="all", help="Scope filter.")
    pi.add_argument("--categories", default="all", help="Comma-separated categories or 'all'.")
    pi.set_defaults(func=cmd_inspect)

    pm = sub.add_parser("migrate", help="Migrate context (and secrets out-of-band in 0600 mode by default) between profiles.", epilog="Example:\n  python3 scripts/migrate_context.py migrate --source cursor --target claude-code --scope project\n\n" + EPILOG_COMMON, formatter_class=fmt_cls)
    pm.add_argument("--source", required=True, help="Source profile name or 'all'.")
    pm.add_argument("--target", required=True, help="Comma-separated target profile name(s).")
    pm.add_argument("--workspace", default=".", help="Workspace project directory.")
    pm.add_argument("--home", default=str(Path.home()), help="User home directory.")
    pm.add_argument("--scope", choices=("project", "user", "all"), default="all", help="Scope to migrate.")
    pm.add_argument("--categories", default="all", help="Comma-separated categories or 'all'.")
    pm.add_argument("--redact-secrets", action="store_true", help="Replace secrets with env placeholders instead of copying out-of-band.")
    pm.add_argument("--activate-hooks", action="store_true", help="Activate hooks instead of parking in .migration-review/.")
    pm.add_argument("--allow-broaden-scope", action="store_true", help="Merge glob rules into root instructions when target lacks file-glob rules.")
    pm.add_argument("--allow-git-tracked-secrets", action="store_true", help="Allow writing literal secrets into Git-tracked files.")
    pm.add_argument("--strict-conflicts", action="store_true", help="Exit with code 3 when conflicts or parked drafts remain.")
    pm.add_argument("--backup-dir", default=None, help="Private 0700 backup directory.")
    pm.add_argument("--dry-run", action="store_true", help="Preview actions with zero filesystem writes.")
    pm.set_defaults(func=cmd_migrate)

    pe = sub.add_parser("export-device", help="Prepare a 0700/0600 plain-folder device-transfer bundle plus redacted MIGRATION.md.", epilog="Example:\n  python3 scripts/migrate_context.py export-device --output ~/context-transfer --profiles all\n\n" + EPILOG_COMMON, formatter_class=fmt_cls)
    pe.add_argument("--output", required=True, help="New output folder path (refuses overwrite).")
    pe.add_argument("--workspace", default=".", help="Workspace project directory.")
    pe.add_argument("--home", default=str(Path.home()), help="User home directory.")
    pe.add_argument("--profiles", default="all", help="Comma-separated profile names or 'all'.")
    pe.add_argument("--scope", choices=("project", "user", "all"), default="all", help="Scope to export.")
    pe.add_argument("--categories", default="all", help="Comma-separated categories or 'all'.")
    pe.add_argument("--redact-secrets", action="store_true", help="Redact secrets into env placeholders inside the bundle.")
    pe.add_argument("--dry-run", action="store_true", help="Preview bundle as JSON with zero filesystem writes.")
    pe.set_defaults(func=cmd_export_device)

    pimp = sub.add_parser("import-device", help="Verify SHA-256 checksums and restore or cross-migrate a device-transfer folder.", epilog="Example:\n  python3 scripts/migrate_context.py import-device --input ~/context-transfer --target same\n\n" + EPILOG_COMMON, formatter_class=fmt_cls)
    pimp.add_argument("--input", required=True, help="Transfer folder created by export-device.")
    pimp.add_argument("--target", default="same", help="'same' (default) or comma-separated target profile(s).")
    pimp.add_argument("--workspace", default=".", help="Destination workspace directory.")
    pimp.add_argument("--home", default=str(Path.home()), help="Destination home directory.")
    pimp.add_argument("--scope", choices=("project", "user", "all"), default="all", help="Scope filter.")
    pimp.add_argument("--redact-secrets", action="store_true", help="Redact secrets during import.")
    pimp.add_argument("--activate-hooks", action="store_true", help="Activate hooks instead of parking in .migration-review/.")
    pimp.add_argument("--allow-broaden-scope", action="store_true", help="Allow broadening glob rules on cross-product import.")
    pimp.add_argument("--allow-git-tracked-secrets", action="store_true", help="Allow writing literal secrets into Git-tracked files.")
    pimp.add_argument("--strict-conflicts", action="store_true", help="Exit with code 3 when conflicts remain.")
    pimp.add_argument("--backup-dir", default=None, help="Private 0700 backup directory.")
    pimp.add_argument("--dry-run", action="store_true", help="Preview restore actions with zero writes.")
    pimp.set_defaults(func=cmd_import_device)

    pp = sub.add_parser("patch-mcp", help="Composable out-of-band MCP server + secret patcher for any JSON/JSONC/TOML client.", epilog="Example:\n  python3 scripts/migrate_context.py patch-mcp --src-file ~/.bob/settings/mcp.json --src-key-path mcpServers --dst-file .codex/config.toml --dst-key-path mcp_servers\n\n" + EPILOG_COMMON, formatter_class=fmt_cls)
    pp.add_argument("--src-file", required=True, help="Source MCP config file.")
    pp.add_argument("--src-key-path", default="mcpServers", help="Dotpath or '/json/pointer' to source MCP map.")
    pp.add_argument("--dst-file", required=True, help="Destination MCP config file.")
    pp.add_argument("--dst-key-path", default="mcpServers", help="Dotpath or '/json/pointer' to destination MCP map.")
    pp.add_argument("--src-format", choices=("auto", "json", "jsonc", "toml"), default="auto", help="Source format.")
    pp.add_argument("--dst-format", choices=("auto", "json", "toml"), default="auto", help="Destination format.")
    pp.add_argument("--servers", default=None, help="Optional comma-separated server names.")
    pp.add_argument("--workspace", default=".", help="Workspace directory for Git-tracked check.")
    pp.add_argument("--home", default=str(Path.home()), help="User home directory for backups.")
    pp.add_argument("--redact-secrets", action="store_true", help="Replace secrets with env placeholders.")
    pp.add_argument("--allow-git-tracked-secrets", action="store_true", help="Allow writing literal secrets into Git-tracked files.")
    pp.add_argument("--strict-conflicts", action="store_true", help="Exit with code 3 on server conflicts.")
    pp.add_argument("--backup-dir", default=None, help="Private 0700 backup directory.")
    pp.add_argument("--dry-run", action="store_true", help="Preview patch actions with zero writes.")
    pp.set_defaults(func=cmd_patch_mcp)
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        payload, code = args.func(args)
    except SafetyRefusalError as exc:
        warn_err(f"ERROR [{exc.code}]: {exc}")
        print(json.dumps({"ok": False, "error": exc.code, "message": str(exc), "details": exc.details}, indent=2, ensure_ascii=False))
        return 2
    except (json.JSONDecodeError, tomllib.TOMLDecodeError, UnicodeDecodeError) as exc:
        loc = f" (line {getattr(exc, 'lineno', '?')}, col {getattr(exc, 'colno', '?')})" if hasattr(exc, "lineno") else ""
        warn_err(f"PARSE ERROR: {exc.__class__.__name__}{loc}")
        print(json.dumps({"ok": False, "error": "parse_error", "message": f"Configuration syntax error{loc}; inspect structure without printing secret values."}, indent=2))
        return 2
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return code


if __name__ == "__main__":
    raise SystemExit(main())
