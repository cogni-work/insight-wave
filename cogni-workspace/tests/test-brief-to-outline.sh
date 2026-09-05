#!/usr/bin/env bash
#
# test-brief-to-outline.sh — suite for
# cogni-workspace/skills/story-to-slides/scripts/brief-to-outline.py.
#
# Exports libraries/EXAMPLE_BRIEF.md twice (default and --include-internal) and
# grades the outline against the library that owns the layout-to-type mapping.
# No committed fixtures: the real brief is the corpus.
#
# The shared predicates live in ONE place — $TMPROOT/outline_probe.py, written
# below — and every case imports them. They were originally inlined per case,
# which put three copies of the "walk the slide_points block" scanner in the
# file and, worse, gave bo06 its OWN copy of the predicate it exists to falsify:
# a later edit to bo05's copy alone would have left bo06 green while proving
# teeth for a predicate no longer under test.
#
# Mutation recipe (the discriminator is bo07-slide-points-max-four):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/skills/story-to-slides/scripts/brief-to-outline.py \
#     --expr 's{MAX_SLIDE_POINTS = 4}{MAX_SLIDE_POINTS = 9}' \
#     --test 'bash cogni-workspace/tests/test-brief-to-outline.sh' \
#     --case bo07-slide-points-max-four
#
# Verdict: guard_verified. The search text occurs exactly once. Nine of the
# thirteen slides carry more than four on-slide leaves, so raising the cap to 9
# emits five-or-more slide_points lines on those sections and bo07 goes red.

set -u

# Several cases import the exporter via spec_from_file_location. Without this,
# CPython writes a __pycache__/ next to the source inside the plugin tree, which
# test-relocated-skill-hygiene.sh P2 then flags as an unresolvable
# ${CLAUDE_PLUGIN_ROOT} reference — a suite polluting the tree it grades.
export PYTHONDONTWRITEBYTECODE=1

failures=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BTO="$ROOT/cogni-workspace/skills/story-to-slides/scripts/brief-to-outline.py"
EXB="$ROOT/cogni-workspace/libraries/EXAMPLE_BRIEF.md"
LIB="$ROOT/cogni-workspace/libraries/presentation-intent.md"
PPTX="$ROOT/cogni-workspace/libraries/pptx-layouts.md"

OUT="$TMPROOT/presentation-outline.md"
INC="$TMPROOT/with-internal.md"

cat > "$TMPROOT/outline_probe.py" <<'PYEOF'
"""Shared predicates for test-brief-to-outline.sh. Defined once, imported by
every case, so a case that falsifies a predicate falsifies THE predicate."""
import os
import re

BRIEF = open(os.environ['EXB'], encoding='utf-8').read()


def slides_of(brief=None):
    """(headline, body) per `## Slide N:` block in the brief."""
    text = BRIEF if brief is None else brief
    out = []
    for block in re.split(r'^## Slide \d+: ', text, flags=re.M)[1:]:
        head, _, body = block.partition('\n')
        out.append((head.strip(), body))
    return out


def slide_point_blocks(outline):
    """Every `slide_points:` block in an outline, as lists of raw lines."""
    blocks, current = [], None
    for line in outline.splitlines():
        if line.startswith('slide_points:'):
            current = []
            blocks.append(current)
            continue
        if current is not None:
            if line.startswith('- '):
                current.append(line[2:])
            else:
                current = None
    return blocks


def offenders(outline):
    """slide_points lines that are NOT verbatim substrings of the brief.

    Citation markers are reduced to `[N]` by the exporter, so they are stripped
    again here before the comparison. Copy is frozen: a line the renderer would
    read must appear in the brief exactly.
    """
    bad = []
    for block in slide_point_blocks(outline):
        for raw in block:
            stripped = re.sub(r'\[\d+\]', '', raw).strip()
            if stripped and stripped not in BRIEF:
                bad.append(stripped)
    return bad


