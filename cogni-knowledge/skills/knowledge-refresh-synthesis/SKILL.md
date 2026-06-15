---
name: knowledge-refresh-synthesis
description: "This skill refreshes one existing synthesis in a bound cogni-knowledge base from a newly-landed source — union-not-rederive. Given a synthesis flagged in binding.json::refresh_candidates[] (populated by synthesis-impact.py at ingest-source time), it unions the new source into that synthesis's existing project ingest-manifest rather than re-deriving the manifest via wiki-grounding (which under-maps and thins the synthesis), then runs knowledge-compose -> knowledge-verify -> knowledge-finalize --overwrite as one orchestrated flow. A pure orchestrator over existing phase skills. Pass --all to refresh every open refresh candidate in one fail-soft batch run instead of one synthesis per invocation. Use this skill whenever the user says 'refresh this synthesis from the new source', 'update the <topic> synthesis with the source I just ingested', 'extend an existing synthesis instead of re-running it', 'a new source supersedes my synthesis — fold it in', 'resolve a refresh candidate without thinning the synthesis', or 'refresh all my open refresh candidates in one run'."
allowed-tools: Read, Bash, Glob, AskUserQuestion, Skill
---

# Knowledge Refresh Synthesis

Update an **existing** synthesis when a fresh source lands in the base, without
re-deriving it from scratch. This is the dominant compounding case: a new source
supersedes or extends a prior synthesis, and you want to fold it in — adding to the
prior evidence base, never replacing it.

The base already detects this: `synthesis-impact.py` (run at `knowledge-ingest-source`
time) flags affected syntheses into `binding.json::refresh_candidates[]`. What was
missing is a first-class path to *act* on a candidate. Doing it by hand means ~10
error-prone steps stitched across `knowledge-ingest-source`, `knowledge-compose`,
`knowledge-verify`, and `knowledge-finalize`. The only existing one-shot route —
`knowledge-refresh` push-mode — routes the topic into a **full Phase-1 plan re-run**
whose `knowledge-compose --source wiki` re-derives the ingest-manifest via
`wiki-grounding`, which under-maps (a real run mapped only 21 of 35 original sources),
**thinning** the existing synthesis instead of extending it.

This skill is the targeted, manifest-unioning, single-synthesis orchestrator that
closes that gap. It **unions the new source into the synthesis's existing project
manifest** (`ingest-manifest.json::ingested[]`) — the new source is mapped in and added
to the prior set, never replacing it — then composes the existing phase skills via
`Skill(...)`, never re-implementing them.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once per session to
remember the delegation boundary and the `Skill(...)`-dispatch convention.

## When to run

- A new source has landed and `binding.json::refresh_candidates[]` flags a synthesis it affects
- The user wants to **extend** an existing synthesis from that source, not re-research the topic
- The user wants to resolve a refresh candidate without the wiki-grounding under-mapping that thins the page

## Never run when

- No `binding.json` exists at the resolved knowledge root — route to `/cogni-knowledge:knowledge-setup`
- The binding has zero `refresh_candidates[]` (or none `open`) — there is nothing to refresh; suggest `knowledge-refresh --mode push` for time-based staleness instead
- The targeted synthesis page has no `derived_from_research` frontmatter (it was not deposited by the inverted pipeline, so there is no project manifest to union into) — abort with the message in Step 2 and suggest `knowledge-refresh --mode push` to re-research the topic as a fresh project

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--synthesis-slug <slug>` | No | The synthesis to refresh. When omitted (and `--all` is not set), the open `refresh_candidates[]` are surfaced via `AskUserQuestion` and the user picks one. When set, it must match an `open` candidate. **Mutually exclusive with `--all`.** |
| `--all` | No | Batch mode: refresh **every** `open` candidate in the Step 0 snapshot in one orchestrated, fail-soft run (skips the Step 1 `AskUserQuestion`). **Mutually exclusive with `--synthesis-slug`** — passing both is an error. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |

## Workflow

### 0. Pre-flight

This orchestrator dispatches **only** this plugin's own phase skills (`knowledge-compose`,
`knowledge-verify`, `knowledge-finalize`) plus the in-tree `knowledge-binding.py` — it
runs **no** vendored `wiki-*` script and dispatches **no** `cogni-wiki`/`cogni-research`
skill, so the pre-flight is just binding resolution.

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = cogni-knowledge/<knowledge-slug>/` (relative to the current working directory).

