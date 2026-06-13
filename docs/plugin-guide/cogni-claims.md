# cogni-claims

**Plugin guide** — for canonical positioning see the [cogni-claims README](../../cogni-claims/README.md).

---

## Overview

cogni-claims manages the full lifecycle of sourced-claim verification within a Claude Cowork workspace. When another plugin — cogni-knowledge, cogni-trends, cogni-portfolio, or cogni-sales — produces content that cites sources, cogni-claims is the layer that checks whether the sources actually say what the claims assert.

The plugin accepts individual claims or batches imported from markdown, fetches each cited source, detects discrepancies, and surfaces findings in a dashboard. You then decide, claim by claim, how to resolve each one: correct the text, find a better source, dispute the finding, or accept the deviation as-is.

Nothing gets resolved without your input. Deviation detection is LLM-based and the plugin treats its own findings as assessments rather than verdicts.

---

## Key Concepts

| Term | What it means in practice |
|------|--------------------------|
| **Claim** | A factual assertion paired with a source URL — the unit of work in cogni-claims |
| **Deviation** | A discrepancy found between what the claim says and what the source actually says |
| **Deviation type** | The category of mismatch: misquotation, unsupported conclusion, selective omission, data staleness, or source contradiction |
| **Severity** | How consequential the deviation is: critical, major, minor, or cosmetic |
| **Resolution** | Your decision about a deviated claim: corrected, disputed, alternative source, discarded, or accepted as-is |
| **claim-verifier agent** | A sub-agent dispatched once per unique source URL — fetches the page and checks all claims citing it in one pass |
| **source-inspector agent** | A sub-agent that opens the source in your browser and highlights the relevant passage so you can compare directly |
| **ClaimRecord** | The JSON structure representing one claim: id, statement, source URL, status, deviations, resolution |

### Status transitions

A claim moves through a defined state machine:

```
unverified  →  verified
            →  deviated
            →  source_unavailable
```

A deviated claim gains a `resolution` field when you act on it.

---

## Getting Started

The fastest path into cogni-claims is to let another plugin generate sourced content and then verify it:

```
Search the web for recent findings on LLM citation accuracy and verify the claims
```

What happens:
1. Claude searches, produces sourced findings, and submits them as claims to `cogni-claims/claims.json`
2. The verification runs — one claim-verifier agent per unique source URL
3. You receive a dashboard showing each claim grouped by status (verified, deviated, source unavailable)
4. Any deviated claims show the deviation type, severity, and the excerpt from the source that contradicts the claim

Your workspace gains a `cogni-claims/` directory:

```
cogni-claims/
├── claims.json       all claims with status and evidence
├── sources/          cached source content per URL
└── history/          audit trail per claim
```

---

## Capabilities

### `claims` — Verification orchestrator

The main skill handles five operating modes. You do not need to name the mode explicitly — describe your intent and the skill routes accordingly.

**Submit** — add claims individually or import a batch from a markdown file with citations:

```
submit the claims from my research report
```

```
/claims submit --batch
```

**Verify** — fetch each cited source and check claims against it:

```
verify my unverified claims
```

```
/claims verify
```

**Dashboard** — see all claims grouped by status with inline deviation summaries:

```
what's the status of my claims?
```

```
/claims dashboard
```

**Inspect** — open a source in your browser with the relevant passage highlighted, so you can read the original in context:

```
show me what the source actually says for claim-007
```

```
/claims inspect claim-007
```

**Resolve** — work through deviated claims and decide what to do with each one:

```
let's fix the deviated claims one by one
```

```
/claims resolve claim-007
```

---

### `claim-entity` — Cross-plugin data contract

This skill defines the shared schemas — ClaimRecord, DeviationRecord, ResolutionRecord — used by every plugin that submits or consumes claims. You interact with this skill indirectly: when another plugin produces sourced content, it reads claim-entity to know how to format the submission.

If you are building a plugin that needs to submit claims for verification, read `cogni-claims/skills/claim-entity/references/schema.md` for the full field definitions and batch submission format.

---

## Integration Points

### Upstream — plugins that send claims to cogni-claims

