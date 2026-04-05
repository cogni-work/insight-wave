---
name: claims
description: |
  Manage claim verification lifecycle — submit, verify, review dashboard, inspect, and resolve claims.
  Use this skill whenever the user mentions claims, fact-checking, source verification, checking
  whether statements match their cited sources, reviewing deviations, or anything related to
  tracking the accuracy of sourced statements. Also use it when another plugin submits claims
  for verification (e.g., after a research or portfolio workflow produces sourced assertions).
  Even if the user doesn't say "claims" explicitly — if they're asking about verifying facts
  against sources, checking citations, finding outdated or mismatched data in cited references,
  reviewing what's been flagged, checking for stale sources, outdated data in references,
  or asking "which claims need attention" or "what did verification find", this skill handles it.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion
---

# Claims Verification Orchestrator

You manage the full lifecycle of sourced claims: accepting them, verifying them against their cited URLs, detecting deviations, presenting findings, and guiding the user through resolution.

The key insight behind this system is that LLM-generated content often cites sources but may subtly misrepresent them — a number rounded too aggressively, a conclusion that goes beyond what the source actually says, context that changes the meaning. This skill exists to catch those gaps systematically rather than hoping someone manually checks every citation.

## What this skill does NOT do

- **Generate claims** — that's the submitting plugin's job (e.g., cogni-trends, cogni-portfolio)
- **Make editorial decisions** — the user always has final say on how to handle deviations
- **Present findings as verdicts** — deviation detection is LLM-based, so findings are assessments for the user to review, not definitive judgments

## Choosing the right mode

Determine the operating mode from the user's intent. People rarely say "mode: verify" — they'll say things like "check my claims" or "what's the status" or "let me see what's wrong with claim-xyz". Here's how to map intent to mode:

| Mode | What triggers it | What it does |
|------|-----------------|--------------|
| `submit` | User or plugin provides new claims with sources | Add claims to the registry for tracking |
| `verify` | "verify", "check", "re-check", "re-verify", "run verification", or first time after submission | Fetch sources and compare claims against them |
| `dashboard` | "show", "status", "overview", "what claims", "dashboard", "what did you find", "which claims need attention", "what's the status" | Display all claims grouped by status |
| `inspect` | "inspect", "show me", "details on", "what's wrong with", "explain this deviation" + a claim ID | Deep-dive into one claim's evidence |
| `resolve` | "resolve", "fix", "handle", "deal with", "correct" + a claim ID | Walk the user through resolving a deviation |

When in doubt, `dashboard` is a safe default — it gives the user an overview and they can drill down from there.

## Workspace setup

Before any operation, make sure the workspace exists. Run the init script — it's idempotent, so calling it when the workspace already exists is fine:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/claims/scripts/claims-store.sh" init "${working_dir}"
```

The `working_dir` is either passed as a parameter or defaults to the current working directory. All claim state lives in `{working_dir}/cogni-claims/`.

## Submit mode

Accept one or more claims and register them for future verification.

Each claim needs: `statement` (the claim text), `source_url`, `source_title`, and `submitted_by` (the plugin name, or `"user"` for direct submissions).

**Steps:**
1. Generate a unique ID for each claim using the store script: `bash claims-store.sh gen-id`
2. Create a ClaimRecord with status `unverified` (see the `cogni-claims:claim-entity` skill for the data model)
3. Append to `claims.json` and update the `updated_at` timestamp
4. Write a submission event to `history/{claim-id}.json`
5. Tell the user how many claims were submitted

For batch submissions, process all claims in a single registry update to keep things efficient.

## Verify mode

This is where the real work happens — fetching sources and comparing claims against them.

### Step 1: Select which claims to verify

- If the user specified `--id <id>`, verify just that claim (even if already verified — this is re-verification)
- Otherwise, grab all claims with status `unverified`
- If there's nothing to verify, let the user know and stop

### Step 2: Group by source URL

Multiple claims often cite the same source. Group them by `source_url` so each URL is fetched exactly once. Tell the user: "Verifying {N} claims against {K} unique sources."

### Step 3: Dispatch verification agents

For each unique URL group, launch a `cogni-claims:claim-verifier` agent:

```
Agent parameters:
  subagent_type: "cogni-claims:claim-verifier"
  prompt: Include working_dir, source URL, claim IDs, and claim statements
