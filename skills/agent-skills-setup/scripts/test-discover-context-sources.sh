#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISCOVERY_TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$DISCOVERY_TEST_ROOT"' EXIT
if command -v cygpath >/dev/null 2>&1; then
    DISCOVERY_TEST_ROOT="$(cygpath -w "$DISCOVERY_TEST_ROOT")"
    SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi
export DISCOVERY_TEST_ROOT SCRIPT_DIR
export PYTHONDONTWRITEBYTECODE=1

"${DISCOVERY_TEST_PYTHON:-python3}" -B - <<'PY'
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sqlite3
import stat
import subprocess
import sys

root = Path(os.environ['DISCOVERY_TEST_ROOT']).resolve()
scripts = Path(os.environ['SCRIPT_DIR']).resolve()
helper = scripts / 'discover-context-sources.py'
home, workspace, external = root / 'home', root / 'project', root / 'external'
for directory in (home, workspace, external):
    directory.mkdir()
environment = dict(os.environ, HOME=str(home), USERPROFILE=str(home), PYTHONDONTWRITEBYTECODE='1')
selected = ['trae', 'codex', 'antigravity', 'claude-code', 'tuanjie', 'workbuddy']
private_value = 'synthetic-unselected-sensitive-literal'
has_tomllib = importlib.util.find_spec('tomllib') is not None


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value)


def skill(path, name='fixture'):
    write(path / 'SKILL.md', '---\nname: ' + name + '\ndescription: Discovery fixture.\n---\nKeep source context.\n')


def tree(directory):
    result = {}
    for path in directory.rglob('*'):
        relative = path.relative_to(directory).as_posix()
        if path.is_symlink():
            result[relative] = ('link', os.readlink(path))
        elif path.is_file():
            result[relative] = ('file', hashlib.sha256(path.read_bytes()).hexdigest())
        else:
            result[relative] = ('directory', None)
    return result


def run(output, clients=selected, *extra, success=True):
    result = subprocess.run([sys.executable, '-B', str(helper), '--clients', ','.join(clients),
                             '--workspace', 'fixture=' + str(workspace), '--output', str(output), *extra],
                            env=environment, cwd=root, capture_output=True, text=True)
    assert 'Traceback' not in result.stderr and private_value not in result.stdout + result.stderr
    payload = json.loads(result.stdout)
    assert payload['ok'] is success and (result.returncode == 0) is success, (payload, result.stderr)
    return payload


skill(home / '.trae/skills/direct')
skill(home / '.trae-cn/skills/solo-context', 'solo-context')
skill(home / '.agents/skills/native')
skill(home / '.codex/skills/legacy')
skill(home / '.gemini/config/skills/gravity')
skill(home / '.claude/skills/claude')
skill(home / '.codely-cli/skills/tuanjie')
skill(home / '.workbuddy/skills/@lingmoon96-dev/nested/tool', 'namespaced-tool')
skill(home / '.cursor/skills/never-selected')
skill(home / '.gemini/skills/not-antigravity')
skill(workspace / '.agents/skills/project')
skill(workspace / '.workbuddy/skills/project-workbuddy')
skill(external / 'linked')
write(home / '.workbuddy/skills/invalid/SKILL.md', '---\nname: invalid\n---\nNo description.\n')
write(home / '.claude/commands/review.sh', '#!/bin/sh\ntouch "$DISCOVERY_EXECUTION_SENTINEL"\n')
write(home / '.claude/agents/reviewer.md', 'Review only.\n')
write(home / '.codex/AGENTS.md', 'Global instructions.\n')
write(workspace / 'AGENTS.md', 'Project instructions.\n')
write(workspace / 'CLAUDE.local.md', 'Local scope instructions.\n')
write(home / '.claude/settings.json', json.dumps({'model': 'not-exported-model',
    'hooks': {'PreToolUse': [{'command': 'touch "$DISCOVERY_EXECUTION_SENTINEL"'}]},
    'enabledPlugins': {'fixture-claude@fixture-market': True},
    'account': {'password': private_value}}))
