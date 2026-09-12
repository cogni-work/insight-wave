#!/usr/bin/env bash
# Guard: the text-to-narrative skill's deterministic Phase 5 gates are real gates.
#
# WHAT THIS PINS
#   skills/text-to-narrative/scripts/validate-narrative.py reads a finished narrative and the
#   arc contract it claims, and reports the mechanical gates from
#   skills/text-to-narrative/references/validation.md. This suite proves two things about it:
#   a conforming narrative passes every gate, and each gate can go red on a narrative
#   that breaks precisely the rule it names. A validator that only ever sees a healthy
#   fixture is indistinguishable from one that cannot fail.
#
#   Every mutation is generated into this run's own mktemp -d from the tracked fixture
#   at tests/fixtures/narrative-output/corporate-visions-en.md; no tracked file is
#   written. The mutations are the replayable form of the mutation recipes the narrative
#   issues ask for: drop a Sources entry, add a fifth `##`, rename a heading, and so on.
#
# CASE LABEL SHAPE: `PASS: <id>` / `FAIL: <id>` with a single-token id, summary line
#   `RESULT:`. Ids are NV-prefixed so no summary line is read as a case verdict.
#
# Contract: runs as `bash <path>` with no arguments, from any cwd, touches no network,
# needs bash + coreutils + python3, and exits non-zero on failure.
#
# Mutation recipes (generic harness:
# ~/GitHub/dev/managed-service/cogni-service/scripts/mutation-check.sh):
#   --file cogni-workspace/skills/text-to-narrative/scripts/validate-narrative.py \
#     --expr 's{cites = body_cites if stage == "body" else opening_cites \+ body_cites}{cites = opening_cites + body_cites}' \
#     --test 'bash cogni-workspace/tests/test-narrative-validate.sh' --case NV21
#   --file cogni-workspace/skills/text-to-narrative/scripts/validate-narrative.py \
#     --expr 's{gate\("T0", not opening,}{gate\("T0", True,}' \
#     --test 'bash cogni-workspace/tests/test-narrative-validate.sh' --case NV19
#
# The first reverts the body-stage E1 restriction so it counts TL;DR markers again: the
# 14-body-marker narrative then clears the floor of 15 on 2 TL;DR repeats, NV21 goes RED
# and every other case stays green. The second defeats T0's absence assertion, so NV19
# (T0 red while TL;DR prose is still present) goes RED while NV20 stays green.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$HERE/.." && pwd)"
VALIDATOR="$PLUGIN_DIR/skills/text-to-narrative/scripts/validate-narrative.py"
FIXTURE="$PLUGIN_DIR/tests/fixtures/narrative-output/corporate-visions-en.md"
CONTRACT="$PLUGIN_DIR/skills/text-to-narrative/references/arc-corporate-visions.md"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

for f in "$VALIDATOR" "$FIXTURE" "$CONTRACT"; do
  if [ ! -f "$f" ]; then
    fail "NV0 inputs readable — missing $f"
    printf '%s\n' "RESULT: 1 narrative-validate case(s) failed."
    exit 1
  fi
done
pass "NV0 inputs readable"

# run <narrative> [stage] -> sets OUT (json) and RC. An empty or absent stage invokes the
# validator with no --stage flag at all, so every pre-existing call site is unchanged.
run() {
  if [ -n "${2:-}" ]; then
    OUT="$(python3 "$VALIDATOR" --narrative "$1" --contract "$CONTRACT" --stage "$2" --json 2>&1)"
    RC=$?
  else
    OUT="$(python3 "$VALIDATOR" --narrative "$1" --contract "$CONTRACT" --json 2>&1)"
    RC=$?
  fi
}

# gate_status <json> <gate id> -> pass|fail|absent
gate_status() {
  printf '%s' "$1" | python3 -c '
import json, sys
gid = sys.argv[1]
try:
    data = json.load(sys.stdin)
except Exception:
    print("unparseable"); sys.exit(0)
for g in data.get("data", {}).get("gates", []):
    if g["id"] == gid:
        print(g["status"]); sys.exit(0)
print("absent")
' "$2"
}

# ---------------------------------------------------------------- NV1 the fixture passes
run "$FIXTURE"
if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q '"success": true'; then
  pass "NV1 the conforming fixture passes every gate"
else
  printf '%s\n' "$OUT" | sed 's/^/    /'
  fail "NV1 the conforming fixture passes every gate (exit $RC)"
fi

