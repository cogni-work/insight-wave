# Delegation contract

cogni-knowledge is a **thin orchestrator**. Its live v0.1.0 path delegates to `cogni-wiki` and forks the agents it needs locally (see `agents/`); the archived v0.0.x chain also delegated to `cogni-research`. This document is the precise contract: what cogni-knowledge owns vs. what it delegates.

## The hard rule

If a behavior already exists in `cogni-wiki` or `cogni-research`, cogni-knowledge MUST delegate to it. Re-implementing upstream behavior in this plugin is a design error, not a shortcut. The reasons:

1. **Bugfix locality.** A bug in wiki bootstrapping should be fixed in one place (`cogni-wiki:wiki-setup`), not in N orchestrators that each forked the logic.
2. **Clean absorption boundary.** cogni-research is being absorbed — runtime reached zero at v0.1.0; formal deprecation is Phase 6. The boundary stays clean only if we never duplicate `cogni-wiki` logic; the forked v0.1.0 agents under `agents/` are the one intentional, documented exception.
3. **Version skew.** `cogni-wiki` and `cogni-research` are released independently. Forked logic drifts; delegated logic tracks the upstream automatically.

> **Terminal-arc reversal (Phase 7+).** The hard rule above holds for the **entire research-absorption arc through v1.0** — keep delegating to `cogni-wiki`, do not fork it. It **inverts** for the cogni-wiki absorption arc (Phases 7–9, see `references/absorption-roadmap.md`): the committed single-installable-plugin FMO requires **internalizing** cogni-wiki, not delegating to it. From Phase 7 the wiki engine is **vendored** into `cogni-knowledge/scripts/` and that vendored copy becomes the single source of truth; by Phase 9 cogni-wiki is archived. **Until Phase 7 actually lands, this reversal is intent, not licence** — do not pre-emptively fork cogni-wiki logic into cogni-knowledge ahead of the planned vendoring (it would re-introduce exactly the drift reasons 1–3 warn about, with no upstream to track). The reasons above are not "wrong"; they are the cost the FMO knowingly accepts in exchange for one shippable plugin.

## What cogni-knowledge owns

- **`binding.json`.** The single new artifact. Records knowledge_slug, wiki path, deposited research_projects[]. Read/written by `scripts/knowledge-binding.py`.
- **Lineage stamping.** `derived_from_research: <slug>` on a deposited wiki page is cogni-knowledge-specific (`cogni-wiki` is general-purpose and has no concept of research lineage), so cycle-guard depends on it. `knowledge-finalize` sets it inline; the legacy `lineage-stamp.py` helper is archived under `_archive/scripts/`.
- **Skill choreography.** The order and conditional logic of dispatching upstream skills. This is real value — the user gets one-prompt workflows in exchange for the loss of fine-grained control.
- **Opinionated defaults.** `--skip-prefill-prompt` on `wiki-setup` so cogni-knowledge's own deposit-driven seeding (via the inverted pipeline) is not duplicated by canonical foundations.

## What cogni-knowledge delegates

| Behavior | Delegate target |
|---|---|
| Bootstrap a wiki (create directory layout, write `.cogni-wiki/config.json`, seed SCHEMA.md/index.md/log.md/overview.md) | `cogni-wiki:wiki-setup` |
| Cold-start a wiki from a research topic | `cogni-wiki:wiki-from-research` (Mode A) |
| Deposit an already-completed research project into a wiki | `cogni-wiki:wiki-from-research` (Mode B) |
| Configure a research project (interactive menu, market/language/tone/citations/source mode) | `cogni-research:research-setup` (transitively, via `wiki-from-research`) |
| Run the research pipeline (sub-questions, parallel researchers, writer, reviewer, claims) | `cogni-research:research-report` (transitively) |
| Write per-sub-question wiki pages | `cogni-wiki:wiki-ingest --discover research:<slug>` (transitively) |
| Read from a wiki during research (Phase 2+) | `cogni-research`'s `wiki-researcher` agent, via `report_source=wiki` in `cogni-research:research-setup` |
| Compute wiki health (broken links, missing frontmatter, entries_count drift) | `cogni-wiki:wiki-health` |
| Show wiki status | `cogni-wiki:wiki-resume` (which itself runs `wiki-health`) |
| Query the wiki (Phase 3) | native — vendored `wiki-grounding.py` (knowledge-query re-homed; no longer dispatches `cogni-wiki:wiki-query`) |
| Lint the wiki for staleness (Phase 3) | `cogni-wiki:wiki-lint` |
| Render the wiki dashboard (Phase 3) | native — vendored `render_dashboard.py` + `build_graph.py` (knowledge-dashboard re-homed; no longer dispatches `cogni-wiki:wiki-dashboard`) |
| Refresh stale pages from a research project (Phase 3 pull-mode) | `cogni-wiki:wiki-refresh` |

