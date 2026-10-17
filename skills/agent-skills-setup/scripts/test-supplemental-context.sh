#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPPLEMENTAL_CONTEXT_TEST="$(mktemp -d)"
trap 'rm -rf "$SUPPLEMENTAL_CONTEXT_TEST"' EXIT
export SCRIPT_DIR SUPPLEMENTAL_CONTEXT_TEST PYTHONDONTWRITEBYTECODE=1
"${SUPPLEMENTAL_TEST_PYTHON:-python3}" -I -B - <<'PY'
from pathlib import Path
import hashlib,json,os,subprocess,sys
root=Path(os.environ['SUPPLEMENTAL_CONTEXT_TEST']).resolve();scripts=Path(os.environ['SCRIPT_DIR']);src=root/'source';home=root/'home';src.mkdir();home.mkdir()
settings=src/'settings.json';settings.write_text(json.dumps({'locale':'zh-cn','disabled':['one','two'],'secretSibling':'DO_NOT_CAPTURE_PRIVATE_SIBLING','plugins':{'plugin@market:colon':{'version':'1.2.3','secretSibling':'DO_NOT_CAPTURE_PRIVATE_SIBLING'}},'backgroundOperation':True}))
shell=src/'profile';shell.write_text('privateSibling=DO_NOT_CAPTURE_PRIVATE_SIBLING\nclaude() {\n  touch DO_NOT_EXECUTE_SOURCE\n  command claude "$@"\n}\n')
sources=[{'id':'preferences','path':str(settings),'kind':'preferences','format':'json','fields':[['locale'],['disabled']],'string_arrays':[['disabled']]},{'id':'inventory','path':str(settings),'kind':'installation-inventory','format':'json','selectors':[{'path':['plugins','*'],'fields':[['version']]}]},{'id':'shell','path':str(shell),'kind':'shell-context','functions':['claude']},{'id':'behavior','path':str(settings),'kind':'preferences','format':'json','fields':[['backgroundOperation']],'classification':'activation-bearing'}]
scope=root/'scope.json';scope.write_text(json.dumps({'schema_version':1,'clients':[{'id':'fixture','label':'fixture'}],'review':{'schema_version':1,'clients':[{'id':'fixture','label':'fixture','sources':sources}]}}));source_before={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in src.rglob('*') if p.is_file()}
env=dict(os.environ,HOME=str(home));env.pop('CODEX_HOME',None)
def cli(tool,*args,ok=True):
 r=subprocess.run([sys.executable,'-I','-B',str(tool),*map(str,args)],env=env,cwd=root,capture_output=True,text=True);d=json.loads(r.stdout);assert (r.returncode==0)==ok and d['ok']==ok,(d,r.stderr);return d
packet=root/'packet';cli(scripts/'device-export.py','--spec',scope,'--output',packet)
assert not any(b'DO_NOT_CAPTURE_PRIVATE_SIBLING' in p.read_bytes() for p in packet.rglob('*') if p.is_file())
entries=[{'client':'fixture','source':'preferences','target':str(home/'settings.json'),'format':'json'},{'client':'fixture','source':'inventory','target':str(home/'inventory.json')},{'client':'fixture','source':'shell','target':str(home/'.ai-ide-migration/pending/shell/fixture')},{'client':'fixture','source':'behavior','target':str(home/'behavior.json'),'format':'json'}];mapping=root/'mapping.json';m={'schema_version':1,'roots':[str(home)],'entries':entries};mapping.write_text(json.dumps(m));tool=packet/'skill/scripts/review-restore.py';plan=root/'plan.json';cli(tool,'plan','--packet',packet,'--mapping',mapping,'--plan-out',plan);d=json.loads(plan.read_text());reasons={row['reason'] for row in d['remaining_work']};assert {'installation-provenance-captured-not-installed','behavior-or-installation-source-needs-native-review','shell-snippets-staged-not-sourced-review-routing-dependencies'}<=reasons
state=root/'state';cli(tool,'apply','--packet',packet,'--mapping',mapping,'--plan-in',plan,'--state-dir',state,'--yes');cli(tool,'verify','--state-dir',state)
assert json.loads((home/'settings.json').read_text())=={'locale':'zh-cn','disabled':['one','two']};assert (home/'.ai-ide-migration/pending/shell/fixture/functions/claude.sh').is_file();assert not (home/'inventory.json').exists() and not (home/'behavior.json').exists() and not (root/'DO_NOT_EXECUTE_SOURCE').exists()
cli(tool,'rollback','--state-dir',state,'--yes')
entries[3]['behavior_reviewed']=True;mapping.write_text(json.dumps(m));reviewed=root/'reviewed.json';cli(tool,'plan','--packet',packet,'--mapping',mapping,'--plan-out',reviewed);assert any(op['target']==str(home/'behavior.json') for op in json.loads(reviewed.read_text())['operations'])
entries[2]['target']=str(home/'profile');mapping.write_text(json.dumps(m));cli(tool,'plan','--packet',packet,'--mapping',mapping,'--plan-out',root/'escape.json',ok=False)
assert source_before=={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in src.rglob('*') if p.is_file()}
print('OK self-contained source capture, install inventory and shell staging with explicit behavior review, no whole profile or command execution, and verified rollback')
PY