write(home / '.codely/config.yaml', 'name: fixture\nschema: v1\nmodels:\n  - name: Fixture\n    provider: fixture\n    model: fixture-model\n    apiBase: https://fixture.invalid\n    roles:\n      - chat\n    apiKey: ' + private_value + '\n')
write(home / '.workbuddy/mcp.json', json.dumps({'mcpServers': {'fixture': {'command': 'node', 'env': {'TOKEN': private_value}}}, 'account': private_value}))
write(home / '.workbuddy/settings.json', json.dumps({'enabledPlugins': {'fixture-workbuddy@fixture-market': False, 'unsupported-fixture': {'password': private_value}}, 'claw': {'token': private_value}}))
write(home / '.codex/config.toml', '[plugins."fixture-codex@fixture-market"]\nenabled = true\nopaque = "' + private_value + '"\n')
write(home / '.gemini/config/config.json', json.dumps({'userSettings': {'themeMode': 'fixture-dark', 'globalPermissionGrants': private_value},
    'plugins': {'fixture-gravity': {'installedFrom': {'id': 'fixture-gravity', 'marketplace': 'fixture-market', 'version': '1.2.3', 'opaque': private_value},
                                    'account': {'password': private_value}}, 'unsupported-fixture': private_value}}))
for index, base in enumerate(('.trae-cn/extensions', '.antigravity/extensions', '.antigravity-ide/extensions')):
    extension = home / base / ('publisher.fixture-' + str(index))
    write(extension / 'package.json', json.dumps({'publisher': 'fixture-publisher', 'name': 'fixture-extension-' + str(index), 'version': '1.0.' + str(index),
        'activationEvents': ['*'], 'scripts': {'install': 'touch "$DISCOVERY_EXECUTION_SENTINEL"'}, 'opaque': private_value}))
    (extension / 'runtime.node').write_bytes(b'\x7fELF\x00do-not-execute-or-capture')
write(home / '.antigravity/extensions/invalid/package.json', 'not json: ' + private_value)
for index in range(4):
    write(home / '.codex/automations' / ('authored-' + str(index)) / 'automation.toml', 'id = "fixture-' + str(index) + '"\nprompt = "Review fixture context."\n')
write(home / '.codex/automations/.run-jitter-salt', 'RUN_JITTER_SALT_NOT_FOR_EXPORT_' + private_value)
write(home / '.codex/automations/authored-0/state/session.md', private_value)
write(home / '.codex/automations/authored-0/state/automation.toml', 'Nested state is excluded: ' + private_value)

database = home / 'Library/Application Support/Trae CN/User/globalStorage/state.vscdb'
database.parent.mkdir(parents=True)
connection = sqlite3.connect(database)
connection.execute('CREATE TABLE ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB)')
connection.executemany('INSERT INTO ItemTable VALUES (?, ?)', [
    ('custom.mcp.config', json.dumps({'mcpServers': {'fixture': {'command': 'node', 'env': {'TOKEN': private_value}}}, 'account': private_value})),
    ('autoRunConfirm_IDE_mcp_alwaysRun', json.dumps({'token': private_value})),
    ('currentAgentData_fixture', json.dumps({'prompt': private_value, 'mcp_list': [{'name': 'reference-only'}]})),
    ('chat.session.mcp.config', json.dumps({'mcpServers': {'chat-secret': {'token': private_value}}})),
])
connection.commit()
connection.close()
other_db = home / 'Library/Application Support/TRAE SOLO CN/User/globalStorage/state.vscdb'
other_db.parent.mkdir(parents=True)
connection = sqlite3.connect(other_db)
connection.execute('CREATE TABLE OtherTable (payload BLOB)')
connection.commit()
connection.close()

links_available = True
try:
    (home / '.workbuddy/skills/linked').symlink_to(external / 'linked', target_is_directory=True)
    reference = home / '.workbuddy/skills/@lingmoon96-dev/nested/tool/references/source.md'
    reference.parent.mkdir(parents=True)
    write(external / 'reference.md', 'Referenced source context.\n')
    reference.symlink_to(external / 'reference.md')
    (home / '.antigravity/extensions/linked-extension').symlink_to(home / '.trae-cn/extensions/publisher.fixture-0', target_is_directory=True)
except (OSError, NotImplementedError):
    links_available = False

sentinel = root / 'source-script-executed'
environment['DISCOVERY_EXECUTION_SENTINEL'] = str(sentinel)
before = tree(home), tree(workspace), tree(external)
output = root / 'discovery'
result = run(output, selected, '--scopes', 'user,project,local')
scope = json.loads((output / 'scope.json').read_text())
report = json.loads((output / 'discovery.json').read_text())
assert scope['discovery_report'] == str(output / 'discovery.json')
assert [row['id'] for row in scope['clients']] == selected
assert set(row['id'] for row in scope['review']['clients']) == set(selected)
assert report['configuration_values_exported'] is True and report['automatic_restore_verified'] is False
assert 'identity and enabled-state inventory fields' in report['configuration_value_policy']
assert result['status'] == 'scope-draft-created-not-captured'
assert report['selection_basis'] == 'explicit-client-arguments-not-installation-detection'
assert not sentinel.exists() and before == (tree(home), tree(workspace), tree(external))
for path in output.iterdir():
    text = path.read_text()
    assert private_value not in text and 'not-exported-model' not in text and 'fixture-dark' not in text
    assert 'RUN_JITTER_SALT_NOT_FOR_EXPORT' not in text and '.run-jitter-salt' not in text
    assert '.cursor/' not in text and '~/.gemini/skills' not in text
    if os.name == 'posix':
        assert stat.S_IMODE(path.stat().st_mode) == 0o600
