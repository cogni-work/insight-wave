#!/usr/bin/env bash
# test_lint_fix.sh — exercise the v0.0.32 (#222) `wiki-lint --fix=*` and
# `--suggest` modes end-to-end against a migrated fixture wiki.
#
# Plants one defect per fixable class, then asserts:
#   1. `--fix=<class> --dry-run` emits a plan and writes nothing.
#   2. `--fix=<class>` (wet) modifies disk and clears the warning class.
#   3. `--fix=all` composes cleanly across all five classes.
#   4. `--suggest` populates `data.suggestions[]` for prose-shaped findings
#      (orphan_page, stale_page, claim_drift).
#
# Mirrors the structure of test_lint_health_partition.sh — bash 3.2 +
# python3 stdlib only, exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
LINT="$PLUGIN_ROOT/skills/wiki-lint/scripts/lint_wiki.py"
HEALTH="$PLUGIN_ROOT/skills/wiki-health/scripts/health.py"
MIGRATE="$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { red "FAIL: $1"; exit 1; }

# ---------- prepare a migrated fixture and plant one defect per class ----------
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$MIGRATE" --wiki-root "$WIKI" --apply >/dev/null

# Defect 1 (reverse_link_missing): strip back-link in per-type-directories.md.
cat > "$WIKI/wiki/concepts/per-type-directories.md" <<'EOF'
---
id: per-type-directories
title: Per-Type Page Directories
type: concept
tags: [layout, schema]
created: 2026-04-01
updated: 2026-04-01
sources:
  - https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
---

# Per-Type Page Directories

Closing the gap is what motivates the [[adopt-schema-version-0-0-5]] decision.
EOF

# Defect 2 (synthesis_no_wiki_source): synthesis page with non-wiki source only.
mkdir -p "$WIKI/wiki/syntheses"
cat > "$WIKI/wiki/syntheses/synth-thoughts.md" <<'EOF'
---
id: synth-thoughts
title: Synthesis Thoughts
type: synthesis
tags: [synthesis]
created: 2026-04-01
updated: 2026-04-01
sources:
  - https://example.com/blog
---

# Synthesis Thoughts

Building on [[karpathy-pattern]] and [[per-type-directories]].
EOF

# Defect 3 (frontmatter_defaults): missing `id:` and non-ISO `updated:`.
cat > "$WIKI/wiki/concepts/old-format.md" <<'EOF'
---
title: Old Format
type: concept
tags: [test]
created: 2026-04-01
updated: 04/15/2026
sources:
  - https://example.com
---

# Old Format

References [[karpathy-pattern]].
EOF

# Defect 4 (entries_count_drift): bump config to a deliberately-wrong count.
python3 - <<EOF
import json
p = "$WIKI/.cogni-wiki/config.json"
d = json.load(open(p))
d["entries_count"] = 99
json.dump(d, open(p, "w"), indent=2)
EOF

# Defect 5 (alphabetisation): shuffle index.md bullet ordering.
cat > "$WIKI/wiki/index.md" <<'EOF'
# Index

## Concepts

- [[per-type-directories]] — promote page types from frontmatter to filesystem layout
- [[karpathy-pattern]] — the LLM-wiki design idea this whole project rests on
- [[old-format]] — fixture page with old-format updated
- [[synth-thoughts]] — synthesis fixture page

## Decisions

- [[adopt-schema-version-0-0-5]] — bump to 0.0.5 once per-type dirs land
EOF

green "fixture prepared with one defect per fixable class"

# ---------- helper: snapshot every wiki file's checksum ----------
snap() {
  find "$WIKI/wiki" "$WIKI/.cogni-wiki/config.json" -type f \
    -exec sha256sum {} \; | sort
}

# ---------- 1) per-class --dry-run: plan emitted, no on-disk change ----------
for cls in reverse_link_missing synthesis_no_wiki_source frontmatter_defaults \
           entries_count_drift alphabetisation; do
  before=$(snap)
  out=$(python3 "$LINT" --wiki-root "$WIKI" --fix="$cls" --dry-run)
  echo "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
