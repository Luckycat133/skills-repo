#!/usr/bin/env bash
# Explicit maps and string arrays preserve unrelated settings and credentials.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/preference-selections.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT
"${PREFERENCE_SELECTIONS_PYTHON:-python3}" -I -B - "$SCRIPT_DIR" "$TMP_ROOT" <<'PY'
import copy
import importlib.util
import json
import sys
from pathlib import Path
scripts, root = map(Path, sys.argv[1:])
sys.path.insert(0, str(scripts))
def load(name, filename):
    spec = importlib.util.spec_from_file_location(name, scripts / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module
capture = load('preference_capture_test', 'capture-review-sources.py')
restore = load('preference_restore_test', 'review-restore.py')
from acb.preferences import valid_review_value, valid_review_map_key
assert not valid_review_value(['x'], ['disabled'])
assert valid_review_value(['x'], ['disabled'], allow_string_array=True)
assert valid_review_value(['x'], ['roles'])
assert not valid_review_value(['x'] * 129, ['disabled'], allow_string_array=True)
assert valid_review_map_key('official:plugin@author/package')
for bad in ['', 'api_key', 'https://user:password@fixture.invalid', 'run;command', '\0']:
    assert not valid_review_map_key(bad)
source = root / 'settings.json'
source.write_text(json.dumps({'disabled': ['skill-%02d' % i for i in range(32)],
    'unselected': ['keep-private'], 'managedSkills': {'pkg': 'registry/pkg', 'nested': {'not': 'scalar'}, 'unsafe': 'password=synthetic-private-value', 'api_key': 'not-captured'},
    'plugins': {'official:plugin@author/package': {'user_enabled': True, 'app_origin_enabled': False,
        'secretSibling': 'never-export-this-value'}},
    'marketplaces': {'official': {'source': {'source': 'git', 'url': 'https://fixture.invalid/plugin'},
        'secretSibling': 'never-export-this-value'}}}))
before = source.read_bytes()
selection = {'id': 'preferences', 'kind': 'preferences', 'path': str(source), 'format': 'json',
    'string_arrays': [['disabled']], 'maps': [
        {'path': ['managedSkills'], 'scalar_values': True},
        {'path': ['plugins'], 'fields': [['user_enabled'], ['app_origin_enabled']]},
        {'path': ['marketplaces'], 'fields': [['source', 'source'], ['source', 'url']]}]}
def spec(s):
    return {'schema_version': 1, 'clients': [{'id': 'fixture', 'label': 'Fixture', 'sources': [s]}]}
capture.validate_spec(spec(selection))
report = {}
tasks, ok = capture.preferences(source, selection, root / 'payload', report)
assert ok and any(x['reason'] == 'map-value-not-scalar' for x in tasks)
assert any(x['reason'] == 'secret-not-captured' for x in tasks)
assert any(x['reason'] == 'unsafe-map-identity-not-captured' for x in tasks)
assert 'synthetic-private-value' not in json.dumps(tasks)
payload = json.loads((root / 'payload/preferences.json').read_text())
assert 'never-export-this-value' not in json.dumps(payload)
assert 'synthetic-private-value' not in json.dumps(payload)
assert len(payload['fields'][0]['value']) == 32
existing = {'disabled': ['old'], 'keep': True, 'managedSkills': {'other': 'kept'},
    'plugins': {'official:plugin@author/package': {'user_enabled': False, 'api_key': 'destination-only'}},
    'marketplaces': {'official': {'source': {'token': 'destination-token'}}}}
original = copy.deepcopy(existing)
try:
    restore.merge_preferences(copy.deepcopy(existing), payload, {'conflict': 'error'}, [])
except restore.RestoreError:
    pass
else:
    raise AssertionError('conflict accepted')
restore.merge_preferences(existing, payload, {'conflict': 'replace'}, [])
assert existing['keep'] and existing['managedSkills']['other'] == 'kept'
assert existing['plugins']['official:plugin@author/package']['api_key'] == 'destination-only'
assert existing['marketplaces']['official']['source']['token'] == 'destination-token'
assert existing['marketplaces']['official']['source']['url'] == 'https://fixture.invalid/plugin'
assert source.read_bytes() == before
root_selection = dict(selection, maps=[{'path': [], 'fields': [['source', 'url']]}])
root_selection.pop('string_arrays')
capture.validate_spec(spec(root_selection))
root_source = root / 'marketplaces.json'
root_source.write_text(json.dumps({'official': {'source': {'url': 'https://fixture.invalid/root'}, 'private': 'omitted'}}))
capture.preferences(root_source, root_selection, root / 'root-payload', {})
root_payload = json.loads((root / 'root-payload/preferences.json').read_text())
root_target = {'official': {'source': {'token': 'keep'}}}
restore.merge_preferences(root_target, root_payload, {}, [])
assert root_target['official']['source']['token'] == 'keep'
assert root_target['official']['source']['url'] == 'https://fixture.invalid/root'
maps_only = copy.deepcopy(selection)
maps_only.pop('string_arrays')
capture.validate_spec(spec(maps_only))
for invalid in [dict(selection, maps=[{'path': ['plugins'], 'fields': [['api_key']]}]),
                dict(selection, string_arrays=[['secret']]),
                dict(selection, maps=[{'path': ['plugins'], 'scalar_values': True, 'fields': [['name']]}])]:
    try:
        capture.validate_spec(spec(invalid))
    except ValueError:
        pass
    else:
        raise AssertionError('unsafe selection accepted')
for bad in [
    {'maps': [{'path': ['plugins'], 'entries': [{'key': 'x', 'value': 1}, {'key': 'x', 'value': 2}]}]},
    {'maps': [{'path': ['plugins'], 'entries': [{'key': 'x', 'value': {'nested': 'bad'}}]}]},
    {'maps': [{'path': ['plugins'], 'entries': [{'key': 'x', 'fields': [{'path': ['api_key'], 'value': 'bad'}]}]}]},
    {'fields': [{'path': ['disabled'], 'value': ['not-explicitly-selected']}]},
]:
    try:
        restore.merge_preferences({}, bad, {}, [])
    except (restore.RestoreError, ValueError):
        pass
    else:
        raise AssertionError('bad payload accepted')
url_source = root / 'url.json'
url_source.write_text(json.dumps({'official': {'source': {'url': 'https://user:private-pass@fixture.invalid/repo?secret=private-query'}}}))
url_tasks, _ = capture.preferences(url_source, root_selection, root / 'url-payload', {})
url_payload = json.loads((root / 'url-payload/preferences.json').read_text())
assert any(x['reason'] == 'url-components-redacted' for x in url_tasks)
assert 'private-pass' not in json.dumps(url_payload) + json.dumps(url_tasks)
assert 'private-query' not in json.dumps(url_payload) + json.dumps(url_tasks)
source.write_text('{"plugins":{"x":true,"x":false}}')
try:
    capture.preferences(source, maps_only, root / 'duplicate-payload', {})
except ValueError as error:
    assert str(error) == 'duplicate-preference-key'
else:
    raise AssertionError('duplicate source key accepted')
assert not (root / 'duplicate-payload').exists()
# Root maps must never become a whole-settings or activation-policy backdoor.
unsafe_root = dict(selection, maps=[{'path': [], 'scalar_values': True}])
for operation in [lambda: capture.validate_spec(spec(unsafe_root)),
                  lambda: capture.preferences(root_source, unsafe_root, root / 'unsafe-root', {})]:
    try:
        operation()
    except ValueError:
        pass
    else:
        raise AssertionError('root scalar map accepted')
assert not (root / 'unsafe-root').exists()
for identity in ['trust', 'sandbox', 'hooks', 'permissionMode', 'env', 'shell_environment_policy']:
    assert not valid_review_map_key(identity, root=True)
    for item in [{'key': identity, 'value': True},
                 {'key': identity, 'fields': [{'path': ['enabled'], 'value': True}]}]:
        try:
            restore.merge_preferences({}, {'maps': [{'path': [], 'entries': [item]}]}, {}, [])
        except restore.RestoreError:
            pass
        else:
            raise AssertionError('unsafe root identity restored')
root_source.write_text(json.dumps({'hooks': {'source': {'url': 'https://fixture.invalid/unsafe'}},
    'official:market@author/package': {'source': {'url': 'https://fixture.invalid/safe'}}}))
unsafe_tasks, _ = capture.preferences(root_source, root_selection, root / 'root-filtered', {})
filtered = json.loads((root / 'root-filtered/preferences.json').read_text())
assert filtered['maps'][0]['entries'][0]['key'] == 'official:market@author/package'
assert len(filtered['maps'][0]['entries']) == 1
assert any(t['reason'] == 'unsafe-map-identity-not-captured' for t in unsafe_tasks)
try:
    restore.merge_preferences({}, {'maps': [{'path': [], 'entries': [{'key': 'normal', 'value': True}]}]}, {}, [])
except restore.RestoreError:
    pass
else:
    raise AssertionError('ordinary root scalar accepted')
print('PASS explicit preference maps and string-array selections')
PY
