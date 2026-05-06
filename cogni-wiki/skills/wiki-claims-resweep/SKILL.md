---
name: wiki-claims-resweep
description: "Re-verify claims embedded in existing wiki pages against their cited source URLs. Extracts inline-cited statements deterministically (sentences containing http(s) URLs or markdown links — no LLM extraction), submits them as a batch to cogni-claims for re-verification (WebFetch + LLM compare per source), and writes a sweep report under <wiki-root>/raw/claims-resweep-<date>/ plus a machine-readable .cogni-wiki/last-resweep.json bridge for future lint integration. Report-only — never mutates the per-type page dirs. Trigger when the user says 're-verify wiki claims', 'check if wiki sources still hold up', 'sweep wiki for stale citations', 'run a claims re-check on the wiki', 'audit wiki citations against sources', or 'wiki-claims-resweep'. Pull-mode only; the user picks scope (--all, --page <slug>, or --stale-only)."
allowed-tools: Read, Write, Bash, Glob, AskUserQuestion, Skill
---

# Wiki Claims Re-Verify Sweep

Wiki pages cite sources but no mechanism re-checks those citations after ingest. URLs 404, paywalls appear, content gets rewritten. This skill closes that loop: it extracts cited statements from existing wiki pages, dispatches them through cogni-claims for verification (which already does the WebFetch + LLM compare against the live source), and writes a sweep report so the user can see drift at a glance.

This is a **report-only** skill. It does not edit the per-type page dirs. The report tells the user which pages have deviated or unavailable claims; the user decides whether to run `wiki-update` to mark them stale. This keeps diff-before-write inside `wiki-update` where it belongs.

This is a **pull-mode** primitive — the user invokes it on a schedule that fits their workflow. There is no auto-trigger.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once before proceeding to re-anchor on the three-layer model — sweep artefacts land in `raw/`, never in the per-type page dirs.

## When to run

- User asks to re-verify, sweep, or audit existing wiki citations
- After a long stretch (months) of accumulated wiki growth, to surface URL drift
- Before a major wiki release or share-out, to spot embarrassing dead citations
- Targeted: "re-verify just the ai-safety-evals page" → `--page <slug>`

## Never run when

- The wiki has no pages with `sources:` populated — there's nothing to re-verify
- The user wants to mutate page bodies (set `## Stale` markers etc.) — that's `wiki-update`'s job; this skill is report-only and never touches `wiki/<type>/`
- The user wants to create new claims from scratch — that's `wiki-ingest`'s job

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--all` | No | (Default) Sweep every page that has a non-empty `sources:` field. |
| `--page <slug>` | No | Sweep a single page only. Mutually exclusive with `--all` and `--stale-only`. |
| `--stale-only` | No | Sweep only pages older than `STALE_PAGE_DAYS` (365) — or `--days N`. |
| `--days <N>` | No | Override staleness threshold; only valid with `--stale-only`. |
| `--wiki-root <path>` | No | Override auto-detected wiki root. |
| `--dry-run` | No | Run extract + plan; print the plan and stop. No cogni-claims dispatch, no report. The materialised manifests under `raw/claims-resweep-<date>/` are still written (audit trail). |

## Workflow

### 0. Pre-flight (always; fail-fast)

1. Resolve `wiki_root` (walk up for `.cogni-wiki/config.json`).
2. Compute `today = YYYY-MM-DD`.
3. If neither `--all`, `--page`, nor `--stale-only` is set, default to `--all`.
4. If `--days` is set without `--stale-only`, abort with "--days requires --stale-only".

### 1. Extract claim candidates (deterministic, read-only)

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/wiki-claims-resweep/scripts/extract_page_claims.py \
  --wiki-root <wiki_root> \
  [--all | --page <slug> | --stale-only] \
  [--days <N>]
```

The script parses each selected page's body and emits claim candidates: every sentence that contains an inline `[text](http(s)://...)` link or a bare `http(s)://` URL becomes a candidate, with the URL as the source. Sentences shorter than 30 characters are dropped (heading/list-item noise). The script never makes network calls.

Pages with **circular sources** (URLs pointing back into the wiki tree, e.g. relative paths under `wiki/`) have those specific claims dropped and counted in `circular_skipped` — same circular-evidence rule as `wiki-from-research` and `wiki-refresh`.

