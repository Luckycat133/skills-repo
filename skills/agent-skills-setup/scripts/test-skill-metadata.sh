#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="$SCRIPT_DIR/../SKILL.md"

python3 - "$SKILL_FILE" <<'PY'
from pathlib import Path
import re
import sys

skill = Path(sys.argv[1]).read_text(encoding="utf-8")
if not skill.startswith("---\n"):
    raise SystemExit("FAIL: Skill metadata must start with YAML frontmatter")
end = skill.find("\n---\n", 4)
if end < 0:
    raise SystemExit("FAIL: Skill metadata has no closing frontmatter marker")
frontmatter = skill[4:end]

permissions = re.search(
    r"(?m)^permissions:[ \t]*\n((?:[ \t]+-[ \t]+[a-z_]+[ \t]*\n?)+)",
    frontmatter,
)
if permissions is None:
    raise SystemExit("FAIL: Skill must declare local runtime capabilities")
declared = set(re.findall(r"(?m)^\s*-\s+([a-z_]+)\s*$", permissions.group(1)))
if declared != {"file_read", "file_write", "shell"}:
    raise SystemExit(
        "FAIL: permissions must be exactly file_read, file_write, and shell"
    )

compatibility = re.search(r"(?m)^compatibility:\s*(.*)$", frontmatter)
if compatibility is None:
    raise SystemExit("FAIL: compatibility must describe the local capability surface")
compatibility_text = compatibility.group(1).lower()
if "no network" not in compatibility_text or "filesystem" not in compatibility_text:
    raise SystemExit("FAIL: compatibility must mention filesystem access and no network")

description = re.search(r"(?ms)^description:\s*>\s*\n(.*?)(?=\n\S|\Z)", frontmatter)
if description is None:
    raise SystemExit("FAIL: description is missing")
description_text = " ".join(line.strip() for line in description.group(1).splitlines())
if "two named supported IDEs or agent products" not in description_text:
    raise SystemExit("FAIL: description must require two named supported products")
for generic in ("copy", "sync"):
    if re.search(rf"\b{re.escape(generic)}\b", description_text, re.IGNORECASE):
        raise SystemExit(f"FAIL: generic trigger word is too broad: {generic}")

print("Skill metadata test passed")
PY
