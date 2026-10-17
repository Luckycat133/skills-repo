#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVICE_EXPORT_ROOT="$(mktemp -d)"
trap 'rm -rf "$DEVICE_EXPORT_ROOT"' EXIT
if command -v cygpath >/dev/null 2>&1; then
    DEVICE_EXPORT_ROOT="$(cygpath -w "$DEVICE_EXPORT_ROOT")"
    SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi
export DEVICE_EXPORT_ROOT SCRIPT_DIR
export PYTHONDONTWRITEBYTECODE=1

"${DEVICE_EXPORT_PYTHON:-python3}" - <<'PY'
import copy
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys

root = Path(os.environ['DEVICE_EXPORT_ROOT']).resolve()
scripts = Path(os.environ['SCRIPT_DIR']).resolve()
home, workspace = root / 'home', root / 'project'
home.mkdir()
workspace.mkdir()
environment = dict(os.environ, HOME=str(home), AGENT_SKILLS_PLATFORM='linux', PYTHONDONTWRITEBYTECODE='1')
environment.pop('CLINE_DATA_DIR', None)


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def tree(directory):
    return {path.relative_to(directory).as_posix(): ('file', hashlib.sha256(path.read_bytes()).hexdigest())
            if path.is_file() else ('directory', None) for path in directory.rglob('*')}


def run(script, arguments, *, success=True):
    result = subprocess.run([sys.executable, '-B', str(script), *map(str, arguments)],
                            cwd=root, env=environment, text=True, capture_output=True)
    try:
        output = json.loads(result.stdout)
    except ValueError:
        raise AssertionError(('non-JSON helper output', result.returncode, result.stdout, result.stderr))
    assert bool(output.get('ok')) == success, (arguments, output, result.stderr)
    assert (result.returncode == 0) == success, (arguments, result.returncode, output)
    return output


skill = '---\nname: fixture\ndescription: Device exporter regression fixture.\n---\nKeep fixture context.\n'
write(home / '.cline/skills/fixture/SKILL.md', skill)
write(workspace / '.cline/skills/project-fixture/SKILL.md', skill.replace('name: fixture', 'name: project-fixture'))
write(home / '.cursor/skills/not-selected/SKILL.md', skill.replace('name: fixture', 'name: not-selected'))
write(home / '.gemini/skills/not-selected/SKILL.md', skill.replace('name: fixture', 'name: not-selected'))
write(workspace / 'keep.txt', 'Project repositories are not copied by the exporter.\n')
write(workspace / '.cline/local-rule.md', 'LOCAL_SCOPE_ONLY_MARKER\n')
manual = root / 'manual-source'
write(manual / 'rule.md', 'Review this native client rule before reconstruction.\n')
registry = json.loads((scripts.parent / 'references/registry-v2.json').read_text())
profile = copy.deepcopy(registry['products']['cline']['profiles']['ide'])
profile['detection'] = []
profile['platforms'] = {}
profile['surfaces']['instructions'].append({
    'format': 'cline-rule', 'path': '.cline/local-rule.md', 'scope': 'local',
    'policy': 'semantic-ir-with-loss-report', 'storage': 'file',
})
registry['products'] = {'cline': {'default_profile': 'ide', 'profiles': {'ide': profile}}}
registry_path = root / 'fixture-registry.json'
registry_path.write_text(json.dumps(registry))
spec = {
    'schema_version': 1,
    'clients': [
        {'id': 'native-fixture', 'label': 'Native fixture', 'native_profiles': [
            {'selector': 'cline/ide', 'registry': str(registry_path), 'scopes': ['user', 'project']}]},
        {'id': 'manual-fixture', 'label': 'Manual fixture', 'native_profiles': []},
    ],
    'workspaces': [{'id': 'fixture-project', 'path': str(workspace)}],
    'review': {'schema_version': 1, 'clients': [{'id': 'manual-fixture', 'label': 'Manual fixture',
        'sources': [{'id': 'rule', 'kind': 'text', 'path': str(manual)}]}]},
    'private_note': 'sk-' + 'b' * 40,
}
spec_path = root / 'scope.json'
spec_path.write_text(json.dumps(spec))
output = root / 'packet'
before_home, before_workspace, before_manual = tree(home), tree(workspace), tree(manual)
dry = run(scripts / 'device-export.py', ['--spec', spec_path, '--output', output, '--dry-run'])
assert dry['dry_run'] is True
assert set(dry['selected_clients']) == {'native-fixture', 'manual-fixture'}
assert not output.exists()
assert tree(home) == before_home and tree(workspace) == before_workspace and tree(manual) == before_manual
print('OK explicit export dry-run is read-only for all source configurations and output')

