#!/usr/bin/env bash
# test_migrate_question_index.sh — functional test for
# scripts/migrate-question-index.py (the #438 Part B driver that re-files each
# wiki/questions/<slug>.md node under its theme_label index heading via
# cogni-wiki's locked wiki_index_update.py --move-slug mode).
#
# Executes the real code path against a synthetic wiki whose index.md starts
# with both question slugs under a flat `## Research questions` heading and
# whose question pages carry distinct theme_label values.
#
# Covers:
#   1. --dry-run reports the moves (moved[] populated) but leaves index.md
#      byte-identical — no subprocess, no write.
#   2. Wet run relocates both slugs under their theme_label headings and out of
#      `## Research questions`; the empty source heading is dropped.
#   3. Idempotent re-run: every node reports action=noop, success stays true,
#      index.md is unchanged from the post-wet state.
#   4. A node whose theme_label is empty is recorded under skipped[] (never
#      passed as an empty --to-category, which the locked script rejects).
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/migrate-question-index.py"
WSD="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

if [ ! -d "$WSD" ]; then
  red "FAIL: cogni-wiki wiki-ingest scripts not found at $WSD"
  exit 1
fi

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

WIKI="$WORK/wiki-root"
mkdir -p "$WIKI/wiki/questions" "$WIKI/.cogni-wiki"

# -- index.md: both question slugs live under a flat ## Research questions --
cat > "$WIKI/wiki/index.md" <<'EOF'
# Index

## Research questions

- [[records-of-processing-scope]] — What is in scope for the records of processing.
- [[high-risk-obligations]] — Obligations that attach to high-risk systems.

## Sources

- [[some-source]] — An unrelated source bullet that must remain untouched.
EOF

# -- question pages with distinct theme_label values (JSON-quoted, as emitted) --
cat > "$WIKI/wiki/questions/records-of-processing-scope.md" <<'EOF'
---
id: records-of-processing-scope
title: "Records of processing scope"
type: question
tags: [question]
theme_label: "Compliance Scope"
---

## Findings
EOF

cat > "$WIKI/wiki/questions/high-risk-obligations.md" <<'EOF'
---
id: high-risk-obligations
title: "High-risk obligations"
type: question
tags: [question]
theme_label: "Risk Tiers"
---

## Findings
EOF

# -- a node with an empty theme_label: must be skipped, not moved --
cat > "$WIKI/wiki/questions/legacy-no-theme.md" <<'EOF'
---
id: legacy-no-theme
title: "Legacy node with no theme"
type: question
tags: [question]
theme_label: ""
---

## Findings
EOF

# ---------------------------------------------------------------------------
# Test 1: --dry-run reports moves but does not touch index.md
# ---------------------------------------------------------------------------
INDEX_BEFORE="$WORK/index-before.md"
cp "$WIKI/wiki/index.md" "$INDEX_BEFORE"

OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI" --dry-run)
echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['dry_run'] is True, d
moved = {m['slug'] for m in d['data']['moved']}
assert moved == {'records-of-processing-scope', 'high-risk-obligations'}, d
skipped = {s['slug'] for s in d['data']['skipped']}
assert 'legacy-no-theme' in skipped, d
print('OK')
" | grep -q OK && green "PASS: dry-run reports the two moves and skips the empty-theme node" \
  || { red "FAIL: dry-run output assertion"; errors=$((errors + 1)); }

if diff -q "$INDEX_BEFORE" "$WIKI/wiki/index.md" >/dev/null 2>&1; then
  green "PASS: dry-run left index.md byte-identical"
else
  red "FAIL: dry-run modified index.md"
  errors=$((errors + 1))
fi

# ---------------------------------------------------------------------------
# Test 2: wet run relocates both slugs under their theme_label headings
# ---------------------------------------------------------------------------
OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['dry_run'] is False, d
actions = {m['slug']: m['action'] for m in d['data']['moved']}
assert actions.get('records-of-processing-scope') == 'moved', d
assert actions.get('high-risk-obligations') == 'moved', d
skipped = {s['slug'] for s in d['data']['skipped']}
assert 'legacy-no-theme' in skipped, d
print('OK')
" | grep -q OK && green "PASS: wet run reports both nodes moved, empty-theme node skipped" \
  || { red "FAIL: wet-run output assertion"; errors=$((errors + 1)); }

assert_grep '## Compliance Scope' "$WIKI/wiki/index.md" "Compliance Scope heading created"
assert_grep '## Risk Tiers' "$WIKI/wiki/index.md" "Risk Tiers heading created"

