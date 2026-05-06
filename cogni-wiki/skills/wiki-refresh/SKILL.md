---
name: wiki-refresh
description: "Refresh stale wiki pages with fresh evidence from a completed cogni-research project. Runs wiki-lint internally, matches stale pages to sub-questions via deterministic token overlap (Jaccard), prints a batch plan for one user confirmation, then dispatches wiki-update per matched page with the synthesised refresh content as the new source. Trigger when the user says 'refresh stale pages from research <slug>', 'wiki-refresh against project X', 'update aging pages with the new agent-economy research', 'pull recent findings into stale pages', or 'my wiki is getting stale, use the latest research to refresh it'. Pull-mode only — does not auto-launch new research."
allowed-tools: Read, Bash, Glob, AskUserQuestion, Skill
---

# Wiki Refresh

Close the *update* loop in the cogni-research → cogni-wiki integration. Wiki pages age (`wiki-lint` flags `stale_page` >365d, `stale_draft` >180d), but lint alone doesn't bring fresh evidence. This skill matches stale pages to sub-questions of a completed cogni-research project, materialises one synthesis file per matched pair, and pipes each through `wiki-update` to apply the diff against the existing page.

This is a **pull-mode** primitive — the user provides the fresh research project; this skill never spins up new research. (Push-mode auto-research per stale page is deferred — it would cost ~$0.50/page and surprises a wiki owner with a research bill.)

The skill is a pure orchestrator. It calls `lint_wiki.py` directly for staleness data (cheaper than dispatching `wiki-lint`, which would write a noise line to `wiki/log.md`), runs `refresh_planner.py` for the match plan, materialises per-page refresh files under `<wiki-root>/raw/refresh-<research-slug>-<YYYY-MM-DD>/`, and then dispatches `wiki-update` sequentially per matched page. Every wiki write goes through existing locked code paths.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once before proceeding to re-anchor on the three-layer model (raw / wiki / schema) — refresh content lands in `raw/`, not directly in the per-type page dirs.

## When to run

- User asks to refresh stale pages from a specific completed cogni-research project
- User wants to pull fresh evidence into an aging wiki without re-running research from scratch
- After a periodic deep-research run on a known domain, to fan the new findings into existing wiki pages

## Never run when

- The user has no existing cogni-research project to pull from — that's `wiki-from-research`'s territory (Mode A)
- The wiki has zero stale pages and the user did not pass `--pages` — there's nothing to refresh
- The cogni-research project's `report_source` is `wiki` or `hybrid` — circular evidence (deferred per `wiki-from-research`'s same rule)

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--from-research <slug>` | Yes | Slug of an existing `cogni-research-<slug>/` project. Auto-located at `<workspace>/cogni-research-<slug>/` or `<wiki-root>/cogni-research-<slug>/`. |
| `--research-root <path>` | No | Override auto-locate. |
| `--match-threshold <float>` | No | Jaccard cutoff for accepting a match. Default `0.30`. Range `[0.0, 1.0]`. |
| `--days <N>` | No | Override staleness threshold (collapses lint's `STALE_PAGE_DAYS=365` and `STALE_DRAFT_DAYS=180` to a single `N`). Mutually exclusive with `--pages`. |
| `--pages <slug,slug>` | No | Explicit page list, bypassing the lint-based stale filter. Implies the user is targeting specific pages. Mutually exclusive with `--days`. |
| `--limit <N>` | No | Cap matches at N after ranking by score (highest first). Excess pages are reported as unmatched. |
| `--force` | No | With `--pages`: include sub-threshold matches (the best available sub-question is taken regardless of score). No effect on lint-driven runs — we never auto-refresh below threshold. |
| `--related-sweep <yes\|no>` | No | Pass-through to `wiki-update`. Default `no` (related-sweep multiplies work and the user only batch-confirms the top-level plan). |
| `--dry-run` | No | Print the resolved plan and stop. No materialisation, no `wiki-update` dispatch. |
| `--wiki-root <path>` | No | Override auto-detected wiki root. |

## Workflow

### 0. Pre-flight (always; fail-fast)

1. Resolve `wiki_root` (walk up for `.cogni-wiki/config.json`).
2. Resolve `project = cogni-research-<slug>` via the same logic as `batch_builder.py::_locate_research_project`.
3. Verify `<project>/project-config.json` exists. Verify `<project>/output/report.md` exists. Verify at least one `<project>/00-sub-questions/data/sq-*.md` exists. Any missing → abort with the verbatim missing-path.
4. Read `<project>/project-config.json`. If `report_source ∈ {wiki, hybrid}`: abort with "circular-evidence projects can't refresh a wiki — same rule as wiki-from-research".
5. **Project-staleness warning (not abort).** If the project's youngest source file (under `<project>/02-sources/data/`) has a `fetched_at` older than 180 days, emit one paragraph: "this research project is itself >180 days old; the refresh may not actually bring newer evidence than the existing pages." Continue anyway.
6. Compute `today = YYYY-MM-DD` for the per-day refresh subdir name.

### 1. Lint for staleness (skipped if `--pages` is set)

Direct script call:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/wiki-lint/scripts/lint_wiki.py --wiki-root <wiki_root>
```

