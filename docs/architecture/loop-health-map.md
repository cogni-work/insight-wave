# insight-wave loop-health map

A one-time, **read-only** application of the cogni-service loop-anatomy rubric
across every plugin **loop** in this monorepo — the ecosystem's first
loop-health baseline, requested as a repo-wide hardening baseline and mirroring
the managed-service marketplace sweep precedent. It grades each loop against
the five moves and the anti-pattern map, cites concrete evidence for every
finding, and — just as importantly — records the **clean passes**, because a
clean pass is load-bearing per the rubric: it is what makes a flagged finding
credible.

- **Swept:** 2026-07-07
- **Rubric:** the `loop-anatomy.md` reference shipped with the cogni-service
  plugin (`skills/service-review/references/loop-anatomy.md`) — five moves
  (Discovery / Handoff / Verification / Persistence / Scheduling); five
  anti-patterns, each = one move skipped (blind / tangled / nodding / amnesiac /
  manual); two unattended-safety sub-signals (no-caps / no-checkpoint);
  severity policy (caps at `major`, never `critical`; judgment-heavy calls →
  advisory `minor`; only statically-confirmable signals with a concrete
  file + section location are flagged).
- **Scope:** all 13 plugins in this repo's marketplace — cogni-claims,
  cogni-consult, cogni-copywriting, cogni-help, cogni-knowledge,
  cogni-marketing, cogni-narrative, cogni-portfolio, cogni-sales, cogni-trends,
  cogni-visual, cogni-website, cogni-workspace.
- **Nature:** read-only. This map is a data artifact; it changes no loop and
  proposes no specific code edits. Any targeted hardening of a flagged loop is
  a further, evidence-gated concern — decided from this baseline, not
  pre-filed off it.

## How to read this

A **loop** is a skill or flow that repeats to make progress — a pipeline that
advances stages, a per-topic drain, or a generate→evaluate→revise gate. A
single-pass read-only dashboard or orienter that reads state, recommends, and
stops is **not** a loop and is excluded from rubric application (recorded as a
summary-table row for coverage, never counted as a finding). Single-pass
generate pipelines whose verification lives in a separate downstream skill are
likewise excluded — the downstream verify loop is what gets graded.

Evidence locations are cited as `path :: anchor` (a step, section, or named
construct a read-only pass can confirm). "Unattended?" gates the two
sub-signals — they apply only to loops designed to run without a human in the
loop (autonomous drivers, batch drains). Nearly every skill here is
**human-driven interactive** (a user invokes it in a session), so
unattended-safety sub-signals are assessed only where a driver genuinely runs
hands-off.

## Summary