# Each slug now sits under its theme_label heading, not under Research questions.
LOC_RESULT=$(python3 - "$WIKI/wiki/index.md" <<'PY'
import sys, re
text = open(sys.argv[1], encoding="utf-8").read()
# Map each slug to the most recent ## heading above it.
current = None
loc = {}
for line in text.splitlines():
    h = re.match(r"^##\s+(.*?)\s*$", line)
    if h:
        current = h.group(1)
        continue
    m = re.match(r"^- \[\[([a-z0-9\-]+)\]\]", line)
    if m:
        loc[m.group(1)] = current
ok = (loc.get("records-of-processing-scope") == "Compliance Scope"
      and loc.get("high-risk-obligations") == "Risk Tiers"
      and loc.get("some-source") == "Sources")
print("OK" if ok else f"BAD {loc}")
PY
)
if [ "$LOC_RESULT" = "OK" ]; then
  green "PASS: each slug sits under its theme_label heading, Sources untouched"
else
  red "FAIL: heading placement wrong — $LOC_RESULT"
  errors=$((errors + 1))
fi

# The flat Research questions heading is now empty and dropped.
assert_not_grep '## Research questions' "$WIKI/wiki/index.md" "empty Research questions heading dropped"
# The unrelated Sources bullet is untouched.
assert_grep '\[\[some-source\]\]' "$WIKI/wiki/index.md" "unrelated Sources bullet preserved"

# ---------------------------------------------------------------------------
# Test 3: idempotent re-run — every node is a noop, index unchanged
# ---------------------------------------------------------------------------
INDEX_AFTER_WET="$WORK/index-after-wet.md"
cp "$WIKI/wiki/index.md" "$INDEX_AFTER_WET"

OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['moved'] == [], d
noop = {n['slug'] for n in d['data']['noop']}
assert noop == {'records-of-processing-scope', 'high-risk-obligations'}, d
print('OK')
" | grep -q OK && green "PASS: idempotent re-run reports both nodes as noop" \
  || { red "FAIL: idempotent re-run assertion"; errors=$((errors + 1)); }

if diff -q "$INDEX_AFTER_WET" "$WIKI/wiki/index.md" >/dev/null 2>&1; then
  green "PASS: idempotent re-run left index.md unchanged"
else
  red "FAIL: idempotent re-run modified index.md"
  errors=$((errors + 1))
fi

# ---------------------------------------------------------------------------
# Test 4: self-resolve path — NO --wiki-scripts-dir. Exercises the driver's
# resolve_wiki_scripts("wiki-ingest") probe (now _knowledge_lib.resolve_wiki_scripts)
# against the in-repo sibling checkout, which the lines 33-36 WSD guard above
# already proved exists. Tests 2/3 always pass --wiki-scripts-dir, so this is
# the only case that fires the probe end-to-end.
#
# A fresh wiki fixture (a legacy flat `## Research questions` heading) gives the
# self-resolve run a relocatable bullet, so success means the probe resolved AND
# the move ran to completion against the resolved wiki_index_update.py.
# ---------------------------------------------------------------------------
WIKI2="$WORK/wiki-root-2"
mkdir -p "$WIKI2/wiki/questions" "$WIKI2/.cogni-wiki"
cat > "$WIKI2/wiki/index.md" <<'EOF'
# Index

## Research questions

- [[records-of-processing-scope]] — What is in scope for the records of processing.
EOF
cat > "$WIKI2/wiki/questions/records-of-processing-scope.md" <<'EOF'
---
id: records-of-processing-scope
title: "Records of processing scope"
type: question
tags: [question]
theme_label: "Compliance Scope"
---

## Findings
EOF

OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI2")
echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['dry_run'] is False, d
actions = {m['slug']: m['action'] for m in d['data']['moved']}
assert actions.get('records-of-processing-scope') == 'moved', d
print('OK')
" | grep -q OK && green "PASS: self-resolve (no --wiki-scripts-dir) probes the sibling checkout and relocates the node" \
  || { red "FAIL: self-resolve output assertion (probe or move failed)"; errors=$((errors + 1)); }

assert_grep '## Compliance Scope' "$WIKI2/wiki/index.md" "self-resolve run created the theme_label heading"
assert_not_grep '## Research questions' "$WIKI2/wiki/index.md" "self-resolve run dropped the empty flat heading"

# ---------------------------------------------------------------------------
if [ "$errors" -eq 0 ]; then
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
