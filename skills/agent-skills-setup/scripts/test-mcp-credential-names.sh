#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREDENTIAL_TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$CREDENTIAL_TEST_ROOT"' EXIT
if command -v cygpath >/dev/null 2>&1; then
    CREDENTIAL_TEST_ROOT="$(cygpath -w "$CREDENTIAL_TEST_ROOT")"
    SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi
export HOME="$CREDENTIAL_TEST_ROOT"
export PYTHONPATH="$SCRIPT_DIR${PYTHONPATH:+:$PYTHONPATH}"
export PYTHONDONTWRITEBYTECODE=1

"${MCP_SECURITY_PYTHON:-python3}" - <<'PY'
import json
from urllib.parse import parse_qsl, urlsplit

from migration_core import LossReport, _safe_args, _safe_secret_value, _safe_url, emit_mcp_document, parse_mcp_document

literal = 'opaqueFixtureCredentialValue12345'
names = ['authToken', 'X-Auth', 'auth', 'accessToken', 'credential', 'credentials',
         'session', 'sessionId', 'signature', 'sig', 'key', 'APIKey', 'clientSecret',
         'X-APIKey', 'accesskey', 'AUTH_KEY']
for name in names:
    safe, changed = _safe_secret_value(name, literal)
    assert changed and safe.startswith('${') and literal not in safe, name
for name, value in [('LANG', 'en_US.UTF-8'), ('PATH', '/usr/bin:/bin'),
                    ('PYTHONPATH', '/old/project'), ('region', 'west'), ('MONKEY', 'ordinary')]:
    assert _safe_secret_value(name, value) == (value, False), name
for value in ('${AUTH_TOKEN}', '$AUTH_TOKEN', 'Bearer ${AUTH_TOKEN}'):
    assert _safe_secret_value('authToken', value) == (value, False)

args = []
for name in names:
    args.extend(['--' + name, literal, '--' + name + '=' + literal])
args.extend(['--region', 'west', '--path', '/old/project',
             'https://host.invalid/mcp?authToken=' + literal + '&region=west',
             '--url=https://host.invalid/mcp?auth=' + literal,
             'X-Auth: ' + literal, 'accessToken=' + literal])
report = LossReport()
safe_args = _safe_args(args, 'fixture', report)
assert literal not in json.dumps(safe_args)
assert '--region' in safe_args and 'west' in safe_args and '/old/project' in safe_args
assert report.lossy
query = '&'.join(name + '=' + literal for name in names) + '&region=west'
safe_url = _safe_url('https://host.invalid/mcp?' + query, 'fixture', LossReport())
assert literal not in safe_url
values = dict(parse_qsl(urlsplit(safe_url).query))
assert values['region'] == 'west'
assert all(values[name].startswith('${') for name in names)

# The automatic writer must use the same expanded boundary; this is distinct
# from the more conservative inert-review policy for arbitrary header/env data.
document = {'mcpServers': {'fixture': {'command': 'fixture-local-tool',
    'args': ['--authToken', literal],
    'env': {'LANG': 'en_US.UTF-8', 'PATH': '/usr/bin', 'authToken': literal, 'AUTH_KEY': literal}}}}
servers = parse_mcp_document(json.dumps(document), 'json:mcpServers')
emitted, losses = emit_mcp_document(servers, 'json:mcpServers')
assert literal not in emitted and losses.lossy
definition = json.loads(emitted)['mcpServers']['fixture']
assert definition['env']['LANG'] == 'en_US.UTF-8' and definition['env']['PATH'] == '/usr/bin'
assert definition['env']['authToken'] == '${AUTH_TOKEN}'
assert definition['env']['AUTH_KEY'] == '${AUTH_KEY}'
print('PASS: automatic MCP redacts camelCase/auth/credential/session/signature/key names, flags and URLs while preserving LANG/PATH and explicit references')
PY
