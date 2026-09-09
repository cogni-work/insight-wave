#!/usr/bin/env bash
#
# test-text-to-narrative-brief.sh — the text-to-narrative skill's design-brief
# checker is a real gate, and the skill's vendored asset set is what it claims.
#
# Three things are pinned:
#   1. skills/text-to-narrative/scripts/check-design-brief.py goes green on one
#      fixture per target (plus a German one) and red — on precisely the named
#      check — for one mutant per check; unreadable inputs are exit 2, never 0.
#   2. SKILL.md's local `references/...` and `scripts/...` paths resolve inside
#      the skill (templated `{arc_id}` / `${ARC_ID}` / `{language}` segments are
#      expanded).
#   3. The bundled validate-narrative.py is a gate against the flat contracts.
#      The identity and phase-parity cases that once compared the bundle against
#      the narrative skill retired with that skill: the bundle is the only copy,
#      and test-arc-contract-shape.sh grades its shape directly.
#
# Fixtures: tests/fixtures/design-brief/{slides-en,document-en,infographic-en,
# web-en,slides-de}.md, cut from tests/fixtures/narrative-output/. Mutants are
# built from copies in mktemp -d; no tracked file is written.
#
# Mutation recipes (generic harness:
# ~/GitHub/dev/managed-service/cogni-service/scripts/mutation-check.sh):
#   --file cogni-workspace/skills/text-to-narrative/scripts/check-design-brief.py \
#     --expr 's{if clauses < CONTRACT_MIN_CLAUSES:}{if False:}' \
#     --test 'bash cogni-workspace/tests/test-text-to-narrative-brief.sh' --case ttn-05-contract-clauses
#   --expr 's{if len\(points\) > c\["slide_points_max_lines"\]:}{if False:}' --case ttn-08-density-slides
#   --expr 's{if token not in b.narrative_numbers:}{if False:}' --case ttn-09-copy-frozen-numbers
#   --expr 's{for m in STYLING_KEY_RE.finditer\(b.body\):}{for m in []:}' --case ttn-12-no-styling-keys
#   --expr 's{if t != "bluf":}{if False:}' --case ttn-19-slides-open-bluf
#   --expr 's{if t != "sources":}{if False:}' --case ttn-20-slides-close-sources
#   --expr 's{if f.get\("type"\) == "sources":}{if False:}' --case ttn-01-green-slides
#     (the exemption's teeth: it reds ttn-01-green-slides AND ttn-01-green-slides-de,
#      since the sources unit of each fixture carries no slide_points)
#
#   --expr 's{if b.target == "slides" and not \(u is last and _visual_intent_exempt\(u\)\):}{if False:}' \
#     --case ttn-22-visual-intent-required-missing
#   --expr 's{if key not in allowed:}{if False:}' --case ttn-22-visual-intent-unknown-key
#   --expr 's{if value and value not in enum:}{if False:}' --case ttn-23-visual-intent-message-pattern-enum
#   The two disjuncts of the trailing-source-register exemption, each proven on its own —
#   disabling either branch reds only the case that isolates it:
#   --expr 's{f.get\("type"\) == "sources" or "slide_points" not in f}{False or "slide_points" not in f}' \
#     --case ttn-25-visual-intent-exempt-sources-type
#   --expr 's{f.get\("type"\) == "sources" or "slide_points" not in f}{f.get("type") == "sources" or False}' \
#     --case ttn-25-visual-intent-exempt-no-slide-points
#   --file cogni-workspace/skills/text-to-narrative/scripts/check-design-brief.py \
#     --expr 's{if value is not None and value not in EVIDENCE_STATUS_ENUM:}{if False:}' \
#     --test 'bash cogni-workspace/tests/test-text-to-narrative-brief.sh' --case ttn-26-evidence-status-out-of-enum
#
# CASE LABEL SHAPE: "PASS: <id>" / "FAIL: <id>", ids unique per emitted line.

set -u
export PYTHONDONTWRITEBYTECODE=1

failures=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WS="$ROOT/cogni-workspace"
SKILL="$WS/skills/text-to-narrative"
CHECKER="$SKILL/scripts/check-design-brief.py"
CEILINGS="$SKILL/references/density-ceilings.md"
FIX="$WS/tests/fixtures/design-brief"
NARR="$WS/tests/fixtures/narrative-output"
EN_NARR="$NARR/corporate-visions-en.md"
DE_NARR="$NARR/consulting-problem-solving-de.md"

pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

# run <brief> <narrative> <outfile> [extra args...] -> sets RC
run() {
  local brief="$1" narrative="$2" out="$3"
  shift 3
  python3 "$CHECKER" --brief "$brief" --narrative "$narrative" --json "$@" > "$out" 2>/dev/null
  RC=$?
}

# clean <outfile> — exit 0 when success is true and fails is 0
clean() {
  python3 - "$1" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
sys.exit(0 if d["success"] and d["data"].get("fails") == 0 else 1)
PY
}

# has_fail <outfile> <check> — exit 0 when the check appears with severity fail
has_fail() {
  python3 - "$1" "$2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
hits = [f for f in d["data"].get("findings", []) if f["check"] == sys.argv[2] and f["severity"] == "fail"]
sys.exit(0 if hits else 1)
PY
}

# has_fail_unit <outfile> <check> <unit> — exit 0 when the check appears with
# severity fail AND names that unit number (a null unit never satisfies it)
has_fail_unit() {
  python3 - "$1" "$2" "$3" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
want = int(sys.argv[3])
hits = [f for f in d["data"].get("findings", [])
        if f["check"] == sys.argv[2] and f["severity"] == "fail" and f.get("unit") == want]
sys.exit(0 if hits else 1)
PY
}

# no_fail <outfile> <check> — exit 0 when the check appears in NO finding. The
# complement of has_fail, needed where a mutant legitimately reds OTHER checks and
# the claim under test is only that this one stayed silent.
no_fail() {
  python3 - "$1" "$2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
hits = [f for f in d["data"].get("findings", []) if f["check"] == sys.argv[2]]
sys.exit(1 if hits else 0)
PY
}

# mutate <source-fixture> <dest> <python-transform> — copy then transform `text`
mutate() {
  python3 - "$1" "$2" "$3" <<'PY'
import sys
src, dst, transform = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(src, encoding="utf-8").read()
ns = {"text": text}
exec(transform, ns)
assert ns["text"] != text, "transform did not change the brief"
open(dst, "w", encoding="utf-8").write(ns["text"])
PY
}

# --- ttn-00: inputs readable --------------------------------------------------
missing=""
for f in "$CHECKER" "$CEILINGS" "$SKILL/SKILL.md" "$EN_NARR" "$DE_NARR" \
         "$FIX/slides-en.md" "$FIX/document-en.md" "$FIX/infographic-en.md" "$FIX/web-en.md" "$FIX/slides-de.md"; do
  [ -f "$f" ] || missing="$missing $f"
done
if [ -n "$missing" ]; then
  fail "ttn-00-inputs-readable missing:$missing"
  exit "$failures"
fi
pass "ttn-00-inputs-readable"

# --- ttn-01: every green fixture is clean -------------------------------------
for spec in "slides:slides-en:$EN_NARR" "document:document-en:$EN_NARR" "infographic:infographic-en:$EN_NARR" \
            "web:web-en:$EN_NARR" "slides-de:slides-de:$DE_NARR"; do
  IFS=: read -r id name narrative <<EOF
$spec
EOF
  run "$FIX/$name.md" "$narrative" "$TMPROOT/green-$name.json"
  if [ "$RC" -eq 0 ] && clean "$TMPROOT/green-$name.json"; then
    pass "ttn-01-green-$id"
  else
    fail "ttn-01-green-$id fixture $name.md has findings or exit $RC"
  fi
done

# --- ttn-02..ttn-12: one red mutant per check --------------------------------
# red <id> <check> <fixture> <narrative> <transform>
red() {
  local id="$1" check="$2" fixture="$3" narrative="$4" transform="$5"
  if ! mutate "$fixture" "$TMPROOT/$id.md" "$transform" 2>"$TMPROOT/$id.err"; then
    fail "$id the mutant could not be built: $(tr '\n' ' ' < "$TMPROOT/$id.err")"
    return
  fi
  run "$TMPROOT/$id.md" "$narrative" "$TMPROOT/$id.json"
  if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/$id.json" "$check"; then
    pass "$id"
  else
    fail "$id expected exit 1 with a '$check' fail, got exit $RC"
  fi
}

