#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="$SCRIPT_DIR/../SKILL.md"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

python3 - "$SKILL_FILE" "$REPO_ROOT" <<'PY'
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

top_level = {
    match.group(1)
    for match in re.finditer(r"(?m)^([A-Za-z0-9-]+):", frontmatter)
}
allowed = {
    "name", "description", "license", "compatibility", "metadata", "allowed-tools"
}
unknown = top_level - allowed
if unknown:
    raise SystemExit(f"FAIL: unknown Agent Skills fields: {sorted(unknown)}")
# A top-level ``permissions:`` field is not part of the Agent Skills spec;
# capability declarations belong under the free-form ``metadata`` map (as
# dotted ``permissions.*`` keys) or in a body section.
if re.search(r"(?m)^permissions:", frontmatter):
    raise SystemExit("FAIL: non-standard permissions frontmatter field must not be declared")
permissions_keys = re.findall(r"(?m)^  (permissions\.[a-z_]+):\s*.+$", frontmatter)
for required_key in (
    "permissions.shell",
    "permissions.env",
    "permissions.file_read",
    "permissions.file_write",
    "permissions.network",
):
    if required_key not in permissions_keys:
        raise SystemExit(f"FAIL: metadata is missing explicit permission key: {required_key}")
if not re.search(r'(?m)^  permissions\.network:\s*"denied"\s*$', frontmatter):
    raise SystemExit('FAIL: permissions.network must be quoted "denied"')
if "## Permissions" not in skill:
    raise SystemExit("FAIL: body must carry an explicit ## Permissions section")

version = re.search(r'(?m)^  version:\s*"([^"]+)"\s*$', frontmatter)
if version is None:
    raise SystemExit("FAIL: metadata.version must be a quoted string")

repo = Path(sys.argv[2])
changelog = (repo / "CHANGELOG.md").read_text(encoding="utf-8")
pending = re.search(r"(?m)^Next release: `([^`]+)`", changelog)
released = re.search(r"(?m)^## \[([^\]]+)\] - \d{4}-\d{2}-\d{2}$", changelog)
if released is None:
    raise SystemExit("FAIL: Changelog must identify the latest dated release")
expected = pending.group(1) if pending else released.group(1)
if version.group(1) != expected:
    raise SystemExit(f"FAIL: metadata.version must match Changelog ({expected})")
for name in ("README.md", "README.zh-CN.md", "README.ja-JP.md", "README.es.md"):
    readme = (repo / name).read_text(encoding="utf-8")
    if f"**{expected}**" not in readme:
        raise SystemExit(f"FAIL: {name} must identify the current version ({expected})")
    clone = re.search(r"(?m)^git clone --depth 1 --branch v(\S+) ", readme)
    if clone is None or clone.group(1) != released.group(1):
        raise SystemExit(f"FAIL: {name} must pin the latest released GitHub tag ({released.group(1)})")

compatibility = re.search(r"(?m)^compatibility:\s*(.*)$", frontmatter)
if compatibility is None:
    raise SystemExit("FAIL: compatibility must describe the local capability surface")
compatibility_text = compatibility.group(1).lower()
if "no network" not in compatibility_text or "filesystem" not in compatibility_text:
    raise SystemExit("FAIL: compatibility must mention filesystem access and no network")

description = re.search(r"(?ms)^description:\s*>[-\s]*\n(.*?)(?=\n\S|\Z)", frontmatter)
if description is None:
    raise SystemExit("FAIL: description is missing")
description_text = " ".join(line.strip() for line in description.group(1).splitlines())
for capability in (
    "migrate",
    "restore",
    "Cursor",
    "Claude Code",
    "Skills",
    "MCP",
    "secret redaction",
    "rollback",
):
    if capability.lower() not in description_text.lower():
        raise SystemExit(f"FAIL: description omits capability: {capability}")
for generic in ("copy", "sync"):
    if re.search(rf"\b{re.escape(generic)}\b", description_text, re.IGNORECASE):
        raise SystemExit(f"FAIL: generic trigger word is too broad: {generic}")

print("Skill metadata test passed")
PY

python3 - "$SCRIPT_DIR" <<'PY'
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

scripts = Path(sys.argv[1])
sys.path.insert(0, str(scripts))
from migration_core import _skill_metadata, preflight_skill_source

