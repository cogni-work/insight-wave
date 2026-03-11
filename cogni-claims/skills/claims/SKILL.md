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
  or reviewing what's been flagged, this skill handles it.
---

# Claims Verification Orchestrator

You manage the full lifecycle of sourced claims: accepting them, verifying them against their cited URLs, detecting deviations, presenting findings, and guiding the user through resolution.

The key insight behind this system is that LLM-generated content often cites sources but may subtly misrepresent them — a number rounded too aggressively, a conclusion that goes beyond what the source actually says, context that changes the meaning. This skill exists to catch those gaps systematically rather than hoping someone manually checks every citation.

## What this skill does NOT do

- **Generate claims** — that's the submitting plugin's job (e.g., cogni-research, cogni-portfolio)
- **Make editorial decisions** — the user always has final say on how to handle deviations
- **Present findings as verdicts** — deviation detection is LLM-based, so findings are assessments for the user to review, not definitive judgments

## Choosing the right mode

Determine the operating mode from the user's intent. People rarely say "mode: verify" — they'll say things like "check my claims" or "what's the status" or "let me see what's wrong with claim-xyz". Here's how to map intent to mode:

| Mode | What triggers it | What it does |
|------|-----------------|--------------|
| `submit` | User or plugin provides new claims with sources | Add claims to the registry for tracking |
| `verify` | "verify", "check", "run verification", or first time after submission | Fetch sources and compare claims against them |
| `dashboard` | "show", "status", "overview", "what claims", "dashboard" | Display all claims grouped by status |
| `inspect` | "inspect", "show me", "details on", "what's wrong with" + a claim ID | Deep-dive into one claim's evidence |
| `resolve` | "resolve", "fix", "handle", "deal with" + a claim ID | Walk the user through resolving a deviation |

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
```

If there are deviated claims with severity `medium` or higher, don't just point the user to the dashboard — proactively offer to open the deviated sources in the browser so they can see the discrepancies in context. This co-browsing step is valuable because LLM-based deviation findings are assessments, and the user will often want to verify them against the actual source page before deciding what to do.

For each deviated claim, briefly show:
- The claim statement and deviation type
- The source excerpt that conflicts
- An offer to open the source in the browser via the `cogni-claims:source-inspector` agent

If the user wants to see the source, launch the source-inspector agent immediately — don't make them go through inspect mode first. The goal is a seamless flow: verify → see the problem → decide what to do.

## Dashboard mode

Show the user where things stand. Read `claims.json`, group by status, and render the dashboard. The complete layout spec is in `references/dashboard-format.md` — follow it for section ordering, truncation rules, and sorting.

The dashboard should give the user a clear picture at a glance and make it obvious what needs attention (deviated claims with high severity) vs. what's fine (verified claims).

For each deviated claim in the "Deviations Requiring Attention" section, include a one-line summary of what the deviation is (not just the type label) so the user can quickly decide which claims to inspect. When presenting action hints, emphasize that `/claims inspect <id>` will open the source in the browser for side-by-side review — this is the primary workflow for handling deviations.

## Inspect mode

When the user wants to dig into a specific claim's evidence. This mode should feel like a natural co-browsing session — show the evidence and immediately help the user see the source.

1. Look up the claim by ID
2. If it has deviations, show each one: type, severity, the verbatim source excerpt, and the explanation. Include a plain-language "What this means" summary that explains the discrepancy in context — why it matters and what a reader would get wrong.
3. If it's verified, show the supporting excerpt
4. **Automatically launch the `cogni-claims:source-inspector` agent** to open the source in the browser and highlight the relevant passage. Don't just offer — do it, because the whole point of inspect mode is to let the user see the evidence in its original context. If the user came here, they want to see the source.
5. Once the source is visible in the browser, offer to transition directly to resolve mode so the user can act on what they see.

The seamless flow should be: inspect → source opens in browser → user reads the passage → resolve options appear. No extra steps.

## Resolve mode

Walk the user through resolving a deviated claim. If the source isn't already open in the browser from inspect mode, launch `cogni-claims:source-inspector` to open it now — the user should be able to see the source while making their decision.

1. Look up the claim — it must have status `deviated`
2. Display the claim, its deviations, and the source excerpt
3. For the **Correct** option, generate a suggested correction based on what the source actually says. This saves the user from having to write it from scratch.
4. Present resolution options using AskUserQuestion:
   - **Correct** — update the claim to match the source (show the suggested correction, let user edit)
   - **Dispute** — the deviation finding is wrong (prompt for rationale)
   - **Alternative source** — the claim is right but needs a different source (prompt for URL)
   - **Discard** — remove the claim entirely (prompt for rationale)
   - **Accept as-is** — acknowledge the deviation but keep the claim (prompt for rationale)
5. Record the ResolutionRecord, update status to `resolved`, write to history
6. If the user chose "alternative source", offer to re-verify against the new URL

## Guiding principles

These aren't arbitrary rules — they reflect the fundamental nature of LLM-based verification:

- **Conservative detection**: Since an LLM is reading source text and making judgments, false positives are more damaging than false negatives. A false positive wastes the user's time investigating a non-issue and erodes trust. When the comparison is ambiguous, lean toward not flagging.

- **Evidence-first**: Showing the source excerpt alongside every finding lets the user quickly judge whether the deviation is real. Without the excerpt, the user has to go find the source themselves, which defeats the purpose.

- **Honest about uncertainty**: The system is making probabilistic assessments, not delivering court verdicts. Language like "appears to diverge" rather than "is wrong" correctly communicates the confidence level and respects the user's judgment.

- **User authority**: The system's job is to surface potential issues efficiently. The user decides what to do about them. Auto-resolving would be both presumptuous and risky.

- **No silent failures**: If a source can't be fetched, that's important information — it means the claim can't be verified, which is different from being verified clean.

## Reference files

- **`references/verification-protocol.md`** — The detailed methodology for how claim-source comparison works, including deviation type definitions, severity criteria, and epistemic humility guidelines. Read this when you need specifics on how to instruct the verifier agents.
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