| # | Loop | Source | Unattended? | Verdict | Findings |
|---|------|--------|-------------|---------|----------|
| 1 | knowledge-verify verifier→revisor loop | `cogni-knowledge/skills/knowledge-verify/SKILL.md` | Yes (dispatched by autonomous drivers) | ✅ Clean pass *(rubric exemplar)* | — |
| 2 | knowledge-run seven-phase driver | `cogni-knowledge/skills/knowledge-run/SKILL.md` | Yes (unattended-through-finalize by design) | ✅ Clean pass | — |
| 3 | knowledge-refresh push-mode topic drain | `cogni-knowledge/skills/knowledge-refresh/SKILL.md` | Partially (one batch confirm, then per-topic autonomous) | ✅ Clean pass | — |
| 4 | verify-trend-report reviewer→revisor loop | `cogni-trends/skills/verify-trend-report/SKILL.md` | No | ✅ Clean pass *(rubric exemplar)* | — |
| 5 | compete stakeholder-review auto-rewrite loop | `cogni-portfolio/skills/compete/SKILL.md` | No | ✅ Clean pass | — |
| 6 | propositions ordered quality-gate chain | `cogni-portfolio/skills/propositions/SKILL.md` | No | ✅ Clean pass | — |
| 7 | review-brief assessor verdict loop | `cogni-visual/skills/review-brief/SKILL.md` | No | ✅ Clean pass | — |
| 8 | story-to-slides stakeholder-review loop (story-to-* family) | `cogni-visual/skills/story-to-slides/SKILL.md` | No | ✅ Clean pass | — |
| 9 | why-change assess-revise-reassess loop | `cogni-sales/skills/why-change/SKILL.md` | No | ✅ Clean pass | — |
| 10 | copy-reader persona review + auto-improvement | `cogni-copywriting/skills/copy-reader/SKILL.md` | No (but agent-callable) | ⚠ 1 major | nodding (Verification) |
| 11 | consult-design-thinking DT stage machine | `cogni-consult/skills/consult-design-thinking/SKILL.md`, `cogni-consult/scripts/dt-stage-advance.sh` | No | ⚠ 1 advisory-minor | nodding-adjacent (Verification) |
| — | trend-research enrichment stage | `cogni-trends/skills/trend-research/SKILL.md` | — | — *(not a loop — excluded)* | single-pass fan-out with retry-once + deterministic JSON gate; manifest hashes hand drift detection downstream |
| — | trend-synthesis composer pipeline | `cogni-trends/skills/trend-synthesis/SKILL.md` | — | — *(not a loop — excluded)* | single-pass ordered assembly with resume gates; verification lives in verify-trend-report (Loop 4) |
| — | narrative transform | `cogni-narrative/skills/narrative/SKILL.md` | — | — *(not a loop — excluded)* | single-pass transform; Phase-5 gates are inline deterministic checks (header count, citation count, word bands) |
| — | narrative-review scorer | `cogni-narrative/skills/narrative-review/SKILL.md` | — | — *(not a loop — excluded)* | single-pass read-only scorer; the fresh-context Verification resource other loops cite |
| — | campaign-builder | `cogni-marketing/skills/campaign-builder/SKILL.md` | — | — *(not a loop — excluded)* | single-pass campaign assembly with gap inventory |
| — | marketing-setup | `cogni-marketing/skills/marketing-setup/SKILL.md` | — | — *(not a loop — excluded)* | single-pass interactive project scaffold with hard/soft validation gates |
| — | website-plan | `cogni-website/skills/website-plan/SKILL.md` | — | — *(not a loop — excluded)* | single-pass interactive planning; step-4 iterate-until-confirm is a human conversation, not a machine loop |
| — | website-build | `cogni-website/skills/website-build/SKILL.md` | — | — *(not a loop — excluded)* | single-pass build fan-out with legal-compliance gate + deterministic completeness checks |
| — | consult-resume orienter | `cogni-consult/skills/consult-resume/SKILL.md` | — | — *(not a loop — excluded)* | single-pass read-only recommender ("never edits engagement state") |
| — | knowledge-resume orienter | `cogni-knowledge/skills/knowledge-resume/SKILL.md` | — | — *(not a loop — excluded)* | single-pass read-only status view (only side effect: health-check log line) |
| — | marketing-resume orienter | `cogni-marketing/skills/marketing-resume/SKILL.md` | — | — *(not a loop — excluded)* | single-pass status + next-action recommendation |
| — | portfolio-resume orienter | `cogni-portfolio/skills/portfolio-resume/SKILL.md` | — | — *(not a loop — excluded)* | single-pass dashboard + recommendation |
| — | trends-resume orienter | `cogni-trends/skills/trends-resume/SKILL.md` | — | — *(not a loop — excluded)* | single-pass pipeline-position detection + routing |
| — | website-resume orienter | `cogni-website/skills/website-resume/SKILL.md` | — | — *(not a loop — excluded)* | single-pass state detection + routing to the next skill |
| — | cogni-claims (all skills) | `cogni-claims/skills/` | — | — *(assessed empty — no loop surfaces)* | grep over `skills/` for iteration caps / revise-loop / auto-rewrite signals returned zero hits |
| — | cogni-help (all skills) | `cogni-help/skills/` | — | — *(assessed empty — no loop surfaces)* | same grep basis, zero hits across 7 skills |
| — | cogni-workspace (all skills) | `cogni-workspace/skills/` | — | — *(assessed empty — no loop surfaces)* | same grep basis, zero hits across 9 skills |

**Totals:** 11 loops assessed (14 flows excluded as non-loops; 3 plugins
assessed-empty). **9 clean passes.** **2 loops flagged, 2 findings: 1 `major`
(copy-reader, nodding), 1 advisory `minor` (consult-design-thinking,
nodding-adjacent).** Zero `critical`.

Supporting tooling note: `cogni-portfolio-evals/scripts/grade_review_loop.py`
and `cogni-portfolio-evals/scripts/grade_compete_review_loop.py` are offline
eval-harness graders for the compete review loop — ground-truth evidence for
Loop 5's Verification move, not loop entries themselves.

---

## Loop 1 — knowledge-verify verifier→revisor loop

**Source:** `cogni-knowledge/skills/knowledge-verify/SKILL.md`.
**Unattended?** Yes — it is a phase in the autonomous `knowledge-run` /
`knowledge-refresh` chains, so it must behave safely with no human present.

