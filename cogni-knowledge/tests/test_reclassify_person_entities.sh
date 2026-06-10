#!/usr/bin/env bash
# test_reclassify_person_entities.sh — functional test for
# scripts/reclassify-person-entities.py (the one-shot legacy person-entity
# reclassifier that moves named-human type:entity pages into wiki/people/).
#
# Covers:
#   1. Dry-run (default) lists the person entity as a candidate (with reason),
#      does NOT list the org entity, and moves/retypes nothing.
#   2. --apply without a selector is refused (the heuristic never acts alone).
#   3. --apply --slugs moves the page into wiki/people/, retypes
#      type: entity -> type: person (rest byte-for-byte), re-renders the
#      entities + people sub-indexes and the curated root MAP, and leaves the
#      org page untouched.
#   4. Second --apply --slugs run is a clean noop (already_reclassified).
#   5. No-clobber: a pre-existing wiki/people/<slug>.md target is refused.
#   6. A pre-0.0.8 base is refused with the knowledge-index --migrate pointer.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/reclassify-person-entities.py"
WSD="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

build_wiki() {
  # $1 = root, $2 = schema_version
  rm -rf "$1"
  mkdir -p "$1/wiki/entities" "$1/wiki/people" "$1/wiki/meta" "$1/.cogni-wiki"
  cat > "$1/.cogni-wiki/config.json" <<EOF
{"wiki_slug": "fixture", "title": "Fixture Base", "entries_count": 3, "schema_version": "$2"}
EOF
  printf '# Fixture Base\n' > "$1/wiki/index.md"
  printf '# Log\n' > "$1/wiki/meta/log.md"
  cat > "$1/wiki/entities/andrej-karpathy.md" <<'EOF'
---
id: andrej-karpathy
title: "Andrej Karpathy"
type: entity

created: 2026-01-01
updated: 2026-01-01
sources:
  - https://example.org/karpathy
---

# Andrej Karpathy

A named human filed as an entity before the person type existed.
EOF
  cat > "$1/wiki/entities/j-robert-oppenheimer.md" <<'EOF'
---
id: j-robert-oppenheimer
title: "J. Robert Oppenheimer"
type: entity
created: 2026-01-01
updated: 2026-01-01
sources:
  - https://example.org/oppenheimer
---

# J. Robert Oppenheimer

Dotted initials must read as a name token, not an acronym.
EOF
  cat > "$1/wiki/entities/fraunhofer-institut.md" <<'EOF'
---
id: fraunhofer-institut
title: "Fraunhofer Institut"
type: entity
created: 2026-01-01
updated: 2026-01-01
sources:
  - https://example.org/fraunhofer
---

# Fraunhofer Institut

An organization that must never be flagged as a person.
EOF
}

WIKI="$WORK/wiki-root"
build_wiki "$WIKI" "0.0.8"

# ---------------------------------------------------------------------------
# 1. Dry-run: person is a candidate, org is not, nothing moves
# ---------------------------------------------------------------------------
DRY_OUT="$WORK/dry.json"
python3 "$SCRIPT" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" > "$DRY_OUT"
assert_grep '"success": true' "$DRY_OUT" "dry-run succeeds"
assert_grep '"action": "dry_run"' "$DRY_OUT" "dry-run is the default"
assert_grep '"slug": "andrej-karpathy"' "$DRY_OUT" "person entity listed as candidate"
if python3 -c "
import json,sys
d = json.load(open('$DRY_OUT'))
sys.exit(0 if all(c['slug'] != 'fraunhofer-institut' for c in d['data']['candidates']) else 1)
"; then
  green "PASS: org entity is NOT a candidate (org marker)"
else
  red "FAIL: org entity surfaced as a person candidate"
  errors=$((errors + 1))
fi
assert_grep '"slug": "j-robert-oppenheimer"' "$DRY_OUT" \
  "dotted-initials person listed as candidate (not an acronym false-negative)"
if [ -f "$WIKI/wiki/entities/andrej-karpathy.md" ] && [ ! -e "$WIKI/wiki/people/andrej-karpathy.md" ]; then
  green "PASS: dry-run moved nothing"
else
  red "FAIL: dry-run moved files"
  errors=$((errors + 1))
fi

# ---------------------------------------------------------------------------
# 2. --apply without a selector is refused
# ---------------------------------------------------------------------------
NOSEL_OUT="$WORK/nosel.json"
python3 "$SCRIPT" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" --apply > "$NOSEL_OUT" || true
assert_grep '"success": false' "$NOSEL_OUT" "--apply without selector refused"
assert_grep 'requires an explicit selector' "$NOSEL_OUT" "refusal names the selector contract"

