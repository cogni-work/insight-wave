#!/usr/bin/env bash
#
# test-brief-layout-sync.sh — the closed slide-layout set is identical across its
# four homes.
#
# The eleven layout names live in four places with nothing else binding them:
#   1. the `## Layout N: <name>` headings in libraries/pptx-layouts.md
#   2. the LAYOUT_RENDERERS keys in skills/render-html-slides/scripts/
#      generate-html-slides.py, minus `references` (a Slide-Kind, not a layout)
#   3. the `### Closed layout set` bullets in
#      libraries/presentation-brief-validation.md
#   4. the LAYOUT_ENUM tuple in scripts/check-brief.py
# A layout added to one is invisible to the others until this suite goes red.
#
# Each home's path can be overridden through an environment variable so a
# mutant copy can be graded without editing the tree:
#   BRIEF_SYNC_PPTX_LAYOUTS  BRIEF_SYNC_HTML_RENDERER  BRIEF_SYNC_CHECKLIST
#   BRIEF_SYNC_CHECKER
#
# Mutation recipe (the discriminator is bls03-all-homes-identical):
#
#   cp cogni-workspace/libraries/pptx-layouts.md "$T/pptx-layouts.md"
#   printf '\n## Layout 12: bogus-layout\n' >> "$T/pptx-layouts.md"
#   BRIEF_SYNC_PPTX_LAYOUTS="$T/pptx-layouts.md" bash cogni-workspace/tests/test-brief-layout-sync.sh
#
# must print `FAIL: bls03-all-homes-identical`. bls05 runs that very mutant
# inside this suite, so a green run already proves the override path is live.

set -u
export PYTHONDONTWRITEBYTECODE=1

failures=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WS="$ROOT/cogni-workspace"
PPTX="${BRIEF_SYNC_PPTX_LAYOUTS:-$WS/libraries/pptx-layouts.md}"
HTML="${BRIEF_SYNC_HTML_RENDERER:-$WS/skills/render-html-slides/scripts/generate-html-slides.py}"
CHECKLIST="${BRIEF_SYNC_CHECKLIST:-$WS/libraries/presentation-brief-validation.md}"
CHECKER="${BRIEF_SYNC_CHECKER:-$WS/scripts/check-brief.py}"

pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

cat > "$TMPROOT/homes.py" <<'PY'
"""Print the four layout sets as JSON; exit 3 when a home cannot be read."""
import importlib.util, json, re, sys

pptx, html, checklist, checker = sys.argv[1:5]

def read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()

homes = {}
homes["pptx-layouts"] = re.findall(r"^## Layout \d+: (\S+)\s*$", read(pptx), re.M)

m = re.search(r"^LAYOUT_RENDERERS = \{(.*?)^\}", read(html), re.M | re.S)
if not m:
    sys.exit(3)
homes["html-renderer"] = [k for k in re.findall(r'^\s*"([a-z-]+)":', m.group(1), re.M) if k != "references"]

text = read(checklist)
start = text.find("### Closed layout set")
if start < 0:
    sys.exit(3)
block = text[start:]
nxt = re.search(r"^#{1,3} ", block[len("### Closed layout set"):], re.M)
if nxt:
    block = block[:len("### Closed layout set") + nxt.start()]
homes["checklist"] = re.findall(r"^- `([a-z-]+)`\s*$", block, re.M)

spec = importlib.util.spec_from_file_location("_cb", checker)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
homes["checker"] = list(mod.LAYOUT_ENUM)

print(json.dumps(homes))
PY

python3 "$TMPROOT/homes.py" "$PPTX" "$HTML" "$CHECKLIST" "$CHECKER" > "$TMPROOT/homes.json" 2>/dev/null
rc=$?

# --- bls01: every home readable ---------------------------------------------
if [ "$rc" -eq 0 ]; then
  pass "bls01-all-homes-readable"
else
  fail "bls01-all-homes-readable a layout home could not be read or parsed"
  exit "$failures"
fi

# --- bls02: each home carries eleven names, none repeated --------------------
if python3 - "$TMPROOT/homes.json" <<'PY'
import json, sys
homes = json.load(open(sys.argv[1]))
ok = all(len(v) == 11 and len(set(v)) == 11 for v in homes.values())
if not ok:
    for k, v in homes.items():
        print(k, len(v), file=sys.stderr)
sys.exit(0 if ok else 1)
PY
then
  pass "bls02-each-home-has-eleven-layouts"
else
  fail "bls02-each-home-has-eleven-layouts a home does not carry exactly eleven distinct layouts"
fi

# --- bls03: the four sets are identical --------------------------------------
if python3 - "$TMPROOT/homes.json" <<'PY'
import json, sys
homes = json.load(open(sys.argv[1]))
sets = {k: set(v) for k, v in homes.items()}
ref = sets["pptx-layouts"]
diverged = {k: sorted(v ^ ref) for k, v in sets.items() if v != ref}
for k, d in diverged.items():
    print(k, "differs from pptx-layouts by", d)
sys.exit(0 if not diverged else 1)
PY
then
  pass "bls03-all-homes-identical"
else
  fail "bls03-all-homes-identical the layout set differs between homes"
fi

# --- bls04: the pptx-layouts order is the checker's order --------------------
if python3 - "$TMPROOT/homes.json" <<'PY'
import json, sys
homes = json.load(open(sys.argv[1]))
sys.exit(0 if homes["pptx-layouts"] == homes["checker"] else 1)
PY
then
  pass "bls04-checker-order-matches-library"
else
  fail "bls04-checker-order-matches-library LAYOUT_ENUM is not in the library's Layout N order"
fi

# --- bls05: self-hosted mutant — a twelfth heading in a COPY turns bls03 red --
cp "$PPTX" "$TMPROOT/pptx-mutant.md"
printf '\n## Layout 12: bogus-layout\n' >> "$TMPROOT/pptx-mutant.md"
python3 "$TMPROOT/homes.py" "$TMPROOT/pptx-mutant.md" "$HTML" "$CHECKLIST" "$CHECKER" > "$TMPROOT/mutant.json" 2>/dev/null
if python3 - "$TMPROOT/mutant.json" <<'PY'
import json, sys
homes = json.load(open(sys.argv[1]))
sys.exit(0 if set(homes["pptx-layouts"]) != set(homes["checker"]) else 1)
PY
then
  pass "bls05-mutant-twelfth-layout-detected"
else
  fail "bls05-mutant-twelfth-layout-detected a bogus twelfth heading in a copy was not seen as divergence"
fi

exit "$failures"
