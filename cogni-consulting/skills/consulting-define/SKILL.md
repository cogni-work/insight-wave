---
name: consulting-define
description: |
  Execute the Define phase of a Double Diamond engagement — converge from discovery insights to a
  clear problem statement. Verifies assumptions via cogni-claims, guides affinity clustering and
  HMW framing. Use whenever the user wants to synthesize findings, frame the problem, or narrow
  focus within a diamond engagement. Trigger on: "define the problem", "what's the real issue",
  "frame the challenge", "synthesize the findings", "narrow down", "converge", "problem statement",
  "how might we", "verify assumptions", "check our assumptions", "what did we learn",
  "so what does this all mean", "cluster the themes", "prioritize the insights",
  "define phase", "D1 converge", "assumption check", or any request to move from broad research
  to focused problem framing. Also trigger when the user says something like "I think the real
  problem is..." — they're already doing Define work and this skill should scaffold it.
---

# Diamond Define — Converge on the Challenge

Synthesize discovery findings into a clear, actionable problem statement. This is the convergence half of Diamond 1 — the goal is to narrow from a broad evidence base to the core challenge worth solving.

## Core Concept

Define is about making choices. Discovery surfaced many themes, tensions, and opportunities. Define forces the consultant and client to decide: "Of everything we learned, what is the one challenge that, if solved, would create the most value?" This requires both analytical rigor (verifying assumptions) and creative synthesis (reframing the problem).

The outputs — a problem statement and HMW questions — become the brief for Diamond 2. Getting the problem framing wrong means solving the wrong problem, no matter how elegant the solution.

## Prerequisites

- Discovery phase should be complete or substantially progressed (the phase-gate-guard hook will warn if not)
- Discovery synthesis (`discover/synthesis.md`) should exist — the starting input for Define

## Workflow

### 1. Load Context

Read consulting-project.json and `discover/synthesis.md`. Review the themes, surprises, and tensions from Discovery.

