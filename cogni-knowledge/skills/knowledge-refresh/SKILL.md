---
name: knowledge-refresh
description: "Refresh a bound cogni-knowledge base. Push-mode lints the bound wiki, asks the user which stale topics to refresh, then runs the inverted pipeline per selected topic — the seven-phase chain knowledge-plan → knowledge-curate → knowledge-fetch → knowledge-ingest → (knowledge-distill, optional) → knowledge-compose → knowledge-verify → knowledge-finalize — so each stale topic gets a freshly-composed, claim-verified synthesis deposited into the bound wiki, and the concept/entity web is enriched along the way. An orthogonal opt-in --resweep flag re-verifies the bound wiki's cited claims against live source URLs by running the vendored claim-extractor + resweep-planner scripts and dispatching cogni-claims:claims submit/verify for the live-source re-check (composable with --mode push, or standalone). Use this skill whenever the user says 'refresh my knowledge base', 'knowledge refresh push', 'update stale pages in my <slug> base', 'refresh stale topics in the eu-ai-act base', 're-verify cited claims against live sources', 'resweep the bound wiki'."
allowed-tools: Read, Bash, Glob, AskUserQuestion, Skill
---

# Knowledge Refresh

Close the self-healing loop for a bound cogni-knowledge base. Wiki pages age — `wiki-lint` flags `stale_page` (>365d) and `stale_draft` (>180d) findings, but lint alone doesn't bring fresh evidence. **Push-mode** lints the wiki, asks the user which stale topics they want fresh evidence on, then runs the **inverted pipeline** per selected topic: the seven-phase chain `knowledge-plan` → `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-distill` (optional, fail-soft) → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`. Each topic ends with a freshly-composed, claim-verified `type: synthesis` page deposited into the bound wiki, and the distill step enriches the concept/entity web. An orthogonal opt-in `--resweep` flag re-verifies the bound wiki's cited claims against live source URLs.

This skill is a pure orchestrator — push-mode composes existing `cogni-knowledge` phase skills via `Skill(...)`, never re-implementing them. **Push-mode dispatches zero cogni-research skills** — cogni-research is 0% of the runtime path.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once per session to remember the delegation boundary and the Skill-dispatch convention (§"How `Skill(...)` blocks are written").

## When to run

- User wants to refresh stale pages in a bound knowledge base
- User wants the system to auto-research the stale topics (push-mode)
- User wants to re-verify the bound wiki's cited claims against live source URLs — `--resweep` (opt-in)

## Never run when

- No `binding.json` exists at the resolved knowledge root — route to `/cogni-knowledge:knowledge-setup`
- The bound wiki has zero stale pages AND `--mode push` — there's nothing to push-refresh
- `--resweep` was passed but the vendored wiki-claims-resweep scripts are missing from this install — abort with the standard missing-vendored-scripts message (Step 0 pre-flight)

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--mode` | No | `push` is the only mode and the default; `--mode push` is accepted as a no-op for back-compat. When `--resweep` is the only operation requested, no mode is required. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--resweep` | No | **Orthogonal opt-in.** Re-verify the bound wiki's cited claims against live source URLs by running the vendored `extract_page_claims.py` + `resweep_planner.py` scripts and dispatching `cogni-claims:claims submit/verify` against `binding.wiki_path` (the inline orchestration in §2). Composable: `--mode push --resweep` runs push then resweep; `--resweep` alone (no `--mode`) runs the resweep only. **Never auto-runs** — the per-run zero-network invariant is preserved. |
| `--resweep-page <slug>` | Resweep pass-through | Mapped to `extract_page_claims.py --page`. Sweep a single page only (mutually exclusive with `--resweep-stale-only`). |
| `--resweep-stale-only` | Resweep pass-through | Mapped to `extract_page_claims.py --stale-only`. Sweep only pages older than the staleness threshold. |
| `--resweep-days <N>` | Resweep pass-through | Mapped to `extract_page_claims.py --days` (only valid with `--resweep-stale-only`). |
| `--resweep-dry-run` | Resweep pass-through | Runs only the extract + `resweep_planner.py --phase plan` steps — materialises the plan + manifests under `raw/claims-resweep-<date>/` but dispatches no `cogni-claims` verification and runs no `--phase aggregate` (no report, no `last-resweep.json` write). |

