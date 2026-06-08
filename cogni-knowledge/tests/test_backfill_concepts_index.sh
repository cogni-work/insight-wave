#!/usr/bin/env bash
# test_backfill_concepts_index.sh — driver test for backfill_concepts_index.py.
#
# backfill_concepts_index.py is the one-shot operator driver that brings an
# already-finalized base up to the /concepts layout on demand: it wraps
# concepts_index.py render (the deterministic spine) so a base with concept
# pages but no queued research can materialise wiki/concepts/index.md without
# waiting for the next finalize. It is RENDER-ONLY (the lead-in spans stay empty
# until the next finalize narrates them), idempotent, and non-destructive.
#
# Asserts (against fixture concept pages under a temp wiki root):
#   1. RENDER-CREATES: on a base with concept pages and no prior index.md, the
#      driver creates wiki/concepts/index.md with the H1 + ownership marker +
#      a lead-in placeholder; the envelope is {success:true, action:rendered,
#      changed:true} and carries the structural-only render_only note.
#   2. BYTE-IDEMPOTENT: a second run on the built outline is a byte-identical
#      no-op and reports action:noop / changed:false.
#   3. LEAD-IN PRESERVED: a narrator-authored MACHINE-OWNED:CONCEPTS-LEADIN span
#      survives a re-run (no clobber) — the driver inherits the renderer's
#      carry-forward + human/engine no-clobber contract.
#   4. EMPTY-CONCEPTS NOOP: a base with no wiki/concepts/*.md pages is a clean
#      action:noop, not an abort.
#   5. DRY-RUN: --dry-run probes the concept count and reports would_render /
#      noop without invoking the renderer (no index.md write).
#   6. python3.9 floor: the driver carries `from __future__ import annotations`
#      and parses cleanly under ast.parse.
#
# bash 3.2 + stdlib python3 only. Posix only (render uses fcntl.flock via
# cogni-wiki's _wiki_lock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER="$PLUGIN_ROOT/scripts/backfill_concepts_index.py"
SCRIPTS_DIR="$PLUGIN_ROOT/scripts"
WSD="$PLUGIN_ROOT/../cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$DRIVER" ]; then
  red "FAIL: backfill_concepts_index.py not found at $DRIVER"
  exit 1
fi
if [ ! -d "$WSD" ]; then
  red "FAIL: cogni-wiki wiki-ingest scripts not found at $WSD (needed for _wiki_lock)"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
errors=0

# Tiny envelope-field reader (same idiom as test_concepts_index.sh).
field() { python3 -c 'import sys,json;d=json.load(sys.stdin);print(eval("d"+sys.argv[1]))' "$1"; }

# Concept page emitter: title, sources list (wiki://<slug>), a SUMMARY block.
mk_concept() {
  wiki="$1"; slug="$2"; title="$3"; summary="$4"; shift 4
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
  } > "$wiki/wiki/concepts/$slug.md"
}

# --- fixture wiki (concept pages, NO prior index.md) -------------------------
WIKI="$WORK/wiki-root"
mkdir -p "$WIKI/wiki/concepts" "$WIKI/.cogni-wiki"
echo '{"schema_version":"0.0.6","entries_count":0}' > "$WIKI/.cogni-wiki/config.json"
cat > "$WIKI/wiki/index.md" <<'EOF'
# Knowledge Portal

## Regulatory Scope

- [[src-scope-a]] — Scope source A
- [[src-scope-b]] — Scope source B

## Enforcement

- [[src-enf-a]] — Enforcement source A
EOF
mk_concept "$WIKI" data-protection "Data Protection" \
  "How personal data is protected under the regime." src-scope-a src-scope-b
mk_concept "$WIKI" penalties "Penalties" \
  "Fines and sanctions for non-compliance." src-enf-a

IDX="$WIKI/wiki/concepts/index.md"

