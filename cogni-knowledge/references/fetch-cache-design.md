# Fetch cache design

The fetch cache is the single mechanism that solves the dual-fetch problem identified in the Phase 4 alpha. Every URL the inverted pipeline touches goes through it; nothing reaches the wiki or the writer without a cache entry.

## Where it lives

```
<knowledge-root>/.cogni-knowledge/fetch-cache/
└── <sha256-of-url>.json     # one file per URL, content-addressed by URL
```

One canonical cache per knowledge base, shared across all projects under that base. A second knowledge run on a related topic that pulls the same URL gets a free hit.

## Cache entry shape

```json
{
  "schema_version": "0.1.0",
  "url": "https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689",
  "fetched_at": "2026-05-20T14:31:02Z",
  "content_hash": "sha256:<hex>",
  "fetch_method": "webfetch",
  "status": "ok",
  "body": "<body as returned by WebFetch — a summarized/extracted representation, typically 300-1200 words, not the full HTML source>",
  "publisher": "europa.eu",
  "http_status": 200,
  "etag": "...",
  "last_modified": "..."
}
```

`fetch_method ∈ {webfetch, webfetch_fulltext, cobrowse_interactive, direct}`. `webfetch` / `cobrowse_interactive` are kept aligned with cogni-claims (`cogni-claims/CLAUDE.md:111`, `skills/claims/SKILL.md`) so a future shared verifier can read either cache's entries without translation; `webfetch_fulltext` and `direct` are additionally documented on the cogni-claims side as recognized-but-never-emitted (cogni-claims has neither a fuller-body fetch nor a local-ingest path). Adding a value here is an additive cross-plugin contract change, mirrored in the cogni-claims prose.

**`direct` — non-web sources.** `webfetch` and `cobrowse_interactive` are the two web-fetch outcomes (an automated `WebFetch`, or an interactive Claude-in-Chrome recovery). `direct` records a source whose bytes are already in hand and were never fetched over the network — a local file (`.docx`/`.html`/`.txt`), pasted text, a local PDF, or a local interview note. It is the honest provenance value for `knowledge-ingest-source`'s local-input path. A `direct` entry is always `status: ok` (the body exists by definition), so it never carries a `webfetch_*`/negative-cache `reason` — the negative-cache machinery is web-only.

`status ∈ {ok, unavailable}`. An unavailable entry is recorded for negative caching — repeated fetches against a known-dead URL within the freshness window short-circuit to the cached `unavailable` verdict. `direct` entries are never `unavailable`.

## Body fidelity and grounding contract

The cached `body` for a `webfetch` entry is **the value WebFetch returns — a tool-generated extract of the page, not its full HTML source**. WebFetch summarizes and truncates: in practice an `ok` body is typically 300–1200 words, even when the underlying document is a 40+-page PDF or a long regulatory text. This is the deliberate, documented grounding contract, not a defect in the cache: `fetch-cache.py store` is a body-agnostic pass-through (it stores exactly the string it is handed), and `source-curator` (Phase 2) hands it the raw WebFetch return. The cache neither summarizes nor re-fetches.

Everything downstream grounds on this extract:

- **claim extraction** (`source-ingester` → `claim-extractor`, Phase 4) reads the cached body to populate `pre_extracted_claims:`;
- **composition** (`wiki-composer`, Phase 5) cites those claims;
- **verification** (`wiki-verifier`, Phase 6) scores citations against them.

For the large majority of sources this is sufficient — WebFetch returns the page's primary informational content, and the wiki **compounds** claims across runs and across sources (see [`differentiation-thesis.md` §"The compounding loop"](differentiation-thesis.md)), so a single source's extract is rarely the whole evidentiary picture for a synthesis. The deliberate trade-off: a source ingested once contributes its extracted claims to the wiki for every future run, rather than being re-fetched in full each time.

The documented limitation: for **high-authority `primary`-tier sources** — legal normative text, dense regulatory annexes, multi-page statutes — the WebFetch extract may omit sections, which bounds claim-extraction completeness and is a real (documented) correctness consideration: a claim extracted from an extract may miss nuance present only in the omitted full text.

