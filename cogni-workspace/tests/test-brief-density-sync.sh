#!/usr/bin/env bash
#
# test-brief-density-sync.sh — every density ceiling the text-to-narrative skill
# states still agrees with the surviving home it was carried from.
#
# skills/text-to-narrative/references/density-ceilings.md is the one home the
# design-brief checker reads. Its numbers were consolidated from older homes in
# the story-to-* brief producers and the narrative validator. The producers and
# the narrative skill have retired; what survives, and what this suite compares
# the reference against, is:
#   1. scripts/check-brief.py constants (slides)
#   2. skills/text-to-narrative/scripts/validate-narrative.py constants and the
#      C1 band, plus one arc contract's four `### N.` element sections (document)
#   3. libraries/web-section-copywriting.md and web-section-architecture.md (web)
#   4. libraries/infographic-style-presets.md and
#      infographic-block-copywriting.md (infographic)
# A key whose only home retired with its producer is a SOLE-HOME key: the
# reference is now its only statement, and bds-07 lists such keys explicitly in
# both directions — an untracked key must be listed, and a listed key must be
# untracked — so the list cannot go stale in either direction. Retire this suite
# only when the render chain retires and check-brief.py goes with it.
#
# Every home's path can be overridden so a mutant copy can be graded without
# editing the tree:
#   BRIEF_DENSITY_REFERENCE   BRIEF_DENSITY_CHECKER    BRIEF_DENSITY_VALIDATOR
#   BRIEF_DENSITY_ARC_CONTRACT BRIEF_DENSITY_WEB_COPY  BRIEF_DENSITY_WEB_ARCH
#   BRIEF_DENSITY_INFO_PRESETS BRIEF_DENSITY_INFO_BLOCKS
#
# Mutation recipe (the discriminator is bds-03-slides-matches-homes):
#
#   cp cogni-workspace/skills/text-to-narrative/references/density-ceilings.md "$T/dc.md"
#   sed -i '' 's/| `slide_point_words_max` | 10 |/| `slide_point_words_max` | 99 |/' "$T/dc.md"
#   BRIEF_DENSITY_REFERENCE="$T/dc.md" bash cogni-workspace/tests/test-brief-density-sync.sh
#
# must print `FAIL: bds-03-slides-matches-homes`. bds-08 runs that very mutant
# inside this suite, so a green run already proves the override path is live.
#
# Generic harness: ~/GitHub/dev/managed-service/cogni-service/scripts/mutation-check.sh
#   --file cogni-workspace/skills/text-to-narrative/references/density-ceilings.md \
#   --expr 's{\| `slide_point_words_max` \| 10 \|}{| `slide_point_words_max` | 99 |}' \
#   --test 'bash cogni-workspace/tests/test-brief-density-sync.sh' --case bds-03-slides-matches-homes

set -u
export PYTHONDONTWRITEBYTECODE=1

failures=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WS="$ROOT/cogni-workspace"
REFERENCE="${BRIEF_DENSITY_REFERENCE:-$WS/skills/text-to-narrative/references/density-ceilings.md}"
CHECKER="${BRIEF_DENSITY_CHECKER:-$WS/scripts/check-brief.py}"
VALIDATOR="${BRIEF_DENSITY_VALIDATOR:-$WS/skills/text-to-narrative/scripts/validate-narrative.py}"
ARC_CONTRACT="${BRIEF_DENSITY_ARC_CONTRACT:-$WS/skills/text-to-narrative/references/arc-corporate-visions.md}"
WEB_COPY="${BRIEF_DENSITY_WEB_COPY:-$WS/libraries/web-section-copywriting.md}"
WEB_ARCH="${BRIEF_DENSITY_WEB_ARCH:-$WS/libraries/web-section-architecture.md}"
INFO_PRESETS="${BRIEF_DENSITY_INFO_PRESETS:-$WS/libraries/infographic-style-presets.md}"
INFO_BLOCKS="${BRIEF_DENSITY_INFO_BLOCKS:-$WS/libraries/infographic-block-copywriting.md}"

pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

cat > "$TMPROOT/homes.py" <<'PY'
"""Print {"reference": {target: {key: value}}, "upstream": {target: {key: {home: value}}}}.

Exit 3 when a home cannot be read or a reading is missing — an empty reading must
never compare equal to anything.
"""
import importlib.util, json, re, sys

(reference, checker, validator, arc_contract,
 web_copy, web_arch, info_presets, info_blocks) = sys.argv[1:9]


def read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def num(text):
    text = text.strip().strip("*")
    return float(text) if "." in text else int(text)


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def must(pattern, text, flags=0, group=1):
    m = re.search(pattern, text, flags)
    if not m:
        sys.exit(3)
    return m.group(group)