def section_of(outline, headline):
    """The outline text belonging to one `## <headline>` section."""
    after = outline.split('## ' + headline, 1)[1]
    return after.split('\n## ', 1)[0]


def type_of(outline, headline):
    return re.search(r'^type: (.+)$', section_of(outline, headline), re.M).group(1)
PYEOF

python3 "$BTO" --brief "$EXB" --out "$OUT" > "$TMPROOT/default.json" 2>"$TMPROOT/default.err"
python3 "$BTO" --brief "$EXB" --out "$INC" --include-internal > "$TMPROOT/inc.json" 2>"$TMPROOT/inc.err"

export TMPROOT ROOT BTO EXB LIB PPTX OUT INC PYTHONPATH="$TMPROOT"

# --- bo01
if python3 -c "
import json, os, re, sys
from outline_probe import BRIEF
data = json.load(open(os.environ['TMPROOT'] + '/default.json'))['data']
total = len(re.findall(r'^## Slide \d+:', BRIEF, re.M))
internal = len(re.findall(r'^Slide-Kind: internal-prep\s*\$', BRIEF, re.M))
sections = len(re.findall(r'^## ', open(os.environ['OUT'], encoding='utf-8').read(), re.M))
sys.exit(0 if (sections == total - internal == data['sections'] and internal > 0) else 1)"; then
  echo "ok: bo01-default-section-count-derived"
else
  echo "FAIL: bo01-default-section-count-derived section count is not slides-minus-internal-prep"
  failures=$((failures + 1))
fi

# --- bo02
if python3 -c "
import json, os, re, sys
from outline_probe import BRIEF
total = len(re.findall(r'^## Slide \d+:', BRIEF, re.M))
inc = json.load(open(os.environ['TMPROOT'] + '/inc.json'))['data']
sections = len(re.findall(r'^## ', open(os.environ['INC'], encoding='utf-8').read(), re.M))
sys.exit(0 if sections == total == inc['sections'] else 1)"; then
  echo "ok: bo02-include-internal-emits-every-slide"
else
  echo "FAIL: bo02-include-internal-emits-every-slide --include-internal did not emit every slide"
  failures=$((failures + 1))
fi

# --- bo03
if python3 -c "
import os, re, sys
from outline_probe import slides_of
default = open(os.environ['OUT'], encoding='utf-8').read()
inc = open(os.environ['INC'], encoding='utf-8').read()
titles = [h for h, body in slides_of() if re.search(r'^Slide-Kind: internal-prep\s*\$', body, re.M)]
ok = bool(titles)
ok = ok and all(('## ' + t) not in default for t in titles)
ok = ok and all(('## ' + t) in inc for t in titles)
sys.exit(0 if ok else 1)"; then
  echo "ok: bo03-internal-prep-excluded-by-default"
else
  echo "FAIL: bo03-internal-prep-excluded-by-default an internal-prep slide leaked into the default outline"
  failures=$((failures + 1))
fi

# --- bo04
if python3 -c "
import importlib.util, os, re, sys
spec = importlib.util.spec_from_file_location('_bto', os.environ['BTO'])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
tags = mod.load_type_map(os.environ['LIB'])['tags']
used = re.findall(r'^type: (.+)\$', open(os.environ['INC'], encoding='utf-8').read(), re.M)
# The library's own clause-3 vocabulary is eight tags; a wrapped clause silently
# yielding seven is the bug this length check pins.
sys.exit(0 if len(tags) == 8 and used and all(u in tags for u in used) else 1)"; then
  echo "ok: bo04-every-type-in-library-vocabulary"
else
  echo "FAIL: bo04-every-type-in-library-vocabulary a section carries a tag the library does not define"
  failures=$((failures + 1))
fi

# --- bo05
if python3 -c "
import os, sys
from outline_probe import offenders, slide_point_blocks
out = open(os.environ['INC'], encoding='utf-8').read()
blocks = slide_point_blocks(out)
sys.exit(0 if blocks and any(blocks) and not offenders(out) else 1)"; then
  echo "ok: bo05-slide-points-verbatim"
