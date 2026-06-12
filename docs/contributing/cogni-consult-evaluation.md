# cogni-consult Evaluation — Dogfood Comparison vs cogni-consulting

cogni-consult (action-fields-as-WBS, design thinking per deliverable, acting
personas, one compounding knowledge base) is the evaluation candidate
alongside cogni-consulting (Double Diamond). This document is the evaluation
protocol and scorecard: one real engagement brief, run end-to-end through
both plugins, scored side-by-side against the six criteria defined in
[`cogni-consult/references/evaluation-criteria.md`](../../cogni-consult/references/evaluation-criteria.md).

**Status: scorecard filled from an agent-driven run (2026-06-12), pending
maintainer verification.** The protocol stipulates a human-driven run; this
run was executed autonomously by an agent commissioned by the maintainer — a
recorded protocol deviation, disclosed in the Run record below and inside
every score that depends on consultant-effort judgments. The brief was real
(a genuine client workshop engagement), the artifacts are real, and the
resume probes were performed cold in a separate session one day-boundary
later; what is proxied is the consultant's judgment and effort experience.
The maintainer verifies these scores before they count.

**What this evaluation does not decide.** The completed scorecard is
evidence for a replace/archive decision about cogni-consulting — it is not
that decision. The decision itself is a separate human go/no-go gate, the
same maintainer-sign-off pattern the ecosystem uses for its other archival
gates. Until that gate is explicitly passed by a maintainer, cogni-consulting
remains active and untouched: this evaluation does not modify, deprecate, or
archive it, and nothing downstream may treat a filled scorecard as an
archival trigger.

## The two candidates