# red_unit <id> <check> <unit> <fixture> <narrative> <transform> — as red, but the
# finding must also carry the expected unit number
red_unit() {
  local id="$1" check="$2" unit="$3" fixture="$4" narrative="$5" transform="$6"
  if ! mutate "$fixture" "$TMPROOT/$id.md" "$transform" 2>"$TMPROOT/$id.err"; then
    fail "$id the mutant could not be built: $(tr '\n' ' ' < "$TMPROOT/$id.err")"
    return
  fi
  run "$TMPROOT/$id.md" "$narrative" "$TMPROOT/$id.json"
  if [ "$RC" -eq 1 ] && has_fail_unit "$TMPROOT/$id.json" "$check" "$unit"; then
    pass "$id"
  else
    fail "$id expected exit 1 with a '$check' fail on unit $unit, got exit $RC"
  fi
}

SL="$FIX/slides-en.md"
red ttn-02-frontmatter-type frontmatter-type "$SL" "$EN_NARR" \
  'text = text.replace("type: design-brief", "type: presentation-brief", 1)'
red ttn-03-target-enum target-enum "$SL" "$EN_NARR" \
  'text = text.replace("target: slides", "target: poster", 1)'
red ttn-04-contract-present contract-present "$SL" "$EN_NARR" \
  'start = text.index("# Rendering Contract"); end = text.index("## Slide 1:"); block = text[start:end]; text = text[:start] + text[end:]; text = text.replace("## Slide 2:", block + "## Slide 2:", 1)'
red ttn-05-contract-clauses contract-clauses "$SL" "$EN_NARR" \
  'import re; text = re.sub(r"^- `type` is a content shape.*\n", "", text, count=1, flags=re.M)'
red ttn-06-unit-numbering unit-numbering "$SL" "$EN_NARR" \
  'text = text.replace("## Slide 3:", "## Slide 4:", 1)'
red ttn-07-density-frontmatter density-frontmatter "$SL" "$EN_NARR" \
  'text = text.replace("    slide_points_max_lines: 4", "    slide_points_max_lines: 9", 1)'
red ttn-08-density-slides density-slides "$SL" "$EN_NARR" \
  'text = text.replace("- costs roughly a quarter of what inaction costs\n", "- costs roughly a quarter of what inaction costs\n- The constraint is signal, not labour\n", 1)'
red ttn-08-density-document density-document "$FIX/document-en.md" "$EN_NARR" \
  'summary = text[text.index("executive_summary:\n") + len("executive_summary:\n"):text.index("\n## Section 1:")].strip(); text = text.replace(summary, summary + " " + summary, 1)'
red ttn-08-density-infographic density-infographic "$FIX/infographic-en.md" "$EN_NARR" \
  'text = text.replace("- roughly 4x\n", "- roughly 4x\n- Set against 17.4 million, the comparison needs\n", 1)'
red ttn-08-density-web density-web "$FIX/web-en.md" "$EN_NARR" \
  'old = "The evidence shows it is an information problem. The operators that spend most on scheduled maintenance lose 11 percent more production hours than those that spend least [1]."; new = old + " In the same sample, 62 percent of unplanned stops had a measurable precursor in sensor data at least 48 hours before failure, and in 71 percent of those cases the data existed but was not read [1]. Scheduled work replaces parts on a calendar rather than on evidence of wear, so budget flows to components that were not failing while the components that were failing go unmonitored [2]."; assert old in text; text = text.replace(old, new, 1)'
red ttn-09-copy-frozen-numbers copy-frozen-numbers "$SL" "$EN_NARR" \
  'text = text.replace("- lose 11 percent more production hours [1]", "- lose 97 percent more production hours [1]", 1)'
red ttn-09-copy-frozen-key-figures copy-frozen-numbers "$SL" "$EN_NARR" \
  'text = text.replace("\"13.0 million euros (src: [1])\"", "\"99.9 million euros (src: [1])\"", 1)'
red ttn-09-copy-frozen-governing-thought copy-frozen-numbers "$SL" "$EN_NARR" \
  'text = text.replace("lose 11 percent more production hours than those that spend least [1].\"", "lose 88 percent more production hours than those that spend least [1].\"", 1)'
red ttn-09-copy-frozen-title copy-frozen-numbers "$SL" "$EN_NARR" \
  'text = text.replace("\n# The Maintenance Budget That Buys Downtime\n", "\n# The 999 Maintenance Budget That Buys Downtime\n", 1)'