> **Note (M11+).** The rows describing `cogni-research:*` dispatch and `cogni-wiki:wiki-from-research` Mode A/B were the legacy `knowledge-research` / `knowledge-report` delegation targets, now archived under `_archive/`. The live v0.1.0 inverted pipeline does **not** use `wiki-from-research`; it writes `wiki/sources/*.md` and `wiki/syntheses/*.md` directly (see `references/inverted-pipeline.md`). Its live `Skill`-dispatch delegation surface is `cogni-wiki:wiki-setup` / `wiki-resume` / `wiki-lint` / `wiki-refresh`, plus cogni-wiki helper scripts called at script level (`backlink_audit.py`, `wiki_index_update.py`, `config_bump.py`, `rebuild_context_brief.py`). The read/render skills `knowledge-query` and `knowledge-dashboard` no longer dispatch `cogni-wiki:wiki-query` / `wiki-dashboard` — they resolve the wiki engine **vendored-first** under `scripts/vendor/cogni-wiki/` (`wiki-grounding.py`; `render_dashboard.py` + `build_graph.py`) and run with no `cogni-wiki` plugin installed (the install is a graceful-degradation fallback only).

## What about `agents/`?

Since v0.0.17 cogni-knowledge ships its own `agents/` directory, and the v0.1.0 inverted pipeline dispatches **zero** cogni-research agents. The seven local agents:

- `source-curator` (Phase 2 — forked from cogni-research; per-sub-question WebSearch + scoring + a Phase-4 WebFetch body-pull into the fetch-cache, Option B #292)
- `source-fetcher` (Phase 3 — net-new; cobrowse-only recovery of WebFetch misses, opt-in)
- `claim-extractor` (Phase 4 — forked from cogni-research; per-body claim extraction)
- `source-ingester` (Phase 4 — net-new; writes `wiki/sources/<slug>.md` with `pre_extracted_claims:`)
- `wiki-composer` (Phase 5 — forked from cogni-research `writer`; reads the populated wiki, emits a cited draft)
- `wiki-verifier` (Phase 6 — net-new; zero-network claim alignment, replaces the cogni-claims verifier)
- `revisor` (Phase 6 — forked from cogni-research; rephrase-or-drop on `unsupported` deviations)

These are point-in-time forks — drift from upstream is acceptable and documented in `references/inverted-pipeline.md` (the v0.1.0 source of truth). The legacy v0.0.x design delegated all agent dispatch upstream and shipped no local agents; that chain (`knowledge-research` / `knowledge-report`) is archived under `_archive/` — see `_archive/README.md`.

## How to add a new cogni-knowledge skill

1. Identify the user-facing job to be done.
2. Map the job to upstream primitives (cogni-wiki and/or cogni-research). If the mapping requires logic that does not exist upstream, push that logic upstream first — do not implement it in cogni-knowledge.
3. The new skill's body is: (a) read `binding.json`, (b) dispatch upstream skill(s), (c) update `binding.json` if state changed, (d) compose a summary.
4. If the skill needs new state, it goes in `binding.json` — never in a parallel manifest.
5. Scripts (`knowledge-*.py`) stay stdlib-only. Anything that needs a library belongs upstream.

## How `Skill(...)` blocks are written

Every fenced code block of the shape

    ```
    Skill("<plugin>:<skill>", args="…")
    ```

in a cogni-knowledge **orchestrator** SKILL.md (`knowledge-setup`, `knowledge-resume`, `knowledge-refresh`) is a **dispatch contract**: the orchestrating LLM MUST execute the call via the Skill tool, not output the literal text. The fenced shape (rather than inline backticks) is the canonical surface so the call survives copy-paste, line-wrap, and downstream rendering, and so contract tests can pin it with `grep`. The dispatch verb in the preceding prose — `Dispatch:`, `Delegate to`, or equivalent — reinforces the contract but the fenced block is the source of truth.

Phase skills (`knowledge-plan` … `knowledge-finalize`) **do not dispatch other skills**; they run Bash + agent dispatch only. If a future phase skill needs to dispatch a downstream skill, this convention applies to it too.

Scope: cogni-knowledge-internal. Sibling plugins (`cogni-wiki`, `cogni-research`, etc.) document their own dispatch conventions independently — this section does not constrain them.

Rationale (#350): named the convention so future readers and reviewers find it once, rather than re-deriving it from prose verbs at each site.

## What about Phase 2's `--allow-wiki-source` flag on `wiki-from-research`?

Phase 2 modifies `cogni-wiki:wiki-from-research` to lift its current abort on `report_source ∈ {wiki, hybrid}` projects, gated behind a new `--allow-wiki-source --cycle-guard-cleared` opt-in. This is the right pattern: the cycle-guard logic lives in cogni-knowledge (it is cogni-knowledge-specific — there is no general-purpose meaning to "research lineage" in `cogni-wiki`), but the deposit pathway lives in `cogni-wiki`. We add an opt-in flag instead of forking the deposit pathway.

## Wiring `report_source` into `binding.json`

`knowledge-finalize` is the only live skill that calls `knowledge-binding.py append-project`, and it hard-codes `--report-source wiki` — the v0.1.0 inverted pipeline only ever produces wiki-mode synthesis deposits. (The archived legacy chain read a live `report_source` from a cogni-research project config and could record `web` / `local` / `hybrid`; that path is gone.)

The guardrail rule still holds for any new codepath: a `report_source` value other than `wiki` MUST be sourced from real project state, never assumed.

## Phase-3 push-refresh behaviour

`knowledge-refresh --mode push` is the only skill that initiates new research runs without the user supplying a topic per run. As of **v0.0.26 (M10b)** push-mode drives the v0.1.0 inverted pipeline — the legacy `knowledge-research` + `wiki-refresh` pair is gone (that path transitively reached cogni-research, which the decision-1 clean break forbids). The contract:

- **One batch-level confirmation, not per-topic.** The user is asked twice: which stale topics to refresh (multi-select), and one yes/no on whether to run the pipeline for `<K>` topics at roughly $1–$5 of WebSearch/WebFetch budget each. There is no per-topic confirmation gate from this skill.
- **Composition only — no new orchestration logic.** Push-mode dispatches this plugin's own seven phase skills per selected topic, in order: `knowledge-plan` → `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`. Knowledge-refresh never re-implements a phase; if a phase skill changes, push-mode tracks the change automatically. Every phase skill probes only `cogni-wiki` and runs forked agents locally — no cogni-research dispatch anywhere in the chain.
- **Fail-soft per topic, idempotent resume.** A topic that dies mid-chain records `{topic, failed_phase, error}` and the loop skips to the next topic — no rollback. The manifests on disk are the truth, and each phase short-circuits on already-complete state (plan aborts-on-existing so refresh reuses an existing project dir; curate/fetch dedup-by-construction; ingest skips already-ingested URLs; compose honours the F11 outline-recovery contract; finalize refuses to overwrite a synthesis without `--overwrite`). Re-running the skill resumes a partial topic.
- **Sequential, not parallel.** `knowledge-binding.py append-project` (called by `knowledge-finalize`) writes via temp-file + `os.replace` without an external lock; concurrent finalizes could race. Sequential per-topic is the simple safe choice.
- **No cost cap by design.** The single batch confirmation is the user gate. A per-topic cap would either need a cost-aware orchestrator (none today) or surprise the user mid-batch.
- **Cycle-guarding is finalize's job.** Self-citing-loop refusal lives in `knowledge-finalize`'s `cycle-guard.py` pass per topic, not in this orchestrator.