Update phase state:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" define in-progress
```

### 2. Propose Define Methods

Present the convergence plan:

**Assumption Verification** (plugin-powered):
- Extract key assumptions from the discovery synthesis
- Submit to cogni-claims for verification against cited sources
- Flag unsupported or contradicted assumptions

**Guided Convergence Methods** (interactive):

| Method | Purpose | Reference |
|---|---|---|
| Affinity Clustering | Group discovery themes into clusters | `references/methods/affinity-clustering.md` |
| HMW Synthesis | Reframe clusters as "How Might We" questions | `references/methods/hmw-synthesis.md` |
| Assumption Mapping | Map and prioritize assumptions by risk | `references/methods/assumption-mapping.md` |

Ask: "I recommend starting with assumption verification, then affinity clustering, then HMW synthesis. Want to adjust the approach?"

### 3. Assumption Verification

Extract 10-20 key assumptions from the discovery synthesis. These are factual claims that underpin the emerging problem framing.

Present them to the consultant:

> **Assumptions extracted from Discovery:**
> 1. "Mid-market cloud spend in DACH will grow 18% YoY through 2028" — from desk research
> 2. "No incumbent offers unified monitoring across hybrid environments" — from competitive analysis
> 3. ...
>
> Any to add, remove, or reframe?

After confirmation, dispatch to cogni-claims:
- Submit assumptions as claims with source references from discovery
- Dispatch the `claims` skill in verify mode to check against cited sources
- Present results: verified, deviated, source unavailable

Save verified/deviated results to `define/assumptions.json`.

Key decision point: deviated assumptions need resolution. Common patterns:
- **Correct the claim** with the verified data — straightforward when the source is clear
- **Mark as open question** needing primary research — appropriate when no good source exists
- **Accept with caveat** — the assumption stays but is flagged as unverified in the problem statement

Expect 20-30% of assumptions to deviate — this is normal and valuable, not a failure. The deviations themselves refine understanding.

### 4. Affinity Clustering (Guided)

Read `$CLAUDE_PLUGIN_ROOT/references/methods/affinity-clustering.md` and guide the consultant:

1. List all discovery themes (from synthesis.md) as individual items
2. Propose initial groupings based on thematic similarity
3. Ask the consultant to review, merge, split, or relabel clusters
4. Name each cluster with a descriptive label
5. Rank clusters by relevance to the engagement vision

Output: 3-7 named theme clusters, ordered by priority. Save to `define/theme-clusters.md`.

### 5. HMW Synthesis (Guided)

Read `$CLAUDE_PLUGIN_ROOT/references/methods/hmw-synthesis.md` and guide the consultant:

1. For each top-priority cluster, draft 2-3 "How Might We" questions
2. Present HMW questions for refinement — too broad is useless, too narrow is premature
3. Converge on 3-5 HMW questions that frame the problem space for Diamond 2

Save to `define/hmw-questions.md`.

### 6. Problem Statement

Synthesize the verified assumptions, clusters, and HMW questions into a problem statement:

**Structure**:
- **Context**: What is the situation? (from Discovery)
- **Tension**: What is the core conflict or gap?
- **Question**: What needs to be resolved? (from HMW)
- **Constraints**: What boundaries apply? (from engagement vision)

**Example** (strategic-options for DACH market growth):
> **Context**: The client's DACH cloud portfolio has plateaued at €45M ARR despite 18% market growth, with mid-market share eroding to two vertical-specialist competitors.
> **Tension**: Current horizontal positioning serves enterprise accounts well but fails to resonate with mid-market buyers who prioritize speed-to-value over feature breadth.
> **Question**: How might we reposition the portfolio to capture mid-market growth without cannibalizing enterprise margins?
> **Constraints**: No M&A, 6-week timeline, existing technology stack.

Draft the problem statement and present for consultant review. The problem statement is the most consultant-dependent artifact in the entire engagement — draft it, but expect 2-3 rounds of refinement. That iteration is where the real value lives.

Save to `define/problem-statement.md`.

### 7. Stakeholder Review

Before transitioning to Develop, stress-test the Define outputs against four stakeholder perspectives. Getting the problem framing wrong means solving the wrong problem in Diamond 2 — this review catches misalignment before it compounds.

#### 7a. Launch Parallel Persona Review

Launch one Task agent per persona. Each reads the Define artifacts and evaluates from their perspective.

| Persona | Focus | Reference |
|---|---|---|
| Engagement Sponsor | Right problem for the business? | `references/personas/engagement-sponsor.md` |
| Delivery Lead | Rigorous convergence process? | `references/personas/delivery-lead.md` |
| Solution Architect | Can Develop work with this? | `references/personas/solution-architect.md` |
| End-User Advocate | Real user pain preserved? | `references/personas/end-user-advocate.md` |

**For each persona, launch a Task with this prompt:**

```
You are a {PERSONA_NAME} reviewing the Define phase outputs of a Double Diamond engagement.

FILES TO READ (use Read tool):
1. Problem statement: {project-dir}/define/problem-statement.md
2. HMW questions: {project-dir}/define/hmw-questions.md
3. Verified assumptions: {project-dir}/define/assumptions.json
4. Theme clusters: {project-dir}/define/theme-clusters.md
5. Discovery synthesis: {project-dir}/discover/synthesis.md (for traceability)
6. Diamond project: {project-dir}/consulting-project.json (for engagement context)
7. Your persona profile: {absolute path to references/personas/{persona}.md}

INSTRUCTIONS:
1. Read all files
2. Adopt the tone described in your persona profile
3. Evaluate each of your 5 criteria, assigning PASS / WARN / FAIL
4. For each criterion, provide specific evidence from the Define artifacts
5. Calculate your weighted score: PASS=1.0, WARN=0.5, FAIL=0.0
6. Generate 3-5 questions your stakeholder would ask
7. Identify the single most important issue from your perspective
8. List 2-3 concerns that could block Develop phase success

