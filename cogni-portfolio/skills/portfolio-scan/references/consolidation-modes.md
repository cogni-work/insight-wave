# Scan Consolidation Modes

The scan produces a structured research report (Phase 6) regardless of mode. What differs is **what Phase 7 does with the discovered offerings** — whether they enter the portfolio's `features/` set immediately, get staged for later review, or are left as a report only.

Three modes, selected at Phase 0 via `AskUserQuestion`, persisted into `research/.metadata/scan-output.json` as `consolidation_mode`.

## Why modes exist

Before v1.3.0 the scan always ran Phase 7 — every scan wrote/merged `features/*.json`. That is the right default when you are scanning your **own** company, because the whole point is to refresh the feature set. It is the wrong default when:

- **Scanning a competitor** — competitor offerings must not silently enter your feature set, not even with lineage annotations. A competitor's "Managed Kubernetes" is not your feature.
- **Scanning a partner, reference provider, or prospect** — you want the structured view for comparison or account planning, but the features are not yours to own.
- **Re-scanning your own company in review-mode** — you want to see what the scan proposes before it mutates curated, human-edited features.

The mode toggle lets the same scan pipeline serve all of these cases by deferring (or skipping) the write step rather than duplicating the entire skill.

## The three modes

| Mode | Phase 7 runs? | `features/*.json` touched? | Output beyond the report |
|---|---|---|---|
| `consolidate` *(default)* | Yes — full 7.1–7.7 | Yes — merges and new writes | Updated `features/`, `products/` if new dimensions, enriched `scan-output.json.dedupe_summary` and `provider_units[].feature_count` |
| `shadow` | Partial — 7.1, 7.2-light, modified 7.3 only | **No** | Candidate JSON files under `research/scan-candidates/{COMPANY_SLUG}/` |
| `research-only` | **No** — skipped entirely | No | Nothing beyond the Phase 6 report + metadata |

### `consolidate`

Today's behaviour. Use when the scan target is the portfolio's own company and you want the feature set to reflect the scan findings. Dedupe agent runs, user confirms merges/creates, features and (if needed) products are written.

### `shadow`

Phase 7 maps offerings into the same feature JSON shape but writes them to a parallel staging area — `research/scan-candidates/{COMPANY_SLUG}/{slug}.json` — instead of `features/`. No dedupe agent runs. `portfolio.json` is not updated. `products/` is not created.

This gives a reviewable "what would scan propose?" artifact without mutating curated state. The human-in-the-loop promotion step (a future addition to the `features` skill) reads the shadow directory, runs dedupe against current `features/`, and lets the user pull selected candidates into the real set on demand.

Shadow candidate file shape — a normal feature JSON plus two diagnostic fields:

```json
{
  "slug": "aws-managed-services",
  "product_slug": "cloud-services",
  "name": "AWS Managed Services",
  "purpose": "Operate AWS workloads end-to-end for regulated enterprises",
  "description": "...",
  "taxonomy_mapping": {
    "dimension": 4,
    "dimension_name": "Cloud Services",
    "category_id": "4.1",
    "category_name": "Managed Hyperscaler Services",
    "horizon": "current"
  },
  "readiness": "ga",
  "source_file": "research/{COMPANY_SLUG}-portfolio.md",
  "created": "2026-04-22",
  "_shadow_candidate": true,
  "_source_offering": {
    "domain": "t-systems.com",
    "link": "https://www.t-systems.com/...",
    "usp": "BSI C5-attested AWS operations with German data residency"
  }
}
```

The `_shadow_candidate` marker and `_source_offering` block are stripped when a candidate is later promoted into `features/`.

### `research-only`

Phase 7 is skipped. The Phase 6 report and `scan-output.json` metadata are the complete output. Use when the scan target is a competitor, a prospect, or any non-self entity whose capabilities must never enter the portfolio's `features/`.

The `scan-output.json` remains useful — `status_summary` and the per-domain structure are the canonical inputs to the future `portfolio-consolidate` skill, which rolls up N research-only scans into a taxonomy-shaped coverage matrix across providers.

## Choosing a default

The skill prompts the user explicitly rather than heuristically guessing from the company slug. Keep the default as `consolidate` so v1.2.0 behaviour is preserved for any caller (including `portfolio-setup`) that does not pass a mode through.

Callers that know the scan target is not the portfolio owner should pass `consolidation_mode: "research-only"` (or `"shadow"`) explicitly to avoid the prompt and the default.

## Forward compatibility

The `dedupe_summary` block in `scan-output.json` remains present in every mode (for schema stability) but only carries meaningful counts under `consolidate`. Under `shadow` and `research-only` the counters are all zero by convention — a filesystem count of `research/scan-candidates/{COMPANY_SLUG}/` gives the shadow candidate total; `research-only` has no candidate artifact at all.

`provider_units[].feature_count` is likewise only meaningful under `consolidate`. Under the other two modes the skeleton written at Phase 1.5 stands without enrichment, which dashboards must treat as "not measured", not as "zero".