# expect_red <id> <gate> <mutant path> [stage] — the mutant must exit non-zero AND name
# the gate red
expect_red() {
  run "$3" "${4:-}"
  status="$(gate_status "$OUT" "$2")"
  if [ "$RC" -ne 0 ] && [ "$status" = "fail" ]; then
    pass "$1 mutant turns $2 red"
  else
    printf '%s\n' "    exit=$RC gate=$2 status=$status"
    fail "$1 mutant turns $2 red"
  fi
}

# ---------------------------------------------------------------- NV2 fifth `##` -> S1
python3 - "$FIXTURE" "$TMPROOT/fifth.md" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
open(dst, "w", encoding="utf-8").write(text.rstrip("\n") + "\n\n## Appendix\n\nExtra section.\n")
PY
expect_red NV2 S1 "$TMPROOT/fifth.md"

# ---------------------------------------------------------------- NV3 renamed heading -> S2
sed 's/^## Why Now: Forcing Functions$/## Why Now: The Closing Window/' "$FIXTURE" > "$TMPROOT/renamed.md"
expect_red NV3 S2 "$TMPROOT/renamed.md"

# ---------------------------------------------------------------- NV4 body far under band -> C1
python3 - "$FIXTURE" "$TMPROOT/short.md" <<'PY'
import sys, re
src, dst = sys.argv[1], sys.argv[2]
lines = open(src, encoding="utf-8").read().splitlines()
out, in_pay = [], False
for line in lines:
    if line.startswith("## Why Pay"):
        in_pay = True
        out.append(line)
        out.append("")
        out.append("Short.")
        continue
    if in_pay:
        continue
    out.append(line)
