#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_REVIEW_ROOT="$(mktemp -d)"
trap 'rm -rf "$MCP_REVIEW_ROOT"' EXIT
if command -v cygpath >/dev/null 2>&1; then
    MCP_REVIEW_ROOT="$(cygpath -w "$MCP_REVIEW_ROOT")"
    SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi
export MCP_REVIEW_ROOT
export HOME="$MCP_REVIEW_ROOT"
export PYTHONPATH="$SCRIPT_DIR${PYTHONPATH:+:$PYTHONPATH}"
export PYTHONDONTWRITEBYTECODE=1

"${MCP_REVIEW_PYTHON:-python3}" - <<'PY'
import hashlib
import importlib
import json
import os
from pathlib import Path
from unittest.mock import patch

from acb import bundle
from acb.mcp_review import collect_mcp_review

root = Path(os.environ['MCP_REVIEW_ROOT']).resolve()


def row(path, source_format='json:mcpServers', **overrides):
    result = {
        'product': 'codex', 'profile': 'cli', 'scope': 'user', 'object_type': 'mcp',
        'source_format': source_format, 'policy': 'profile-version-adapter',
        'storage': 'config-subobject', 'canonical_path': '~/.fixture/config.json',
        'resolved_path': str(path), 'boundary': str(root),
    }
    result.update(overrides)
    return result


def capture(rows):
    return collect_mcp_review(rows, selected_profiles={'codex/cli'}, scopes={'user'})


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


