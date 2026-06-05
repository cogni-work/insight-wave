---
name: knowledge-refresh
description: "Refresh a bound cogni-knowledge base — two modes. Pull-mode delegates to cogni-wiki:wiki-refresh against the bound wiki to refresh stale pages from an existing research project. Push-mode lints the bound wiki, asks the user which stale topics to refresh, then runs the inverted pipeline per selected topic — the seven-phase chain knowledge-plan → knowledge-curate → knowledge-fetch → knowledge-ingest → (knowledge-distill, optional) → knowledge-compose → knowledge-verify → knowledge-finalize — so each stale topic gets a freshly-composed, claim-verified synthesis deposited into the bound wiki, and the concept/entity web is enriched along the way. An orthogonal opt-in --resweep flag re-verifies the bound wiki's cited claims against live source URLs by delegating to cogni-wiki:wiki-claims-resweep (composable with --mode, or standalone). Use this skill whenever the user says 'refresh my knowledge base', 'knowledge refresh push|pull', 'update stale pages in my <slug> base', 'refresh stale topics in the eu-ai-act base', 'pull fresh research into the bound wiki', 're-verify cited claims against live sources', 'resweep the bound wiki'."
allowed-tools: Read, Bash, Glob, AskUserQuestion, Skill
---

# Knowledge Refresh

Close the self-healing loop for a bound cogni-knowledge base. Wiki pages age — `wiki-lint` flags `stale_page` (>365d) and `stale_draft` (>180d) findings, but lint alone doesn't bring fresh evidence. This skill has two modes:

- **Pull-mode** — the user already has a completed cogni-research project; we delegate to `cogni-wiki:wiki-refresh` to match its sub-questions to stale pages and refresh them. (Pull-mode is the legacy bridge; it stays unchanged.)
- **Push-mode** — we lint the wiki, ask the user which stale topics they want fresh evidence on, then run the **inverted pipeline** per selected topic: the seven-phase chain `knowledge-plan` → `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-distill` (optional, fail-soft) → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`. Each topic ends with a freshly-composed, claim-verified `type: synthesis` page deposited into the bound wiki, and the distill step enriches the concept/entity web.

This skill is a pure orchestrator — pull-mode is a thin pass-through; push-mode composes existing `cogni-knowledge` phase skills via `Skill(...)`, never re-implementing them. **Push-mode dispatches zero cogni-research skills** — cogni-research is 0% of the runtime path.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once per session to remember the delegation boundary and the Skill-dispatch convention (§"How `Skill(...)` blocks are written").

## When to run

- User wants to refresh stale pages in a bound knowledge base
- User has a fresh research project and wants to pipe it into the wiki (pull-mode)
- User wants the system to auto-research the stale topics (push-mode)
- User wants to re-verify the bound wiki's cited claims against live source URLs — `--resweep` (opt-in)

## Never run when

- No `binding.json` exists at the resolved knowledge root — route to `/cogni-knowledge:knowledge-setup`
- `research_projects[]` is empty AND `--mode pull` — there's no upstream research project to pull from; suggest `--mode push` (which builds fresh evidence via the inverted pipeline) instead
- The bound wiki has zero stale pages AND `--mode push` — there's nothing to push-refresh
- `--resweep` was passed but `cogni-wiki:wiki-claims-resweep` is not installed — abort with the standard missing-plugin message (Step 0 pre-flight)

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--mode` | Yes, **except** when `--resweep` is the only operation requested | `push` or `pull`. Selects the workflow. When `--resweep` is passed without `--mode`, the resweep IS the work — no mode is required and the missing-mode `AskUserQuestion` is suppressed. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--from-research <slug>` | Pull-mode only | Slug of the cogni-research project to pull from. Required when `--mode pull`. |
| `--days <N>` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --days`. |
| `--pages <slug,slug>` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --pages`. |
| `--match-threshold <float>` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --match-threshold` (default `0.30` upstream). |
| `--limit <N>` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --limit`. |
| `--force` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --force`. |
| `--related-sweep <yes\|no>` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --related-sweep`. |
| `--dry-run` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --dry-run`. |
| `--resweep` | No | **Orthogonal opt-in.** Re-verify the bound wiki's cited claims against live source URLs by dispatching `cogni-wiki:wiki-claims-resweep` against `binding.wiki_path`. Composable: `--mode push --resweep` runs push then resweep; `--resweep` alone (no `--mode`) runs the resweep only. **Never auto-runs** — the per-run zero-network invariant is preserved. |
| `--resweep-page <slug>` | Resweep pass-through | Forwarded to `wiki-claims-resweep --page`. Sweep a single page only (mutually exclusive with `--resweep-stale-only`). |
| `--resweep-stale-only` | Resweep pass-through | Forwarded to `wiki-claims-resweep --stale-only`. Sweep only pages older than the upstream staleness threshold. |
| `--resweep-days <N>` | Resweep pass-through | Forwarded to `wiki-claims-resweep --days` (only valid with `--resweep-stale-only`). |
| `--resweep-dry-run` | Resweep pass-through | Forwarded to `wiki-claims-resweep --dry-run`. Materialises the plan + manifests under `raw/claims-resweep-<date>/` but dispatches no cogni-claims verification and writes no report. |

