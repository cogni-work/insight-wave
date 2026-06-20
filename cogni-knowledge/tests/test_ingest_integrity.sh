#!/usr/bin/env bash
# test_ingest_integrity.sh — functional test for scripts/ingest-integrity.py
# (the knowledge-ingest Step 3.5 post-wave integrity sweep that catches a
# cross-contaminated wiki/sources/<slug>.md page before the index/backlink
# step). Executes the real code path against a synthetic wiki + dispatch table.
#
# Covers:
#   1. Positive: pages whose frontmatter id + sources URL match the dispatch
#      record report zero violations.
#   2. Negative: a page carrying a FOREIGN id: AND a FOREIGN sources: URL (the
#      cross-contamination signature) is flagged with id_ok:false AND
#      url_ok:false, reason id_mismatch.
#   3. url_mismatch: id matches but the sources: URL was swapped.
#   4. page_missing: a dispatched slug with no page on disk.
#   5. URL normalization: a trailing slash / tracking param difference between
#      dispatch and page does NOT trip a false url_mismatch.
#   6. stdin dispatch (--dispatch -).
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/ingest-integrity.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

WIKI="$WORK/wiki-root"
mkdir -p "$WIKI/wiki/sources"

# --- helper to write a source page -------------------------------------------
write_page() {  # $1=slug $2=id $3=url
  cat > "$WIKI/wiki/sources/$1.md" <<EOF
---
id: $2
title: "Page for $1"
type: source
created: 2026-01-01
updated: 2026-01-01
sources: ["$3"]
---

# Page for $1

Body long enough to clear any later stub threshold.
EOF
}

# clean page (id + url match dispatch)
write_page clean-source clean-source "https://europa.eu/clean"
# contaminated page: clean-source's neighbour got clean-source's payload.
# Dispatched as slug "victim-source" / url "https://europa.eu/victim", but on
# disk it carries the FOREIGN id + FOREIGN url of another source.
write_page victim-source foreign-source "https://europa.eu/foreign"
# swapped-url page: id matches its slug, but sources: URL is wrong.
write_page url-swap url-swap "https://europa.eu/wrong-url"
# normalization page: dispatch url differs only by trailing slash + tracking param.
write_page norm-source norm-source "https://europa.eu/norm"

DISPATCH="$WORK/dispatch.json"
cat > "$DISPATCH" <<'EOF'
[
  {"slug": "clean-source", "url": "https://europa.eu/clean"},
  {"slug": "victim-source", "url": "https://europa.eu/victim"},
  {"slug": "url-swap", "url": "https://europa.eu/url-swap-expected"},
  {"slug": "norm-source", "url": "https://europa.eu/norm/?utm_source=x"},
  {"slug": "never-written", "url": "https://europa.eu/missing"}
]
EOF

OUT="$(python3 "$SCRIPT" sweep --wiki-root "$WIKI" --dispatch "$DISPATCH")"

echo "$OUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] else 1)' \
  && green "PASS: sweep returns success" || { red "FAIL: sweep not success"; echo "$OUT"; errors=$((errors+1)); }

# Use python to introspect the envelope deterministically.
introspect() { echo "$OUT" | python3 -c "$1"; }

# 1) clean-source + norm-source in ok[]; checked == 5
introspect '
import json,sys
d=json.load(sys.stdin)["data"]
assert d["checked"]==5, d["checked"]
assert "clean-source" in d["ok"], d["ok"]
assert "norm-source" in d["ok"], d["ok"]
' && green "PASS: clean + normalized-URL pages report ok (checked=5)" \
  || { red "FAIL: clean/norm not ok"; echo "$OUT"; errors=$((errors+1)); }

# 2) victim-source: both legs flagged, reason id_mismatch
introspect '
import json,sys
d=json.load(sys.stdin)["data"]
v={x["slug"]:x for x in d["violations"]}
e=v["victim-source"]
assert e["id_ok"] is False and e["url_ok"] is False, e
assert e["reason"]=="id_mismatch", e
assert e["observed_id"]=="foreign-source", e
assert e["observed_url"]=="https://europa.eu/foreign", e
' && green "PASS: contaminated page flagged id_ok=false AND url_ok=false (id_mismatch)" \
  || { red "FAIL: contamination not flagged correctly"; echo "$OUT"; errors=$((errors+1)); }

# 3) url-swap: id ok, url flagged, reason url_mismatch
introspect '
import json,sys
d=json.load(sys.stdin)["data"]
v={x["slug"]:x for x in d["violations"]}
e=v["url-swap"]
assert e["id_ok"] is True and e["url_ok"] is False, e
assert e["reason"]=="url_mismatch", e
' && green "PASS: swapped sources URL flagged url_mismatch (id intact)" \
  || { red "FAIL: url_mismatch not detected"; echo "$OUT"; errors=$((errors+1)); }

