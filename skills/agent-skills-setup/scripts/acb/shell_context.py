"""Read explicitly named shell context as inert snippets, never whole profiles."""
from __future__ import annotations

import re
from pathlib import Path

from acb.bundle import MAX_FILE_SIZE, ACBError, scan_object_bytes


def collect_shell_context(path: Path, source: dict) -> tuple[dict[str, bytes], list[dict]]:
    files, tasks = {}, []
    if path.is_symlink() or not path.is_file() or path.stat().st_size > MAX_FILE_SIZE:
        return files, [{"reason": "shell-source-not-regular-or-bounded"}]
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)
    for name in source.get("functions", []):
        if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
            raise ValueError("shell function names must be literal identifiers")
        starts = [i for i, line in enumerate(lines) if re.fullmatch(
            r"(?:function\s+)?" + re.escape(name) + r"\s*\(\s*\)\s*\{\s*", line.strip())]
        if len(starts) != 1:
            tasks.append({"function": name, "reason": "shell-function-absent-or-ambiguous"})
            continue
        start = starts[0]
        end = next((i for i in range(start + 1, len(lines)) if re.fullmatch(r"}\s*", lines[i])), None)
        if end is None:
            tasks.append({"function": name, "reason": "shell-function-boundary-needs-review"})
            continue
        data = "".join(lines[start:end + 1]).encode()
        try:
            scan_object_bytes(data, "shell-function.sh")
        except ACBError:
            tasks.append({"function": name, "reason": "shell-function-sensitive-content-excluded"})
            continue
        files["functions/" + name + ".sh"] = data
    selected_paths = []
    for marker in source.get("path_markers", []):
        if not isinstance(marker, str) or not marker or "\n" in marker:
            raise ValueError("shell PATH markers must be literal single-line text")
        matches = [line for line in lines if marker in line and re.match(r"^\s*export\s+PATH=", line)]
        if not matches:
            tasks.append({"marker": marker, "reason": "shell-path-marker-not-present"})
        for line in matches:
            try:
                if any(operator in line for operator in (";", "&&", "||", "`", "$(")):
                    raise ValueError("compound PATH expression")
                scan_object_bytes(line.encode(), "shell-path.sh")
            except (ValueError, ACBError):
                tasks.append({"reason": "shell-path-binding-needs-native-review"})
                continue
            if line not in selected_paths:
                selected_paths.append(line)
    if selected_paths:
        files["path-bindings.sh"] = "".join(selected_paths).encode()
    return files, tasks
