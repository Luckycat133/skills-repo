#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAPTURE_REVIEW_TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$CAPTURE_REVIEW_TEST_ROOT"' EXIT
if command -v cygpath >/dev/null 2>&1; then
    CAPTURE_REVIEW_TEST_ROOT="$(cygpath -w "$CAPTURE_REVIEW_TEST_ROOT")"
    SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi
export CAPTURE_REVIEW_TEST_ROOT SCRIPT_DIR

python3 -B - <<'PY'
import hashlib
import importlib.util
import json
import os
import sqlite3
import stat
import subprocess
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

root = Path(os.environ['CAPTURE_REVIEW_TEST_ROOT']).resolve()
helper = Path(os.environ['SCRIPT_DIR']) / 'capture-review-sources.py'
sys.path.insert(0, str(helper.parent))
from acb.preferences import UnsupportedYAML, _decode_preferences

# The same data-only decoder is used for target-side merge verification. It
# preserves unselected credentials as data rather than scanning the whole file.
assert _decode_preferences(b'{}\n', 'yaml') == {}
emitted_fixture = b'''"empty": {}
"roles": []
"models":
  -
    "name": "Quoted target model"
    "roles":
      - "chat"
      - "edit"
"account":
  "apiKey": "target-only-unselected-credential"
'''
decoded = _decode_preferences(emitted_fixture, 'yaml')
assert decoded['models'][0] == {'name': 'Quoted target model', 'roles': ['chat', 'edit']}
assert decoded['account']['apiKey'] == 'target-only-unselected-credential'
assert _decode_preferences(b'models:\n- name: fixture\n  roles:\n  - chat\nnext: true\n', 'yml') == {
    'models': [{'name': 'fixture', 'roles': ['chat']}], 'next': True}
for rejected in (b'a: &anchor value\n', b'a: *alias\n', b'a: !tag value\n',
                 b'<<: ignored\n', b'a: {nested: flow-map}\n', b'a: |\n  block text\n',
                 b'a: one\n---\nb: two\n', b'---\n---\n', b'a: one\na: two\n',
                 b'a:\n\tb: tab-indentation\n', b'a: [' + b'1' * 300 + b']\n'):
    try:
        _decode_preferences(rejected, 'yaml')
    except UnsupportedYAML:
        pass
    else:
        raise AssertionError('Unsupported YAML was silently interpreted')
print('OK bounded YAML decoder handles target emitter shapes and preserves unselected values without executing complex constructs')
home, external = root / 'home', root / 'reviewed-linked-root'
home.mkdir()
environment = dict(os.environ, HOME=str(home), PYTHONDONTWRITEBYTECODE='1')
source = home / '.unknown'
secret_values = ('synthetic-unknown-literal-value', 'synthetic-map-literal', 'synthetic-query-literal', 'synthetic-sibling-literal', 'synthetic-userinfo-literal')


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data if isinstance(data, bytes) else data.encode())


def skill(path, name):
    text = f'---\nname: {name}\ndescription: Supplemental capture fixture.\n---\n# {name}\n'
    write(path / 'SKILL.md', text)
    return text.encode()


def state(directory):
    result = {}
    for path in directory.rglob('*'):
        key = path.relative_to(directory).as_posix()
        if path.is_symlink():
            result[key] = ('link', os.readlink(path))
        elif path.is_file():
            result[key] = ('file', hashlib.sha256(path.read_bytes()).hexdigest())
        else:
            result[key] = ('directory', None)
    return result