| Move | Assessment | Evidence |
|------|------------|----------|
| Discovery | ✅ Healthy | Each round re-reads real state: draft version resolved from disk (`SKILL.md :: Step 1`), manifest freshness asserted against the on-disk draft (`:: Step 2`), and round ≥1 re-scores only the deterministically derived `DELTA_IDS` — computed from a manifest diff against a pre-round snapshot, explicitly **not** from the revisor's self-reported `fixes_applied` (`:: Step 3.3`, "which an LLM could under-report"). |
| Handoff | ✅ Healthy | Structured contracts everywhere: shard files → `wiki-verifier` via `CITATIONS_PATH`/`VERIFY_OUT_PATH`, fragments merged by `verify-store.py merge` with an id-set conservation check; the revisor writes raw-text citation records that `citation-store.py build` serializes and gate-checks (verbatim-substring + known-URL gates) — no prose-parsing (`:: Step 3.1`, `:: Step 3.3`). |
| Verification | ✅ Healthy | Generator and grader never share a context: `wiki-verifier` (fresh-context, zero-network) scores every citation; `revisor` (separate fresh-context agent) only repairs; the next round's verifier re-scores the repairs. The loop's exit is computed from the merged verdict file, not from the revisor's claims (`:: Step 3.2`). |
| Persistence | ✅ Healthy | Every round leaves a durable audit trail: `verify-vN.json` per round, `draft-v{N+1}.md` per revisor round, rebuilt `citation-manifest.json`, an appended `wiki/log.md` line, and a `run-metrics.json` phase ledger (`:: Steps 4–7`). On a mid-loop failure the prior `verify-vN.json` is explicitly named as "the latest valid audit trail". |
| Scheduling | ✅ Healthy | Hard cap of 2 revisor rounds, enforced structurally: `--max-rounds` values ≥3 are **rejected**, not accepted ("the 2-iteration cap is a structural property of the contract, not a tunable", `:: Step 0.5`). EXHAUSTED termination is surfaced as a warning, never silently swallowed (`:: Step 6`). |

**Sub-signals:** no-caps ✅ (hard 2-round ceiling, rejection of higher values,
per-shard wall-clock target). no-checkpoint ✅ (verify never ships anything —
the deposit is Phase 7's job, and an exhausted loop hands the decision to the
operator: "the operator decides whether to ship the draft anyway").

**Verdict: ✅ Clean pass — no findings.** This is the repo's strongest loop:
capped, fresh-context-graded, deterministically re-scored, fully persisted.

---

## Loop 2 — knowledge-run seven-phase driver

**Source:** `cogni-knowledge/skills/knowledge-run/SKILL.md`.
**Unattended?** Yes — the default gating-policy menu offers "run unattended
through finalize", and `--no-pause` is an explicit fully-unattended contract.

| Move | Assessment | Evidence |
|------|------------|----------|
| Discovery | ✅ Healthy | The resume entry recomputes `phase_reached` from on-disk artifacts every invocation via `pipeline-summary.py project` (`SKILL.md :: §0.5`) — the skip set is derived from real state, never from a remembered plan. A fully-finalized project is detected and exits as a clean no-op. |
| Handoff | ✅ Healthy | Every phase takes the same uniform CLI contract (`--knowledge-slug / --project-path / --knowledge-root`) and returns a `{success}` envelope the driver parses; the deliverable contract (deposited synthesis + `binding.json` append) is owned by the dispatched phase, not re-implemented (`:: §2`). |
| Verification | ✅ Healthy | The driver never self-grades — verification is wholly delegated to the `knowledge-verify` phase (Loop 1) and finalize's conformance gate; a phase failure stops the chain rather than being papered over (`:: §2`, "on a failure … STOP the chain"). |
| Persistence | ✅ Healthy | Checkpoint/resume is the skill's core design: per-phase manifests on disk, idempotent per-phase short-circuits, `run-metrics.json` cost ledger rolled up at exit, and an appended `wiki/log.md` run line on success (`:: §0.5`, `:: §3`, `:: Resume contract`). An abort or `--until` stop is explicitly "a clean exit 0 that re-invocation resumes from". |
| Scheduling | ✅ Healthy | The chain is finite (8 ordered phases, no unbounded iteration); cost gates (`--pause-before`, default gate at the first heavy-spend phase, re-pointed forward on resume so it is never silently lost) and a stop gate (`--until`) bound the run (`:: §0 step 2`, `:: §0.5 step 4`). |