# 4) never-written: page_missing
introspect '
import json,sys
d=json.load(sys.stdin)["data"]
v={x["slug"]:x for x in d["violations"]}
e=v["never-written"]
assert e["reason"]=="page_missing", e
' && green "PASS: undispatched-on-disk slug reported page_missing" \
  || { red "FAIL: page_missing not detected"; echo "$OUT"; errors=$((errors+1)); }

# 5) norm-source NOT a violation (normalize_url absorbs slash/tracking diff)
introspect '
import json,sys
d=json.load(sys.stdin)["data"]
slugs={x["slug"] for x in d["violations"]}
assert "norm-source" not in slugs, slugs
' && green "PASS: trailing-slash/tracking-param diff does not false-flag" \
  || { red "FAIL: normalization false-flagged"; echo "$OUT"; errors=$((errors+1)); }

# 6) stdin dispatch (--dispatch -)
OUT_STDIN="$(cat "$DISPATCH" | python3 "$SCRIPT" sweep --wiki-root "$WIKI" --dispatch -)"
echo "$OUT_STDIN" | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert d["success"], d
assert d["data"]["checked"]==5, d["data"]["checked"]
' && green "PASS: --dispatch - reads the table from stdin" \
  || { red "FAIL: stdin dispatch broke"; echo "$OUT_STDIN"; errors=$((errors+1)); }

# --- content_hash leg (--knowledge-root, #421) -------------------------------
# A separate knowledge-root with its own wiki + fetch-cache, exercising the
# body-only cross-talk variant: id + sources URL match the dispatch record but
# the page's frontmatter content_hash diverges from the cached body's hash.
KR="$WORK/kr"
KR_WIKI="$KR"                       # wiki-root == knowledge-root here (allowed)
mkdir -p "$KR_WIKI/wiki/sources"   # fetch-cache.py store creates its own dir

# page with a content_hash: frontmatter line
write_page_ch() {  # $1=slug $2=id $3=url $4=content_hash
  cat > "$KR_WIKI/wiki/sources/$1.md" <<EOF
---
id: $2
title: "Page for $1"
type: source
created: 2026-01-01
updated: 2026-01-01
sources: ["$3"]
content_hash: "$4"
---

# Page for $1

Body long enough to clear any later stub threshold.
EOF
}

# Populate a fetch-cache entry through fetch-cache.py itself (black-box — the
# script owns the cache key + entry schema, so the test never re-derives them).
# The stored content_hash is derived from --body; echo it back for the caller.
FETCH_CACHE="$PLUGIN_ROOT/scripts/fetch-cache.py"
store_cache_entry() {  # $1=url $2=body  -> prints the stored content_hash
  python3 "$FETCH_CACHE" store --knowledge-root "$KR" --url "$1" \
    --fetch-method webfetch --status ok --body "$2" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["content_hash"])'
}

BODY="Body long enough to clear any later stub threshold."
FOREIGN_HASH="sha256:2222222222222222222222222222222222222222222222222222222222222222"

# ch-good: page hash == the cache entry's derived hash (positive)
CACHED_HASH="$(store_cache_entry "https://europa.eu/ch-good" "$BODY")"
write_page_ch ch-good ch-good "https://europa.eu/ch-good" "$CACHED_HASH"
# ch-bad: id + url match dispatch, but page content_hash is a sibling's
store_cache_entry "https://europa.eu/ch-bad" "$BODY" >/dev/null
write_page_ch ch-bad ch-bad "https://europa.eu/ch-bad" "$FOREIGN_HASH"
# ch-nocache: page has a hash but there is NO cache entry for its URL (miss)
write_page_ch ch-nocache ch-nocache "https://europa.eu/ch-nocache" "$FOREIGN_HASH"

CH_DISPATCH="$WORK/ch-dispatch.json"
cat > "$CH_DISPATCH" <<'EOF'
[
  {"slug": "ch-good", "url": "https://europa.eu/ch-good"},
  {"slug": "ch-bad", "url": "https://europa.eu/ch-bad"},
  {"slug": "ch-nocache", "url": "https://europa.eu/ch-nocache"}
]
EOF