The `--resweep-*` pass-throughs are explicitly prefixed so they namespace cleanly against the vendored scripts' own flags.

If `--mode` is missing and `--resweep` was not passed, default to push-mode — it is the only research workflow, so there is nothing to disambiguate. When `--resweep` is the only operation requested, run the resweep alone.

## Workflow

### 0. Pre-flight

**Required plugins.** Push-mode dispatches `cogni-wiki:wiki-lint` (to find stale topics) plus this plugin's own inverted-pipeline phase skills, so push-mode probes `cogni-wiki`. `--resweep` does **not** reach `cogni-wiki` — it runs the vendored `wiki-claims-resweep` scripts in-tree and dispatches `cogni-claims:claims` for the live-source re-check (probe both in the `--resweep` block below). Nothing here reaches cogni-research — it is 0% of the runtime path. Abort cleanly here rather than letting a downstream `Skill` dispatch fail with an opaque error. The probe handles both the dev-repo sibling layout (`../<plugin>/skills/...`) and the marketplace cache layout (`../../<plugin>/<version>/skills/...`):

```
probe_plugin() {
  local plugin="$1" skill="$2"
  test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
  for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
    [ -f "$d" ] && return 0
  done
  return 1
}
probe_plugin cogni-wiki wiki-setup && WIKI_OK=yes || WIKI_OK=no
```

If `WIKI_OK` is `no`, abort:

> cogni-knowledge requires `cogni-wiki` to be installed.
> Install it via the marketplace, then retry.

**When `--resweep` is passed**, the live-source re-check runs the **vendored** `wiki-claims-resweep` scripts in-tree (no `cogni-wiki` dispatch) and dispatches `cogni-claims:claims`. Probe both — the vendored script directory (vendored-first, mirroring `knowledge-dashboard`) and the `cogni-claims:claims` skill:

```
test -d "${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-claims-resweep/scripts" \
  && RESWEEP_SCRIPTS_OK=yes || RESWEEP_SCRIPTS_OK=no
probe_plugin cogni-claims claims && CLAIMS_OK=yes || CLAIMS_OK=no
```

If `RESWEEP_SCRIPTS_OK` is `no`, abort with the missing-vendored-scripts message:

> --resweep requires the vendored `wiki-claims-resweep` scripts, which are missing from this install.
> Reinstall/upgrade cogni-knowledge via the marketplace, then retry. (Push-mode does not need them; drop --resweep to run without the live-source re-check.)

If `CLAIMS_OK` is `no`, abort with the standard missing-plugin message:

> --resweep requires `cogni-claims` to be installed (it performs the live-source claim re-verification).
> Install it via the marketplace, then retry. (Push-mode does not need it; drop --resweep to run without the live-source re-check.)

Then continue with the binding-resolution checks:

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = cogni-knowledge/<knowledge-slug>/` (relative to the current working directory).

2. Read the binding:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false`, abort and offer `knowledge-setup`.

3. Extract `wiki_path`, `knowledge_slug`, and `research_projects[]`. Validate `binding.knowledge_slug == --knowledge-slug`. Confirm `<wiki_path>/.cogni-wiki/config.json` exists.

4. Mode dispatch:
   - Push-mode (default, or explicit `--mode push`) → §1, then (if `--resweep`) §2.
   - If `--resweep` with no `--mode` → skip §1 and go straight to §2 (the resweep is the work).

### 1. Push-mode

1. **Lint the bound wiki.** Dispatch:
   ```
   Skill("cogni-wiki:wiki-lint", args="--wiki-root <wiki_path> --skip-semantic")
   ```
   This writes one `lint` log line to `<wiki_path>/wiki/log.md` — acceptable noise for the value of going through the upstream skill rather than reaching into a sibling plugin's scripts.