**Sub-signals:** no-caps ✅ (linear phase chain; the loops it contains carry
their own caps — verify's 2 rounds, compose's single capped expansion, distill
fail-soft). no-checkpoint ✅ (the safe-by-default gating menu fires before the
first web spend; finalize is dispatched with prompts suppressed but **stages**
the portal/concepts diffs rather than applying them, and never passes
`--overwrite` — an existing synthesis is refused, not clobbered, `:: §2`
dispatch rules).

**Verdict: ✅ Clean pass — no findings.**

---

## Loop 3 — knowledge-refresh push-mode topic drain

**Source:** `cogni-knowledge/skills/knowledge-refresh/SKILL.md`.
**Unattended?** Partially — the user selects topics and confirms once
(`:: §1 step 4`, "the single batch-level gate"), then the per-topic chains run
autonomously; the opt-in `--resweep` adds its own confirmation gate.

| Move | Assessment | Evidence |
|------|------------|----------|
| Discovery | ✅ Healthy | Each run re-derives the work-list fresh: the vendored `lint_wiki.py` staleness pass runs in-tree per invocation, merged with the binding's evidence-based `refresh_candidates[]` (`:: §1 steps 1–2`) — no cached stale-page list is reused across runs. |
| Handoff | ✅ Healthy | Per-topic dispatch reuses the uniform phase contract (identical to Loop 2 — the SKILL.md states the two entrypoints deliberately share the dispatch block so they cannot drift); resweep bridges verdicts through explicit JSON shapes into `resweep_planner.py --phase aggregate` (`:: §2 step 4`). |
| Verification | ✅ Healthy | Delegated per topic to the `knowledge-verify` phase (Loop 1); the drain itself never grades content. The opt-in resweep adds live-source re-verification via `cogni-claims` — a second, orthogonal verification surface. |
| Persistence | ✅ Healthy | Fail-soft per topic with a `failures[]` record naming `{topic, failed_phase, error}`; on-disk manifests are declared the truth ("do not roll back"); the resume contract documents per-phase idempotent short-circuits (`:: §1 step 5`, `:: Push-mode resume contract`). |
| Scheduling | ✅ Healthy | Bounded by the user-selected topic set, sequential per topic, opt-in only — resweep "never auto-runs" so the zero-network per-run invariant holds (`:: §2` intro; `:: Out of scope`). |

**Sub-signals:** no-caps ✅ (topic set is finite and user-chosen; inner loops
carry their own caps). no-checkpoint ✅ (batch confirmation gate before spend;
finalize prompts suppressed but diffs staged, `--overwrite` never passed; the
summary honestly reports that stale pages are superseded, not rewritten).

**Verdict: ✅ Clean pass — no findings.**

---

## Loop 4 — verify-trend-report reviewer→revisor loop

**Source:** `cogni-trends/skills/verify-trend-report/SKILL.md`.
**Unattended?** No — interactive quality gate with a user-steered claims
review (Phase 3).

| Move | Assessment | Evidence |
|------|------------|----------|
| Discovery | ✅ Healthy | Phase 0 discovers eligible projects fresh via `discover-projects.sh`, and Phase 0.5 explicitly branches on pre-existing verification artifacts (re-verify / inspect / continue / accept) rather than silently re-running or reusing stale results. |
| Handoff | ✅ Healthy | Claims flow through the canonical `tips-trend-report-claims.json` registry into `cogni-claims:claims` and back as a structured QualityGateResult persisted to `.metadata/trend-report-verification.json`; reviewer and revisor exchange verdict JSON (`revision_priorities[]`) and versioned files, never prose (`:: Phases 2–4`). |
| Verification | ✅ Healthy | Runs "in a **fresh context window** — separate from the trend-synthesis pipeline" (`:: intro`); `trend-report-reviewer` (fresh-context agent) grades, `trend-report-revisor` (separate agent) repairs, and the reviewer re-scores each iteration. Post-revision output is additionally validated deterministically (heading preservation, claims-table integrity, no dead references) with an explicit "do not auto-rerun" on failure (`:: Step 4b`). |
| Persistence | ✅ Healthy | Every step leaves audit state: `.metadata/trend-report-verification.json`, `user-claims-review.json`, per-iteration `review-verdicts/v{N}.json`, versioned `tips-trend-report-v{N}.md` plus pre-revision backups (`:: Debugging`). |
| Scheduling | ✅ Healthy | Maximum 2 iterations (reduced to 1 when cogni-claims is absent, `:: Phase 4`); termination is verdict-accept OR cap, then the user picks the downstream path (`:: Step 4c`, `:: Phase 5`). |

