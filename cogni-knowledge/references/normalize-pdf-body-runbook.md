# Runbook: enabling `--normalize-pdf-body` on an existing base

`--normalize-pdf-body` is an opt-in toggle that makes the PDF text-layer fallback
(`scripts/pdf-extract.py`) store a *cleaned* body — NFKC-folding ligatures, mapping
smart quotes/dashes to ASCII, and rejoining hyphenated column-wrap breaks. It is
surfaced as a flag on `knowledge-curate` and `knowledge-ingest-source` (threaded as
`NORMALIZE_PDF_BODY` to `source-curator`). Default **off**: when the flag is absent
the stored body and its `content_hash:` stay byte-identical to today.

On a **fresh** base the flag is safe from day one — there are no pre-existing cache
entries to diverge from. This runbook is only for the **existing-base** case, where
PDFs were already fetched and stored with the raw (un-normalized) body.

## The hazard

The fetch-cache is content-addressed by URL: one entry per URL at
`<knowledge-root>/.cogni-knowledge/fetch-cache/<sha256-of-url>.json`, carrying the
extracted `body` and its `content_hash`. `fetch-cache.py fetch` **short-circuits on a
cache hit** — it returns the cached body without re-extracting.

Two consequences follow when you flip `--normalize-pdf-body` on an existing base:

1. **A re-ingest alone does nothing.** The next curate/ingest run hits the cached
   *raw* body and returns it unchanged. The normalization runs only inside
   `pdf-extract.py` at *extract* time, which is skipped on a cache hit — so the
   normalized body never lands until the cached entry is removed.
2. **`content_hash` divergence.** A normalized body hashes differently from the raw
   one. Each `wiki/sources/<slug>.md` page records the `content_hash:` it was
   ingested with. The Step 3.5 post-wave integrity sweep
   (`scripts/ingest-integrity.py sweep --knowledge-root …`) asserts each page's
   `content_hash:` equals the fetch-cache entry's `content_hash` for that URL
   (the `content_hash` leg, reason `content_hash_mismatch`). So the cached entry
   and the page must be regenerated **together** — evict, re-fetch (normalized),
   re-ingest — or they will disagree. (The leg is fail-safe: a cache miss or empty
   hash on either side skips it, never a false positive — but the right fix is to
   keep both sides consistent, not to rely on the skip.)

## The eviction interface (what actually exists)

`fetch-cache.py` evicts **by age only** — there is no per-URL `evict` and no
per-reason `evict` (per-reason is an explicit future enhancement noted in
[`fetch-cache-design.md`](fetch-cache-design.md), not shipped). The available knobs:

| Command | What it does |
|---|---|
| `fetch-cache.py stat --knowledge-root <root>` | Cache-wide summary (entry count, ages). Start here. |
| `fetch-cache.py key --url <URL> --bare` | Prints `sha256(<URL>)` — the entry's filename stem under `.cogni-knowledge/fetch-cache/`. Use this to locate (and hand-delete) a single entry. |
| `fetch-cache.py evict --knowledge-root <root> --older-than-days <N> [--dry-run]` | Removes every entry older than `N` days. `--older-than-days 0` clears the whole cache. `--dry-run` previews without deleting. |

## Procedure

Pick **surgical** (a few known PDF URLs) or **full reset** (small base / simplest).

### Option A — surgical, per-URL (preferred when you know the PDF URLs)

```bash
KROOT=<path-to-knowledge-base-root>   # the dir holding .cogni-knowledge/

# 1. Locate the entry file for each affected PDF URL.
STEM=$(python3 cogni-knowledge/scripts/fetch-cache.py key --url "<PDF_URL>" --bare)
ENTRY="$KROOT/.cogni-knowledge/fetch-cache/$STEM.json"

# 2. (Optional) confirm it is the PDF you expect before removing.
python3 -c "import json;e=json.load(open('$ENTRY'));print(e['url'],e.get('fetch_method'),e.get('content_hash'))"

# 3. Remove the entry so the next fetch re-extracts with normalization on.
rm "$ENTRY"
```

Repeat for each affected PDF URL.

### Option B — full reset (simplest; re-fetches the whole base)

```bash
# Preview first.
python3 cogni-knowledge/scripts/fetch-cache.py evict --knowledge-root "$KROOT" --older-than-days 0 --dry-run
# Then clear all entries.
python3 cogni-knowledge/scripts/fetch-cache.py evict --knowledge-root "$KROOT" --older-than-days 0
```

This evicts non-PDF entries too, so the next run re-fetches everything — fine for a
small base, wasteful for a large one (prefer Option A there).

### Then enable and re-ingest

```bash
# Re-curate (re-fetches the evicted URLs; PDFs now store the normalized body) …
/cogni-knowledge:knowledge-curate <project> --normalize-pdf-body
# … or, for a single hand-added source:
/cogni-knowledge:knowledge-ingest-source <project> --normalize-pdf-body

# Re-ingest to rewrite the affected wiki/sources/<slug>.md pages with the new content_hash.
/cogni-knowledge:knowledge-ingest <project>
```

The Step 3.5 integrity sweep runs inside `knowledge-ingest`; a clean run (no
`content_hash_mismatch`) confirms each page's `content_hash:` matches its
freshly-stored normalized cache entry.

## Verification

- `fetch-cache.py stat --knowledge-root "$KROOT"` shows the evicted entries gone (then
  repopulated after the re-curate).
- The re-ingest summary reports **no** `integrity_mismatch` skips
  (`reason: content_hash_mismatch` in particular).
- Spot-check an affected `wiki/sources/<slug>.md`: its `content_hash:` matches the
  cache entry for the same URL (`fetch-cache.py fetch --knowledge-root "$KROOT" --url
  "<PDF_URL>"` reports the same hash).

## Leaving it off

Doing nothing is safe. With the flag off, the cache and pages stay byte-identical to
today; this runbook is only needed when you deliberately want the cleaned body on a
base whose PDFs predate the toggle.
