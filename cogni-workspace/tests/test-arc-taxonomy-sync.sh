#!/usr/bin/env bash
# Guard: cogni-visual's arc taxonomy must stay in sync with the text-to-narrative skill's bundled arcs.
#
# WHAT THIS PINS
#   The `arc_id` set in the mapping table of cogni-workspace/libraries/arc-taxonomy.md
#   must equal the set of arc directories under
#   cogni-workspace/skills/text-to-narrative/references/ (one flat arc-{arc-id}.md per arc).
#
# WHY A TEST AND NOT MORE PROSE
#   Divergence degrades SILENTLY. An `arc_id` absent from the mapping table hits the
#   documented `**Fallback:**` in arc-taxonomy.md and falls back to auto-detection from
#   narrative content — nothing errors, nothing warns. The only symptom is a narrative
#   getting a less-appropriate visual decomposition than it asked for. The two surfaces
#   have drifted apart three separate times; each recurrence was found by a human reading
#   prose and fixed with more prose. This suite makes the seam observable instead.
#
# STRICTNESS LEVEL: (a) HARD ASSERT, BOTH DIRECTIONS — chosen deliberately.
#   The issue that requested this guard laid out three options: (a) hard assert, (b) assert
#   only the table-names-a-missing-arc direction and warn on the missing-row direction, and
#   (c) advisory reporting with no failure. (a) is chosen because the binding requirement is
#   that reintroducing a missing mapping row produce a NON-ZERO EXIT — and that omission is
#   precisely the missing-row direction, which (b) downgrades to a warning and (c) never
#   fails on at all. Neither weaker option can satisfy it.
#
#   The cost is real and accepted: this couples two plugins' CI. A cogni-workspace change
#   that adds a twelfth arc will turn *cogni-visual's* suite red until the taxonomy mirror is
#   updated — a failure attributed to a plugin the author may not have touched. That is the
#   intended trade: adding an arc without a visual mapping is an incomplete change, and a
#   loud failure in the wrong place beats a silent one in the right place.
#
# CASE LABEL SHAPE: `ok: <id>` / `FAIL: <id>` — the shape every discovered suite in this repo
#   now carries, no longer a departure from an older `OK   ` / `FAIL ` form. It is forced by
#   the machinery that has to read this output, not chosen as a matter of style. Two facts
#   carry it.
#
#   READ THIS BEFORE CHECKING THEM: neither cited file is at an insight-wave path. Both live in
#   the INSTALLED cogni-service plugin (quoted here from v0.0.383), which a reviewer scoped to an
#   insight-wave worktree cannot see — so grepping this checkout for them finds nothing and the
#   citations read as fabricated. They are not; re-verify against the installed plugin. That
#   invisibility, not the shape itself, is what turned this into a three-round dispute on #1254.
#
#     - scripts/mutation-check.sh:412-413 — the shared mutation harness classifies a case by
#       reading OUTPUT LINES rather than the exit code. Red is `^[ \t]*FAIL:[ \t]+<case>`, green
#       is `^[ \t]*(?:ok|PASS):[ \t]+<case>`. The no-colon shape matches neither, so a suite
#       wearing it returns case_not_found (mutation-check.sh:434, exit 2) and its mutation recipe
#       cannot be run at all.
#     - scripts/check-preflight.sh:792 — the handoff preflight instrument that runs that recipe is
#       registered `"advisory": False`, so a suite the harness cannot classify also cannot clear
#       the standard author-to-merger handoff. The incompatibility is blocking, not cosmetic.
#
#   NOT a supporting fact, recorded so it is not cited again: cogni-portfolio/scripts/mutation-check.sh
#   also emits a colon form, but it classifies its sub-runs by EXIT CODE (lines 62, 86, 116) and
#   never parses a verdict line, so its output is harness messaging consumed by no classifier. An
#   earlier draft of this header offered it as precedent for the shape. It is not one.
#
#   Ratified in issue #1251's `## Acceptance criteria`, which now requires the colon form outright.
#   The contract-derivation boilerplate that still pins the older shape is tracked in #1259.
#
#   The cost is one deviation from the older shape; the saving is a migration this suite would
#   otherwise need later. Do not "restore" the no-colon form without first changing the
#   classifier — doing so silently disarms the negative case below.
#
#   Two label rules are load-bearing, not style:
#     - a case id is a single token followed by a space or end-of-line, never `S2:` or `S2 -`;
#       a trailing colon reads as case_not_found to both the harness and the handoff preflight.
#     - the final summary line must NOT begin with `FAIL:`, or it would itself be parsed as a
#       case verdict. It begins with `RESULT:`.
#
# THE ARC COUNT IS NEVER PINNED. Both sets are derived at run time. Hardcoding the current
#   count would reintroduce the very stale-count failure class this guard exists to prevent.
#
# BOTH PARSES ARE SECTION-SCOPED, and that is load-bearing. An unscoped `^### ` sweep over
#   arc-taxonomy.md matches four extra headings beyond the arc sections — including an Example
#   heading that embeds an arc id in backticks, which would fabricate a phantom duplicate and
#   turn the duplicate check red on a clean file. Likewise the mapping-table parse is bounded to
#   its own section so the Example table's `|`-leading rows are not read as arc rows.
#
# THE NEGATIVE CASE IS SELF-HOSTED (M1), not merely recorded in prose. A guard that only ever
#   sees a healthy tree is indistinguishable from a guard that cannot fail, and a mutation
#   recipe written into a pull-request description is not replayable by anyone reading the repo
#   later. M1 therefore copies the taxonomy into this run's own mktemp -d, deletes one mapping
#   row FROM THE COPY, re-invokes this same file against the mutant, and asserts the child both
#   exits non-zero and reports S2 red by name. It runs on every CI sweep, and the tracked
#   arc-taxonomy.md is never written to — a negative case that edits its own repository is a
#   dirty-tree hazard, not a test.
#
# stdlib-only: bash + coreutils + python3. No network, no credentials, no pip dependencies.
# Writes only under its own mktemp -d. Self-locates from $0, so it is cwd-independent — the
# mutation harness runs it with cwd set to the tree under test, not to this directory.