**Sub-signals:** not applicable (interactive). Noted anyway: caps present,
human steers corrections before any automated revision.

**Verdict: ✅ Clean pass — no findings.** With Loop 1, the second exemplar:
fresh-context grade → separate-context revise → re-grade → hard cap.

---

## Loop 5 — compete stakeholder-review auto-rewrite loop

**Source:** `cogni-portfolio/skills/compete/SKILL.md` (§5a–5d).
**Unattended?** No — interactive skill; the loop runs between generation and
the user presentation.

| Move | Assessment | Evidence |
|------|------------|----------|
| Discovery | ✅ Healthy | Step 1 scans `propositions/` and `competitors/` fresh each run to find propositions without competitor files; internal context is re-read from `context/context-index.json` per run (`:: Steps 1–2`). |
| Handoff | ✅ Healthy | Generator (`competitor-researcher` agent) and reviewers exchange the competitor JSON file plus its parent proposition file; reviewers return scored assessments; the orchestrator maps failing dimensions to specific JSON fields via an explicit table before re-dispatch (`:: Step 5c.1`). |
| Verification | ✅ Healthy | The nodding check passes: two **fresh-context** reviewer subagents (`tsystems-cso-reviewer`, `market-industry-analyst-reviewer`) grade in parallel (`:: Step 5a`); the rewrite is executed by re-invoking `competitor-researcher` in revision mode — a separate agent, not the orchestrator editing inline — and the updated file is **re-reviewed by both reviewers** each iteration (`:: Step 5c.2–5c.3`). Offline eval graders (`cogni-portfolio-evals/scripts/grade_compete_review_loop.py`) exercise this loop's convergence behavior. |
| Persistence | ✅ Healthy | A `convergence.json` log records per-iteration scores, pass/fail, and rewrite actions alongside the competitor file (`:: Step 5c.5`); the convergence path is shown to the user (`:: Step 5d`). |
| Scheduling | ✅ Healthy | Max 3 iterations; on non-convergence the best-scoring version is presented **with** the unresolved issues and reviewer scores — degraded output is surfaced, never silently accepted (`:: Step 5c.4`). |

**Sub-signals:** not applicable (interactive; user review at Step 6 is the
final gate).

**Verdict: ✅ Clean pass — no findings.**

---

## Loop 6 — propositions ordered quality-gate chain

**Source:** `cogni-portfolio/skills/propositions/SKILL.md` (Quality Gates +
Research & Improve + Deep Dive).
**Unattended?** No — consulting-stance interactive skill with explicit user
checkpoints.

| Move | Assessment | Evidence |
|------|------------|----------|
| Discovery | ✅ Healthy | Reads all entity state fresh before acting (`:: Strategic Assessment`, "Read available data (silent, before any questions)"); batch tiers come from a recomputed `relevance_matrix` via `project-status.sh`. |
| Handoff | ✅ Healthy | Generation dispatches `proposition-generator` per Feature × Market pair with an explicit `plugin_root` contract; assessors return dimension-scored verdicts; repair paths route by verdict shape (Quick Fix → `quality-enricher`, Deep Dive → `proposition-deep-diver`) per a documented decision table (`:: Research & Improve`). |
| Verification | ✅ Healthy | Four ordered gates, fresh-context throughout: structural script validation, `feature-quality-assessor` + `feature-review-assessor` **before** generation (with a hard refuse-to-generate on `revise`/`reject` — an upstream-failure block, `:: Before Generation`), then `proposition-quality-assessor` + `proposition-review-assessor` after. The SKILL.md marks the order load-bearing ("Don't skip stages"). |
| Persistence | ✅ Healthy | Propositions, exclusion decisions (`excluded_markets` with reasons), and evidence registrations persist to entity JSON + `source-registry.json`; decisions survive across sessions (`:: Persisting Exclusion Decisions`). |
| Scheduling | ✅ Healthy | Human-gated at both ends: a pre-generation checkpoint the user must explicitly confirm, and a post-generation review checkpoint with "Do not auto-continue to next steps" (`:: Post-Generation Review Checkpoint`). Repair loops (Quick Fix / Deep Dive) are user-elected per round, so no runaway iteration exists to cap. |

**Sub-signals:** not applicable (interactive; every generation round is
bracketed by user checkpoints).

**Verdict: ✅ Clean pass — no findings.**

---

## Loop 7 — review-brief assessor verdict loop

