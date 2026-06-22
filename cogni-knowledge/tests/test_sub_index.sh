#!/usr/bin/env bash
# test_sub_index.sh — deterministic-renderer test for the generic sub_index.py.
#
# sub_index.py is the generalization of concepts_index.py: one shared renderer
# that produces a curated, machine-owned per-type sub-index for ANY of the seven
# cogni-knowledge wiki page types. concepts_index.py now delegates to it (its own
# byte-stable contract is locked by test_concepts_index.sh). This test locks the
# GENERALIZED contract: every type renders a `wiki/<type>/index.md` with the right
# `MACHINE-OWNED:<TYPE>-INDEX` marker + `<TYPE>-LEADIN:<theme>` sentinels, groups
# pages by their (per-type-derived) theme, and re-renders byte-idempotently.
#
# Asserts, parameterized across all 5 types (sources, questions, syntheses,
# entities, concepts):
#   1. render creates wiki/<type>/index.md; the envelope is well-formed and
#      reports changed:true with the per-type page count.
#   2. The page carries the `# <H1>` heading and the `MACHINE-OWNED:<TYPE>-INDEX`
#      ownership marker.
#   3. A page resolves to its theme via the type's theme strategy (backing
#      `sources:` for distilled/synthesis, own-slug-in-portal for source,
#      `theme_label:` frontmatter for question); a page with no resolvable theme
#      lands under `## Uncategorized`.
#   4. Each page renders its one-line summary + a `[[slug]]` wikilink; each theme
#      lead-in lives in a `MACHINE-OWNED:<TYPE>-LEADIN:<slug>` placeholder span.
#   5. BYTE-IDEMPOTENT: re-rendering an unchanged wiki reports changed:false and
#      leaves the page byte-identical.
#   6. stage writes <wiki-root>/.cogni-wiki/<type>-index-proposed.md without the
#      lock and without touching the live page.
# Plus, once (representative types):
#   7. CARRY-FORWARD: a narrator-authored lead-in survives a re-render (sources).
#   8. HUMAN-PAGE: an index.md with content but no ownership marker is skipped
#      (questions).
#   9. python3.9 floor: sub_index.py carries `from __future__ import annotations`
#      and parses cleanly under ast.parse.
#
# bash 3.2 + stdlib python3 only. Posix only (render uses fcntl.flock via
# cogni-wiki's _wiki_lock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/sub_index.py"
SCRIPTS_DIR="$PLUGIN_ROOT/scripts"
WSD="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: sub_index.py not found at $SCRIPT"
  exit 1
fi
if [ ! -d "$WSD" ]; then
  red "FAIL: cogni-wiki wiki-ingest scripts not found at $WSD (needed for _wiki_lock)"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
errors=0

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
mkdir -p "$WIKI/.cogni-wiki" \
  "$WIKI/wiki/concepts" "$WIKI/wiki/entities" "$WIKI/wiki/sources" \
  "$WIKI/wiki/questions" "$WIKI/wiki/syntheses"
echo '{"schema_version":"0.0.8","entries_count":0}' > "$WIKI/.cogni-wiki/config.json"

# Portal: Regulatory Scope owns the backing source src-scope-a (which is itself a
# source page, so the `sources` type resolves its own slug here). src-loose is
# under NO theme heading, so anything backed only by it lands in Uncategorized.
cat > "$WIKI/wiki/index.md" <<'EOF'
# Knowledge Portal

## Regulatory Scope

- [[src-scope-a]] — Scope source A

## Enforcement

- [[src-enf-a]] — Enforcement source A
EOF