set -u

# One collation authority for every ordered comparison in this file. `comm` requires both inputs
# ordered the same way and reports a WRONG difference set — silently, exit 0 — when they are not.
# Its inputs come from two different sorters: python's byte-wise sorted() and coreutils sort,
# whose order is locale-dependent. Under a UTF-8 locale, sort demotes punctuation to a secondary
# level, so a future arc-id pair like `smart-service` / `smartservice` would order differently in
# the two files and the comparison would quietly return nonsense. Pinning C makes both agree.
export LC_ALL=C

HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$HERE/.." && pwd)"

# Both inputs default to the real tracked paths and are overridable only so M1 can aim this
# same file at a mutant under $TMPROOT. The override exists for the negative case, not as a
# configuration surface — a normal run, and every CI run, resolves both defaults.
TAXONOMY="${ARC_TAXONOMY_PATH:-$PLUGIN_DIR/libraries/arc-taxonomy.md}"
ARC_DIR="${ARC_STORY_ARC_DIR:-$PLUGIN_DIR/skills/text-to-narrative/references}"

# The five valid visual arc types. arc-taxonomy.md does not declare this set itself — it is
# stated by the consuming surfaces (cogni-workspace/libraries/brief-core.md, render-html-slides
# and the render agents that read brief frontmatter), which document `arc_type` as
# one of these values. Mirrored here because there is no machine-readable source to read.
VALID_ARC_TYPES="why-change problem-solution journey argument report"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf '%s\n' "ok: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

# THE CASE REGISTRY — the one declaration every other case list in this file derives from.
# A guard whose whole purpose is pinning one list against another has no business carrying an
# un-pinned list of its own, so this one is verified rather than merely maintained: M1 compares
# it against the ids a complete run actually emits, in both directions. A case added without
# registering it here, or an id left here after its case was deleted, turns M1 red.
ALL_CASES="V1 V2 V3 V4 S1 S2 T1 E1 D1 H1 M1 M2"

# Every case downstream of the non-vacuity guards — derived from the registry, never re-typed.
# Cases that cannot be evaluated must still emit their own id: a case id simply absent from the
# output is indistinguishable, to the harness, from a typo'd --case, so an unevaluated case is
# reported as a failure under its own name rather than skipped silently.
DOWNSTREAM_CASES=""
for case_id in $ALL_CASES; do
  case "$case_id" in
    V*) ;;
    *) DOWNSTREAM_CASES="$DOWNSTREAM_CASES $case_id" ;;
  esac