red ttn-10-citations-resolve citations-resolve "$SL" "$EN_NARR" \
  'text = text.replace("- The constraint is signal, not labour\n", "- The constraint is signal, not labour [9]\n", 1)'
red ttn-11-key-figures-src key-figures-src "$SL" "$EN_NARR" \
  'text = text.replace("\"13.0 million euros (src: [1])\"", "\"13.0 million euros\"", 1)'
red ttn-12-no-styling-keys no-styling-keys "$SL" "$EN_NARR" \
  'text = text.replace("type: bluf\n", "type: bluf\nBackground: dark\n", 1)'

# --- ttn-08-max-units-*: the caller cap binds every unit-bearing target --------
run "$FIX/infographic-en.md" "$EN_NARR" "$TMPROOT/mu-info.json" --max-units 2
if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/mu-info.json" density-infographic; then
  pass "ttn-08-max-units-infographic"
else
  fail "ttn-08-max-units-infographic --max-units 2 did not cap a four-block infographic (exit $RC)"
fi
run "$FIX/web-en.md" "$EN_NARR" "$TMPROOT/mu-web.json" --max-units 2
if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/mu-web.json" density-web; then
  pass "ttn-08-max-units-web"
else
  fail "ttn-08-max-units-web --max-units 2 did not cap a six-section web brief (exit $RC)"
fi
run "$FIX/document-en.md" "$EN_NARR" "$TMPROOT/mu-doc.json" --max-units 2
if [ "$RC" -eq 0 ] && clean "$TMPROOT/mu-doc.json" && python3 -c "
import json,sys; d=json.load(open('$TMPROOT/mu-doc.json')); sys.exit(0 if any('max-units' in n for n in d['data'].get('notes',[])) else 1)"; then
  pass "ttn-08-max-units-document-ignored"
else
  fail "ttn-08-max-units-document-ignored the document target must stay green under --max-units 2 and say the flag was ignored (exit $RC)"
fi

# --- ttn-13..15: unreadable inputs are exit 2, never 0 ------------------------
# exit2 <id> <outfile> — success false, non-empty error, exit 2
exit2() {
  local id="$1" out="$2"
  if [ "$RC" -eq 2 ] && python3 -c "
import json,sys; d=json.load(open('$out')); sys.exit(0 if d['success'] is False and d['error'] else 1)"; then
    pass "$id"
  else
    fail "$id expected exit 2 with success:false and an error, got exit $RC"
  fi
}
run "$SL" "$EN_NARR" "$TMPROOT/no-ceilings.json" --ceilings "$TMPROOT/does-not-exist.md"
exit2 ttn-13-missing-ceilings-exit-2 "$TMPROOT/no-ceilings.json"
run "$SL" "$TMPROOT/does-not-exist.md" "$TMPROOT/no-narrative.json"
exit2 ttn-14-missing-narrative-exit-2 "$TMPROOT/no-narrative.json"
: > "$TMPROOT/empty.md"
run "$TMPROOT/empty.md" "$EN_NARR" "$TMPROOT/empty.json"
exit2 ttn-15-empty-brief-exit-2 "$TMPROOT/empty.json"

# --- ttn-16: --list-checks names every check the green run ran ----------------
python3 "$CHECKER" --list-checks > "$TMPROOT/list.json" 2>/dev/null
if python3 - "$TMPROOT/list.json" "$TMPROOT/green-slides-en.json" <<'PY'
import json, sys
listed = [c.replace("<target>", "slides") for c in json.load(open(sys.argv[1]))["data"]["checks"]]
ran = json.load(open(sys.argv[2]))["data"]["checks_run"]
sys.exit(0 if listed and listed == ran else 1)
PY
then
  pass "ttn-16-list-checks-complete"
else
  fail "ttn-16-list-checks-complete --list-checks and the green run's checks_run differ"
fi

