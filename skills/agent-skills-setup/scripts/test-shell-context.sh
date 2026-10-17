#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_CONTEXT_TEST="$(mktemp -d)"
trap 'rm -rf "$SHELL_CONTEXT_TEST"' EXIT
export SCRIPT_DIR SHELL_CONTEXT_TEST PYTHONDONTWRITEBYTECODE=1
python3 -B - <<'PY'
from pathlib import Path
import hashlib,os,sys
sys.path.insert(0,os.environ['SCRIPT_DIR']);from acb.shell_context import collect_shell_context
root=Path(os.environ['SHELL_CONTEXT_TEST']);path=root/'profile';text='unselected_secret=SYNTHETIC_PRIVATE_SIBLING\nexport PATH="/example/.antigravity-ide/bin:$PATH"\nclaude() {\n  touch DO_NOT_EXECUTE\n  command claude "$@"\n}\n';path.write_text(text);before=hashlib.sha256(path.read_bytes()).hexdigest()
files,tasks=collect_shell_context(path,{'functions':['claude'],'path_markers':['.antigravity-ide/bin']})
assert not tasks and set(files)=={'functions/claude.sh','path-bindings.sh'}
assert b'SYNTHETIC_PRIVATE_SIBLING' not in b''.join(files.values());assert not (root/'DO_NOT_EXECUTE').exists();assert before==hashlib.sha256(path.read_bytes()).hexdigest()
path.write_text(text+'claude() {\n  exit 1\n}\n');files,tasks=collect_shell_context(path,{'functions':['claude']});assert not files and tasks[0]['reason']=='shell-function-absent-or-ambiguous'
path.write_text('export PATH="/example/.antigravity-ide/antigravity-ide/bin:$PATH"\n')
files,tasks=collect_shell_context(path,{'path_markers':['.antigravity-ide/antigravity-ide/bin']})
assert not tasks and 'path-bindings.sh' in files
files,tasks=collect_shell_context(path,{'path_markers':['missing-marker']})
assert not files and tasks[0]['reason']=='shell-path-marker-not-present'
print('OK named shell functions/PATH captured inertly; private siblings excluded, duplicates rejected and source unchanged')
PY