done
DOWNSTREAM_CASES="${DOWNSTREAM_CASES# }"

# Deliberately not prefixed `FAIL:` — that shape is reserved for per-case verdicts, and a
# summary wearing it would be misread as a case named by its first token.
finish() {
  echo ""
  if [ "$failures" -gt 0 ]; then
    echo "RESULT: $failures arc-taxonomy sync case(s) failed."
    exit 1
  fi
  echo "RESULT: all arc-taxonomy sync cases passed."
  exit 0
}

# Abandon the run when an input is missing or unparseable, reporting every downstream case
# under its own id first.
bail_out() {
  for case_id in $DOWNSTREAM_CASES; do
    fail "$case_id not evaluated — non-vacuity guard failed"
  done
  finish
}

# ---------------------------------------------------------------- non-vacuity guards (V1-V4)
# Without these, a renamed or moved input path yields two empty sets, which compare equal, and
# the suite reports green forever. An empty-vs-empty pass is the same silent degradation this
# guard was written to catch, one level up.

vacuous=0

if [ -f "$TAXONOMY" ]; then
  pass "V1 arc-taxonomy.md is present at $TAXONOMY"
else
  fail "V1 arc-taxonomy.md not found at $TAXONOMY"
  vacuous=1
fi

if [ -d "$ARC_DIR" ]; then
  pass "V2 arc-contract set is present at $ARC_DIR"
else
  fail "V2 arc-contract set not found at $ARC_DIR"
  vacuous=1
fi

if [ "$vacuous" -ne 0 ]; then
  bail_out
fi

# Extract both machine-readable views of the taxonomy in one pass. Emits, into $TMPROOT:
#   rows.tsv        arc_id<TAB>arc_type, one per mapping-table data row, document order
#   map_ids_all.txt every mapping-table arc_id, sorted, duplicates retained (feeds D1)
#   map_ids.txt     the same set, sorted and deduplicated (feeds the set comparisons)
#   sections.txt    every `### <name>` heading inside the Arc Element Names section, sorted
if ! python3 - "$TAXONOMY" "$TMPROOT" <<'PY'
import os
import sys

taxonomy_path, outdir = sys.argv[1], sys.argv[2]

with open(taxonomy_path, encoding="utf-8") as handle:
    lines = handle.read().splitlines()

MAPPING_HEADING = "## Arc ID to Visual Arc Type Mapping"
ELEMENTS_HEADING = "## Arc Element Names"


def section_body(heading):
    """Lines between `heading` and the next H2. Bounding the scan is the whole point:
    an unscoped sweep picks up unrelated tables and headings elsewhere in the file."""
    start = None
    for index, line in enumerate(lines):
        if line.strip() == heading:
            start = index + 1
            break
    if start is None:
        return []
    body = []
    for line in lines[start:]:
        if line.startswith("## "):  # H3 (`### `) does not match, so arc sections survive
            break
        body.append(line)
    return body


rows = []
for line in section_body(MAPPING_HEADING):
    stripped = line.strip()
    if not stripped.startswith("|"):
        continue
    cells = [cell.replace("`", "").strip() for cell in stripped.strip("|").split("|")]
    if len(cells) < 2:
        continue
    # The `|---|---|` separator row: every cell is made only of dashes and colons.
    if all(cell and set(cell) <= set("-:") for cell in cells):
        continue
    arc_id, arc_type = cells[0], cells[1]
    if not arc_id:
        continue
    # The header row names the column rather than an arc.
    if "arc_id" in arc_id:
        continue
    rows.append((arc_id, arc_type))

sections = [
    line[4:].replace("`", "").strip()
    for line in section_body(ELEMENTS_HEADING)
    if line.startswith("### ")
]


def write(name, values):
    with open(os.path.join(outdir, name), "w", encoding="utf-8") as handle:
        for value in values:
            handle.write(value + "\n")