# --- ttn-17 / ttn-18: SKILL.md's local paths resolve; a broken one is caught --
# check_paths <skill.md> -> prints dangling paths, exit 1 when any (or none extracted)
check_paths() {
  python3 - "$1" "$SKILL" <<'PY'
import os, re, sys
skill_md, skill_dir = sys.argv[1], sys.argv[2]
text = open(skill_md, encoding="utf-8").read()
cited = set(re.findall(r"(?<![A-Za-z0-9_/-])((?:references|scripts)/[A-Za-z0-9_.{}$-]+\.(?:md|py))", text))
if not cited:
    print("extracted zero paths")
    sys.exit(1)
arcs = sorted(f[len("arc-"):-3] for f in os.listdir(os.path.join(skill_dir, "references"))
              if f.startswith("arc-") and f != "arc-registry.md" and f.endswith(".md"))
bad, count = [], 0
for rel in sorted(cited):
    expansions = [rel]
    for token in ("{arc_id}", "${ARC_ID}"):
        if token in rel:
            expansions = [rel.replace(token, a) for a in arcs]
    if "{language}" in rel:
        expansions = [e.replace("{language}", lang) for e in expansions for lang in ("en", "de")]
    for path in expansions:
        count += 1
        if not os.path.isfile(os.path.join(skill_dir, path)):
            bad.append(path)
for b in bad:
    print("dangling:", b)
print(f"{count} path(s) checked")
sys.exit(1 if bad else 0)
PY
}
if check_paths "$SKILL/SKILL.md" > "$TMPROOT/paths.txt"; then
  pass "ttn-17-local-paths-resolve"
else
  fail "ttn-17-local-paths-resolve $(tr '\n' ' ' < "$TMPROOT/paths.txt")"
fi
sed 's#references/techniques-overview.md#references/does-not-exist.md#g' "$SKILL/SKILL.md" > "$TMPROOT/SKILL-mutant.md"
if grep -q 'does-not-exist.md' "$TMPROOT/SKILL-mutant.md" && ! check_paths "$TMPROOT/SKILL-mutant.md" > /dev/null; then
  pass "ttn-18-mutant-path-detected"
else
  fail "ttn-18-mutant-path-detected a rewritten path in a copy of SKILL.md was not reported"
fi

# --- ttn-19 / ttn-20: the slides deck opens on bluf and closes on sources ------
# Two separately-named checks, each naming its own unit, so a deck that loses its
# answer-first opening and one that loses its source register are distinguishable.
red_unit ttn-19-slides-open-bluf slides-open-bluf 1 "$SL" "$EN_NARR" \
  'text = text.replace("\ntype: bluf\n", "\ntype: two-column\n", 1)'
red_unit ttn-20-slides-close-sources slides-close-sources 8 "$SL" "$EN_NARR" \
  'text = text.replace("\ntype: sources\n", "\ntype: metric\n", 1)'

# The slide_points exemption is scoped to `sources`, not granted to every unit: the
# green fixture's sources unit carries none and stays clean (ttn-01-green-slides),
# while a non-sources unit stripped of its list is still reported.
red ttn-20-slides-points-still-required density-slides "$SL" "$EN_NARR" \
  'import re; i = text.index("## Slide 2:"); j = text.index("## Slide 3:"); blk = text[i:j]; nb = re.sub(r"slide_points:\n(?:- .*\n)+", "", blk, count=1); assert nb != blk; text = text[:i] + nb + text[j:]'

# --- ttn-22 / ttn-23 / ttn-24: the visual-intent arm ---------------------------
# One named check answers every malformation of the visual_intent block, so a brief
# cannot pass by being wrong in a new way. Each case names `visual-intent`.
red_unit ttn-22-visual-intent-required-missing visual-intent 2 "$SL" "$EN_NARR" \
  'import re; i = text.index("## Slide 2:"); j = text.index("## Slide 3:"); blk = text[i:j]; nb = re.sub(r"visual_intent:\n(?:  .*\n)+", "", blk, count=1); assert nb != blk; text = text[:i] + nb + text[j:]'

# An inline scalar parses as a str, never a mapping — which is what the arm detects.
red ttn-22-visual-intent-non-mapping visual-intent "$SL" "$EN_NARR" \
  'import re; text = re.sub(r"visual_intent:\n(?:  .*\n)+", "visual_intent: comparison\n", text, count=1)'

red ttn-22-visual-intent-unknown-key visual-intent "$SL" "$EN_NARR" \
  'text = text.replace("  message_pattern: decision\n", "  message_pattern: decision\n  narrative_beat: rising\n", 1)'

red ttn-22-visual-intent-empty-subkey visual-intent "$SL" "$EN_NARR" \
  'import re; text = re.sub(r"  focal_point: .*\n", "  focal_point:\n", text, count=1)'