good_bytes = skill(source / 'skills/good', 'good')
skill(source / 'skills/bad', 'bad')
write(source / 'skills/bad/references/example.md', 'password=' + secret_values[0] + '\n')
linked_bytes = skill(external / 'linked', 'linked')
outside = root / 'unapproved-root'
skill(outside / 'unsafe', 'unsafe')
write(source / 'texts/check.md', 'Review this text. Never activate without review.\n')
write(source / 'texts/check.sh', '#!/bin/sh\ntouch "$CAPTURE_REVIEW_EXECUTION_SENTINEL"\n')
write(source / 'texts/unsafe.md', 'password=' + secret_values[0] + '\n')
write(source / 'texts/.env', 'Not portable environment fixture.\n')
write(source / 'texts/image.png', b'\x89PNG\x00binary fixture')
write(source / 'shared.json', json.dumps({
    'mcpServers': {
        'remote': {'url': 'https://fixture.invalid/mcp?custom=' + secret_values[2],
                   'headers': {'Custom-Auth': secret_values[1]}},
        'local': {'command': 'node', 'args': ['server.js'], 'env': {'CUSTOM': secret_values[1]}},
    },
    'account': {'password': secret_values[3]}, 'trust': True,
}))
write(source / 'preferences.json', json.dumps({
    'model': {'name': 'fixture-model'}, 'editor.fontSize': 15, 'optional': None,
    'custom': 'password=' + secret_values[0], 'notScalar': ['not a scalar'],
    'account': {'password': secret_values[3]},
}))
write(source / 'preferences.jsonc', '// explicit JSONC source\n{"model": "jsonc-fixture"}\n')
write(source / 'preferences.toml', 'model = "toml-fixture"\n[account]\npassword = "' + secret_values[3] + '"\n')
write(source / 'model-records.json', json.dumps({
    'customModels': [
        {'id': 'first', 'model': 'fixture-a', 'displayName': 'First model', 'providerId': 'provider-a',
         'wireApi': 'responses', 'supportsMultimodal': True,
         'extra_body': {'reasoning': {'effort': 'high'}, 'auth': secret_values[1]}, 'apiKey': secret_values[1]},
        'Invalid array item',
        {'id': 'third', 'model': 'fixture-c', 'displayName': 'Third model'},
        {'id': 'secret-selected', 'model': 'password=' + secret_values[0]},
        {'id': {'not': 'scalar'}, 'model': 'invalid-id'},
    ],
    'customModelProviders': [
        {'id': 'provider-a', 'name': 'Provider A',
         'baseUrl': 'https://fixture-user:' + secret_values[4] + '@provider.invalid/api?sig=' + secret_values[2],
         'flashModelId': 'first', 'apiKey': secret_values[1], 'auth': {'token': secret_values[1]}},
        42,
        {'id': 'provider-c', 'name': 'Provider C', 'baseUrl': 'https://clean.invalid/api'},
    ],
    'unselected': {'password': secret_values[3]},
}))
yaml_bytes = ('''---
"name": "Codely fixture"
"models":
  - "name": "Quoted # first" # ordinary comment
    provider: openai
    model: "fixture-a"
    apiBase: "https://fixture-user:''' + secret_values[4] + '''@yaml.invalid/v1?sig=''' + secret_values[2] + '''"
    apiKey: "''' + secret_values[1] + '''"
    roles:
      - chat
      - edit
    defaultCompletionOptions:
      contextLength: 32768
  - name: invalid-roles
    model: fixture-b
    roles: [chat, 5]
  - not-an-object
  - name: valid-third-index
    model: fixture-c
    roles: [chat, apply]
''').encode()
write(source / 'config.yaml', yaml_bytes)
write(source / 'unsupported.yaml', 'models: &unsafe\n  - name: fixture\n    model: fixture\n')
write(source / 'tagged.yaml', 'models:\n  - name: fixture\n    model: !!python/object/apply:os.system [touch]\n')
write(source / 'duplicate.yaml', 'name: first\nname: second\nmodels: []\n')
database = source / 'state.vscdb'
writer = sqlite3.connect(database)
writer.execute('PRAGMA journal_mode=WAL')
writer.execute('PRAGMA wal_autocheckpoint=0')
writer.execute('CREATE TABLE ItemTable (key TEXT PRIMARY KEY, value TEXT)')
writer.execute('INSERT INTO ItemTable VALUES (?, ?)', ('fixture.mcp.storage', json.dumps({'mcpServers': {'base-stale': {'command': 'node'}}})))
writer.execute('INSERT INTO ItemTable VALUES (?, ?)', ('NEVER_EXPORT_SQLITE_OTHER_KEY', 'password=' + secret_values[3]))
writer.commit()
writer.execute('PRAGMA wal_checkpoint(TRUNCATE)')
sqlite_value = json.dumps({'mcpServers': {'wal-remote': {'url': 'https://wal.invalid/mcp?key=' + secret_values[2],
                                                        'headers': {'Custom-Auth': secret_values[1]}}},
                           'account': {'password': secret_values[3]}})