assert d['success'], d.get('error')
fixed = [f for f in d['data']['fixed'] if f['class'] == '$cls']
assert fixed, '$cls dry-run: no plan emitted'
for f in fixed:
    assert f['applied'] is False, '$cls dry-run: applied=true (must be false)'
" || fail "$cls dry-run plan check"
  after=$(snap)
  [ "$before" = "$after" ] || fail "$cls dry-run modified files on disk"
  green "  $cls: dry-run plan emitted, no on-disk change"
done

# ---------- 2) wet --fix per class: writes disk, clears warning class ----------
# Re-run the plant block to undo any state that wet runs below will mutate.
# Each fixer below is run on the same fixture in sequence; we re-snapshot and
# re-lint to confirm the class disappears from `data.warnings[]`.

# reverse_link_missing
out=$(python3 "$LINT" --wiki-root "$WIKI" --fix=reverse_link_missing)
echo "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())['data']
fixed = [f for f in d['fixed'] if f['class']=='reverse_link_missing' and f['applied']]
assert fixed, 'no reverse_link_missing fix applied'
" || fail "reverse_link_missing wet apply"
relint=$(python3 "$LINT" --wiki-root "$WIKI")
echo "$relint" | python3 -c "
import json, sys
ws = json.loads(sys.stdin.read())['data']['warnings']
remaining = [w for w in ws if w['class']=='reverse_link_missing']
assert not remaining, f'reverse_link_missing still present after wet fix: {remaining}'
" || fail "reverse_link_missing not cleared after wet fix"
green "  reverse_link_missing: wet apply clears the warning class"

# synthesis_no_wiki_source
out=$(python3 "$LINT" --wiki-root "$WIKI" --fix=synthesis_no_wiki_source)
echo "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())['data']
fixed = [f for f in d['fixed'] if f['class']=='synthesis_no_wiki_source' and f['applied']]
assert fixed, 'no synthesis_no_wiki_source fix applied'
" || fail "synthesis_no_wiki_source wet apply"
grep -q '^  - wiki://karpathy-pattern$' "$WIKI/wiki/syntheses/synth-thoughts.md" \
  || fail "synthesis fix did not add wiki://karpathy-pattern source"
green "  synthesis_no_wiki_source: wet apply backfills wiki:// sources"

# frontmatter_defaults
out=$(python3 "$LINT" --wiki-root "$WIKI" --fix=frontmatter_defaults)
echo "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())['data']
fixed = [f for f in d['fixed'] if f['class']=='frontmatter_defaults' and f['applied']]
assert fixed, 'no frontmatter_defaults fix applied'
" || fail "frontmatter_defaults wet apply"
grep -q '^id: old-format$' "$WIKI/wiki/concepts/old-format.md" \
  || fail "frontmatter_defaults did not backfill id"
grep -q '^updated: 2026-04-15$' "$WIKI/wiki/concepts/old-format.md" \
  || fail "frontmatter_defaults did not normalise updated"
green "  frontmatter_defaults: wet apply backfills id + normalises updated"

# entries_count_drift
out=$(python3 "$LINT" --wiki-root "$WIKI" --fix=entries_count_drift)
echo "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())['data']
fixed = [f for f in d['fixed'] if f['class']=='entries_count_drift' and f['applied']]
assert fixed, 'no entries_count_drift fix applied'
" || fail "entries_count_drift wet apply"
got=$(python3 -c "import json; print(json.load(open('$WIKI/.cogni-wiki/config.json'))['entries_count'])")
[ "$got" = "5" ] || fail "entries_count is $got after fix (expected 5)"
green "  entries_count_drift: wet apply reconciles config to filesystem count"