Parse stdout JSON. If `data.stats.total_claims == 0`, emit one line — "no cited claims to re-verify in scope" — and exit 0.

### 2. Materialise sweep workspace

Pipe the extract output into the planner's `plan` phase:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/wiki-claims-resweep/scripts/resweep_planner.py \
  --phase plan \
  --extract-file - \
  --date <today>
```

The planner creates `<wiki-root>/raw/claims-resweep-<today>/` and writes one `<slug>-claims.md` manifest per page (YAML frontmatter + statement/source list) plus an `index.json` with the dispatch plan. Re-runs on the same day overwrite deterministically; reruns on different days preserve the audit trail.

The planner only writes inside the per-day workspace dir (isolated, no lock contention).

### 3. Print plan, batch-confirm

Render the planner output as a table:

```
Claims re-verify plan (mode: <mode>, date: <today>):
  <K> pages, <total_claims> claims, <unique_sources> unique source URLs

  page                       claims  sources  age
  ai-safety-evals               8       3     412d
  llm-jailbreaks                3       2     198d
  …
```

If `--dry-run` was set, stop here. Exit 0. The materialised manifests stay on disk for inspection.

Otherwise, AskUserQuestion with three options:

| Label | Action |
|---|---|
| `proceed` | Dispatch cogni-claims (Steps 4–6) |
| `refine` | Re-prompt for a tighter scope (suggest switching to `--stale-only` or naming a `--page`); loop back to Step 1 |
| `abort` | Exit 0; manifests stay on disk for the user to inspect |

### 4. Submit + verify per page (sequential)

For each entry in `data.plan[]`:

1. Read the manifest at `<wiki-root>/<entry.manifest>` and parse the `## Claims` section into a list of `{statement, source_url, source_title}` records.
2. Dispatch:

   ```
   Skill("cogni-claims:claims",
         args="submit working_dir=<wiki-root> claims=<list> submitted_by=wiki-claims-resweep")
   ```

   Pass each record verbatim. The claims skill assigns IDs and appends to `<wiki-root>/cogni-claims/claims.json`.

3. Capture the submission's claim IDs. Then dispatch:

   ```
   Skill("cogni-claims:claims",
         args="verify working_dir=<wiki-root> ids=<list-of-just-submitted-ids>")
   ```

   The claim-verifier agent groups by source URL, fetches each URL once (cached at `cogni-claims/sources/{url-hash}.json`), and updates each claim's status to `verified | deviated | source_unavailable`.

**Sequential per page**, not parallel — keeps the orchestration trivial and the cogni-claims source-cache hot for any URLs shared across pages within the same sweep.

If a `cogni-claims:claims` dispatch fails for a specific page (e.g. WebFetch network blip, store init error), capture the error in a per-page failure entry and continue. Per-page failures never halt the sweep.

### 5. Build verification-results JSON

After all per-page dispatches complete, read `<wiki-root>/cogni-claims/claims.json` and group by page (using the manifest IDs you captured in Step 4). Construct:

```json
{
  "success": true,
  "data": {
    "pages": [
      {
        "slug": "<page-slug>",
        "claims": [
          {"id": "<claim-id>", "statement": "...", "source_url": "...",
           "status": "verified | deviated | source_unavailable",
           "deviations": [...]}
        ]
      }
    ]
  },
  "error": ""
}
```

This is the input shape for `--phase aggregate` below.

### 6. Aggregate report + lint-bridge

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/wiki-claims-resweep/scripts/resweep_planner.py \
  --phase aggregate \
  --workspace <wiki_root>/raw/claims-resweep-<today> \
  --results-file - <<<'<json from Step 5>'