writer.execute('UPDATE ItemTable SET value = ? WHERE key = ?', (sqlite_value, 'fixture.mcp.storage'))
writer.commit()
reader = sqlite3.connect(database.resolve().as_uri() + '?mode=ro', uri=True)
reader.execute('SELECT value FROM ItemTable WHERE key = ?', ('fixture.mcp.storage',)).fetchone()
wrong_database = source / 'wrong-schema.vscdb'
with sqlite3.connect(wrong_database) as wrong:
    wrong.execute('CREATE TABLE DifferentTable (key TEXT, value TEXT)')
links_available = True
try:
    (source / 'skills/linked').symlink_to(external / 'linked', target_is_directory=True)
    (source / 'skills/unsafe-link').symlink_to(outside / 'unsafe', target_is_directory=True)
    (source / 'texts/linked.md').symlink_to(outside / 'unsafe/SKILL.md')
    (source / 'linked-config.json').symlink_to(source / 'shared.json')
except (OSError, NotImplementedError):
    links_available = False

sources = [
    {'id': 'skills', 'kind': 'skills', 'path': '~/.unknown/skills', 'linked_roots': [str(external)]},
    {'id': 'texts', 'kind': 'text', 'path': '~/.unknown/texts'},
    {'id': 'mcp', 'kind': 'mcp', 'path': '~/.unknown/shared.json', 'container': 'mcpServers'},
    {'id': 'missing', 'kind': 'text', 'path': '~/.unknown/missing.md'},
    {'id': 'preferences', 'kind': 'preferences', 'path': '~/.unknown/preferences.json', 'format': 'json',
     'fields': [['model', 'name'], ['editor.fontSize'], ['optional'], ['custom'], ['notScalar'], ['absent']]},
    {'id': 'preferences-jsonc', 'kind': 'preferences', 'path': '~/.unknown/preferences.jsonc', 'format': 'jsonc', 'fields': [['model']]},
    {'id': 'preferences-toml', 'kind': 'preferences', 'path': '~/.unknown/preferences.toml', 'format': 'toml', 'fields': [['model']]},
    {'id': 'model-records', 'kind': 'preferences', 'path': '~/.unknown/model-records.json', 'format': 'json',
     'records': [
         {'path': ['customModels'], 'fields': [['id'], ['model'], ['displayName'], ['providerId'], ['wireApi'], ['supportsMultimodal'], ['extra_body', 'reasoning', 'effort']]},
         {'path': ['customModelProviders'], 'fields': [['id'], ['name'], ['baseUrl'], ['flashModelId']]},
     ]},
    {'id': 'yaml-models', 'kind': 'preferences', 'path': '~/.unknown/config.yaml', 'format': 'yaml',
     'fields': [['name']], 'records': [{'path': ['models'], 'fields': [['name'], ['provider'], ['model'], ['apiBase'], ['roles'], ['defaultCompletionOptions', 'contextLength']]}]},
    *[{'id': name, 'kind': 'preferences', 'path': '~/.unknown/' + filename, 'format': 'yaml',
       'records': [{'path': ['models'], 'fields': [['name'], ['model'], ['roles']]}]}
      for name, filename in (('yaml-unsupported', 'unsupported.yaml'), ('yaml-tagged', 'tagged.yaml'), ('yaml-duplicate', 'duplicate.yaml'))],
    {'id': 'sqlite-mcp', 'kind': 'mcp-sqlite', 'path': '~/.unknown/state.vscdb', 'sqlite_key': 'fixture.mcp.storage', 'container': 'mcpServers'},
    {'id': 'sqlite-missing', 'kind': 'mcp-sqlite', 'path': '~/.unknown/state.vscdb', 'sqlite_key': "not-present' OR 1=1--", 'container': 'mcpServers'},
    {'id': 'sqlite-schema', 'kind': 'mcp-sqlite', 'path': '~/.unknown/wrong-schema.vscdb', 'sqlite_key': 'fixture.mcp.storage', 'container': 'mcpServers'},
]
if links_available:
    sources.append({'id': 'linked-config', 'kind': 'mcp', 'path': '~/.unknown/linked-config.json'})