# A distilled/synthesis page: block-style `sources:` of `wiki://<backing-slug>`
# (theme_via_backing_sources). dir is the type name; type frontmatter varies.
mk_backed() {
  dir="$1"; slug="$2"; ptype="$3"; title="$4"; summary="$5"; backing="$6"
  {
    printf -- '---\n'
    printf 'title: %s\n' "$title"
    printf 'type: %s\n' "$ptype"
    printf 'sources:\n'
    printf -- '  - wiki://%s\n' "$backing"
    printf -- '---\n'
    printf '# %s\n' "$title"
    printf -- '<!-- MACHINE-OWNED:SUMMARY:START -->\n'
    printf '%s\n' "$summary"
    printf -- '<!-- MACHINE-OWNED:SUMMARY:END -->\n'
  } > "$WIKI/wiki/$dir/$slug.md"
}

# A source page: inline `sources: ["<URL>"]` + pre_extracted_claims
# (theme_via_own_slug — the page's OWN slug is looked up in the portal).
mk_source() {
  slug="$1"; title="$2"; claim="$3"
  {
    printf -- '---\n'
    printf 'title: %s\n' "$title"
    printf 'type: source\n'
    printf 'sources: ["https://example.org/%s"]\n' "$slug"
    printf 'pre_extracted_claims:\n'
    printf -- '  - id: clm-001\n'
    printf '    text: %s\n' "$claim"
    printf '    excerpt_quote: %s\n' "$claim"
    printf '    excerpt_position: 1\n'
    printf -- '---\n'
    printf '# %s\nbody\n' "$title"
  } > "$WIKI/wiki/sources/$slug.md"
}

# A question page: `theme_label:` frontmatter (theme_via_frontmatter).
mk_question() {
  slug="$1"; title="$2"; theme="$3"
  {
    printf -- '---\n'
    printf 'title: %s\n' "$title"
    printf 'type: question\n'
    if [ -n "$theme" ]; then printf 'theme_label: %s\n' "$theme"; fi
    printf -- '---\n'
    printf '# %s\n' "$title"
  } > "$WIKI/wiki/questions/$slug.md"
}

# Backing-source types: themed page backed by src-scope-a (Regulatory Scope),
# loose page backed by src-loose (no theme heading -> Uncategorized).
for t in concepts entities; do
  mk_backed "$t" "$t-themed" "${t%s}" "${t} themed" "A themed ${t} page." src-scope-a
  mk_backed "$t" "$t-loose"  "${t%s}" "${t} loose"  "A loose ${t} page."  src-loose
done
# syntheses: summary is the title (summary_fn=summary_title); still backing-sourced.
mk_backed syntheses syntheses-themed synthesis "Syntheses themed" "ignored" src-scope-a
mk_backed syntheses syntheses-loose  synthesis "Syntheses loose"  "ignored" src-loose

# sources: src-scope-a is named in the portal (Regulatory Scope); src-loose is not.
mk_source src-scope-a "Scope Source A" "The regime applies to all providers."
mk_source src-loose   "Loose Source"   "An unfiled source with no theme."

# questions: q-themed carries theme_label, q-loose carries none.
mk_question q-themed "Who must comply?" "Regulatory Scope"
mk_question q-loose  "An unthemed question?" ""

# Per-type expected (type, themed_slug, loose_slug).
# A bash-3.2-safe parallel-array loop (no associative arrays).
TYPES="concepts entities syntheses sources questions"
themed_for() { case "$1" in
  sources) echo "src-scope-a" ;; questions) echo "q-themed" ;; *) echo "$1-themed" ;;
esac; }
loose_for() { case "$1" in
  sources) echo "src-loose" ;; questions) echo "q-loose" ;; *) echo "$1-loose" ;;
esac; }