review = {row['id']: row['sources'] for row in scope['review']['clients']}
assert any(row['path'].endswith('/@lingmoon96-dev/nested/tool') for row in review['workbuddy'])
namespace_source = next(row for row in review['workbuddy'] if row['path'].endswith('/@lingmoon96-dev/nested/tool'))
assert namespace_source['layout'] == 'skill-package-root'
assert namespace_source['restore_target']['package_relative_path'] == '@lingmoon96-dev/nested/tool'
assert namespace_source['restore_target']['source_root'] == '~/.workbuddy/skills'
assert namespace_source['restore_target']['requires_path_mapping'] is True
assert namespace_source['scope'] == 'user' and namespace_source['workspace'] is None
assert next(row for row in review['codex'] if row['path'].startswith(str(workspace)))['workspace'] == 'fixture'
assert any(row['path'] == '~/.codex/skills/legacy' for row in review['codex'])
assert any(row['path'] == '~/.trae-cn/skills/solo-context' for row in review['trae'])
profiles = {row['id']: row['native_profiles'] for row in scope['clients']}
assert [row['selector'] for row in profiles['codex']] == ['codex/cli']
assert profiles['antigravity'] == [] and profiles['tuanjie'] == [] and profiles['workbuddy'] == []
wb_report = next(row for row in report['clients'] if row['id'] == 'workbuddy')
packages = [package for row in wb_report['sources'] for package in row.get('packages', [])]
assert next(row for row in packages if row['path'].endswith('/invalid'))['metadata_status'] == 'invalid-metadata'
if links_available:
    linked_source = next(row for row in review['workbuddy'] if row['path'].endswith('/skills/linked'))
    assert linked_source['linked_roots'] == [str(external / 'linked')]
    namespace = next(row for row in review['workbuddy'] if row['path'].endswith('/nested/tool'))
    assert namespace['linked_roots'] == [str(external / 'reference.md')]
    evidence = next(row for row in packages if row['path'].endswith('/nested/tool'))['linked_roots_review']
    assert evidence[0]['reason'] == 'package-referenced-link'
    assert str(external) not in namespace['linked_roots']
sqlite_sources = [row for row in review['trae'] if row['kind'] == 'mcp-sqlite']
assert len(sqlite_sources) == 1 and sqlite_sources[0]['sqlite_key'] == 'custom.mcp.config'
assert sqlite_sources[0]['container'] == 'mcpServers'
trae_report = next(row for row in report['clients'] if row['id'] == 'trae')
db_report = next(row for row in trae_report['sources'] if row['path'].endswith('Trae CN/User/globalStorage/state.vscdb'))
keys = {row['key']: row['status'] for row in db_report['keys']}
assert keys['autoRunConfirm_IDE_mcp_alwaysRun'] == 'excluded-sensitive-or-execution-state-key'
assert keys['chat.session.mcp.config'] == 'excluded-sensitive-or-execution-state-key'
assert keys['currentAgentData_fixture'] == 'sqlite-mcp-binding-references-only'
assert next(row for row in trae_report['sources'] if row['path'].endswith('TRAE SOLO CN/User/globalStorage/state.vscdb'))['status'] == 'sqlite-unsupported-schema'
yaml_source = next(row for row in review['tuanjie'] if row['path'].endswith('/config.yaml'))
assert yaml_source['format'] == 'yaml' and ['roles'] in yaml_source['records'][0]['fields']
assert ['schema'] in yaml_source['fields']
plugin_rows = scope['selected_plugin_inventory']
expected_plugins = {'claude-code', 'antigravity', 'workbuddy'} | ({'codex'} if has_tomllib else set())
assert {row['client'] for row in plugin_rows} == expected_plugins
assert len(plugin_rows) == len(expected_plugins) and all(row['status'] == 'inventory-only-not-activated' for row in plugin_rows)
assert next(row for row in plugin_rows if row['client'] == 'workbuddy')['enabled'] is False
assert next(row for row in plugin_rows if row['client'] == 'antigravity')['installed_from'] == {
    'id': 'fixture-gravity', 'marketplace': 'fixture-market', 'version': '1.2.3'}
