#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_USER_TEST="$(mktemp -d)"
trap 'rm -rf "$CLAUDE_USER_TEST"' EXIT
export SCRIPT_DIR CLAUDE_USER_TEST PYTHONDONTWRITEBYTECODE=1
python3 -B - <<'PY'
from pathlib import Path
import json,os,subprocess,sys
root=Path(os.environ['CLAUDE_USER_TEST']).resolve();scripts=Path(os.environ['SCRIPT_DIR']);workspace=root/'project';workspace.mkdir()
def cli(home,*args):
 env=dict(os.environ,HOME=str(home),USERPROFILE=str(home),AGENT_SKILLS_PLATFORM='linux')
 env.pop('CODEX_HOME',None)
 r=subprocess.run([sys.executable,'-B',str(scripts/'context-migrator.py'),*map(str,args),'--json'],env=env,cwd=root,capture_output=True,text=True)
 assert r.returncode==0,(r.stdout,r.stderr)
 return json.loads(r.stdout)
for number,(source,target,source_path,target_path) in enumerate([
 ('codex/cli','claude/code-cli','.codex/AGENTS.md','.claude/CLAUDE.md'),
 ('claude/code-cli','codex/cli','.claude/CLAUDE.md','.codex/AGENTS.md')
]):
 home=root/('home-'+str(number));home.mkdir();path=home/source_path;path.parent.mkdir();text='Preserve reviewed user context across coding clients.\n';path.write_text(text)
 plan=root/(str(number)+'.plan.json');manifest=root/(str(number)+'.manifest.json')
 p=cli(home,'plan','--source',source,'--target',target,'--workspace',workspace,'--scope','user','--objects','instructions','--output',plan)
 assert len(p['items'])==1 and p['items'][0]['target']['resolved_path']==str(home/target_path),p
 assert p['items'][0]['status'] in {'ready','ready-lossy'},p
 assert not (home/target_path).exists() and not (workspace/'CLAUDE.md').exists()
 cli(home,'apply',plan,'--manifest',manifest,'--yes','--include','lossy')
 assert text.strip() in (home/target_path).read_text() and path.read_text()==text
 assert cli(home,'verify','--manifest',manifest)['ok']
print('OK reviewed Codex and Claude user instructions plan, apply and verify in both directions with actual native paths and explicit conversion-loss acceptance')
PY
