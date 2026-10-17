#!/usr/bin/env python3
"""Materialize explicitly reviewed linked Skills into a new staging source.

This never installs Skills. A subsequent snapshot captures the staged source;
the report preserves link provenance and exclusions for the destination agent.
"""

from __future__ import annotations

import argparse
import ast
import hashlib
import json
import os
import re
import stat
import sys
from pathlib import Path

_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from acb.bundle import MAX_BUNDLE_FILES, MAX_DIR_DEPTH, MAX_FILE_SIZE, MAX_TOTAL_SIZE, ACBError, ACBSecretLeak, scan_object_bytes
import skill_secret_scanner as scanner


def _prepare_strict(source: Path, output: Path, report: Path, allowed: list[Path]) -> dict:
    source = source.expanduser().absolute()
    output = output.expanduser().absolute()
    report = report.expanduser().absolute()
    if not source.is_dir():
        raise ValueError("source must be an existing Skill directory")
    # Staging is additive only. Do not replace live, previous or overlapping data.
    if output.exists() or output.is_symlink() or report.exists() or report.is_symlink():
        raise ValueError("use fresh, distinct staging and report paths")
    roots = [source.resolve(), *(path.expanduser().resolve() for path in allowed)]
    for destination in (output, report):
        resolved = destination.resolve()
        if any(resolved == root or root in resolved.parents or resolved in root.parents for root in roots):
            raise ValueError("staging/report must not overlap source or allowed roots")
    if report == output or output in report.parents or report in output.parents:
        raise ValueError("staging and report paths must not overlap")
    for destination in (output, report):
        for parent in destination.parents:
            if parent.is_symlink() and str(parent) not in {"/var", "/tmp", "/etc"}:
                raise ValueError("staging path has a symlink parent")
    output.mkdir(parents=True, mode=0o700)
    entries = []
    total = 0
    count = 0
    candidates = [source] if (source / "SKILL.md").is_file() else sorted(source.iterdir())
    for candidate in candidates:
        record = {"name": candidate.name, "source": str(candidate), "link_target": None,
                  "status": "excluded", "files": [], "omissions": [], "reason": "not-a-directory"}
        entries.append(record)
        if candidate.is_symlink():
            try:
                record["link_target"] = str(candidate.resolve(strict=True))
            except (OSError, RuntimeError):
                # Path.resolve reports symlink loops as RuntimeError on older
                # Python and OSError on newer Python. Keep one portable outcome
                # and retain the exclusion record before examining the target.
                record["reason"] = "unresolvable-link"
                continue
        if not candidate.is_dir():
            continue
        if not (candidate / "SKILL.md").is_file() and candidate.name != ".system":
            record["reason"] = "not-a-skill-package"
            continue
        files: dict[str, tuple[bytes, int]] = {}
        visiting: set[Path] = set()

        def walk(path: Path, parts: tuple[str, ...]) -> None:
            if len(parts) > MAX_DIR_DEPTH:
                raise ACBError("depth-limit")
            if (path.name in {"__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache", ".DS_Store"}
                    or path.name.endswith((".pyc", ".pyo"))):
                record["omissions"].append({"path": "/".join(parts), "reason": "generated-cache-excluded"})
                return
            if path.name == ".env" or path.name.startswith(".env."):
                record["omissions"].append({"path": "/".join(parts), "reason": "environment-file-excluded"})
                return
            resolved = path.resolve(strict=True)
            if not any(resolved == root or root in resolved.parents for root in roots):
                raise ACBError("link-outside-reviewed-roots")
            mode = resolved.stat().st_mode
            if stat.S_ISDIR(mode):
                if resolved in visiting:
                    raise ACBError("link-cycle")
                visiting.add(resolved)
                for child in sorted(resolved.iterdir()):
                    walk(child, (*parts, child.name))
                visiting.remove(resolved)
            elif stat.S_ISREG(mode):
                if resolved.stat().st_size > MAX_FILE_SIZE:
                    raise ACBError("file-size-limit")
                with resolved.open("rb") as reader:
                    data = reader.read(MAX_FILE_SIZE + 1)
                if len(data) > MAX_FILE_SIZE:
                    raise ACBError("file-size-limit")
                relative = "/".join(parts)
                scan_object_bytes(relative.encode("utf-8"), "filename-metadata.txt")
                scan_object_bytes(data, relative)
                files[relative] = (data, stat.S_IMODE(mode) & 0o777)
                if len(files) + count > MAX_BUNDLE_FILES or sum(len(value[0]) for value in files.values()) + total > MAX_TOTAL_SIZE:
                    raise ACBError("staging-resource-limit")
            else:
                raise ACBError("non-regular-source")

        try:
            walk(candidate, () if candidate == source else (candidate.name,))
        except ACBSecretLeak:
            record["reason"] = "secret-or-unsafe-binary"
            continue
        except (OSError, RuntimeError, ACBError):
            record["reason"] = "unreadable-unsafe-or-resource-limited"
            continue
        for relative, (data, mode) in sorted(files.items()):
            target = output / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            target.chmod(mode)
            record["files"].append({"path": relative, "sha256": hashlib.sha256(data).hexdigest(), "mode": mode})
            count += 1
            total += len(data)
        record["status"] = "staged-partial" if record["omissions"] else "staged"
        record["reason"] = "reviewed-source-materialized"
    payload = {"schema_version": 1, "source_root": str(source), "staging_root": str(output),
               "source_unchanged": "read-only-operation", "not_installed": True,
               "files_staged": count, "bytes_staged": total, "entries": entries}
    from acb.recovery import _safe_metadata
    payload = _safe_metadata(payload)
    report.parent.mkdir(parents=True, exist_ok=True)
    descriptor = os.open(report, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as writer:
        json.dump(payload, writer, indent=2)
        writer.write("\n")
    return payload


_IDENTITY_FIELDS = frozenset({
    "name", "id", "version", "revision", "commit", "commit_sha", "sha",
    "source_url", "sourceURL", "url", "repository", "repository_url", "repo",
    "original_path", "source_path", "license", "author",
})
_IDENTITY_CONTAINERS = frozenset({"source", "upstream", "origin", "provenance"})


def _source_metadata(package: Path) -> dict:
    """Read only safe provenance fields; never transport opaque SOURCE data."""
    path = package / "SOURCE.json"
    try:
        if path.is_symlink() or not path.is_file() or path.stat().st_size > MAX_FILE_SIZE:
            return {}
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError, UnicodeError, RecursionError):
        return {}

    def select(value, depth=0):
        if not isinstance(value, dict) or depth > 3:
            return {}
        result = {}
        for key, item in value.items():
            if key in _IDENTITY_CONTAINERS and isinstance(item, dict):
                chosen = select(item, depth + 1)
                if chosen:
                    result[key] = chosen
            elif key in _IDENTITY_FIELDS and isinstance(item, str) and len(item) <= 2048:
                try:
                    if "://" in item:
                        from acb.mcp_review import _safe_review_url
                        from migration_core import LossReport
                        item, _, _ = _safe_review_url(item, "provenance", LossReport())
                    scan_object_bytes(item.encode(), "provenance.txt")
                    result[key] = item
                except (ACBError, ValueError):
                    continue
        return result
    return select(document)


