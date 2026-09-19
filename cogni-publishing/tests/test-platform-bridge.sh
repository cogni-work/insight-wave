#!/usr/bin/env bash
# The explicit host bridge is required, admits only verified bytes and never invokes a legacy writer.
set -u
PLUGIN="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
if python3 - "$PLUGIN" "$WORK" <<'PY'
import hashlib,json,pathlib,subprocess,sys
plugin,work=map(pathlib.Path,sys.argv[1:])
render=plugin/'scripts/design-render.py';verify=plugin/'scripts/design-verify.py'
fix=plugin/'tests/fixtures/verify'
common=['--target','html','--brief',str(fix/'direct-proof-v1.normalized.json'),'--composition',str(fix/'composition-proof-boardroom-v2.json'),'--theme',str(plugin/'themes/boardroom')]
def run(script,*args):
 p=subprocess.run([sys.executable,str(script),*map(str,args)],text=True,capture_output=True)
 assert not p.stderr,p.stderr
 return p.returncode,json.loads(p.stdout)
for script,command in ((render,'render'),(verify,'render-verified')):
 out=work/script.stem
 rc,e=run(script,command,*common,'--out',out)
 assert rc==1 and e=={'success':False,'error':'platform_renderer_unavailable'},e
 assert not out.exists()
for command in ('check-html','check-pptx','compare'):
 rc,e=run(render,command);assert rc==2 and e['data']['code']=='usage-error',e
rc,e=run(plugin/'scripts/validate-publishing.py','check-plan');assert rc==2,e
chain=json.loads((plugin/'tests/fixtures/contract-chain-v1.json').read_text())
chain['target_resolved_plan']['artifact_version']='2'
(work/'chain.json').write_text(json.dumps(chain))
rc,e=run(plugin/'scripts/validate-publishing.py','validate','--input',work/'chain.json')
assert rc==1 and e['data']['code']=='invalid-version',e
bridge=json.dumps([sys.executable,str(fix/'copy-artifact.py')])
rc,e=run(render,'render',*common,'--out',work/'green','--platform-command',bridge)
assert rc==0 and e['success'],e
assert json.loads((work/'green/verification.json').read_text())['verdict']=='pass'
# A poisoned native artifact with a freshly updated provenance digest must still fail independent verification.
wrapper=work/'poison.py'
wrapper.write_text('''import hashlib,json,pathlib,subprocess,sys
source=sys.argv[1];args=sys.argv[2:]
p=subprocess.run([sys.executable,source,*args],capture_output=True,text=True)
assert p.returncode==0,p.stdout
out=pathlib.Path(args[args.index('--out')+1]);page=out/'index.html'
text=page.read_text();text=text.replace('Maintenance','MAINTENANCE',1);page.write_text(text)
prov=json.loads((out/'provenance.json').read_text());prov['outputs']['artifact']['sha256']='sha256:'+hashlib.sha256(page.read_bytes()).hexdigest()
(out/'provenance.json').write_text(json.dumps(prov));print(p.stdout)
''')
poison=json.dumps([sys.executable,str(wrapper),str(fix/'copy-artifact.py')])
rc,e=run(render,'render',*common,'--out',work/'red','--platform-command',poison)
assert rc==1 and e['data']['code']=='verification-failed',e
assert not (work/'red').exists()
# Existing output is preserved byte for byte; malformed argv does not create output.
before=(work/'green/index.html').read_bytes()
rc,e=run(render,'render',*common,'--out',work/'green','--platform-command',bridge)
assert rc==1 and e['data']['code']=='output-exists',e
assert (work/'green/index.html').read_bytes()==before
rc,e=run(render,'render',*common,'--out',work/'bad','--platform-command','{"shell":"true"}')
assert rc==2 and not (work/'bad').exists(),e
PY
then printf 'PASS: platform-bridge-01-admission\n'; else printf 'FAIL: platform-bridge-01-admission\n'; exit 1; fi