2. **Parse stale findings.** Read the freshest audit file at `<wiki_path>/wiki/audits/lint-*.md` (sorted by filename, last one). Extract `stale_page` and `stale_draft` warnings — for each, capture the page slug and page title. If the stale set is empty, print "wiki is up to date — nothing to push-refresh" and exit 0.

3. **Ask which stale topics to refresh.** `AskUserQuestion` with `multiSelect: true`. One option per stale page; the label is the page title (truncated to ~50 chars for readability), with the slug in parentheses. Default surfaced: none preselected (the user opts in explicitly). If the user picks zero, exit 0 cleanly.

4. **Batch confirmation.** `AskUserQuestion` (single-select) with the question: "Run the inverted pipeline for `<K>` stale topics against the `<knowledge_slug>` knowledge base? Each topic runs the seven-phase chain (plan → curate → fetch → ingest → distill → compose → verify → finalize) and costs roughly $1–$5 in WebSearch/WebFetch budget." Options: `proceed`, `abort`. On `abort`, exit 0. This is the **single batch-level gate** — there is no per-topic confirmation from this skill.

5. **Per-topic loop — run the seven-phase inverted pipeline.** For each selected stale page, sequentially run the chain below. The page title is the topic. All dispatches pass `--knowledge-root <knowledge_root>` so they resolve the same base regardless of cwd. Parse each phase's `{success}` summary; **on any phase failure, capture `{topic, failed_phase, error}` in `failures[]` and skip to the next topic — do not run later phases for that topic, and do not roll back.** The manifests already on disk are the truth, and every phase is idempotent (see §"Push-mode resume contract" below), so a partial topic is safely resumable by re-running this skill.

   **Phase 1 — plan (idempotent guard).** `knowledge-plan` derives `project_path = <knowledge_root>/<topic-slug>-<today>/` and *aborts if that directory already exists* (it never overwrites; it `mkdir -p`s `<project_path>/.metadata/` before writing `plan.json`). So before dispatching, compute the same path — `topic_slug` = kebab-case of the page title (lowercase, alphanumerics + dashes, collapse dash runs, strip ends, cap 60 chars), `today = $(date -u +%F)` — and branch on the **project directory**, matching `knowledge-plan`'s own abort condition (not on `plan.json` alone, or a crashed prior plan that created the dir but no manifest would be re-dispatched into an abort):
   - **Dir does not exist** → dispatch `knowledge-plan` and capture the resolved `<project_path>` from the summary's "New project:" / "Plan path:" lines:
     ```
     Skill("cogni-knowledge:knowledge-plan",
           args="--knowledge-slug <knowledge_slug> --topic '<page title>' --knowledge-root <knowledge_root>")
     ```
   - **Dir exists AND `<project_path>/.metadata/plan.json` exists** → skip the dispatch and reuse `<project_path>` — the resume path for a same-day retry.
   - **Dir exists BUT `plan.json` is absent** (orphaned dir from a crashed plan) → do **not** re-dispatch; `knowledge-plan` would abort on the existing dir. Capture `{topic, failed_phase: "plan", error: "orphaned project dir <project_path> has no plan.json — remove it and re-run"}` and skip to the next topic.

   **Phases 2–7 — curate → fetch → ingest → distill → compose → verify → finalize.** Each takes the uniform `--knowledge-slug <slug> --project-path <project_path> --knowledge-root <knowledge_root>` interface; dispatch them in order, stopping that topic's chain on the first failure — **except `knowledge-distill`, which is fail-soft** (see below):
   ```
   Skill("cogni-knowledge:knowledge-curate",   args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
   Skill("cogni-knowledge:knowledge-fetch",    args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root> --no-cobrowse")
   Skill("cogni-knowledge:knowledge-ingest",   args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
   Skill("cogni-knowledge:knowledge-distill",  args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
   Skill("cogni-knowledge:knowledge-compose",  args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
   Skill("cogni-knowledge:knowledge-verify",   args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
   Skill("cogni-knowledge:knowledge-finalize", args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root> --no-portal-prompt")
   ```
   `knowledge-fetch` is passed `--no-cobrowse` explicitly — push-mode is autonomous, so it must never block on the cobrowse opt-in prompt (the bodies are already fetched during `knowledge-curate`; WebFetch misses stay unavailable rather than waiting for a browser). `knowledge-finalize` is passed `--no-portal-prompt` for the same reason — push-mode must never block on finalize's interactive apply-portal confirm; the autonomous loop continues to **stage** the portal diff (reviewable later via `<wiki>/.cogni-wiki/portal-proposed.md`, appliable with `--apply-portal` or a human-direct `knowledge-finalize`). **`knowledge-distill` (Phase 4.5) is optional + fail-soft**: it enriches the bound wiki's concept/entity web, but a distill failure must NOT fail the topic — do not capture it in `failures[]` and do not skip `compose`; just note it and continue (distill itself exits 0 even on internal failure, so this is belt-and-suspenders). `knowledge-finalize` deposits the verified draft as `<wiki>/syntheses/<slug>.md` and appends the project to `binding.json::research_projects[]` with `report_source: wiki` — that is the per-topic deliverable. Do not pass `--overwrite`; finalize refusing to clobber an existing synthesis is the correct resume behaviour.

   **What push-mode does and does not do to the stale page.** Push-mode brings fresh, claim-verified evidence into the base as a **new** `synthesis` page per topic. It does **not** rewrite or delete the originally-flagged stale page — the inverted pipeline has no in-place page-rewrite primitive, and the wiki separates `sources/` + `syntheses/` rather than editing arbitrary pages. The fresh synthesis supersedes the stale framing; the originally-flagged page stays on disk and a later `wiki-lint` may still flag it. Retiring or merging the old page is a manual decision — surface this in the final summary so the user is not surprised.

   Sequential overall (topic-A's full chain, then topic-B's) — `knowledge-binding.py append-project` writes without an external lock, so concurrent finalizes could race. See `references/delegation-contract.md` §"Phase-3 push-refresh behaviour" for the contract.

