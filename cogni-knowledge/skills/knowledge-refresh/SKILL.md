---
name: knowledge-refresh
description: "Refresh a bound cogni-knowledge base — two modes. Pull-mode delegates to cogni-wiki:wiki-refresh against the bound wiki to refresh stale pages from an existing research project. Push-mode lints the bound wiki, asks the user which stale topics to re-research, sequentially dispatches knowledge-research per selected topic, then dispatches wiki-refresh per new project so originally-stale pages refresh against the fresh evidence. Use this skill whenever the user says 'refresh my knowledge base', 'knowledge refresh push|pull', 'update stale pages in my <slug> base', 're-research stale topics in the eu-ai-act base', 'pull fresh research into the bound wiki'."
allowed-tools: Read, Bash, Glob, AskUserQuestion, Skill
---

# Knowledge Refresh

Close the self-healing loop for a bound cogni-knowledge base. Wiki pages age — `wiki-lint` flags `stale_page` (>365d) and `stale_draft` (>180d) findings, but lint alone doesn't bring fresh evidence. This skill has two modes:

- **Pull-mode** — the user already has a completed cogni-research project; we delegate to `cogni-wiki:wiki-refresh` to match its sub-questions to stale pages and refresh them.
- **Push-mode** — we lint the wiki, ask the user which stale pages they want fresh research on, sequentially dispatch `knowledge-research` per selected topic, then dispatch `wiki-refresh` per new project so the originally-stale pages refresh against the new evidence.

This skill is a pure orchestrator — pull-mode is a thin pass-through; push-mode composes `wiki-lint` + `knowledge-research` + `wiki-refresh` via existing skills, never re-implementing them.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once per session to remember the delegation boundary.

## When to run

- User wants to refresh stale pages in a bound knowledge base
- User has a fresh research project and wants to pipe it into the wiki (pull-mode)
- User wants the system to auto-research the stale topics (push-mode)

## Never run when

- No `binding.json` exists at the resolved knowledge root — route to `/cogni-knowledge:knowledge-setup`
- `research_projects[]` is empty AND `--mode pull` — there's no upstream research project to pull from; suggest `knowledge-research` instead
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

3. **Ask which stale topics to re-research.** `AskUserQuestion` with `multiSelect: true`. One option per stale page; the label is the page title (truncated to ~50 chars for readability), with the slug in parentheses. Default surfaced: none preselected (the user opts in explicitly). If the user picks zero, exit 0 cleanly.

4. **Batch confirmation.** `AskUserQuestion` (single-select) with the question: "Launch `<K>` sequential research runs against the `<knowledge_slug>` knowledge base? Each run costs roughly $1–$5." Options: `proceed`, `abort`. On `abort`, exit 0.

5. **Per-topic loop — research, then refresh.** For each selected stale page, sequentially:
   ```
   Skill("cogni-knowledge:knowledge-research",
         args="--knowledge-slug <knowledge_slug> --topic '<page title>'")
   ```
   Capture the new `<resolved_slug>` from the dispatch summary (parse `cogni-research-<slug>/` from the printed project path, same convention as `knowledge-research/SKILL.md` Step 1). On per-topic research failure, capture in `failures: [{topic, error}]` and skip to the next topic.

   On research success, immediately dispatch the matching refresh:
   ```
   Skill("cogni-wiki:wiki-refresh",
         args="--from-research <resolved_slug> --wiki-root <wiki_path>")
   ```
   The new research's topic was the originally-stale page title, so `wiki-refresh`'s Jaccard match should score high against the original page. The upstream skill runs its own batch-confirmation per dispatch — that's a feature: the user can decline a per-run plan if the match is unexpectedly weak.

   Interleaved (research-A → refresh-A → research-B → refresh-B …) rather than two batches: a mid-loop abort leaves a consistent partial state (each completed topic is fully landed), and refreshed pages are visible to the user sooner. Sequential overall — see `references/delegation-contract.md` §"Phase-3 push-refresh behaviour" for the contract.

6. **Final summary.** ≤ 8 lines:
   - `<N>` topics re-researched (slug list)
   - `<M>` pages refreshed downstream via `wiki-refresh`
   - `<K>` per-topic failures (topic + error)
   - Suggested next: `/cogni-knowledge:knowledge-resume` to confirm the new deposits, or `/cogni-knowledge:knowledge-dashboard` to re-render the overlay.

## Edge cases

- **Empty `research_projects[]` + pull-mode.** Pre-flight does not block this — the user may want to pull from a project deposited via another binding or hand-created on disk. Step 1(2) emits the "not in binding" warning if applicable, and `wiki-refresh` itself fails if the project files don't exist.
- **All selected topics fail to research in push-mode.** Step 5 captures every failure; step 6 reports honestly with `<N> = 0`.
- **Stale pages exist but `wiki-lint` returns no `stale_page`/`stale_draft` warnings.** Step 2 treats the audit as empty and exits cleanly.
- **User selects zero stale topics in step 3.** Exit 0 cleanly — the multi-select prompt is genuinely opt-in.
- **Inherited interactive menu mid-batch.** Each per-topic `knowledge-research` dispatch transitively invokes `cogni-research:research-setup`, which surfaces its own interactive menu (market, language, report type, source mode). The batch confirmation in step 4 gates the *count* of runs, not their per-run scope decisions — the user should expect `K` interactive prompts after answering "proceed".

## Out of scope

- **Cycle-detection between push-mode runs.** Phase 2's `cycle-guard.py` only fires on `report_source ∈ {wiki, hybrid}`. Push-mode invokes `knowledge-research`, which always lands at `report_source == web` (Mode A) — no circular evidence is possible by construction.
- **Auto-running `wiki-resume` or `knowledge-resume` after the batch.** Surfaced in the summary as a suggestion; manual decision.
- **Modifying the binding directly.** All binding writes flow through `knowledge-research`'s own `append-project` call.

For the push-mode UX contract (single batch confirmation, sequential, composition-only, no cost cap), see `references/delegation-contract.md` §"Phase-3 push-refresh behaviour".

## Output

- **Pull-mode:** upstream `wiki-refresh` output verbatim. Wiki pages updated by `wiki-update` (via `wiki-refresh`); raw refresh files under `<wiki_path>/raw/refresh-<slug>-<date>/`. No binding write.
- **Push-mode:**
  - One `<wiki_path>/wiki/audits/lint-<date>.md` from the upstream lint run (and one `lint` log line)
  - Per selected topic: a new `cogni-research-<slug>/` project, deposited wiki pages, one entry in `research_projects[]` (all written by `knowledge-research`)
  - Per new project: refreshed wiki pages and a raw refresh subdir (all written by `wiki-refresh`)

No files are written directly by this skill — every artefact comes from a downstream dispatch.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — the delegation boundary
- `cogni-wiki:wiki-refresh` SKILL.md — pull-mode and per-new-project dispatch target
- `cogni-wiki:wiki-lint` SKILL.md — push-mode staleness source
- `cogni-knowledge:knowledge-research` SKILL.md — push-mode per-topic dispatch target
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