write("rows.tsv", ["%s\t%s" % row for row in rows])
write("map_ids_all.txt", sorted(arc_id for arc_id, _ in rows))
write("map_ids.txt", sorted({arc_id for arc_id, _ in rows}))
write("sections.txt", sorted(sections))
PY
then
  fail "V3 could not parse the mapping table out of arc-taxonomy.md"
  bail_out
fi

# `sort` here agrees with python's byte-wise sorted() above because LC_ALL=C is exported at the
# top of this file. See that comment — the agreement is what makes every `comm` below sound.
ls "$ARC_DIR"/arc-*.md | xargs -n1 basename | sed 's/^arc-//; s/\.md$//' | grep -vx registry | sort > "$TMPROOT/dir_ids.txt"

map_count=$(wc -l < "$TMPROOT/map_ids.txt" | tr -d ' ')
dir_count=$(wc -l < "$TMPROOT/dir_ids.txt" | tr -d ' ')

if [ "$map_count" -gt 0 ]; then
  pass "V3 mapping table yielded $map_count arc_id(s)"
else
  fail "V3 mapping table yielded no arc_id rows — the section heading or table shape changed"
  vacuous=1
fi

if [ "$dir_count" -gt 0 ]; then
  pass "V4 arc-contract set yielded $dir_count arc directory/ies"
else
  fail "V4 arc-contract set contains no arc directories"
  vacuous=1
fi

if [ "$vacuous" -ne 0 ]; then
  bail_out
fi

# ------------------------------------------------------------- set equality, both directions

orphan_rows=$(comm -23 "$TMPROOT/map_ids.txt" "$TMPROOT/dir_ids.txt" | tr '\n' ' ' | sed 's/ *$//')
if [ -z "$orphan_rows" ]; then
  pass "S1 every mapping-table arc_id has a arc-contract set"
else
  fail "S1 mapping-table arc_id(s) with no arc-contract set: $orphan_rows"
fi

# S2 is the direction a dropped mapping row turns red: the arc directory still exists, but
# nothing maps it, so it silently falls through to auto-detection.
unmapped_dirs=$(comm -13 "$TMPROOT/map_ids.txt" "$TMPROOT/dir_ids.txt" | tr '\n' ' ' | sed 's/ *$//')
if [ -z "$unmapped_dirs" ]; then
  pass "S2 every arc-contract set has a mapping-table row"
else
  fail "S2 arc-contract set/ies with no mapping-table row: $unmapped_dirs"
fi

# ------------------------------------------------------------------------ arc_type validity

bad_types=""
while IFS="$(printf '\t')" read -r arc_id arc_type; do
  [ -n "$arc_id" ] || continue
  valid=0
  for candidate in $VALID_ARC_TYPES; do
    if [ "$arc_type" = "$candidate" ]; then
      valid=1
      break
    fi
  done
  if [ "$valid" -eq 0 ]; then
    bad_types="$bad_types $arc_id=$arc_type"
  fi
done < "$TMPROOT/rows.tsv"
bad_types="${bad_types# }"

if [ -z "$bad_types" ]; then
  pass "T1 every mapping-table arc_type is one of: $VALID_ARC_TYPES"
else
  fail "T1 invalid arc_type value(s): $bad_types (valid: $VALID_ARC_TYPES)"
fi

# ------------------------------------------------------- element-section coverage, duplicates
# The half-wired case: arc_type resolves from the mapping table, but the element labels have no
# section to read, so they fall back to generic names. Green mapping, degraded output.

missing_sections=$(comm -23 "$TMPROOT/map_ids.txt" "$TMPROOT/sections.txt" | tr '\n' ' ' | sed 's/ *$//')
if [ -z "$missing_sections" ]; then
  pass "E1 every mapping-table arc_id has a section under Arc Element Names"
else
  fail "E1 mapping-table arc_id(s) with no element section: $missing_sections"
fi

duplicate_ids=$(uniq -d < "$TMPROOT/map_ids_all.txt" | tr '\n' ' ' | sed 's/ *$//')
if [ -z "$duplicate_ids" ]; then
  pass "D1 no arc_id appears more than once in the mapping table"
else
  fail "D1 duplicate mapping-table arc_id(s): $duplicate_ids"
fi

