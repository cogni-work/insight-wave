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

if [ "$errors" -eq 0 ]; then
  green "ALL TESTS PASS"
  exit 0
else
  red "$errors test(s) FAILED"
  exit 1
fi
