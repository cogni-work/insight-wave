#!/usr/bin/env bash
# Platform-route contract suite. The host-skill resolution and retry mechanism are prose-carried, so
# cases 01-03 pin their exact code shape and publish mutation recipes instead of pretending a shell
# stub can execute a host model decision. The stub exercises the executable artifact-admission half.
#
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/On Codex, select/On another host, select/' --test 'bash cogni-publishing/tests/test-platform-route.sh' --case platform-route-01-resolution-order
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/platform_renderer_unavailable/platform_renderer_missing/' --test 'bash cogni-publishing/tests/test-platform-route.sh' --case platform-route-02-unavailable-envelope
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/The repair budget defaults to 3 and is never more than 10/The repair budget is unbounded/' --test 'bash cogni-publishing/tests/test-platform-route.sh' --case platform-route-03-bounded-loop
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/(On Codex,.*?)(On an Anthropic host,.*?)(On another host,)/$2$1$3/' --test 'bash cogni-publishing/tests/test-platform-route.sh' --case platform-route-01-resolution-order
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/re-invoke that same selected presentation skill/stop after the initial attempt/' --test 'bash cogni-publishing/tests/test-platform-route.sh' --case platform-route-03-bounded-loop
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/carrying the last attempt.s findings verbatim/carrying no findings/' --test 'bash cogni-publishing/tests/test-platform-route.sh' --case platform-route-03-bounded-loop
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLUGIN="$ROOT/cogni-publishing"
SKILL="$PLUGIN/skills/design-render/SKILL.md"
QA="$PLUGIN/skills/design-render/references/visual-qa.md"
LAYOUT="$PLUGIN/references/layout-contract.md"
RENDER="$PLUGIN/scripts/design-render.py"
VERIFY="$PLUGIN/scripts/design-verify.py"
STUB="$PLUGIN/tests/fixtures/platform-stub/render-stub.py"
BRIEF="$PLUGIN/tests/fixtures/verify/direct-proof-v1.normalized.json"
COMP="$PLUGIN/tests/fixtures/verify/composition-proof-boardroom-v2.json"
THEME="$PLUGIN/themes/boardroom"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
passes=0
failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

if python3 - "$SKILL" <<'PY'
import pathlib, sys
t=pathlib.Path(sys.argv[1]).read_text()
codex="On Codex, select the bundled `presentations:Presentations` skill even when `document-skills:pptx` is installed."
anthropic="On an Anthropic host, select its installed `anthropic-skills:pptx` or `document-skills:pptx` capability."
fallback="On another host, select an installed skill whose description explicitly claims `.pptx` creation."
assert all(x in t for x in (codex, anthropic, fallback, "do not create or consult a renderer registry"))
assert t.index(codex) < t.index(anthropic) < t.index(fallback)
PY
then pass "platform-route-01-resolution-order"; else fail "platform-route-01-resolution-order"; fi

if grep -Fq '{"success": false, "error": "platform_renderer_unavailable"}' "$SKILL" &&
   ! find "$PLUGIN" -name platform-renderers.json -print -quit | grep -q .
then pass "platform-route-02-unavailable-envelope"; else fail "platform-route-02-unavailable-envelope"; fi

if grep -Fq 're-invoke that same selected presentation skill' "$SKILL" &&
   grep -Fq 'with every finding returned verbatim' "$SKILL" &&
   grep -Fq 'The repair budget defaults to 3 and is never more than 10' "$SKILL" &&
   grep -Fq 'Never make more re-invocations than the budget' "$SKILL" &&
   grep -Fq "When the budget is spent, report a bounded failure carrying the last attempt's findings verbatim; never report success" "$SKILL" &&
   python3 - "$STUB" "$ROOT" "$COMP" "$WORK" <<'PY'
import json, subprocess, sys
stub, root, comp, work = sys.argv[1:]
last = None
for attempt in range(1, 4):
    run = subprocess.run([sys.executable, stub, "--target", "pptx", "--out", work,
                          "--root", root, "--composition", comp, "--attempt", str(attempt),
                          "--fail-until", "10"], text=True, capture_output=True)
    assert run.returncode == 1
    last = json.loads(run.stdout)
assert last["data"]["attempt"] == 3 and last["data"]["findings"][0]["code"] == "stub-open-finding"
PY
then pass "platform-route-03-bounded-loop"; else fail "platform-route-03-bounded-loop"; fi

if python3 - "$QA" <<'PY'
import pathlib, sys
t=pathlib.Path(sys.argv[1]).read_text()
need=["copy-differs", "notes-differs", "sources-differs", "data-differs", "flattened-substitution",
      "misleading-encoding", "unreadable-text", "clipping", "overlap", "appearance",
      "Charts and text remain native and editable", "package-derived editability inventory",
      "read-back witness for each chart series and named text object"]