red ttn-23-visual-intent-message-pattern-enum visual-intent "$SL" "$EN_NARR" \
  'text = text.replace("  message_pattern: decision\n", "  message_pattern: vibes\n", 1)'

red ttn-23-visual-intent-expression-enum visual-intent "$SL" "$EN_NARR" \
  'text = text.replace("  preferred_expression: metric\n", "  preferred_expression: infographic\n", 1)'

red ttn-23-visual-intent-asset-signal-enum visual-intent "$SL" "$EN_NARR" \
  'text = text.replace("  asset_signal: none\n", "  asset_signal: screenshot\n", 1)'

# The document target carries no unit-level visual decision at all.
red_unit ttn-24-visual-intent-on-document visual-intent 1 "$FIX/document-en.md" "$EN_NARR" \
  'text = text.replace("\nbody:\n", "\nvisual_intent:\n  message_pattern: shift\n  relationship: a relationship\n  focal_point: a focal point\nbody:\n", 1)'

# --- ttn-25: the trailing-source-register exemption is a DISJUNCTION -----------
# `type: sources` OR no `slide_points`, each sufficient on its own. Both are true of
# the green fixture's Slide 8, so neither disjunct is observable there — each needs a
# mutant that makes ONLY the other one false.
#
# First disjunct alone: Slide 8 keeps `type: sources` and GAINS a slide_points list,
# so "no slide_points" is false. The exemption must still hold.
if mutate "$SL" "$TMPROOT/ttn-25a.md" \
  'text = text.replace("\ntype: sources\n\ntalk_track:", "\ntype: sources\nslide_points:\n- The deck source register\n\ntalk_track:", 1)' 2>/dev/null; then
  run "$TMPROOT/ttn-25a.md" "$EN_NARR" "$TMPROOT/ttn-25a.json"
  if [ "$RC" -eq 0 ] && clean "$TMPROOT/ttn-25a.json"; then
    pass "ttn-25-visual-intent-exempt-sources-type"
  else
    fail "ttn-25-visual-intent-exempt-sources-type expected a clean exit 0, got exit $RC"
  fi
else
  fail "ttn-25-visual-intent-exempt-sources-type the mutant could not be built"
fi

# Second disjunct alone: Slide 8 loses `type: sources` but still carries no
# slide_points. Assert ONLY that visual-intent stayed silent — never exit 0, because
# slides-close-sources and density-slides fire independently on this mutant. A rule
# keyed solely on `type: sources` fails here, which is the whole point of the case.
if mutate "$SL" "$TMPROOT/ttn-25b.md" \
  'text = text.replace("\ntype: sources\n", "\ntype: bluf\n", 1)' 2>/dev/null; then
  run "$TMPROOT/ttn-25b.md" "$EN_NARR" "$TMPROOT/ttn-25b.json"
  if no_fail "$TMPROOT/ttn-25b.json" visual-intent; then
    pass "ttn-25-visual-intent-exempt-no-slide-points"
  else
    fail "ttn-25-visual-intent-exempt-no-slide-points the exemption is keyed on type: sources alone"
  fi
else
  fail "ttn-25-visual-intent-exempt-no-slide-points the mutant could not be built"
fi

# --- ttn-26..ttn-30: optional evidence-status metadata -----------------------
if mutate "$SL" "$TMPROOT/ttn-26.md" \
  'text = text.replace("\ntype: bluf\n", "\ntype: bluf\nevidence_status: guesswork\n", 1)' 2>/dev/null; then
  run "$TMPROOT/ttn-26.md" "$EN_NARR" "$TMPROOT/ttn-26.json"
  if [ "$RC" -eq 1 ] && python3 - "$TMPROOT/ttn-26.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
hits = [f for f in d["data"].get("findings", [])
        if f["check"] == "evidence-status" and f.get("unit") == 1]
detail = hits[0]["detail"] if len(hits) == 1 else ""
values = ("direct", "triangulated", "proxy", "interpretation", "mixed")
sys.exit(0 if all(v in detail for v in values) else 1)
PY
  then
    pass "ttn-26-evidence-status-out-of-enum"
  else
    fail "ttn-26-evidence-status-out-of-enum expected unit 1 and all five valid values (exit $RC)"
  fi
else
  fail "ttn-26-evidence-status-out-of-enum the mutant could not be built"
fi

if clean "$TMPROOT/green-slides-en.json" && no_fail "$TMPROOT/green-slides-en.json" evidence-status; then
  pass "ttn-27-evidence-status-optional"
