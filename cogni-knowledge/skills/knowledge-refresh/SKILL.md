---
name: knowledge-refresh
description: "Refresh a bound cogni-knowledge base — two modes. Pull-mode delegates to cogni-wiki:wiki-refresh against the bound wiki to refresh stale pages from an existing research project. Push-mode lints the bound wiki, asks the user which stale topics to refresh, then runs the v0.1.0 inverted pipeline per selected topic — the seven-phase chain knowledge-plan → knowledge-curate → knowledge-fetch → knowledge-ingest → knowledge-compose → knowledge-verify → knowledge-finalize — so each stale topic gets a freshly-composed, claim-verified synthesis deposited into the bound wiki. Use this skill whenever the user says 'refresh my knowledge base', 'knowledge refresh push|pull', 'update stale pages in my <slug> base', 'refresh stale topics in the eu-ai-act base', 'pull fresh research into the bound wiki'."
allowed-tools: Read, Bash, Glob, AskUserQuestion, Skill
---

# Knowledge Refresh

Close the self-healing loop for a bound cogni-knowledge base. Wiki pages age — `wiki-lint` flags `stale_page` (>365d) and `stale_draft` (>180d) findings, but lint alone doesn't bring fresh evidence. This skill has two modes:

- **Pull-mode** — the user already has a completed cogni-research project; we delegate to `cogni-wiki:wiki-refresh` to match its sub-questions to stale pages and refresh them. (Pull-mode is the legacy bridge; it stays unchanged.)
- **Push-mode** — we lint the wiki, ask the user which stale topics they want fresh evidence on, then run the **v0.1.0 inverted pipeline** per selected topic: the seven-phase chain `knowledge-plan` → `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`. Each topic ends with a freshly-composed, claim-verified `type: synthesis` page deposited into the bound wiki.

This skill is a pure orchestrator — pull-mode is a thin pass-through; push-mode composes existing `cogni-knowledge` phase skills via `Skill(...)`, never re-implementing them. **Push-mode dispatches zero cogni-research skills** — the v0.1.0 clean break (decision-1) means cogni-research is 0% of the runtime path. The legacy push-mode (which re-ran the old research+ingest chain) was replaced by the seven-phase inverted pipeline at v0.0.26.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once per session to remember the delegation boundary.

## When to run

- User wants to refresh stale pages in a bound knowledge base
- User has a fresh research project and wants to pipe it into the wiki (pull-mode)
- User wants the system to auto-research the stale topics (push-mode)

## Never run when

- No `binding.json` exists at the resolved knowledge root — route to `/cogni-knowledge:knowledge-setup`
- `research_projects[]` is empty AND `--mode pull` — there's no upstream research project to pull from; suggest `--mode push` (which builds fresh evidence via the inverted pipeline) instead
- The bound wiki has zero stale pages AND `--mode push` — there's nothing to push-refresh

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `<cwd>/<slug>/` unless `--knowledge-root` overrides. |
| `--mode` | Yes | `push` or `pull`. Selects the workflow. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--from-research <slug>` | Pull-mode only | Slug of the cogni-research project to pull from. Required when `--mode pull`. |
| `--days <N>` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --days`. |
| `--pages <slug,slug>` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --pages`. |
| `--match-threshold <float>` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --match-threshold` (default `0.30` upstream). |
| `--limit <N>` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --limit`. |
| `--force` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --force`. |
| `--related-sweep <yes\|no>` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --related-sweep`. |
| `--dry-run` | Pull pass-through | Forwarded to `cogni-wiki:wiki-refresh --dry-run`. |

If `--mode` is missing, ask the user once via `AskUserQuestion`. Do not infer.

## Workflow

### 0. Pre-flight (both modes)

**Required plugins.** Both modes dispatch only `cogni-wiki` (pull-mode → `wiki-refresh`; push-mode → `wiki-lint` to find stale topics) plus this plugin's own inverted-pipeline phase skills. Neither reaches cogni-research, so probe only `cogni-wiki` — the v0.1.0 clean break (decision-1: cogni-research is 0% of the runtime path; same posture as `knowledge-plan`). Abort cleanly here rather than letting a downstream `Skill` dispatch fail with an opaque error. The probe handles both the dev-repo sibling layout (`../<plugin>/skills/...`) and the marketplace cache layout (`../../<plugin>/<version>/skills/...`):

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

Then continue with the binding-resolution checks:

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = <cwd>/<knowledge-slug>/`.