2. Read the binding:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false`, abort and offer `knowledge-setup`. Capture `data.binding`.

3. Validate `binding.knowledge_slug == --knowledge-slug`. Confirm
   `<binding.wiki_path>/.cogni-wiki/config.json` exists. Hold `wiki_path = binding.wiki_path`
   and `knowledge_slug = binding.knowledge_slug` (the validated slug the Step 4–6 `Skill(...)`
   dispatches pass through as `--knowledge-slug <knowledge_slug>`).

4. Read the open refresh candidates: `CANDIDATES = data.binding.get("refresh_candidates", [])`
   filtered to `status == "open"` (use `.get(...)` — a pre-0.1.5 binding has no key). Each
   entry carries `synthesis_slug`, `synthesis_title`, `triggered_by_source[]`, `via_pages[]`,
   `detected_at`, `status`. If `CANDIDATES` is empty, print
   "no open refresh candidates — nothing to refresh (try `knowledge-refresh --mode push` for time-based staleness)"
   and exit 0.

   `CANDIDATES` is the **batch-mode iteration snapshot** — capture it once here and never
   re-read it mid-loop. `knowledge-finalize` clears each `refresh_candidates[]` entry as that
   synthesis lands (Step 6), so re-reading the shrinking binding between candidates would skip
   the not-yet-processed ones.

5. **Mode dispatch.** `--all` and `--synthesis-slug` are mutually exclusive — if both are set,
   abort with: "pass either `--synthesis-slug <slug>` (refresh one) or `--all` (refresh every
   open candidate), not both". Then branch:
   - **`--all` set** → skip Step 1's `AskUserQuestion` and run **[Batch mode (`--all`)](#batch-mode---all)**
     below, which loops the per-candidate flow (Step 1 selection non-interactive, then Steps 2–6)
     over every entry in the `CANDIDATES` snapshot.
   - **otherwise** (default / `--synthesis-slug`) → run the single-candidate flow, Steps 1–7,
     unchanged.

### Batch mode (`--all`)

Refresh every open candidate in one run. This **reuses Steps 2–6 verbatim as the per-candidate
loop body** (Step 1's candidate selection is made non-interactively from the snapshot) — it adds
no new refresh logic, only iteration + fail-soft accounting + an aggregate summary.
Single-candidate mode (default / `--synthesis-slug`) is unaffected.

Initialise `RESULTS = []`. For each `candidate` in the `CANDIDATES` snapshot (Step 0.4), in
order:

1. Set `SYNTHESIS_SLUG = candidate.synthesis_slug` and `NEW_SOURCE_SLUGS =
   candidate.triggered_by_source` (this is Step 1's selection, made non-interactively from the
   snapshot — no `AskUserQuestion`).
2. Run **Steps 2 → 3 → 4 → 5 → 6** exactly as written for that candidate.
3. **Fail-soft:** if any step aborts for this candidate — a missing/stale synthesis page or
   project scaffold (Step 2), a `K == 0`-and-still-failing union, or a `compose`/`verify`/
   `finalize` failure (Steps 4–6) — **record the failure and continue to the next candidate;
   never abort the whole batch.** Append a row
   `{synthesis_slug, sources_unioned: <K>, verify: "<verbatim>/<paraphrase>/<unsupported>/<synthesis>" or "—", status: "ok" | "failed", note: <failed_phase>:<error> when failed}`
   to `RESULTS`. A successful candidate appends the same row shape with `status: "ok"` and its
   verify counts.
4. Do **not** clear the candidate yourself — Step 6's `knowledge-finalize` already clears each
   `refresh_candidates[]` entry as it lands (single-candidate Step 6 note), and that is just as
   true inside the loop.

When the loop finishes, emit the **batch summary** (Step 7's batch variant) and stop — do not
fall through to the single-synthesis Step 7.

### 1. Identify the candidate

- **`--synthesis-slug` given** → select the candidate whose `synthesis_slug` matches. If
  none of the `open` candidates match, abort: name the requested slug and list the open
  candidate slugs so the user can re-run with a valid one.
- **`--synthesis-slug` omitted** → `AskUserQuestion` (single-select) over the open
  candidates. One option per candidate, label = `synthesis_title` (truncated ~50 chars) +
  `synthesis_slug` in parentheses + the triggering source count, e.g.
  `(+2 new sources)`. The chosen option's `synthesis_slug` is `SYNTHESIS_SLUG`; its
  `triggered_by_source[]` is `NEW_SOURCE_SLUGS`.

Hold `SYNTHESIS_SLUG` and `NEW_SOURCE_SLUGS` (the source slugs to union in).

### 2. Locate the synthesis's project

The new source must be unioned into the **same** project that produced the synthesis —
that project's `ingest-manifest.json` is the existing evidence base. The project slug
lives on the synthesis page frontmatter (`derived_from_research`), **not** on the binding
candidate, so read the page:

1. Resolve the synthesis page: `<wiki_path>/syntheses/<SYNTHESIS_SLUG>.md`. If it does not
   exist, abort (the candidate is stale — suggest `knowledge-binding.py resolve-refresh-candidate`
   to clear it, or `knowledge-refresh --mode push` to re-research).
2. Read its YAML frontmatter and extract `derived_from_research`. If the key is absent or
   empty, abort with:
   > Synthesis `<SYNTHESIS_SLUG>` has no `derived_from_research` project — it was not
   > deposited by the inverted pipeline, so there is no ingest-manifest to union into.
   > Re-research the topic as a fresh project with `knowledge-refresh --mode push` instead.
3. Resolve `PROJECT_PATH = <knowledge_root>/<derived_from_research>/`. Assert
   `<PROJECT_PATH>/.metadata/plan.json` AND `<PROJECT_PATH>/.metadata/ingest-manifest.json`
   exist. If either is missing, abort naming the missing file (the project scaffold is
   incomplete — a manual `knowledge-refresh --mode push` is the safe route).

### 3. Union the new source(s) into the existing ingest-manifest

This is the load-bearing step — it is what keeps the refresh **additive** instead of a
thinning re-derivation. Avoid `knowledge-compose --source wiki` here — that mode re-derives
the manifest via `wiki-grounding`, the exact under-mapping regression this skill removes.
Instead, read the existing manifest and append only the genuinely-new sources.

For each slug in `NEW_SOURCE_SLUGS`:

1. Skip it if it already appears in `ingest-manifest.json::ingested[].slug` (idempotent — a
   re-run unions nothing twice).
2. Otherwise read its source page `<wiki_path>/sources/<slug>.md` frontmatter and build one
   `ingested[]` entry — `url` (from the page's `sources:`/`source_url`), `slug`, `title`,
   `publisher`, a one-line `summary`, `claims_extracted` (length of the page's
   `pre_extracted_claims[]`), and `sub_question_refs` (carry the plan's sub-question IDs from
   `<PROJECT_PATH>/.metadata/plan.json::sub_questions[].id`; if no precise mapping is
   available, attach all plan sub-question IDs so the composer sees the source's claims).
3. If the source page does not exist, record it as skipped and continue — never fail the
   whole refresh on one missing page.

Write the updated manifest back **atomically** via an inline `python3 -c` (write to a temp
file in the same dir, then `os.replace`), bumping `ingested_count` to `len(ingested)`. Mirror
the atomic-write posture the existing scripts use; never edit the JSON with a non-atomic
in-place rewrite. Print a one-line summary: `unioned <K> new source(s) into <N>-source manifest`.

If every `NEW_SOURCE_SLUGS` slug was already present (K == 0), the manifest is unchanged —
note it and continue to compose anyway (the source may have landed via a prior partial run;
re-composing against the already-unioned manifest is still the correct refresh).

### 4. Compose

Re-compose the synthesis against the now-unioned manifest. The composer reads the existing
`ingest-manifest.json` (Step 3's union), so the new source's claims are available alongside
the prior evidence:

```
Skill("cogni-knowledge:knowledge-compose",
      args="--knowledge-slug <knowledge_slug> --project-path <PROJECT_PATH> --knowledge-root <knowledge_root>")