assert all(x in t for x in need)
PY
then pass "platform-route-04-handoff-falsifiers"; else fail "platform-route-04-handoff-falsifiers"; fi

if python3 - "$LAYOUT" <<'PY'
import pathlib, sys
t=pathlib.Path(sys.argv[1]).read_text()
assert all(x in t for x in ("data-unit", "data-pattern", "data-slot", "data-copy", "data-value", "data-source"))
PY
then pass "platform-route-05-layout-contract"; else fail "platform-route-05-layout-contract"; fi

ok=1
for target in html pptx; do
  python3 "$STUB" --target "$target" --out "$WORK/$target" --root "$PLUGIN" --composition "$COMP" >/dev/null || ok=0
  artifact="$WORK/$target/$( [ "$target" = html ] && printf index.html || printf deck.pptx )"
  python3 "$VERIFY" verify --target "$target" --brief "$BRIEF" --composition "$COMP" --theme "$THEME" --artifact "$artifact" >/dev/null || ok=0
  python3 "$RENDER" check-provenance --provenance "$WORK/$target/provenance.json" --composition "$COMP" --out-dir "$WORK/$target" >/dev/null || ok=0
done
if [ "$ok" -eq 1 ]; then pass "platform-route-06-stub-admission"; else fail "platform-route-06-stub-admission"; fi

if python3 - "$WORK/html/provenance.json" "$WORK" <<'PY'
import json, pathlib, subprocess, sys
source=pathlib.Path(sys.argv[1]); work=pathlib.Path(sys.argv[2]); render=source.parents[3]/"scripts"/"design-render.py"
# The shell checks field-level rejection below; this block only materializes variants.
p=json.loads(source.read_text())
for key in ("kind", "name", "version"):
    q=json.loads(json.dumps(p)); q["renderer"].pop(key); (work/f"missing-{key}.json").write_text(json.dumps(q))
q=json.loads(json.dumps(p)); q.pop("reproducible"); (work/"missing-reproducible.json").write_text(json.dumps(q))
PY
then
  ok=1
  for bad in "$WORK"/missing-*.json; do python3 "$RENDER" check-provenance --provenance "$bad" >/dev/null 2>&1 && ok=0; done
  if [ "$ok" -eq 1 ]; then pass "platform-route-07-provenance-required-fields"; else fail "platform-route-07-provenance-required-fields"; fi
else fail "platform-route-07-provenance-required-fields"; fi

if python3 - "$PLUGIN" "$WORK" <<'PYCODE'
import copy, importlib.util, json, pathlib, subprocess, sys
plugin, work = map(pathlib.Path, sys.argv[1:])
spec=importlib.util.spec_from_file_location("schema_check", plugin/"tests/fixtures/platform-stub/check-schema.py")
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
s=json.loads((plugin/"references/render-provenance-v1.schema.json").read_text())
records=list((plugin/"docs/design-verify-proof").glob("*/html/provenance.json"))
records+=list((plugin/"docs/design-verify-proof").glob("*/pptx/provenance.json"))
# Live host proofs are separate from the legacy stdlib fixtures and offline stub.
for host in ("codex-openai", "document-skills"):
    for target in ("html", "pptx"):
        path=plugin/"docs/design-verify-proof"/host/"boardroom"/target/"provenance.json"
        assert path.is_file(), "missing committed live proof: " + str(path)
        live=json.loads(path.read_text())
        skill="presentations:Presentations" if host == "codex-openai" else "document-skills:pptx"
        if target == "html":
            skill="cogni-publishing:design-render HTML"
        assert live["live_proof"] is True and live["renderer"]["name"] == skill
        checked=subprocess.run([sys.executable,str(plugin/"scripts/design-render.py"),"check-provenance", "--provenance",str(path),"--out-dir",str(path.parent)],capture_output=True,text=True)
        assert checked.returncode == 0, (str(path),checked.stdout)
        records.append(path)
records += [work/target/"provenance.json" for target in ("html", "pptx")]
for path in records:
    p=json.loads(path.read_text()); m.validate(p,s,s)
    required=("runtime","theme","inputs","language","fonts","layout_face","measurement","generated_at","run_id") if p["renderer"].get("kind") != "platform" else ("inputs","run","attempts","review","applicability","live_proof")
    for key in required:
        q=copy.deepcopy(p); q.pop(key)
        try: m.validate(q,s,s)
        except AssertionError: pass
        else: raise AssertionError(str(path)+" missing "+key)
    q=copy.deepcopy(p); q["outputs"]["artifact"]["sha256"]="not-a-digest"
    try: m.validate(q,s,s)
    except AssertionError: pass
    else: raise AssertionError("schema admitted a malformed output digest")
