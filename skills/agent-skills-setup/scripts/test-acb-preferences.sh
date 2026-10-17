#!/usr/bin/env bash
# Review-only scalar preferences never copy or activate shared configuration.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/acb-preferences.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

native_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$1"
    else
        printf '%s' "$1"
    fi
}

python3 - "$(native_path "$SCRIPT_DIR")" "$(native_path "$TMP_ROOT")" <<'PY'
import copy
import hashlib
import importlib.util
import json
import os
import sys
from pathlib import Path
from unittest.mock import patch

scripts, root = map(Path, sys.argv[1:])
sys.path.insert(0, str(scripts))
from acb.preferences import collect_preferences, valid_review_fields
from migration_core import Registry

home, workspace = root / 'home', root / 'workspace'
home.mkdir()
workspace.mkdir()
source = json.loads((scripts.parent / 'references/registry-v2.json').read_text())
data = copy.deepcopy(source)
data['products'] = {
    product: {'default_profile': profile, 'profiles': {profile: {
        'kind': 'cli', 'migration_policy': 'bidirectional-reviewed',
        'surfaces': {'preferences': copy.deepcopy(source['products'][product]['profiles'][profile]['surfaces']['preferences'])}
    }}}
    for product, profile in [('codex', 'cli'), ('claude', 'code-cli'), ('gemini-cli', 'cli')]
}
registry_file = root / 'registry.json'


def registry():
    registry_file.write_text(json.dumps(data))
    return Registry(registry_file, workspace, home)


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def digest_tree():
    return {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in root.rglob('*') if path.is_file() and not path.is_symlink()}


write(home / '.codex/config.toml', 'model = "example-model"\nmodel_provider = "local"\nmodel_reasoning_effort = "high"\npersonality = "pragmatic"\n[projects.fixture]\ntrust_level = "trusted"\n')
private_value = 'sk-' + 'a' * 48
write(home / '.claude/settings.json', json.dumps({'model': 'example-claude', 'permissions': {'allow': ['all']}, 'env': {'PRIVATE_VALUE': private_value}}))
write(home / '.gemini/settings.json', json.dumps({'model': {'name': 'example-gemini'}, 'mcpServers': {'private': {'env': {'PRIVATE_VALUE': 'fixture-private-value'}}}}))
write(workspace / '.codex/config.toml', 'model = "project-model"\n')
write(workspace / '.claude/settings.json', '{invalid project config')
selected = {'codex/cli', 'claude/code-cli', 'gemini-cli/cli'}
reg = registry()
before = digest_tree()
files, objects, bindings, tasks = collect_preferences(reg, selected, {'user'})
has_tomllib = importlib.util.find_spec('tomllib') is not None
assert len(files) == len(objects) == (3 if has_tomllib else 2)
assert len(tasks) == 3
assert all(task['status'] == ('missing-parser' if task['product'] == 'codex' and not has_tomllib else 'review-captured') for task in tasks), tasks
assert all(obj['surface'] == 'review' and obj['status'] == 'manual-rebuild' for obj in objects)
assert all(key.startswith('review/') for key in bindings)
assert sum(map(len, bindings.values())) == len(files)
assert digest_tree() == before, 'collection changed source or created outputs'
encoded = b''.join(files.values())
assert b'fixture-private-value' not in encoded and private_value.encode() not in encoded and b'trusted' not in encoded
assert str(root).encode() not in encoded and str(root) not in json.dumps(tasks)
fields = {obj['product']: json.loads(payload)['fields']
          for obj, payload in zip(objects, files.values())}
assert fields['gemini-cli'] == [{'path': ['model', 'name'], 'value': 'example-gemini'}]

# Scope and selector restrict reads; missing scalar fields are explicit.
files, _, _, tasks = collect_preferences(reg, {'codex/cli'}, {'project'})
if has_tomllib:
    assert len(files) == 1 and tasks[0]['status'] == 'partial-review'
    assert tasks[0]['fields_captured'] == 1 and len(tasks[0]['omitted_fields']) == 3
    assert b'project-model' in next(iter(files.values()))
else:
    assert not files and tasks[0]['status'] == 'missing-parser'

