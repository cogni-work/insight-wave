# Delegation contract

cogni-knowledge is a **thin orchestrator**. Every primitive delegates to `cogni-wiki` or `cogni-research`. This document is the precise contract: what cogni-knowledge owns vs. what it delegates.

## The hard rule

If a behavior already exists in `cogni-wiki` or `cogni-research`, cogni-knowledge MUST delegate to it. Re-implementing upstream behavior in this plugin is a design error, not a shortcut. The reasons:

1. **Bugfix locality.** A bug in wiki bootstrapping should be fixed in one place (`cogni-wiki:wiki-setup`), not in N orchestrators that each forked the logic.
2. **Future absorption.** Phase 6 absorbs `cogni-research` into this plugin. Until then, the absorption boundary is clean only if we never duplicate.
3. **Version skew.** `cogni-wiki` and `cogni-research` are released independently. Forked logic drifts; delegated logic tracks the upstream automatically.

## What cogni-knowledge owns

- **`binding.json`.** The single new artifact. Records knowledge_slug, wiki path, deposited research_projects[]. Read/written by `scripts/knowledge-binding.py`.
- **Lineage stamping.** `scripts/lineage-stamp.py` adds `derived_from_research: <slug>` to YAML frontmatter on deposited wiki pages. Phase 2's cycle-guard depends on this; we cannot push it upstream because the field is cogni-knowledge-specific (`cogni-wiki` is general-purpose and has no concept of research lineage).
- **Skill choreography.** The order and conditional logic of dispatching upstream skills. This is real value — the user gets one-prompt workflows in exchange for the loss of fine-grained control.
- **Opinionated defaults.** `--research-overrides report_type=detailed` if the caller did not pass any; `--skip-prefill-prompt` on `wiki-setup` so the seeding does not duplicate `knowledge-research`'s own deposit-driven seeding.

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
| Query the wiki (Phase 3) | `cogni-wiki:wiki-query` |
| Lint the wiki for staleness (Phase 3) | `cogni-wiki:wiki-lint` |
| Render the wiki dashboard (Phase 3) | `cogni-wiki:wiki-dashboard` |
| Refresh stale pages from a research project (Phase 3 pull-mode) | `cogni-wiki:wiki-refresh` |

## What about `agents/`?

> **Legacy (v0.0.x) contract.** Superseded for the v0.1.0 inverted-pipeline runtime path — see `references/inverted-pipeline.md`. Since v0.0.17 cogni-knowledge ships its own `agents/` directory (forked `source-curator`, `claim-extractor`, `wiki-composer`, `revisor`, plus net-new `source-fetcher`, `source-ingester`, `wiki-verifier`); the v0.1.0 path dispatches **zero** cogni-research agents. As of v0.0.26, `knowledge-refresh --mode push` runs those local phase skills/agents, not the legacy chain below. The paragraph below describes the original delegated-everything design and is retained for historical context until M11's docs rewrite.

cogni-knowledge has no `agents/` directory by design. All agent dispatch goes to upstream agents:

- `cogni-research/agents/section-researcher.md` (web research per sub-question)
- `cogni-research/agents/deep-researcher.md` (recursive web research for deep mode)
- `cogni-research/agents/local-researcher.md` (local-document research)
- `cogni-research/agents/wiki-researcher.md` (wiki-as-source research — load-bearing for Phase 2)
- `cogni-research/agents/writer.md`, `reviewer.md`, `revisor.md` (composition)
- `cogni-research/agents/claim-extractor.md`, `source-curator.md` (provenance)

When Phase 6 absorbs cogni-research, these agents move into `cogni-knowledge/agents/`. Until then, leaving them upstream means we benefit from any cogni-research patch immediately.

## How to add a new cogni-knowledge skill

1. Identify the user-facing job to be done.
2. Map the job to upstream primitives (cogni-wiki and/or cogni-research). If the mapping requires logic that does not exist upstream, push that logic upstream first — do not implement it in cogni-knowledge.
3. The new skill's body is: (a) read `binding.json`, (b) dispatch upstream skill(s), (c) update `binding.json` if state changed, (d) compose a summary.
4. If the skill needs new state, it goes in `binding.json` — never in a parallel manifest.
5. Scripts (`knowledge-*.py`) stay stdlib-only. Anything that needs a library belongs upstream.

## What about Phase 2's `--allow-wiki-source` flag on `wiki-from-research`?

Phase 2 modifies `cogni-wiki:wiki-from-research` to lift its current abort on `report_source ∈ {wiki, hybrid}` projects, gated behind a new `--allow-wiki-source --cycle-guard-cleared` opt-in. This is the right pattern: the cycle-guard logic lives in cogni-knowledge (it is cogni-knowledge-specific — there is no general-purpose meaning to "research lineage" in `cogni-wiki`), but the deposit pathway lives in `cogni-wiki`. We add an opt-in flag instead of forking the deposit pathway.

## Wiring `report_source` into `binding.json`

`knowledge-research` (v0.0.7) and `knowledge-report` (v0.0.6) both read the live `report_source` from `<project>/.metadata/project-config.json` and pass it through to `knowledge-binding.py append-project` — `wiki` for round-trip runs, `hybrid` if a user opts in, `web`/`local` for default Mode A invocations or when a user pivots away from wiki mode in the interactive menu.

The guardrail rule: when a new skill or codepath calls `append-project`, the `report_source` value MUST be sourced live from `<project>/.metadata/project-config.json`, never assumed.

## Phase-3 push-refresh behaviour

`knowledge-refresh --mode push` is the only skill that initiates new research runs without the user supplying a topic per run. As of **v0.0.26 (M10b)** push-mode drives the v0.1.0 inverted pipeline — the legacy `knowledge-research` + `wiki-refresh` pair is gone (that path transitively reached cogni-research, which the decision-1 clean break forbids). The contract:

- **One batch-level confirmation, not per-topic.** The user is asked twice: which stale topics to refresh (multi-select), and one yes/no on whether to run the pipeline for `<K>` topics at roughly $1–$5 of WebSearch/WebFetch budget each. There is no per-topic confirmation gate from this skill.
- **Composition only — no new orchestration logic.** Push-mode dispatches this plugin's own seven phase skills per selected topic, in order: `knowledge-plan` → `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`. Knowledge-refresh never re-implements a phase; if a phase skill changes, push-mode tracks the change automatically. Every phase skill probes only `cogni-wiki` and runs forked agents locally — no cogni-research dispatch anywhere in the chain.
- **Fail-soft per topic, idempotent resume.** A topic that dies mid-chain records `{topic, failed_phase, error}` and the loop skips to the next topic — no rollback. The manifests on disk are the truth, and each phase short-circuits on already-complete state (plan aborts-on-existing so refresh reuses an existing project dir; curate/fetch dedup-by-construction; ingest skips already-ingested URLs; compose honours the F11 outline-recovery contract; finalize refuses to overwrite a synthesis without `--overwrite`). Re-running the skill resumes a partial topic.
- **Sequential, not parallel.** `knowledge-binding.py append-project` (called by `knowledge-finalize`) writes via temp-file + `os.replace` without an external lock; concurrent finalizes could race. Sequential per-topic is the simple safe choice.
- **No cost cap by design.** The single batch confirmation is the user gate. A per-topic cap would either need a cost-aware orchestrator (none today) or surprise the user mid-batch.
- **Cycle-guarding is finalize's job.** Self-citing-loop refusal lives in `knowledge-finalize`'s `cycle-guard.py` pass per topic, not in this orchestrator.
