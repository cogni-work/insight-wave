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

green "ALL TESTS PASS"
