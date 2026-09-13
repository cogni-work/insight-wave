---
title: Stakeholder Review Procedure
version: 1.0
---

# Stakeholder Review

Step 4 of the copywriter workflow: read the document as its stakeholders, in parallel and in fresh contexts, then synthesize what they raise into a ranked improvement list. The persona profiles (`persona-*.md`) say *how each reader judges*; `synthesis-protocol.md` says *how their verdicts merge*; this file says *how the step runs*.

## 1. Resolve the persona set

Use the explicit `PERSONAS` list when one is given. Any `references/persona-<name>.md` is a valid persona; the name is the `<name>` part (`executive`, `technical`, `legal`, `marketing`, `end-user`, `cdo-utility`, `cmo-provider`). Otherwise take the audience defaults from SKILL.md Step 4. Load each resolved profile before dispatching.

## 2. Dispatch one agent per persona, in parallel

Launch one `Agent` per persona in a single message so they run concurrently. Fast model; tools `Read` only; wait for all to return before synthesizing.

**Prompt template (one per persona):**

```text
You are a {PERSONA_NAME} stakeholder reading a document. Your job is to evaluate it from your specific perspective and produce structured feedback.

DOCUMENT PATH: {FILE_PATH}

Read the document, then evaluate using the criteria from your persona profile.

PERSONA PROFILE:
{content of references/persona-{persona}.md}

INSTRUCTIONS:
1. Read the entire document carefully
2. Evaluate against each criterion in your profile; score each PASS (100) / CONCERN (60) / FAIL (0) and weight by the criterion's percentage
3. Generate 3-5 questions a real {PERSONA_NAME} stakeholder would ask after reading
4. Identify specific concerns with line references where possible
5. Provide concrete improvement recommendations

OUTPUT FORMAT (JSON only):
{
  "perspective": "{persona}",
  "score": <0-100>,
  "questions": ["Question 1?", "Question 2?", ...],
  "concerns": ["Concern with specific reference", ...],
  "recommendations": [
    {"priority": "CRITICAL|HIGH|OPTIONAL", "action": "Specific improvement to make", "location": "Section or paragraph reference"}
  ],
  "strengths": ["What works well", ...]
}
```

**Graceful degradation.** One persona fails or returns malformed JSON → log a warning and continue with the rest. Every persona fails → skip synthesis, continue to Step 5 with the document as written and `fallback_reason: "review_failure"`. Review never blocks delivery.

## 3. Synthesize

Read `synthesis-protocol.md`, then:

1. Collect every persona result into one array.
2. Identify cross-persona themes by semantic matching and assign each theme's priority with the protocol's Priority Escalation table (ordered, first match wins).
3. Resolve conflicts structurally first, then by the protocol's tiebreaker hierarchy.
4. Deduplicate recommendations: merge same-theme actions, keep the highest contributing priority, track source personas.
5. Rank by priority, then by the number of personas who raised the issue.

**Synthesis shape:**

```json
{
  "persona_scores": {"executive": 78, "technical": 85},
  "overall_score": 82,
  "cross_cutting_themes": [
    {"theme": "Missing quantification", "personas": ["executive", "marketing"], "priority": "CRITICAL"}
  ],
  "merged_recommendations": [
    {"priority": "CRITICAL", "action": "...", "sources": ["executive", "marketing"]},
    {"priority": "HIGH", "action": "...", "sources": ["technical"]}
  ],
  "all_questions": [
    {"persona": "executive", "question": "What's the expected ROI timeline?"}
  ]
}
```

**Score bands** (interpretation of `overall_score` and each persona score):

| Score | Assessment |
|-------|-----------|
| 85-100 | Excellent — meets stakeholder expectations |
| 70-84 | Good — minor improvements recommended |
| 50-69 | Concerns — significant improvements needed |
| 0-49 | Failing — major issues detected |

## 4. Apply improvements (when `REVIEW_APPLY` is true)

One pass, in this order:

1. **Apply every CRITICAL recommendation** — locate the section, make the edit, keep protected content intact. Skip and log any edit that would drop a citation, fold a German character, or touch protected content.
2. **Apply HIGH recommendations where feasible** — only when no external data is needed and the edit does not conflict with a CRITICAL edit applied above. Skip with a reason otherwise.
3. **Log OPTIONAL recommendations** without applying them.

Step 5 then runs its normal backup, validation and write on the edited draft. When `REVIEW_APPLY` is false, no edit is made: the review is reported and Step 5 writes nothing.

## 5. Report — pre-edit scores only

The persona scores are the read of the document **before** any improvement was applied. Nothing re-reads the edited document, so the report never asserts a post-edit score or a score delta. State what was applied; do not claim what it achieved. A caller who needs a measured post-edit score runs `--scope=review` again on the written file.

**User-facing format:**

```markdown
## Stakeholder Review: {filename}

**Personas consulted:** {list}
**Overall score (pre-edit):** {score}/100
**Improvements applied:** {count} · skipped: {count} · logged: {count}

### Persona Scores (pre-edit)

| Persona | Score | Top Concern |
|---------|-------|-------------|
| Executive | 78 | Missing ROI timeline |
| Technical | 85 | Vague implementation details |

### Questions Your Stakeholders Would Ask

**Executive:**
1. What's the expected payback period?

### Improvements Applied

1. **CRITICAL:** Added decision timeline (March 15, 2026) — raised by executive, marketing
2. **HIGH:** Broke dense paragraph into bullets — raised by end-user
3. **OPTIONAL (logged):** Add vendor comparison table — requires external research
```

**JSON for agent callers** (the `stakeholder_reviews[]` and `synthesis{}` fields of the copywriter agent's contract):

```json
{
  "stakeholder_reviews": [
    {"perspective": "executive", "score": 78, "strengths": [], "concerns": [], "recommendations": []}
  ],
  "synthesis": {
    "overall_score": 82,
    "audience_weighted_score": 84,
    "critical_improvements": [],
    "high_improvements": [],
    "optional_improvements": [],
    "recommendations_applied": true,
    "application_rate": 1.0
  }
}
```

`overall_score` and every entry in `stakeholder_reviews[]` are pre-edit values; `recommendations_applied` and `application_rate` describe what was done, not what it achieved.