```

Launch all agents in parallel when there are multiple URLs — this is the main performance optimization. Each agent fetches the source once and verifies all claims referencing it.

### Step 4: Collect and record results

As agents complete, update `claims.json` for each claim:
- No deviations found → status becomes `verified`
- Deviations detected → status becomes `deviated`, attach the DeviationRecords
- Source unreachable → status becomes `source_unavailable`

Also record the source excerpt and write verification events to each claim's history file.

### Step 5: Summarize and offer co-browsing

Show a brief summary:
```
Verification complete:
- {n} verified (no deviations)
- {n} deviations detected ({n} critical, {n} high, {n} medium, {n} low)
- {n} sources unavailable
- {n} recovered via browser fallback (included in verified/deviated counts above)
```

The "recovered via browser fallback" line shows how many sources were initially unreachable via WebFetch but succeeded when the claim-verifier fell back to headless browser (browsermcp). This helps the user understand the value of the browser fallback and which sources required it.

If there are deviated claims with severity `medium` or higher, briefly show each one (claim statement, deviation type, source excerpt) and proactively offer source inspection (see Source inspection section below). The goal is a seamless flow: verify → see the problem → decide what to do.

## Dashboard mode

Show the user where things stand. Read `claims.json`, group by status, and render the dashboard. The complete layout spec is in `references/dashboard-format.md` — follow it for section ordering, truncation rules, and sorting.

The dashboard should give the user a clear picture at a glance and make it obvious what needs attention (deviated claims with high severity) vs. what's fine (verified claims). Show at most 20 claims per status section — see `references/dashboard-format.md` for overflow handling and full layout spec.

For each deviated claim in the "Deviations Requiring Attention" section, include a one-line summary of what the deviation is (not just the type label) so the user can quickly decide which claims to inspect. When presenting action hints, emphasize that `/claims inspect <id>` will fetch the source via headless browser, locate the relevant passage, and capture a screenshot for review — this is the primary workflow for handling deviations.

## Inspect mode

When the user wants to dig into a specific claim's evidence. This mode should feel like a natural co-browsing session — show the evidence and immediately help the user see the source.

1. Look up the claim by ID
2. If it has deviations, show each one: type, severity, the verbatim source excerpt, and the explanation. Include a plain-language "What this means" summary that explains the discrepancy in context — why it matters and what a reader would get wrong.
3. If it's verified, show the supporting excerpt
4. Automatically launch source inspection (see Source inspection section below) — the whole point of inspect mode is to see the evidence in context, so don't just offer, do it
5. Once the source content and screenshot are available, offer to transition directly to resolve mode

## Resolve mode

Walk the user through resolving a deviated claim. If source inspection hasn't been done yet from inspect mode, launch it (see Source inspection section below) — the user should have the source evidence available while making their decision.

1. Look up the claim — it must have status `deviated`
2. Display the claim, its deviations, and the source excerpt
3. For the **Correct** option, generate a suggested correction based on what the source actually says. This saves the user from having to write it from scratch.
4. Present resolution options using AskUserQuestion:
   - **Correct** — update the claim to match the source (show the suggested correction, let user edit)
   - **Dispute** — the deviation finding is wrong (prompt for rationale)
   - **Alternative source** — the claim is right but needs a different source (prompt for URL)
   - **Discard** — remove the claim entirely (prompt for rationale)
   - **Accept as-is** — acknowledge the deviation but keep the claim (prompt for rationale)
5. Record the ResolutionRecord, update status to `resolved`, write to history. Preserve the `entity_ref` field on the claim — downstream systems (cogni-portfolio's portfolio-verify Step 8) use it to propagate corrections back to the entity files that originally contained the wrong data. Do not set `propagated_at` here — that's set by the propagating system after it applies the correction.
6. If the user chose "alternative source", offer to re-verify against the new URL

## Guiding principles

These aren't arbitrary rules — they reflect the fundamental nature of LLM-based verification:

- **Conservative detection**: Since an LLM is reading source text and making judgments, false positives are more damaging than false negatives. A false positive wastes the user's time investigating a non-issue and erodes trust. When the comparison is ambiguous, lean toward not flagging.

- **Evidence-first**: Showing the source excerpt alongside every finding lets the user quickly judge whether the deviation is real. Without the excerpt, the user has to go find the source themselves, which defeats the purpose.

- **Honest about uncertainty**: The system is making probabilistic assessments, not delivering court verdicts. Language like "appears to diverge" rather than "is wrong" correctly communicates the confidence level and respects the user's judgment.

- **User authority**: The system's job is to surface potential issues efficiently. The user decides what to do about them. Auto-resolving would be both presumptuous and risky.

- **No silent failures**: If a source can't be fetched, that's important information — it means the claim can't be verified, which is different from being verified clean.

## Source inspection

When the user needs to see a source in context — whether from verify, inspect, or resolve mode — launch the `cogni-claims:source-inspector` agent with the source URL, the verbatim excerpt, the claim statement, and the deviation explanation. The source-inspector uses headless browser (browsermcp) to navigate to the page, extract the text, locate the relevant passage, and capture a screenshot as visual evidence.

Source inspection is valuable because LLM-based deviation findings are assessments, not verdicts. Seeing the source content helps the user make informed decisions. Don't make the user request it explicitly — if they're looking at a deviation, they almost certainly want to see the source.

The source-inspector returns a structured result with the matched text, surrounding context, and a screenshot. If the passage was not found on the page, let the user know the source may have been updated since verification.

## Example flows

**Submit + Verify:**
- User: "I found these claims in the research report, can you check them?"
- System: submits claims, groups by URL, dispatches verifiers in parallel, shows summary with deviation counts
- User: "Show me the one about revenue growth" → transitions to inspect mode

**Dashboard + Resolve:**
- User: "What's the status of my claims?"
- System: renders dashboard showing 2 deviations (1 critical, 1 medium), 5 verified, 1 pending
- User: "Fix the critical one" → transitions to resolve mode with suggested correction

## When things go wrong

- **claims.json is corrupted or malformed**: The init script is idempotent and won't overwrite an existing file. If the file exists but is unreadable, tell the user, offer to back it up (rename to `claims.json.bak`), and reinitialize.
- **A verifier agent times out or returns malformed JSON**: Mark those claims as `source_unavailable` with a verification note explaining the failure, report to the user, and offer re-verification.
- **Source content changed since last verification**: This is expected — sources get updated. If `verified_at` is more than 7 days old, note this on the dashboard so the user knows the verification may be stale. Re-verification handles this cleanly.

## Reference files

- **`references/verification-protocol.md`** — Quality principles (epistemic humility, conservative detection, batch consistency) and re-verification rules. Read this when you need to understand the philosophical approach to verification or handle re-verification edge cases. The step-by-step methodology lives inline in the claim-verifier agent.
- **`references/dashboard-format.md`** — Complete dashboard layout spec with section ordering, truncation rules, and sorting. Read this when rendering the dashboard.

## Scripts

- **`scripts/claims-store.sh`** — Handles workspace init, ID generation, URL hashing, and claim counting. Invoke via: `bash "${CLAUDE_PLUGIN_ROOT}/skills/claims/scripts/claims-store.sh" <command> [args...]`

## Examples

- **`examples/claims-sample.json`** — A sample `claims.json` showing claims in all statuses with complete field structures. Useful for understanding the data shape.

## Cross-plugin contract

The ClaimEntity data model (record types, field definitions, status transitions) lives in the `cogni-claims:claim-entity` skill. Consult it when you need to create or validate record structures.

## Agents

- **`cogni-claims:claim-verifier`** — Fetches one source URL, verifies all claims against it, returns structured JSON. Launch in parallel for multiple URLs.
- **`cogni-claims:source-inspector`** — Opens a source URL in the browser and highlights the relevant passage for the user to inspect.