else
  fail "ttn-27-evidence-status-optional a slides brief without the field must stay clean"
fi

if mutate "$SL" "$TMPROOT/ttn-28.md" \
  'text = text.replace("\ntype: bluf\n", "\ntype: bluf\nevidence_status: direct\n", 1)' 2>/dev/null; then
  run "$TMPROOT/ttn-28.md" "$EN_NARR" "$TMPROOT/ttn-28.json"
  if [ "$RC" -eq 0 ] && python3 - "$TMPROOT/green-slides-en.json" "$TMPROOT/ttn-28.json" <<'PY'
import json, sys
base, tagged = (json.load(open(p))["data"] for p in sys.argv[1:])
def frozen(data):
    return [f for f in data.get("findings", []) if f["check"] == "copy-frozen-numbers"]
sys.exit(0 if base["brief_word_count"] == tagged["brief_word_count"] and frozen(base) == frozen(tagged) else 1)
PY
  then
    pass "ttn-28-evidence-status-not-copy"
  else
    fail "ttn-28-evidence-status-not-copy valid metadata changed copy accounting (exit $RC)"
  fi
else
  fail "ttn-28-evidence-status-not-copy the mutant could not be built"
fi

if python3 - "$SKILL/references/design-brief-template.md" <<'PY'
import sys
t = open(sys.argv[1], encoding="utf-8").read()
slides = t[t.index("### slides"):t.index("### document")]
values = ("direct", "triangulated", "proxy", "interpretation", "mixed")
ordered = slides.index("type:") < slides.index("evidence_status:") < slides.index("element:") < slides.index("visual_intent:") < slides.index("slide_points:")
phrases = ("strongest label", "metadata, not frozen on-slide copy", "neutral evidence-status pattern", "otherwise keep it in notes")
sys.exit(0 if ordered and all(v in slides for v in values) and all(p in slides for p in phrases) else 1)
PY
then
  pass "ttn-29-evidence-status-template-contract"
else
  fail "ttn-29-evidence-status-template-contract slides grammar or semantics are incomplete"
fi

if python3 - "$SKILL/SKILL.md" <<'PY'
import sys
t = open(sys.argv[1], encoding="utf-8").read()
start = t.index("**Pass 1 — evidence draft.**")
end = t.index("\n\n**Pass 2 —", start)
p = t[start:end]
sys.exit(0 if "classify each material claim" in p and "never upgrade evidence strength beyond what the supplied material supports" in p else 1)
PY
then
  pass "ttn-30-evidence-status-pass-1"
else
  fail "ttn-30-evidence-status-pass-1 both evidence rules must live in Pass 1"
fi

# --- ttn-21: the vendored validator is a gate against the flat contracts ------
VAL="$SKILL/scripts/validate-narrative.py"
v_ok=1
v_count=0
for fixture in "$NARR"/*.md; do
  arc="$(grep -m1 '^arc_id:' "$fixture" | sed 's/^arc_id:[[:space:]]*//; s/"//g')"
  contract="$SKILL/references/arc-$arc.md"
  [ -f "$contract" ] || { v_ok=0; continue; }
  v_count=$((v_count + 1))
  python3 "$VAL" --narrative "$fixture" --contract "$contract" --json > /dev/null 2>&1 || v_ok=0
done
# mutant: a fifth `##` before the Sources block must turn the validator red
python3 - "$EN_NARR" "$TMPROOT/narr-mutant.md" <<'PY'
import sys
t = open(sys.argv[1], encoding="utf-8").read()
assert "\n**Sources**" in t
open(sys.argv[2], "w", encoding="utf-8").write(t.replace("\n**Sources**", "\n## A fifth heading\n\nExtra text.\n\n**Sources**", 1))
PY
python3 "$VAL" --narrative "$TMPROOT/narr-mutant.md" --contract "$SKILL/references/arc-corporate-visions.md" --json > /dev/null 2>&1
mrc=$?
if [ "$v_ok" -eq 1 ] && [ "$v_count" -ge 3 ] && [ "$mrc" -eq 1 ]; then
  pass "ttn-21-vendored-validator-green"
else
  fail "ttn-21-vendored-validator-green fixtures green=$v_ok count=$v_count mutant-exit=$mrc (expected 1)"
fi

exit "$failures"