open(dst, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
expect_red NV4 C1 "$TMPROOT/short.md"

# ---------------------------------------------------------------- NV5 arc_id mismatch -> C3
sed 's/^arc_id: "corporate-visions"$/arc_id: "jtbd-portfolio"/' "$FIXTURE" > "$TMPROOT/arcid.md"
expect_red NV5 C3 "$TMPROOT/arcid.md"

# ---------------------------------------------------------------- NV6 citations stripped -> E1
sed -E 's#<sup>\[[0-9]+\]\([^)]*\)</sup>##g' "$FIXTURE" > "$TMPROOT/nocites.md"
expect_red NV6 E1 "$TMPROOT/nocites.md"

# ---------------------------------------------------------------- NV7 numbering gap -> E2
sed 's#<sup>\[2\](source-02-vdma.md)</sup>#<sup>[30](source-02-vdma.md)</sup>#g' "$FIXTURE" > "$TMPROOT/gap.md"
expect_red NV7 E2 "$TMPROOT/gap.md"

# ---------------------------------------------------------------- NV8 DE ASCII fallback -> L1
# Switch the language flag to `de` and plant one digraph. S2 goes red too (the headings are
# English), which is why the assertion is on L1 by name rather than on the exit code alone.
sed -e 's/^language: "en"$/language: "de"/' -e 's/The cost of delay compounds\./Die Kosten fuer Verzoegerung steigen./' "$FIXTURE" > "$TMPROOT/ascii.md"
expect_red NV8 L1 "$TMPROOT/ascii.md"

# ---------------------------------------------------------------- NV9 TL;DR over band -> T1
python3 - "$FIXTURE" "$TMPROOT/longtldr.md" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
lines = open(src, encoding="utf-8").read().splitlines()
out, seen_sub = [], False
for line in lines:
    out.append(line)
    if line.startswith("*") and line.endswith("*") and not seen_sub:
        seen_sub = True
        out.append("")
        out.append(" ".join(["Padding sentence number %d adds words to the opening." % i for i in range(1, 9)]))
open(dst, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
expect_red NV9 T1 "$TMPROOT/longtldr.md"

# ---------------------------------------------------------------- NV10 TL;DR cites a number the body lacks -> T2
# The TL;DR's second citation is rewritten to a number no body sentence carries. Only the
# first occurrence (which is in the TL;DR) is touched, so the body stays intact.
python3 - "$FIXTURE" "$TMPROOT/orphan.md" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
needle = "<sup>[1](source-01-fraunhofer.md)</sup>, so the constraint"
if needle not in t:
    sys.exit(1)
t = t.replace(needle, "<sup>[99](source-09-nowhere.md)</sup>, so the constraint", 1)
open(dst, "w", encoding="utf-8").write(t)
PY
expect_red NV10 T2 "$TMPROOT/orphan.md"

# ---------------------------------------------------------------- NV11 cited entry dropped from Sources -> X1
# The replayable form of the Sources-block mutation recipe: drop one entry that the body
# still cites, re-run the deterministic gates, expect X1 red.
grep -v '^\[2\] ' "$FIXTURE" > "$TMPROOT/dropped.md"
expect_red NV11 X1 "$TMPROOT/dropped.md"

# ---------------------------------------------------------------- NV12 uncited entry added to Sources -> X1
{ cat "$FIXTURE"; echo '[9] source-09-nowhere.md — Nobody, "Uncited", 2026, https://example.org/uncited'; } > "$TMPROOT/uncited.md"
expect_red NV12 X1 "$TMPROOT/uncited.md"

# ---------------------------------------------------------------- NV13 a source carrying two numbers -> E3
# The last marker of source-02 is renumbered to a fresh 5, which keeps first-appearance order
# intact (1,2,3,4,5) so E2 stays green and E3 alone carries the finding.
python3 - "$FIXTURE" "$TMPROOT/twonums.md" <<'PY2'
import sys, re
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
body, sep, rest = t.partition("\n**Sources**")
idx = body.rfind("<sup>[2](source-02-vdma.md)</sup>")
if idx < 0:
    sys.exit(1)
body = body[:idx] + "<sup>[5](source-02-vdma.md)</sup>" + body[idx + len("<sup>[2](source-02-vdma.md)</sup>"):]
open(dst, "w", encoding="utf-8").write(body + sep + rest)
PY2
expect_red NV13 E3 "$TMPROOT/twonums.md"

# ---------------------------------------------------------------- NV16 Sources block removed entirely -> X1
# The block is mandatory, so its absence is a finding rather than a skipped gate.
python3 - "$FIXTURE" "$TMPROOT/nosources.md" <<'PY3'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
body, sep, rest = t.partition("\n**Sources**")
if not sep:
    sys.exit(1)
open(dst, "w", encoding="utf-8").write(body.rstrip("\n") + "\n")
PY3
expect_red NV16 X1 "$TMPROOT/nosources.md"

# ---------------------------------------------------------------- NV17 one element stripped of every citation -> E4
python3 - "$FIXTURE" "$TMPROOT/uncitedelement.md" <<'PY4'
import sys, re
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
head, sep, tail = t.partition("\n## Why Pay")
if not sep:
    sys.exit(1)
section, ssep, sources = tail.partition("\n**Sources**")
section = re.sub(r"<sup>\[\d+\]\([^)]*\)</sup>", "", section)
open(dst, "w", encoding="utf-8").write(head + sep + section + ssep + sources)
PY4
expect_red NV17 E4 "$TMPROOT/uncitedelement.md"

# ---------------------------------------------------------------- NV18 one element pushed over its proportional band -> C2
# ~160 filler words land in Why Pay (17% of a 1000-word target: band 144-195 words), which
# leaves the total inside C1's band so C2 is the gate that carries the finding.
python3 - "$FIXTURE" "$TMPROOT/fatelement.md" <<'PY5'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
head, sep, tail = t.partition("\n**Sources**")
filler = " ".join("Filler word number %d keeps the element growing." % i for i in range(1, 21))
open(dst, "w", encoding="utf-8").write(head.rstrip("\n") + "\n\n" + filler + "\n" + sep + tail)
PY5
expect_red NV18 C2 "$TMPROOT/fatelement.md"

# expect_gate <id> <gate> <narrative> <want status> [stage] — assert one gate's status by
# name. Used where the discriminating signal is a single gate and the exit code is not: a
# body-stage mutant reddens several gates at once, and `absent` has no exit code at all.
expect_gate() {
  run "$3" "${5:-}"
  status="$(gate_status "$OUT" "$2")"
  if [ "$status" = "$4" ]; then
    pass "$1 $2 is $4 on $(basename "$3")${5:+ at the $5 stage}"
  else
    printf '%s\n' "    gate=$2 want=$4 got=$status exit=$RC"
    fail "$1 $2 is $4 on $(basename "$3")${5:+ at the $5 stage}"
  fi
}

# ---------------------------------------------------------------- NV19 / NV20 T0 both ways
# T0 is the body stage's whole point: the four-element argument is graded BEFORE the
# Executive TL;DR exists. The tracked fixture carries a TL;DR, so it must go red; the same
# narrative with only that prose removed must go green. A T0 that cannot do both is not a
# gate. The mutant keeps the H1, the italic subtitle and the `---` rule — only the TL;DR
# paragraph between the subtitle and the first `##` is dropped.
python3 - "$FIXTURE" "$TMPROOT/notldr.md" <<'PY6'
import sys
src, dst = sys.argv[1], sys.argv[2]
lines = open(src, encoding="utf-8").read().splitlines()
idx = 1
while idx < len(lines) and lines[idx].strip() != "---":
    idx += 1
fm_end = idx
h2 = [k for k, l in enumerate(lines) if l.startswith("## ")]
if not h2:
    sys.exit(1)
first_h2 = h2[0]
out = []
for k, line in enumerate(lines):
    if fm_end < k < first_h2:
        s = line.strip()
        keep = (s == "" or s == "---" or s.startswith("# ")
                or (s.startswith("*") and s.endswith("*") and s.count("*") == 2))
        if not keep:
            continue
    out.append(line)
open(dst, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY6
expect_gate NV19 T0 "$FIXTURE" fail body
expect_gate NV20 T0 "$TMPROOT/notldr.md" pass body

# ---------------------------------------------------------------- NV21 / NV22 the E1 discriminator
# The defect the two stages exist to separate: a narrative whose BODY is under-evidenced,
# padded over the floor of 15 by TL;DR repeats. The tracked fixture carries 19 body markers
# and 2 TL;DR repeats of [1]; dropping the last 5 body markers leaves 14 + 2 = 16. The body
# stage must fail E1 on the body's 14, the final stage must pass on the total of 16. The
# assertion is per gate id, never on the exit code: deleting markers also reddens E4 and X1.
python3 - "$FIXTURE" "$TMPROOT/fourteen.md" <<'PY7'
import sys, re
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
marker = "\n## "
if marker not in t:
    sys.exit(1)
cut = t.index(marker)
head, body = t[:cut], t[cut:]
cit = re.compile(r"<sup>\[(\d+)\]\(([^)]+)\)</sup>")
found = list(cit.finditer(body))
if len(found) != 19:
    sys.exit(1)
for m in reversed(found[-5:]):
    body = body[:m.start()] + body[m.end():]
open(dst, "w", encoding="utf-8").write(head + body)
PY7
expect_gate NV21 E1 "$TMPROOT/fourteen.md" fail body
expect_gate NV22 E1 "$TMPROOT/fourteen.md" pass

# ---------------------------------------------------------------- NV23 / NV24 T1 and T2 withheld
# At the body stage T1 and T2 are ABSENT from data.gates, not reported as passing — a gate
# that green-lights a TL;DR which does not exist yet is an unfalsifiable pass.
expect_gate NV23 T1 "$FIXTURE" absent body
expect_gate NV24 T2 "$FIXTURE" absent body

# ---------------------------------------------------------------- NV25 / NV26 data.stage
# stage_value <json> -> the reported stage, or `missing`
stage_value() {
  printf '%s' "$1" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    print("unparseable"); sys.exit(0)
print(data.get("data", {}).get("stage", "missing"))
'
}
for pair in ":final:NV25" "body:body:NV26"; do
  st="${pair%%:*}"; rest="${pair#*:}"; want="${rest%%:*}"; cid="${rest#*:}"
  run "$FIXTURE" "$st"
  got="$(stage_value "$OUT")"
  if [ "$got" = "$want" ]; then
    pass "$cid data.stage is $want${st:+ under --stage $st}"
  else
    printf '%s\n' "    want=$want got=$got"
    fail "$cid data.stage is $want${st:+ under --stage $st}"
  fi
done

# ---------------------------------------------------------------- NV27 --help documents the flag
HELP_OUT="$(python3 "$VALIDATOR" --help 2>&1)"
if printf '%s' "$HELP_OUT" | grep -q -- "--stage" && printf '%s' "$HELP_OUT" | grep -q "final"; then
  pass "NV27 --help documents --stage and names final as the default"
else
  printf '%s\n' "$HELP_OUT" | sed 's/^/    /'
  fail "NV27 --help documents --stage and names final as the default"
fi

# ---------------------------------------------------------------- NV14 / NV15 the two end-to-end fixtures pass
for pair in "strategic-choice-en.md:strategic-choice:NV14" "consulting-problem-solving-de.md:consulting-problem-solving:NV15"; do
  f="${pair%%:*}"; rest="${pair#*:}"; arc="${rest%%:*}"; cid="${rest#*:}"
  OUT="$(python3 "$VALIDATOR" --narrative "$PLUGIN_DIR/tests/fixtures/narrative-output/$f" --contract "$PLUGIN_DIR/skills/text-to-narrative/references/arc-$arc.md" --json 2>&1)"
  RC=$?
  if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q '"success": true'; then
    pass "$cid end-to-end fixture $f passes every gate against the $arc contract"
  else
    printf '%s\n' "$OUT" | sed 's/^/    /'
    fail "$cid end-to-end fixture $f passes every gate against the $arc contract (exit $RC)"
  fi
done

# ---------------------------------------------------------------- summary
echo ""
if [ "$failures" -gt 0 ]; then
  echo "RESULT: $failures narrative-validate case(s) failed."
  exit 1
fi
echo "RESULT: all narrative-validate cases passed."
exit 0