```

Parse the `{success}` summary. On failure, capture `{failed_phase: "compose", error}`, report
it, and stop — do not run verify/finalize against a failed compose, and do not roll back (the
manifest union is already on disk and is safely re-composable on a re-run).

### 5. Verify

```
Skill("cogni-knowledge:knowledge-verify",
      args="--knowledge-slug <knowledge_slug> --project-path <PROJECT_PATH> --knowledge-root <knowledge_root>")
```

Capture the verify verdict counts (verbatim / paraphrase / unsupported / synthesis) for the
final summary. On failure, capture `{failed_phase: "verify", error}`, report, and stop.

### 6. Finalize (overwrite)

```
Skill("cogni-knowledge:knowledge-finalize",
      args="--knowledge-slug <knowledge_slug> --project-path <PROJECT_PATH> --knowledge-root <knowledge_root> --synthesis-slug <SYNTHESIS_SLUG> --overwrite --no-portal-prompt --no-concepts-prompt")
```

`--synthesis-slug <SYNTHESIS_SLUG>` is required — pass the slug held since Step 1, **not**
finalize's default. Without it, `knowledge-finalize` re-derives the deposit slug from
`slugify(plan.topic)`; when the existing synthesis slug diverges (it was originally finalized
with a custom `--synthesis-slug`, or hand-named), that derived slug points at no existing page,
so `--overwrite` never fires and finalize silently writes a **duplicate** synthesis instead of
refreshing the real one — and the wrong slug also leaves the `refresh_candidates[]` entry
uncleared. Passing the held slug makes the overwrite deterministic and the candidate-clear
reliable.

`--overwrite` is required — the synthesis page already exists, and finalize refuses to
clobber it without the flag. `--no-portal-prompt` and `--no-concepts-prompt` keep the run
autonomous (the portal/concepts diffs are still staged for later review, exactly as
push-mode does).

**Do not clear the refresh candidate yourself** — `knowledge-finalize` already calls
`knowledge-binding.py resolve-refresh-candidate --synthesis-slug <slug> [--cites <csv>]` during
its binding-append step, which removes the `refresh_candidates[]` entry. Now that Step 6 passes
the held `--synthesis-slug`, that deposit slug is deterministic and matches the candidate, so
finalize clears by exact `synthesis_slug` match; the `--cites` citation-overlap clear remains a
backstop for a hand-named or legacy candidate whose slug still diverges. Either way a second
`resolve-refresh-candidate` call here would be a redundant double-clear — let finalize own it.

On failure, capture `{failed_phase: "finalize", error}`, report, and stop.

### 7. Summary

**Single-candidate mode** (default / `--synthesis-slug`) — ≤ 8 lines:

- Refreshed synthesis: `<SYNTHESIS_SLUG>` (project `<derived_from_research>`)
- New source(s) unioned in: `<NEW_SOURCE_SLUGS>` (or "none new — re-composed against existing manifest")
- Evidence base: `<N>` sources (was `<N-K>`)
- Verify verdict: `<verbatim>/<paraphrase>/<unsupported>/<synthesis>`
- The `refresh_candidates[]` entry was cleared by finalize (Step 6)
- Suggested next: `/cogni-knowledge:knowledge-resume` to confirm the deposit, or
  `/cogni-knowledge:knowledge-dashboard` to re-render the overlay

If any phase failed, report `<failed_phase>: <error>` instead and note that the manifest
union is on disk, so re-running this skill resumes from a clean, already-unioned state.

**Batch mode (`--all`)** — one per-synthesis summary table over `RESULTS`, then a tally line:

| Synthesis | Sources unioned | Verify (vb/par/uns/syn) | Status |
|---|---|---|---|
| `<synthesis_slug>` | `<K>` | `<verbatim>/<paraphrase>/<unsupported>/<synthesis>` | ok |
| `<synthesis_slug>` | — | — | failed — `<failed_phase>: <error>` |
| … | | | |

`vb/par/uns/syn` = verbatim/paraphrase/unsupported/synthesis counts; `Status` ∈ `ok` | `failed` (matching the `RESULTS` row enum); a failed row shows `—` for the verify column it never reached.

- Batch tally: `<ok_count>` refreshed, `<failed_count>` failed, of `<len(CANDIDATES)>` open candidate(s).
- Each `✅ ok` candidate's `refresh_candidates[]` entry was cleared by its `knowledge-finalize`
  (Step 6); each `❌ failed` candidate's entry remains `open`, so re-running `--all` (or the
  single-candidate path on that slug) resumes it from its on-disk, already-unioned manifest.
- Suggested next: `/cogni-knowledge:knowledge-resume` to confirm the deposits, or
  `/cogni-knowledge:knowledge-dashboard` to re-render the overlay.