Parse stdout JSON. From `data.warnings[]`, collect entries where `class == "stale_page"` or `class == "stale_draft"`. Extract the `page` field of each as the slug list. Both classes survive the v0.0.31 (#223) lint refactor — they are explicitly retained in `lint_wiki.py` because `wiki-refresh` depends on them. `data.errors` is now always an empty list (structural integrity moved to `health.py`); only `data.warnings` matters for refresh-planning purposes.

If `--days N` was set, post-filter the lint output: walk pages across the per-type page dirs under `<wiki_root>/wiki/` (excluding `audits/`), parse frontmatter, keep only those whose `(today - updated).days > N`.

If the resolved stale list is empty, emit "wiki is up to date — no stale pages to refresh" and exit 0.

### 2. Compute match plan

Dispatch the helper:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/wiki-refresh/scripts/refresh_planner.py \
  --wiki-root <wiki_root> \
  --research-slug <slug> \
  [--research-root <path>] \
  [--threshold 0.3] \
  [--days N | --pages slug,slug] \
  [--limit N] \
  [--force]
```

The script returns `{"success": true, "data": {"matches": [...], "unmatched_pages": [...], "stats": {...}}}`. On `success: false`, surface the error verbatim and stop.

### 3. Print plan, batch-confirm

Render plan as a table the user can review:

```
Refresh plan (research: <slug>, <date>):
  <K> of <stale_total> stale pages matched, <below_threshold> below threshold

  page                       age   →  sub-question                                      score
  ai-safety-evals            412d  →  sq-03 What evaluation methods…                    0.42
  llm-jailbreaks             198d  →  sq-07 How do current jailbreak techniques…        0.38

Unmatched (<count>): legacy-rag-notes (best 0.12), …
```

Truncate sub-question queries to ~50 chars in the table; the full query lives in the JSON for any user that wants to inspect it.

If `--dry-run` was set, stop here. Exit 0.

Otherwise, AskUserQuestion with three options:

| Label | Action |
|---|---|
| `proceed` | Run Steps 4–6 against the current plan |
| `refine` | Re-prompt for `--match-threshold` (free text), loop back to Step 2 |
| `abort` | Exit 0, no writes |

Default surfaced: `proceed` if `data.stats.matched > 0`, otherwise `refine`.

### 4. Materialise per-page refresh markdown

For each entry in `data.matches[]`:

1. Compute output path:
   ```
   <wiki_root>/raw/refresh-<research-slug>-<today>/<page-slug>.md
   ```
   Date in path → reruns same day overwrite deterministically; reruns different days preserve audit trail.
2. Compose the body. Use the same context/source/claim aggregation as `batch_builder.py` (Step 5 of `wiki-ingest --discover research:`), restricted to the matched sub-question:
   ```markdown
   # <Page Title> — refresh from research <slug> (<date>)

   *Sub-question SQ-<NN> ("<query>") matched <score:.2f> against this page (`reasons: <reasons>`). Findings below are from the research project and may refine, contradict, or supplement the current page.*

   ## Findings

   <context bodies for the matched sub-question>

   ## Verified claims

   - <statement> ([source](<url>)) — verified <date>

   ## New sources

   - [<title>](<url>) — <publisher>          # only sources NOT already in the page's `sources:` frontmatter
   ```
   If the "new sources" set-difference is empty, label the section `## Sources (already in page)` instead — `wiki-update`'s LLM may still cross-check claims against them.

   **Verified-claim filter**: `verification_status == "verified"` AND the claim's `source_ref` overlaps with the matched sub-question's contexts' source set. Same structural join as PR #197.

3. Write atomically: write to `<path>.tmp`, then `os.replace(<path>.tmp, <path>)`.

The skill does **not** pre-bake a diff. `wiki-update`'s LLM-driven Step 3 (diff-before-write) computes the diff from the existing page + the new source.

### 5. Dispatch wiki-update sequentially

For each entry in `data.matches[]`, in score-desc order (already provided by the planner):

```
Skill("cogni-wiki:wiki-update",
      args="--page <page-slug> --reason new-source --source raw/refresh-<slug>-<today>/<page-slug>.md --related-sweep <no|yes>")
```

**Sequential, not parallel.** `wiki-update` mutates `wiki/index.md` (and, with `--related-sweep yes`, potentially many other pages). The advisory lock at `<wiki-root>/.cogni-wiki/.lock` keeps writes safe, but parallel dispatch buys nothing because each call already serialises on the lock; sequential keeps the orchestration trivial and the failure surface single-threaded.

If a `wiki-update` dispatch fails for a specific page (e.g. the page was deleted between Step 1 and now, or the page is locked by an unrelated worker), capture the error in a `failures: [{page: <slug>, error: <message>}]` list and continue with the rest of the batch. Per-page failures never halt the run.

### 6. Final summary

Plain prose, ≤8 lines:

- Research source slug + date used
- `N` pages refreshed successfully (slug list)
- `K` failures (slug + error per failure)
- `M` pages unmatched / below threshold (slug list)
- Path to the per-day refresh subdir under `raw/` (kept for audit; user may `git rm -rf` if undesired)
- Suggested next: `wiki-lint` (catches contradictions surfaced by the refreshes), `wiki-query` to spot-check that a refreshed page reflects the new findings.

## Match algorithm

The planner uses **Jaccard on token sets**:

- Page side: tokens from `title + " " + " ".join(tags) + " " + type`.
- Sub-question side: tokens from `query + " " + parent_topic`.
- `score = |A ∩ B| / |A ∪ B|`.

Tokenizer (in `refresh_planner.py`):
1. Lowercase, replace any non-`[a-z0-9]` run with space, split on whitespace.
2. Drop tokens with `len < 3`.
3. Drop ~30 stopwords (`a, an, the, of, in, on, for, with, and, or, …`).
4. Mini suffix-strip: `ies → y`, then trailing `ing | ed | es | s` → empty.
5. Set up the deduped result.

**Asymmetric-overlap rejected**: with short titles (1–2 tokens), one matching term gives score 1.0, which over-matches.
**Weighted Jaccard rejected**: a wiki's tag corpus is too small to estimate IDF reliably.

Tie-breakers (highest-scoring sub-question wins per page):
- Higher score wins
- On tie: lower `section_index` wins
- On tie: lexicographic sub-question id wins

Threshold default `0.30` is empirically reasonable but tunable. The user can `refine` the threshold in Step 3, or pass `--match-threshold` upfront.

## Edge cases

- **Project too old.** Step 0 (5) emits a one-paragraph warning and continues.
- **Zero stale pages.** Step 1 exits clean with `nothing to do`.
- **Zero matches above threshold.** Step 3 surfaces `0 of N matched`; the `refine` option re-prompts. The default surfaced flips to `refine`.
- **Page newer than project report.** The page's `updated:` may be more recent than the project's `output/report.md` if the user hand-edited the page between research runs. Refresh proceeds regardless — the refresh's value is the *evidence axis*, not just recency.
- **Re-run same day.** The per-day subdir overwrites deterministically; the planner's match output is byte-identical for the same inputs (deterministic tokenizer + sorted reasons).
- **`wiki-update` per-page failure.** Captured in `failures[]`; the batch continues. The user sees per-failure detail in Step 6.
- **`--pages` with an unknown slug.** The planner emits `stale_pages_total: 0` (the slug isn't in the wiki at all). Step 1 surfaces it; the SKILL warns and excludes it from the batch.
- **Sub-question with zero contexts.** The planner still scores it normally (the query+parent_topic tokens still match). The materialised file has an empty `## Findings` section; `wiki-update`'s LLM detects the lack of new evidence and likely retires the refresh — acceptable.

## Out of scope

- **Push-mode auto-research** per stale page. Cost-prohibitive at scale; user explicitly chose pull-only.
- **LLM-judged matching.** Token overlap is debuggable, deterministic, and good enough for v1. LLM matching is a future option if false-positive rates prove unacceptable.
- **Per-page interactive confirmation.** Batch-confirm only — the user reviews the whole plan once.
- **URL-drift detection** on page sources. `wiki-lint` doesn't do this today; this skill doesn't either. A `wiki-claims-resweep` skill (Punkt 4) is the right place.
- **Refresh of non-stale pages.** Override via `--pages` only.
- **Wiki/hybrid-mode research projects** as the source. Same circular-evidence concern as `wiki-from-research`.
- **Refactor of `batch_builder.py`** to share entity-loading helpers. The duplication is acknowledged tech debt — both consumers target the same cogni-research entity contract; a schema change touches both anyway. Refactor is non-urgent (parallel to the `_wiki_lock` situation noted in `cogni-wiki/CLAUDE.md`).

## Output

The skill produces:
- A populated `<wiki-root>/raw/refresh-<research-slug>-<today>/` subdir with one synthesis file per matched page (audit trail; idempotent same-day, preserved across days)
- Updated wiki pages — bumped `updated:`, expanded `sources:`, body diffed by `wiki-update`'s LLM
- Append-only `wiki/log.md` with one `update` line per refreshed page (written by `wiki-update`)

No file is created outside `<wiki-root>/`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the three-layer model
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-lint/scripts/lint_wiki.py` — direct invocation in Step 1; `STALE_*_DAYS` constants
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-update/SKILL.md` — Step 5 dispatch contract (`--page`, `--reason new-source`, `--source`, `--related-sweep`)
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/batch_builder.py` — entity-loading pattern (`_locate_research_project`, `_load_sub_questions`, `_index_research_entities`, `_render_synthesis`); `refresh_planner.py` mirrors these helpers
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-refresh/scripts/refresh_planner.py` — match-plan generator
