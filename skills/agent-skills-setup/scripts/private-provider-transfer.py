#!/usr/bin/env python3
"""Explicitly selected provider credentials: encrypted export, merge, verify.

No discovery, code execution, OAuth login or native activation. Requires Node.js.
"""
from __future__ import annotations

import argparse
import base64
import datetime
import copy
import json
import math
import os
from pathlib import Path
import re
import sqlite3
import stat
import subprocess
import sys
import tempfile
from typing import Any
import uuid

MAX_FILE = 32 * 1024 * 1024
MAX_TOTAL = 64 * 1024 * 1024


class TransferError(Exception):
    pass


def fail(reason: str) -> None:
    raise TransferError(reason)


def pairs(items: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in items:
        if key in result:
            fail('duplicate-json-key')
        result[key] = value
    return result


def load_json(data: bytes) -> Any:
    try:
        return json.loads(data, object_pairs_hook=pairs,
                          parse_constant=lambda _: fail('nonfinite-json-number'))
    except TransferError:
        raise
    except Exception:
        fail('invalid-json')


def encode(value: Any) -> bytes:
    try:
        return json.dumps(value, ensure_ascii=False, allow_nan=False, separators=(',', ':')).encode()
    except Exception:
        fail('unrepresentable-data')


def ordinary(path: Path, *, private: bool = False) -> None:
    # Check every component, including existing ancestors of new targets.
    path = Path(os.path.abspath(path))
    for component in [*reversed(path.parents), path]:
        if component.is_symlink():
            fail('symlink-path')
        if not component.exists():
            continue
        info = component.lstat()
        if component == path:
            if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
                fail('not-single-regular-file')
            if info.st_uid != os.getuid() or info.st_mode & 0o022:
                fail('unsafe-file-owner-or-permissions')
            if private and info.st_mode & 0o077:
                fail('password-file-must-be-private')


def read(path: Path, *, private: bool = False) -> bytes:
    ordinary(path, private=private)
    if not path.is_file() or path.stat().st_size > MAX_FILE:
        fail('missing-or-oversized-file')
    return path.read_bytes()


def crypto(mode: str, data: bytes, password: Path) -> bytes:
    passphrase = read(password, private=True)
    if passphrase.endswith(b'\r\n'):
        passphrase = passphrase[:-2]
    elif passphrase.endswith(b'\n'):
        passphrase = passphrase[:-1]
    if not 16 <= len(passphrase) <= 4096:
        fail('password-file-length')
    helper = Path(__file__).with_name('private-provider-crypto.js')
    try:
        result = subprocess.run(['node', str(helper), mode, str(password)], input=data,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
    except Exception:
        fail('crypto-runtime-unavailable')
    if result.returncode or len(result.stdout) > MAX_TOTAL * 2:
        fail('encryption-or-authentication-failed')
    return result.stdout


def strings(value: Any) -> bool:
    return (isinstance(value, list) and 0 < len(value) <= 256
            and all(isinstance(x, str) and 0 < len(x) <= 2048 and '\x00' not in x for x in value)
            and len(set(value)) == len(value))


def field_paths(fields: Any) -> list[list[str]]:
    if not isinstance(fields, list) or not 0 < len(fields) <= 256:
        fail('invalid-fields')
    paths = []
    for item in fields:
        path = [item] if isinstance(item, str) else item
        if (not isinstance(path, list) or not 0 < len(path) <= 16
                or not all(isinstance(part, str) and 0 < len(part) <= 2048 and '\x00' not in part for part in path)):
            fail('invalid-field-path')
        paths.append(path)
    for index, path in enumerate(paths):
        if any(path[:len(other)] == other or other[:len(path)] == path
               for other in paths[index + 1:]):
            fail('duplicate-or-overlapping-field-path')
    return paths


def selection_keys(entry: dict[str, Any]) -> list[str]:
    if entry['kind'] == 'sqlite-items':
        return entry['keys']
    return [json.dumps(path, ensure_ascii=False, separators=(',', ':')) for path in field_paths(entry['fields'])]


def lookup(document: Any, parts: list[str]) -> tuple[bool, Any]:
    for part in parts:
        if not isinstance(document, dict) or part not in document:
            return False, None
        document = document[part]
    return True, document


def put(document: dict[str, Any], parts: list[str], value: Any) -> None:
    for part in parts[:-1]:
        if part not in document:
            document[part] = {}
        if not isinstance(document[part], dict):
            fail('target-field-parent-is-not-object')
        document = document[part]
    document[parts[-1]] = value


def target(home: Path, relative: Any) -> Path:
    if (not isinstance(relative, str) or not relative or len(relative) > 4096
            or '\\' in relative or '\x00' in relative or relative.startswith('/')
            or any(p in ('', '.', '..') for p in relative.split('/'))):
        fail('invalid-relative-target')
    out = home / relative
    ordinary(out)
    return out


def validate(entries: Any, *, exported: bool = False) -> list[dict[str, Any]]:
    if not isinstance(entries, list) or not 0 < len(entries) <= 128:
        fail('invalid-entry-count')
    ids, destinations = set(), set()
    for entry in entries:
        if not isinstance(entry, dict):
            fail('invalid-entry')
        ident = entry.get('id')
        if not isinstance(ident, str) or not re.fullmatch(r'[a-zA-Z0-9_.-]{1,128}', ident) or ident in ids:
            fail('invalid-or-duplicate-entry-id')
        ids.add(ident)
        if not isinstance(entry.get('client'), str) or not re.fullmatch(r'[a-zA-Z0-9_.-]{1,80}', entry['client']):
            fail('invalid-client-id')
        relative = entry.get('relative_target')
        target(Path('/'), relative)
        if relative in destinations:
            fail('duplicate-target')
        destinations.add(relative)
        kind = entry.get('kind')
        if kind not in ('json-fields', 'sqlite-items', 'json-file'):
            fail('unsupported-kind')
        selector = 'fields' if kind == 'json-fields' else 'keys'
        if kind == 'json-fields':
            field_paths(entry.get('fields'))
        elif kind == 'sqlite-items' and not strings(entry.get('keys')):
            fail('invalid-or-duplicate-selection')
        allowed = {'id', 'client', 'kind', 'relative_target'}
        if kind != 'json-file':
            allowed.add(selector)
        if 'home_paths' in entry:
            if kind != 'json-fields':
                fail('home-paths-require-json-fields')
            selected_paths = field_paths(entry['fields'])
            for path in field_paths(entry['home_paths']):
                if not any(path[:len(prefix)] == prefix for prefix in selected_paths):
                    fail('home-path-outside-selection')
            allowed.add('home_paths')
        allowed.add('data' if exported else 'path')
        if set(entry) != allowed:
            fail('unexpected-entry-fields')
        if exported:
            data = entry['data']
            if kind in ('json-fields', 'sqlite-items'):
                if not isinstance(data, dict) or set(data) != set(selection_keys(entry)):
                    fail('selection-data-mismatch')
                if kind == 'sqlite-items':
                    for value in data.values():
                        unpack(value)
            elif not isinstance(data, (dict, list)):
                fail('json-file-root-must-be-object-or-array')
        elif not isinstance(entry['path'], str) or not Path(entry['path']).is_absolute():
            fail('source-must-be-absolute')
    return entries


def pack(value: Any) -> dict[str, Any]:
    if value is None:
        return {'type': 'null', 'value': None}
    if isinstance(value, bytes):
        return {'type': 'blob', 'value': base64.b64encode(value).decode()}
    if isinstance(value, str):
        return {'type': 'text', 'value': value}
    if type(value) is int:
        return {'type': 'integer', 'value': value}
    if type(value) is float and math.isfinite(value):
        return {'type': 'real', 'value': value}
    fail('unsupported-sqlite-type')


def unpack(item: Any) -> Any:
    if not isinstance(item, dict) or set(item) != {'type', 'value'}:
        fail('invalid-sqlite-value')
    kind, value = item['type'], item['value']
    if kind == 'null' and value is None:
        return None
    if kind == 'text' and isinstance(value, str):
        return value
    if kind == 'integer' and type(value) is int and -(2**63) <= value < 2**63:
        return value
    if kind == 'real' and type(value) in (int, float) and math.isfinite(value):
        return float(value)
    if kind == 'blob' and isinstance(value, str):
        try:
            return base64.b64decode(value, validate=True)
        except Exception:
            pass
    fail('invalid-sqlite-value')


def connect(path: Path, *, writable: bool = False) -> sqlite3.Connection:
    ordinary(path)
    for suffix in ('-wal', '-shm', '-journal'):
        sidecar = Path(str(path) + suffix)
        if sidecar.exists() or sidecar.is_symlink():
            ordinary(sidecar)
    try:
        uri = path.as_uri() + ('?mode=rw' if writable else '?mode=ro')
        conn = sqlite3.connect(uri, uri=True, timeout=1)
        columns = conn.execute('PRAGMA table_info(ItemTable)').fetchall()
        if {row[1] for row in columns} != {'key', 'value'}:
            conn.close()
            fail('unsupported-sqlite-schema')
        schema = conn.execute("SELECT type,sql FROM sqlite_master WHERE name='ItemTable'").fetchone()
        if (not schema or schema[0] != 'table' or not schema[1].upper().startswith('CREATE TABLE')
                or conn.execute("SELECT 1 FROM sqlite_master WHERE type='trigger' AND tbl_name='ItemTable'").fetchone()):
            conn.close()
            fail('unsupported-sqlite-schema')
        return conn
    except TransferError:
        raise
    except Exception:
        fail('sqlite-unavailable-or-busy')


def sqlite_rows(path: Path, keys: list[str]) -> dict[str, Any]:
    if not path.exists():
        return {}
    conn = connect(path)
    try:
        conn.execute('BEGIN')
        rows: dict[str, Any] = {}
        for key in keys:
            values = conn.execute('SELECT value FROM ItemTable WHERE key=? COLLATE BINARY', (key,)).fetchall()
            if len(values) > 1:
                fail('duplicate-sqlite-key')
            if values:
                rows[key] = pack(values[0][0])
        return rows
    finally:
        conn.close()


def selected(entry: dict[str, Any], path: Path, *, required: bool = False) -> Any:
    if entry['kind'] == 'sqlite-items':
        data = sqlite_rows(path, entry['keys'])
        if required and set(data) != set(entry['keys']):
            fail('selected-sqlite-key-absent')
        return data
    document = load_json(read(path)) if path.exists() else {}
    if entry['kind'] == 'json-file':
        if not isinstance(document, (dict, list)):
            fail('json-root-must-be-object-or-array')
        return document
    if not isinstance(document, dict):
        fail('json-root-must-be-object')
    result = {}
    for key, parts in zip(selection_keys(entry), field_paths(entry['fields'])):
        present, value = lookup(document, parts)
        if present:
            result[key] = value
        elif required:
            fail('selected-json-field-absent')
    return result


def atomic(path: Path, data: bytes, *, exclusive: bool = False) -> None:
    ordinary(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    ordinary(path)
    if exclusive:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, 'wb') as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        return
    fd, name = tempfile.mkstemp(prefix='.private-provider-', dir=str(path.parent))
    try:
        with os.fdopen(fd, 'wb') as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def write_selection(entry: dict[str, Any], path: Path, data: Any) -> None:
    if entry['kind'] == 'sqlite-items':
        path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        if not path.exists():
            fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
            os.close(fd)
            conn = sqlite3.connect(str(path), timeout=1)
            try:
                conn.execute('CREATE TABLE ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB)')
                conn.commit()
            finally:
                conn.close()
        conn = connect(path, writable=True)
        try:
            conn.execute('BEGIN IMMEDIATE')
            for key in entry['keys']:
                conn.execute('DELETE FROM ItemTable WHERE key=? COLLATE BINARY', (key,))
                if key in data:
                    conn.execute('INSERT INTO ItemTable (key,value) VALUES (?,?)', (key, unpack(data[key])))
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()
        return
    if entry['kind'] == 'json-fields':
        document = load_json(read(path)) if path.exists() else {}
        for key, parts in zip(selection_keys(entry), field_paths(entry['fields'])):
            put(document, parts, data[key])
    else:
        document = data
    atomic(path, encode(document))


def source_home(value: Any) -> str:
    if (not isinstance(value, str) or not value.startswith('/') or value == '/'
            or value.endswith('/') or '\x00' in value or '\\' in value
            or os.path.normpath(value) != value):
        fail('invalid-source-home')
    return value


def map_home(entries: list[dict[str, Any]], old_home: str, new_home: str) -> list[dict[str, Any]]:
    mapped = copy.deepcopy(entries)
    for entry in mapped:
        if not entry.get('home_paths'):
            continue
        paths = field_paths(entry['fields'])
        for home_path in field_paths(entry['home_paths']):
            prefix = next(parts for parts in paths if home_path[:len(parts)] == parts)
            key = json.dumps(prefix, ensure_ascii=False, separators=(',', ':'))
            remaining = home_path[len(prefix):]
            present, value = lookup(entry['data'][key], remaining)
            if (not present or not isinstance(value, str) or not value.startswith(old_home + '/')
                    or '\\' in value or '\x00' in value
                    or any(part in ('', '.', '..') for part in value.split('/')[1:])):
                fail('home-path-value-is-not-source-home-path')
            changed = new_home + value[len(old_home):]
            if remaining:
                put(entry['data'][key], remaining, changed)
            else:
                entry['data'][key] = changed
    return mapped


def export(spec: Path, output: Path, password: Path) -> dict[str, Any]:
    document = load_json(read(spec))
    if not isinstance(document, dict) or not {'entries'} <= set(document) <= {'entries', 'source_home'}:
        fail('invalid-spec')
    entries = validate(document['entries'])
    old_home = source_home(document.get('source_home', str(Path.home())))
    exported = []
    for entry in entries:
        item = {key: value for key, value in entry.items() if key != 'path'}
        source = Path(entry['path'])
        read(source)  # Size, ownership, regular-file and permission checks.
        item['data'] = selected(entry, source, required=True)
        exported.append(item)
    map_home(exported, old_home, old_home)  # Validate exact home-path leaves before encryption.
    plaintext = encode({'format': 'private-provider-transfer-v1', 'source_home': old_home, 'entries': exported})
    if len(plaintext) > MAX_TOTAL:
        fail('oversized-selection')
    atomic(output, crypto('encrypt', plaintext, password), exclusive=True)
    return summary(exported, 'exported')


def summary(entries: list[dict[str, Any]], status: str) -> dict[str, Any]:
    return {'status': status, 'entries': [{'id': e['id'], 'client': e['client'],
            'kind': e['kind'], 'field_names': e.get('fields', []),
            'key_count': len(e.get('keys', []))} for e in entries]}


def restore(artifact: Path, home: Path, password: Path, *, replace: bool, verify: bool) -> dict[str, Any]:
    # Ciphertext expands with base64; permit twice the plaintext size.
    ordinary(artifact)
    if not artifact.is_file() or artifact.stat().st_size > MAX_TOTAL * 2:
        fail('missing-or-oversized-artifact')
    encrypted = artifact.read_bytes()
    load_json(encrypted)  # Reject duplicate envelope fields before authentication.
    document = load_json(crypto('decrypt', encrypted, password))
    if not isinstance(document, dict) or set(document) != {'format', 'source_home', 'entries'} or document['format'] != 'private-provider-transfer-v1':
        fail('invalid-artifact-format')
    entries = validate(document['entries'], exported=True)
    home = Path(os.path.abspath(home))
    if home.is_symlink() or not home.is_dir():
        fail('home-must-be-existing-directory')
    entries = map_home(entries, source_home(document['source_home']), str(home))
    states = []
    for entry in entries:
        path = target(home, entry['relative_target'])
        before = selected(entry, path)
        same = encode(before) == encode(entry['data'])
        if verify and not same:
            fail('readback-mismatch:' + entry['id'])
        if not verify and not replace and not same and (before or (path.exists() and entry['kind'] == 'json-file')):
            fail('replace-required:' + entry['id'])
        state = {'entry': entry, 'existed': path.exists(), 'before': before}
        if path.exists() and entry['kind'] != 'sqlite-items':
            state['raw'] = base64.b64encode(read(path)).decode()
            state['mode'] = stat.S_IMODE(path.stat().st_mode)
        states.append(state)
    if verify:
        return summary(entries, 'verified')
    backup = home / '.ai-ide-migration' / 'private-provider-backups' / (datetime.datetime.now().strftime('%Y%m%dT%H%M%S') + '-' + uuid.uuid4().hex + '.encrypted')
    target(home, backup.relative_to(home).as_posix())
    atomic(backup, crypto('encrypt', encode({'format': 'private-provider-backup-v1', 'states': states}), password), exclusive=True)
    applied = []
    try:
        for state in states:
            entry = state['entry']
            path = target(home, entry['relative_target'])
            try:
                write_selection(entry, path, entry['data'])
            except Exception:
                # Existing SQLite writes are transactional; failed atomic JSON
                # writes have not replaced the destination. Remove only new files.
                if not state['existed'] and path.exists():
                    applied.append(state)
                raise
            applied.append(state)
            if encode(selected(entry, path, required=True)) != encode(entry['data']):
                fail('readback-mismatch:' + entry['id'])
    except Exception:
        rollback_ok = True
        for state in reversed(applied):
            entry = state['entry']
            try:
                path = target(home, entry['relative_target'])
                if not state['existed']:
                    if path.exists():
                        path.unlink()
                elif entry['kind'] == 'sqlite-items':
                    write_selection(entry, path, state['before'])
                else:
                    atomic(path, base64.b64decode(state['raw']))
                    os.chmod(path, state['mode'])
            except Exception:
                rollback_ok = False
        fail('import-failed-rolled-back' if rollback_ok else 'import-failed-rollback-incomplete-encrypted-backup-retained')
    result = summary(entries, 'imported-and-verified')
    result['encrypted_backup'] = str(backup.relative_to(home))
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    exp = commands.add_parser('export')
    exp.add_argument('--spec', type=Path, required=True)
    exp.add_argument('--output', type=Path, required=True)
    for name in ('import', 'verify'):
        cmd = commands.add_parser(name)
        cmd.add_argument('artifact', type=Path)
        cmd.add_argument('--home', type=Path, required=True)
        if name == 'import':
            cmd.add_argument('--replace', action='store_true')
    for cmd in commands.choices.values():
        cmd.add_argument('--password-file', type=Path, required=True)
    args = parser.parse_args()
    try:
        if os.name != 'posix':
            fail('requires-posix-host')
        if args.command == 'export':
            result = export(args.spec, args.output, args.password_file)
        else:
            result = restore(args.artifact, args.home, args.password_file,
                             replace=getattr(args, 'replace', False), verify=args.command == 'verify')
        print(json.dumps(result, ensure_ascii=False))
        return 0
    except TransferError as error:
        print(json.dumps({'status': 'failed', 'reason': str(error)}))
    except Exception:
        # sqlite/OS/JSON exceptions can contain private values; never echo them.
        print(json.dumps({'status': 'failed', 'reason': 'operation-failed'}))
    return 2


if __name__ == '__main__':
    sys.exit(main())