# alphabetisation
out=$(python3 "$LINT" --wiki-root "$WIKI" --fix=alphabetisation)
echo "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())['data']
fixed = [f for f in d['fixed'] if f['class']=='alphabetisation' and f['applied']]
assert fixed, 'no alphabetisation fix applied'
" || fail "alphabetisation wet apply"
# Concepts should now be alphabetical: karpathy, old-format, per-type, synth.
python3 - <<EOF || fail "alphabetisation did not produce sorted bullets"
text = open("$WIKI/wiki/index.md").read()
import re
m = re.search(r"## Concepts\s*\n+((?:- \[\[[^\]]+\]\][^\n]*\n)+)", text)
assert m, "Concepts section not found"
slugs = re.findall(r"\[\[([^\]]+)\]\]", m.group(1))
assert slugs == sorted(slugs), f"not sorted: {slugs}"
EOF
green "  alphabetisation: wet apply re-sorts category bullets"

# ---------- 3) --fix=all on a fresh fixture ----------
rm -rf "$WIKI"
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$MIGRATE" --wiki-root "$WIKI" --apply >/dev/null

# Re-plant all five defects in one shot (same blocks as above).
cat > "$WIKI/wiki/concepts/per-type-directories.md" <<'EOF'
---
id: per-type-directories
title: Per-Type Page Directories
type: concept
tags: [layout, schema]
created: 2026-04-01
updated: 2026-04-01
sources:
  - https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
---

# Per-Type Page Directories

Closing the gap is what motivates the [[adopt-schema-version-0-0-5]] decision.
EOF
mkdir -p "$WIKI/wiki/syntheses"
cat > "$WIKI/wiki/syntheses/synth-thoughts.md" <<'EOF'
---
id: synth-thoughts
title: Synthesis Thoughts
type: synthesis
tags: [synthesis]
created: 2026-04-01
updated: 2026-04-01
sources:
  - https://example.com/blog
---

# Synthesis Thoughts

Building on [[karpathy-pattern]] and [[per-type-directories]].
EOF
cat > "$WIKI/wiki/concepts/old-format.md" <<'EOF'
---
title: Old Format
type: concept
tags: [test]
created: 2026-04-01
updated: 04/15/2026
sources:
  - https://example.com
---

# Old Format

References [[karpathy-pattern]].
EOF
python3 - <<EOF
import json
p = "$WIKI/.cogni-wiki/config.json"
d = json.load(open(p))
d["entries_count"] = 99
json.dump(d, open(p, "w"), indent=2)
EOF
cat > "$WIKI/wiki/index.md" <<'EOF'
# Index

## Concepts

- [[per-type-directories]] — promote page types from frontmatter to filesystem layout
- [[karpathy-pattern]] — the LLM-wiki design idea this whole project rests on
- [[old-format]] — fixture page with old-format updated
- [[synth-thoughts]] — synthesis fixture page

## Decisions

- [[adopt-schema-version-0-0-5]] — bump to 0.0.5 once per-type dirs land
EOF

# Dry-run --fix=all: plan all five, write nothing.
before=$(snap)
out=$(python3 "$LINT" --wiki-root "$WIKI" --fix=all --dry-run)
echo "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())['data']
classes = {f['class'] for f in d['fixed']}
expected = {'reverse_link_missing','synthesis_no_wiki_source','frontmatter_defaults','entries_count_drift','alphabetisation'}
missing = expected - classes
assert not missing, f'--fix=all --dry-run missing classes: {missing}'
assert all(f['applied'] is False for f in d['fixed']), 'dry-run had applied=true entries'
" || fail "--fix=all --dry-run plan check"
after=$(snap)
[ "$before" = "$after" ] || fail "--fix=all --dry-run modified files on disk"
green "  --fix=all --dry-run: plans every class, writes nothing"

# Wet --fix=all
out=$(python3 "$LINT" --wiki-root "$WIKI" --fix=all)
echo "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())['data']
applied = [f for f in d['fixed'] if f['applied']]
assert len(applied) >= 5, f'--fix=all applied {len(applied)} (expected ≥5)'
assert not d['failed'], f'--fix=all had failures: {d[\"failed\"]}'
" || fail "--fix=all wet apply"
green "  --fix=all (wet): applies every class without failures"

