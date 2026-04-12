# Severity Tiers

The lint report uses three tiers. Each finding belongs to exactly one tier. The tier determines urgency, not necessarily truth — a tier-1 finding might be intentional; it still gets flagged so the user sees it.

## 🔴 Error — structural integrity

An error means the wiki's contract is broken and a reader (human or LLM) might make a wrong inference. Errors must be fixed.

### Error classes

| Class | Detection | Fix path |
|-------|-----------|----------|
| **Broken wikilink** | `[[slug]]` where `wiki/pages/{slug}.md` does not exist | `wiki-update` the referring page — either remove the link or create the target |
| **Filename–id mismatch** | Frontmatter `id: x` but filename is `y.md` | Rename the file or fix the frontmatter |
| **Missing required frontmatter** | `id`, `title`, `type`, `created`, or `updated` missing | `wiki-update` to add the field |
| **Invalid type** | `type:` value is not one of the allowed values | `wiki-update` to pick a valid type |
| **Missing source file** | `sources: [../raw/foo.pdf]` where `raw/foo.pdf` doesn't exist | Either restore the source or remove the reference |
| **Duplicate slug** | Two pages with the same `id` frontmatter (shouldn't be possible if filenames are unique, but check) | Rename one |

Errors are reported with a file path and line number so the user can jump directly.

## 🟡 Warning — maintenance debt

A warning means the wiki works but is accumulating debt. Warnings should be reviewed periodically — not urgent, but don't let them pile up.

### Warning classes

| Class | Detection | Fix path |
|-------|-----------|----------|
| **Orphan page** | No other page in `wiki/pages/` contains a `[[slug]]` link to this page, AND the page is not listed in `wiki/index.md` as a top-level entry | Add inbound links via `wiki-ingest` backlink audit or `wiki-update`; or confirm top-level status |
| **Stale draft** | `status: draft` and `updated` > 180 days ago | `wiki-update` to promote or retire |
| **Stale page** | `updated` > 365 days ago, regardless of status | Review and refresh or mark `status: stale` |
| **No sources** | `sources:` empty or missing, and `type` is not `decision` or `note` | `wiki-update` to add citations |
| **Tag typo** | Tag differs from another tag by edit distance ≤ 2, one used ≥3× more than the other | `wiki-update` to normalize |
| **Contradiction** | Two pages make opposing claims about the same entity or concept (semantic pass) | `wiki-update` to reconcile, or add explicit contradiction note |
| **Type drift** | Page body's structure doesn't match declared `type` (e.g. a `concept` page that is actually a `summary`) | `wiki-update` to retype or rewrite |

## 🔵 Info — observations

Info is not a finding — it's descriptive statistics that help the user understand the wiki's shape. Info never requires action, but it often reveals opportunities.

### Info classes

- **Total pages**, excluding lint reports
- **Pages by type** distribution
- **Tag distribution** — top 20 tags with counts
- **Average sources per page**
- **Most-linked pages** — top 10 pages by inbound `[[wikilink]]` count
- **Least-linked pages** — pages with exactly 0 or 1 inbound links, excluding orphans (already in warnings)
- **Log activity** — ingests, queries, lints in the last 30 days
- **Age histogram** — buckets for pages by age: <7d, <30d, <90d, <365d, >365d

## Thresholds

| Knob | Default | Rationale |
|------|---------|-----------|
| Stale draft cutoff | 180 days | Drafts that sit this long usually need retirement or promotion |
| Stale page cutoff | 365 days | A year is generous — shorter cutoffs cause warning fatigue |
| Tag-typo max edit distance | 2 | Catches `mashine`/`machine` without flagging `nlp`/`llm` |
| Tag-typo usage ratio | 3:1 | Only flag when one spelling dominates — below that it's just two variant tags |
| Semantic pass page cap | 20 | Limit cost on large wikis; rotate which pages are sampled on repeat runs |

All thresholds live in constants at the top of `lint_wiki.py` so they can be tuned without restructuring the script.