# 7) with --knowledge-root: ch-bad is content_hash_mismatch; ch-good + ch-nocache ok
OUT_CH="$(python3 "$SCRIPT" sweep --wiki-root "$KR_WIKI" --knowledge-root "$KR" --dispatch "$CH_DISPATCH")"
echo "$OUT_CH" | python3 -c '
import json,sys
d=json.load(sys.stdin)["data"]
v={x["slug"]:x for x in d["violations"]}
# positive: matching hash -> ok, not a violation
assert "ch-good" in d["ok"], d
assert "ch-good" not in v, v
# mismatch: id+url ok but content_hash diverges
e=v["ch-bad"]
assert e["id_ok"] is True and e["url_ok"] is True, e
assert e["content_hash_ok"] is False, e
assert e["reason"]=="content_hash_mismatch", e
assert e["observed_content_hash"].endswith("2222"), e   # the foreign page hash
assert e["expected_content_hash"].startswith("sha256:"), e   # the cache-derived hash
assert e["expected_content_hash"] != e["observed_content_hash"], e
# cache miss: leg skips -> ok despite the foreign page hash
assert "ch-nocache" in d["ok"], d
assert "ch-nocache" not in v, v
' && green "PASS: content_hash leg flags body-only mismatch, skips on cache miss, passes on match" \
  || { red "FAIL: content_hash leg wrong"; echo "$OUT_CH"; errors=$((errors+1)); }

# 8) backwards compat: SAME wiki WITHOUT --knowledge-root -> content_hash ignored,
#    so ch-bad is no longer a violation (zero violations across the three pages).
OUT_NOKR="$(python3 "$SCRIPT" sweep --wiki-root "$KR_WIKI" --dispatch "$CH_DISPATCH")"
echo "$OUT_NOKR" | python3 -c '
import json,sys
d=json.load(sys.stdin)["data"]
assert d["violations"]==[], d["violations"]
assert set(d["ok"])=={"ch-good","ch-bad","ch-nocache"}, d["ok"]
' && green "PASS: no --knowledge-root -> content_hash leg off (today behavior)" \
  || { red "FAIL: backwards-compat broke"; echo "$OUT_NOKR"; errors=$((errors+1)); }

# --- excerpt-presence leg (--knowledge-root, grounding L1) --------------------
# The claim-level variant: id + sources URL + content_hash all conform, but a
# claim's excerpt_quote is absent from the page's cached source body (cross-wave
# attention cross-talk wrote one source's quote onto another's page). These
# pages carry pre_extracted_claims: and NO content_hash: line, so the id/url and
# (no-op) content_hash legs all pass and only the excerpt-presence leg fires.
write_page_ep() {  # $1=slug $2=url $3=claims-block (YAML under pre_extracted_claims:)
  cat > "$KR_WIKI/wiki/sources/$1.md" <<EOF
---
id: $1
title: "Page for $1"
type: source
created: 2026-01-01
updated: 2026-01-01
sources: ["$2"]
pre_extracted_claims:
$3
---

# Page for $1

The grounding surface is the cached source body, not this rendered body.
EOF
}

EP_BODY="Recital text. Article 6 designates certain AI systems as high-risk under Annex III of the Regulation."
GOOD_QUOTE="certain AI systems as high-risk"
BAD_QUOTE="this excerpt appears in no cached body"

GOOD_CLAIMS="  - id: clm-001
    text: \"AI Act high-risk classification\"
    excerpt_quote: \"$GOOD_QUOTE\""
BAD_CLAIMS="  - id: clm-001
    text: \"Claim grounded in the wrong body\"
    excerpt_quote: \"$BAD_QUOTE\""
PARTIAL_CLAIMS="  - id: clm-001
    text: \"Present claim\"
    excerpt_quote: \"$GOOD_QUOTE\"
  - id: clm-002
    text: \"Absent claim\"
    excerpt_quote: \"$BAD_QUOTE\""

# ep-good: single claim, excerpt present in cached body -> rate 1.0, ok
store_cache_entry "https://europa.eu/ep-good" "$EP_BODY" >/dev/null
write_page_ep ep-good "https://europa.eu/ep-good" "$GOOD_CLAIMS"
# ep-bad: single claim, excerpt absent -> rate 0.0, below-threshold violation
store_cache_entry "https://europa.eu/ep-bad" "$EP_BODY" >/dev/null
write_page_ep ep-bad "https://europa.eu/ep-bad" "$BAD_CLAIMS"
# ep-partial: 2 claims (1 present, 1 absent) -> rate 0.5, below default 0.95
store_cache_entry "https://europa.eu/ep-partial" "$EP_BODY" >/dev/null
write_page_ep ep-partial "https://europa.eu/ep-partial" "$PARTIAL_CLAIMS"
# ep-nocache: claim present-looking, but NO cache entry for its URL (miss) -> skip
write_page_ep ep-nocache "https://europa.eu/ep-nocache" "$GOOD_CLAIMS"