```

The planner writes:

- `<wiki_root>/raw/claims-resweep-<today>/report.md` — human-readable per-page findings
- `<wiki_root>/.cogni-wiki/last-resweep.json` — machine-readable bridge (sweep_date, mode, deviated_pages, unavailable_pages, report_path). **Lock-wrapped** via `_wiki_lock` since `last-resweep.json` is shared state.

### 7. Final summary

Plain prose, ≤8 lines:

- Sweep date + mode used
- `N` pages scanned, `T` claims checked
- `V` verified, `D` deviated (across `K` pages), `U` source_unavailable (across `M` pages)
- Per-page failures (if any), with verbatim error per failure
- Path to the report markdown (relative to wiki-root)
- Path to `last-resweep.json` (for the future lint integration)
- Suggested next: `wiki-update --page <slug>` for any flagged page where the user wants to add a `## Stale (date)` marker, or `claim-verify --id <id> cobrowse` for source_unavailable claims that may be recoverable interactively

## Edge cases

- **No claims found.** Step 1 emits `total_claims == 0`; skill exits 0 with "no cited claims to re-verify in scope". No workspace dir created (planner short-circuits when pages list is empty).
- **All claims circular.** All extract candidates dropped because their URLs point back into the wiki. Step 1 reports `circular_skipped > 0` but `total_claims == 0`. Skill exits 0 with the same nothing-to-do message.
- **Page newer than the sweep.** No problem — re-verification is independent of page age. The user can sweep stale or fresh pages alike.
- **Per-page cogni-claims failure.** Captured, sweep continues for remaining pages. Failure list surfaces in Step 7. The user re-runs the skill or runs `cogni-claims:claims verify` manually for the failed slugs later.
- **Re-run same day.** Workspace path is `claims-resweep-<today>`; per-page manifests overwrite deterministically. `last-resweep.json` is replaced under lock.
- **Source-cache hit.** If a URL was verified within the cogni-claims cache TTL, the claim-verifier agent reuses the cached source body — no extra WebFetch. Sweep cost scales with unique URLs, not total claims.
- **`--page` for an unknown slug.** `extract_page_claims.py` aborts with "page not found"; SKILL surfaces the error verbatim.
- **Source URL list contains duplicates across pages.** Same URL appearing in 5 pages = 1 WebFetch (claim-verifier groups by URL within a single cogni-claims run). Across pages we dispatch sequentially; the source-cache still saves the WebFetch on the second page.

## Out of scope

- **Page-body mutation.** Report-only by design. The user runs `wiki-update` if they want to mark stale claims.
- **LLM-based claim extraction.** Deterministic extraction (sentences near URLs) is sufficient for cited prose; an agent-driven extractor would over-yield on synthetic wiki text and add cost. If the user has a wiki where claims are made *without* inline citations, they should add citations during ingest — that's the wiki-ingest contract.
- **Auto-trigger from lint.** A future `claim_drift` warning class in `wiki-lint` could read `last-resweep.json` and surface flagged pages, but the sweep itself is always user-invoked. Not in this skill's scope.
- **Cross-wiki sweeps.** One wiki per invocation. Run the skill from inside each wiki's tree.
- **Push-mode auto re-verify.** No background scheduler. The user invokes when they want a fresh check.
- **Resolve / cobrowse mode dispatch.** This skill stops at verify. The user runs `claims:claims resolve <id>` or `claims:claims cobrowse` manually for findings that need interactive recovery.

## Output

The skill produces:

- A populated `<wiki-root>/raw/claims-resweep-<today>/` directory with:
  - One `<slug>-claims.md` manifest per page (audit trail)
  - `index.json` (dispatch plan, machine-readable)
  - `report.md` (human-readable findings)
- `<wiki-root>/.cogni-wiki/last-resweep.json` — lint-bridge JSON, lock-wrapped write
- New / updated entries in `<wiki-root>/cogni-claims/claims.json` (managed by cogni-claims, not this skill)

No file outside `<wiki-root>/` is created. No `wiki/<type>/` file is modified.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the three-layer model (raw / wiki / schema)
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-lint/scripts/lint_wiki.py` — `STALE_PAGE_DAYS` / `STALE_DRAFT_DAYS` constants mirrored in `extract_page_claims.py`
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-refresh/SKILL.md` — sibling pull-mode skill; same batch-confirm + materialise-then-enumerate pattern
- `cogni-claims/skills/claims/SKILL.md` — `submit` and `verify` modes (Step 4 dispatch contracts)
- `cogni-claims/agents/claim-verifier.md` — the WebFetch + 5-dimension comparison agent that does the actual re-verification work