# Re-lint should show zero of the fixable classes.
relint=$(python3 "$LINT" --wiki-root "$WIKI")
echo "$relint" | python3 -c "
import json, sys
ws = json.loads(sys.stdin.read())['data']['warnings']
fixable = {'reverse_link_missing','synthesis_no_wiki_source'}
remaining = [w for w in ws if w['class'] in fixable]
assert not remaining, f'fixable warnings remain after --fix=all: {remaining}'
" || fail "fixable warnings remain after --fix=all"
green "  --fix=all leaves zero fixable warnings on re-lint"

# ---------- 4) --suggest: structured proposals for prose-shaped findings ----------
rm -rf "$WIKI"
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$MIGRATE" --wiki-root "$WIKI" --apply >/dev/null

# Plant: orphan with shared tags, stale page, claim_drift bridge.
cat > "$WIKI/wiki/concepts/lonely-thing.md" <<'EOF'
---
id: lonely-thing
title: Lonely Thing
type: concept
tags: [karpathy, design]
created: 2026-04-01
updated: 2026-04-01
sources:
  - https://example.com
---

# Lonely Thing

Nobody links here.
EOF
cat > "$WIKI/wiki/concepts/old-stale.md" <<'EOF'
---
id: old-stale
title: Old Stale
type: concept
tags: [karpathy, schema]
created: 2024-01-01
updated: 2024-01-01
sources:
  - https://example.com
---

# Old Stale

Outdated. Refers to [[karpathy-pattern]].
EOF
cat > "$WIKI/.cogni-wiki/last-resweep.json" <<'EOF'
{
  "sweep_date": "2026-04-15",
  "mode": "lite",
  "report_path": "raw/claims-resweep-2026-04-15/report.md",
  "deviated_pages": ["karpathy-pattern"],
  "unavailable_pages": []
}
EOF

out=$(python3 "$LINT" --wiki-root "$WIKI" --suggest)
echo "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())['data']
classes = {s['class'] for s in d['suggestions']}
for c in ('orphan_page','stale_page','claim_drift'):
    assert c in classes, f'--suggest did not emit class {c}: got {classes}'
# Validate orphan_page schema fields.
orphan = next(s for s in d['suggestions'] if s['class']=='orphan_page' and s['page']=='lonely-thing')
assert orphan['proposed_action'] == 'link_from'
assert 'karpathy-pattern' in orphan['candidates']
# Validate claim_drift carries wiki_update_args.
cd_ = next(s for s in d['suggestions'] if s['class']=='claim_drift')
assert cd_['proposed_action'] == 'invoke_wiki_update'
assert cd_['wiki_update_args']['slug'] == cd_['page']
" || fail "--suggest output schema check"
green "  --suggest emits structured proposals for orphan/stale/claim_drift"

# ---------- 5) --suggest does not write to disk ----------
before=$(snap)
python3 "$LINT" --wiki-root "$WIKI" --suggest >/dev/null
after=$(snap)
[ "$before" = "$after" ] || fail "--suggest modified files on disk"
green "  --suggest writes nothing to disk"

# ---------- 6) --fix=all composition: no stale-snapshot clobber ----------
# Regression: in-process fixers (reverse_link_missing, then frontmatter_defaults)
# must each read the page FRESH, not from the start-of-scan snapshot. Otherwise
# frontmatter_defaults rewrites a cited source from the stale snapshot and erases
# the `## See also` reverse link reverse_link_missing just wrote — silently
# un-doing de-orphaning. Fixture: a source MISSING id: (triggers
# frontmatter_defaults) that is ALSO cited by a synthesis (triggers
# reverse_link_missing on that source). One --fix=all pass must apply BOTH.
TODAY=$(date +%Y-%m-%d)
CLOB="$WORKDIR/clobber-wiki"
mkdir -p "$CLOB/wiki/sources" "$CLOB/wiki/syntheses" "$CLOB/.cogni-wiki"
cat > "$CLOB/.cogni-wiki/config.json" <<EOF
{"name":"c","slug":"c","created":"$TODAY","entries_count":2,"last_lint":null,"schema_version":"0.0.6"}
EOF
cat > "$CLOB/wiki/index.md" <<EOF
# Index

