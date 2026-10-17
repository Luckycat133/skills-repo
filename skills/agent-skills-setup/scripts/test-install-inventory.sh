#!/usr/bin/env bash
# Installation inventory is bounded, selected, data-only and never activates.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/install-inventory.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

"${INSTALL_INVENTORY_PYTHON:-python3}" -I -B - "$SCRIPT_DIR" "$TMP_ROOT" <<'PY'
import hashlib
import importlib.util
import json
import sys
from pathlib import Path
from unittest.mock import patch

scripts, root = map(Path, sys.argv[1:])
sys.path.insert(0, str(scripts))
from acb.install_inventory import collect_install_inventory, MAX_RECORDS
from acb.bundle import MAX_FILE_SIZE

private = 'sk-' + 'a' * 48
source = root / 'source.json'


def collect(document, selectors, family='json'):
    raw = document if isinstance(document, str) else json.dumps(document)
    source.write_text(raw)
    before = hashlib.sha256(source.read_bytes()).hexdigest()
    files, tasks = collect_install_inventory(source, {'format': family, 'selectors': selectors})
    assert hashlib.sha256(source.read_bytes()).hexdigest() == before
    encoded = b''.join(files.values()) + json.dumps(tasks).encode()
    assert private.encode() not in encoded
    return (json.loads(next(iter(files.values()))) if files else None), tasks


selectors = [{'path': ['plugins', '*', '*'],
              'fields': [['scope'], ['version'], ['gitCommitSha']]}]
doc = {'plugins': {'tool@official:market': [{
    'scope': 'user', 'version': '1.2', 'gitCommitSha': 'abc123',
    'installPath': '/private/unselected', 'account': 'private-account',
    'env': {'TOKEN': private}, 'permissions': ['all']}],
    private: [{'scope': 'user'}]}, 'token': private}
result, tasks = collect(doc, selectors)
assert result['inventory_only'] is True and result['native_installation'] == 'not-run'
assert len(result['records']) == 1
assert result['records'][0]['source_path'] == ['plugins', 'tool@official:market', 0]
assert {tuple(f['path']) for f in result['records'][0]['fields']} == {('scope',), ('version',), ('gitCommitSha',)}
assert 'unsafe-installation-map-key' in {t['reason'] for t in tasks}
assert not any(x in json.dumps(result) for x in ['installPath', 'private-account', 'permissions', 'TOKEN'])

# Dedicated root selectors remain inert inventory, including literal dotted keys.
root_result, _ = collect({'google.cloud.project': 'fixture-project'},
    [{'path': [], 'fields': [['google.cloud.project']]}])
assert root_result['records'][0]['fields'][0]['value'] == 'fixture-project'

# TRAE marketplace records retain only explicit identities and source metadata.
result, tasks = collect({'data': {'marketplaces': [{'plugins': [{
    'id': 'plugin.demo', 'version': 2, 'source': {'type': 'git', 'path': 'org/repo',
    'url': 'https://user:privatepass@example.test/plugin?token=hidden-query#hidden-fragment'},
    'token': private}]}]}}, [{'path': ['data', 'marketplaces', '*', 'plugins', '*'],
    'fields': [['id'], ['version'], ['source', 'type'], ['source', 'path'], ['source', 'url']]}])
fields = {tuple(item['path']): item['value'] for item in result['records'][0]['fields']}
assert fields[('source', 'url')] == 'https://example.test/plugin'
assert fields[('source', 'path')] == 'org/repo'
assert 'hidden-' not in json.dumps((result, tasks)) and 'privatepass' not in json.dumps((result, tasks))
assert any(t['reason'] == 'installation-url-redacted' for t in tasks)

# WorkBuddy installed/configured records are independent selected source maps.
result, tasks = collect({'installed': {'demo': {'version': '3', 'enabled': True}},
    'configured': {'https://user:pass@example.test/registry?secret=q': {
        'source': {'url': 'https://example.test/pkg?key=hidden'}, 'token': private}}}, [
    {'path': ['installed', '*'], 'fields': [['version'], ['enabled']]},
    {'path': ['configured', '*'], 'fields': [['source', 'url']]}])
assert len(result['records']) == 2
assert result['records'][1]['source_path'] == ['configured', 'https://example.test/registry']
assert 'secret=q' not in json.dumps((result, tasks))

# No parent object, array, null, NaN, command execution or unselected sibling.
marker = root / 'must-not-exist'
result, tasks = collect({'items': [{'id': 'demo', 'bad': {'token': private},
    'array': ['anything'], 'null': None, 'nan': float('nan'),
    'command': 'touch ' + str(marker)}]}, [{'path': ['items', '*'],
    'fields': [['id'], ['bad'], ['array'], ['null'], ['nan']]}])
assert result['records'][0]['fields'] == [{'path': ['id'], 'value': 'demo'}]
assert not marker.exists()
assert any(t['reason'] == 'installation-field-not-finite-scalar' for t in tasks)

# JSONC is parsed as inert data; TOML is stdlib-only and Python 3.9 defers.
result, _ = collect('{// comment\n"items":{"demo":{"version":"4"}},}',
                    [{'path': ['items', '*'], 'fields': [['version']]}], 'jsonc')
assert result['records'][0]['fields'][0]['value'] == '4'
result, tasks = collect('[items.demo]\nversion="5"\n',
                       [{'path': ['items', '*'], 'fields': [['version']]}], 'toml')
if importlib.util.find_spec('tomllib') is None:
    assert result is None and tasks[0]['reason'] == 'tomllib-unavailable'
else:
    assert result['records'][0]['fields'][0]['value'] == '5'

for bad in ('{"secret":"' + private + '",', 'true', '"' + private + '"'):
    result, tasks = collect(bad, selectors)
    assert result is None and tasks[-1]['reason'] == 'installation-source-unreadable-unsafe-or-invalid'
result, tasks = collect({'plugins': 10}, selectors)
assert result is None and any(t['reason'] == 'installation-selector-path-not-present-or-container' for t in tasks)
result, tasks = collect({'plugins': {str(i): {'version': '1'} for i in range(MAX_RECORDS + 1)}},
                       [{'path': ['plugins', '*'], 'fields': [['version']]}])
assert result is None and tasks[-1]['reason'] == 'installation-inventory-limit-exceeded'
source.write_bytes(b' ' * (MAX_FILE_SIZE + 1))
files, tasks = collect_install_inventory(source, {'format': 'json', 'selectors': selectors})
assert not files and tasks[-1]['reason'] == 'installation-source-not-regular-or-too-large'
for invalid in ([], [{'path': ['*'], 'fields': [['*']]}], [{'path': ['plugins'], 'fields': [['api_key']]}]):
    files, tasks = collect_install_inventory(source, {'format': 'json', 'selectors': invalid})
    assert not files and tasks[-1]['reason'] == 'invalid-installation-selectors'
source.unlink()
source.symlink_to(root / 'missing')
files, tasks = collect_install_inventory(source, {'format': 'json', 'selectors': selectors})
assert not files and tasks[-1]['reason'] == 'installation-source-unreadable-unsafe-or-invalid'
print('PASS: bounded installation inventories preserve selected identities without source writes or activation')
PY
