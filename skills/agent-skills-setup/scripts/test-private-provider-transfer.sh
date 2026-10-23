#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 - "$SCRIPT_DIR" <<'PY'
import base64
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile

if os.name != 'posix':
    print('SKIP private provider transfer requires a POSIX host')
    sys.exit(0)

scripts = Path(sys.argv[1])
helper = scripts / 'private-provider-transfer.py'
with tempfile.TemporaryDirectory(prefix='private-provider-test-') as directory:
    root = Path(directory).resolve()
    src = root / 'source'
    dst = root / 'target'
    src.mkdir()
    dst.mkdir()
    password = root / 'password'
    password.write_text('fixture-password-with-中文-and-entropy')
    password.chmod(0o600)
    newline_password = root / 'password-crlf'
    newline_password.write_bytes(password.read_bytes() + b'\r\n')
    newline_password.chmod(0o600)
    badpassword = root / 'wrong-password'
    badpassword.write_text('other-fixture-password-with-entropy')
    badpassword.chmod(0o600)
    model = {'customModelProvider': 'fixture-provider', 'customModelProviders': [{'id': 'fixture-provider', 'apiKey': 'fixture-api-key', 'models': ['model-A']}], 'customModels': {'model-A': {'endpoint': 'https://fixture.invalid/v1', 'apiKey': 'fixture-model-key'}}, 'migratedToMultiProvider': True, 'mcpServers': {'fixture': {'command': 'old-command', 'env': {'API_KEY': 'fixture-env-key'}}}, 'unselected': 'private-do-not-export'}
    model['mcpServers']['ported'] = {'command': str(src / '.local/bin/uvx'), 'env': {'API_KEY': 'fixture-key-' + str(src)}, 'url': 'https://fixture.invalid/path' + str(src)}
    sourcejson = src / 'settings.json'
    sourcejson.write_text(json.dumps(model))
    auth = src / 'auth.json'
    auth.write_text(json.dumps([{'api_key': 'fixture-array-key'}]))
    database = src / 'state.vscdb'
    conn = sqlite3.connect(str(database))
    conn.execute('PRAGMA journal_mode=WAL')
    conn.execute('CREATE TABLE ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB)')
    fixture_rows = {'selected.text': '{"provider":"fixture","apiKey":"fixture-sql-key"}', 'selected.blob': b'\x00\xfffixture-bytes', 'selected.int': 42, 'selected.real': 1.25, 'selected.null': None}
    conn.executemany('INSERT INTO ItemTable VALUES (?,?)', fixture_rows.items())
    conn.execute('INSERT INTO ItemTable VALUES (?,?)', ('unselected', 'not-exported'))
    conn.commit()  # Keep WAL live while exporting.
    entries = [
        {'id': 'models', 'client': 'tuanjie', 'kind': 'json-fields', 'path': str(sourcejson), 'relative_target': '.codely/settings.json', 'fields': ['customModelProvider', 'customModelProviders', 'customModels', 'migratedToMultiProvider', ['mcpServers', 'fixture', 'env'], ['mcpServers', 'ported']], 'home_paths': [['mcpServers', 'ported', 'command']]},
        {'id': 'sql', 'client': 'trae', 'kind': 'sqlite-items', 'path': str(database), 'relative_target': 'Library/Application Support/fixture/state.vscdb', 'keys': list(fixture_rows)},
        {'id': 'auth', 'client': 'fixture', 'kind': 'json-file', 'path': str(auth), 'relative_target': '.fixture/auth.json'},
    ]
    spec = root / 'spec.json'
    spec.write_text(json.dumps({'entries': entries, 'source_home': str(src)}))
    artifact = root / 'providers.encrypted'
    def run(args, ok=True):
        result = subprocess.run([sys.executable, str(helper), *map(str, args), '--password-file', str(password)], capture_output=True, text=True)
        output = result.stdout + result.stderr
        assert 'fixture-api-key' not in output and 'fixture-env-key' not in output and 'fixture-sql-key' not in output
        assert (result.returncode == 0) == ok, (args, result.returncode, output)
        return json.loads(result.stdout)
    before = hashlib.sha256(sourcejson.read_bytes()).hexdigest()
    run(['export', '--spec', spec, '--output', artifact])
    # The same passphrase with one final LF/CRLF remains compatible; spaces stay meaningful.
    newline_dst = root / 'newline-target'
    newline_dst.mkdir()
    result = subprocess.run([sys.executable, str(helper), 'import', str(artifact), '--home', str(newline_dst), '--password-file', str(newline_password)], capture_output=True)
    assert result.returncode == 0, result.stdout
    for kind in ('lf', 'crlf'):
        newline_password.write_bytes(password.read_bytes() + (b'\n' if kind == 'lf' else b'\r\n'))
        line_artifact = root / ('line-' + kind + '.encrypted')
        result = subprocess.run([sys.executable, str(helper), 'export', '--spec', str(spec), '--output', str(line_artifact), '--password-file', str(newline_password)], capture_output=True)
        assert result.returncode == 0
        run(['verify', line_artifact, '--home', newline_dst])
    assert artifact.stat().st_mode & 0o077 == 0
    assert b'fixture-api-key' not in artifact.read_bytes() and b'private-do-not-export' not in artifact.read_bytes()
    run(['export', '--spec', spec, '--output', artifact], False)
    targetjson = dst / '.codely/settings.json'
    targetjson.parent.mkdir()
    targetjson.write_text(json.dumps({'other': 'retain-me', 'customModelProvider': 'existing', 'mcpServers': {'fixture': {'command': 'new-command', 'env': {'OLD': 'existing'}}}}))
    run(['import', artifact, '--home', dst], False)
    assert json.loads(targetjson.read_text())['customModelProvider'] == 'existing'
    result = run(['import', artifact, '--home', dst, '--replace'])
    assert result['status'] == 'imported-and-verified'
    final = json.loads(targetjson.read_text())
    assert final['other'] == 'retain-me'
    assert final['mcpServers']['fixture']['command'] == 'new-command'
    assert final['mcpServers']['fixture']['env'] == model['mcpServers']['fixture']['env']
    for name in ['customModelProvider', 'customModelProviders', 'customModels', 'migratedToMultiProvider']:
        assert final[name] == model[name]
    assert final['mcpServers']['ported']['command'] == str(dst / '.local/bin/uvx')
    assert final['mcpServers']['ported']['env'] == model['mcpServers']['ported']['env']
    assert final['mcpServers']['ported']['url'] == model['mcpServers']['ported']['url']
    assert 'unselected' not in final
    assert json.loads((dst / '.fixture/auth.json').read_text()) == json.loads(auth.read_text())
    destdb = dst / entries[1]['relative_target']
    check = sqlite3.connect(str(destdb))
    assert dict(check.execute('SELECT key,value FROM ItemTable')) == fixture_rows
    check.execute('INSERT INTO ItemTable VALUES (?,?)', ('unrelated-target', 'preserve-row'))
    check.commit()
    check.close()
    run(['verify', artifact, '--home', dst])
    run(['import', artifact, '--home', dst])
    check = sqlite3.connect(str(destdb))
    assert check.execute('SELECT value FROM ItemTable WHERE key=?', ('unrelated-target',)).fetchone()[0] == 'preserve-row'
    check.close()
    backup = dst / result['encrypted_backup']
    assert backup.stat().st_mode & 0o077 == 0 and b'new-command' not in backup.read_bytes()
    # Wrong password, authenticated tampering, duplicate targets/fields/JSON keys.
    result = subprocess.run([sys.executable, str(helper), 'verify', str(artifact), '--home', str(dst), '--password-file', str(badpassword)], capture_output=True)
    assert result.returncode != 0
    tampered = root / 'tampered'
    envelope = json.loads(artifact.read_text())
    data = bytearray(base64.b64decode(envelope['data']))
    data[0] ^= 1
    envelope['data'] = base64.b64encode(data).decode()
    tampered.write_text(json.dumps(envelope))
    run(['import', tampered, '--home', dst, '--replace'], False)
    def rejected(changed, name):
        test = root / ('spec-' + name)
        test.write_text(json.dumps({'entries': changed}))
        run(['export', '--spec', test, '--output', root / ('out-' + name)], False)
    rejected([entries[0], dict(entries[0], id='other')], 'duplicate-target')
    rejected([dict(entries[0], fields=['customModels', ['customModels', 'model-A']])], 'overlap')
    rejected([dict(entries[0], fields=['customModels', 'customModels'])], 'duplicate-field')
    rejected([dict(entries[0], home_paths=[['unselected']])], 'home-path-outside-selection')
    unsafe_command = src / 'unsafe-command.json'
    unsafe_model = json.loads(sourcejson.read_text())
    unsafe_model['mcpServers']['ported']['command'] = str(Path.home()) + '/../outside'
    unsafe_command.write_text(json.dumps(unsafe_model))
    rejected([dict(entries[0], path=str(unsafe_command))], 'home-path-traversal')
    rejected([dict(entries[0], relative_target='../escape')], 'escape')
    rejected([dict(entries[0], relative_target='/absolute')], 'absolute')
    duplicate = src / 'duplicate.json'
    duplicate.write_text('{"customModels": {}, "customModels": {}}')
    rejected([dict(entries[0], path=str(duplicate), fields=['customModels'])], 'duplicate-json')
    link = src / 'link.json'
    link.symlink_to(sourcejson)
    rejected([dict(entries[0], path=str(link))], 'source-link')
    hard = src / 'hard.json'
    os.link(sourcejson, hard)
    rejected([dict(entries[0], path=str(hard))], 'source-hard-link')
    hard.unlink()
    escaped = root / 'escape-home'
    escaped.mkdir()
    (escaped / '.codely').symlink_to(src, target_is_directory=True)
    run(['import', artifact, '--home', escaped, '--replace'], False)
    final['customModelProvider'] = 'modified'
    targetjson.write_text(json.dumps(final))
    run(['verify', artifact, '--home', dst], False)
    # A real SQLite writer lock after preflight must fail and undo prior JSON writes.
    original_target = targetjson.read_bytes()
    busy = sqlite3.connect(str(destdb))
    busy.execute('BEGIN IMMEDIATE')
    result = run(['import', artifact, '--home', dst, '--replace'], False)
    assert result['reason'] == 'import-failed-rolled-back'
    assert targetjson.read_bytes() == original_target
    busy.rollback()
    busy.close()
    # White-box fault after a successful SQLite write verifies cross-file rollback.
    module_spec = importlib.util.spec_from_file_location('private_transfer', helper)
    module = importlib.util.module_from_spec(module_spec)
    module_spec.loader.exec_module(module)
    native_write = module.write_selection
    calls = [0]
    def injected(entry, path, data):
        calls[0] += 1
        if calls[0] == 3:
            raise RuntimeError('private-must-not-log')
        return native_write(entry, path, data)
    module.write_selection = injected
    try:
        module.restore(artifact, dst, password, replace=True, verify=False)
        raise AssertionError('fault must propagate')
    except module.TransferError as error:
        assert str(error) == 'import-failed-rolled-back'
    assert targetjson.read_bytes() == original_target
    check = sqlite3.connect(str(destdb))
    assert dict(check.execute('SELECT key,value FROM ItemTable')) == dict(fixture_rows, **{'unrelated-target': 'preserve-row'})
    check.close()
    assert hashlib.sha256(sourcejson.read_bytes()).hexdigest() == before
    assert dict(conn.execute('SELECT key,value FROM ItemTable')) == dict(fixture_rows, unselected='not-exported')
    conn.close()
    newline_password.write_bytes(password.read_bytes() + b' ')
    result = subprocess.run([sys.executable, str(helper), 'verify', str(artifact), '--home', str(dst), '--password-file', str(newline_password)], capture_output=True)
    assert result.returncode != 0  # Do not strip meaningful spaces.
    password.chmod(0o644)
    run(['verify', artifact, '--home', dst], False)
    assert not list(root.rglob('.private-provider-*'))
print('PASS private provider encrypted export/import/verify, nested merges, typed SQLite WAL, conflicts, tamper, links, rollback and source preservation')
PY