else
  echo "FAIL: bo05-slide-points-verbatim a slide_points line is not a substring of the brief"
  failures=$((failures + 1))
fi

# --- bo06
if python3 -c "
import os, sys
from outline_probe import offenders
out = open(os.environ['INC'], encoding='utf-8').read()
# Alter exactly one slide_points line; THE predicate bo05 ran must reject it.
altered, done = [], False
for line in out.splitlines():
    if not done and line.startswith('- '):
        altered.append(line + ' PARAPHRASED-BY-THE-RENDERER')
        done = True
    else:
        altered.append(line)
sys.exit(0 if done and offenders('\n'.join(altered)) else 1)"; then
  echo "ok: bo06-verbatim-check-rejects-an-altered-line"
else
  echo "FAIL: bo06-verbatim-check-rejects-an-altered-line the verbatim predicate passed an altered outline"
  failures=$((failures + 1))
fi

# --- bo07
if python3 -c "
import os, sys
from outline_probe import slide_point_blocks
blocks = slide_point_blocks(open(os.environ['INC'], encoding='utf-8').read())
sys.exit(0 if blocks and max(len(b) for b in blocks) <= 4 else 1)"; then
  echo "ok: bo07-slide-points-max-four"
else
  echo "FAIL: bo07-slide-points-max-four a section emitted more than four on-slide lines"
  failures=$((failures + 1))
fi

# --- bo08
if python3 -c "
import json, os, re, sys
figures = json.load(open(os.environ['TMPROOT'] + '/default.json'))['data']['key_figures']
marked = [f for f in figures if f.startswith('688')]
ok = len(marked) == 1 and re.search(r'^688 \(src: \[\d+\]\)\$', marked[0]) is not None
ok = ok and any(f.startswith('156%') and 'src:' not in f for f in figures)
sys.exit(0 if ok else 1)"; then
  echo "ok: bo08-key-figure-688-carries-provenance"
else
  echo "FAIL: bo08-key-figure-688-carries-provenance 688 lost its (src: [N]) marker or an uncited figure gained one"
  failures=$((failures + 1))
fi

# --- bo09
if python3 -c "
import importlib.util, os, re, sys
spec = importlib.util.spec_from_file_location('_bto', os.environ['BTO'])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
# Independent re-extraction: this case never calls the exporter's loader to
# build its expectation, and grounds the layout set in a SECOND file.
lib = open(os.environ['LIB'], encoding='utf-8').read()
section = lib.split('## Layout to type mapping', 1)[1]
rows = {}
for line in section.splitlines():
    cells = [c.strip() for c in line.strip().strip('|').split('|')] if line.strip().startswith('|') else []
    if len(cells) >= 2 and cells[0].startswith('\`'):
        rows[cells[0].strip('\`')] = [p.strip().strip('\`') for p in cells[1].split('/') if p.strip()]
pptx = open(os.environ['PPTX'], encoding='utf-8').read()
declared = re.findall(r'^## Layout \d+: (\S+)\s*\$', pptx, re.M)
loaded = mod.load_type_map(os.environ['LIB'])['layouts']
ok = len(declared) == 11 and set(declared) == set(rows) == set(loaded)
ok = ok and all(rows[name] == loaded[name] for name in rows)
sys.exit(0 if ok else 1)"; then
  echo "ok: bo09-layout-type-parity-with-library"
else
  echo "FAIL: bo09-layout-type-parity-with-library the exporter and the library disagree on the layout mapping"
  failures=$((failures + 1))
fi

# --- bo10
if python3 -c "
import os, re, sys
from outline_probe import slides_of, type_of
out = open(os.environ['INC'], encoding='utf-8').read()
refs = [(h, b) for h, b in slides_of() if re.search(r'^Slide-Kind: references\s*\$', b, re.M)]
if len(refs) != 1:
    sys.exit(1)