with tempfile.TemporaryDirectory(prefix='skill-metadata-') as temporary:
    root = Path(temporary)
    valid = [
        'name: fixture\ndescription:\n  Create a reviewed pull request.\n  Preserve source and destination context.',
        'name: fixture\ndescription: Create a reviewed\n  pull request from this change.',
        *['name: fixture\ndescription: ' + marker + '\n  Create a reviewed pull request.\n  Preserve the intended context.'
          for marker in ('|', '|-', '>', '>-', '|+', '>+', '|2-', '>2-')],
        'name: fixture\ndescription: "false"',
        'name: fixture\ndescription: |-\n  false',
        'name : fixture\ndescription : A valid spaced mapping key.',
        "name: fixture\ndescription: 'The user''s reviewed request.'",
        'name: fixture\ndescription: A short task. # inline comment\nmetadata:\n  description: Nested values do not override root metadata.',
        'name: ' + 'a' * 64 + '\ndescription: ' + 'a' * 1024,
    ]
    for index, body in enumerate(valid):
        package = root / f'valid-{index}'
        package.mkdir()
        document = '---\n' + body + '\n---\n# Original source body.\n'
        (package / 'SKILL.md').write_text(document)
        preflight_skill_source(package)
        assert (package / 'SKILL.md').read_text() == document
    assert _skill_metadata('description: >-\n  First paragraph.\n\n  Second paragraph.')['description'] == 'First paragraph.\nSecond paragraph.'

    invalid = [
        'description: Missing name.', 'name: fixture',
        *['name: fixture\ndescription: ' + value
          for value in ('false', 'true', 'null', '~', '123', '3.14', '[]', '{}', '[item]', '{key: value}', '!tag value', '*alias', '&anchor value', '"unterminated', "'unterminated", '""')],
        'name: fixture\ndescription:\n  - list item',
        'name: fixture\ndescription:\n  nested: mapping',
        'name: fixture\ndescription: |\n   First.\n  Invalid indentation.',
        'name: fixture\ndescription: |\n  ',
        'name: fixture\ndescription: >-\n\tTabbed indentation.',
        'name: fixture\ndescription: ' + 'a' * 1025,
        'name: fixture\ndescription: |-\n  ' + 'a' * 1025,
        'name: fixture\ndescription: >-\n  ' + 'a' * 600 + '\n  ' + 'b' * 600,
        'name: ' + 'a' * 65 + '\ndescription: Valid description.',
        'name: false\ndescription: Name must be a string.',
        'name: [fixture]\ndescription: Name must be a string.',
        'name: fixture\ndescription: First.\ndescription: Duplicate.',
        'name: fixture\ndescription: Valid text.\n<<<<<<< upstream\nlicense: MIT\n=======\n>>>>>>> local',
    ]
    for index, body in enumerate(invalid):
        package = root / f'invalid-{index}'
        package.mkdir()
        (package / 'SKILL.md').write_text('---\n' + body + '\n---\n')
        try:
            preflight_skill_source(package)
        except ValueError:
            pass
        else:
            raise AssertionError(f'invalid metadata accepted at fixture {index}')
    print('Skill metadata scalar regression passed: plain continuation, literal/folded blocks and type/length failures')

    old_home, new_home = root / 'old-home', root / 'new-home'
    old_workspace, new_workspace = root / 'old-workspace', root / 'new-workspace'
    for directory in (old_home, new_home, old_workspace, new_workspace):
        directory.mkdir()
    package = old_home / '.trae/skills/pr-creator'
    package.mkdir(parents=True)
    original = '---\nname: pr-creator\ndescription:\n  Create a reviewed pull request.\n  Use the current repository context.\n---\n# Preserve this body.\n'
    (package / 'SKILL.md').write_text(original)
    registry = json.loads((scripts.parent / 'references/registry-v2.json').read_text())
    profile = registry['products']['trae']['profiles']['cn-ide']
    profile['platforms'] = {}
    profile['detection'] = []
    profile['surfaces'] = {'skills': [entry for entry in profile['surfaces']['skills'] if entry['scope'] == 'user']}
    registry['products'] = {'trae': {'default_profile': 'cn-ide', 'profiles': {'cn-ide': profile}}}
    registry_path = root / 'registry.json'
    registry_path.write_text(json.dumps(registry))

    def run(home, *arguments):
        result = subprocess.run(
            [sys.executable, '-B', str(scripts / 'context-migrator.py'), *map(str, arguments), '--registry', str(registry_path), '--json'],
            env=dict(os.environ, HOME=str(home), USERPROFILE=str(home), AGENT_SKILLS_PLATFORM='linux'),
            capture_output=True, text=True,
        )
        assert result.returncode == 0, (result.stdout, result.stderr)
        output = json.loads(result.stdout)
        assert output.get('ok'), output
        return output

    bundle = root / 'skill.acb'
    run(old_home, 'snapshot', '--source', 'trae/cn-ide', '--target', 'trae/cn-ide',
        '--scope', 'user', '--objects', 'skills', '--workspace', old_workspace, '--output', bundle)
    shutil.rmtree(old_home)
    plan, manifest = root / 'plan.json', root / 'manifest.json'
    run(new_home, 'restore', bundle, '--source', 'trae/cn-ide', '--target', 'trae/cn-ide',
        '--scope', 'user', '--objects', 'skills', '--workspace', new_workspace,
        '--plan-only', '--plan-out', plan)
    document = json.loads(plan.read_text())
    assert any(item['object_type'] == 'skills' and item['status'] == 'ready' for item in document['items']), document
    run(new_home, 'restore', bundle, '--source', 'trae/cn-ide', '--target', 'trae/cn-ide',
        '--scope', 'user', '--objects', 'skills', '--workspace', new_workspace,
        '--plan-in', plan, '--manifest-out', manifest, '--yes')
    restored = new_home / '.trae/skills/pr-creator/SKILL.md'
    assert restored.read_text() == original
    dispositions = json.loads(manifest.read_text())['items']
    assert any(item['outcome'] == 'applied' for item in dispositions), dispositions
    print('Skill metadata snapshot -> same-product saved-plan/apply regression passed with original multiline bytes')
PY
