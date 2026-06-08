#!/usr/bin/env bash
# test_concepts_index.sh — deterministic-renderer test for concepts_index.py.
#
# concepts_index.py is the load-bearing spine of the /concepts outline: it
# groups the wiki's concept pages by their wiki-resident theme, lays down the
# engine-owned MACHINE-OWNED:CONCEPTS-LEADIN spans, and re-renders idempotently
# without clobbering a narrator-authored lead-in. A regression in theme grouping
# or sentinel handling would silently corrupt the outline, so this locks the
# contract down — mirroring tests/test_concept_store.sh / test_portal_store.sh.
#
# Asserts (against fixture concept pages under a temp wiki root):
#   1. render creates wiki/concepts/index.md with the H1, ownership marker, and
#      intro line; the envelope is well-formed {success,data,error}.
#   2. Concepts are grouped under the correct `## <theme>` heading via the
#      wiki-resident theme derivation (a concept's backing `sources:` slugs are
#      looked up in wiki/index.md): unanimous theme, MAJORITY theme on a mixed
#      backing set, and the `## Uncategorized` fallback for a concept whose
#      backing source sits under no theme heading.
#   3. Each concept renders its one-line summary + a `[[slug]]` wikilink.
#   4. Each theme lead-in lives inside a MACHINE-OWNED:CONCEPTS-LEADIN sentinel
#      span; a fresh render uses the placeholder.
#   5. CARRY-FORWARD: a narrator-authored lead-in is preserved across a
#      re-render (no clobber), while the untouched themes keep the placeholder.
#   6. BYTE-IDEMPOTENT: re-rendering an unchanged wiki reports changed:false and
#      leaves the page byte-identical (no stamp/date churn).
#   7. HUMAN-PAGE: an existing index.md with content but NO ownership marker is
#      skipped (skipped_human_page:true) and left untouched.
#   8. stage writes the proposed page to .cogni-wiki/concepts-index-proposed.md
#      without the lock and without touching the live page.
#   9. python3.9 floor: the script carries `from __future__ import annotations`
#      and parses cleanly under ast.parse.
#
# bash 3.2 + stdlib python3 only. Posix only (render uses fcntl.flock via
# cogni-wiki's _wiki_lock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/concepts_index.py"
SCRIPTS_DIR="$PLUGIN_ROOT/scripts"
WSD="$PLUGIN_ROOT/../cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: concepts_index.py not found at $SCRIPT"
  exit 1
fi
if [ ! -d "$WSD" ]; then
  red "FAIL: cogni-wiki wiki-ingest scripts not found at $WSD (needed for _wiki_lock)"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
errors=0

# Tiny envelope-field reader (same idiom as test_concept_store.sh).
field() { python3 -c 'import sys,json;d=json.load(sys.stdin);print(eval("d"+sys.argv[1]))' "$1"; }

# Print the `## <theme>` heading the `[[slug]]` bullet renders under, or empty.
bullet_section() {
  python3 - "$1" "$2" <<'PY'
import sys, re
slug, path = sys.argv[1], sys.argv[2]
cur = None
for line in open(path, encoding="utf-8"):
    m = re.match(r"^##\s+(.+?)\s*$", line)
    if m:
        cur = m.group(1)
        continue
    if re.match(r"^\s*-\s", line) and ("[[" + slug + "]]") in line:
        print(cur or "")
        break
PY
}

# --- fixture wiki ------------------------------------------------------------
WIKI="$WORK/wiki-root"
mkdir -p "$WIKI/wiki/concepts" "$WIKI/.cogni-wiki"
echo '{"schema_version":"0.0.6","entries_count":0}' > "$WIKI/.cogni-wiki/config.json"

# Portal: two themes, each owning source bullets. src-loose is named under NO
# theme heading, so a concept backed only by it lands in Uncategorized.
cat > "$WIKI/wiki/index.md" <<'EOF'
# Knowledge Portal

## Regulatory Scope

- [[src-scope-a]] — Scope source A
- [[src-scope-b]] — Scope source B

## Enforcement

- [[src-enf-a]] — Enforcement source A
EOF

