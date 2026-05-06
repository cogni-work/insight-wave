# Severity Tiers

The lint report uses three tiers. Each finding belongs to exactly one tier. The tier determines urgency, not necessarily truth — a tier-1 finding might be intentional; it still gets flagged so the user sees it.

## Health vs Lint coverage matrix

As of v0.0.27, structural integrity checks live in `wiki-health` (zero LLM, every session) and content-quality checks live in `wiki-lint` (LLM-powered, periodic). The two skills share the same severity vocabulary; they differ in what they own.

| Class | Tier | Owner | LLM? |
|-------|------|-------|------|
| `broken_wikilink` | Error | `wiki-health` | no |
| `missing_frontmatter` | Error | `wiki-health` | no |
| `id_mismatch` | Error | `wiki-health` | no |
| `invalid_type` | Error | `wiki-health` | no |
| `missing_source` | Error | `wiki-health` | no |
| `broken_wiki_source` | Error | `wiki-health` | no |
| `read_error` | Error | `wiki-health` | no |
| `stub_page` | Warning | `wiki-health` | no |
| `entries_count_drift` | Warning | `wiki-health` | no |
| `index_filesystem_drift` | Warning | `wiki-health` | no |
| Claim-drift **count** (from last resweep) | Stat | `wiki-health` | no |
| `orphan_page` | Warning | `wiki-lint` | no |
| `stale_draft` | Warning | `wiki-lint` | no |
| `stale_page` | Warning | `wiki-lint` | no |
| `no_sources` | Warning | `wiki-lint` | no |
| `synthesis_no_wiki_source` | Warning | `wiki-lint` | no |
| `reverse_link_missing` | Warning | `wiki-lint` | no |
| `tag_typo` | Warning | `wiki-lint` | no |
| `claim_drift` (per-page narrative) | Warning | `wiki-lint` | no |
| `contradiction` | Warning | `wiki-lint` | **yes** |
| `type_drift` | Warning | `wiki-lint` | **yes** |
| `undercited_claim` | Warning | `wiki-lint` | **yes** |
| `missing_concept_page` | Info | `wiki-lint` | **yes** |
| Total pages, by type, top tags, most-linked | Info | `wiki-lint` | no |
| `last_resweep` (date narrative) | Info | `wiki-lint` | no |

**Rule of thumb:** if a check is a pure filesystem or schema test, it lives in `wiki-health`. If it needs date math with editorial judgement, a heuristic, narrative, or actual reading of page bodies, it lives in `wiki-lint`. Health is what runs on every session; lint is what runs every 10–15 ingests.

**Why lint still does deterministic warnings.** Orphans, stale drafts, tag typos, and reverse-link gaps are all mechanically detectable but require narrative around the fix path — e.g. an orphan might be intentional (a top-level entry), a stale draft might be a deliberate parking spot, a reverse-link gap encodes the SCHEMA `R1_bidirectional_wikilink` contract. Surfacing them in the same report as the semantic findings keeps the "tokenful pass" coherent: when the user runs lint, they see everything that needs human judgement in one place.

## 🔴 Error — structural integrity

An error means the wiki's contract is broken and a reader (human or LLM) might make a wrong inference. Errors must be fixed. **Errors are owned by `wiki-health`** — they're cheap to detect deterministically and they should fail fast on every session, not wait for a tokenful lint.

### Error classes