exported = run(scripts / 'device-export.py', ['--spec', spec_path, '--output', output])
assert exported['captures'] == 2 and exported['recipes'] == 2, exported
assert set(exported['selected_clients']) == {'native-fixture', 'manual-fixture'}
if os.name == 'posix':
    assert stat.S_IMODE(output.stat().st_mode) == 0o700
index = json.loads((output / 'device-index.json').read_text())
assert {item['source'] for item in index['recipes']} == {'cline/ide'}
assert {item['target'] for item in index['recipes']} == {'cline/ide'}
assert {item['client'] for item in index['captures']} == {'native-fixture'}
assert all(client['capture_status'] == 'captured-with-pending-acceptance' and client['next_actions']
           for client in index['selected_clients'])
for capture in index['captures']:
    manifest = json.loads((output / capture['bundle'] / 'manifest.json').read_text())
    assert all(item['product'] == 'cline' and item['profile'] == 'ide' for item in manifest['objects'])
    assert all('not-selected' not in file['path'] for item in manifest['objects'] for file in item.get('files', []))
    assert not any(item['scope'] == 'local' for item in manifest['objects'])
checksums = json.loads((output / 'PACKET-SHA256.json').read_text())
assert {'skill/scripts/context-migrator.py', 'skill/scripts/device-export.py',
        'skill/scripts/device-restore.py', 'skill/scripts/capture-review-sources.py',
        'AGENT-START-HERE.md', 'scope.json', 'coverage.json', 'review/index.json'} <= checksums.keys()
actual = {path.relative_to(output).as_posix() for path in output.rglob('*') if path.is_file()}
assert actual == set(checksums) | {'PACKET-SHA256.json'}
assert not any(path.name.endswith('-spec.json') or path.name == 'review-spec.json' for path in output.rglob('*'))
assert spec['private_note'] not in (output / 'scope.json').read_text()
assert 'private_note' not in json.loads((output / 'scope.json').read_text())
for name, digest in checksums.items():
    assert hashlib.sha256((output / name).read_bytes()).hexdigest() == digest
review_index = json.loads((output / 'review/index.json').read_text())
assert [client['id'] for client in review_index['clients']] == ['manual-fixture']
for client in review_index['clients']:
    for source in client['sources']:
        assert (output / 'review' / source['report']).is_file()
        for file in source['files']:
            path = output / 'review' / file['path']
            assert path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == file['sha256']
assert tree(home) == before_home and tree(workspace) == before_workspace and tree(manual) == before_manual
run(output / 'skill/scripts/device-restore.py', ['verify', '--packet', output])
listed = run(output / 'skill/scripts/device-restore.py', ['list', '--packet', output])
assert len(listed['recipes']) == 2
print('OK explicit clients do not broaden; self-contained runtime, review bindings and packet verify/list all work')

def rejection(variant, destination):
    candidate = root / 'invalid-scope.json'
    candidate.write_text(json.dumps(variant))
    result = run(scripts / 'device-export.py', ['--spec', candidate, '--output', destination, '--dry-run'], success=False)
    assert not destination.exists()
    assert tree(home) == before_home and tree(workspace) == before_workspace
    return result


variant = copy.deepcopy(spec)
variant['review']['clients'][0]['id'] = 'unselected-client'
rejection(variant, root / 'unselected-packet')
rejection(spec, workspace / 'packet-inside-project')
rejection(spec, manual / 'packet-inside-source')
run(scripts / 'device-export.py', ['--spec', spec_path, '--output', output], success=False)
print('OK unselected review client, source/workspace overlap and overwrite attempts are rejected before capture')

# Product-like directory names are data. Credential-shaped source paths must
# be hashed/redacted in metadata, not rejected by scanning the executable spec.
token = 'sk-' + 'a' * 40
token_source = root / token / 'rule.md'
write(token_source, 'Safe source text in a sensitive-looking directory name.\n')
token_spec = {'schema_version': 1, 'clients': [{'id': 'manual-only', 'label': 'Manual only'}],
              'review': {'schema_version': 1, 'clients': [{'id': 'manual-only', 'label': 'Manual only',
                  'sources': [{'id': 'rule', 'kind': 'text', 'path': str(token_source)}]}]}}
token_path = root / 'token-path-spec.json'
token_path.write_text(json.dumps(token_spec))
token_packet = root / 'token-path-packet'
run(scripts / 'device-export.py', ['--spec', token_path, '--output', token_packet, '--dry-run'])
run(scripts / 'device-export.py', ['--spec', token_path, '--output', token_packet])
for path in token_packet.rglob('*'):
    if path.is_file() and not str(path.relative_to(token_packet)).startswith('skill/'):
        assert token.encode() not in path.read_bytes(), path.relative_to(token_packet)
