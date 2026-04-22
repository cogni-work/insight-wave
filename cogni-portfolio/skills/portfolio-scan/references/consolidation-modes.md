# Scan Consolidation Modes

The scan produces a structured research report (Phase 6) regardless of mode. What differs is **what Phase 7 does with the discovered offerings** — whether they enter the portfolio's `features/` set immediately, get staged for later review, are left as a report only, or are rolled up into a taxonomy-shaped feature grid with per-stack delivery detail pushed into the solution layer.

Four modes, selected at Phase 0 via `AskUserQuestion`, persisted into `research/.metadata/scan-output.json` as `consolidation_mode`.

## Why modes exist

Before v1.3.0 the scan always ran Phase 7 — every scan wrote/merged `features/*.json`. That is the right default when you are scanning your **own** company, because the whole point is to refresh the feature set. It is the wrong default when:

- **Scanning a competitor** — competitor offerings must not silently enter your feature set, not even with lineage annotations. A competitor's "Managed Kubernetes" is not your feature.
- **Scanning a partner, reference provider, or prospect** — you want the structured view for comparison or account planning, but the features are not yours to own.
- **Re-scanning your own company in review-mode** — you want to see what the scan proposes before it mutates curated, human-edited features.

The mode toggle lets the same scan pipeline serve all of these cases by deferring (or skipping) the write step rather than duplicating the entire skill.

## The four modes

| Mode | Phase 7 runs? | `features/*.json` touched? | Output beyond the report |
|---|---|---|---|
| `consolidate` *(default)* | Yes — full 7.1–7.7 | Yes — merges and new writes | Updated `features/`, `products/` if new dimensions, enriched `scan-output.json.dedupe_summary` and `provider_units[].feature_count` |
| `shadow` | Partial — 7.1, 7.2-light, modified 7.3 only | **No** | Candidate JSON files under `research/scan-candidates/{COMPANY_SLUG}/` |
| `research-only` | **No** — skipped entirely | No | Nothing beyond the Phase 6 report + metadata |
| `category-aggregation` | Yes — 7.1, 7.2, 7.3, 7.6 Branch F, 7.7 (skips 7.4–7.5 dedupe) | Yes — one write per populated taxonomy category | Category-grained `features/` (≤57 for b2b-ict), plus `research/scan-solutions-draft.json` listing per-stack delivery seeds for `solutions/` to bootstrap |

### `consolidate`

Today's behaviour. Use when the scan target is the portfolio's own company and you want the feature set to reflect the scan findings. Dedupe agent runs, user confirms merges/creates, features and (if needed) products are written.

### `shadow`

Phase 7 maps offerings into the same feature JSON shape but writes them to a parallel staging area — `research/scan-candidates/{COMPANY_SLUG}/{slug}.json` — instead of `features/`. No dedupe agent runs. `portfolio.json` is not updated. `products/` is not created.

This gives a reviewable "what would scan propose?" artifact without mutating curated state. The human-in-the-loop promotion step lives in the `features` skill's **Promote Shadow Candidates** operation (see `cogni-portfolio/skills/features/references/promote-shadow.md`): it lists the shadow directory, lets the user pick one or many candidates, strips the two diagnostic fields, writes to `features/{slug}.json`, dispatches `feature-deduplication-detector` in candidate mode so new features compete with existing ones fairly, and either deletes or archives the original.

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

### `category-aggregation`

Phase 7 runs Steps 7.1 and 7.2 as usual, stages candidates in Step 7.3, **skips Steps 7.4 and 7.5** (no per-offering dedupe agent — aggregation by taxonomy category supersedes per-offering similarity), then runs Step 7.6 **Branch F** (the whole-dataset aggregation write path) and Step 7.7 (taxonomy update in `portfolio.json`). Instead of writing one feature per discovered offering, this mode groups the staged candidates by `taxonomy_mapping.category_id` and writes **one category-grained feature per populated category** — bounded by the taxonomy shape (≤57 features for b2b-ict rather than a per-offering sprawl).

Use when the scan is serving **consolidation or benchmarking** rather than proposition/differentiation workflows. Typical signals:

- Scanning a provider (or the portfolio's own company in a consolidation pass) where the user expects the feature grid to mirror the 8×57 taxonomy rather than each granular offering.
- Follow-up passes where a prior `consolidate` scan produced more features than dashboards can meaningfully navigate, and the user wants the offering-grained detail preserved but pushed into the solution layer.
- Benchmarking setup where features must align to taxonomy categories so cross-provider coverage matrices (via `portfolio-consolidate`) are directly comparable.

**Why the feature is category-grained and not offering-grained:** buyers evaluate delivery stacks at the proposition / solution level, not the feature level. A single feature "Sovereign Cloud IaaS" has legitimate delivery variants (OTC, AWS Frankfurt, GCP Frankfurt, on-prem) with different sovereignty guarantees, compliance postures, and pricing — but those are all the same *capability* at the IS layer. Keeping the feature capability-shaped and pushing the delivery variants into `solutions/` mirrors how buyers and sales actually reason about the portfolio.

**What is preserved and where:**

| Dimension of the offering | In `consolidate` mode | In `category-aggregation` mode |
|---|---|---|
| Capability / IS layer | Per-offering feature | Category-grained feature |
| Delivery stack (provider, region, cloud, on-prem) | Feature-level field or separate features | Solution-level — written to `research/scan-solutions-draft.json` for `solutions/` to seed |
| Compliance posture / certifications | Feature fields | Solution-level (follow-on, see "Forward compatibility") |
| Pricing & commercial terms | Solution-level (unchanged) | Solution-level (unchanged) |
| Source lineage (scan link, USP) | `source_lineage` per feature | `source_lineage` per category-grained feature (one entry per absorbed offering with `entity_role: "aggregated_from"`) |

**Delivery-stack artifact.** Phase 7.6 Branch F emits `research/scan-solutions-draft.json` (written at the stable `research/` path, not under `.staging/`, so the file survives the post-write staging sweep). An array with one element per category-grained feature, each containing a `delivery_stacks[]` list of the provider-level seeds drawn from the staged candidates' `_source_offering` blocks. Schema:

```json
[
  {
    "category_id": "4.1",
    "category_name": "Managed Hyperscaler Services",
    "feature_slug": "sovereign-cloud-iaas",
    "delivery_stacks": [
      {
        "domain": "t-systems.com",
        "provider_unit": "T-Systems International",
        "link": "https://www.t-systems.com/.../otc",
        "usp": "BSI C5-attested, German data residency",
        "delivery_stack": "open-telekom-cloud"
      }
    ]
  }
]
```

The artifact is **persistent across scan sessions** — it lives at the stable `research/` path (not `.staging/`) specifically so the `solutions/` skill's forthcoming seed-from-scan-draft entry point can read it in a later session, not just within the scan run that produced it. Once `solutions/` has seeded the per-stack solution entities, the artifact is fair game to delete, but scan itself will not remove it. Until the seed-from-scan-draft entry point lands (tracked as follow-on work), the artifact is diagnostic: inspect with `cat` to see what per-stack seeds the scan proposes, and bootstrap solution entities manually if needed.

**How it differs from `consolidate`:**

- `consolidate` writes per-offering features and runs the dedupe agent to merge near-duplicates across providers. `category-aggregation` writes per-category features and skips the dedupe agent entirely — aggregation by taxonomy is a stricter collapse than similarity-based merging.
- `consolidate`'s feature count varies with the scan target (229 offerings → 215 features on a T-Systems scan). `category-aggregation`'s feature count is bounded by the taxonomy shape (≤57 for b2b-ict), regardless of how many offerings the scan discovered.
- `consolidate` keeps per-offering evidence in `source_lineage` with `entity_role: "merged_from"` or `"refreshed"`. `category-aggregation` keeps per-offering evidence in `source_lineage` with `entity_role: "aggregated_from"` and also emits the delivery-stack staging artifact — the per-stack detail has two homes in the data model (staging for `solutions/` seeding, lineage for audit).
- `consolidate` is the right choice when building a portfolio that will feed propositions at the per-offering grain (e.g. "Managed AWS Services" and "Managed OTC Services" as distinct features with distinct propositions). `category-aggregation` is the right choice when feature-level differentiation at that grain would be redundant because the distinction is really about delivery, not capability.

## Choosing a default

The skill prompts the user explicitly rather than heuristically guessing from the company slug. Keep the default as `consolidate` so v1.2.0 behaviour is preserved for any caller (including `portfolio-setup`) that does not pass a mode through.

Callers that know the scan target is not the portfolio owner should pass `consolidation_mode: "research-only"` (or `"shadow"`) explicitly to avoid the prompt and the default.

## Forward compatibility

The `dedupe_summary` block in `scan-output.json` remains present in every mode (for schema stability) but only carries meaningful counts under `consolidate` and (differently) under `category-aggregation`.

- Under `consolidate`, all five counters are meaningful and the sum invariant holds (`merged_into_existing + collapsed_among_candidates + written_new + soft_duplicates_deferred` = candidate count).
- Under `shadow` and `research-only` the counters are all zero by convention — a filesystem count of `research/scan-candidates/{COMPANY_SLUG}/` gives the shadow candidate total; `research-only` has no candidate artifact at all.
- Under `category-aggregation`, `written_new` = the number of populated taxonomy categories (one feature per category group). `merged_into_existing`, `collapsed_among_candidates`, `legacy_duplicates_flagged`, and `soft_duplicates_deferred` are all zero — not because nothing was absorbed (many candidates collapse into one feature), but because the aggregation path does not go through per-resolution branches. The sum invariant does **not** hold under this mode by design; dashboards must branch on `consolidation_mode` before computing dedupe health metrics.

`provider_units[].feature_count` is meaningful under `consolidate` (each feature has a single `_source_offering.domain`). Under `category-aggregation`, a category-grained feature has many source offerings across potentially many domains, so `feature_count` should be computed as the count of features whose `source_lineage` contains **any** entry sourced from the unit's domain, counting each feature at most once per unit — otherwise a feature absorbed from five offerings at the same unit would inflate the count to 5 for that one feature. Under `shadow` and `research-only`, the skeleton written at Phase 1.5 stands without enrichment, which dashboards must treat as "not measured", not as "zero".