The `--resweep-*` pass-throughs are prefixed to avoid colliding with the pull-mode `--days` / `--pages` / `--dry-run` flags (those forward to `wiki-refresh`, a different upstream skill).

If `--mode` is missing **and `--resweep` was not passed**, ask the user once via `AskUserQuestion`. Do not infer. When `--resweep` is the only operation requested, skip that prompt — the resweep is the work.

## Workflow

### 0. Pre-flight (both modes)

**Required plugins.** Both modes dispatch only `cogni-wiki` (pull-mode → `wiki-refresh`; push-mode → `wiki-lint` to find stale topics) plus this plugin's own inverted-pipeline phase skills. Neither reaches cogni-research, so probe only `cogni-wiki` — cogni-research is 0% of the runtime path. Abort cleanly here rather than letting a downstream `Skill` dispatch fail with an opaque error. The probe handles both the dev-repo sibling layout (`../<plugin>/skills/...`) and the marketplace cache layout (`../../<plugin>/<version>/skills/...`):

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

**When `--resweep` is passed**, additionally probe the resweep target (`probe_plugin cogni-wiki wiki-claims-resweep && RESWEEP_OK=yes || RESWEEP_OK=no`). If `RESWEEP_OK` is `no`, abort with the standard missing-plugin message:

> --resweep requires `cogni-wiki:wiki-claims-resweep` to be installed.
> Install/upgrade cogni-wiki via the marketplace, then retry. (The push/pull modes do not need it; drop --resweep to run without the live-source re-check.)

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
   - If `--mode pull` → §1, then (if `--resweep`) §3.
   - If `--mode push` → §2, then (if `--resweep`) §3.
   - If `--resweep` with no `--mode` → skip §1/§2 and go straight to §3 (the resweep is the work).

### 1. Pull-mode

1. Verify `--from-research <slug>` is set. If not, abort with: "pull-mode requires --from-research <slug>. Provide the slug of an existing cogni-research project to pull from." (Pull-mode is a thin wrapper; we let the user pick which project to use rather than auto-selecting.)

2. Optional sanity check (warning only, do not abort): if `--from-research <slug>` is not present in `research_projects[]`, emit one line — "note: <slug> is not currently recorded in this binding; wiki-refresh will still proceed if the project files exist on disk". This catches typos without blocking a legitimate cross-binding pull.

3. Dispatch:
   ```
   Skill("cogni-wiki:wiki-refresh",
         args="--from-research <slug> --wiki-root <wiki_path> [pass-through flags]")
   ```
   Forward `--days`, `--pages`, `--match-threshold`, `--limit`, `--force`, `--related-sweep`, `--dry-run` only if the caller passed them.