source = root / 'config.json'
raw = {
    'model': 'private-provider-selection',
    'trust': {'approved': True, 'password': 'sibling-password-must-not-copy'},
    'api_key': 'sibling-credential-must-not-copy',
    'mcpServers': {
        'local': {
            'command': 'python3', 'args': ['/old/device/server.py', '--token', 'argument-value-must-not-copy'],
            'cwd': '/old/device/workspace', 'env': {'API_KEY': 'env-value-must-not-copy', 'LANG': 'en_US.UTF-8',
                'authToken': 'camel-env-value-must-not-copy', 'CUSTOM': 'opaque-env-value-must-not-copy',
                'EXPLICIT': '${env:KNOWN_ENV_REFERENCE}'},
            'env_vars': ['FORWARDED_ENV'], 'enabled': True, 'startup_timeout_sec': 45,
            'enabled_tools': ['search'], 'disabled_tools': ['delete'],
            'custom_provider': {'password': 'unknown-field-value-must-not-copy'},
        },
        'remote': {
            'httpUrl': 'https://sourceuser:sourcepass@example.invalid/mcp?token=url-value-must-not-copy&region=west&auth=auth-query-must-not-copy&accessToken=camel-query-must-not-copy&opaque=opaque-query-must-not-copy',
            'transport': 'streamable-http',
            'http_headers': {'Authorization': 'Bearer header-value-must-not-copy', 'X-Region': 'west',
                'X-Auth': 'header-auth-must-not-copy', 'Opaque': 'opaque-header-must-not-copy',
                'X-Explicit': 'Bearer ${env:EXPLICIT_HEADER}'},
            'env_http_headers': {'X-Private': 'PRIVATE_HEADER_ENV'},
            'bearer_token_env_var': 'REMOTE_BEARER_TOKEN', 'tool_timeout_sec': 60,
            'unknown': 'unknown-string-value-must-not-copy',
        },
        'bad-shape': {'command': ['bad']},
        'bad-residual': {'command': 'password=unhandled-literal-must-not-copy'},
    },
}
source.write_text(json.dumps(raw))
before = digest(source)
source_before = before
objects, manifests, mapping, tasks = capture([row(source)])
assert digest(source) == before
assert len(objects) == 2, (objects, tasks)
assert len(manifests) == 1 and manifests[0]['surface'] == 'review'
assert manifests[0]['status'] == 'manual-rebuild' and 'source' not in manifests[0]
assert set(mapping['review/codex/cli/user']) == set(objects)
enriched = bundle.enrich_manifest_object(manifests[0], objects, object_file_map=mapping)
assert len(enriched['files']) == 2
payloads = {payload['server_name']: payload for payload in map(json.loads, objects.values())}
local, remote = payloads['local'], payloads['remote']
assert local['definition']['command'] == 'python3'
assert local['definition']['args'] == ['/old/device/server.py', '--token', '${TOKEN}']
assert local['definition']['cwd'] == '/old/device/workspace'
assert local['definition']['env']['API_KEY'] == '${API_KEY}'
assert local['definition']['env']['LANG'] == '${LANG}'
assert local['definition']['env']['authToken'] == '${AUTH_TOKEN}'
assert local['definition']['env']['CUSTOM'] == '${CUSTOM}'
assert local['definition']['env']['EXPLICIT'] == '${KNOWN_ENV_REFERENCE}'
assert local['definition']['enabled_tools'] == ['search']
assert local['definition']['startup_timeout_sec'] == 45
assert local['paths_need_remapping'] is True
assert local['omitted_fields'] == ['custom_provider']
assert {'API_KEY', 'TOKEN', 'FORWARDED_ENV'} <= set(local['required_credentials'])
assert 'sourceuser' not in remote['definition']['httpUrl']
assert 'sourcepass' not in remote['definition']['httpUrl']
assert remote['definition']['httpUrl'] == 'https://example.invalid/mcp'
assert remote['definition']['http_headers']['Authorization'] == '${AUTHORIZATION}'
assert remote['definition']['http_headers']['X-Region'] == '${X_REGION}'
assert remote['definition']['http_headers']['X-Auth'] == '${X_AUTH}'
assert remote['definition']['http_headers']['Opaque'] == '${OPAQUE}'
assert remote['definition']['http_headers']['X-Explicit'] == 'Bearer ${EXPLICIT_HEADER}'
assert remote['definition']['env_http_headers'] == {'X-Private': 'PRIVATE_HEADER_ENV'}
assert remote['definition']['bearer_token_env_var'] == 'REMOTE_BEARER_TOKEN'
assert {'MCP_USER', 'MCP_PASSWORD', 'TOKEN', 'AUTHORIZATION', 'REMOTE_BEARER_TOKEN', 'PRIVATE_HEADER_ENV'} <= set(remote['required_credentials'])
assert remote['omitted_fields'] == ['httpUrl.query.accessToken', 'httpUrl.query.auth', 'httpUrl.query.opaque', 'httpUrl.query.region', 'httpUrl.query.token', 'unknown']
text = json.dumps([manifests, mapping, tasks]) + ''.join(data.decode() for data in objects.values())
for excluded in ('private-provider-selection', 'sibling-password-must-not-copy', 'sibling-credential-must-not-copy',
                 'argument-value-must-not-copy', 'env-value-must-not-copy', 'url-value-must-not-copy',
                 'header-value-must-not-copy', 'unknown-field-value-must-not-copy',
                 'unknown-string-value-must-not-copy', 'unhandled-literal-must-not-copy',
                 'camel-env-value-must-not-copy', 'opaque-env-value-must-not-copy',
                 'auth-query-must-not-copy', 'camel-query-must-not-copy', 'opaque-query-must-not-copy',
                 'header-auth-must-not-copy', 'opaque-header-must-not-copy', 'en_US.UTF-8', str(root)):
    assert excluded not in text, excluded
assert {'invalid-server-definition', 'server-secret-not-captured', 'mcp-review-definition-captured'} <= {task['reason'] for task in tasks}
assert all(task['automatic_restore'] is False and task['next_action'] for task in tasks)
print('OK precise MCP extraction, stdio and remote redaction, credential names, unknown fields and per-server isolation')

for family in ('json', 'jsonc'):
    for container in ('mcpServers', 'servers', 'mcp'):
        data = json.dumps({container: {'fixture': {'command': 'fixture-local-tool'}}, 'sibling': {'password': 'no-copy'}})
        path = root / (family + '-' + container + '.json')
        path.write_text('// a JSONC comment\n' + data if family == 'jsonc' else data)
        objects, _, _, tasks = capture([row(path, family + ':' + container)])
        assert len(objects) == 1 and next(iter(map(json.loads, objects.values())))['definition']['command'] == 'fixture-local-tool'