6. **Final summary.** ≤ 8 lines:
   - `<N>` topics finalized (synthesis slug list)
   - `<K>` topics with a per-phase failure — list each as `<topic> — failed at <failed_phase>: <error>` so the user knows exactly where to resume
   - To resume a failed topic, re-run `knowledge-refresh --mode push` and re-select it (the chain short-circuits on already-complete phases) — or run the remaining phases by hand from `<project_path>`
   - Note that the originally-flagged stale pages were **superseded by new syntheses, not rewritten** — they remain on disk and `wiki-lint` may still flag them; retire them manually if desired.
   - Suggested next: `/cogni-knowledge:knowledge-resume` to confirm the new deposits, or `/cogni-knowledge:knowledge-dashboard` to re-render the overlay.

### Push-mode resume contract

The per-topic loop fails soft: a topic that dies mid-chain leaves valid manifests on disk for the phases that completed. To resume, the user re-runs `knowledge-refresh --mode push` (same day) and re-selects the topic; each phase short-circuits on already-complete state by construction:

- **`knowledge-plan`** — Step 5's existence guard skips the re-dispatch when `<project_path>/.metadata/plan.json` already exists, because `knowledge-plan` itself aborts on an existing project dir (it never overwrites). Same-day retry → reuse; a retry on a later day computes a new `<topic-slug>-<date>` and starts a fresh project (acceptable — a day later you likely want fresh evidence anyway).
- **`knowledge-curate` / `knowledge-fetch`** — `candidate-store.py` and `fetch-cache.py` are dedup-by-construction; re-runs cost only the WebSearch/WebFetch budget for cache misses.
- **`knowledge-ingest`** — skips URLs already in `ingest-manifest.json::ingested[]` (orchestrator-side, URL-keyed); re-runs are a no-op on already-ingested slugs.
- **`knowledge-distill`** (optional, fail-soft) — `concept-store.py merge` is byte-stable on re-run (claim dedup + the on-disk created-vs-updated decision under the lock make an unchanged page a no-op); the orchestrator also skips re-dispatch when the source-claim-bundle hash is unchanged. A distill failure never blocks the topic chain.
- **`knowledge-compose`** — preserves the outline-recovery contract: a leftover `writer-outline-vN.json` from a crashed prior run triggers `RESUME_FROM_OUTLINE=true` so only Phase 2 re-runs.
- **`knowledge-verify`** — single-pass per round, max-2 revisor iterations. **`knowledge-finalize`** — refuses to overwrite an existing `<wiki>/syntheses/<slug>.md` without `--overwrite`, so a re-run after a successful finalize is a safe no-op.