head, body = refs[0]
layout = re.search(r'^Layout: (\S+)\s*\$', body, re.M).group(1)
sys.exit(0 if layout == 'two-columns-equal' and type_of(out, head) == 'table' else 1)"; then
  echo "ok: bo10-references-slide-types-as-table"
else
  echo "FAIL: bo10-references-slide-types-as-table the references slide took its Layout tag instead of the references tag"
  failures=$((failures + 1))
fi

# --- bo11
if python3 -c "
import os, re, sys
from outline_probe import slides_of, type_of
out = open(os.environ['INC'], encoding='utf-8').read()
modes = {}
for head, body in slides_of():
    if not re.search(r'^Layout: four-quadrants\s*\$', body, re.M):
        continue
    stat = bool(re.search(r'^\s+Number: ', body, re.M))
    modes[stat] = type_of(out, head)
sys.exit(0 if len(modes) == 2 and modes[True] == 'metric' and modes[False] == 'roles' else 1)"; then
  echo "ok: bo11-quadrant-mode-resolution"
else
  echo "FAIL: bo11-quadrant-mode-resolution four-quadrants did not resolve stat mode to metric and text mode to roles"
  failures=$((failures + 1))
fi

# --- bo12
if python3 -c "
import os, re, sys
from outline_probe import slides_of, section_of
out = open(os.environ['INC'], encoding='utf-8').read()
# The split is structural: any '>>'-prefixed line opens a section, taken
# ordinally. Matching language-specific literals instead would emit an empty
# talk_track on every slide of this German corpus.
#
# Asserting only 'talk_track is non-empty' is NOT enough and was measured to be
# vacuous: when the prefix stops matching, split_notes falls back to putting the
# WHOLE notes block into talk_track, which is still non-empty. So this case
# pins the split itself — both sections populated, and neither carrying the
# '>>' header lines that only survive the fallback.
expected = 0
for head, body in slides_of():
    sections = re.findall(r'^\s*>>.*\$', body, re.M)
    if len(sections) < 2:
        continue
    expected += 1
    block = section_of(out, head)
    talk = re.search(r'^talk_track:\n((?:(?!^\w+:).*\n)*)', block, re.M)
    notes = re.search(r'^notes:\n((?:(?!^\w+:).*\n)*)', block, re.M)
    if not (talk and talk.group(1).strip()):
        sys.exit(1)
    if not (notes and notes.group(1).strip()):
        sys.exit(1)
    if '>>' in talk.group(1) or '>>' in notes.group(1):
        sys.exit(1)
sys.exit(0 if expected >= 1 else 1)"; then
  echo "ok: bo12-speaker-notes-sections-split-structurally"
else
  echo "FAIL: bo12-speaker-notes-sections-split-structurally a slide with speaker notes produced an empty talk_track"
  failures=$((failures + 1))
fi

# --- bo13
if python3 -c "
import json, os, subprocess, sys
bto, tmp = os.environ['BTO'], os.environ['TMPROOT']
def envelope(args):
    proc = subprocess.run([sys.executable, bto] + args, capture_output=True, text=True)
    try:
        payload = json.loads(proc.stdout)
    except ValueError:
        return None
    return payload if set(payload) == {'success', 'data', 'error'} else None
missing = envelope(['--brief', tmp + '/does-not-exist.md'])
noargs = envelope([])
ok = missing is not None and missing['success'] is False
ok = ok and noargs is not None and noargs['success'] is False
ok = ok and 'Traceback' not in (missing['error'] + noargs['error'])
# The happy path must also be silent on stderr — captured at export time above.
ok = ok and os.path.getsize(tmp + '/default.err') == 0
ok = ok and os.path.getsize(tmp + '/inc.err') == 0
sys.exit(0 if ok else 1)"; then
  echo "ok: bo13-error-paths-emit-one-envelope"
else
  echo "FAIL: bo13-error-paths-emit-one-envelope an error path printed something other than the JSON envelope"
  failures=$((failures + 1))