| Class | Detection | Fix path |
|-------|-----------|----------|
| **Broken wikilink** | `[[slug]]` where `wiki/<type>/{slug}.md` does not exist | `wiki-update` the referring page — either remove the link or create the target |
| **Filename–id mismatch** | Frontmatter `id: x` but filename is `y.md` | Rename the file or fix the frontmatter |
| **Missing required frontmatter** | `id`, `title`, `type`, `created`, or `updated` missing | `wiki-update` to add the field |
| **Invalid type** | `type:` value is not one of the allowed values | `wiki-update` to pick a valid type |
| **Missing source file** | `sources: [../raw/foo.pdf]` where `raw/foo.pdf` doesn't exist | Either restore the source or remove the reference |
| **Broken wiki source** | `sources: [wiki://other-slug]` where `wiki/<type>/other-slug.md` does not exist | `wiki-update` to fix the slug, or re-run `wiki-query --file-back` to regenerate the synthesis after the missing page is created |
| **Duplicate slug** | Two pages with the same `id` frontmatter (shouldn't be possible if filenames are unique, but check) | Rename one |

Errors are reported with a file path and line number so the user can jump directly. `wiki-lint` refuses to run its semantic pass when `wiki-health` reports errors > 0 (override with `--ignore-health`) — reasoning over a broken graph wastes tokens and produces noisy findings.

## 🟡 Warning — maintenance debt

A warning means the wiki works but is accumulating debt. Warnings should be reviewed periodically — not urgent, but don't let them pile up. Warnings split between health (mechanical-only structural debt) and lint (everything that needs narrative or reading).

### Warning classes

| Class | Detection | Owner | Fix path |
|-------|-----------|-------|----------|
| **Stub page** | Body shorter than 50 chars after frontmatter | `wiki-health` | `wiki-update` to expand, or delete |
| **entries_count drift** | `.cogni-wiki/config.json` `entries_count` ≠ actual file count under `wiki/<type>/` (excluding `lint-*` and `health-*`) | `wiki-health` | Run `wiki-ingest` to bump the counter, or hand-edit `config.json` |
| **Index/filesystem drift** | A slug appears in `wiki/index.md` as a `[[wikilink]]` but no page file exists, or a page exists but is not in the index | `wiki-health` | `wiki-update` to add the missing entry, or delete the stale index line |
| **Orphan page** | No other page in the per-type page dirs contains a `[[slug]]` link to this page, AND the page is not listed in `wiki/index.md` as a top-level entry | `wiki-lint` | Add inbound links via `wiki-ingest` backlink audit or `wiki-update`; or confirm top-level status |
| **Stale draft** | `status: draft` and `updated` > 180 days ago | `wiki-lint` | `wiki-update` to promote or retire |
| **Stale page** | `updated` > 365 days ago, regardless of status | `wiki-lint` | Review and refresh or mark `status: stale` |
| **No sources** | `sources:` empty or missing, and `type` is not `decision` or `note` | `wiki-lint` | `wiki-update` to add citations |
| **Synthesis without wiki source** | `type: synthesis` but no `wiki://`-prefixed entry in `sources:`. Synthesis pages must cite the wiki pages they derived from. | `wiki-lint` | `wiki-update` to add `wiki://<slug>` references, or re-file via `wiki-query --file-back yes` |
| **Reverse link missing** | Page A contains `[[B]]` but page B does not contain `[[A]]` — violates SCHEMA.md `R1_bidirectional_wikilink`. Lint reports (filename `lint-*`) and health reports (`health-*`) are exempt on both ends per `R3`. | `wiki-lint` | `wiki-update` page B to add a natural-language sentence containing `[[A]]`, or re-run `wiki-ingest` against B to refresh the backlink-audit pass. Auto-fix via `--fix` is not available today; the discipline is "lint reports, never auto-fixes" |
| **Tag typo** | Tag differs from another tag by edit distance ≤ 2, one used ≥3× more than the other | `wiki-lint` | `wiki-update` to normalize |
| **Contradiction** | Two pages make opposing claims about the same entity or concept (semantic pass) | `wiki-lint` (LLM) | `wiki-update` to reconcile, or add explicit contradiction note |
| **Type drift** | Page body's structure doesn't match declared `type` (e.g. a `concept` page that is actually a `summary`) | `wiki-lint` (LLM) | `wiki-update` to retype or rewrite |
| **Undercited claim** | Strong factual claim (number, named entity, dated event) with no citation in the surrounding sentence or `sources:` | `wiki-lint` (LLM) | `wiki-update` to add a citation or soften the claim |
| **Claim drift** | A `wiki-claims-resweep` finding (`deviated` or `source_unavailable`) is recorded for the page in `.cogni-wiki/last-resweep.json` | `wiki-lint` (narrative); `wiki-health` (count) | Consult the sweep report; consider `wiki-update` to mark the affected claims stale, or re-run `wiki-claims-resweep` after sources are recovered |

## 🔵 Info — observations

Info is not a finding — it's descriptive statistics that help the user understand the wiki's shape. Info never requires action, but it often reveals opportunities. Info is owned by `wiki-lint` (the periodic, fully-detailed audit); `wiki-health` exposes only the few counts it cheaply computes (`pages_audited`, `entries_count_*`, `claim_drift_count`).

### Info classes

- **Total pages**, excluding lint and health reports
- **Pages by type** distribution
- **Tag distribution** — top 20 tags with counts
- **Average sources per page**
- **Most-linked pages** — top 10 pages by inbound `[[wikilink]]` count
- **Least-linked pages** — pages with exactly 0 or 1 inbound links, excluding orphans (already in warnings)
- **Log activity** — ingests, queries, syntheses, lints, health runs in the last 30 days
- **Age histogram** — buckets for pages by age: <7d, <30d, <90d, <365d, >365d
- **Last resweep** — date and age (in days) of the most recent `wiki-claims-resweep` run, surfaced when `.cogni-wiki/last-resweep.json` exists
- **Missing concept pages** (LLM) — entity/concept names that recur across ≥3 pages but lack a page of their own

## Thresholds

| Knob | Default | Owner | Rationale |
|------|---------|-------|-----------|
| Stub page minimum body length | 50 chars | `wiki-health` | Below this, the page isn't yet useful; flagging nudges expansion or deletion |
| Stale draft cutoff | 180 days | `wiki-lint` | Drafts that sit this long usually need retirement or promotion |
| Stale page cutoff | 365 days | `wiki-lint` | A year is generous — shorter cutoffs cause warning fatigue |
| Tag-typo max edit distance | 2 | `wiki-lint` | Catches `mashine`/`machine` without flagging `nlp`/`llm` |
| Tag-typo usage ratio | 3:1 | `wiki-lint` | Only flag when one spelling dominates — below that it's just two variant tags |
| Semantic pass page cap | 20 | `wiki-lint` | Limit cost on large wikis; rotate which pages are sampled on repeat runs |

All thresholds live in constants at the top of the relevant script (`health.py` or `lint_wiki.py`) so they can be tuned without restructuring the script.