# Invalid documents, absent files, unavailable stdlib parsers, and links defer.
_, _, _, tasks = collect_preferences(reg, {'claude/code-cli'}, {'project'})
assert tasks[0]['status'] == 'malformed' and str(root) not in json.dumps(tasks)
_, _, _, tasks = collect_preferences(reg, {'gemini-cli/cli'}, {'project'})
assert tasks[0]['status'] == 'not-present'
with patch('acb.preferences.importlib.import_module', side_effect=ModuleNotFoundError):
    files, _, _, tasks = collect_preferences(reg, {'codex/cli'}, {'user'})
    assert not files and tasks[0]['reason'] == 'tomllib-unavailable'
if os.name == 'posix':
    (workspace / '.claude/settings.json').unlink()
    (workspace / '.claude/settings.json').symlink_to(home / '.claude/settings.json')
    files, _, _, tasks = collect_preferences(reg, {'claude/code-cli'}, {'project'})
    assert not files and tasks[0]['status'] == 'malformed'

# Secrets inside selected fields are rejected; sibling safe fields survive.
write(home / '.claude/settings.json', json.dumps({'model': 'Bearer fixture' + 'a' * 50}))
files, _, _, tasks = collect_preferences(reg, {'claude/code-cli'}, {'user'})
assert not files and tasks[0]['omitted_fields'] == [{'path': ['model'], 'reason': 'secret-rejected'}]
assert 'Bearer' not in json.dumps(tasks)

# Selecting a parent object cannot copy its contents.
write(home / '.gemini/settings.json', json.dumps({'model': {'name': {'private': 'not-a-scalar'}}}))
files, _, _, tasks = collect_preferences(reg, {'gemini-cli/cli'}, {'user'})
assert not files and tasks[0]['omitted_fields'][0]['reason'] == 'field-not-scalar'

# Literal dotted JSON keys differ from nested paths; JSONC stays inert.
entry = data['products']['claude']['profiles']['code-cli']['surfaces']['preferences'][0]
entry.update(format='jsonc', review_fields=[['editor.fontSize'], ['model', 'name']])
write(home / '.claude/settings.json', '{// comment\n"editor.fontSize": 15, "model": {"name": "nested"},}')
files, _, _, tasks = collect_preferences(registry(), {'claude/code-cli'}, {'user'})
assert json.loads(next(iter(files.values())))['fields'] == [
    {'path': ['editor.fontSize'], 'value': 15}, {'path': ['model', 'name'], 'value': 'nested'}]
assert tasks[0]['status'] == 'review-captured'

for invalid in ([], ['model'], [[]], [['*']], [['model', '*']], [['api_key']],
                [['permissions']], [['sandbox_mode']], [['env']], [['model'], ['model']]):
    assert not valid_review_fields(invalid), invalid
assert valid_review_fields([['editor.fontSize'], ['model', 'name']])
entry['review_fields'] = [['env']]
files, _, _, tasks = collect_preferences(registry(), {'claude/code-cli'}, {'user'})
assert not files and tasks[0]['reason'] == 'invalid-review-fields'

# A custom registry's absolute location never enters portable tasks or bytes.
entry.update(path=str((home / '.claude/settings.json').resolve()), format='json', review_fields=[['model']])
write(home / '.claude/settings.json', '{"model": "portable"}')
files, _, _, tasks = collect_preferences(registry(), {'claude/code-cli'}, {'user'})
assert files and tasks[0]['canonical_path'] == '~/.claude/settings.json'
assert str(root) not in json.dumps(tasks) and str(root).encode() not in b''.join(files.values())

# The schema declares nonempty exact field-path arrays, independent of optional
# jsonschema availability in a host Python environment.
schema = json.loads((scripts.parent / 'references/registry-v2.schema.json').read_text())
field_schema = schema['$defs']['surface']['properties']['review_fields']
assert field_schema['type'] == 'array' and field_schema['minItems'] == 1
assert field_schema['items']['type'] == 'array' and field_schema['items']['minItems'] == 1
for product, profile in [('codex', 'cli'), ('claude', 'code-cli'), ('gemini-cli', 'cli')]:
    entries = source['products'][product]['profiles'][profile]['surfaces']['preferences']
    assert {entry['scope'] for entry in entries} == {'user', 'project'}
    assert all(valid_review_fields(entry['review_fields']) for entry in entries)
print('PASS: allowlisted preferences are inert, scoped, secret-scanned and explicit about omissions')
PY