# ---------------------------------------------------------------------------
# 3. --apply --slugs moves + retypes + re-renders
# ---------------------------------------------------------------------------
APPLY_OUT="$WORK/apply.json"
python3 "$SCRIPT" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" --apply --slugs andrej-karpathy > "$APPLY_OUT"
assert_grep '"success": true' "$APPLY_OUT" "apply succeeds"
assert_grep '"action": "reclassified"' "$APPLY_OUT" "apply reports reclassified"
if [ -f "$WIKI/wiki/people/andrej-karpathy.md" ] && [ ! -e "$WIKI/wiki/entities/andrej-karpathy.md" ]; then
  green "PASS: page moved into wiki/people/"
else
  red "FAIL: page not moved"
  errors=$((errors + 1))
fi
assert_grep '^type: person$' "$WIKI/wiki/people/andrej-karpathy.md" "frontmatter retyped to person"
assert_grep 'A named human filed as an entity' "$WIKI/wiki/people/andrej-karpathy.md" \
  "body preserved byte-for-byte"
if python3 -c "
import sys
t = open('$WIKI/wiki/people/andrej-karpathy.md').read()
sys.exit(0 if 'type: person\n\ncreated:' in t else 1)
"; then
  green "PASS: blank line after the retyped frontmatter line preserved (regex does not eat newlines)"
else
  red "FAIL: blank line after type: line was consumed by the retype"
  errors=$((errors + 1))
fi
assert_grep '^type: entity$' "$WIKI/wiki/entities/fraunhofer-institut.md" "org page untouched"
if [ -f "$WIKI/wiki/people/index.md" ] && [ -f "$WIKI/wiki/entities/index.md" ]; then
  green "PASS: entities + people sub-indexes rendered"
else
  red "FAIL: sub-indexes not rendered"
  errors=$((errors + 1))
fi
assert_grep 'andrej-karpathy' "$WIKI/wiki/people/index.md" "people sub-index carries the moved page"
assert_grep 'reclassify' "$WIKI/wiki/meta/log.md" "reclassification logged"
assert_grep '"entries_count": 3' "$WIKI/.cogni-wiki/config.json" "entries_count unchanged"

# ---------------------------------------------------------------------------
# 4. Second run is a clean noop
# ---------------------------------------------------------------------------
NOOP_OUT="$WORK/noop.json"
python3 "$SCRIPT" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" --apply --slugs andrej-karpathy > "$NOOP_OUT"
assert_grep '"success": true' "$NOOP_OUT" "second run succeeds"
assert_grep '"action": "noop"' "$NOOP_OUT" "second run is a noop"
assert_grep '"reason": "already_reclassified"' "$NOOP_OUT" "noop reason is already_reclassified"

# ---------------------------------------------------------------------------
# 5. No-clobber refusal
# ---------------------------------------------------------------------------
WIKI2="$WORK/wiki-clobber"
build_wiki "$WIKI2" "0.0.8"
printf -- '---\nid: andrej-karpathy\ntitle: "Andrej Karpathy"\ntype: person\n---\n\nExisting person page.\n' \
  > "$WIKI2/wiki/people/andrej-karpathy.md"
CLOB_OUT="$WORK/clobber.json"
python3 "$SCRIPT" --wiki-root "$WIKI2" --wiki-scripts-dir "$WSD" --apply --slugs andrej-karpathy > "$CLOB_OUT" || true
assert_grep '"success": false' "$CLOB_OUT" "existing target refused"
assert_grep '"reason": "target_exists"' "$CLOB_OUT" "refusal reason is target_exists"
assert_grep 'Existing person page.' "$WIKI2/wiki/people/andrej-karpathy.md" "existing target not clobbered"
assert_grep '^type: entity$' "$WIKI2/wiki/entities/andrej-karpathy.md" "source left intact on refusal"

# ---------------------------------------------------------------------------
# 6. Pre-0.0.8 base refused
# ---------------------------------------------------------------------------
WIKI3="$WORK/wiki-legacy"
build_wiki "$WIKI3" "0.0.7"
LEGACY_OUT="$WORK/legacy.json"
python3 "$SCRIPT" --wiki-root "$WIKI3" --wiki-scripts-dir "$WSD" > "$LEGACY_OUT" || true
assert_grep '"success": false' "$LEGACY_OUT" "pre-0.0.8 base refused"
assert_grep 'knowledge-index --migrate' "$LEGACY_OUT" "refusal points at the migration path"

# ---------------------------------------------------------------------------
if [ "$errors" -gt 0 ]; then
  red "$errors assertion(s) failed"
  exit 1
fi
green "all reclassify-person-entities assertions passed"