**Source:** `cogni-visual/skills/review-brief/SKILL.md`.
**Unattended?** No — standalone interactive review; `auto_improve` defaults to
`false`.

| Move | Assessment | Evidence |
|------|------------|----------|
| Discovery | ✅ Healthy | Auto-discovers the brief and source narrative from the filesystem each run, confirming ambiguous candidates with the user (`:: Steps 0–2`). |
| Handoff | ✅ Healthy | The `brief-review-assessor` agent takes a typed contract (brief path, detected `brief_type`, narrative, round number) and returns structured JSON the skill parses into the verdict presentation (`:: Steps 3–4`). |
| Verification | ✅ Healthy | Grading is fresh-context (`brief-review-assessor`, three type-adapted perspectives); when `auto_improve` applies edits, the loop **re-launches the assessor for round 2** — improvements are re-graded, not self-asserted (`:: Step 5`, "Re-launch the assessor (round 2)"). Structural integrity is re-validated after edits. |
| Persistence | ✅ Healthy | Full verdict JSON written to `{brief_stem}.review.json` alongside the brief, including applied/skipped improvement counts and rounds completed (`:: Step 6`). |
| Scheduling | ✅ Healthy | Max 2 rounds; unresolved round-2 issues are presented to the user and recorded in the review artifact; `reject` is explicitly not auto-fixed — "fundamental issues that need human judgment" (`:: Step 5`). |

**Sub-signals:** not applicable (interactive; auto-improve is opt-in).

**Verdict: ✅ Clean pass — no findings.**

---

## Loop 8 — story-to-slides stakeholder-review loop (story-to-* family)

**Source:** `cogni-visual/skills/story-to-slides/SKILL.md` (Step 9b),
representative of the story-to-infographic / story-to-storyboard /
story-to-web siblings, which integrate the same `brief-review-assessor` loop
per the plugin's shared `stakeholder_review` convention.
**Unattended?** No — interactive checkpoints at narrative and theme selection;
`stakeholder_review` defaults to interactive.

The human-gated iterate here **does** count as a loop under the rubric: it is
a generate→evaluate→revise gate (brief generated in Steps 0–8.2, graded in
Step 9b, surgically revised, re-graded), not a mere confirmation prompt.

| Move | Assessment | Evidence |
|------|------------|----------|
| Discovery | ✅ Healthy | Step 0 searches the filesystem for narrative candidates fresh each run; Step 9 entry-gates verify the prior step's output before proceeding (`:: Execution protocol`). |
| Handoff | ✅ Healthy | The brief itself is the contract ("The YAML specification is the contract between this skill and the PPTX renderer", `:: Step 8`); enrichment is delegated to `slides-enrichment-artist` with a typed field table and an explicit fallback path on `ok: false` (`:: Step 8.2`). |
| Verification | ✅ Healthy | Two-layer: a five-layer deterministic validation (Step 9 — motivated by an honest note that "self-assessment is unreliable without explicit measurement") plus the fresh-context `brief-review-assessor` (Step 9b). Applied improvements trigger structural re-validation **and** an assessor round 2; `reject` is surfaced to the user, never auto-fixed. |
| Persistence | ✅ Healthy | Brief written to a durable output path; review verdict persisted to `presentation-brief.review.json` (`:: Step 9b`). |
| Scheduling | ✅ Healthy | Max 2 assessor rounds; round-2 residual issues are presented to the user before proceeding (`:: Step 9b`). |

**Sub-signals:** not applicable (interactive).

**Verdict: ✅ Clean pass — no findings.**

---

## Loop 9 — why-change assess-revise-reassess loop

**Source:** `cogni-sales/skills/why-change/SKILL.md` (Phase 5.5).
**Unattended?** No — every content phase (1–4) carries its own interactive
approve/revise quality gate before the loop even starts.

| Move | Assessment | Evidence |
|------|------------|----------|
| Discovery | ✅ Healthy | Phase 0 discovers portfolios via script; interrupted pitches resume from `pitch-status.sh` + `workflow_state.current_phase` read from disk (`:: Resuming an Interrupted Pitch`). |
| Handoff | ✅ Healthy | Phases exchange structured bridge files (`research.json` + `narrative.md` per phase); the assessor writes `output/pitch-review.json`; the revisor receives the archived assessment path explicitly and writes `output/revision-log.json` (`:: Step 5.5.2`). |
| Verification | ✅ Healthy | Three-role fresh-context assessor (`pitch-review-assessor`) grades; a **separate** `pitch-revisor` agent applies surgical fixes; the assessor is **re-run** after revision and the before/after score comparison is presented to the user (`:: Step 5.5.2` steps 3–5). `reject` routes to a human decision with a named phase to re-run, never an auto-fix (`:: Step 5.5.1`). |
| Persistence | ✅ Healthy | Assessments archived per pass (`pitch-review-v1.json`, `-v2.json`), revision log with fixes applied/preserved, phase state in `pitch-log.json` (`:: Data model` per plugin guide). |
| Scheduling | ✅ Healthy | Hard stop with documented rationale: "Maximum 2 revision passes. … Do not loop further — diminishing returns and oscillation risk increase with each pass" (`:: Step 5.5.2`). The escape hatch (manual `/copywrite` polish) is named. |

