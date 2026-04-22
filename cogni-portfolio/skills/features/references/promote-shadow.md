# Promote Shadow Candidates

Workflow for pulling `portfolio-scan --mode=shadow` candidates into the authoritative `features/` set. Triggered from the `features` skill when the user says "promote shadow candidates", "import the scan candidates", "pull the shadow features in", or equivalent. The SKILL.md entry is a thin stub; the full workflow lives here because the prose is too detailed to belong in the main skill body.

## When to use this

`portfolio-scan` in `shadow` mode writes one JSON per discovered offering under `research/scan-candidates/{COMPANY_SLUG}/{slug}.json` instead of touching `features/`. That is the right default when scanning competitors, partners, or your own company in review-mode — curated state stays clean until the user reviews and accepts each candidate.

This workflow is the human-in-the-loop promotion step: list candidates, let the user pick, strip diagnostic fields, write real feature JSONs, dispatch dedupe, then delete or archive the originals.

## Prerequisites

- A `cogni-portfolio` project with `portfolio.json` at its root.
- One or more candidate JSONs under `research/scan-candidates/{COMPANY_SLUG}/`. If the directory is empty or absent, stop and tell the user there are no candidates to promote — do not enter the AskUserQuestion flow.
- The candidates must be shadow-mode output (they carry `_shadow_candidate: true` and `_source_offering: {...}` diagnostic fields). If those fields are missing, the file is not a shadow candidate and should be skipped with a warning — don't assume structure.

## Workflow

### 1. List candidates

Dispatch the helper script in `list` mode:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/skills/features/scripts/promote-shadow.py" list \
  --project-dir "<project-dir>"
```

The script returns `{"success": true, "data": {"candidates_by_company": {...}, "total": N}}`. Each candidate entry carries `{slug, product_slug, name, taxonomy_mapping, source_path}` — enough to render a pick list without re-reading the JSON.

Empty state: when `total` is 0, tell the user there are no shadow candidates and stop. Do not offer to run `portfolio-scan` inline — that's a separate flow.

### 2. Present and pick

Group the candidates by company (the top-level key in `candidates_by_company`) and present them as a pick list. For each candidate show: `slug`, `name`, `product_slug`, and the taxonomy category when present. Use `AskUserQuestion` with `multiSelect: true` so the user can pick one, many, or all candidates in a single prompt.

If the user declines or picks none, stop cleanly — do not loop.

Sort candidates alphabetically by slug within each company. Multiple companies means one pick list per company is cleaner than a flat list; the skill can ask "which company first?" when there are more than one, or collapse into a single grouped prompt for a small total.

### 3. Dry-run preview

Before writing any file, show the user what will happen for each selected candidate:

- **Target path**: `features/{slug}.json` (relative to project root).
- **Slug collision**: if `features/{slug}.json` already exists, flag it — do not overwrite silently. Offer to rename (append `-scan` suffix), skip, or let the user edit the slug. Default to **skip** for safety.
- **Diagnostic fields to strip**: `_shadow_candidate`, `_source_offering`. Call these out explicitly so the user understands the JSON will be modified before landing.
- **Post-action**: delete the source candidate JSON (default) or move it to `research/scan-candidates/{COMPANY_SLUG}/.archive/{slug}.json` when the user opts in to archive.

Confirm before proceeding. One confirmation for the whole batch is fine — per-file confirmation becomes a wizard.

### 4. Promote each candidate

For each selected candidate, dispatch the helper in `promote` mode:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/skills/features/scripts/promote-shadow.py" promote \
  --candidate "<source_path>" \
  --features-dir "<project-dir>/features" \
  [--archive]
```

The helper:
1. Reads the candidate JSON.
2. Strips `_shadow_candidate` and `_source_offering`.
3. Writes the cleaned JSON to `features/{slug}.json` (respecting the slug the user may have edited in Step 3).
4. Deletes the source JSON, or moves it to `.archive/` when `--archive` is passed.
5. Returns `{"success": true, "data": {"feature_path": "...", "archived_to": "..." | null}}`.

Loop through candidates independently. If one fails (slug collision, permission error, malformed JSON), capture the error and continue to the next candidate — do not abort the batch. Collect successes and failures for the post-batch summary.

### 5. Dispatch dedupe

After all promotions land, dispatch the `feature-deduplication-detector` agent in candidate mode against the product(s) that received new features. The agent's candidate mode is documented in its own definition (`cogni-portfolio/agents/feature-deduplication-detector.md`) — pass it the newly-promoted feature slugs as the candidate pool plus the full `features/` set as the existing-features pool. The agent returns cluster recommendations (hard duplicate → merge, soft duplicate → review, related → annotate).

Surface the agent's verdict to the user. Do not auto-merge — the user reviews each cluster recommendation. Promotion landed the features; dedupe is the cleanup pass.

When multiple products are affected, dispatch the agent once per product (the agent operates per-product, per its own contract).

### 6. Summary

Print a compact summary: how many candidates were selected, how many promoted successfully, how many skipped on slug collision, how many failed, and where originals went (deleted vs archived). Point the user at the dedupe verdict and suggest they re-run quality assessment on the affected product to pick up the new features.

## Error paths

| Case | Behaviour |
|---|---|
| No candidates in `research/scan-candidates/` | Stop cleanly, one-line message. Do not offer to run scan inline. |
| Candidate JSON lacks `_shadow_candidate: true` | Warn and skip. The file is probably not a shadow-mode candidate and dropping it into `features/` untouched would be unsafe. |
| Candidate JSON is malformed | Warn with the parse error, skip. Continue batch. |
| Slug collision on `features/{slug}.json` | Default **skip**. User can rename or overwrite explicitly in the dry-run step. Never overwrite silently. |
| Permission error on write or delete | Warn, skip, continue batch. Collect for summary. |
| User aborts mid-batch | Stop cleanly. Already-promoted candidates stay; un-promoted ones stay in `research/scan-candidates/`. The helper is idempotent — re-running the flow will pick them up again. |

## Design notes

- **Why a helper script, not inline Read/Write**: the strip/move logic is the same every call; pulling it into a script keeps the SKILL.md prose focused on UX and lets the mechanical bits be tested in isolation.
- **Why delete by default, archive as opt-in**: once a candidate lands in `features/`, the shadow copy is a stale duplicate. Keeping both around invites confusion. Users who want an audit trail opt in to `--archive`, which moves the original to `.archive/` instead of deleting it.
- **Why per-file error isolation**: a batch of 10 candidates where one has a malformed JSON should promote the other 9, not abort all 10. The summary tells the user what landed and what didn't.
- **Why dispatch dedupe after promotion, not before**: promoted candidates should compete for slugs on equal footing with existing features. Running dedupe against candidates before they're "real" biases toward the existing set.
- **No bulk-promote-all shortcut**: the user always picks, even if they pick all. Deferred until someone explicitly asks for it — the per-candidate review is the whole point of shadow mode.

## Related

- `cogni-portfolio/skills/portfolio-scan/references/consolidation-modes.md` — scan-time counterpart. Shadow-mode section points at this workflow.
- `cogni-portfolio/agents/feature-deduplication-detector.md` — candidate-mode contract used in Step 5.
- `cogni-portfolio/skills/portfolio-dashboard/SKILL.md` — Section 4a surfaces shadow candidates in the dashboard (read-side); this workflow is the write-side.