# --- 1. RENDER-CREATES: backfill an already-finalized base --------------------
[ ! -f "$IDX" ] || { red "FAIL: precondition — index.md already exists"; errors=$((errors+1)); }
OUT=$(python3 "$DRIVER" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
if [ "$(echo "$OUT" | field '["success"]')" = "True" ] && [ -f "$IDX" ]; then
  green "PASS: backfill creates wiki/concepts/index.md on a base with no prior outline"
else
  red "FAIL: backfill did not create the index"; echo "$OUT"; errors=$((errors+1))
fi
[ "$(echo "$OUT" | field '["data"]["action"]')" = "rendered" ] \
  && green "PASS: first backfill reports action:rendered" \
  || { red "FAIL: first backfill action != rendered"; echo "$OUT"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["changed"]')" = "True" ] \
  && green "PASS: first backfill reports changed:true" \
  || { red "FAIL: first backfill changed != true"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["render_only"]')" = "True" ] \
  && green "PASS: envelope flags render_only (structural-only outline)" \
  || { red "FAIL: render_only flag missing"; errors=$((errors+1)); }
assert_grep '^# Concepts$' "$IDX" "page H1 '# Concepts'"
assert_grep 'MACHINE-OWNED:CONCEPTS-INDEX' "$IDX" "page ownership marker"
assert_grep 'MACHINE-OWNED:CONCEPTS-LEADIN:regulatory-scope:START' \
  "$IDX" "Regulatory Scope lead-in sentinel span present"
assert_grep 'theme lead-in pending narration' \
  "$IDX" "fresh backfill uses the lead-in placeholder (render-only, narration deferred)"

# --- 2. BYTE-IDEMPOTENT re-run -----------------------------------------------
cp "$IDX" "$WORK/idx.before"
OUT=$(python3 "$DRIVER" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
[ "$(echo "$OUT" | field '["data"]["action"]')" = "noop" ] \
  && green "PASS: re-run on a built outline reports action:noop" \
  || { red "FAIL: idempotent re-run action != noop"; echo "$OUT"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["changed"]')" = "False" ] \
  && green "PASS: re-run reports changed:false" \
  || { red "FAIL: idempotent re-run changed != false"; errors=$((errors+1)); }
if cmp -s "$WORK/idx.before" "$IDX"; then
  green "PASS: re-run is byte-identical (no stamp churn)"
else
  red "FAIL: re-run mutated the page"; errors=$((errors+1))
fi

# --- 3. LEAD-IN PRESERVED across a re-run ------------------------------------
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
OUT=$(python3 "$DRIVER" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
assert_grep 'Authored framing: the legal boundaries' \
  "$IDX" "narrator-authored lead-in carried forward across a backfill re-run (no clobber)"
assert_grep 'theme lead-in pending narration' \
  "$IDX" "untouched theme keeps the placeholder after carry-forward"

# --- 4. EMPTY-CONCEPTS base -> noop ------------------------------------------
EWIKI="$WORK/empty-wiki"
mkdir -p "$EWIKI/wiki/concepts" "$EWIKI/.cogni-wiki"
echo '{"schema_version":"0.0.6","entries_count":0}' > "$EWIKI/.cogni-wiki/config.json"
printf '# Knowledge Portal\n' > "$EWIKI/wiki/index.md"
OUT=$(python3 "$DRIVER" --wiki-root "$EWIKI" --wiki-scripts-dir "$WSD")
[ "$(echo "$OUT" | field '["success"]')" = "True" ] \
  && [ "$(echo "$OUT" | field '["data"]["action"]')" = "noop" ] \
  && green "PASS: empty-concepts base is a clean action:noop (not an abort)" \
  || { red "FAIL: empty-concepts base did not report success/noop"; echo "$OUT"; errors=$((errors+1)); }

# --- 5. DRY-RUN probes without invoking the renderer -------------------------
DWIKI="$WORK/dry-wiki"
mkdir -p "$DWIKI/wiki/concepts" "$DWIKI/.cogni-wiki"
echo '{"schema_version":"0.0.6","entries_count":0}' > "$DWIKI/.cogni-wiki/config.json"
printf '# Knowledge Portal\n\n## Regulatory Scope\n\n- [[src-scope-a]] — A\n' > "$DWIKI/wiki/index.md"
mk_concept "$DWIKI" dp "Data Protection" "How data is protected." src-scope-a
OUT=$(python3 "$DRIVER" --wiki-root "$DWIKI" --dry-run)
[ "$(echo "$OUT" | field '["success"]')" = "True" ] \
  && [ "$(echo "$OUT" | field '["data"]["action"]')" = "would_render" ] \
  && green "PASS: --dry-run on a base with concepts reports would_render" \
  || { red "FAIL: --dry-run action != would_render"; echo "$OUT"; errors=$((errors+1)); }
[ ! -f "$DWIKI/wiki/concepts/index.md" ] \
  && green "PASS: --dry-run writes nothing (renderer not invoked)" \
  || { red "FAIL: --dry-run wrote an index.md"; errors=$((errors+1)); }

# --- 6. python3.9 floor: __future__ import + ast.parse -----------------------
assert_grep 'from __future__ import annotations' "$DRIVER" "driver carries __future__ annotations import"
if python3 -c 'import ast,sys; ast.parse(open(sys.argv[1]).read())' "$DRIVER"; then
  green "PASS: driver parses cleanly under ast.parse (python3.9 floor)"
else
  red "FAIL: driver does not parse"; errors=$((errors+1))
fi

# --- summary -----------------------------------------------------------------
echo
if [ "$errors" -eq 0 ]; then
  green "backfill_concepts_index.py driver contract: all pass."
  exit 0
else
  red "backfill_concepts_index.py driver contract: $errors failure(s)."
  exit 1
fi
