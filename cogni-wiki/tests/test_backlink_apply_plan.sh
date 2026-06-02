#!/usr/bin/env bash
# test_backlink_apply_plan.sh — exercise backlink_audit.py apply-mode, focusing
# on the v0.0.53 (#414) `--create-missing-heading` flag.
#
# Finding (5) of #414: knowledge-ingest Step 4.5.2 documents that the reverse
# `source→question` link lands under a `## Research questions` heading "so it
# lands in its own section", but `_insert_sentence` only ever bare-appended at
# end-of-body when the heading was absent (which a freshly-ingested source page
# always is) — so the heading never materialised. The opt-in
# `--create-missing-heading` flag fixes this WITHOUT changing the default
# (wiki-ingest) behaviour, where the EOF-append is the intended safety net.
#
# Cases:
#   1. --create-missing-heading + heading absent  → heading created, link under it
#   2. second question into the now-existing heading → grouped, NO duplicate heading
#   3. NO flag + heading absent                   → bare EOF append, NO heading (wiki-ingest guard)
#   4. heading already present                    → insert after it, one heading (flag-agnostic)
#   5. idempotency: re-apply same plan            → skipped_existing_backlink, file byte-unchanged
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
BACKLINK="$PLUGIN_ROOT/skills/wiki-ingest/scripts/backlink_audit.py"
MIGRATE="$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { red "FAIL: $1"; exit 1; }

# Count occurrences of an exact line ($1) in a file ($2).
count_line() {
  local needle="$1" file="$2"
  grep -cxF "$needle" "$file" 2>/dev/null || true
}

# Run backlink_audit apply-mode with a plan on stdin; echo the data.* field
# named by $4 ("applied" | "skipped_existing_backlink" | "failed") as a
# newline-joined slug list.
apply_field() {
  local new_page="$1" plan="$2" flag="$3" field="$4" out
  # shellcheck disable=SC2086
  out=$(printf '%s' "$plan" | python3 "$BACKLINK" \
          --wiki-root "$WIKI" --new-page "$new_page" --apply-plan - $flag)
  printf '%s' "$out" | FIELD="$field" python3 -c '
import json, os, sys
d = json.loads(sys.stdin.read())
assert d.get("success") is True, d
field = os.environ["FIELD"]
vals = d["data"].get(field, [])
# applied/failed are lists of dicts {slug,...}; skipped is a list of slugs.
out = []
for v in vals:
    out.append(v["slug"] if isinstance(v, dict) else v)
print("\n".join(out))
'
}

# ---------- bootstrap a migrated 0.0.5 fixture wiki ----------
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$MIGRATE" --wiki-root "$WIKI" --apply >/dev/null
green "fixture migrated to per-type-dirs layout (0.0.5)"

TODAY=$(date +%Y-%m-%d)
mkdir -p "$WIKI/wiki/questions" "$WIKI/wiki/sources"

plant_question() {
  local slug="$1" title="$2"
  cat > "$WIKI/wiki/questions/$slug.md" <<EOF
---
id: $slug
title: $title
type: question
created: $TODAY
updated: $TODAY
---

## Findings

- [[src-one]]
EOF
}