def _literal_review(data: bytes, relative: str) -> tuple[bytes, list[dict]]:
    """Replace exact scanner-confirmed literal spans, then rerun the scanner."""
    try:
        scan_object_bytes(data, relative)
        return data, []
    except ACBSecretLeak:
        if scanner.PRIVATE_KEY.search(data) or b"\0" in data:
            raise
    text = data.decode("utf-8")
    spans = []

    def add(start, end, kind, replacement="${REDACTED_CREDENTIAL}"):
        spans.append((start, end, kind, replacement))

    for pattern in scanner.PROVIDER_PATTERNS:
        expression = re.compile(pattern.pattern.decode("ascii"))
        for match in expression.finditer(text):
            authorization_prefix = re.match(r"(?i)bearer[ \t]+", match.group())
            add(match.start() + (authorization_prefix.end() if authorization_prefix else 0), match.end(), "provider-literal")
    for match in re.finditer(scanner.CONNECTION_STRING_USERINFO.pattern.decode("ascii"), text):
        value = match.group()
        start = value.index("://") + 3
        end = value.index("@", start)
        add(match.start() + start, match.start() + end, "connection-userinfo", "${MCP_AUTH}")
    for match in scanner.SECRET_CALL_ASSIGNMENT.finditer(text):
        expression_text = match.group(1)
        expression = scanner.call_expression(expression_text)
        if expression is None:
            continue
        for node in ast.walk(expression):
            if not isinstance(node, ast.Constant) or not isinstance(node.value, str) or len(node.value) < 12:
                continue
            if scanner.SAFE_REFERENCE.fullmatch(node.value) or scanner.is_placeholder(node.value):
                continue
            # AST offsets are UTF-8 byte offsets, even for Unicode text.
            start = len(expression_text.encode()[:node.col_offset].decode())
            end = len(expression_text.encode()[:node.end_col_offset].decode())
            add(match.start(1) + start, match.start(1) + end, "assignment-call-literal", "REDACTED_CREDENTIAL")
    for match in scanner.SECRET_ASSIGNMENT.finditer(text):
        value = match.group(1)
        quoted = text[match.start(1) - 1:match.start(1)] in {"'", '"'}
        if (value.startswith("$(") or scanner.SAFE_REFERENCE.fullmatch(value)
                or scanner.is_placeholder(value) or scanner.is_field_alias(match, text)
                or (not quoted and scanner.is_computed_assignment(value))):
            continue
        if not quoted and re.match(r"[A-Za-z_][A-Za-z0-9_.]*\s*\(", value):
            # Only the exact AST literals above are safe to replace in a call.
            continue
        start, end = match.span(1)
        if quoted:
            quote, end = text[start - 1], start
            while end < len(text):
                if text[end] == "\\":
                    end += 2
                elif text[end] == quote:
                    break
                else:
                    end += 1
            if end >= len(text):
                raise ACBSecretLeak("unclosed-sensitive-literal")
        add(start, end, "credential-assignment")
    if not spans:
        raise ACBSecretLeak("no-safe-literal-redaction")
    selected = []
    for span in sorted(spans, key=lambda item: (item[0], -item[1])):
        if selected and span[0] < selected[-1][1]:
            if span[1] > selected[-1][1]:
                raise ACBSecretLeak("ambiguous-overlapping-redactions")
            continue
        selected.append(span)
    redactions = [{"path": relative, "line": text.count("\n", 0, start) + 1,
                   "column": start - text.rfind("\n", 0, start), "kind": kind,
                   "placeholder": replacement}
                  for start, _, kind, replacement in selected]
    for start, end, _, replacement in reversed(selected):
        text = text[:start] + replacement + text[end:]
    result = text.encode("utf-8")
    scan_object_bytes(result, relative)
    return result, redactions