# Concept page emitter: title, sources list (wiki://<slug>), a SUMMARY block.
mk_concept() {
  slug="$1"; title="$2"; summary="$3"; shift 3
  {
    printf -- '---\n'
    printf 'title: %s\n' "$title"
    printf 'type: concept\n'
    printf 'status: distilled\n'
    printf 'sources:\n'
    for s in "$@"; do printf -- '  - wiki://%s\n' "$s"; done
    printf -- '---\n'
    printf '# %s\n' "$title"
    printf -- '<!-- MACHINE-OWNED:SUMMARY:START -->\n'
    printf '%s\n' "$summary"
    printf -- '<!-- MACHINE-OWNED:SUMMARY:END -->\n'
  } > "$WIKI/wiki/concepts/$slug.md"
}

# Unanimous Regulatory Scope (both backing sources under that theme).
mk_concept data-protection "Data Protection" \
  "How personal data is protected under the regime." src-scope-a src-scope-b
# Single Enforcement source.
mk_concept penalties "Penalties" \
  "Fines and sanctions for non-compliance." src-enf-a
# Mixed backing set: 2 scope + 1 enforcement -> MAJORITY Regulatory Scope.
mk_concept scope-vs-enforcement "Scope vs Enforcement" \
  "Where scope ends and enforcement begins." src-scope-a src-scope-b src-enf-a
# Backed only by a source under no theme heading -> Uncategorized fallback.
mk_concept loose-concept "Loose Concept" \
  "A concept with no resolvable theme." src-loose

IDX="$WIKI/wiki/concepts/index.md"

