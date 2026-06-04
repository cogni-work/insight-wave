# cogni-wiki changelog

## 0.0.58 — 2026-06-04 — raw_citation_depth lint auto-fix (closes #478 for this plugin)

**Heads-up for existing wikis.** v0.0.55 hardened `health.py`'s `missing_source`
check to resolve `sources:` citations from each page's actual on-disk location.
Because pages live two levels deep (`wiki/<type>/<slug>.md`) since schema 0.0.5,
any page still carrying a pre-0.0.5 depth-wrong `../raw/<file>` citation now
resolves to the non-existent `wiki/raw/` and flips to a health **error** — and
`wiki-lint` refuses to run while `health.errors > 0`. On an upgraded wiki this
surfaces as latent breakage that previously went unnoticed.

**The repair.** New deterministic `--fix=raw_citation_depth` class in
`lint_wiki.py`'s existing auto-fix framework. For each `sources:` frontmatter
entry and each body `## Sources` link whose `../raw/<tail>` resolves outside
`raw/`, it rewrites to `../../raw/<tail>` — but only when `<wiki-root>/raw/<tail>`
actually exists (skip-don't-guess otherwise). Subdirectory tails are preserved
(computed from the original string, never `Path.name`), prose links outside the
`## Sources` section are never touched, and an already-`../../raw/` citation is
left untouched (idempotent). Run it once after upgrading:

```
wiki-lint --fix=raw_citation_depth        # or --fix=all
```

It is a fourth in-process page-body fixer, running inside the shared
`_wiki_lock(wiki_root)` block and reading each page fresh from disk so it
composes with the other fixers in a single `--fix=all` run. The class
auto-registers into `FIX_CLASSES`, argparse `choices`, and `--fix=all`. SKILL.md
documents the new class; `tests/test_lint_fix.sh` gains a section asserting
dry-run/wet/idempotency, subdir preservation, the prose-and-nonexistent skips,
and `health.py` reporting 0 `missing_source` afterwards. The secondary
trigger-widening question and the cosmetic `raw/{name}` health message are left
to follow-up issues.

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