# --- 1-6. per-type render contract -------------------------------------------
for T in $TYPES; do
  U=$(echo "$T" | tr 'a-z' 'A-Z')
  THEMED=$(themed_for "$T"); LOOSE=$(loose_for "$T")
  IDX="$WIKI/wiki/$T/index.md"

  OUT=$(python3 "$SCRIPT" render --type "$T" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
  if [ "$(echo "$OUT" | field '["success"]')" = "True" ] && [ -f "$IDX" ]; then
    green "PASS[$T]: render creates wiki/$T/index.md"
  else
    red "FAIL[$T]: render did not create the index"; echo "$OUT"; errors=$((errors+1))
  fi
  [ "$(echo "$OUT" | field '["data"]["changed"]')" = "True" ] \
    && green "PASS[$T]: first render reports changed:true" \
    || { red "FAIL[$T]: first render changed != true"; errors=$((errors+1)); }

  assert_grep "MACHINE-OWNED:$U-INDEX" "$IDX" "[$T] page ownership marker"
  [ "$(bullet_section "$THEMED" "$IDX")" = "Regulatory Scope" ] \
    && green "PASS[$T]: themed page -> Regulatory Scope" \
    || { red "FAIL[$T]: $THEMED not under Regulatory Scope"; errors=$((errors+1)); }
  [ "$(bullet_section "$LOOSE" "$IDX")" = "Uncategorized" ] \
    && green "PASS[$T]: loose page -> Uncategorized fallback" \
    || { red "FAIL[$T]: $LOOSE not under Uncategorized"; errors=$((errors+1)); }
  assert_grep "\[\[$THEMED\]\]" "$IDX" "[$T] themed bullet has [[slug]] wikilink"
  assert_grep "MACHINE-OWNED:$U-LEADIN:regulatory-scope:START" "$IDX" \
    "[$T] Regulatory Scope lead-in sentinel span present"
  assert_grep "This theme groups the $T below" "$IDX" \
    "[$T] fresh render uses the deterministic lead-in fallback"

  # BYTE-IDEMPOTENT re-render
  cp "$IDX" "$WORK/$T.before"
  OUT=$(python3 "$SCRIPT" render --type "$T" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
  [ "$(echo "$OUT" | field '["data"]["changed"]')" = "False" ] \
    && green "PASS[$T]: unchanged re-render reports changed:false" \
    || { red "FAIL[$T]: idempotent re-render changed != false"; errors=$((errors+1)); }
  if cmp -s "$WORK/$T.before" "$IDX"; then
    green "PASS[$T]: re-render is byte-identical (no stamp churn)"
  else
    red "FAIL[$T]: re-render mutated the page"; errors=$((errors+1))
  fi

  # stage (lock-free) writes the proposal, never touches the live page.
  SWIKI="$WORK/stage-$T"
  mkdir -p "$SWIKI/wiki/$T" "$SWIKI/.cogni-wiki"
  echo '{"schema_version":"0.0.8","entries_count":0}' > "$SWIKI/.cogni-wiki/config.json"
  cp "$WIKI/wiki/index.md" "$SWIKI/wiki/index.md"
  cp "$WIKI/wiki/$T/$THEMED.md" "$SWIKI/wiki/$T/$THEMED.md"
  OUT=$(python3 "$SCRIPT" stage --type "$T" --wiki-root "$SWIKI")
  STAGED="$SWIKI/.cogni-wiki/$T-index-proposed.md"
  [ "$(echo "$OUT" | field '["success"]')" = "True" ] && [ -f "$STAGED" ] \
    && green "PASS[$T]: stage writes the proposed page" \
    || { red "FAIL[$T]: stage did not write the proposal"; echo "$OUT"; errors=$((errors+1)); }
  [ ! -f "$SWIKI/wiki/$T/index.md" ] \
    && green "PASS[$T]: stage does not touch the live page" \
    || { red "FAIL[$T]: stage wrote the live page"; errors=$((errors+1)); }
done

# --- 7. CARRY-FORWARD (sources type) -----------------------------------------
SIDX="$WIKI/wiki/sources/index.md"
python3 - "$SIDX" "$SCRIPTS_DIR" <<'PY'
import sys
sys.path.insert(0, sys.argv[2])
from _knowledge_lib import upsert_machine_block
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
t = upsert_machine_block(
    t, "SOURCES-LEADIN:regulatory-scope",
    "Authored framing: the primary sources establishing regulatory scope.")
open(p, "w", encoding="utf-8").write(t)
PY
OUT=$(python3 "$SCRIPT" render --type sources --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
assert_grep 'Authored framing: the primary sources' "$SIDX" \
  "sources: authored lead-in carried forward across re-render (no clobber)"

# --- 8. HUMAN-PAGE skip (questions type) -------------------------------------
HWIKI="$WORK/human-wiki"
mkdir -p "$HWIKI/wiki/questions" "$HWIKI/.cogni-wiki"
echo '{"schema_version":"0.0.8","entries_count":0}' > "$HWIKI/.cogni-wiki/config.json"
cp "$WIKI/wiki/index.md" "$HWIKI/wiki/index.md"
cp "$WIKI/wiki/questions/q-themed.md" "$HWIKI/wiki/questions/q-themed.md"
printf '# My hand-written question index\n\nNothing machine-owned here.\n' \
  > "$HWIKI/wiki/questions/index.md"
cp "$HWIKI/wiki/questions/index.md" "$WORK/human.before"
OUT=$(python3 "$SCRIPT" render --type questions --wiki-root "$HWIKI" --wiki-scripts-dir "$WSD")
[ "$(echo "$OUT" | field '["data"]["skipped_human_page"]')" = "True" ] \
  && green "PASS: human-authored questions index skipped (skipped_human_page)" \
  || { red "FAIL: human page not skipped"; echo "$OUT"; errors=$((errors+1)); }
if cmp -s "$WORK/human.before" "$HWIKI/wiki/questions/index.md"; then
  green "PASS: human page left byte-untouched"
else
  red "FAIL: human page was modified"; errors=$((errors+1))
fi

# --- 9. FRONTMATTER MEMBERSHIP: curated root with NO per-page bullets ---------
# Proves curated-root readiness: with the root portal carrying ONLY `## <theme>`
# headings (no per-page bullets), source membership resolves from each source
# page's OWN `theme_label:` frontmatter (theme_via_own_slug), and a distilled
# page resolves transitively through that frontmatter-derived source_theme map
# (theme_via_backing_sources) — so moving the per-page bullets off the root into
# the sub-indexes never strands either type.
FMWIKI="$WORK/fm-wiki"
mkdir -p "$FMWIKI/.cogni-wiki" "$FMWIKI/wiki/sources" "$FMWIKI/wiki/concepts"
echo '{"schema_version":"0.0.8","entries_count":0}' > "$FMWIKI/.cogni-wiki/config.json"
# Curated root: a theme HEADING only, NO per-page bullets under it.
cat > "$FMWIKI/wiki/index.md" <<'EOF'
# Knowledge Portal

## Regulatory Scope
EOF
# Source page carrying authoritative theme_label: frontmatter (no portal bullet).
{
  printf -- '---\n'
  printf 'title: FM Scope Source\n'
  printf 'type: source\n'
  printf 'sources: ["https://example.org/fm-scope"]\n'
  printf 'theme_label: "Regulatory Scope"\n'
  printf 'pre_extracted_claims:\n'
  printf -- '  - id: clm-001\n'
  printf '    text: A claim.\n'
  printf '    excerpt_quote: A claim.\n'
  printf '    excerpt_position: 1\n'
  printf -- '---\n'
  printf '# FM Scope Source\nbody\n'
} > "$FMWIKI/wiki/sources/src-fm.md"
# Concept backed only by that source — no portal bullet for src-fm anywhere.
{
  printf -- '---\n'
  printf 'title: FM Concept\n'
  printf 'type: concept\n'
  printf 'sources:\n'
  printf -- '  - wiki://src-fm\n'
  printf -- '---\n'
  printf '# FM Concept\n'
  printf -- '<!-- MACHINE-OWNED:SUMMARY:START -->\n'
  printf 'A concept backed by the frontmatter-themed source.\n'
  printf -- '<!-- MACHINE-OWNED:SUMMARY:END -->\n'
} > "$FMWIKI/wiki/concepts/con-fm.md"

python3 "$SCRIPT" render --type sources  --wiki-root "$FMWIKI" --wiki-scripts-dir "$WSD" >/dev/null
python3 "$SCRIPT" render --type concepts --wiki-root "$FMWIKI" --wiki-scripts-dir "$WSD" >/dev/null
[ "$(bullet_section src-fm "$FMWIKI/wiki/sources/index.md")" = "Regulatory Scope" ] \
  && green "PASS: source resolves theme from frontmatter (no root bullet)" \
  || { red "FAIL: src-fm not under Regulatory Scope via frontmatter"; errors=$((errors+1)); }
[ "$(bullet_section con-fm "$FMWIKI/wiki/concepts/index.md")" = "Regulatory Scope" ] \
  && green "PASS: distilled page resolves theme transitively via frontmatter source map" \
  || { red "FAIL: con-fm not under Regulatory Scope via backing-source frontmatter"; errors=$((errors+1)); }

# --- 9b. A1 false-filtering fix (#933): theme-label whitespace is normalized ---
# A source whose theme_label carries a double internal space + trailing whitespace
# ("AI  Liability ") must render its sub-index `## <theme>` heading collapsed to a
# single space ("AI Liability"), so it agrees with root_index._heading_anchor's
# \s+ → %20 fragment (#AI%20Liability). Without the producer-site _collapse the
# heading would keep the double space and the root deep-link would land at page top.
{
  printf -- '---\n'
  printf 'title: AI Liability Drift Source\n'
  printf 'type: source\n'
  printf 'sources: ["https://example.org/fm-drift"]\n'
  printf 'theme_label: "AI  Liability "\n'
  printf 'pre_extracted_claims:\n'
  printf -- '  - id: clm-001\n'
  printf '    text: A claim.\n'
  printf '    excerpt_quote: A claim.\n'
  printf '    excerpt_position: 1\n'
  printf -- '---\n'
  printf '# AI Liability Drift Source\nbody\n'
} > "$FMWIKI/wiki/sources/src-drift.md"
python3 "$SCRIPT" render --type sources --wiki-root "$FMWIKI" --wiki-scripts-dir "$WSD" >/dev/null
[ "$(bullet_section src-drift "$FMWIKI/wiki/sources/index.md")" = "AI Liability" ] \
  && green "PASS: double-space theme_label collapsed to single-space heading (#933)" \
  || { red "FAIL: src-drift heading not collapsed to 'AI Liability' (A1 drift)"; errors=$((errors+1)); }
if grep -q '^## AI  Liability' "$FMWIKI/wiki/sources/index.md"; then
  red "FAIL: sub-index heading kept the double space (the A1 drift, #933)"; errors=$((errors+1))
else
  green "PASS: sub-index heading does NOT keep the double space (#933)"
fi

# --- 10. unknown type is a clean fail-soft error -----------------------------
if python3 "$SCRIPT" stage --type bogus --wiki-root "$WIKI" >/dev/null 2>&1; then
  red "FAIL: unknown --type did not error"; errors=$((errors+1))
else
  green "PASS: unknown --type rejected (argparse choices guard)"
fi

# --- 11. python3.9 floor -----------------------------------------------------
assert_grep 'from __future__ import annotations' "$SCRIPT" \
  "sub_index.py carries the py3.9 future-annotations import"
if python3 -c "import ast,sys; ast.parse(open(sys.argv[1],encoding='utf-8').read())" "$SCRIPT"; then
  green "PASS: sub_index.py parses cleanly (ast.parse)"
else
  red "FAIL: sub_index.py has a syntax error"; errors=$((errors+1))
fi

# --- summary -----------------------------------------------------------------
if [ "$errors" -eq 0 ]; then
  green "ALL PASS: test_sub_index.sh"
  exit 0
else
  red "FAILED: $errors assertion(s) in test_sub_index.sh"
  exit 1
fi