2. Read the binding:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false`, abort and offer `knowledge-setup`.

3. Extract `wiki_path`, `knowledge_slug`, and `research_projects[]`. Validate `binding.knowledge_slug == --knowledge-slug`. Confirm `<wiki_path>/.cogni-wiki/config.json` exists.

4. Mode dispatch — jump to §1 (pull) or §2 (push).

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

4. **Batch confirmation.** `AskUserQuestion` (single-select) with the question: "Run the inverted pipeline for `<K>` stale topics against the `<knowledge_slug>` knowledge base? Each topic runs the seven-phase chain (plan → curate → fetch → ingest → compose → verify → finalize) and costs roughly $1–$5 in WebSearch/WebFetch budget." Options: `proceed`, `abort`. On `abort`, exit 0. This is the **single batch-level gate** — there is no per-topic confirmation from this skill.

5. **Per-topic loop — run the seven-phase inverted pipeline.** For each selected stale page, sequentially run the chain below. The page title is the topic. All dispatches pass `--knowledge-root <knowledge_root>` so they resolve the same base regardless of cwd. Parse each phase's `{success}` summary; **on any phase failure, capture `{topic, failed_phase, error}` in `failures[]` and skip to the next topic — do not run later phases for that topic, and do not roll back.** The manifests already on disk are the truth, and every phase is idempotent (see §"Push-mode resume contract" below), so a partial topic is safely resumable by re-running this skill.

   **Phase 1 — plan (idempotent guard).** `knowledge-plan` derives `project_path = <knowledge_root>/<topic-slug>-<today>/` and *aborts if that directory already exists* (it never overwrites). So before dispatching, compute the same path — `topic_slug` = kebab-case of the page title (lowercase, alphanumerics + dashes, collapse dash runs, strip ends, cap 60 chars), `today = $(date -u +%F)` — and check for `<project_path>/.metadata/plan.json`:
   - **If it exists** (a same-day retry of this topic): skip the dispatch and reuse `<project_path>` — this is the resume path.
   - **Else**: dispatch and capture the resolved `<project_path>` from the summary's "New project:" / "Plan path:" lines:
     ```
     Skill("cogni-knowledge:knowledge-plan",
           args="--knowledge-slug <knowledge_slug> --topic '<page title>' --knowledge-root <knowledge_root>")
     ```

   **Phases 2–7 — curate → fetch → ingest → compose → verify → finalize.** Each takes the uniform `--knowledge-slug <slug> --project-path <project_path> --knowledge-root <knowledge_root>` interface; dispatch them in order, stopping that topic's chain on the first failure:
   ```
   Skill("cogni-knowledge:knowledge-curate",   args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
   Skill("cogni-knowledge:knowledge-fetch",    args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
   Skill("cogni-knowledge:knowledge-ingest",   args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
   Skill("cogni-knowledge:knowledge-compose",  args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
   Skill("cogni-knowledge:knowledge-verify",   args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
   Skill("cogni-knowledge:knowledge-finalize", args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
   ```
   `knowledge-finalize` deposits the verified draft as `<wiki>/syntheses/<slug>.md` and appends the project to `binding.json::research_projects[]` with `report_source: wiki` — that is the per-topic deliverable. Do not pass `--overwrite`; finalize refusing to clobber an existing synthesis is the correct resume behaviour.

   Sequential overall (topic-A's full chain, then topic-B's) — `knowledge-binding.py append-project` writes without an external lock, so concurrent finalizes could race. See `references/delegation-contract.md` §"Phase-3 push-refresh behaviour" for the contract.

6. **Final summary.** ≤ 8 lines:
   - `<N>` topics finalized (synthesis slug list)
   - `<K>` topics with a per-phase failure — list each as `<topic> — failed at <failed_phase>: <error>` so the user knows exactly where to resume
   - To resume a failed topic, re-run `knowledge-refresh --mode push` and re-select it (the chain short-circuits on already-complete phases) — or run the remaining phases by hand from `<project_path>`
   - Suggested next: `/cogni-knowledge:knowledge-resume` to confirm the new deposits, or `/cogni-knowledge:knowledge-dashboard` to re-render the overlay.

### Push-mode resume contract

The per-topic loop fails soft: a topic that dies mid-chain leaves valid manifests on disk for the phases that completed. To resume, the user re-runs `knowledge-refresh --mode push` (same day) and re-selects the topic; each phase short-circuits on already-complete state by construction:

- **`knowledge-plan`** — Step 5's existence guard skips the re-dispatch when `<project_path>/.metadata/plan.json` already exists, because `knowledge-plan` itself aborts on an existing project dir (it never overwrites). Same-day retry → reuse; a retry on a later day computes a new `<topic-slug>-<date>` and starts a fresh project (acceptable — a day later you likely want fresh evidence anyway).
- **`knowledge-curate` / `knowledge-fetch`** — `candidate-store.py` and `fetch-cache.py` are dedup-by-construction; re-runs cost only the WebSearch/WebFetch budget for cache misses.
- **`knowledge-ingest`** — skips URLs already in `ingest-manifest.json::ingested[]` (orchestrator-side, URL-keyed); re-runs are a no-op on already-ingested slugs.
- **`knowledge-compose`** — preserves the F11 outline-recovery contract: a leftover `writer-outline-vN.json` from a crashed prior run triggers `RESUME_FROM_OUTLINE=true` so only Phase 2 re-runs.
- **`knowledge-verify`** — single-pass per round, max-2 revisor iterations. **`knowledge-finalize`** — refuses to overwrite an existing `<wiki>/syntheses/<slug>.md` without `--overwrite`, so a re-run after a successful finalize is a safe no-op.

## Edge cases

- **Empty `research_projects[]` + pull-mode.** Pre-flight does not block this — the user may want to pull from a project deposited via another binding or hand-created on disk. Step 1(2) emits the "not in binding" warning if applicable, and `wiki-refresh` itself fails if the project files don't exist.
- **All selected topics fail mid-chain in push-mode.** Step 5 captures every failure with its `failed_phase`; step 6 reports honestly with `<N> = 0` and lists where each topic stopped.
- **Stale pages exist but `wiki-lint` returns no `stale_page`/`stale_draft` warnings.** Step 2 treats the audit as empty and exits cleanly.
- **User selects zero stale topics in step 3.** Exit 0 cleanly — the multi-select prompt is genuinely opt-in.
- **A phase dies after writing partial manifests.** Re-running the skill resumes from the last complete phase per the resume contract above — no manual cleanup needed for the common case.

## Out of scope

- **Cycle-detection between push-mode runs.** `knowledge-finalize` runs `cycle-guard.py` (with the v0.0.24 citation-manifest fallback) per topic before depositing the synthesis — that is where self-citing loops are refused, not in this orchestrator.
- **Auto-running `wiki-resume` or `knowledge-resume` after the batch.** Surfaced in the summary as a suggestion; manual decision.
- **Modifying the binding directly.** All binding writes flow through `knowledge-finalize`'s own `append-project` call (one per finalized topic, `report_source: wiki`).

For the push-mode UX contract (single batch confirmation, sequential, composition-only), see `references/delegation-contract.md` §"Phase-3 push-refresh behaviour".

## Output

- **Pull-mode:** upstream `wiki-refresh` output verbatim. Wiki pages updated by `wiki-update` (via `wiki-refresh`); raw refresh files under `<wiki_path>/raw/refresh-<slug>-<date>/`. No binding write.
- **Push-mode:**
  - One `<wiki_path>/wiki/audits/lint-<date>.md` from the upstream lint run (and one `lint` log line)
  - Per selected topic: a new `<topic-slug>-<date>/` project directory with its six `.metadata/` manifests, one or more `wiki/sources/<slug>.md` pages, one `wiki/syntheses/<slug>.md` synthesis, one `research_projects[]` entry (`report_source: wiki`), and `compose` / `verify` / `finalize` lines in `wiki/log.md` — all written by the dispatched phase skills.

No files are written directly by this skill — every artefact comes from a downstream phase dispatch.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — the delegation boundary
- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — the seven-phase chain push-mode drives
- `cogni-wiki:wiki-refresh` SKILL.md — pull-mode dispatch target
- `cogni-wiki:wiki-lint` SKILL.md — push-mode staleness source
- `cogni-knowledge:knowledge-plan` … `knowledge-finalize` SKILL.md — push-mode per-topic phase chain
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