def table_rows(text, heading):
    """Rows of the first pipe table after `heading`, as lists of stripped cells."""
    start = text.find(heading)
    if start < 0:
        sys.exit(3)
    rows = []
    for line in text[start:].splitlines()[1:]:
        if line.startswith("|"):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if cells and not set(cells[0]) <= set("-: "):
                rows.append(cells)
        elif rows:
            break
    if len(rows) < 2:
        sys.exit(3)
    return rows[1:]  # drop the header row


# --- the reference -----------------------------------------------------------
ref = {}
section = None
for line in read(reference).splitlines():
    m = re.match(r"^## ([a-z]+)\s*$", line)
    if m:
        section = m.group(1)
        ref[section] = {}
        continue
    m = re.match(r"^\| `([a-z_]+)` \| ([0-9.]+) \|", line)
    if m and section:
        ref[section][m.group(1)] = num(m.group(2))

# --- the homes ---------------------------------------------------------------
up = {t: {} for t in ("slides", "document", "infographic", "web")}


def put(target, key, home, value):
    up[target].setdefault(key, {})[home] = value


cb = load(checker, "_check_brief")
put("slides", "headline_chars_max", "check-brief", cb.HEADLINE_MAX)
put("slides", "slide_point_words_max", "check-brief", cb.BULLET_WORDS_MAX)
put("slides", "slide_point_words_max_table", "check-brief", cb.IDM_BUDGET["DOES-Box"])
put("slides", "talk_track_words_min", "check-brief", cb.NOTES_WORDS_MIN)
put("slides", "talk_track_words_max", "check-brief", cb.NOTES_WORDS_MAX)
put("slides", "units_min", "check-brief", cb.DECK_MIN_CONTENT)
put("slides", "units_max_default", "check-brief", cb.DECK_MAX_DEFAULT)

vn = load(validator, "_validate_narrative")
put("document", "target_length_default", "validate-narrative", vn.DEFAULT_TARGET)
put("document", "summary_words_min", "validate-narrative", vn.TLDR_WORDS[0])
put("document", "summary_words_max", "validate-narrative", vn.TLDR_WORDS[1])
put("document", "summary_sentences_min", "validate-narrative", vn.TLDR_SENTENCES[0])
put("document", "summary_sentences_max", "validate-narrative", vn.TLDR_SENTENCES[1])
band = re.search(r"target \* (0\.\d+), target \* (1\.\d+)", read(validator))
if not band:
    sys.exit(3)
put("document", "band_lower", "validate-narrative", num(band.group(1)))
put("document", "band_upper", "validate-narrative", num(band.group(2)))
elements = re.findall(r"^### (\d)\. ", read(arc_contract), re.M)
if not elements:
    sys.exit(3)
put("document", "sections", "arc-contract", len(elements))

wc = read(web_copy)
headline = {r[0]: r[1] for r in table_rows(wc, "### Headline Rules")}
put("web", "headline_chars_max", "web-copy", num(must(r"(\d+) characters", headline["Max length"])))
put("web", "hero_headline_words_max", "web-copy", num(must(r"(\d+) words max", headline["Hero headline"])))
put("web", "section_headline_words_max", "web-copy", num(must(r"(\d+) words max", headline["Section headline"])))
body = {r[0]: r[1] for r in table_rows(wc, "## Body Text Constraints")}
put("web", "hero_subline_words_max", "web-copy", num(body["Hero subline"]))
put("web", "section_body_words_max", "web-copy", num(body["Section body"]))
put("web", "bullet_words_max", "web-copy", num(must(r"(\d+) per item", body["Bullet items"])))
put("web", "quote_words_max", "web-copy", num(body["Quote text"]))
put("web", "attribution_words_max", "web-copy", num(body["Attribution"]))
lo, hi = must(r"within the (\d+)-(\d+) range", read(web_arch), 0, 1), must(r"within the (\d+)-(\d+) range", read(web_arch), 0, 2)
put("web", "sections_min", "web-arch", num(lo))
put("web", "sections_max", "web-arch", num(hi))

presets = read(info_presets)
rows = table_rows(presets, "# Content Density by Style Preset")
standard = next(r for r in rows if r[0].startswith("sketchnote"))
dense = next(r for r in rows if "economist" in r[0])
put("infographic", "blocks_max", "info-presets", num(standard[1]))
put("infographic", "words_max", "info-presets", num(standard[2]))
put("infographic", "blocks_max_dense", "info-presets", num(dense[1]))
put("infographic", "words_max_dense", "info-presets", num(dense[2]))
put("infographic", "blocks_min", "info-presets", num(must(r"fewer than\s+(\d+) content blocks", presets)))
blocks = read(info_blocks)
title = {r[0]: r[1] for r in table_rows(blocks, "### title")}
put("infographic", "headline_words_max", "info-blocks", num(title["Headline"]))
put("infographic", "subline_words_max", "info-blocks", num(title["Subline"]))
kpi = {r[0]: r[1] for r in table_rows(blocks, "### kpi-card")}
put("infographic", "hero_label_words_max", "info-blocks", num(kpi["Hero-Label"]))