PYCODE
then pass "platform-route-08-schema-additive"; else fail "platform-route-08-schema-additive"; fi

if python3 - "$WORK/html/provenance.json" "$RENDER" <<'PYCODE'
import copy, json, pathlib, subprocess, sys
source=pathlib.Path(sys.argv[1]); render=sys.argv[2]
base=json.loads(source.read_text())
variants={}
def variant(name):
    value=copy.deepcopy(base); variants[name]=value; return value
variant("open-findings")["attempts"][-1]["findings"]=[{"code":"still-open"}]
variant("preserve-drift")["attempts"][-1]["preserve"]["differences"]=[{"path":"copy"}]
variant("stub-labelled-live")["live_proof"]=True
q=variant("stub-relabelled-as-live-host")
q["renderer"].update(name="presentations:Presentations", host="Codex")
q["run"].update(skill="presentations:Presentations", host="Codex", live=True)
q["live_proof"]=True
variant("empty-units")["attempts"][0].update(unit_ids_before=[],unit_ids_after=[])
variant("bad-attempt-type")["attempts"][0]=None
variant("wrong-attempt-number")["attempts"][0]["attempt"]=2
variant("wrong-host")["run"]["host"]="invented-host"
variant("wrong-skill")["run"]["skill"]="invented-skill"
variant("missing-input-digest")["inputs"]["brief"].pop("sha256")
variant("unsubstantiated-applicability")["applicability"]["theme"]=None
variant("bad-review-digest")["review"]["sha256"]="sha256:"+"0"*64
variant("bad-host-evidence-digest")["run"]["evidence"]["sha256"]="sha256:"+"0"*64
variant("missing-artifact-id").pop("artifact_id")
variant("missing-live-status").pop("live_proof")
variant("wrong-input-digest")["inputs"]["brief"]["sha256"]="sha256:"+"0"*64
for name, value in variants.items():
    path=source.parent/f"{name}.json"; path.write_text(json.dumps(value))
    run=subprocess.run([sys.executable, render, "check-provenance", "--provenance", str(path), "--out-dir", str(source.parent)], capture_output=True, text=True)
    assert run.returncode == 1, (name,run.stdout,run.stderr)
    result=json.loads(run.stdout)
    assert result["success"] is False and result["data"]["findings"], (name,result)
    if name == "stub-relabelled-as-live-host":
        assert "host-evidence-mismatch" in {f["code"] for f in result["data"]["findings"]}, result
# Historical failures remain in the ledger when a later attempt repairs them.
q=copy.deepcopy(base); failed=copy.deepcopy(q["attempts"][0]); failed["findings"]=[{"code":"repaired"}]
failed["preserve"]["differences"]=[{"path":"copy"}]
q["attempts"][0]["attempt"]=2; q["attempts"].insert(0,failed)
path=source.parent/"repaired-ledger.json"; path.write_text(json.dumps(q))
run=subprocess.run([sys.executable,render,"check-provenance","--provenance",str(path),"--out-dir",str(source.parent)], capture_output=True, text=True)
assert run.returncode == 0, run.stdout
PYCODE
then pass "platform-route-09-negative-evidence-controls"; else fail "platform-route-09-negative-evidence-controls"; fi

if grep -Fq 'local-render:pptx' "$ROOT/cogni-consult/skills/consult-publish/SKILL.md" &&
   grep -Fq 'local-render:html' "$ROOT/cogni-consult/skills/consult-publish/SKILL.md"
then pass "platform-route-10-consult-lineage"; else fail "platform-route-10-consult-lineage"; fi

# Full-slide and per-unit captures need a separate budget from the small legacy
# stdlib proof; keep each complete host bundle bounded, including its deck.
if python3 - "$PLUGIN/docs/design-verify-proof" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
for host in ("codex-openai", "document-skills"):
    bundle = root / host
    assert bundle.is_dir(), "missing platform proof: " + host
    sizes = [p.stat().st_size for p in bundle.rglob('*')
             if p.is_file() and p.suffix.lower() in (".png", ".pdf", ".pptx", ".jpg", ".jpeg", ".webp")]
    assert sizes and sum(sizes) <= 8 * 1024 * 1024, (host, sizes)
PY
then pass "platform-route-11-binary-budget"; else fail "platform-route-11-binary-budget"; fi

printf 'RESULT: %d passed, %d failed\n' "$passes" "$failures"
[ "$failures" -eq 0 ]