EP_DISPATCH="$WORK/ep-dispatch.json"
cat > "$EP_DISPATCH" <<'EOF'
[
  {"slug": "ep-good", "url": "https://europa.eu/ep-good"},
  {"slug": "ep-bad", "url": "https://europa.eu/ep-bad"},
  {"slug": "ep-partial", "url": "https://europa.eu/ep-partial"},
  {"slug": "ep-nocache", "url": "https://europa.eu/ep-nocache"}
]
EOF

# 9) excerpt-presence leg: ep-bad/ep-partial below threshold, ep-good/ep-nocache ok,
#    per-run aggregate rate emitted.
OUT_EP="$(python3 "$SCRIPT" sweep --wiki-root "$KR_WIKI" --knowledge-root "$KR" --dispatch "$EP_DISPATCH")"
echo "$OUT_EP" | python3 -c '
import json,sys
d=json.load(sys.stdin)["data"]
v={x["slug"]:x for x in d["violations"]}
# positive: every excerpt present -> ok
assert "ep-good" in d["ok"], d
assert "ep-good" not in v, v
# absent excerpt: id/url/content_hash ok but excerpt-presence fails
e=v["ep-bad"]
assert e["id_ok"] is True and e["url_ok"] is True and e["content_hash_ok"] is True, e
assert e["excerpt_presence_ok"] is False, e
assert e["reason"]=="excerpt_presence_below_threshold", e
assert e["excerpt_presence_rate"]==0.0, e
# partial: one of two excerpts present -> rate 0.5, below default 0.95
p=v["ep-partial"]
assert p["excerpt_presence_ok"] is False, p
assert abs(p["excerpt_presence_rate"]-0.5)<1e-9, p
assert p["reason"]=="excerpt_presence_below_threshold", p
# cache miss: leg skips -> ok despite the claim
assert "ep-nocache" in d["ok"], d
assert "ep-nocache" not in v, v
# per-run aggregate: present 1(good)+0(bad)+1(partial)=2 over 1+1+2=4 scored claims
assert abs(d["excerpt_presence_rate"]-0.5)<1e-9, d["excerpt_presence_rate"]
' && green "PASS: excerpt-presence leg flags absent/partial quotes, skips on cache miss, reports per-run rate" \
  || { red "FAIL: excerpt-presence leg wrong"; echo "$OUT_EP"; errors=$((errors+1)); }

# 10) --excerpt-threshold lowers the bar: ep-partial (0.5) now passes, ep-bad (0.0) still fails
OUT_EP_THR="$(python3 "$SCRIPT" sweep --wiki-root "$KR_WIKI" --knowledge-root "$KR" --excerpt-threshold 0.4 --dispatch "$EP_DISPATCH")"
echo "$OUT_EP_THR" | python3 -c '
import json,sys
d=json.load(sys.stdin)["data"]
slugs={x["slug"] for x in d["violations"]}
assert "ep-partial" not in slugs, slugs        # 0.5 >= 0.4 now ok
assert "ep-partial" in d["ok"], d
assert "ep-bad" in slugs, slugs                # 0.0 < 0.4 still fails
assert "ep-good" in d["ok"], d
' && green "PASS: --excerpt-threshold tunes the gate (0.4 passes the 0.5 page, fails the 0.0 page)" \
  || { red "FAIL: --excerpt-threshold not honored"; echo "$OUT_EP_THR"; errors=$((errors+1)); }

# 11) backwards compat: WITHOUT --knowledge-root the excerpt leg is off, so the
#     ep pages (id+url match, no content_hash) report zero violations and a null rate.
OUT_EP_NOKR="$(python3 "$SCRIPT" sweep --wiki-root "$KR_WIKI" --dispatch "$EP_DISPATCH")"
echo "$OUT_EP_NOKR" | python3 -c '
import json,sys
d=json.load(sys.stdin)["data"]
assert d["violations"]==[], d["violations"]
assert set(d["ok"])=={"ep-good","ep-bad","ep-partial","ep-nocache"}, d["ok"]
assert d["excerpt_presence_rate"] is None, d["excerpt_presence_rate"]
' && green "PASS: no --knowledge-root -> excerpt leg off, rate null (today behavior)" \
  || { red "FAIL: excerpt backwards-compat broke"; echo "$OUT_EP_NOKR"; errors=$((errors+1)); }

if [ "$errors" -eq 0 ]; then
  green "ALL TESTS PASS"
  exit 0
else
  red "$errors test(s) FAILED"
  exit 1
fi