### 2. Resweep — native inline orchestration (opt-in)

Runs **only when `--resweep` is passed** — after push completes (if `--mode push` was given), or **alone** when `--resweep` carries no `--mode`. It re-verifies the bound wiki's cited claims against **live** source URLs, the one thing the zero-network per-run pipeline structurally never does. Never auto-dispatched — the operator must pass the flag, so every finalize/verify/dashboard run stays zero-network and fast.

This is an **inline orchestration over the vendored `wiki-claims-resweep` scripts plus `cogni-claims`** — there is **no** `cogni-wiki:` dispatch. The two vendored scripts are deterministic plumbing (claim extraction + plan-materialize/aggregate); the live-source re-verification (WebFetch + LLM-compare against the live page) is `cogni-claims`' job. Resolve the vendored script directory **vendored-first**, exactly as `knowledge-dashboard`/`knowledge-resume` do:

```
source "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
RESWEEP_SCRIPTS=$(resolve_wiki_scripts wiki-claims-resweep extract_page_claims.py) \
  || abort "vendored wiki-claims-resweep scripts not found — reinstall cogni-knowledge"
```

**After a partial push (`--mode push --resweep` where ≥ 1 topic failed mid-chain):** the resweep still runs. Push-mode is fail-soft per topic, and a topic that crashed *before* `knowledge-finalize` deposited **no** `wiki/syntheses/<slug>.md` page — so there is nothing on disk for the resweep to scan, and it cannot surface phantom deviations on a partially-deposited topic. The resweep therefore covers only the syntheses that actually landed; failed topics are simply absent. No special skip logic needed.

