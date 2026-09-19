#!/usr/bin/env bash
# Browser measurement survives renderer retirement. Required CI provisioning cannot skip.
set -u
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RENDER="$PLUGIN_ROOT/scripts/design-render.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
passes=0; failures=0; skips=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
skip() { printf 'SKIP: %s\n' "$1"; skips=$((skips+1)); }
unprovisioned() {
  if [ "${COGNI_PUBLISHING_REQUIRE_PROVISIONED:-}" = 1 ]; then fail "$1"; else skip "$1"; fi
}
if python3 "$RENDER" check-runtime-lock > "$WORK/lock.json"; then pass bm-01-lock; else fail bm-01-lock; fi
for variant in range missing; do
  mkdir "$WORK/$variant"
  cp "$PLUGIN_ROOT/runtime/package.json" "$PLUGIN_ROOT/runtime/package-lock.json" "$PLUGIN_ROOT/runtime/.gitignore" "$WORK/$variant/"
  python3 - "$WORK/$variant/package.json" "$variant" <<'PY'
import json,sys
p,variant=sys.argv[1:];m=json.load(open(p))
if variant=='range':m['dependencies']['playwright-core']='^'+m['dependencies']['playwright-core']
else:m['dependencies']['left-pad']='1.3.0'
json.dump(m,open(p,'w'))
PY
  rc=0
  python3 "$RENDER" check-runtime-lock --runtime-dir "$WORK/$variant" > "$WORK/$variant.json" || rc=$?
  if [ "$rc" -eq 1 ] && python3 - "$WORK/$variant.json" "$variant" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]));code='range-pin' if sys.argv[2]=='range' else 'lock-missing'
assert not r['success'] and code in {f['code'] for f in r['data']['findings']}
PY
  then pass "bm-02-lock-$variant"; else fail "bm-02-lock-$variant"; fi
done
mkdir "$WORK/empty-runtime"
rc=0
python3 "$RENDER" measure --html absent --out "$WORK/absent.json" --runtime-root "$WORK/empty-runtime" > "$WORK/missing.json" || rc=$?
if [ "$rc" -eq 2 ] && [ ! -e "$WORK/absent.json" ] && python3 - "$WORK/missing.json" "$WORK/empty-runtime" <<'PY'
import json,pathlib,sys
r=json.load(open(sys.argv[1]));assert r['data']['code']=='runtime-missing' and 'provision.sh' in r['error']
assert not list(pathlib.Path(sys.argv[2]).iterdir())
PY
then pass bm-03-missing-runtime; else fail bm-03-missing-runtime; fi
PAGE="$PLUGIN_ROOT/tests/fixtures/verify/reference-artifacts/boardroom/html/index.html"
rc=0
python3 "$RENDER" measure --html "$PAGE" --out "$WORK/measured.json" > "$WORK/measure.out" || rc=$?
if [ "$rc" -eq 2 ] && python3 -c 'import json,sys;assert json.load(open(sys.argv[1]))["data"]["code"]=="runtime-missing"' "$WORK/measure.out"; then
  unprovisioned bm-04-browser-evidence
elif [ "$rc" -eq 0 ] && python3 "$RENDER" measure --html "$PAGE" --out "$WORK/again.json" >/dev/null && python3 - "$WORK/measured.json" "$WORK/again.json" <<'PY'
import json,sys
one,two=(json.load(open(p)) for p in sys.argv[1:])
assert one['requests']=={'blocked':[],'failed':[]} and not one['clipped'] and one['platform_fonts']
assert one['units']==two['units']
PY
then pass bm-04-browser-evidence; else fail bm-04-browser-evidence; fi
# The declared Python floor compiles all remaining production modules in memory.
floor_py=""
for candidate in python3.9 python3.10 python3.11 /usr/bin/python3; do
  bin="$(command -v "$candidate" 2>/dev/null)" || continue
  ver="$("$bin" -c 'import sys; print("%d%02d" % sys.version_info[:2])' 2>/dev/null)" || continue
  case "$ver" in ''|*[!0-9]*) continue ;; esac
  if [ "$ver" -ge 309 ] && [ "$ver" -lt 312 ]; then floor_py="$bin"; break; fi
done
if [ -z "$floor_py" ]; then unprovisioned bm-05-python-floor
elif "$floor_py" - "$PLUGIN_ROOT/scripts" <<'PY'
from pathlib import Path
import sys
for p in Path(sys.argv[1]).glob('*.py'):compile(p.read_text(),str(p),'exec')
PY
then pass bm-05-python-floor; else fail bm-05-python-floor; fi
printf 'Browser measurement: %s passed, %s failed, %s skipped\n' "$passes" "$failures" "$skips"
[ "$failures" -eq 0 ]