## T

- [[clob-src]] — s
- [[clob-syn]] — y
EOF
# Source page deliberately MISSING the id: field.
cat > "$CLOB/wiki/sources/clob-src.md" <<EOF
---
title: "Clobber Source"
type: source
tags: [source]
created: $TODAY
updated: $TODAY
sources: ["https://example.org/c"]
---
# Clobber Source
Body text comfortably beyond the fifty-character stub threshold so no stub warning.
EOF
cat > "$CLOB/wiki/syntheses/clob-syn.md" <<EOF
---
id: clob-syn
title: "Clobber Synthesis"
type: synthesis
tags: [synthesis]
created: $TODAY
updated: $TODAY
sources:
  - wiki://clob-src
derived_from_research: proj
---
# Clobber Synthesis
Synthesis body comfortably beyond the fifty-character stub threshold so no warning.

## References

**[1]** "Clobber Source". [https://example.org/c](https://example.org/c) — [[clob-src]]
EOF
python3 "$LINT" --wiki-root "$CLOB" --fix=all >/dev/null
src_after=$(cat "$CLOB/wiki/sources/clob-src.md")
case "$src_after" in
  *"id: clob-src"*) : ;;
  *) fail "clobber: frontmatter_defaults did not backfill id: on clob-src" ;;
esac
case "$src_after" in
  *"[[clob-syn]]"*) : ;;
  *) fail "clobber: reverse_link_missing's [[clob-syn]] back-link was clobbered by frontmatter_defaults (stale-snapshot regression)" ;;
esac
orphans=$(python3 "$LINT" --wiki-root "$CLOB" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];print(len([w for w in d['warnings'] if w['class']=='orphan_page']))")
[ "$orphans" = "0" ] || fail "clobber: expected 0 orphan_page after --fix=all, got $orphans"
green "  --fix=all applies reverse_link_missing AND frontmatter_defaults to one page without clobber"

# ---------- 7) frontmatter_defaults reconciles a CROSSED id: (#415) ----------
# A source page whose frontmatter `id:` is a *different* source's slug. The
# filename stem is authoritative; health.py flags id_mismatch (a hard error
# that blocks wiki-lint without --ignore-health). frontmatter_defaults must
# rewrite id: -> filename stem, not just backfill a missing id:.
TODAY=$(date +%Y-%m-%d)
XID="$WORKDIR/crossed-id-wiki"
mkdir -p "$XID/wiki/sources" "$XID/.cogni-wiki"
cat > "$XID/.cogni-wiki/config.json" <<EOF
{"name":"x","slug":"x","created":"$TODAY","entries_count":1,"last_lint":null,"schema_version":"0.0.6"}
EOF
cat > "$XID/wiki/index.md" <<EOF
# Index

## Sources

- [[overview-source]] — o
EOF
# id: carries a DIFFERENT source's slug than the filename stem.
cat > "$XID/wiki/sources/overview-source.md" <<EOF
---
id: tuv-other-source
title: "Overview Source"
type: source
tags: [source]
created: $TODAY
updated: $TODAY
sources: ["https://example.org/overview"]
---
# Overview Source
Body text comfortably beyond the fifty-character stub threshold so no stub warning.
EOF

# Sanity: health reports the crossed id as an id_mismatch error before the fix.
before_mm=$(python3 "$HEALTH" --wiki-root "$XID" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];print(len([e for e in d['errors'] if e['class']=='id_mismatch']))")
[ "$before_mm" = "1" ] || fail "crossed-id: expected 1 id_mismatch before fix, got $before_mm"