# --- 1. render creates the page ----------------------------------------------
OUT=$(python3 "$SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
if [ "$(echo "$OUT" | field '["success"]')" = "True" ] && [ -f "$IDX" ]; then
  green "PASS: render creates wiki/concepts/index.md"
else
  red "FAIL: render did not create the index"; echo "$OUT"; errors=$((errors+1))
fi
[ "$(echo "$OUT" | field '["data"]["changed"]')" = "True" ] \
  && green "PASS: first render reports changed:true" \
  || { red "FAIL: first render changed != true"; errors=$((errors+1)); }
assert_grep '^# Concepts$' "$IDX" "page H1 '# Concepts'"
assert_grep 'MACHINE-OWNED:CONCEPTS-INDEX' "$IDX" "page ownership marker"
assert_grep 'Auto-generated concept map' "$IDX" "page intro line"

# --- 2. theme grouping (wiki-resident derivation) ----------------------------
[ "$(bullet_section data-protection "$IDX")" = "Regulatory Scope" ] \
  && green "PASS: unanimous concept -> Regulatory Scope" \
  || { red "FAIL: data-protection not under Regulatory Scope"; errors=$((errors+1)); }
[ "$(bullet_section penalties "$IDX")" = "Enforcement" ] \
  && green "PASS: single-source concept -> Enforcement" \
  || { red "FAIL: penalties not under Enforcement"; errors=$((errors+1)); }
[ "$(bullet_section scope-vs-enforcement "$IDX")" = "Regulatory Scope" ] \
  && green "PASS: mixed backing set -> MAJORITY (Regulatory Scope)" \
  || { red "FAIL: majority theme resolution wrong"; errors=$((errors+1)); }
[ "$(bullet_section loose-concept "$IDX")" = "Uncategorized" ] \
  && green "PASS: no-resolvable-theme concept -> Uncategorized fallback" \
  || { red "FAIL: loose-concept not under Uncategorized"; errors=$((errors+1)); }

# --- 3. summary + wikilink bullet --------------------------------------------
assert_grep 'How personal data is protected under the regime. \[\[data-protection\]\]' \
  "$IDX" "concept bullet renders summary + [[slug]] link"
assert_grep '\[\[penalties\]\]' "$IDX" "penalties bullet has [[slug]] wikilink"

# --- 4. lead-in sentinel spans, placeholder on a fresh render ----------------
assert_grep 'MACHINE-OWNED:CONCEPTS-LEADIN:regulatory-scope:START' \
  "$IDX" "Regulatory Scope lead-in sentinel span present"
assert_grep 'theme lead-in pending narration' \
  "$IDX" "fresh render uses the lead-in placeholder"

# --- 5. CARRY-FORWARD: a narrator-authored lead-in survives a re-render -------
python3 - "$IDX" "$SCRIPTS_DIR" <<'PY'
import sys
sys.path.insert(0, sys.argv[2])
from _knowledge_lib import upsert_machine_block
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
t = upsert_machine_block(
    t, "CONCEPTS-LEADIN:regulatory-scope",
    "Authored framing: the legal boundaries of the regime; start with data protection.")
open(p, "w", encoding="utf-8").write(t)
PY
OUT=$(python3 "$SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
assert_grep 'Authored framing: the legal boundaries' \
  "$IDX" "authored lead-in carried forward across re-render (no clobber)"
# The untouched Enforcement theme still shows the placeholder.
assert_grep 'theme lead-in pending narration' \
  "$IDX" "untouched theme keeps the placeholder after carry-forward"

# --- 6. BYTE-IDEMPOTENT re-render --------------------------------------------
cp "$IDX" "$WORK/idx.before"
OUT=$(python3 "$SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
[ "$(echo "$OUT" | field '["data"]["changed"]')" = "False" ] \
  && green "PASS: unchanged re-render reports changed:false" \
  || { red "FAIL: idempotent re-render changed != false"; errors=$((errors+1)); }
if cmp -s "$WORK/idx.before" "$IDX"; then
  green "PASS: re-render is byte-identical (no stamp churn)"
else
  red "FAIL: re-render mutated the page"; errors=$((errors+1))
fi

# --- 7. HUMAN-PAGE skip ------------------------------------------------------
HWIKI="$WORK/human-wiki"
mkdir -p "$HWIKI/wiki/concepts" "$HWIKI/.cogni-wiki"
echo '{"schema_version":"0.0.6","entries_count":0}' > "$HWIKI/.cogni-wiki/config.json"
cp "$WIKI/wiki/index.md" "$HWIKI/wiki/index.md"
cp "$WIKI/wiki/concepts/data-protection.md" "$HWIKI/wiki/concepts/data-protection.md"
printf '# My hand-written concept map\n\nNothing machine-owned here.\n' \
  > "$HWIKI/wiki/concepts/index.md"
cp "$HWIKI/wiki/concepts/index.md" "$WORK/human.before"
OUT=$(python3 "$SCRIPT" render --wiki-root "$HWIKI" --wiki-scripts-dir "$WSD")
[ "$(echo "$OUT" | field '["data"]["skipped_human_page"]')" = "True" ] \
  && green "PASS: human-authored index skipped (skipped_human_page)" \
  || { red "FAIL: human page not skipped"; echo "$OUT"; errors=$((errors+1)); }
if cmp -s "$WORK/human.before" "$HWIKI/wiki/concepts/index.md"; then
  green "PASS: human page left byte-untouched"
else
  red "FAIL: human page was modified"; errors=$((errors+1))
fi

# --- 8. stage subcommand (lock-free) -----------------------------------------
SWIKI="$WORK/stage-wiki"
mkdir -p "$SWIKI/wiki/concepts" "$SWIKI/.cogni-wiki"
echo '{"schema_version":"0.0.6","entries_count":0}' > "$SWIKI/.cogni-wiki/config.json"
cp "$WIKI/wiki/index.md" "$SWIKI/wiki/index.md"
cp "$WIKI/wiki/concepts/penalties.md" "$SWIKI/wiki/concepts/penalties.md"
OUT=$(python3 "$SCRIPT" stage --wiki-root "$SWIKI")
STAGED="$SWIKI/.cogni-wiki/concepts-index-proposed.md"
[ "$(echo "$OUT" | field '["success"]')" = "True" ] && [ -f "$STAGED" ] \
  && green "PASS: stage writes the proposed page" \
  || { red "FAIL: stage did not write the proposal"; echo "$OUT"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["would_change"]')" = "True" ] \
  && green "PASS: stage reports would_change on a missing live page" \
  || { red "FAIL: stage would_change != true"; errors=$((errors+1)); }
[ ! -f "$SWIKI/wiki/concepts/index.md" ] \
  && green "PASS: stage does not touch the live page" \
  || { red "FAIL: stage wrote the live page"; errors=$((errors+1)); }

# --- 9. python3.9 floor ------------------------------------------------------
assert_grep 'from __future__ import annotations' "$SCRIPT" \
  "script carries the py3.9 future-annotations import"
if python3 -c "import ast,sys; ast.parse(open(sys.argv[1],encoding='utf-8').read())" "$SCRIPT"; then
  green "PASS: concepts_index.py parses cleanly (ast.parse)"
else
  red "FAIL: concepts_index.py has a syntax error"; errors=$((errors+1))
fi

# --- summary -----------------------------------------------------------------
if [ "$errors" -eq 0 ]; then
  green "ALL PASS: test_concepts_index.sh"
  exit 0
else
  red "FAILED: $errors assertion(s) in test_concepts_index.sh"
  exit 1
fi
