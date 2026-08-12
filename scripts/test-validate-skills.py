#!/usr/bin/env python3
"""Regression tests for scripts/validate_skills.py (HI-004).

The publish-time validator is the ONLY detector of provider-key value formats
(e.g. `sk-`/`ghp_`/`AKIA`) in commit-time files; the runtime redactor relied on
it before CR-001. This test pins every validator branch so a future regex
drift/regression is caught before it can let a secret through.
"""

import importlib.util
import os
import pathlib
import sys
import tempfile
import textwrap

SPEC = importlib.util.spec_from_file_location(
    "validate_skills",
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "validate_skills.py"),
)
vs = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(vs)

CHECKS = 0
FAIL = 0


def check(name: str, cond: bool) -> None:
    global CHECKS, FAIL
    CHECKS += 1
    if cond:
        print(f"PASS: {name}")
    else:
        print(f"FAIL: {name}", file=sys.stderr)
        FAIL += 1


providers = {
    "sk-": "sk-ant-abcdefghijklmnopqrstuvw",
    "ghp_": "ghp_abcdefghijklmnopqrstuv",
    "AKIA": "AKIAIOSFODNN7EXAMPLE",
    "ASIA": "ASIAIOSFODNN7EXAMPLE",
    "xoxb": "xoxb-1234567890-abcdefghij",
    "ya29": "ya29.abcDEF123_",
    "AIza": "AIzaSyA1234567890abcdefghijklmnopqrstuvw",
    "sk_live_": "sk_live_abcdefghijklmnop",
    "tvly": "tvly-abcdefghijklmnopqr",
}
for label, val in providers.items():
    check(f"SECRET matches {label} value", bool(vs.SECRET.search(val)))

for benign in [
    "sk-",
    "sk-short",
    "my api key is secret but this is long prose",
    "https://example.com",
    "AKIA",
    "xox",
]:
    check(f"SECRET ignores benign {benign!r}", not vs.SECRET.search(benign))

check("PRIVATE_PATH matches /Users/...", bool(vs.PRIVATE_PATH.search("/Users/jack/.config/secret")))
check("PRIVATE_PATH matches /home/...", bool(vs.PRIVATE_PATH.search("/home/alice/.ssh/id_rsa")))
check("PRIVATE_PATH ignores relative", not vs.PRIVATE_PATH.search("~/.config/secret"))

tmp = tempfile.mkdtemp()
vs.ROOT = pathlib.Path(tmp)  # keep relative_to() valid for our out-of-tree fixture


def write_skill(body: str) -> pathlib.Path:
    skill_dir = pathlib.Path(tmp) / "demo-skill"
    if skill_dir.exists():
        for f in skill_dir.iterdir():
            f.unlink()
    else:
        skill_dir.mkdir()
    (skill_dir / "SKILL.md").write_text(body, encoding="utf-8")
    return skill_dir


vs.errors.clear()
write_skill(
    "---\n"
    "name: demo-skill\n"
    "description: a skill with a leaked key sk-ant-ABCDEFGHIJKLMNOPQRSTUVW inside\n"
    "---\n"
    "body\n"
)
vs.validate_skill(pathlib.Path(tmp) / "demo-skill")
check(
    "validate_skill flags embedded provider secret",
    any("possible secret detected" in e for e in vs.errors),
)
vs.errors.clear()

write_skill(
    "---\n"
    "name: demo-skill\n"
    "description: a skill referencing /Users/jack/secret/path\n"
    "---\n"
    "body\n"
)
vs.validate_skill(pathlib.Path(tmp) / "demo-skill")
check(
    "validate_skill flags private absolute path",
    any("private absolute path detected" in e for e in vs.errors),
)
vs.errors.clear()

write_skill(
    "---\n"
    "name: demo-skill\n"
    "description: a skill\n"
    "---\n"
    "see [missing](nonexistent-file.md) for details\n"
)
vs.validate_skill(pathlib.Path(tmp) / "demo-skill")
check(
    "validate_skill flags broken relative link",
    any("broken relative link" in e for e in vs.errors),
)
vs.errors.clear()

write_skill(
    "---\n"
    "name: demo-skill\n"
    "description: a clean skill\n"
    "---\n"
    "body\n"
)
vs.validate_skill(pathlib.Path(tmp) / "demo-skill")
check("validate_skill passes a clean skill", len(vs.errors) == 0)
vs.errors.clear()

write_skill(
    "---\n"
    "name: demo-skill\n"
    "description: invalid generic field\n"
    "permissions: [file_read]\n"
    "---\n"
    "body\n"
)
vs.validate_skill(pathlib.Path(tmp) / "demo-skill")
check(
    "validate_skill rejects unknown frontmatter fields",
    any("unknown Agent Skills frontmatter field: permissions" in e for e in vs.errors),
)
vs.errors.clear()

write_skill(
    "---\n"
    "name: demo-skill\n"
    "description: invalid nested metadata\n"
    "metadata:\n"
    "  release:\n"
    "    version: 1\n"
    "---\n"
    "body\n"
)
vs.validate_skill(pathlib.Path(tmp) / "demo-skill")
check(
    "validate_skill rejects nested metadata",
    any("metadata must map string keys to string values" in e for e in vs.errors),
)
vs.errors.clear()

write_skill(
    "---\n"
    "name: demo-skill\n"
    "description: invalid metadata scalar\n"
    "metadata:\n"
    "  version: 8\n"
    "---\n"
    "body\n"
)
vs.validate_skill(pathlib.Path(tmp) / "demo-skill")
check(
    "validate_skill requires quoted string metadata values",
    any("metadata values must be quoted strings" in e for e in vs.errors),
)
vs.errors.clear()

write_skill(
    "---\n"
    "name: demo-skill\n"
    "description: invalid allowed tools\n"
    "allowed-tools: [Bash, Read]\n"
    "---\n"
    "body\n"
)
vs.validate_skill(pathlib.Path(tmp) / "demo-skill")
check(
    "validate_skill rejects list-valued allowed-tools",
    any("allowed-tools must be a space-separated string" in e for e in vs.errors),
)
vs.errors.clear()


if FAIL == 0:
    print(f"ALL {CHECKS} validate_skills CHECKS PASSED")
    sys.exit(0)
else:
    print(f"{FAIL}/{CHECKS} validate_skills CHECKS FAILED", file=sys.stderr)
    sys.exit(1)
