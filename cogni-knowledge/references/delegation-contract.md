# Delegation contract

cogni-knowledge is a **thin orchestrator** over a **vendored** wiki engine. Its live v0.1.0 path does not delegate to `cogni-wiki`: the wiki-absorption arc (Phases 7–9) has landed, so the engine is vendored into this plugin and `cogni-wiki` itself is retired — its prefix is registered in the repo-root `scripts/retired-plugins.json`. The archived v0.0.x chain delegated to `cogni-research`, which was absorbed earlier and is retired on the same register. This document is the precise contract: what cogni-knowledge owns vs. what it delegates.

## The hard rule

**Don't duplicate the vendored engine.** If a behavior already exists in the vendored engine, call it rather than re-implementing it here. The reason that survives the absorption intact:

1. **Bugfix locality.** A bug in wiki ingest should be fixed in one place (the vendored `wiki-ingest` helper scripts), not in N orchestrators that each forked the logic.

The forked v0.1.0 agents under `agents/` are the one intentional, documented exception. Where the vendored engine is resolved from is deliberately **not** restated here — the **Note (M11+)** under the delegation table is the canonical reference point for that rule, and a second copy would be a second thing to drift.

> **History — the superseded delegate-upstream rule.** Through the research-absorption arc this section instructed the opposite: a behavior that already existed in `cogni-wiki` or `cogni-research` had to be delegated to and never re-implemented, because the absorption boundary stayed clean only while upstream logic was never duplicated, and because independently released upstreams made forked logic drift while delegated logic tracked them automatically. The cogni-wiki absorption arc (Phases 7–9) reversed that by design — the committed single-installable-plugin FMO required **internalizing** cogni-wiki rather than delegating to it — and that arc has since landed, leaving no upstream to track. The delegate-upstream rule is therefore spent, not paused; it is recorded here so a reader who meets its wording elsewhere can date it, and because the reasons it gave were the cost the FMO knowingly accepted in exchange for one shippable plugin.

## What cogni-knowledge owns

- **`binding.json`.** The single new artifact. Records knowledge_slug, wiki path, deposited research_projects[]. Read/written by `scripts/knowledge-binding.py`.
- **Lineage stamping.** `derived_from_research: <slug>` on a deposited wiki page is cogni-knowledge-specific (`cogni-wiki` is general-purpose and has no concept of research lineage), so cycle-guard depends on it. `knowledge-finalize` sets it inline; the legacy `lineage-stamp.py` helper is archived under `_archive/scripts/`.
- **Skill choreography.** The order and conditional logic of the pipeline — which of this plugin's own phase skills run in which sequence, and which of its forked `agents/` each dispatches. This is real value — the user gets one-prompt workflows in exchange for the loss of fine-grained control.
- **Opinionated seeding.** The native setup scaffold seeds no canonical foundations — cogni-knowledge's own deposit-driven seeding (via the inverted pipeline) populates the base instead; the user can still prefill a base later with `knowledge-prefill`, the standalone skill that computes foundations natively on the vendored engine.

## What cogni-knowledge delegates

| Behavior | Delegate target |
|---|---|
| Bootstrap a wiki (create the directory layout + write `.cogni-wiki/config.json`) | native — `knowledge-setup` Step 3 scaffolds the skeleton + config; Step 3.5 curates the layout (SCHEMA/index/sub-indexes) via the vendored engine (no `cogni-wiki:wiki-setup` dispatch) |
| Cold-start a wiki from a research topic | `cogni-wiki:wiki-from-research` (Mode A) |
| Deposit an already-completed research project into a wiki | `cogni-wiki:wiki-from-research` (Mode B) |
| Configure a research project (interactive menu, market/language/tone/citations/source mode) | `cogni-research:research-setup` (transitively, via `wiki-from-research`) |
| Run the research pipeline (sub-questions, parallel researchers, writer, reviewer, claims) | `cogni-research:research-report` (transitively) |
| Write per-sub-question wiki pages | `cogni-wiki:wiki-ingest --discover research:<slug>` (transitively) |
| Read from a wiki during research (Phase 2+) | `cogni-research`'s `wiki-researcher` agent, via `report_source=wiki` in `cogni-research:research-setup` |
| Compute wiki health (broken links, missing frontmatter, entries_count drift) | native — vendored `health.py` (knowledge-health re-homed; no longer dispatches `cogni-wiki:wiki-health`) |
| Show wiki status | native — vendored `health.py` + direct reads of `context_brief.md` / `log.md` / `config.json` (knowledge-resume re-homed; no longer dispatches `cogni-wiki:wiki-resume`) |
| Query the wiki (Phase 3) | native — vendored `wiki-grounding.py` (knowledge-query re-homed; no longer dispatches `cogni-wiki:wiki-query`) |
| Lint the wiki for staleness (Phase 3) | native — vendored `lint_wiki.py` (knowledge-lint and knowledge-refresh push-mode re-homed; no longer dispatches `cogni-wiki:wiki-lint`) |
| Render the wiki dashboard (Phase 3) | native — vendored `render_dashboard.py` + `build_graph.py` (knowledge-dashboard re-homed; no longer dispatches `cogni-wiki:wiki-dashboard`) |