4. Print the upstream summary verbatim. No binding write — pull-mode mutates wiki pages, not the binding (the original deposit's binding entry stays as the historical record).

### 2. Push-mode

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

   **What push-mode does and does not do to the stale page.** Push-mode brings fresh, claim-verified evidence into the base as a **new** `synthesis` page per topic. Unlike the legacy push-mode (which dispatched `wiki-refresh` to rewrite the flagged page in place), it does **not** rewrite or delete the originally-flagged stale page — the inverted pipeline has no in-place page-rewrite primitive, and the wiki separates `sources/` + `syntheses/` rather than editing arbitrary pages. The fresh synthesis supersedes the stale framing; the originally-flagged page stays on disk and a later `wiki-lint` may still flag it. Retiring or merging the old page is a manual `cogni-wiki:wiki-update` decision — surface this in the final summary so the user is not surprised.

   Sequential overall (topic-A's full chain, then topic-B's) — `knowledge-binding.py append-project` writes without an external lock, so concurrent finalizes could race. See `references/delegation-contract.md` §"Phase-3 push-refresh behaviour" for the contract.

6. **Final summary.** ≤ 8 lines:
   - `<N>` topics finalized (synthesis slug list)
   - `<K>` topics with a per-phase failure — list each as `<topic> — failed at <failed_phase>: <error>` so the user knows exactly where to resume
   - To resume a failed topic, re-run `knowledge-refresh --mode push` and re-select it (the chain short-circuits on already-complete phases) — or run the remaining phases by hand from `<project_path>`
   - Note that the originally-flagged stale pages were **superseded by new syntheses, not rewritten** — they remain on disk and `wiki-lint` may still flag them; retire them via `cogni-wiki:wiki-update` if desired.
   - Suggested next: `/cogni-knowledge:knowledge-resume` to confirm the new deposits, or `/cogni-knowledge:knowledge-dashboard` to re-render the overlay.

### Push-mode resume contract

The per-topic loop fails soft: a topic that dies mid-chain leaves valid manifests on disk for the phases that completed. To resume, the user re-runs `knowledge-refresh --mode push` (same day) and re-selects the topic; each phase short-circuits on already-complete state by construction:

- **`knowledge-plan`** — Step 5's existence guard skips the re-dispatch when `<project_path>/.metadata/plan.json` already exists, because `knowledge-plan` itself aborts on an existing project dir (it never overwrites). Same-day retry → reuse; a retry on a later day computes a new `<topic-slug>-<date>` and starts a fresh project (acceptable — a day later you likely want fresh evidence anyway).
- **`knowledge-curate` / `knowledge-fetch`** — `candidate-store.py` and `fetch-cache.py` are dedup-by-construction; re-runs cost only the WebSearch/WebFetch budget for cache misses.
- **`knowledge-ingest`** — skips URLs already in `ingest-manifest.json::ingested[]` (orchestrator-side, URL-keyed); re-runs are a no-op on already-ingested slugs.
- **`knowledge-distill`** (optional, fail-soft) — `concept-store.py merge` is byte-stable on re-run (claim dedup + the on-disk created-vs-updated decision under the lock make an unchanged page a no-op); the orchestrator also skips re-dispatch when the source-claim-bundle hash is unchanged. A distill failure never blocks the topic chain.
- **`knowledge-compose`** — preserves the outline-recovery contract: a leftover `writer-outline-vN.json` from a crashed prior run triggers `RESUME_FROM_OUTLINE=true` so only Phase 2 re-runs.
- **`knowledge-verify`** — single-pass per round, max-2 revisor iterations. **`knowledge-finalize`** — refuses to overwrite an existing `<wiki>/syntheses/<slug>.md` without `--overwrite`, so a re-run after a successful finalize is a safe no-op.

### 3. Resweep dispatch (opt-in)

Runs **only when `--resweep` is passed** — after push/pull completes (if a `--mode` was given), or **alone** when `--resweep` carries no `--mode`. It re-verifies the bound wiki's cited claims against **live** source URLs, the one thing the zero-network per-run pipeline structurally never does. Never auto-dispatched — the operator must pass the flag, so every finalize/verify/dashboard run stays zero-network and fast.

**After a partial push (`--mode push --resweep` where ≥ 1 topic failed mid-chain):** the resweep still runs. Push-mode is fail-soft per topic, and a topic that crashed *before* `knowledge-finalize` deposited **no** `wiki/syntheses/<slug>.md` page — so there is nothing on disk for the resweep to scan, and it cannot surface phantom deviations on a partially-deposited topic. The resweep therefore covers only the syntheses that actually landed; failed topics are simply absent. No special skip logic needed.

1. Confirm `RESWEEP_OK == yes` (the Step 0 probe). If `no`, the skill already aborted in pre-flight.

2. Dispatch the upstream primitive against the bound wiki, forwarding only the `--resweep-*` flags the caller actually set (omitted → upstream defaults apply):
   ```
   Skill("cogni-wiki:wiki-claims-resweep",
         args="--wiki-root <binding.wiki_path> [--page <resweep-page> | --stale-only [--days <resweep-days>]] [--dry-run]")
   ```
   Map: `--resweep-page` → `--page`, `--resweep-stale-only` → `--stale-only`, `--resweep-days` → `--days`, `--resweep-dry-run` → `--dry-run`. The upstream skill runs its own `AskUserQuestion proceed | refine | abort` batch confirmation — the resweep confirms **separately** from push-mode's per-batch gate (do not suppress it; opt-in is the whole point).

3. **No binding write, no `last-resweep.json` write.** `wiki-claims-resweep` writes `<binding.wiki_path>/.cogni-wiki/last-resweep.json` itself (lock-wrapped, single-writer-per-wiki) and its own report under `<wiki_root>/raw/claims-resweep-<date>/`. cogni-knowledge does not duplicate or shadow that state.

4. **Final summary (≤ 6 lines)** — capture the upstream summary and surface:
   ```
   Resweep dispatched against <binding.wiki_path>.
     <N> pages scanned, <T> claims checked.
     <V> verified, <D> deviated (across <K> pages), <U> source_unavailable (across <M> pages).
     Report: <relative path>. Reconcile flagged pages via cogni-wiki:wiki-update.
     last-resweep.json updated → knowledge-dashboard will surface the new date.
   ```
   **Synthesis-underyield note.** The upstream report classifies scanned pages by directory; surface the source-vs-synthesis split so the underyield is visible at run time: append `Note: yield is from wiki/sources/<slug>.md (inline-URL bodies); wiki/syntheses/<slug>.md ([N]/[[slug]] citations) underyield.` If the upstream summary exposes per-directory page counts, prefer the concrete form `Covered <K_src> source page(s); <K_syn> synthesis page(s) underyielded.`
   When the upstream reports `total_claims == 0` for a `--resweep-page <slug>`, append: `⚠ <slug> yielded zero re-verifiable claims — this is a synthesis page or a page without inline URLs; resweep is most useful against wiki/sources/<slug>.md pages.`

## Edge cases

- **Empty `research_projects[]` + pull-mode.** Pre-flight does not block this — the user may want to pull from a project deposited via another binding or hand-created on disk. Step 1(2) emits the "not in binding" warning if applicable, and `wiki-refresh` itself fails if the project files don't exist.
- **All selected topics fail mid-chain in push-mode.** Step 5 captures every failure with its `failed_phase`; step 6 reports honestly with `<N> = 0` and lists where each topic stopped.
- **Stale pages exist but `wiki-lint` returns no `stale_page`/`stale_draft` warnings.** Step 2 treats the audit as empty and exits cleanly.
- **User selects zero stale topics in step 3.** Exit 0 cleanly — the multi-select prompt is genuinely opt-in.
- **A phase dies after writing partial manifests.** Re-running the skill resumes from the last complete phase per the resume contract above — no manual cleanup needed for the common case.

## Out of scope

- **Cycle-detection between push-mode runs.** `knowledge-finalize` runs `cycle-guard.py` per topic before depositing the synthesis — that is where self-citing loops are refused, not in this orchestrator.
- **Auto-running `wiki-resume` or `knowledge-resume` after the batch.** Surfaced in the summary as a suggestion; manual decision.
- **Modifying the binding directly.** All binding writes flow through `knowledge-finalize`'s own `append-project` call (one per finalized topic, `report_source: wiki`).
- **In-place rewrite of the originally-flagged stale page.** Push-mode deposits a fresh `synthesis` and supersedes the stale framing; it does not edit or remove the old page (the legacy `wiki-refresh`-rewrite path is gone with the clean break). Retiring the superseded page is a manual `cogni-wiki:wiki-update` decision.
- **Extracting claims from synthesis-page `[N]` markers during `--resweep`.** The upstream `extract_page_claims.py` heuristic matches sentences containing inline `http(s)://` URLs or `[text](url)` links. `wiki/sources/<slug>.md` pages carry the verbatim fetched source body with inline URLs, so they **DO yield correctly**; but `wiki/syntheses/<slug>.md` pages use `[N]` markers backed by a `## References` block + bare `[[<slug>]]` backlinks and will **underyield**. Resweep is most useful against source pages.
- **Auto-running `--resweep` from `--mode push|pull`, `knowledge-finalize`, or any cadence scheduler.** Opt-in only — a forced live re-fetch would reintroduce the WebFetch cost the inverted pipeline structurally fixed (`agents/wiki-verifier.md` §"What this agent does NOT do").

For the push-mode UX contract (single batch confirmation, sequential, composition-only), see `references/delegation-contract.md` §"Phase-3 push-refresh behaviour".

## Output

- **Pull-mode:** upstream `wiki-refresh` output verbatim. Wiki pages updated by `wiki-update` (via `wiki-refresh`); raw refresh files under `<wiki_path>/raw/refresh-<slug>-<date>/`. No binding write.
- **Push-mode:**
  - One `<wiki_path>/wiki/audits/lint-<date>.md` from the upstream lint run (and one `lint` log line)
  - Per selected topic: a new `<topic-slug>-<date>/` project directory with its six `.metadata/` manifests, one or more `wiki/sources/<slug>.md` pages, one `wiki/syntheses/<slug>.md` synthesis, one `research_projects[]` entry (`report_source: wiki`), and `compose` / `verify` / `finalize` lines in `wiki/log.md` — all written by the dispatched phase skills.

No files are written directly by this skill — every artefact comes from a downstream phase dispatch.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — the delegation boundary and §"How `Skill(...)` blocks are written"
- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — the seven-phase chain push-mode drives
- `cogni-wiki:wiki-refresh` SKILL.md — pull-mode dispatch target
- `cogni-wiki:wiki-lint` SKILL.md — push-mode staleness source
- `cogni-wiki:wiki-claims-resweep` SKILL.md — `--resweep` dispatch target (live-source re-verification)
- `cogni-knowledge:knowledge-plan` … `knowledge-finalize` SKILL.md — push-mode per-topic phase chain
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
