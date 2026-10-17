#!/usr/bin/env bash
# Codex provider reconstruction material is selective, inert and secret-free.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVIDER_REVIEW_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/provider-review.XXXXXX")"
trap 'rm -rf "$PROVIDER_REVIEW_ROOT"' EXIT

native_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$1"
    else
        printf '%s' "$1"
    fi
}

PYTHONDONTWRITEBYTECODE=1 "${PROVIDER_REVIEW_PYTHON:-python3}" - "$(native_path "$SCRIPT_DIR")" "$(native_path "$PROVIDER_REVIEW_ROOT")" <<'PY'
import copy
import hashlib
import importlib.util
import json
import os
import sys
from contextlib import nullcontext
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

scripts, root = map(Path, sys.argv[1:])
sys.path.insert(0, str(scripts))
from acb.provider_review import collect_provider_review
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
    for product, profile in [('codex', 'cli'), ('claude', 'code-cli')]
}
registry_path = root / 'registry.json'
registry_path.write_text(json.dumps(data))
registry = Registry(registry_path, workspace, home)
config = home / '.codex/config.toml'
config.parent.mkdir()
token = 'sk-' + 'a' * 48
bearer = 'Bearer ' + token
document = {
    'model_provider': 'gateway',
    'model_providers': {
        'gateway': {
            'name': 'Gateway', 'base_url': 'https://old-user:old-password@example.invalid/v1?api_key=query-credential&region=test&auth=opaque-auth-value&accessToken=camel-query-value&opaque=unknown-query-value',
            'wire_api': 'responses', 'env_key': 'EXAMPLE_API_KEY',
            'requires_openai_auth': False, 'request_max_retries': 3,
            'stream_max_retries': 5, 'stream_idle_timeout_ms': 300000,
            'http_headers': {'Authorization': bearer, 'X-Client': 'native', 'X-Auth': 'opaque-auth-header',
                             'authToken': 'opaque-camel-header', 'Opaque': 'unknown-header-value',
                             'X-Explicit': 'Bearer ${env:KNOWN_REFERENCE}'},
            'env_http_headers': {'X-Api-Key': 'EXAMPLE_API_KEY'},
            'api_key': token,
        },
        'bad': {'name': token, 'wire_api': 'responses'},
    },
    'profiles': {
        'focused': {'model': 'example-model', 'model_provider': 'gateway',
                    'model_reasoning_effort': 'high', 'personality': 'pragmatic',
                    'approval_policy': 'do-not-copy-policy-value',
                    'sandbox_mode': 'do-not-copy-sandbox-value'},
        'unsafe': {'model': token},
    },
    'permissions': {'credential': token}, 'projects': {'private': {'trust_level': 'trusted'}},
    'mcp_servers': {'not-captured': {'command': 'do-not-copy-command'}},
}
text = '\n'.join([
    'model_provider = "gateway"',
    '[model_providers.gateway]', 'name = "Gateway"',
    'base_url = "https://old-user:old-password@example.invalid/v1?api_key=query-credential&region=test&auth=opaque-auth-value&accessToken=camel-query-value&opaque=unknown-query-value"',
    'wire_api = "responses"', 'env_key = "EXAMPLE_API_KEY"',
    'requires_openai_auth = false', 'request_max_retries = 3',
    'stream_max_retries = 5', 'stream_idle_timeout_ms = 300000',
    'api_key = ' + json.dumps(token),
    '[model_providers.gateway.http_headers]', 'Authorization = ' + json.dumps(bearer),
    'X-Client = "native"', 'X-Auth = "opaque-auth-header"', 'authToken = "opaque-camel-header"',
    'Opaque = "unknown-header-value"', 'X-Explicit = "Bearer ${env:KNOWN_REFERENCE}"',
    '[model_providers.gateway.env_http_headers]',
    'X-Api-Key = "EXAMPLE_API_KEY"',
    '[model_providers.bad]', 'name = ' + json.dumps(token), 'wire_api = "responses"',
    '[profiles.focused]', 'model = "example-model"', 'model_provider = "gateway"',
    'model_reasoning_effort = "high"', 'personality = "pragmatic"',
    'approval_policy = "do-not-copy-policy-value"', 'sandbox_mode = "do-not-copy-sandbox-value"',
    '[profiles.unsafe]', 'model = ' + json.dumps(token),
    '[permissions]', 'credential = ' + json.dumps(token),
    '[projects.private]', 'trust_level = "trusted"',
    '[mcp_servers.not-captured]', 'command = "do-not-copy-command"',
]) + '\n'
config.write_text(text)
(workspace / '.codex').mkdir()
(workspace / '.codex/config.toml').write_text('invalid project document')

has_tomllib = importlib.util.find_spec('tomllib') is not None


def collect(*, selected=None, scopes=None):
    # All security/selection tests also run on Python <3.11, independently of
    # parser availability. A second run on 3.11+ exercises actual TOML bytes.
    context = nullcontext() if has_tomllib else patch(
        'acb.provider_review.importlib.import_module',
        return_value=SimpleNamespace(loads=lambda _: copy.deepcopy(document)))
    with context:
        return collect_provider_review(registry, selected_profiles=selected or {'codex/cli'}, scopes=scopes or {'user'})