> **Note (M11+).** The rows describing `cogni-research:*` dispatch and `cogni-wiki:wiki-from-research` Mode A/B were the legacy `knowledge-research` / `knowledge-report` delegation targets, now archived under `_archive/`. The live v0.1.0 inverted pipeline does **not** use `wiki-from-research`; it writes `wiki/sources/*.md` and `wiki/syntheses/*.md` directly (see `references/inverted-pipeline.md`). Its live `Skill`-dispatch delegation surface is now **empty** — `knowledge-setup` scaffolds the wiki natively (no `cogni-wiki:wiki-setup`), and the lint / claims-resweep paths resolve the vendored engine, so cogni-knowledge dispatches **zero** `cogni-wiki:` skills at runtime. It still calls cogni-wiki helper scripts at **script level** from the vendored tree (`backlink_audit.py`, `wiki_index_update.py`, `config_bump.py`, `rebuild_context_brief.py`). The read/render skills `knowledge-query`, `knowledge-dashboard`, and `knowledge-resume` no longer dispatch `cogni-wiki:wiki-query` / `wiki-dashboard` / `wiki-resume` — they resolve the wiki engine **vendored-only** under `scripts/vendor/cogni-wiki/` (`wiki-grounding.py`; `render_dashboard.py` + `build_graph.py`; `health.py`) and run with no `cogni-wiki` plugin installed. `cogni-wiki` is retired, so there is no external engine source: the sibling and marketplace-cache probes were removed from both resolvers, and an external install is never consulted. Each of these read/render skills (`knowledge-resume`, `knowledge-dashboard`, `knowledge-query`, and the standalone `knowledge-health` / `knowledge-lint`) **sources** the shared `resolve_wiki_scripts()` helper from `scripts/resolve-wiki-scripts.sh` rather than inlining it — `tests/test_resolve_wiki_scripts.sh` case `resolve-wiki-16` asserts no skill carries an inline copy. Its Python peer, `_knowledge_lib.resolve_wiki_scripts`, is a separate copy by necessity (a standalone Python driver cannot source a shell snippet), and **this note is the canonical reference point for the pair**: when the resolution rule changes, change both.

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
2. Map the job to the primitives this plugin already owns — the vendored engine's helper scripts, this plugin's own `scripts/`, and its forked `agents/`. Where the vendored engine already does the job, call it rather than re-implementing it (see **The hard rule**); logic that genuinely does not exist yet is implemented here, because here is the only place left to implement it.
3. The new skill's body is: (a) read `binding.json`, (b) do the work natively — vendored engine scripts plus this plugin's own agents, and for an orchestrator skill its own phase skills, written per **How `Skill(...)` blocks are written** below, (c) update `binding.json` if state changed, (d) compose a summary.
4. If the skill needs new state, it goes in `binding.json` — never in a parallel manifest.
5. Scripts (`knowledge-*.py`) stay stdlib-only. A job that needs a third-party library needs a different design: there is no external engine left to hand the dependency to.

> **History — the superseded map-to-upstream authoring rule.** Through the research-absorption arc steps 2, 3 and 5 read the other way round: a new skill's job had to be mapped onto `cogni-wiki` / `cogni-research` primitives, logic missing from those upstreams had to be pushed upstream *first* rather than implemented here, the skill body was to dispatch upstream skill(s), and anything needing a library belonged upstream too. The rationale was the same one **The hard rule**'s History note already records, and is not restated here. The cogni-wiki absorption arc (Phases 7–9) reversed that by design, and that arc has since landed — the engine is vendored and both prefixes are retired, so there is no upstream to map onto, push to, or dispatch. The map-to-upstream authoring rule is therefore spent, not paused; it is recorded here so a reader who meets its wording in an archived skill under `_archive/` can date it.

## How `Skill(...)` blocks are written

Every fenced code block of the shape

    ```
    Skill("<plugin>:<skill>", args="…")
    ```

in a cogni-knowledge **orchestrator** SKILL.md (`knowledge-setup`, `knowledge-resume`, `knowledge-refresh`) is a **dispatch contract**: the orchestrating LLM MUST execute the call via the Skill tool, not output the literal text. The fenced shape (rather than inline backticks) is the canonical surface so the call survives copy-paste, line-wrap, and downstream rendering, and so contract tests can pin it with `grep`. The dispatch verb in the preceding prose — `Dispatch:`, `Delegate to`, or equivalent — reinforces the contract but the fenced block is the source of truth.