**Sub-signals:** not applicable (interactive; per-phase human gates
throughout).

**Verdict: ✅ Clean pass — no findings.** The explicit oscillation-risk stop
condition is a model for documenting *why* a cap exists, not just its value.

---

## Loop 10 — copy-reader persona review + auto-improvement

**Source:** `cogni-copywriting/skills/copy-reader/SKILL.md`.
**Unattended?** No for the human entry point — but `AUTO_IMPROVE` defaults to
`true`, and the skill exposes a JSON result contract "for agent/skill callers"
(`:: Step 6`), so its output feeds automated pipelines without a human reading
the report.

| Move | Assessment | Evidence |
|------|------------|----------|
| Discovery | ✅ Healthy | Parameters parsed and document validated fresh per run; persona set resolved from `references/personas/` on disk (`:: Step 1`). |
| Handoff | ✅ Healthy | One Task agent per persona with a fixed JSON output schema; synthesis merges them under documented priority/tiebreaker rules from `references/synthesis-protocol.md` (`:: Steps 3–4`). |
| Verification | ⚠ **Major — nodding** | The *initial* grade is healthy (fresh-context persona agents). The gap is the **improvement leg**: Step 5 applies "ONE improvement pass" in the orchestrator's own context, and the flow then proceeds straight to the Step 6 report — **no persona agent ever re-reads the edited document**. Post-edit validation is deterministic guardrails only (charset, citation count, protected content). Yet the Step 6 report template asserts re-measured quality effects — "raised Executive score to 88", "raised End-user score to 95" — scores nothing re-measured. The context that wrote the edits also grades their effect. See [F1](#f1). |
| Persistence | ✅ Healthy | Backup created before analysis (`.{filename}.pre-reader-review`); validation failure reverts to backup with a reason (`:: Steps 2, 5`). |
| Scheduling | ✅ Healthy | The improvement pass is explicitly single ("Apply ONE improvement pass") — bounded by construction. |

**Sub-signals:** not applicable as unattended-only signals (interactive
default), though the agent-caller JSON contract means the self-asserted
post-improvement result can flow downstream unread — which is what elevates
the Verification gap above a stylistic nit.

