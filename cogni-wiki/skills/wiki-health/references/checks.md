# Health Checks

This file is the canonical list of what `health.py` checks. Every check here is deterministic, requires zero LLM calls, and runs on every wiki-resume invocation. If a check needs reasoning or judgement, it belongs in `wiki-lint` (semantic pass), not here.

## Errors — block reliable reads

| Class | Detection | Fix path |
|-------|-----------|----------|
| `broken_wikilink` | `[[slug]]` in any page where `wiki/<type>/{slug}.md` does not exist | `wiki-update` the referring page — remove the link or create the target |
| `missing_frontmatter` | One of `id`, `title`, `type`, `created`, `updated` is missing or empty | `wiki-update` to add the field |
| `id_mismatch` | Frontmatter `id: x` but filename is `y.md` | Rename the file or fix the frontmatter |
| `invalid_type` | Frontmatter `type:` value not in `{concept, entity, summary, decision, interview, meeting, learning, synthesis, note}` | `wiki-update` to pick a valid type |
| `missing_source` | `sources: [../raw/foo.pdf]` where `raw/foo.pdf` does not exist | Restore the source or remove the reference |
| `broken_wiki_source` | `sources: [wiki://other-slug]` where `wiki/<type>/other-slug.md` does not exist | `wiki-update` to fix the slug, or re-run `wiki-query --file-back` to regenerate the synthesis after the missing page is created |
| `read_error` | Page file unreadable (permission, encoding, IO) | OS-level — investigate filesystem |

## Warnings — structural debt that is still mechanical

These are warnings, not errors, because they don't block reads — but they are still purely deterministic, so they belong in health rather than lint.

| Class | Detection | Fix path |
|-------|-----------|----------|
| `stub_page` | Page body (after frontmatter) is shorter than `STUB_PAGE_MIN_CHARS` (50) | `wiki-update` to expand, or delete if abandoned |
| `entries_count_drift` | `.cogni-wiki/config.json` `entries_count` differs from actual file count under `wiki/<type>/` (excluding `lint-*` and `health-*`) | Run `wiki-ingest` to bump the counter, or hand-edit `config.json` to match |
| `index_filesystem_drift` | A slug appears in `wiki/index.md` as a `[[wikilink]]` but no `wiki/<type>/{slug}.md` exists, or vice versa | `wiki-update` to add the missing entry, or delete the stale index line |

## Stats — descriptive only

| Stat | Meaning |
|------|---------|
| `pages_audited` | Count of `*.md` under `wiki/<type>/` excluding `lint-*` and `health-*` |
| `errors` / `warnings` | Total count of each tier |
| `entries_count_config` | Value from `.cogni-wiki/config.json` |
| `entries_count_actual` | Filesystem count |
| `entries_count_drift` | `actual - config` (signed) |
| `claim_drift_count` | Number of pages flagged by the most recent `wiki-claims-resweep` (read from `.cogni-wiki/last-resweep.json`); `0` when no resweep has run |
| `claim_drift_date` | ISO date of the most recent resweep, or `null` |

## What is deliberately **not** here (lives in `wiki-lint`)

- `orphan_page` — judgemental: top-level entries are intentionally orphans
- `stale_draft` / `stale_page` — date-based but the threshold is editorial
- `tag_typo` — heuristic; often false-positive on intentional variants
- `reverse_link_missing` — needs narrative around the SCHEMA `R1_bidirectional_wikilink` contract
- `synthesis_no_wiki_source` — needs narrative around file-back discipline
- `claim_drift` per-page narrative — health surfaces the count; lint narrates severity
- `contradiction`, `type_drift`, `undercited_claim`, `missing_concept_page` — semantic, LLM-powered

## Thresholds

| Knob | Default | Rationale |
|------|---------|-----------|
| `STUB_PAGE_MIN_CHARS` | 50 | A page shorter than this is not yet useful; flagging it nudges either expansion or deletion. Lower than this and we'd flag every just-created page mid-ingest. |

All thresholds are constants at the top of `health.py` so they can be tuned without restructuring the script.

## Performance contract

`health.py` is expected to complete in under 1 second on a 100-page wiki. The checks are O(pages) with one filesystem walk and one `index.md` read. If a future check would break this contract, it belongs in `wiki-lint`, not here. The whole point of the split is that health is cheap enough to run on every `wiki-resume`.