Phase skills (`knowledge-plan` … `knowledge-finalize`) **do not dispatch other skills**; they run Bash + agent dispatch only. If a future phase skill needs to dispatch a downstream skill, this convention applies to it too.

Scope: cogni-knowledge-internal. It constrains this plugin's own orchestrator skills and nothing else; the retired `cogni-wiki` / `cogni-research` prefixes documented their own dispatch conventions independently while they existed.

Rationale (#350): named the convention so future readers and reviewers find it once, rather than re-deriving it from prose verbs at each site.

## What about Phase 2's `--allow-wiki-source` flag on `wiki-from-research`?

It was never built, and it will not be. `cogni-wiki` is retired (see the preamble), so `wiki-from-research` is unreachable and there is no external deposit pathway left to gate. The live inverted pipeline writes its deposits directly (see **Note (M11+)** and `references/inverted-pipeline.md`), which removes the abort the flag existed to lift.

The half that survived is the cycle guard. It was always the cogni-knowledge-specific half, and it is still here: `scripts/cycle-guard.py`, run per topic by `knowledge-finalize` against the citation manifest, refusing self-citing loops on its own rather than clearing a downstream deposit call.

> **History — the superseded `--allow-wiki-source` opt-in plan.** Phase 2 of the absorption roadmap planned to modify `cogni-wiki:wiki-from-research` to lift its abort on `report_source ∈ {wiki, hybrid}` projects, gated behind a new `--allow-wiki-source --cycle-guard-cleared` opt-in. The rationale was a split of ownership: the cycle-guard logic was cogni-knowledge-specific — "research lineage" had no general-purpose meaning in `cogni-wiki` — while the deposit pathway lived upstream, so adding an opt-in flag was cheaper and cleaner than forking that pathway. The cogni-wiki absorption arc (Phases 7–9) overtook the plan by internalizing the engine outright, and the flag pair was never implemented on either side. It is spent, not deferred; it is recorded here because the archived caller still passes it — `_archive/skills/knowledge-report/SKILL.md` dispatches with `--allow-wiki-source --cycle-guard-cleared` — so a reader who meets those flags there can date them.

## Wiring `report_source` into `binding.json`

`knowledge-finalize` is the only live skill that calls `knowledge-binding.py append-project`, and it hard-codes `--report-source wiki` — the v0.1.0 inverted pipeline only ever produces wiki-mode synthesis deposits. (The archived legacy chain read a live `report_source` from a cogni-research project config and could record `web` / `local` / `hybrid`; that path is gone.)

The guardrail rule still holds for any new codepath: a `report_source` value other than `wiki` MUST be sourced from real project state, never assumed.

## Phase-3 push-refresh behaviour

`knowledge-refresh --mode push` is the only skill that initiates new research runs without the user supplying a topic per run. As of **v0.0.26 (M10b)** push-mode drives the v0.1.0 inverted pipeline — the legacy `knowledge-research` + `wiki-refresh` pair is gone (that path transitively reached cogni-research, which the decision-1 clean break forbids). The contract:

- **One batch-level confirmation, not per-topic.** The user is asked twice: which stale topics to refresh (multi-select), and one yes/no on whether to run the pipeline for `<K>` topics at roughly $1–$5 of WebSearch/WebFetch budget each. There is no per-topic confirmation gate from this skill.
- **Composition only — no new orchestration logic.** Push-mode dispatches this plugin's own seven required phase skills per selected topic, in order: `knowledge-plan` → `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → optional, fail-soft `knowledge-distill` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`. Knowledge-refresh never re-implements a phase; if a phase skill changes, push-mode tracks the change automatically. Every phase skill resolves the engine vendored-only and runs forked agents locally — it probes for no installed plugin, and there is no cogni-research dispatch anywhere in the chain (see **Note (M11+)** for the resolution rule).
- **Fail-soft per topic, idempotent resume.** A topic that dies mid-chain records `{topic, failed_phase, error}` and the loop skips to the next topic — no rollback. The manifests on disk are the truth, and each phase short-circuits on already-complete state (plan aborts-on-existing so refresh reuses an existing project dir; curate/fetch dedup-by-construction; ingest skips already-ingested URLs; compose honours the F11 outline-recovery contract; finalize refuses to overwrite a synthesis without `--overwrite`). Re-running the skill resumes a partial topic.
- **Sequential, not parallel.** `knowledge-binding.py append-project` (called by `knowledge-finalize`) writes via temp-file + `os.replace` without an external lock; concurrent finalizes could race. Sequential per-topic is the simple safe choice.
- **No cost cap by design.** The single batch confirmation is the user gate. A per-topic cap would either need a cost-aware orchestrator (none today) or surprise the user mid-batch.
- **Cycle-guarding is finalize's job.** Self-citing-loop refusal lives in `knowledge-finalize`'s `cycle-guard.py` pass per topic, not in this orchestrator.