| | cogni-consult | cogni-consulting |
|---|---|---|
| Work structure | 3-6 action fields as the WBS; every deliverable lives in exactly one field | Five gated phases (scope → discover → define → develop → deliver) |
| Process rhythm | Design-thinking loop (empathize→define→ideate→prototype→test) per deliverable | One Double Diamond pass for the whole engagement |
| Personas | Acting personas challenge deliverables in their own voice before completion | Design-for personas + quality-gate personas evaluate at phase gates |
| Research | One cogni-knowledge base bound at setup; every run routes through it and compounds | One base bound per engagement; cogni-knowledge dispatched in the Discover phase, claims verified in Define/Deliver |
| Progress state | Per deliverable (in the field's `field.json` manifest) | Per phase (state machine in `consulting-project.json`) |
| Re-entry | `consult-resume`: WBS dashboard + single next action | `consulting-resume`: phase status + next step |

Both plugins are pre-1.0 (see each plugin's maturity callout).

## Protocol

1. **Pick one real brief.** A genuine consulting question the maintainer
   actually needs answered — not a toy. The brief must be rich enough to
   produce at least two deliverables in at least two action fields, so the
   research-compounding and persona-review criteria are exercised.
2. **Run cogni-consult end-to-end.** `consult-setup` → `consult-scope` →
   `consult-action-fields` → `consult-design-thinking` (per deliverable) →
   `consult-personas` review → leave the engagement for at least a day →
   `consult-resume`. Capture session notes as you go: interruptions, manual
   state repairs, dead ends, and anything that surprised you.
3. **Run cogni-consulting on the same brief.** The full Double Diamond
   (setup → scope → discover → define → develop → deliver), with its own
   resume check after the same break. Same note-taking discipline. Separate
   engagement directories — the runs share nothing.
4. **Score side-by-side.** Score each plugin on every criterion per the
   Scoring section of `evaluation-criteria.md`, citing concrete artifacts —
   file paths, not impressions.
5. **Keep artifacts local, summarize here.** Live engagement directories
   are not committed (repo convention: live runs stay out of the tree).
   The filled scorecard plus the cited excerpts in this file are the
   committed evidence of record.

## Scorecard

| # | Criterion | cogni-consult | cogni-consulting | Notes |
|---|---|---|---|---|
| 1 | Deliverable quality | pass | partial | consulting artifacts substantive but carry no evidence lineage or challenge-hardening; the side-by-side read was agent-performed, not blind |
| 2 | Scope sharpness | pass | partial | consulting's 0-scope phase has 0 files; scope lived in setup and sharpened only at define |
| 3 | Persona-challenge usefulness | pass | not exercised | consulting's quality-gate persona review legitimately skipped on its lightweight-HMW path |
| 4 | Research depth and compounding | pass | fail | consulting run has `plugin_refs.knowledge_base: null`; no compounding surface exists |
| 5 | Consultant effort and flow | pass | partial | both judged via agent proxy (disclosed); consult's friction sat in the delegated knowledge sub-pipeline, not its own state |
| 6 | Re-entry and resume clarity | pass | partial | consulting's Session B resume recommended correctly, but its discovery listing misreported the engagement and methods/decisions never surface |

### Per-criterion findings

Brief: the iSAGA Audit AI Ideation Workshop — a real 4-hour AI use-case
ideation workshop for Deutsche Telekom Group Audit (~25 participants,
08.07.2026), three contracted deliverables. Engagement directories stay
local per protocol step 5: `cogni-consult/isaga-audit-ai-workshop-dogfood/`
(+ bound base `cogni-knowledge/isaga-audit-ai-workshop-dogfood/`, 45 wiki
entries) and `cogni-consulting/isaga-audit-ai-workshop/`, with run records
in `dogfood-675/{decision-log.md, session-notes-consult.md,
session-notes-consulting.md}`.

#### 1. Deliverable quality — consult: pass · consulting: partial

Both completed cogni-consult deliverables
(`action-fields/workshop-design/facilitation-flow.md`,
`action-fields/engagement-prep/prep-action-plan.md`) carry YAML frontmatter
with `sources[]` lineage — every entry a `kb_ref` (`wiki://<slug>`) that was
spot-verified in Session B to resolve to a page in the bound base (11/11
distinct refs resolve) — plus a `## Persona Challenges` section in which
every challenge is dispositioned. The artifacts are outcome-led
(facilitation-flow opens with what the sponsor holds at 15:00), cite
evidence inline (`[kb: ...]` markers), and carry risk/contingency sections.
The cogni-consulting pair (`develop/workshop-design-v0.5.md`,
`deliver/delivery-package.md`) is genuinely strong content — the v0.5
canvas-led design is rich, human-made work — but carries no `kb_ref`
lineage, no challenge sections, and its third deliverable is honestly a
template (`deliver/followup-report-template.md`; the workshop hasn't run).
Caveat: the pass signal asks for a *blind* side-by-side read; this read was
agent-performed and is disclosed as such, so the quality comparison is
indicative, not blind-validated.

#### 2. Scope sharpness — consult: pass · consulting: partial

`scope/key-question.md` satisfies all four Quality Signals from
`cogni-consult/references/methods/scope-dimensions.md`: a one-sentence
sponsor-recognizable key question; concrete falsifiable statements in every
dimension (named people, ~25 participants, 08.07.2026, ~3-day budget); a
non-empty out-of-scope list (implementation detail, vendor selection,
training); and three action fields that hosted exactly the brief's three
deliverables 1:1. Downstream confirmation: every deliverable landed in
exactly one field and the execution log records zero mid-engagement
re-scoping. The SMART check records two rejected candidate framings, so
convergence is visible, not asserted. On the consulting side the 0-scope
phase directory holds 0 files — scope facts lived in the setup vision block
and were sharpened only at define (`define/problem-statement.md`, which is a
good problem statement); the scope surface itself was never exercised as a
phase.

#### 3. Persona-challenge usefulness — consult: pass · consulting: not exercised

Seven acting-persona challenges across the two completed deliverables
(four on facilitation-flow, three on prep-action-plan), every one
dispositioned in the artifacts' `## Persona Challenges` sections and
mirrored in `personas/*.json` `work_log` entries. The mix is exactly what
the pass signal requires — neither noise nor rubber stamp: challenges
produced 8 concrete artifact revisions (e.g. the AI-stream lead's challenge
narrowed in-diverge feasibility flagging to obvious-reds and moved full
traffic-lighting to candidates with reason tags; the group auditor's
challenge added psychological-safety framing and room-only homework
visibility), and 2 challenges were rejected with recorded reasons (per-card
H2/H3 owners; full 25-person RACI). cogni-consulting's quality-gate persona
review was legitimately skipped by the skill's own lightweight-HMW rules on
this brief, so the baseline is **not exercised** — not failed.

#### 4. Research depth and compounding — consult: pass · consulting: fail

The compounding probe fired and was reproduced cold in Session B:
deliverable 2's empathize-stage gap-check via `wiki-grounding.py rank`
returns verdict `covered` with the top hit being deliverable 1's deposited
synthesis (`wiki/syntheses/ai-ideation-workshop-design-internal-audit.md`;
Session A score 0.36, Session B reproduction 0.31 with reconstructed query
phrasing — the exact query string was not recorded verbatim, a probe-logging
gap noted for next time). The quick rung sufficed where a fresh engagement
would have needed a crawl: deliverable 1 triggered the full inverted
pipeline (40 sources, ~377 claims, 68-citation verified synthesis),
deliverable 2 triggered **no new web crawl**. Every research-backed claim in
both deliverables carries a `kb_ref` resolving into the engagement's base
(verified 11/11). The consulting engagement has
`plugin_refs.knowledge_base: null` — its discover research is a set of
static files with no compounding surface, so the criterion's pass signal
cannot be met on that side: **fail** (observable absence, not an
unexercised path — the plugin's claimed Discover-phase binding simply never
happened on this run).

#### 5. Consultant effort and flow — consult: pass · consulting: partial

**Agent-driven disclosure applies most strongly here**: effort and flow were
experienced by an agent, not a consultant, so these scores proxy the
protocol's intent. On the consult side, both deliverables travelled
empathize→test with zero manual edits to `field.json` /
`consult-project.json` and zero state repairs (session-notes-consult.md
§Effort/flow); all recorded friction sat in the delegated cogni-knowledge
sub-pipeline (manifest merge burden, `sub_question_refs` schema mismatch,
a `CLAUDE_PLUGIN_ROOT` env gap in nested setup — decision-log FRICTION
entries), which is real operator load but not cogni-consult's state
machine. On the consulting side, `update-phase.sh` transitions were clean
and atomic (5/5), but the state machine had silently tolerated two phases
simultaneously in-progress with define skipped, and the Session A dashboard
reported that inconsistency without remediation or any next action — the
consultant carries the repair burden
(session-notes-consulting.md §Effort/flow).

#### 6. Re-entry and resume clarity — consult: pass · consulting: partial

Cold-resume probes ran first thing in Session B, before any state file was
opened by hand (order enforced by the runbook so the probe measures the
dashboards, not agent memory). `consult-resume` reconstructed the WBS
correctly from two script calls — workshop-design complete, engagement-prep
complete, results-followup pending with followup-report (empathize) — with
zero warnings and exactly one next-action recommendation
(consult-design-thinking on followup-report) matching what a consultant
would choose; zero archaeology. `consulting-resume`'s status call also
oriented correctly this time (scope 0 files; discover/define/develop
complete; deliver in_progress; non-empty `next_actions` recommending
consulting-deliver — an improvement over the Session A probe's empty
`next_actions: []` against the then-inconsistent state). It stays partial
for two reproduced defects: the discovery script reported the same
engagement as `current_phase: ""` with all five phases `pending`
(misleading at engagement-selection time), and `methods_used`/`decisions`
returned empty despite decision entries existing in
`consulting-project.json` — the engagement's memory stays invisible at
re-entry (both recorded in session-notes-consulting.md §Session B resume
probe).

### Run record

- **Date(s):** Session A 2026-06-12 (full runs of both plugins), Session B
  2026-06-12+1 day-boundary (cold resume probes, scoring, this scorecard).
- **Agent-driven disclosure:** both runs and this scorecard were executed
  autonomously by an agent commissioned by the maintainer — a recorded
  deviation from this protocol's human-driven stipulation. Decisions the
  agent took in a consultant's place are logged per-entry in
  `dogfood-675/decision-log.md`. Criterion 5 (and the criterion-1
  side-by-side read) depend on consultant-effort judgments and inherit this
  caveat directly.
- **Protocol deviations (from decision-log.md):** skipped fail-soft
  observability agents (ingest contradictor, wiki contradictor/reviewer,
  portal/concepts refresh) in the knowledge pipeline; consulting-develop /
  consulting-deliver SKILL.md prompts were not re-loaded when closing those
  phases (work product pre-existed; phases closed via documented
  `update-phase.sh` transitions); single brief, single run — the protocol's
  own "mixed or thin evidence" branch anticipates a second brief before any
  decision.
- **Local artifacts:** engagement dirs
  `cogni-consult/isaga-audit-ai-workshop-dogfood/`,
  `cogni-consulting/isaga-audit-ai-workshop/`, bound base
  `cogni-knowledge/isaga-audit-ai-workshop-dogfood/`, run records
  `dogfood-675/` — all local per protocol step 5, available to the
  maintainer for verification.
- **Gate restatement:** this filled scorecard is evidence, not a decision.
  The replace/archive decision for cogni-consulting remains a separate
  **human go/no-go gate**; cogni-consulting was not modified, deprecated,
  or archived by this run, and nothing may treat this scorecard as an
  archival trigger.

## After the run

A filled scorecard feeds the maintainer's replace/archive go/no-go gate on
cogni-consulting. Three outcomes are possible, and all three are maintainer
calls, not automated ones:

- **Evidence favors cogni-consult** — the maintainer may open the archival
  gate for cogni-consulting.
- **Evidence favors cogni-consulting** — cogni-consult is frozen or
  re-scoped; the comparison stands as the record of why.
- **Evidence is mixed or thin** — both plugins stay active and the protocol
  is re-run on a second brief before any decision.