print('OK all explicitly supported JSON/JSONC container names')

toml_source = root / 'config.toml'
toml_source.write_text('''model = "private-model-must-not-copy"
api_key = "toml-sibling-secret-must-not-copy"
[projects."/old/project"]
trust_level = "trusted"
[mcp_servers.local]
command = "python3"
args = ["/old/device/server.py", "--token=toml-argument-must-not-copy"]
enabled = true
startup_timeout_sec = 30
enabled_tools = ["search"]
[mcp_servers.local.env]
API_KEY = "toml-env-must-not-copy"
[mcp_servers.remote]
url = "https://example.invalid/mcp?api_key=toml-url-must-not-copy"
bearer_token_env_var = "REMOTE_TOKEN_ENV"
[mcp_servers.remote.http_headers]
Authorization = "Bearer toml-header-must-not-copy"
''')
try:
    importlib.import_module('tomllib')
except ModuleNotFoundError:
    print('OK Python <3.11 explicitly defers TOML; real TOML parse runs with MCP_REVIEW_PYTHON=python3.11+')
else:
    before = digest(toml_source)
    objects, _, _, tasks = capture([row(toml_source, 'toml:mcp_servers')])
    assert len(objects) == 2, tasks
    assert digest(toml_source) == before
    text = ''.join(data.decode() for data in objects.values()) + json.dumps(tasks)
    for excluded in ('private-model-must-not-copy', 'toml-sibling-secret-must-not-copy', 'trust_level',
                     'toml-argument-must-not-copy', 'toml-env-must-not-copy',
                     'toml-url-must-not-copy', 'toml-header-must-not-copy'):
        assert excluded not in text, excluded
    print('OK real Codex TOML preserves only MCP definitions and excludes provider/trust siblings')
with patch('acb.mcp_review.importlib.import_module', side_effect=ModuleNotFoundError('PRIVATE PARSER ERROR')):
    objects, manifests, mapping, tasks = capture([row(toml_source, 'toml:mcp_servers')])
assert not objects and not manifests and not mapping
assert tasks[0]['reason'] == 'missing-tomllib-parser'
assert 'PRIVATE PARSER ERROR' not in json.dumps(tasks)
print('OK missing stdlib TOML parser records actionable failure without exception contents')

excluded_rows = [row(source, profile='other'), row(source, scope='project'), row(source, object_type='hooks')]
assert capture(excluded_rows) == ({}, [], {}, [])
objects, _, _, tasks = capture([row(source, 'json')])
assert not objects and tasks[0]['reason'] == 'unhandled-format'
objects, _, _, tasks = capture([row(source, policy='never-migrate')])
assert not objects and tasks[0]['reason'] == 'excluded-by-policy-or-storage'
if hasattr(os, 'symlink'):
    alias = root / 'link.json'
    try:
        alias.symlink_to(source)
    except (OSError, NotImplementedError):
        pass
    else:
        objects, _, _, tasks = capture([row(alias)])
        assert not objects and any('symlink' in task['reason'] for task in tasks)
with patch.object(bundle, 'MAX_FILE_SIZE', source.stat().st_size - 1):
    objects, _, _, tasks = capture([row(source)])
assert not objects and tasks[0]['reason'] == 'file-size-limit'
with patch.object(bundle, 'MAX_BUNDLE_FILES', 1):
    objects, _, _, tasks = capture([row(source)])
assert len(objects) == 1 and any(task['reason'] == 'server-count-limit' for task in tasks)
with patch.object(bundle, 'MAX_DIR_DEPTH', 6):
    objects, _, _, tasks = capture([row(source)])
assert not objects and any(task['reason'] == 'directory-depth-limit' for task in tasks)
with patch.object(bundle, 'MAX_TOTAL_SIZE', 1):
    objects, _, _, tasks = capture([row(source)])
assert not objects and any(task['reason'] == 'payload-size-limit' for task in tasks)
assert digest(source) == source_before
print('OK selected scopes/profiles only, symlink refusal, unsupported formats, source and payload resource limits; sources never written')
PY