spec = root / 'spec.json'
spec.write_text(json.dumps({'schema_version': 1, 'clients': [
    {'id': 'unknown-client', 'label': 'Unknown client 审查', 'sources': sources}]}))
before = state(home), state(external), state(outside)


def invoke(output, success=True):
    result = subprocess.run([sys.executable, '-B', str(helper), '--spec', str(spec), '--output', str(output)],
                            env=environment, text=True, capture_output=True)
    assert 'Traceback' not in result.stderr, result.stderr
    data = json.loads(result.stdout)
    assert (result.returncode == 0) == success and data.get('ok') == success, (data, result.stderr)
    return data


output = root / 'portable review 中文'
captured = invoke(output)
assert captured['inert_review_only'] is True and captured['automatic_restore'] is False
if os.name != 'nt':
    assert stat.S_IMODE(output.stat().st_mode) == 0o700
index = json.loads((output / 'index.json').read_text())
assert index['clients'][0]['label'] == 'Unknown client 审查'
reports = {row['id']: json.loads((output / row['report']).read_text())
           for row in index['clients'][0]['sources']}
assert reports['skills']['source_canonical'] == '~/.unknown/skills'
assert reports['skills']['status'] == 'partial'
skill_payloads = reports['skills']['payloads']
assert any((output / row['path']).read_bytes() == good_bytes for row in skill_payloads)
bad_package = next(task for task in reports['skills']['tasks'] if task['name'] == 'bad')
assert bad_package['status'] == 'staged-partial' and bad_package['redactions']
assert bad_package['complete'] is True
assert any('/bad/' in row['path'] for row in skill_payloads)
assert all(item['source_sha256'] for task in reports['skills']['tasks'] for item in task['files'])
if links_available:
    assert any((output / row['path']).read_bytes() == linked_bytes for row in skill_payloads)
    assert any(task['name'] == 'unsafe-link' and task['status'] == 'excluded' for task in reports['skills']['tasks'])
    assert reports['linked-config']['status'] == 'excluded'
    assert reports['linked-config']['tasks'][0]['reason'] == 'symlink-not-captured'
    assert any(task['reason'] == 'symlink-not-captured' for task in reports['texts']['tasks'])
assert reports['missing']['status'] == 'missing' and reports['missing']['payloads'] == []
assert len(reports['texts']['payloads']) == 2
assert len(reports['mcp']['payloads']) == 2
definitions = [json.loads((output / row['path']).read_text()) for row in reports['mcp']['payloads']]
remote = next(row for row in definitions if row['server_name'] == 'remote')
assert remote['definition']['url'] == 'https://fixture.invalid/mcp'
assert remote['definition']['headers']['Custom-Auth'].startswith('${')
local = next(row for row in definitions if row['server_name'] == 'local')
assert local['definition']['env']['CUSTOM'] == '${CUSTOM}'
assert reports['preferences']['status'] == 'partial'
preference_copy = json.loads((output / reports['preferences']['payloads'][0]['path']).read_text())
assert preference_copy['fields'] == [
    {'path': ['model', 'name'], 'value': 'fixture-model'},
    {'path': ['editor.fontSize'], 'value': 15}, {'path': ['optional'], 'value': None}]
assert {task['reason'] for task in reports['preferences']['tasks']} == {
    'secret-not-captured', 'field-not-scalar-or-finite', 'field-not-present'}
assert reports['preferences-jsonc']['status'] == 'captured-review'
if sys.version_info >= (3, 11):
    assert reports['preferences-toml']['status'] == 'captured-review'
else:
    assert reports['preferences-toml']['status'] == 'excluded'
    assert reports['preferences-toml']['tasks'][0]['reason'] == 'missing-tomllib-parser'