plant_source() {
  local slug="$1" with_heading="$2"
  cat > "$WIKI/wiki/sources/$slug.md" <<EOF
---
id: $slug
title: Source $slug
type: source
created: $TODAY
updated: $TODAY
sources: [https://example.com/$slug]
---

This is the body of source $slug, long enough to clear any stub threshold and
provide a plausible page for the backlink audit to scan over.
EOF
  if [ "$with_heading" = "yes" ]; then
    printf '\n## Research questions\n' >> "$WIKI/wiki/sources/$slug.md"
  fi
}

plant_question q-data "Data governance"
plant_question q-risk "Risk classification"
plant_source src-one no
plant_source src-two no
plant_source src-three yes
green "planted 2 question nodes + 3 source pages"

HEADING="## Research questions"

# ============================================================
# Case 1: --create-missing-heading + heading absent → created
# ============================================================
PLAN1='{"targets": [{"slug": "src-one", "sentence": "Answers research question [[q-data]].", "insert_after_heading": "## Research questions"}]}'
applied=$(apply_field q-data "$PLAN1" "--create-missing-heading" applied)
[ "$applied" = "src-one" ] || fail "case1: expected src-one applied, got '$applied'"
SRC1="$WIKI/wiki/sources/src-one.md"
[ "$(count_line "$HEADING" "$SRC1")" = "1" ] || fail "case1: expected exactly one '$HEADING' in src-one"
grep -qF "[[q-data]]" "$SRC1" || fail "case1: [[q-data]] link missing from src-one"
# The link must sit AFTER the heading (under the section), not before it.
python3 - "$SRC1" <<'PY' || fail "case1: [[q-data]] not located under the heading"
import sys
text = open(sys.argv[1]).read()
h = text.index("## Research questions")
l = text.index("[[q-data]]")
sys.exit(0 if l > h else 1)
PY
green "case1: --create-missing-heading materialised '## Research questions' with link under it"

# ============================================================
# Case 2: second question groups under the now-existing heading
# ============================================================
PLAN2='{"targets": [{"slug": "src-one", "sentence": "Answers research question [[q-risk]].", "insert_after_heading": "## Research questions"}]}'
applied=$(apply_field q-risk "$PLAN2" "--create-missing-heading" applied)
[ "$applied" = "src-one" ] || fail "case2: expected src-one applied, got '$applied'"
[ "$(count_line "$HEADING" "$SRC1")" = "1" ] || fail "case2: heading duplicated — expected exactly one '$HEADING'"
grep -qF "[[q-data]]" "$SRC1" || fail "case2: original [[q-data]] link lost"
grep -qF "[[q-risk]]" "$SRC1" || fail "case2: new [[q-risk]] link missing"
green "case2: second question grouped under the single existing heading (no duplicate)"

# ============================================================
# Case 3: NO flag + heading absent → bare EOF append, NO heading
# (regression guard for wiki-ingest's default behaviour)
# ============================================================
PLAN3='{"targets": [{"slug": "src-two", "sentence": "Answers research question [[q-data]].", "insert_after_heading": "## Research questions"}]}'
applied=$(apply_field q-data "$PLAN3" "" applied)
[ "$applied" = "src-two" ] || fail "case3: expected src-two applied, got '$applied'"
SRC2="$WIKI/wiki/sources/src-two.md"
[ "$(count_line "$HEADING" "$SRC2")" = "0" ] || fail "case3: heading was created without the flag (wiki-ingest regression)"
grep -qF "[[q-data]]" "$SRC2" || fail "case3: link missing from src-two"
green "case3: no flag → bare EOF append, no heading created (wiki-ingest unchanged)"

# ============================================================
# Case 4: heading already present → insert after it (flag-agnostic)
# ============================================================
PLAN4='{"targets": [{"slug": "src-three", "sentence": "Answers research question [[q-data]].", "insert_after_heading": "## Research questions"}]}'
applied=$(apply_field q-data "$PLAN4" "--create-missing-heading" applied)
[ "$applied" = "src-three" ] || fail "case4: expected src-three applied, got '$applied'"
SRC3="$WIKI/wiki/sources/src-three.md"
[ "$(count_line "$HEADING" "$SRC3")" = "1" ] || fail "case4: expected the one pre-existing '$HEADING' (no duplicate)"
python3 - "$SRC3" <<'PY' || fail "case4: [[q-data]] not located under the pre-existing heading"
import sys
text = open(sys.argv[1]).read()
h = text.index("## Research questions")
l = text.index("[[q-data]]")
sys.exit(0 if l > h else 1)
PY
green "case4: pre-existing heading → insert after it, no duplicate"

# ============================================================
# Case 5: idempotency — re-apply case-1 plan → skipped, file unchanged
# ============================================================
BEFORE=$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$SRC1")
skipped=$(apply_field q-data "$PLAN1" "--create-missing-heading" skipped_existing_backlink)
[ "$skipped" = "src-one" ] || fail "case5: expected src-one in skipped_existing_backlink, got '$skipped'"
AFTER=$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$SRC1")
[ "$BEFORE" = "$AFTER" ] || fail "case5: re-apply mutated src-one (not idempotent)"
green "case5: re-apply skipped (already-linked) and left the file byte-identical"

green "ALL CASES PASS"