print(json.dumps({"reference": ref, "upstream": up}))
PY

run_homes() {
  python3 "$TMPROOT/homes.py" "$1" "$CHECKER" "$VALIDATOR" "$ARC_CONTRACT" \
    "$WEB_COPY" "$WEB_ARCH" "$INFO_PRESETS" "$INFO_BLOCKS"
}

run_homes "$REFERENCE" > "$TMPROOT/homes.json" 2>/dev/null
rc=$?

# --- bds-01: every home readable ---------------------------------------------
if [ "$rc" -eq 0 ]; then
  pass "bds-01-all-homes-readable"
else
  fail "bds-01-all-homes-readable a density home could not be read or a reading is missing"
  exit "$failures"
fi

# --- bds-02: the reference carries the four targets, each with rows ----------
if python3 - "$TMPROOT/homes.json" <<'PY'
import json, sys
ref = json.load(open(sys.argv[1]))["reference"]
sys.exit(0 if set(ref) == {"slides", "document", "infographic", "web"} and all(ref.values()) else 1)
PY
then
  pass "bds-02-reference-has-four-targets"
else
  fail "bds-02-reference-has-four-targets the reference does not carry exactly the four targets with rows"
fi

# --- bds-03..06: per target, every reference value equals every home reading --
cat > "$TMPROOT/compare.py" <<'PY'
import json, sys
homes = json.load(open(sys.argv[1]))
target = sys.argv[2]
ref, up = homes["reference"].get(target, {}), homes["upstream"].get(target, {})
bad = []
for key, value in ref.items():
    for home, seen in up.get(key, {}).items():
        if seen != value:
            bad.append(f"{key}: reference {value} vs {home} {seen}")
for line in bad:
    print(line)
sys.exit(0 if ref and not bad else 1)
PY
n=3
for target in slides document infographic web; do
  if python3 "$TMPROOT/compare.py" "$TMPROOT/homes.json" "$target"; then
    pass "bds-0${n}-${target}-matches-homes"
  else
    fail "bds-0${n}-${target}-matches-homes a ${target} ceiling differs from its home"
  fi
  n=$((n + 1))
done

# --- bds-07: untracked keys are exactly the declared sole-home keys ----------
# A key whose only home retired with its producer has no reading to compare
# against; the reference is its sole statement. The list is pinned in both
# directions: a key with no reading must be listed here, and a listed key must
# have no reading — so re-homing a key without removing it from the list, or
# dropping a home without adding its keys, is red either way.
SOLE_HOME_KEYS="slides.slide_points_max_lines infographic.hero_numbers_min infographic.hero_numbers_max infographic.point_words_max"
if python3 - "$TMPROOT/homes.json" "$SOLE_HOME_KEYS" <<'PY'
import json, sys
homes = json.load(open(sys.argv[1]))
declared = set(sys.argv[2].split())
untracked = {f"{t}.{k}" for t, keys in homes["reference"].items() for k in keys if k not in homes["upstream"].get(t, {})}
for u in sorted(untracked - declared):
    print("untracked but not declared sole-home:", u)
for d in sorted(declared - untracked):
    print("declared sole-home but has a reading (or is absent from the reference):", d)
sys.exit(0 if untracked == declared else 1)
PY
then
  pass "bds-07-sole-home-keys-exact"
else
  fail "bds-07-sole-home-keys-exact the untracked key set and SOLE_HOME_KEYS differ"
fi

# --- bds-08: self-hosted mutant — one changed value in a COPY is detected ----
sed 's/| `slide_point_words_max` | 10 |/| `slide_point_words_max` | 99 |/' "$REFERENCE" > "$TMPROOT/dc-mutant.md"
if ! grep -q '`slide_point_words_max` | 99 |' "$TMPROOT/dc-mutant.md"; then
  fail "bds-08-mutant-drift-detected the mutant could not be built (anchor row missing)"
else
  run_homes "$TMPROOT/dc-mutant.md" > "$TMPROOT/mutant.json" 2>/dev/null
  if python3 "$TMPROOT/compare.py" "$TMPROOT/mutant.json" slides > /dev/null; then
    fail "bds-08-mutant-drift-detected a changed slides ceiling in a copy was not seen as divergence"
  else
    pass "bds-08-mutant-drift-detected"
  fi
fi

exit "$failures"
