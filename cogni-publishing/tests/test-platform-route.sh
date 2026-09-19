#!/usr/bin/env bash
# Platform-route contract suite. The host-skill resolution and retry mechanism are prose-carried, so
# cases 01-03 pin their exact code shape and publish mutation recipes instead of pretending a shell
# stub can execute a host model decision. The stub exercises the executable artifact-admission half.
#
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/anthropic-skills:pptx/anthropic-skills:slides/' --test 'bash cogni-publishing/tests/test-platform-route.sh' --case platform-route-01-resolution-order
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/platform_renderer_unavailable/platform_renderer_missing/' --test 'bash cogni-publishing/tests/test-platform-route.sh' --case platform-route-02-unavailable-envelope
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/The repair budget defaults to 3 and is never more than 10/The repair budget is unbounded/' --test 'bash cogni-publishing/tests/test-platform-route.sh' --case platform-route-03-bounded-loop
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
need=["`anthropic-skills:pptx` or `document-skills:pptx`", "bundled `Presentations` skill on Codex",
      "description claims `.pptx` creation", "do not create or consult a renderer registry"]
assert all(x in t for x in need)
PY
then pass "platform-route-01-resolution-order"; else fail "platform-route-01-resolution-order"; fi

if grep -Fq '{"success": false, "error": "platform_renderer_unavailable"}' "$SKILL" &&
   ! find "$PLUGIN" -name platform-renderers.json -print -quit | grep -q .
then pass "platform-route-02-unavailable-envelope"; else fail "platform-route-02-unavailable-envelope"; fi

if grep -Fq 'The repair budget defaults to 3 and is never more than 10' "$SKILL" &&
   grep -Fq "When the budget is spent, report a bounded failure carrying the last attempt's findings; never report success" "$SKILL" &&
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
      "misleading-encoding", "unreadable-text", "clipping", "overlap", "appearance"]
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

if python3 - "$PLUGIN/references/render-provenance-v1.schema.json" <<'PY'
import json, sys
s=json.load(open(sys.argv[1]))
assert s["properties"]["renderer"]["required"] == ["name", "version", "target"]
assert s["properties"]["renderer"]["properties"]["kind"]["enum"] == ["stdlib", "platform"]
assert s["properties"]["reproducible"]["type"] == "boolean"
PY
then pass "platform-route-08-schema-additive"; else fail "platform-route-08-schema-additive"; fi

if grep -Fq 'local-render:pptx' "$ROOT/cogni-consult/skills/consult-publish/SKILL.md" &&
   grep -Fq 'local-render:html' "$ROOT/cogni-consult/skills/consult-publish/SKILL.md"
then pass "platform-route-09-consult-lineage"; else fail "platform-route-09-consult-lineage"; fi

printf 'RESULT: %d passed, %d failed\n' "$passes" "$failures"
[ "$failures" -eq 0 ]