A **fuller-body capture path** for `primary`-tier sources is the dedicated-full-text-`fetch_method` mechanism, now shipped: when `source-curator` (Phase 2) stores a `primary`-tier candidate whose standard `webfetch` extract is below ~1000 words, it issues a second, deeper `WebFetch` for the same URL asking for the complete verbatim section/annex text and — **only if the second body is materially longer** — stores it under `fetch_method: webfetch_fulltext` (status `ok`), superseding the standard `webfetch` entry. A shorter/identical/empty/failed second fetch keeps the standard body unchanged (fail-safe — the path never degrades the standard result), and a candidate whose first body already clears the floor, or any non-`primary` candidate, skips the second fetch entirely so the added per-fetch cost is bound to exactly the sources that need it. Everything downstream is `fetch_method`-agnostic (claim extraction / composition / verification read `body` regardless of method), so a `webfetch_fulltext` body simply gives the claim extractor a fuller source to ground on. The complementary **interactive cobrowse** mechanism for primary-tier survivors (a different tool surface, with session interactivity) remains a deferred alternative, pursued only if `webfetch_fulltext` proves insufficient on primary sources.

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

## Reason semantics

Unavailable entries carry a closed-vocabulary `reason` token. Since v0.0.29 (Option B, #292) the **`source-curator` (Phase 2) is the primary cache writer** — it writes every positive `ok` entry and the `webfetch_*` / `pdf_extraction_failed` negative entries during its Phase-4 fetch. The cobrowse-only `source-fetcher` (Phase 3, opt-in) writes only the cobrowse outcomes (`cobrowse_interactive` positives that overwrite a curator negative entry, or `cobrowse_unavailable` / `cobrowse_failed` negatives). `knowledge-fetch`'s summary aggregates the tokens; `source-ingester` reads them when a cached entry has `status: unavailable` to decide whether to skip or retry. The reason vocabulary itself is unchanged. The full list, with semantics:

| Token | Class | Semantics |
|---|---|---|
| `webfetch_timeout` | recoverable | WebFetch exceeded its internal deadline. Typically transient — re-fetch outside the freshness window usually succeeds. |
| `webfetch_4xx` | terminal-ish | Server returned 4xx. 404 is terminal (page is gone); 401/403 may recover with proper auth, but cogni-knowledge does not handle auth. |
| `webfetch_5xx` | recoverable | Server returned 5xx (502 / 503 / 504). Often transient infrastructure flap — see F17 (EC-portal 502s during the M4 smoke window). |
| `webfetch_blocked` | terminal | Robots, geo-fence, or anti-bot policy refused the fetch. Negative cache prevents wasted retries. |
| `webfetch_refused` | terminal-ish | Transport-level failure: connection refused, DNS, unsupported scheme. Catch-all for anything Step 2 cannot classify. |
| `webfetch_empty_body` | recoverable | WebFetch returned HTTP 200 but the body was empty or whitespace-only. The server acknowledged the request yet served no extractable content — typically a JS-rendered page, a soft-paywall, or a login redirect that returns 200 with a blank shell. Recorded at fetch time (Phase 2) rather than surfacing late at ingest (Phase 4), so the curate/fetch counts stay accurate. `cobrowse_eligible: true` — a real browser rendering the page is exactly the recovery path for this case. |
| `pdf_extraction_failed` | terminal-for-now | Step 2's PDF branch ran but WebFetch surfaced **no saved-file path** in its output (the EUR-Lex case — an ELI/landing URL served a summary, not the PDF binary), so the Read tool was never reached. Cobrowse is not a viable fallback — browsers download PDFs rather than render text — so Step 3 is skipped on this reason. This token means specifically "we never got a PDF file to read", NOT "the Read tool failed to render a file we did get" (that is `pdf_render_unavailable`). v0.0.20+, issue #275. A future native-PDF-text WebFetch feature would invalidate the "terminal" classification. |
| `pdf_render_unavailable` | environmental | A saved PDF file **was** surfaced, but neither path could recover usable text: the **Read tool could not render it** in this runtime (its page→image rasterization has no PDF-rendering support here — e.g. the Claude Code build shells out to a local rasterizer that is absent) **and** the pure-Python text-layer fallback (`scripts/pdf-extract.py`, using the optional `pypdf` dependency — host or `COGNI_WORKSPACE_PYTHON_VENV` workspace venv) could not recover a usable text layer. `fallback_attempted` is **conditional**: `false` when `pypdf` (an **optional, not-shipped** recovery dependency) is absent (`reason: pypdf_unavailable` — provision it via `/cogni-workspace:manage-workspace` or `pip install pypdf`), `true` when the extractor ran but the PDF is genuinely image-only / scanned (`reason: no_text_layer`). Operator-actionable, NOT URL-fatal — provision pypdf, or re-run where the Read tool can render the pages, as `cobrowse_unavailable` says "install the MCP and re-run". A PDF that **does** carry a text layer no longer lands here: the curator extracts it (when pypdf is available) and stores it `--status ok` with `fetch.pdf_text_extracted: true`. Cobrowse still cannot render PDF text, so `cobrowse_eligible: false`. Issues #458 / #583. |
| `cobrowse_unavailable` | environmental | Step 3 was not attempted because the `claude-in-chrome` MCP server is absent from the runtime tool list. `fallback_attempted: false`. Distinct from `cobrowse_failed` so an operator can see "install the MCP and re-run" separately from "actually dead". v0.0.20+, issue #276 (F14). |
| `cobrowse_failed` | terminal | Cobrowse was attempted (MCP available) but the page did not render — navigation error, timeout, or blank text. `fallback_attempted: true`. Likely terminal: a page that does not render in a real browser will not render on retry. |

Two practical consequences:

- **Negative-cache value is highest for terminal reasons** (`webfetch_blocked`, `cobrowse_failed`). Re-attempting them inside the freshness window burns budget; the negative cache is exactly the short-circuit. Recoverable reasons (`webfetch_timeout`, `webfetch_5xx`) age out under the same window and re-attempt naturally.
- **`cobrowse_unavailable` is operator-actionable, not URL-fatal.** Installing the MCP and re-running will resolve every URL that recorded this reason (subject to its underlying page still being reachable). `knowledge-fetch`'s `fetch-cache.py evict --reason cobrowse_unavailable` is a clean follow-up if the vocabulary grows complex enough to want per-reason eviction (out of scope at v0.0.20).

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
| Schema for `fetch_method` | `webfetch` / `cobrowse_interactive` | superset: adds `direct` |

The 64-char key was chosen because at scale (10k+ URLs across a long-lived knowledge base) the 16-char truncation has nontrivial collision risk. The two caches do not share storage — they have different lifecycles — but the **shared** `fetch_method` web values (`webfetch` / `cobrowse_interactive`) are kept identical so a future absorbed verifier can interpret either format consistently. cogni-knowledge additionally writes `direct` for non-web (local) sources, which cogni-claims — a web-source verifier with no local-ingest path — never emits; the value is documented on the cogni-claims side so an absorbed verifier recognizes it rather than treating it as unknown. When cogni-claims is absorbed at v1.0, the truncated keys are the loose end to reconcile (widen cogni-claims to 64 chars, or accept that legacy 16-char entries lose addressability).

## Why not put this upstream in cogni-wiki?

cogni-wiki's `wiki-ingest` already has a notion of "raw" sources, but it's keyed on filesystem layout (`raw/<slug>/`), not URL. The fetch-cache is purely a URL→body lookup with no wiki semantics — putting it in cogni-wiki would conflate two unrelated concerns. The cache lives in cogni-knowledge because cogni-knowledge owns the fetch policy (when to re-fetch, when to fall back to cobrowse, when to mark unavailable).

A future cogni-wiki version might learn to read this cache when ingesting a URL the user pastes. That's a v0.2+ coordination, not a v0.1.0 prerequisite.