assert reports['model-records']['status'] == 'partial'
record_copy = json.loads((output / reports['model-records']['payloads'][0]['path']).read_text())
assert record_copy['fields'] == []
model_array, provider_array = record_copy['records']
assert model_array['path'] == ['customModels'] and model_array['source_length'] == 5
assert [item['index'] for item in model_array['items']] == [0, 2]
assert {'path': ['extra_body', 'reasoning', 'effort'], 'value': 'high'} in model_array['items'][0]['fields']
assert provider_array['path'] == ['customModelProviders'] and provider_array['source_length'] == 3
assert [item['index'] for item in provider_array['items']] == [0, 2]
assert {'path': ['baseUrl'], 'value': 'https://provider.invalid/api'} in provider_array['items'][0]['fields']
record_tasks = reports['model-records']['tasks']
assert any(task['reason'] == 'record-item-not-object' and task['index'] == 1 for task in record_tasks)
assert {task['index'] for task in record_tasks if task['reason'] == 'record-item-rejected'} == {3, 4}
url_task = next(task for task in record_tasks if task['reason'] == 'url-components-redacted')
assert url_task['record_path'] == ['customModelProviders'] and url_task['index'] == 0
assert url_task['userinfo_omitted'] is True and url_task['omitted_query_fields'] == ['sig']
assert b'apiKey' not in json.dumps(record_copy).encode() and b'fixture-user' not in json.dumps(record_copy).encode()
yaml_report = reports['yaml-models']
assert yaml_report['status'] == 'partial'
yaml_copy = json.loads((output / yaml_report['payloads'][0]['path']).read_text())
assert yaml_report['source_content_sha256'] == hashlib.sha256(yaml_bytes).hexdigest()
assert yaml_copy['source_content_sha256'] == yaml_report['source_content_sha256']
yaml_models = yaml_copy['records'][0]
assert yaml_models['path'] == ['models'] and yaml_models['source_length'] == 4
assert [item['index'] for item in yaml_models['items']] == [0, 3]
assert {'path': ['roles'], 'value': ['chat', 'edit']} in yaml_models['items'][0]['fields']
assert {'path': ['apiBase'], 'value': 'https://yaml.invalid/v1'} in yaml_models['items'][0]['fields']
assert {'path': ['defaultCompletionOptions', 'contextLength'], 'value': 32768} in yaml_models['items'][0]['fields']
for source_id in ('yaml-unsupported', 'yaml-tagged', 'yaml-duplicate'):
    assert reports[source_id]['status'] == 'excluded' and reports[source_id]['payloads'] == []
    assert reports[source_id]['source_content_sha256']
    assert reports[source_id]['tasks'][0]['reason'] == 'yaml-unsupported-or-invalid'
sqlite_report = reports['sqlite-mcp']
assert sqlite_report['source_content_sha256'] == hashlib.sha256(database.read_bytes()).hexdigest()
assert sqlite_report['source_value_sha256'] == hashlib.sha256(sqlite_value.encode()).hexdigest()
assert sqlite_report['source_wal_sha256'] == hashlib.sha256(Path(str(database) + '-wal').read_bytes()).hexdigest()
assert 'source-shm-untouched' in sqlite_report['sqlite_capture']
sqlite_copy = json.loads((output / sqlite_report['payloads'][0]['path']).read_text())
assert sqlite_copy['server_name'] == 'wal-remote' and sqlite_copy['definition']['url'] == 'https://wal.invalid/mcp'
assert reports['sqlite-missing']['status'] == 'excluded'
assert reports['sqlite-missing']['tasks'][0]['reason'] == 'sqlite-key-not-present'
assert reports['sqlite-schema']['status'] == 'excluded'
assert reports['sqlite-schema']['tasks'][0]['reason'] == 'sqlite-read-failed'
module_spec = importlib.util.spec_from_file_location('review_capture_fixture', helper)
capture_module = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(capture_module)
sqlite_spec = {'sqlite_key': 'fixture.mcp.storage', 'path': '~/.unknown/state.vscdb', 'container': 'mcpServers'}
with patch.object(capture_module, 'MAX_TOTAL_SIZE', 1):
    rejected_files, rejected_tasks = capture_module.sqlite_mcp(database, sqlite_spec, 'unknown-client', {})
