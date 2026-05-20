# Fetch cache design

The fetch cache is the single mechanism that solves the dual-fetch problem identified in the Phase 4 alpha. Every URL the inverted pipeline touches goes through it; nothing reaches the wiki or the writer without a cache entry.

## Where it lives

```
<knowledge-root>/.cogni-knowledge/fetch-cache/
└── <sha256-of-url>.json     # one file per URL, content-addressed by URL
```

One canonical cache per knowledge base, shared across all projects under that base. A second `knowledge-research` on a related topic that pulls the same URL gets a free hit.

## Cache entry shape

```json
{
  "schema_version": "0.1.0",
  "url": "https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689",
  "fetched_at": "2026-05-20T14:31:02Z",
  "content_hash": "sha256:<hex>",
  "fetch_method": "webfetch",
  "status": "ok",
  "body": "<full text of the page, as fetched>",
  "publisher": "europa.eu",
  "http_status": 200,
  "etag": "...",
  "last_modified": "..."
}
```

`fetch_method ∈ {webfetch, cobrowse_interactive}`. These are the exact two values cogni-claims uses (`cogni-claims/CLAUDE.md:109`, `skills/claims/SKILL.md:317`) — kept aligned so a future shared verifier can read either cache's entries without translation. Adding a new value here requires an additive coordinated change in cogni-claims.

`status ∈ {ok, unavailable}`. An unavailable entry is recorded for negative caching — repeated fetches against a known-dead URL within the freshness window short-circuit to the cached `unavailable` verdict.

## Cache-key choice: URL, not content

The cache is addressed by `sha256(url)`, not `sha256(body)`. Two reasons:

1. **Idempotency by URL.** When the same URL appears across projects (or twice in one project after a curate re-run), the second lookup hits the cache. A content-addressed cache would store both versions if the body changed even slightly.
2. **Freshness.** Cache invalidation is a function of `fetched_at`, not body content. A page that's been edited but not re-fetched still serves from cache; a re-fetch overwrites the entry.

## Freshness window

Default 30 days, configurable per knowledge base in `binding.json`:

```json
{
  "curator_defaults": {
    "fetch_cache_max_age_days": 30,
    "max_candidates_per_sq": 12,
    "score_threshold": 0.5
  }
}
```

`knowledge-fetch` checks `fetched_at` against the window before reusing. Outside the window → re-fetch; inside → reuse.

## Eviction

`fetch-cache.py --evict --older-than-days N` removes entries older than N days. Run manually (or wired into a `knowledge-refresh --vacuum` future enhancement). v0.1.0 does not auto-evict.

## Negative-cache retention

Entries with `status: unavailable` age out under the same `--older-than-days` rule as `status: ok` entries. This is deliberate — a URL that was unreachable 30 days ago should be re-attempted, since transient outages, paywalled-then-opened pages, and corporate redirects often recover. The trade-off is repeated cobrowse prompts for genuinely-dead URLs (an unavailable entry inside the freshness window will short-circuit; outside it, a fresh fetch attempt fires).

If a future use case wants asymmetric retention (e.g. keep `unavailable` longer than `ok`), the `--older-than-days` flag can grow a per-status variant (`--ok-older-than-days`, `--unavailable-older-than-days`). v0.1.0 keeps the single knob to match operator expectations.

## What is NOT cached

- Per-project research metadata (`plan.json`, `candidates.json`, `fetch-manifest.json`) — those are project-scoped and live under `<project>/.metadata/`.
- Wiki pages — those live in the wiki and are the system of record for source content after Phase 4. The cache is the fetch layer; the wiki is the substrate.

## Concurrency

`fetch-cache.py write` uses temp-file + `os.replace` per entry. Two parallel writers to the same `<sha256>.json` are safe — the loser's bytes are atomically replaced by the winner's. There is no file lock because URL hashes are independent; collisions across distinct URLs are cryptographically impossible at this scale.

## Relationship to cogni-claims' source cache

cogni-claims has its own URL→body cache at `cogni-claims/sources/{url-hash}.json` (`cogni-claims/skills/claims/scripts/claims-store.sh:48-50`). Two deliberate differences:

| | cogni-claims | cogni-knowledge fetch-cache |
|---|---|---|
| Cache key | First 16 chars of sha256(url) | Full 64 chars of sha256(url) |
| Lifecycle | Per-workspace | Per knowledge base |
| Schema for `fetch_method` | `webfetch` / `cobrowse_interactive` | identical |

The 64-char key was chosen because at scale (10k+ URLs across a long-lived knowledge base) the 16-char truncation has nontrivial collision risk. The two caches do not share storage — they have different lifecycles — but the `fetch_method` vocabulary is kept identical so a future absorbed verifier can interpret either format consistently. When cogni-claims is absorbed at v1.0, the truncated keys are the loose end to reconcile (widen cogni-claims to 64 chars, or accept that legacy 16-char entries lose addressability).

## Why not put this upstream in cogni-wiki?

cogni-wiki's `wiki-ingest` already has a notion of "raw" sources, but it's keyed on filesystem layout (`raw/<slug>/`), not URL. The fetch-cache is purely a URL→body lookup with no wiki semantics — putting it in cogni-wiki would conflate two unrelated concerns. The cache lives in cogni-knowledge because cogni-knowledge owns the fetch policy (when to re-fetch, when to fall back to cobrowse, when to mark unavailable).

A future cogni-wiki version might learn to read this cache when ingesting a URL the user pastes. That's a v0.2+ coordination, not a v0.1.0 prerequisite.