before = hashlib.sha256(config.read_bytes()).hexdigest()
files, manifests, bindings, tasks = collect()
assert len(files) == len(manifests) == len(bindings) == len(tasks) == 1, tasks
payload = json.loads(next(iter(files.values())))
encoded = json.dumps([payload, tasks])
assert token not in encoded and 'old-user' not in encoded and 'old-password' not in encoded
assert 'query-credential' not in encoded
assert str(root) not in encoded
assert payload['review_only'] is True and payload['automatic_restore'] is False
assert payload['model_provider'] == 'gateway'
assert set(payload['model_providers']) == {'gateway'}, payload
provider = payload['model_providers']['gateway']
assert provider['http_headers']['Authorization'] == '${AUTHORIZATION}'
assert provider['http_headers']['X-Client'] == '${X_CLIENT}'
assert provider['http_headers']['X-Auth'] == '${X_AUTH}'
assert provider['http_headers']['authToken'] == '${AUTH_TOKEN}'
assert provider['http_headers']['Opaque'] == '${OPAQUE}'
assert provider['http_headers']['X-Explicit'] == 'Bearer ${KNOWN_REFERENCE}'
assert provider['env_http_headers'] == {'X-Api-Key': 'EXAMPLE_API_KEY'}
assert provider['env_key'] == 'EXAMPLE_API_KEY'
assert provider['wire_api'] == 'responses' and provider['request_max_retries'] == 3
assert provider['base_url'] == 'https://example.invalid/v1'
for omitted in ('opaque-auth-value', 'camel-query-value', 'unknown-query-value',
                'opaque-auth-header', 'opaque-camel-header', 'unknown-header-value'):
    assert omitted not in encoded
assert set(payload['profiles']) == {'focused'}
assert payload['profiles']['focused'] == {key: document['profiles']['focused'][key]
                                         for key in ('model', 'model_provider', 'model_reasoning_effort', 'personality')}
for forbidden in ('do-not-copy-policy-value', 'do-not-copy-sandbox-value', 'do-not-copy-command', 'trusted'):
    assert forbidden not in encoded
assert any(item.get('fields') == ['api_key'] for item in payload['unknown_fields'])
assert any(item['entry'] == 'bad' and item['reason'] == 'secret-rejected-entry' for item in tasks[0]['omissions'])
assert tasks[0]['providers_captured'] == tasks[0]['profiles_captured'] == 1
assert tasks[0]['status'] == 'partial-review' and tasks[0]['redactions']
assert any(set(item.get('query_fields_removed', [])) == {'accessToken', 'api_key', 'auth', 'opaque', 'region'} for item in tasks[0]['redactions'])
assert {'EXAMPLE_API_KEY', 'X_AUTH', 'AUTH_TOKEN', 'KNOWN_REFERENCE'} <= set(payload['required_credentials'])
assert manifests[0]['surface'] == 'review' and manifests[0]['status'] == 'manual-rebuild'
assert list(bindings) == ['review/codex/cli/user']
assert set(bindings['review/codex/cli/user']) == set(files)
assert hashlib.sha256(config.read_bytes()).hexdigest() == before
assert not any((workspace / '.codex').glob('*.json'))

# Variable references are names only; provider tokens cannot masquerade as env
# names, and unsafe unknown-field names are omitted without serializing values.
variant = copy.deepcopy(document)
variant['model_providers']['gateway']['env_key'] = token
variant['model_providers']['gateway']['env_http_headers']['Authorization'] = token
variant['model_providers']['gateway'][token] = 'unknown private value'
identifier_shaped_token = 'AIza' + 'a' * 35
variant['model_providers']['bad-reference'] = {'name': 'Rejected', 'env_key': identifier_shaped_token}
with patch('acb.provider_review.importlib.import_module', return_value=SimpleNamespace(loads=lambda _: variant)):
    isolated = collect_provider_review(registry, selected_profiles={'codex/cli'}, scopes={'user'})
variant_payload = json.loads(next(iter(isolated[0].values())))
assert 'env_key' not in variant_payload['model_providers']['gateway']
assert 'Authorization' not in variant_payload['model_providers']['gateway']['env_http_headers']
assert token not in json.dumps([variant_payload, isolated[3]])
assert identifier_shaped_token not in json.dumps([variant_payload, isolated[3]])
assert 'bad-reference' not in variant_payload['model_providers']
assert any(item['reason'] == 'environment-variable-name-required' for item in isolated[3][0]['omissions'])
assert any(item.get('unsafe_field_names_omitted') == 1 for item in isolated[3][0]['omissions'])

assert collect(selected={'claude/code-cli'}) == ({}, [], {}, [])
with patch('acb.provider_review.importlib.import_module', side_effect=ModuleNotFoundError):
    missing = collect_provider_review(registry, selected_profiles={'codex/cli'}, scopes={'user'})
assert not missing[0] and missing[3][0]['status'] == 'missing-parser'
assert missing[3][0]['reason'] == 'tomllib-unavailable'

# Bad parser data, missing sources and links produce safe actionable records.
with patch('acb.provider_review.importlib.import_module', return_value=SimpleNamespace(loads=lambda _: (_ for _ in ()).throw(ValueError(str(root) + '/private')))):
    invalid = collect_provider_review(registry, selected_profiles={'codex/cli'}, scopes={'project'})
assert not invalid[0] and invalid[3][0]['status'] == 'malformed'
assert str(root) not in json.dumps(invalid[3])
(workspace / '.codex/config.toml').unlink()
absent = collect_provider_review(registry, selected_profiles={'codex/cli'}, scopes={'project'})
assert not absent[0] and absent[3][0]['status'] == 'not-present'
if os.name == 'posix':
    (workspace / '.codex/config.toml').symlink_to(config)
    linked = collect_provider_review(registry, selected_profiles={'codex/cli'}, scopes={'project'})
    assert not linked[0] and linked[3][0]['status'] == 'malformed'
with patch('acb.provider_review.MAX_FILE_SIZE', 1):
    too_big = collect()
assert not too_big[0] and too_big[3][0]['reason'] == 'source-not-regular-or-too-large'
print('PASS: Codex provider/profile review is scoped, inert, redacted, isolated by entry and read-only')
PY