def _prepare_review(source: Path, output: Path, report: Path, allowed: list[Path]) -> dict:
    source, output, report = (path.expanduser().absolute() for path in (source, output, report))
    if not source.is_dir():
        raise ValueError("source must be an existing Skill directory")
    if any(path.exists() or path.is_symlink() for path in (output, report)):
        raise ValueError("use fresh staging and report paths")
    roots = [source.resolve(), *(path.expanduser().resolve() for path in allowed)]
    if any(not root.is_dir() for root in roots):
        raise ValueError("reviewed roots must exist as directories")
    for destination in (output, report):
        resolved = destination.resolve()
        if any(resolved == root or root in resolved.parents or resolved in root.parents for root in roots):
            raise ValueError("staging/report must not overlap reviewed sources")
        if any(parent.is_symlink() and str(parent) not in {"/var", "/tmp", "/etc"} for parent in destination.parents):
            raise ValueError("staging path has a symlink parent")
    if report == output or output in report.parents or report in output.parents:
        raise ValueError("staging and report paths must not overlap")
    output.mkdir(parents=True, mode=0o700)
    entries, total, count, examined = [], 0, 0, 0
    candidates = []

    def inside(path):
        return any(path == root or root in path.parents for root in roots)

    def discover(path, parts, active):
        nonlocal examined
        examined += 1
        if examined > MAX_BUNDLE_FILES or len(parts) > MAX_DIR_DEPTH:
            candidates.append((path, parts, None, "discovery-resource-limit"))
            return
        try:
            resolved = path.resolve(strict=True)
        except (OSError, RuntimeError):
            candidates.append((path, parts, None, "unresolvable-link"))
            return
        if not inside(resolved):
            candidates.append((path, parts, None, "link-outside-reviewed-roots"))
            return
        if resolved in active:
            candidates.append((path, parts, None, "link-cycle"))
            return
        if not resolved.is_dir():
            return
        if (resolved / "SKILL.md").is_file():
            candidates.append((path, parts, resolved, ""))
            return
        before = len(candidates)
        try:
            for child in sorted(resolved.iterdir()):
                if examined >= MAX_BUNDLE_FILES:
                    candidates.append((path, parts, None, "discovery-resource-limit"))
                    break
                if child.is_dir() or child.is_symlink():
                    discover(path / child.name, (*parts, child.name), active | {resolved})
        except OSError:
            candidates.append((path, parts, None, "unreadable-namespace"))
        if len(candidates) == before:
            candidates.append((path, parts, None, "not-a-skill-package"))

    if (source / "SKILL.md").is_file():
        candidates.append((source, (), source.resolve(), ""))
    else:
        for child in sorted(source.iterdir()):
            if examined >= MAX_BUNDLE_FILES:
                candidates.append((source, (), None, "discovery-resource-limit"))
                break
            if child.is_dir() or child.is_symlink():
                discover(child, (child.name,), {source.resolve()})

    def rebind(path, parts):
        """Same-name suggestions are not proof; exact origin metadata is."""
        if not path.is_symlink():
            return None, [], None
        try:
            raw = Path(os.readlink(path))
            target = raw if raw.is_absolute() else path.parent / raw
            target = Path(os.path.abspath(target))
        except OSError:
            return None, [], None
        matches, suggestions = [], []
        for root in roots[1:]:
            for suffix in {tuple(parts), (path.name,)}:
                candidate = root.joinpath(*suffix)
                try:
                    resolved = candidate.resolve(strict=True)
                except (OSError, RuntimeError):
                    continue
                if not inside(resolved) or not (resolved / "SKILL.md").is_file():
                    continue
                metadata = _source_metadata(resolved)
                suggestion = {"source": str(resolved), "source_metadata": metadata,
                              "evidence": "same-name-only-not-proof"}
                if suggestion not in suggestions:
                    suggestions.append(suggestion)
                def origins(value):
                    if not isinstance(value, dict):
                        return []
                    return [item for key, item in value.items() if key in {"source_path", "original_path"} and isinstance(item, str)] + [origin for item in value.values() if isinstance(item, dict) for origin in origins(item)]
                if str(target) in origins(metadata) and resolved not in matches:
                    from migration_core import FRONTMATTER, _skill_metadata
                    try:
                        entrypoint = resolved / "SKILL.md"
                        if entrypoint.is_symlink() or entrypoint.stat().st_size > MAX_FILE_SIZE:
                            continue
                        with entrypoint.open("rb") as reader:
                            header_bytes = reader.read(MAX_FILE_SIZE + 1)
                        if len(header_bytes) > MAX_FILE_SIZE:
                            continue
                        text = header_bytes.decode("utf-8")
                        header = FRONTMATTER.match(text)
                        name = _skill_metadata(header.group(1)).get("name") if header else None
                        if name == path.name:
                            matches.append(resolved)
                    except (OSError, UnicodeError, ValueError):
                        continue
        proof = {"kind": "SOURCE-exact-original-path-and-SKILL-name", "original_target": str(target)}
        return (matches[0], suggestions, proof) if len(matches) == 1 else (None, suggestions, None)

    for candidate, parts, resolved, problem in candidates:
        record = {"name": "/".join(parts) or candidate.name, "source": str(candidate),
                  "source_identity": hashlib.sha256(str(candidate).encode()).hexdigest(),
                  "link_target": str(resolved) if candidate.is_symlink() and resolved else None,
                  "status": "excluded", "complete": False, "files": [], "omissions": [],
                  "redactions": [], "missing_files": [], "missing_references": [], "next_actions": [],
                  "source_metadata": {}, "reason": problem or "review-source"}
        entries.append(record)
        if problem == "unresolvable-link":
            rebound, suggestions, proof = rebind(candidate, parts)
            record["recovery_candidates"] = suggestions
            if rebound is not None:
                resolved, problem = rebound, ""
                record.update(link_target=str(rebound), link_rebound=proof)
        if problem or resolved is None:
            record["next_actions"].append("Inspect the preserved source link or namespace and its recorded candidates. Supply an explicitly reviewed source with matching original-path/revision evidence; same names alone do not authorize rebinding. Then recapture without editing the old source.")
            record["missing_files"].append("/".join((*parts, "SKILL.md")))
            continue
        record["source_metadata"] = _source_metadata(resolved)
        files, visiting = {}, set()

        def omit(relative, reason):
            record["omissions"].append({"path": relative, "reason": reason,
                "next_action": "The destination agent must reconstruct or explicitly defer this omitted file, recheck package references, and retain source access. Never execute a partial package automatically."})
            record["missing_files"].append(relative)

        def walk(path, relative_parts):
            nonlocal count, total, examined
            relative = "/".join(relative_parts)
            examined += 1
            if examined > MAX_BUNDLE_FILES or len(relative_parts) > MAX_DIR_DEPTH:
                omit(relative, "resource-or-depth-limit")
                return
            if path.name in {"__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache", ".DS_Store"} or path.suffix in {".pyc", ".pyo"}:
                omit(relative, "generated-cache-excluded")
                return
            if path.name == ".env" or path.name.startswith(".env."):
                omit(relative, "environment-file-excluded")
                return
            try:
                actual = path.resolve(strict=True)
                if not inside(actual):
                    omit(relative, "link-outside-reviewed-roots")
                    return
                mode = actual.stat().st_mode
                if stat.S_ISDIR(mode):
                    if actual in visiting:
                        omit(relative, "link-cycle")
                        return
                    visiting.add(actual)
                    for child in sorted(actual.iterdir()):
                        if examined >= MAX_BUNDLE_FILES:
                            omit(relative, "file-count-limit")
                            break
                        walk(child, (*relative_parts, child.name))
                    visiting.remove(actual)
                    return
                if not stat.S_ISREG(mode):
                    omit(relative, "non-regular-source")
                    return
                if actual.stat().st_size > MAX_FILE_SIZE:
                    omit(relative, "file-size-limit")
                    return
                with actual.open("rb") as reader:
                    original = reader.read(MAX_FILE_SIZE + 1)
                if len(original) > MAX_FILE_SIZE:
                    omit(relative, "file-size-limit")
                    return
                scan_object_bytes(relative.encode(), "filename-metadata.txt")
                staged, redactions = _literal_review(original, relative)
                if len(files) + count >= MAX_BUNDLE_FILES or total + sum(len(item[0]) for item in files.values()) + len(staged) > MAX_TOTAL_SIZE:
                    omit(relative, "staging-resource-limit")
                    return
                files[relative] = (staged, stat.S_IMODE(mode) & 0o777, hashlib.sha256(original).hexdigest())
                record["redactions"].extend(redactions)
            except (ACBError, UnicodeError):
                omit(relative, "unsafe-or-unredactable-file")
            except (OSError, RuntimeError):
                omit(relative, "missing-unreadable-or-looping-source")

        walk(resolved, parts)
        prefix = "/".join(parts)
        skill_relative = (prefix + "/" if prefix else "") + "SKILL.md"
        if skill_relative not in files:
            omit(skill_relative, "entrypoint-not-preserved")
        for relative, (data, _, _) in files.items():
            if not relative.endswith((".md", ".txt")):
                continue
            try:
                text = data.decode("utf-8")
            except UnicodeError:
                continue
            references = re.findall(r"\[[^\]]*\]\(([^\s)]+)(?:\s+[^)]*)?\)", text)
            if relative == skill_relative:
                references.extend(re.findall(r"(?<![A-Za-z0-9_/])(?:references|scripts|assets)/[A-Za-z0-9_./-]+", text))
            for reference in references:
                if "://" in reference or reference.startswith(("#", "/")):
                    continue
                reference = reference.split("#", 1)[0]
                wanted = os.path.normpath(str(Path(relative).parent / reference)).replace("\\", "/")
                if wanted not in files:
                    record["missing_references"].append({"from": relative, "path": wanted})
        for relative, (data, mode, original_hash) in sorted(files.items()):
            target = output / relative
            if target.exists():
                raise ValueError("staging package path collision")
            target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            with target.open("xb") as writer:
                writer.write(data)
            target.chmod(mode)
            record["files"].append({"path": relative, "sha256": hashlib.sha256(data).hexdigest(),
                                    "source_sha256": original_hash, "mode": mode})
            count += 1
            total += len(data)
        record["missing_files"] = sorted(set(record["missing_files"]))
        record["complete"] = bool(files) and not record["omissions"] and not record["missing_references"]
        record["status"] = ("staged-partial" if record["omissions"] or record["redactions"] or record["missing_references"] else "staged") if files else "excluded"
        record["reason"] = "sanitized-review-source-materialized" if files else "no-safe-source-files"
        if not record["complete"]:
            record["next_actions"].append("Resolve missing files and references from the recorded source/provenance, or explicitly approve the partial package before reconstruction.")
        if record["redactions"]:
            record["next_actions"].append("Reconstruct redacted settings with environment references or native authentication. The report records locations, never credential values; do not activate these source commands automatically.")
    payload = {"schema_version": 1, "mode": "sanitize-review", "inert_review_only": True,
               "automatic_restore": False, "source_root": str(source), "staging_root": str(output),
               "source_unchanged": "read-only-operation", "not_installed": True,
               "files_staged": count, "bytes_staged": total, "entries": entries}
    from acb.recovery import _safe_metadata
    payload = _safe_metadata(payload)
    scan_object_bytes(json.dumps(payload).encode(), "staging-report.json")
    report.parent.mkdir(parents=True, exist_ok=True)
    descriptor = os.open(report, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as writer:
        json.dump(payload, writer, indent=2)
        writer.write("\n")
    return payload


def prepare(source: Path, output: Path, report: Path, allowed: list[Path], *, sanitize_review: bool = False) -> dict:
    if sanitize_review:
        return _prepare_review(source, output, report, allowed)
    return _prepare_strict(source, output, report, allowed)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--allow-linked-root", type=Path, action="append", default=[])
    parser.add_argument("--sanitize-review", action="store_true",
                        help="Stage inert safe file copies, redact exact credential literals, and retain explicit partial-package reconstruction tasks.")
    args = parser.parse_args()
    try:
        result = prepare(args.source, args.output, args.report, args.allow_linked_root, sanitize_review=args.sanitize_review)
    except (OSError, ValueError, RuntimeError) as error:
        print(json.dumps({"ok": False, "error_type": type(error).__name__}))
        return 1
    print(json.dumps({"ok": True, "files_staged": result["files_staged"], "packages_staged": sum(entry["status"].startswith("staged") for entry in result["entries"]),
                      "packages_excluded": sum(entry["status"] == "excluded" for entry in result["entries"]), "report": str(args.report)}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