| Plugin | When it submits claims |
|--------|----------------------|
| cogni-knowledge | After the inverted pipeline deposits a synthesis with cited sources |
| cogni-trends | After a trend report with sourced findings |
| cogni-portfolio | After proposition modeling produces sourced assertions |
| cogni-sales | After a sales pitch with cited supporting data |
| cogni-consult | During a deliverable's design-thinking loop (assumption verification) and its final quality gate |

### Downstream — nothing depends on cogni-claims for content

cogni-claims is a terminal verification service. Its outputs — verified or resolved claims — feed back into your editorial process, not into another plugin.

---

## Common Workflows

### Workflow 1: Verify a research report before publishing

1. Run `cogni-knowledge` to produce a sourced synthesis
2. The report's citations are submitted as claims automatically (or submit them manually with `/claims submit --batch`)
3. Run `/claims verify` to fetch each source and check all claims against it
4. Open `/claims dashboard` to see what needs attention
5. For each deviated claim, run `/claims inspect <id>` to compare claim to source in context
6. Run `/claims resolve <id>` to correct, dispute, or discard each deviation
7. Use the corrected claim text to update the research report

This workflow is part of the `research-to-slides` pipeline described in [../workflows/research-to-slides.md](../workflows/research-to-slides.md).

### Workflow 2: Spot-check a single claim

When you have one specific claim to verify — not a full batch:

```
Verify the claim that "45% of GPT-4o citations contain bibliographic errors" against https://mental.jmir.org/2025/1/e80371
```

The skill submits the claim, verifies it against the URL, and returns the finding immediately. No need to run a full batch workflow.

### Workflow 3: Use cogni-claims inside a consulting engagement

During a cogni-consult deliverable's define stage, claims from the discovery synthesis are verified before the problem statement is finalized. The engagement dispatches to claims automatically. You can also trigger it manually:

```
verify the assumptions from our discovery phase
```

See [../workflows/new-engagement.md](../workflows/new-engagement.md) for the full consulting pipeline.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `source_unavailable` status on most claims | The cited URLs are paywalled, behind login, or return 403 | Inspect the claim manually via `/claims inspect` and assess whether the source description is accurate; resolve as `accepted_as_is` or find an open-access alternative |
| Verification finds no deviations but the claim looks wrong to you | The source was fetched but the relevant passage was not in the cached text (e.g., behind JavaScript rendering) | Use `/claims inspect` to open the source in your browser and compare manually |
| Claims submitted by another plugin are not appearing | The submitting plugin may be writing to a different working directory | Check that `cogni-claims/claims.json` exists in the current project directory; if it is missing, the submitting plugin may need `cogni-claims` to be initialized first |
| Claim IDs are not showing in dashboard | `claims.json` exists but is malformed | Open the file and check for JSON syntax errors; the claim-entity schema in `cogni-claims/skills/claim-entity/references/schema.md` shows the expected structure |
| `/claims resolve` updates the record but the research report still has the old text | cogni-claims stores resolutions in JSON — it does not rewrite the source document | Copy the corrected claim text from the resolution record back into your research report manually |

---

## Known Issues

**Chrome native messaging host conflict (KI-001):** When both Claude Desktop (Cowork) and Claude Code are installed, they register competing native messaging host configurations for the Chrome extension. The cobrowse feature — which opens a source URL in your browser and highlights the relevant passage — relies on these browser automation tools. If Claude Code's native host is active, cobrowse will be unavailable and claim verification falls back to web fetch only (no visual source inspection).

**Workaround:** Toggle native messaging host configs by renaming the `.json` file for the unused product in `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/` and restarting Chrome. See the [Known Issues Registry](../../cogni-docs/references/known-issues.md) for detailed steps.

---

## Extending This Plugin

cogni-claims is open-source under AGPL-3.0. The most useful contribution areas are:

- **New deviation types** — the current taxonomy covers misquotation, unsupported conclusion, selective omission, data staleness, and source contradiction. If you encounter a systematic error pattern not in this list, a new type is a good addition.
- **Source fetching improvements** — JavaScript-heavy pages and login-gated sources are the hardest cases. Contributions that improve the claim-verifier agent's ability to handle these are high-value.
- **New resolution workflows** — the current resolution types cover the common cases; domain-specific workflows (e.g., academic citation correction) may benefit from additional resolution paths.

See [CONTRIBUTING.md](../../cogni-claims/CONTRIBUTING.md) for guidelines.