fi

# --- bo14
if python3 -c "
import os, sys
out = open(os.environ['OUT'], encoding='utf-8').read()
wanted = [
    'note: copy is frozen — reproduce every line verbatim',
    'note: render citations as footnotes and keep the URLs',
    'note: attach theme.md only when no organization design system is configured',
]
sys.exit(0 if all(w in out for w in wanted) else 1)"; then
  echo "ok: bo14-trailing-meta-instructions-present"
else
  echo "FAIL: bo14-trailing-meta-instructions-present a trailing note: meta-instruction is missing"
  failures=$((failures + 1))
fi

# --- bo15
if python3 -c "
import json, os, re, sys
# The outline asserts 'copy is frozen', so on-slide copy the cap could not carry
# must be REPORTED, never dropped in silence. bo05 is a substring check and an
# omission passes it trivially; this is the missing no-line-lost guard.
data = json.load(open(os.environ['TMPROOT'] + '/inc.json'))['data']
capped = [w for w in data['warnings'] if w.startswith('slide_points capped at')]
if len(capped) != 1:
    sys.exit(1)
named = set(int(n) for n in re.findall(r'slide (\d+) \(-\d+\)', capped[0]))
sys.exit(0 if named else 1)"; then
  echo "ok: bo15-capped-copy-is-reported-not-dropped"
else
  echo "FAIL: bo15-capped-copy-is-reported-not-dropped on-slide copy was dropped without a warning naming the slides"
  failures=$((failures + 1))
fi

# --- bo16
if python3 -c "
import importlib.util, os, sys
spec = importlib.util.spec_from_file_location('_bto', os.environ['BTO'])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
parser = mod.load_parser()
model = parser.parse_brief(os.environ['EXB'])
# Selection must SPREAD across a slide's on-slide fields, not exhaust the budget
# on the first one. A positional truncation of a flat leaf list loses every
# later field: on the four-quadrant stat slide it kept two quadrants and dropped
# the other two entirely.
worst = None
for slide in model['slides']:
    groups = mod._field_lines(slide)
    if len(groups) >= mod.MAX_SLIDE_POINTS and sum(len(g) for g in groups) > mod.MAX_SLIDE_POINTS:
        points = mod.slide_points(slide)
        represented = sum(1 for g in groups if any(line in points for line in g))
        if worst is None or represented < worst:
            worst = represented
sys.exit(0 if worst is not None and worst >= mod.MAX_SLIDE_POINTS else 1)"; then
  echo "ok: bo16-slide-points-spread-across-fields"
else
  echo "FAIL: bo16-slide-points-spread-across-fields the cap was spent on one field instead of spread across them"
  failures=$((failures + 1))
fi

# --- bo17
if python3 -c "
import os, re, sys
from outline_probe import slide_point_blocks, BRIEF
out = open(os.environ['INC'], encoding='utf-8').read()
# A slide whose evidence lines carry citations must land at least one of them in
# slide_points, with the marker reduced to bare [N] and the URL dropped. Sharing
# one lane between a box's Headline and its Bullets let the headline win every
# time, so no cited line ever reached the outline on a slide whose field count
# already equalled the cap.
flat = [line for block in slide_point_blocks(out) for line in block]
cited = [line for line in flat if re.search(r'\[\d+\]', line)]
reduced_from_sup = [line for line in cited if 'sup>' not in line and 'http' not in line]
ok = bool(reduced_from_sup)
# and the reduction must be lossless in the other direction: no raw marker leaks
ok = ok and not any('<sup>' in line for line in flat)
sys.exit(0 if ok else 1)"; then
  echo "ok: bo17-cited-evidence-line-reaches-slide-points"
else
  echo "FAIL: bo17-cited-evidence-line-reaches-slide-points no citation-bearing on-slide line survived the cap"
  failures=$((failures + 1))
fi

if [ "$failures" -eq 0 ]; then
  echo "All brief-to-outline tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