# ------------------------------------------------------- short names derive from the contract (H1)
# The settled heading rule: the arc contract's full heading ("Warum Wandel: Unerkannte
# Handlungsbedarfe") is the authority, and the taxonomy's short element name is DERIVED from it —
# the segment before the first colon, or the whole cell when there is none. H1 checks that
# derivation for every arc whose contract carries `contract: 2`, enumerated at run time from the
# contracts themselves, never listed. An unmigrated arc has no `## Headings` table and is skipped;
# once every arc is migrated, H1 covers the whole set with no edit here.

h1_report=$(python3 - "$TAXONOMY" "$ARC_DIR" "$TMPROOT" <<'PY'
import os, re, sys

taxonomy_path, arc_dir, outdir = sys.argv[1], sys.argv[2], sys.argv[3]
lines = open(taxonomy_path, encoding="utf-8").read().splitlines()


def taxonomy_block(arc):
    start = None
    for i, line in enumerate(lines):
        if line.strip() == "### " + arc:
            start = i + 1
            break
    if start is None:
        return None
    rows = []
    for line in lines[start:]:
        if line.startswith("## ") or line.startswith("### "):
            break
        s = line.strip()
        if not s.startswith("|"):
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if len(cells) < 3 or not cells[0].isdigit():
            continue
        rows.append((cells[1], cells[2]))
    return rows


def contract_headings(path):
    text = open(path, encoding="utf-8").read()
    fm = text.split("---")
    if len(fm) < 3 or not re.search(r"^contract: *2 *$", fm[1], flags=re.M):
        return None
    m = re.search(r"^## Headings\n(.*?)(?=^## )", text, flags=re.S | re.M)
    if not m:
        return []
    rows = [l for l in m.group(1).splitlines() if l.strip().startswith("|")]
    header = [c.strip() for c in rows[0].strip().strip("|").split("|")]
    en, de = header.index("EN"), header.index("DE")
    out = []
    for r in rows[2:]:
        cells = [c.strip() for c in r.strip().strip("|").split("|")]
        out.append((cells[en], cells[de]))
    return out


def short(cell):
    return cell.split(":", 1)[0].strip() if ":" in cell else cell.strip()


checked, bad = 0, []
for name in sorted(os.listdir(arc_dir)):
    if not (name.startswith("arc-") and name.endswith(".md")) or name == "arc-registry.md":
        continue
    arc = name[len("arc-"):-len(".md")]
    path = os.path.join(arc_dir, name)
    if not os.path.isfile(path):
        continue
    contract = contract_headings(path)
    if contract is None:
        continue
    block = taxonomy_block(arc)
    if not contract or block is None or len(block) != len(contract):
        bad.append("%s(shape)" % arc)
        continue
    checked += 1
    for n, ((c_en, c_de), (t_en, t_de)) in enumerate(zip(contract, block), start=1):
        if short(c_en) != t_en or short(c_de) != t_de:
            bad.append("%s#%d(%s/%s vs %s/%s)" % (arc, n, t_en, t_de, short(c_en), short(c_de)))
print("%d %s" % (checked, " ".join(bad)))
PY
)
h1_rc=$?
h1_checked="${h1_report%% *}"
h1_bad="${h1_report#* }"
[ "$h1_bad" = "$h1_report" ] && h1_bad=""
# A helper that crashes prints nothing, so the count is empty — reject anything that is not a
# plain number before comparing it, or the fail branch is skipped and control falls to pass.
case "$h1_checked" in ''|*[!0-9]*) h1_checked="" ;; esac
if [ "$h1_rc" -ne 0 ] || [ -z "$h1_checked" ]; then
  fail "H1 derivation helper failed (exit $h1_rc) — no comparison was made"
elif [ "$h1_checked" -eq 0 ]; then
  fail "H1 no contract carrying contract: 2 was found — the derivation check ran over nothing"
elif [ -n "$h1_bad" ]; then
  fail "H1 taxonomy short name(s) do not equal the contract heading's pre-colon segment: $h1_bad"
else
  pass "H1 taxonomy EN/DE short names equal the contract headings' pre-colon segments ($h1_checked migrated arc(s))"
fi