# Dry-run: plan the change, write nothing (on-disk id: still the wrong slug).
out=$(python3 "$LINT" --wiki-root "$XID" --fix=frontmatter_defaults --dry-run)
echo "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())['data']
planned = [f for f in d['fixed'] if f['class']=='frontmatter_defaults' and f['page']=='overview-source']
assert planned, 'crossed-id: no frontmatter_defaults plan emitted'
assert all(f['applied'] is False for f in planned), 'crossed-id: dry-run applied=true'
assert any('tuv-other-source' in f.get('change','') and 'overview-source' in f.get('change','') for f in planned), f'crossed-id: change text missing rename: {planned}'
" || fail "crossed-id: dry-run plan check"
grep -q '^id: tuv-other-source$' "$XID/wiki/sources/overview-source.md" \
  || fail "crossed-id: dry-run mutated id: on disk"

# Wet: id: rewritten to the filename stem.
python3 "$LINT" --wiki-root "$XID" --fix=frontmatter_defaults >/dev/null
grep -q '^id: overview-source$' "$XID/wiki/sources/overview-source.md" \
  || fail "crossed-id: wet fix did not rewrite id: to filename stem"

# Idempotent: a second wet run plans no further frontmatter_defaults change.
out=$(python3 "$LINT" --wiki-root "$XID" --fix=frontmatter_defaults)
echo "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())['data']
again = [f for f in d['fixed'] if f['class']=='frontmatter_defaults' and f['page']=='overview-source']
assert not again, f'crossed-id: fixer not idempotent: {again}'
" || fail "crossed-id: fixer not idempotent on re-run"

# End-to-end unblock: health now reports 0 id_mismatch errors.
after_mm=$(python3 "$HEALTH" --wiki-root "$XID" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];print(len([e for e in d['errors'] if e['class']=='id_mismatch']))")
[ "$after_mm" = "0" ] || fail "crossed-id: expected 0 id_mismatch after fix, got $after_mm"
green "  frontmatter_defaults reconciles a crossed id: -> filename (health id_mismatch cleared)"

# ---------- 8) frontmatter_defaults rewrites a QUOTED-but-stem-correct id: ----
# `id: "<slug>"` (quoted, stem matches the filename) is still an id_mismatch:
# _wikilib.parse_frontmatter keeps surrounding quotes, so health.py:162
# compares "<slug>" != <slug>. The fixer must normalise it to the unquoted
# canonical form to clear the error, not skip it as already-correct.
QID="$WORKDIR/quoted-id-wiki"
mkdir -p "$QID/wiki/sources" "$QID/.cogni-wiki"
cat > "$QID/.cogni-wiki/config.json" <<EOF
{"name":"q","slug":"q","created":"$TODAY","entries_count":1,"last_lint":null,"schema_version":"0.0.6"}
EOF
cat > "$QID/wiki/index.md" <<EOF
# Index

## Sources

- [[quoted-source]] — q
EOF
cat > "$QID/wiki/sources/quoted-source.md" <<EOF
---
id: "quoted-source"
title: "Quoted Source"
type: source
tags: [source]
created: $TODAY
updated: $TODAY
sources: ["https://example.org/quoted"]
---
# Quoted Source
Body text comfortably beyond the fifty-character stub threshold so no stub warning.
EOF

q_before=$(python3 "$HEALTH" --wiki-root "$QID" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];print(len([e for e in d['errors'] if e['class']=='id_mismatch']))")
[ "$q_before" = "1" ] || fail "quoted-id: expected 1 id_mismatch before fix, got $q_before"
python3 "$LINT" --wiki-root "$QID" --fix=frontmatter_defaults >/dev/null
grep -q '^id: quoted-source$' "$QID/wiki/sources/quoted-source.md" \
  || fail "quoted-id: fixer did not normalise id: \"quoted-source\" to unquoted form"
q_after=$(python3 "$HEALTH" --wiki-root "$QID" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];print(len([e for e in d['errors'] if e['class']=='id_mismatch']))")
[ "$q_after" = "0" ] || fail "quoted-id: expected 0 id_mismatch after fix, got $q_after"
green "  frontmatter_defaults normalises a quoted-but-stem-correct id: (health id_mismatch cleared)"

green "ALL TESTS PASS"
