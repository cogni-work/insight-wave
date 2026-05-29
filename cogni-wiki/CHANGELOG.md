# cogni-wiki changelog

## 0.0.49 — 2026-05-29 — Research-time gaps in open_questions.md (closes #354 for this plugin)

`rebuild_open_questions.py` accepts two new tracked classes, `research_uncovered`
and `research_partial`, rendered as two sections at the **tail** of
`wiki/open_questions.md` (`## Research-time gaps — uncovered` /
`## Research-time gaps — partial`). These classes are **NOT** lint findings —
`lint_wiki.py` never emits them. They are deposited via the `--findings -` stdin
contract by `cogni-knowledge:knowledge-finalize` (Step 10.5 sub-step 5) from each
research project's `<project>/.metadata/wiki-coverage.json`, keyed by a synthetic
`sq:<sq_id>` identifier instead of an on-disk page slug.

`finalize` is now a `CLOSING_OPS` operation. A `wiki/log.md` line like
`## [YYYY-MM-DD] finalize | … sqs=sq-04,sq-01` credit-closes a previously-open
research-time gap once it drops out of the findings (`- [x] ~~`sq:sq-04` — …~~ —
closed YYYY-MM-DD by finalize`); `attribute_close` strips the `sq:` prefix from the
checklist id before its substring scan so it matches the bare `sqs=` form.

Additive on the seven existing classes — `OPEN_LINE_RE` / `CLOSED_LINE_RE` /
`SECTION_HEADER_RE` / `LOG_LINE_RE` / the 90-day trim are byte-unchanged (the
existing backtick-token regex already matches `sq:sq-04`, `:` is not excluded).
`_flatten` now reads an `id` field (falling back to `page`); `reconcile` returns
per-class `opened_by_class` / `closed_by_class` tallies so the finalize summary can
split lint vs research. `--findings -` additionally unwraps a `{success, data:{…}}`
envelope so the cogni-knowledge merge helper's output (which honours the
`{success, data, error}` script convention) pipes straight in. New
`tests/test_open_questions_research_gaps.sh`. Builds on #338 (Option (b)).

## 0.0.48 — 2026-05-29 — Discoverability — manifest description light-trimmed (closes #351 for this plugin)

`description` in `.claude-plugin/plugin.json` and the matching `marketplace.json`
entry trimmed from 417 to 349 chars. Prose-only tightening: "contradictions
are surfaced at ingest (not missed at retrieval)" → "contradictions surface
at ingest"; "knowledge compounds instead of starting from zero" → "knowledge
compounds"; "Andrej Karpathy's LLM Wiki pattern" → "Karpathy's LLM Wiki
pattern". `keywords[]` unchanged. No behavioural change. No schema change.
No skill change.