# ------------------------------------------------------------------ executed negative case (M1)
# Proves this guard can actually go red, in-repo and on every sweep, without ever writing to the
# tracked taxonomy. Deletes one mapping row from a COPY, runs this same file against the mutant,
# and requires the child to report S2 red by name. Asserting on the child's exit code alone would
# be too weak: a non-zero exit cannot distinguish S2 going red from any other case going red.

if [ "${ARC_TAXONOMY_SYNC_MUTANT:-0}" = "1" ]; then
  # This run IS the mutant child. Recursing here would not terminate.
  finish
fi

# The victim row. `smarter-service` is the omission this guard was written for, so it is
# preferred when present — but it is looked up in the parsed set rather than assumed, and any
# arc_id serves equally, so removing or renaming that arc cannot stale this case out.
victim=$(grep -x 'smarter-service' "$TMPROOT/map_ids.txt" || head -n 1 "$TMPROOT/map_ids.txt")

if [ -z "$victim" ]; then
  fail "M1 no arc_id available to mutate — the mapping table parsed empty"
  finish
fi

# Section-scoped deletion, for the same reason the main parse is section-scoped: the arc's own
# element table further down the file also has rows, and an unscoped match would cut one of those
# instead. Exits non-zero unless at least one row was removed, so a silently-ineffective mutation
# is never mistaken for a passing negative case. The condition is "the victim is now unmapped",
# not "exactly one line was cut": on a file that already carries a duplicate row — the state D1
# exists to catch — cutting only one would leave the arc still mapped, S2 still green, and M1
# would then wrongly report the guard vacuous. Removing every matching row keeps M1 diagnosing
# its own property rather than going red in sympathy with D1.
if python3 - "$TAXONOMY" "$TMPROOT/mutant.md" "$victim" <<'PY'
import sys

source_path, mutant_path, victim = sys.argv[1], sys.argv[2], sys.argv[3]

with open(source_path, encoding="utf-8") as handle:
    lines = handle.read().splitlines(keepends=True)

MAPPING_HEADING = "## Arc ID to Visual Arc Type Mapping"

kept, removed, in_section = [], 0, False
for line in lines:
    stripped = line.strip()
    if stripped == MAPPING_HEADING:
        in_section = True
    elif in_section and stripped.startswith("## "):
        in_section = False
    if in_section and stripped.startswith("|"):
        first_cell = stripped.strip("|").split("|")[0].replace("`", "").strip()
        if first_cell == victim:
            removed += 1
            continue
    kept.append(line)

with open(mutant_path, "w", encoding="utf-8") as handle:
    handle.writelines(kept)

sys.exit(0 if removed >= 1 else 1)
PY
then
  mutant_out=$(ARC_TAXONOMY_SYNC_MUTANT=1 ARC_TAXONOMY_PATH="$TMPROOT/mutant.md" \
    bash "$HERE/$(basename "$0")" 2>&1)
  mutant_rc=$?

  # The S2 verdict line the child emitted, if any. Matching the case id and the victim name
  # separately keeps the assertion readable and avoids anchoring inside a wildcard.
  mutant_s2=$(printf '%s\n' "$mutant_out" | grep '^FAIL: S2 ' || true)

  # Registry pin, riding on the run M1 already performed. $mutant_out is a COMPLETE run of every
  # case except M1 itself — the recursion guard above sits between them, so a child never reaches
  # M1, and that is the one legitimate absence. Every other id in ALL_CASES must appear, and no
  # id may appear that is not in ALL_CASES. Both directions matter: an unregistered case vanishes
  # from bail_out's output, and a registered id whose case was deleted leaves bail_out promising a
  # verdict nothing produces. Same comm idiom as S1/S2, on the same single collation authority.
  # grep -E + awk rather than a sed alternation: BSD sed has no `\|`, so a `\(ok\|FAIL\)` pattern
  # matches nothing on macOS while working on GNU — the silent-empty failure mode this whole file
  # exists to reject. The verdict line's second field IS the case id, by the label rules above.
  printf '%s\n' "$mutant_out" \
    | grep -E '^(ok|FAIL): ' \
    | awk '{print $2}' \
    | sort -u > "$TMPROOT/emitted_cases.txt"
  # M1 and M2 both sit behind the recursion guard, so a child run emits neither.
  for case_id in $ALL_CASES; do
    case "$case_id" in M1|M2) ;; *) echo "$case_id" ;; esac
  done | sort -u > "$TMPROOT/expected_cases.txt"

  unregistered=$(comm -13 "$TMPROOT/expected_cases.txt" "$TMPROOT/emitted_cases.txt" | tr '\n' ' ' | sed 's/ *$//')
  unemitted=$(comm -23 "$TMPROOT/expected_cases.txt" "$TMPROOT/emitted_cases.txt" | tr '\n' ' ' | sed 's/ *$//')

  if [ "$mutant_rc" -eq 0 ]; then
    fail "M1 dropping the '$victim' mapping row left the suite GREEN — the guard is vacuous"
  elif [ -n "$unregistered" ]; then
    fail "M1 case(s) emitted by a full run but missing from ALL_CASES: $unregistered — register them or bail_out will never report them"
  elif [ -n "$unemitted" ]; then
    fail "M1 case id(s) in ALL_CASES that a full run never emitted: $unemitted — the case was removed or renamed"
  elif [ -n "$mutant_s2" ] && printf '%s\n' "$mutant_s2" | grep -qE "(^| )$victim( |$)"; then
    pass "M1 dropping the '$victim' mapping row turns S2 red (child exit $mutant_rc); case registry matches the full run"
  else
    fail "M1 mutant run exited $mutant_rc, but not via S2 naming '$victim' — got: $(printf '%s' "$mutant_out" | grep '^FAIL:' | tr '\n' ';')"
  fi