**Verdict: ⚠ 1 finding — nodding (Verification), `major` (see [F1](#f1)).**

---

## Loop 11 — consult-design-thinking DT stage machine

**Source:** `cogni-consult/skills/consult-design-thinking/SKILL.md`,
`cogni-consult/scripts/dt-stage-advance.sh`.
**Unattended?** No — consultant-driven; auto-walk mode still surfaces every
stage's entries and the Test-stage accept is the consultant's call.

| Move | Assessment | Evidence |
|------|------------|----------|
| Discovery | ✅ Healthy | Prerequisite Gate re-reads engagement state per entry (`discover-projects.sh`, `consult-project.json`, `field.json`, the derived `personas_gate` rollup via `engagement-status.sh`) and refuses to invent manifest entries (`:: Step 1`). |
| Handoff | ✅ Healthy | Stage transitions go through the guarded `dt-stage-advance.sh` helper — validates the target stage, rejects forward jumps that skip a stage, permits idempotent re-sets and earlier-stage re-entry (the loop's iteration mechanism), atomic read-modify-write of `field.json`, and refuses to proceed past a `success: false` (`:: Advancing the stage`; `scripts/dt-stage-advance.sh :: steps 1–5`). |
| Verification | ⚠ Advisory minor | The Test stage challenges the draft **in the same context that drafted it** — the orchestrator role-plays the personas' objections inline; no fresh-context evaluator is dispatched between Prototype and the completion write (`:: Step 7`). The consultant's explicit accept is the real gate (a human checkpoint, which is why this is not full nodding), and a fresh-context grader for exactly this artifact **exists** in the plugin (`cogni-consult/agents/consult-framework-adherence-reviewer.md`, a read-only scorer) — it is offered post-hoc by `consult-resume`, not wired into this loop. See [F2](#f2). |
| Persistence | ✅ Healthy | Exemplary: `dt_stage` + `state` live solely in `field.json` (single source of truth), per-stage moves append to `.metadata/stage-log.json`, state transitions to the execution log, decisions/gap-checks/waivers to the decision log with discriminated `kind` keys, staleness cascades via `deliverable-graph.py cascade-stale` (`:: Steps 2, 7`; `:: Important Notes`). |
| Scheduling | ✅ Healthy | Human-invoked; the stage machine's guard rejects illegal jumps; re-entry to earlier stages is a deliberate, logged iteration path ("Loop, not gate", `:: Important Notes`). |

**Sub-signals:** not applicable (interactive; the personas gate, interactive
mode's confirmation seams, and the elected — never auto-fired — deposit and
publish steps are all human checkpoints).

**Verdict: ⚠ 1 advisory-minor finding — nodding-adjacent (Verification), see
[F2](#f2).**

---

## Findings

### F1 — copy-reader · nodding (Verification) · major {#f1}

**Anti-pattern:** nodding (Verification skipped on the revise leg — the flow
that produces the edited deliverable also grades it).
**Evidence location:** `cogni-copywriting/skills/copy-reader/SKILL.md ::
Step 5 ("Apply Auto-Improvement Loop")` — edits are applied in the
orchestrator's context and validated only deterministically (charset, citation
count, protected content), with no re-dispatch of any persona agent; and
`:: Step 6 ("Report Results")` — the user-facing report template asserts
post-improvement score effects ("raised Executive score to 88", "raised
End-user score to 95") that no evaluator re-measured, and the JSON contract
for "agent/skill callers" carries `overall_score` + `improvements_applied`
downstream on the same unverified basis.
**Why major, not minor:** this is the rubric's priority case and it is
statically confirmable — there is no dispatch between the edit-write and the
accept/report, and the report's score-delta claims are structurally
unmeasurable in the flow as written. `AUTO_IMPROVE` defaults to `true`, so the
self-graded improvement pass is the default path, including when other skills
invoke copy-reader programmatically. Mitigations that keep it from being worse
(fresh-context *initial* grading, deterministic guardrails with
revert-to-backup, an interactive human reading the report in the common case)
are real but do not close the gap the rubric targets: bad edits are laundered
past the only quality gate with asserted-not-measured scores. The healthy
contrast is in this same repo: `cogni-visual/skills/review-brief/SKILL.md ::
Step 5` re-launches its assessor after applying improvements. A follow-up
could look at re-grading applied edits (or reporting only pre-improvement
scores) — evidence-gated, out of this sweep's scope.

### F2 — consult-design-thinking · nodding-adjacent (Verification) · advisory minor {#f2}

**Anti-pattern:** adjacent to nodding (Verification) — not full nodding,
because a human checkpoint sits between produce and accept.
**Evidence location:** `cogni-consult/skills/consult-design-thinking/SKILL.md
:: Step 7 ("Test")` — the Test-stage persona challenge is role-played in the
same context that drafted the artifact in Step 6 (no `Agent`/`Task` dispatch
between Prototype and the `state → "complete"` write); the fresh-context
scorer that exists for exactly this artifact
(`cogni-consult/agents/consult-framework-adherence-reviewer.md`) is offered
only post-hoc via `cogni-consult/skills/consult-resume/SKILL.md` rather than
inside the loop.
**Why advisory, not major:** the accept decision belongs to the consultant —
an explicit human gate ("If the draft survives (consultant accepts)"), and the
challenge outcomes are dispositioned on the record (per-persona `work_log`
entries + a `## Persona Challenges` artifact section). Whether an interactive
consulting loop *should* interpose a fresh-context reviewer before the human
gate is a judgment call, not a statically-decidable absence — the precision
gate routes it to advisory `minor`. A follow-up could look at whether the
existing framework-adherence reviewer belongs at the Test stage — evidence-
gated future work only.

---

## Out of scope

This sweep is read-only and produces **only** this map. Targeted fixes to any
flagged loop, and pre-filed speculative per-loop fix issues, are explicitly
out of scope. The two findings above are an informational baseline —
evidence-gated future work only; act on a finding only where a future re-read
confirms real risk.

Because loop code changes over time, re-running the sweep (re-applying the
cogni-service loop-anatomy rubric and refreshing this map) is the natural way
to keep the baseline honest.