1. **Extract candidate claims (vendored, deterministic).** Run `extract_page_claims.py` against the bound wiki, forwarding only the `--resweep-*` flags the caller actually set (omitted → script defaults). Map: `--resweep-page` → `--page`, `--resweep-stale-only` → `--stale-only`, `--resweep-days` → `--days`:
   ```
   python3 ${RESWEEP_SCRIPTS}/extract_page_claims.py \
     --wiki-root <binding.wiki_path> \
     [--page <resweep-page> | --stale-only [--days <resweep-days>]]
   ```
   Capture stdout as `EXTRACT_JSON`. Each `data.pages[].claims[]` carries `{statement, source_url, source_title, line}`. **If `data.stats.total_claims == 0`**, surface the zero-claims note (see the summary's `total_claims == 0` line) and exit 0 — nothing to re-verify.

2. **Materialize the plan (vendored, deterministic).** Pipe the extract output into `resweep_planner.py --phase plan` (it derives `wiki_root` from the extract JSON, so no separate `--wiki-root`):
   ```
   echo "$EXTRACT_JSON" | python3 ${RESWEEP_SCRIPTS}/resweep_planner.py --phase plan --extract-file -
   ```
   Capture stdout as `PLAN_JSON`. It writes `raw/claims-resweep-<date>/` under the wiki with one `<slug>-claims.md` manifest per page + `index.json`, and returns `data.workspace` (absolute), `data.workspace_rel`, `data.sweep_date`, `data.plan[]` (each `{slug, manifest_abs, claim_count, source_count, page_path, age_days}`), and `data.stats`. Hold `WORKSPACE=$(... data.workspace)`.

   **Opt-in confirmation gate.** Before any live re-fetch, `AskUserQuestion` (single-select): "Re-verify `<data.stats.total_claims>` claims across `<data.stats.pages>` page(s) against their live source URLs? This dispatches `cogni-claims` (WebFetch + LLM-compare) and costs live-source fetch budget." Options: `proceed`, `abort`. On `abort`, exit 0 — the materialized plan stays on disk for inspection. This gate replaces the upstream skill's own `proceed | refine | abort` batch confirmation and confirms **separately** from push-mode's per-batch gate (opt-in is the whole point).

   **`--resweep-dry-run` short-circuit.** When `--resweep-dry-run` was passed, stop here — the plan + manifests are materialized, but skip the confirmation gate, the `cogni-claims` dispatch (step 3), and the aggregate (step 4). No report, no `last-resweep.json` write.

3. **Re-verify against live sources (`cogni-claims`).** This is the live-source re-check the vendored scripts deliberately do not do. Submit the extracted claims into a `cogni-claims` workspace under the sweep workspace, then verify them — each claim is re-fetched (WebFetch) and LLM-compared against its live `source_url`:
   ```
   Skill("cogni-claims:claims", args="submit --working-dir <WORKSPACE> ...")   # one submission per plan page, claims from its <slug>-claims.md manifest
   Skill("cogni-claims:claims", args="verify --working-dir <WORKSPACE>")        # groups by URL, dispatches claim-verifier per source
   ```
   `cogni-claims` writes its verdicts into the workspace `claims.json` (ClaimRecord shape: each claim carries a per-source verification status).

4. **Aggregate (vendored, deterministic) → report + `last-resweep.json`.** Bridge the `cogni-claims` verdicts into the results shape `resweep_planner.py --phase aggregate` expects, then run aggregate. The bridge is inline (read the workspace `claims.json` + the plan's `index.json`, regroup per page slug, map each ClaimRecord's verification status to `verified` / `deviated` / `source_unavailable`) — emit `{"success": true, "data": {"pages": [{"slug": "<slug>", "claims": [{"status": "<verified|deviated|source_unavailable>", ...}]}]}}` and pipe it via stdin (no temp file needed):
   ```
   <build results JSON from claims.json + index.json> | \
     python3 ${RESWEEP_SCRIPTS}/resweep_planner.py \
       --phase aggregate --workspace "$WORKSPACE" --results-file -
   ```
   The aggregate phase writes `report.md` into `raw/claims-resweep-<date>/` **and** the lock-wrapped `<binding.wiki_path>/.cogni-wiki/last-resweep.json` (single-writer-per-wiki, via the vendored `_wiki_lock`) — so unlike the old dispatch, **this skill's §2 now drives that `last-resweep.json` write itself** (through the vendored aggregate). Capture `data.report_path`, `data.last_resweep_path`, `data.deviated_pages[]`, `data.unavailable_pages[]`, `data.stats`.

5. **Final summary (≤ 6 lines)** — from the aggregate output:
   ```
   Resweep complete against <binding.wiki_path>.
     <N> pages scanned, <T> claims checked.
     <V> verified, <D> deviated (across <K> pages), <U> source_unavailable (across <M> pages).
     Report: <data.report_path>. Reconcile flagged pages via cogni-wiki:wiki-update.
     last-resweep.json updated → knowledge-dashboard will surface the new date.
   ```
   **Synthesis-underyield note.** The extract classifies scanned pages by directory; surface the source-vs-synthesis split so the underyield is visible at run time: append `Note: yield is from wiki/sources/<slug>.md (inline-URL bodies); wiki/syntheses/<slug>.md ([N]/[[slug]] citations) underyield.` If `data.stats` exposes per-directory page counts, prefer the concrete form `Covered <K_src> source page(s); <K_syn> synthesis page(s) underyielded.`
   When `data.stats.total_claims == 0` for a `--resweep-page <slug>`, append: `⚠ <slug> yielded zero re-verifiable claims — this is a synthesis page or a page without inline URLs; resweep is most useful against wiki/sources/<slug>.md pages.`

## Edge cases

- **All selected topics fail mid-chain in push-mode.** Step 5 captures every failure with its `failed_phase`; step 6 reports honestly with `<N> = 0` and lists where each topic stopped.
- **Stale pages exist but `wiki-lint` returns no `stale_page`/`stale_draft` warnings.** Step 2 treats the audit as empty and exits cleanly.
- **User selects zero stale topics in step 3.** Exit 0 cleanly — the multi-select prompt is genuinely opt-in.
- **A phase dies after writing partial manifests.** Re-running the skill resumes from the last complete phase per the resume contract above — no manual cleanup needed for the common case.

## Out of scope

- **Cycle-detection between push-mode runs.** `knowledge-finalize` runs `cycle-guard.py` per topic before depositing the synthesis — that is where self-citing loops are refused, not in this orchestrator.
- **Auto-running `wiki-resume` or `knowledge-resume` after the batch.** Surfaced in the summary as a suggestion; manual decision.
- **Modifying the binding directly.** All binding writes flow through `knowledge-finalize`'s own `append-project` call (one per finalized topic, `report_source: wiki`).
- **In-place rewrite of the originally-flagged stale page.** Push-mode deposits a fresh `synthesis` and supersedes the stale framing; it does not edit or remove the old page (the inverted pipeline has no in-place page-rewrite primitive). Retiring the superseded page is a manual decision.
- **Extracting claims from synthesis-page `[N]` markers during `--resweep`.** The vendored `extract_page_claims.py` heuristic matches sentences containing inline `http(s)://` URLs or `[text](url)` links. `wiki/sources/<slug>.md` pages carry the verbatim fetched source body with inline URLs, so they **DO yield correctly**; but `wiki/syntheses/<slug>.md` pages use `[N]` markers backed by a `## References` block + bare `[[<slug>]]` backlinks and will **underyield**. Resweep is most useful against source pages.
- **Auto-running `--resweep` from `--mode push`, `knowledge-finalize`, or any cadence scheduler.** Opt-in only — a forced live re-fetch would reintroduce the WebFetch cost the inverted pipeline structurally fixed (`agents/wiki-verifier.md` §"What this agent does NOT do").

For the push-mode UX contract (single batch confirmation, sequential, composition-only), see `references/delegation-contract.md` §"Phase-3 push-refresh behaviour".

## Output

- **Push-mode:**
  - One `<wiki_path>/wiki/audits/lint-<date>.md` from the upstream lint run (and one `lint` log line)
  - Per selected topic: a new `<topic-slug>-<date>/` project directory with its six `.metadata/` manifests, one or more `wiki/sources/<slug>.md` pages, one `wiki/syntheses/<slug>.md` synthesis, one `research_projects[]` entry (`report_source: wiki`), and `compose` / `verify` / `finalize` lines in `wiki/log.md` — all written by the dispatched phase skills.
- **`--resweep`:**
  - A `<wiki_path>/raw/claims-resweep-<date>/` workspace (per-page `<slug>-claims.md` manifests + `index.json` + `report.md`), written by the vendored `resweep_planner.py`.
  - A lock-wrapped `<wiki_path>/.cogni-wiki/last-resweep.json`, written by `resweep_planner.py --phase aggregate`.
  - A `cogni-claims` workspace under the sweep dir with the live-source verification verdicts (`claims.json`).

This skill never uses the `Write` tool directly — push-mode artefacts come from downstream phase dispatches, and resweep artefacts are written by the vendored scripts (`resweep_planner.py`) and `cogni-claims`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — the delegation boundary and §"How `Skill(...)` blocks are written"
- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — the seven-phase chain push-mode drives
- `cogni-wiki:wiki-lint` SKILL.md — push-mode staleness source
- `${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-claims-resweep/scripts/extract_page_claims.py` — `--resweep` step 1 (deterministic claim extraction)
- `${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-claims-resweep/scripts/resweep_planner.py` — `--resweep` steps 2 + 4 (`--phase plan` materialize / `--phase aggregate` report + `last-resweep.json`)
- `cogni-claims:claims` SKILL.md — `--resweep` step 3 (live-source claim re-verification via `submit` / `verify`)
- `cogni-knowledge:knowledge-plan` … `knowledge-finalize` SKILL.md — push-mode per-topic phase chain
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