assert all(set(row) <= {'client', 'id', 'source', 'status', 'enabled', 'installed_from'} for row in plugin_rows)
extensions = scope['selected_extension_inventory']
assert len(extensions) == 3 and {row['client'] for row in extensions} == {'trae', 'antigravity'}
assert all(set(row) == {'client', 'source_root', 'publisher', 'name', 'version'} for row in extensions)
assert all('runtime.node' not in json.dumps(row) for row in extensions)
gravity_report = next(row for row in report['clients'] if row['id'] == 'antigravity')
assert any(row['tasks'] for row in gravity_report['inventories'])
automations = [row for row in review['codex'] if row['kind'] == 'text' and row['path'].endswith('/automation.toml')]
assert len(automations) == 4 and all(row['activation'] == 'pending-agent-review' for row in automations)
assert all(row['kind'] == 'text' and row['scope'] == 'user' and row['workspace'] is None for row in automations)
assert all(row['path'].endswith('/automation.toml') and '/state/' not in row['path'] for row in automations)
claude_report = next(row for row in report['clients'] if row['id'] == 'claude-code')
assert any(row['kind'] == 'hooks' and row['status'] == 'hook-fields-declared-for-inert-capture' for row in claude_report['sources'])
assert any(row['kind'] == 'hooks' and row['fields'] == ['hooks'] for row in review['claude-code'])
dry_export = subprocess.run([sys.executable, '-B', str(scripts / 'device-export.py'),
                             '--spec', str(output / 'scope.json'), '--output', str(root / 'unwritten-packet'), '--dry-run'],
                            env=environment, cwd=root, text=True, capture_output=True)
assert dry_export.returncode == 0, dry_export.stderr
assert json.loads(dry_export.stdout)['dry_run'] is True
assert not (root / 'unwritten-packet').exists()
assert private_value not in dry_export.stdout + dry_export.stderr
print('OK exact six-client scope, bounded namespace packages, safe metadata and exact linked-root evidence')
print('OK SQLite read-only schema and exact MCP keys; chat, permission and agent binding state excluded')
print('OK YAML model preference draft, metadata diagnostics, exporter dry-run compatibility and unchanged sources')
print('OK plugin/extension identity allowlists, unreadable/symlink diagnostics, authored automations and excluded runtime salt/state')

single = root / 'codex-only'
run(single, ['codex'])
one = json.loads((single / 'scope.json').read_text())
assert [row['id'] for row in one['clients']] == ['codex']
assert all(row['scopes'] == ['user'] for row in one['clients'][0]['native_profiles'])
assert json.loads((single / 'discovery.json').read_text())['selected_scopes'] == ['user']
assert all(not row['path'].startswith(str(workspace)) for row in one['review']['clients'][0]['sources'])
assert 'TRAE' not in (single / 'discovery.json').read_text()
assert {row['client'] for row in one['selected_plugin_inventory']} == ({'codex'} if has_tomllib else set())
if not has_tomllib:
    codex_report = json.loads((single / 'discovery.json').read_text())['clients'][0]
    assert any(row['status'] == 'inventory-missing-parser' for row in codex_report['inventories'])
assert one['selected_extension_inventory'] == []
project_only = root / 'project-only'
run(project_only, ['codex'], '--scopes', 'project')
project_scope = json.loads((project_only / 'scope.json').read_text())
assert project_scope['selected_plugin_inventory'] == [] and project_scope['selected_extension_inventory'] == []
assert not any(row.get('classification') == 'activation-bearing' for row in project_scope['review']['clients'][0]['sources'])
run(root / 'bad-client', ['vscode'], success=False)
run(root / 'duplicate-client', ['codex', 'codex'], success=False)
run(output, success=False)
run(workspace / 'overlap', success=False)
assert not (workspace / 'overlap').exists()
write(database.with_name(database.name + '-wal'), 'synthetic wal marker')
wal_output = root / 'wal-discovery'
run(wal_output, ['trae'])
wal_scope = json.loads((wal_output / 'scope.json').read_text())
assert not any(row['kind'] == 'mcp-sqlite' for row in wal_scope['review']['clients'][0]['sources'])
wal_report = json.loads((wal_output / 'discovery.json').read_text())
assert any(row['status'] == 'sqlite-live-wal-requires-closed-client' for row in wal_report['clients'][0]['sources'])
print('OK explicit subset/scopes, no installation expansion, overlap/fresh-output guards and live-WAL boundary')
PY