OUTPUT FORMAT (Markdown):

## {PERSONA_NAME} Evaluation

### Criteria Assessment

| Criterion | Weight | Verdict | Evidence |
|---|---|---|---|
| {criterion 1} | {weight}% | {PASS/WARN/FAIL} | {specific evidence from Define artifacts} |
| ... | ... | ... | ... |

**Score**: {weighted score}/1.0 — {count PASS} pass, {count WARN} warn, {count FAIL} fail

### Top Questions
1. {Question a real stakeholder would ask}
2. ...

### Critical Issue
{The single most important concern, with specific suggestion}

### Develop Blockers
- {Concern that could block Diamond 2 success} — {one-line rationale}
- ...
```

**Agent configuration**: Use a fast model (haiku or sonnet), Read tool only. Launch all 4 persona agents in the same turn for parallel execution.

#### 7b. Synthesize and Decide

Read `references/review-protocol.md` and apply it to the persona results:

1. Calculate per-persona weighted scores
2. Identify cross-cutting themes using semantic matching
3. Apply priority escalation rules
4. Route themes to Define artifacts
5. Resolve conflicts using the tiebreaker hierarchy

**Decision logic**:
- **CRITICAL themes**: Revise affected artifact(s), then re-run only the persona(s) that flagged CRITICAL (max 2 rounds)
- **HIGH themes**: Present to consultant — they decide whether to revise or accept with noted limitations
- **OPTIONAL only**: Log findings as observations, proceed to step 8

Save the full review results to `define/review-summary.md`.

#### 7c. Iterate (if needed)

If CRITICAL issues triggered revision:

1. Apply specific revisions to the affected artifacts (problem-statement.md, hmw-questions.md, etc.)
2. Re-run only the persona(s) that flagged CRITICAL — don't repeat the full review
3. After round 2, present any remaining issues to the consultant regardless of severity — they get final say
4. Log iteration history in the review summary (what was flagged, what was revised, what was the re-evaluation result)

This keeps the "warn, not block" principle intact — the review enforces a quality bar but the consultant always has the last word.

### 8. Log and Transition

Update method log and decision log with key choices made during Define.

Present the Define summary:

> **Define phase complete.**
> - Assumptions: N verified, N deviated, N unresolved
> - Theme clusters: [list top 3]
> - HMW questions: [list top 3]
> - Problem statement: [one-sentence version]
> - Review: [PASSED / PASSED with observations / PASSED after N revision rounds]
>
> Ready to move to Diamond 2? The Develop phase will generate solution options for these HMW questions.

Mark Define complete:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" define complete
```

## When Things Go Thin

- **Many deviations** (>50% of assumptions): This signals the discovery evidence base was weaker than expected. Rather than patching assumptions one by one, consider whether a targeted research sprint (back to Discover) would be more efficient than proceeding with low-confidence framing.
- **Consultant disengages from clustering or HMW**: These methods require active judgment. If input is minimal, capture the consultant's top 2-3 priorities directly and build from there rather than forcing the full method sequence.
- **Discovery was thin in some areas**: Note this as a known limitation in the problem statement's constraints section rather than blocking progress. A well-framed problem with acknowledged gaps is more useful than a perfectly evidenced problem that never gets framed.

## Important Notes

- Define is the most collaborative phase — expect heavy back-and-forth with the consultant
- Deviated assumptions are valuable signals, not failures — they refine understanding
- Record key decisions in the decision log (why one framing was chosen over another) — these decisions are hard to reconstruct later and valuable for the Deliver phase
- If discovery was thin in some areas, note this as a known limitation rather than blocking progress
- The review summary (`define/review-summary.md`) is a key artifact for the Deliver phase — it documents which stakeholder concerns were addressed and which were flagged for downstream resolution