run(token_packet / 'skill/scripts/device-restore.py', ['verify', '--packet', token_packet])
print('OK credential-shaped paths remain usable as source identities without leaking into the packet')

# Workspace IDs are user metadata; an ID of user must not collide with the
# exporter's separate user-global capture for the same native profile.
collision_spec = copy.deepcopy(spec)
collision_spec['workspaces'][0]['id'] = 'user'
collision_path = root / 'collision-scope.json'
collision_path.write_text(json.dumps(collision_spec))
collision_packet = root / 'collision-packet'
preview = run(scripts / 'device-export.py', ['--spec', collision_path, '--output', collision_packet, '--dry-run'])
assert preview['dry_run'] is True
result = run(scripts / 'device-export.py', ['--spec', collision_path, '--output', collision_packet])
assert result['captures'] == 2
captures = json.loads((collision_packet / 'device-index.json').read_text())['captures']
assert len({capture['id'] for capture in captures}) == 2
run(collision_packet / 'skill/scripts/device-restore.py', ['verify', '--packet', collision_packet])
print('OK user-global and project captures cannot collide through a workspace ID')

for scopes in (['local'], ['project', 'local']):
    scoped_spec = copy.deepcopy(spec)
    scoped_spec['clients'][0]['native_profiles'][0]['scopes'] = scopes
    scoped_path = root / ('scope-' + '-'.join(scopes) + '.json')
    scoped_path.write_text(json.dumps(scoped_spec))
    scoped_output = root / ('packet-' + '-'.join(scopes))
    result = run(scripts / 'device-export.py', ['--spec', scoped_path, '--output', scoped_output])
    assert result['captures'] == 1
    scoped_index = json.loads((scoped_output / 'device-index.json').read_text())
    captured = scoped_index['captures'][0]
    recovery = json.loads((scoped_output / captured['bundle'] / 'recovery.json').read_text())
    assert set(recovery['scope']['scopes']) == set(scopes)
    assert all(row['scope'] in scopes for row in recovery['coverage'])
    assert any(row['scope'] == 'local' for row in recovery['coverage'])
    run(scoped_output / 'skill/scripts/device-restore.py', ['verify', '--packet', scoped_output])
print('OK project scope stays exact; explicit local and combined project/local capture once per workspace')

# Merely listing a project must not opt it into an ordinary device backup.
default_spec = copy.deepcopy(spec)
default_spec['clients'][0]['native_profiles'][0].pop('scopes')
default_path = root / 'default-user-scope.json'
default_path.write_text(json.dumps(default_spec))
default_packet = root / 'default-user-packet'
result = run(scripts / 'device-export.py', ['--spec', default_path, '--output', default_packet])
assert result['captures'] == 1
default_index = json.loads((default_packet / 'device-index.json').read_text())
assert all(row['kind'] == 'user-global' for row in default_index['captures'])
default_bundle = default_packet / default_index['captures'][0]['bundle']
default_recovery = json.loads((default_bundle / 'recovery.json').read_text())
assert default_recovery['scope']['scopes'] == ['user']
assert not any(path.is_file() and b'LOCAL_SCOPE_ONLY_MARKER' in path.read_bytes() for path in default_bundle.rglob('*'))
run(default_packet / 'skill/scripts/device-restore.py', ['verify', '--packet', default_packet])
print('OK default device capture excludes project/local context even with a listed workspace; explicit project support remains available')

pending_spec = {'schema_version': 1, 'clients': [
    {'id': 'unlocated-client', 'label': 'Selected client without located sources'},
    {'id': 'missing-client', 'label': 'Selected client with a missing source'}],
    'review': {'schema_version': 1, 'clients': [{'id': 'missing-client', 'label': 'Missing source',
        'sources': [{'id': 'missing', 'kind': 'text', 'path': str(root / 'not-present-source')}]}]}}
pending_path = root / 'pending-scope.json'
pending_path.write_text(json.dumps(pending_spec))
pending_output = root / 'pending-packet'
result = run(scripts / 'device-export.py', ['--spec', pending_path, '--output', pending_output])
assert result['captures'] == 0 and result['recipes'] == 0
coverage = json.loads((pending_output / 'coverage.json').read_text())
assert {client['id'] for client in coverage['selected_clients']} == {'unlocated-client', 'missing-client'}
for client in coverage['selected_clients']:
    assert client['capture_status'] == 'not-captured' and client['review_files'] == 0
    assert client['next_actions'] and client['native_discovery'] == 'not-run-on-target'
assert coverage['all_native_verified'] is False
assert coverage['review_clients'][0]['sources'][0]['status'] == 'missing'
run(pending_output / 'skill/scripts/device-restore.py', ['verify', '--packet', pending_output])
print('OK selected clients with absent or unlocated sources remain explicit pending agent work, never a restoration claim')
PY