else
  fail "M1 could not remove any '$victim' mapping row from the copy"
fi

# ------------------------------------------------------------------ executed negative case (M2)
# H1's own negative case. Copies the taxonomy, rewrites one DE short name inside the element block
# of a runtime-selected migrated arc to a value that cannot equal any pre-colon segment, re-invokes
# this file against the mutant, and requires H1 red by name. Same recursion guard as M1.
h1_victim=$(for f in "$ARC_DIR"/arc-*.md; do
  a=$(basename "$f" .md); a="${a#arc-}"
  [ "$a" = "registry" ] && continue
  [ -f "$f" ] || continue
  awk 'NR==1 && $0!="---" {exit 1} NR>1 && $0=="---" {exit 0} /^contract: *2 *$/ {found=1} END {exit found?0:1}' "$f" && { echo "$a"; break; }
done)
if [ -z "$h1_victim" ]; then
  fail "M2 no migrated arc available to mutate for H1"
elif python3 - "$TAXONOMY" "$TMPROOT/mutant-h1.md" "$h1_victim" <<'PY'
import sys
source_path, mutant_path, victim = sys.argv[1], sys.argv[2], sys.argv[3]
lines = open(source_path, encoding="utf-8").read().splitlines(keepends=True)
out, in_block, done = [], False, False
for line in lines:
    s = line.strip()
    if s == "### " + victim:
        in_block = True
    elif in_block and (s.startswith("## ") or s.startswith("### ")):
        in_block = False
    if in_block and not done and s.startswith("| 1 |"):
        cells = s.strip("|").split("|")
        cells[2] = " MUTANT-SHORT-NAME "
        line = "|" + "|".join(cells) + "|\n"
        done = True
    out.append(line)
open(mutant_path, "w", encoding="utf-8").writelines(out)
sys.exit(0 if done else 1)
PY
then
  m2_out=$(ARC_TAXONOMY_SYNC_MUTANT=1 ARC_TAXONOMY_PATH="$TMPROOT/mutant-h1.md" bash "$HERE/$(basename "$0")" 2>&1)
  m2_rc=$?
  if [ "$m2_rc" -ne 0 ] && printf '%s\n' "$m2_out" | grep '^FAIL: H1 ' | grep -q "$h1_victim"; then
    pass "M2 rewriting a '$h1_victim' DE short name turns H1 red naming it (child exit $m2_rc)"
  else
    fail "M2 mutant exited $m2_rc but H1 did not go red naming '$h1_victim' — got: $(printf '%s' "$m2_out" | grep '^FAIL:' | tr '\n' ';')"
  fi
else
  fail "M2 could not rewrite a short name inside the '$h1_victim' element block"
fi

# ------------------------------------------------------------------------------------ summary

finish