assert rejected_files == {} and rejected_tasks[0]['reason'] == 'sqlite-source-unsafe-or-too-large'
real_sha256 = hashlib.sha256
digest_calls = [0]
def changing_digest(*args, **kwargs):
    digest_calls[0] += 1
    result = real_sha256(*args, **kwargs)
    if digest_calls[0] == 4:
        altered = MagicMock(wraps=result)
        altered.hexdigest.return_value = '0' * 64
        return altered
    return result
with patch.object(capture_module.hashlib, 'sha256', changing_digest):
    rejected_files, rejected_tasks = capture_module.sqlite_mcp(database, sqlite_spec, 'unknown-client', {})
assert rejected_files == {} and rejected_tasks[0]['reason'] == 'sqlite-source-changed-during-capture'
all_bytes = b''.join(path.read_bytes() for path in output.rglob('*') if path.is_file())
assert all(value.encode() not in all_bytes for value in secret_values)
assert b'"account"' not in all_bytes and b'"trust"' not in all_bytes
assert b'NEVER_EXPORT_SQLITE_OTHER_KEY' not in all_bytes and b'fixture.mcp.storage' not in all_bytes
assert b'SQLite format 3\x00' not in all_bytes
for report in reports.values():
    assert report['automatic_restore'] is False and report['next_actions']
    for binding in report['payloads']:
        assert hashlib.sha256((output / binding['path']).read_bytes()).hexdigest() == binding['sha256']
for row in index['clients'][0]['sources']:
    assert {'id', 'kind', 'canonical', 'source_root', 'status', 'files', 'exclusions', 'next_actions'} <= row.keys()
    assert row['files'] == reports[row['id']]['payloads']
    if reports[row['id']].get('source_content_sha256'):
        assert row['source_content_sha256'] == reports[row['id']]['source_content_sha256']
assert not any(path.is_symlink() for path in output.rglob('*'))
assert not (root / 'CAPTURE_REVIEW_EXECUTION_SENTINEL').exists()
assert (state(home), state(external), state(outside)) == before, [
    sorted(name for name in set(old) | set(new) if old.get(name) != new.get(name))
    for old, new in zip(before, (state(home), state(external), state(outside)))]
checksums = json.loads((output / 'checksums.json').read_text())
assert set(checksums) == {path.relative_to(output).as_posix() for path in output.rglob('*')
                         if path.is_file() and path.name != 'checksums.json'}
assert all(hashlib.sha256((output / name).read_bytes()).hexdigest() == value for name, value in checksums.items())
print('OK inert Skills/text/MCP/preferences, explicit linked roots, field allowlists, complete reports, redaction, hashes and source preservation')

captured_before = state(output)
invoke(output, success=False)
assert state(output) == captured_before
invoke(source / 'texts/new-output', success=False)
assert not (source / 'texts/new-output').exists()
invoke(external / 'overlap-output', success=False)
assert not (external / 'overlap-output').exists()
collision_file = root / 'existing-file'
collision_file.write_text('Preserve this output collision.\n')
invoke(collision_file, success=False)
assert collision_file.read_text() == 'Preserve this output collision.\n'
invalid_spec = json.loads(spec.read_text())
invalid_spec['clients'][0]['sources'][-1] = {
    'id': 'unsafe-preference', 'kind': 'preferences', 'path': '~/.unknown/preferences.json',
    'format': 'json', 'fields': [['api_key']]}
spec.write_text(json.dumps(invalid_spec))
unsafe_output = root / 'unsafe-preference-output'
invoke(unsafe_output, success=False)
assert not unsafe_output.exists()
invalid_spec['clients'][0]['sources'][-1] = {
    'id': 'unsafe-record', 'kind': 'preferences', 'path': '~/.unknown/model-records.json',
    'format': 'json', 'records': [{'path': ['customModels'], 'fields': [['apiKey']]}]}
spec.write_text(json.dumps(invalid_spec))
unsafe_record_output = root / 'unsafe-record-output'
invoke(unsafe_record_output, success=False)
assert not unsafe_record_output.exists()
assert (state(home), state(external), state(outside)) == before
reader.close()
writer.close()
print('OK collisions and source/allowed-root overlaps fail without replacing data')
print('Capture review sources tests passed; no native restore or activation is performed')
PY
