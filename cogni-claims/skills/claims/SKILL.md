---
name: claims
description: |
  Manage claim verification lifecycle — submit, verify, review dashboard, inspect, resolve, and
  cobrowse claims. Use this skill whenever the user mentions claims, fact-checking, source
  verification, checking whether statements match their cited sources, reviewing deviations, or
  anything related to tracking the accuracy of sourced statements. Also use it when another plugin
  submits claims for verification (e.g., after a research or portfolio workflow produces sourced
  assertions). Even if the user doesn't say "claims" explicitly — if they're asking about verifying
  facts against sources, checking citations, finding outdated or mismatched data in cited references,
  reviewing what's been flagged, checking for stale sources, outdated data in references, or asking
  "which claims need attention" or "what did verification find", this skill handles it. Also trigger
  when the user wants to cobrowse unreachable sources together, recover unavailable claims
  interactively, open sources in their browser to help check them, or says things like "let's look
  at those sources together", "help me check these links", or "browse the unavailable sources".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__get_page_text, mcp__claude-in-chrome__read_page, mcp__claude-in-chrome__find, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__tabs_context_mcp
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
| `cobrowse` | "cobrowse", "let's look together", "help me check", "recover sources", "open sources", "browse together", "interactive check", "recover unavailable" | Interactive cobrowsing to recover source_unavailable claims |

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

### Step 2.5: Pre-flight environment check

Before dispatching agents, check whether claude-in-chrome is available. Verification itself uses WebFetch only (no browser fallback), but the source-inspector (inspect mode) and cobrowse mode need claude-in-chrome.

**Check claude-in-chrome:**
1. Attempt `mcp__claude-in-chrome__tabs_context_mcp`
2. If succeeds → set `cobrowse_available = true`
3. If errors out → set `cobrowse_available = false`

**Decision:**
- **Available** → proceed silently to Step 3. Inspect and cobrowse workflows will work.
- **Not available** → inform user: "claude-in-chrome is not available. Verification will proceed using WebFetch, but `/claims inspect` and `/claims cobrowse` will not work until claude-in-chrome is enabled." Proceed to Step 3.

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

If there are `source_unavailable` claims, add a recovery suggestion:
```
{n} source(s) could not be reached via WebFetch. Run `/claims cobrowse` to open them
in your browser for interactive recovery — you can help navigate logins, cookie banners,
and dynamic content while I read and verify.
```

If there are deviated claims with severity `medium` or higher, briefly show each one (claim statement, deviation type, source excerpt) and proactively offer source inspection (see Source inspection section below). The goal is a seamless flow: verify → see the problem → decide what to do.

## Dashboard mode

Show the user where things stand. Read `claims.json`, group by status, and render the dashboard. The complete layout spec is in `references/dashboard-format.md` — follow it for section ordering, truncation rules, and sorting.

The dashboard should give the user a clear picture at a glance and make it obvious what needs attention (deviated claims with high severity) vs. what's fine (verified claims). Show at most 20 claims per status section — see `references/dashboard-format.md` for overflow handling and full layout spec.

For each deviated claim in the "Deviations Requiring Attention" section, include a one-line summary of what the deviation is (not just the type label) so the user can quickly decide which claims to inspect. When presenting action hints, emphasize that `/claims inspect <id>` will open the source via claude-in-chrome, locate the relevant passage, and let the user review it directly in their browser — this is the primary workflow for handling deviations.

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

## Cobrowse mode

Interactive recovery for claims stuck at `source_unavailable`. The automated verification pipeline (WebFetch) already tried and failed for these sources — cobrowse mode is different because the **user actively helps**. They can dismiss cookie banners, log in to paywalled sites, accept terms, scroll to load dynamic content, or navigate to the right page section while you watch and verify.

This mode matters because many "unavailable" sources aren't truly gone — they just need human interaction that automated fetching can't provide. A pricing page behind a cookie wall, a report behind a corporate login, a dynamically-loaded table that needs a scroll — these are recoverable with the user's help.

### Pre-requisite: claude-in-chrome

Cobrowse mode requires the user's real Chrome browser via claude-in-chrome. Before starting:
1. Call `mcp__claude-in-chrome__tabs_context_mcp` to verify availability
2. If unavailable, tell the user: "Interactive cobrowsing requires claude-in-chrome (your Chrome browser). Please ensure the Claude-in-Chrome extension is active, then try again. In the meantime, you can use `/claims resolve <id>` to handle unavailable claims manually."
3. Stop — there is no fallback for this mode (the whole point is user-assisted navigation in the user's real browser)

### Step 1: Identify recovery candidates

Read `claims.json` and filter to `status === "source_unavailable"`. If the user specified `--id <claim-id>`, filter to just that claim. If `--url <url>`, filter to all claims citing that URL.

If no candidates found, tell the user: "No source_unavailable claims to recover. All claims are either verified, deviated, or resolved."

Group candidates by `source_url` (same grouping pattern as verify mode) — each URL is opened once, all claims citing it are verified together.

### Step 2: Session overview

Present what's ahead so the user knows what to expect:

```
Cobrowse Recovery Session

{N} claims across {K} sources are marked source_unavailable.

I'll open each source in your browser. You can help by:
- Dismissing cookie banners or popups
- Logging in if the source requires authentication
- Navigating to the right section or page
- Scrolling to load dynamic content (pricing tables, expandable sections)

Tell me "ready" when the page content is visible, and I'll read and verify.

Sources to recover:
1. [{Source Title}]({url}) — {n} claim(s)
2. [{Source Title}]({url}) — {n} claim(s)
...
```

Use AskUserQuestion: "How would you like to proceed?" with options:
- **Start all** — go through every source in order
- **Select specific** — let user pick which sources to recover (show numbered list)
- **Cancel** — exit cobrowse mode

### Step 3: Per-URL recovery loop

For each source URL in the session:

**3a. Open in browser**

Always open a new tab — never navigate the user's active tab:
```
mcp__claude-in-chrome__tabs_create_mcp  → get new tab ID
mcp__claude-in-chrome__navigate         → go to source URL
```

Tell the user which source is now open: "Opened [{Source Title}]({url}) — {n} claim(s) depend on this source."

**3b. Initial page assessment**

Attempt a first read via `mcp__claude-in-chrome__get_page_text`. Based on what comes back, classify the page state and guide the user:

- **Content visible** (substantial text returned, relevant keywords found): "The page content appears loaded. I can see text that may contain the information we need. Shall I verify now, or do you need to interact with the page first?"
- **Login/paywall detected** (login form indicators, "sign in", "subscribe", thin content with auth prompts): "This page appears to require authentication. Please log in, and tell me when you're ready."
- **Cookie/popup barrier** (cookie consent indicators, overlay text, very thin content): "There may be a cookie banner or popup blocking content. Please dismiss it, then tell me when ready."
- **404 or error page** (error indicators, "page not found", HTTP error text): "This page returns an error — the source may have been removed or moved. You can provide an alternative URL or skip this source."
- **Empty/minimal** (very little text, possibly JS-rendered content not yet loaded): "The page content appears empty — it may need scrolling or interaction to load. Please interact with the page and tell me when the content is visible."

**3c. User interaction checkpoint**

Use AskUserQuestion with options:
- **Ready** — page content is visible, proceed to verify
- **Re-read** — try extracting content again (user may have scrolled, dismissed popups, etc.)
- **Alternative URL** — provide a different URL for this source
- **Skip** — move to next source URL
- **End session** — stop cobrowsing entirely, save results so far

If the user chooses "Alternative URL", ask for the new URL, navigate to it, and return to step 3b.

If the user chooses "Re-read", extract content again and re-assess. Allow multiple re-reads — the user may need several interactions before the page is fully loaded.

**3d. Content extraction**

Extract the page content:
1. Primary: `mcp__claude-in-chrome__get_page_text`
2. If thin or empty, try `mcp__claude-in-chrome__read_page` as alternative
3. If both return insufficient content, tell the user what you got and ask if they can see more on the page. Sometimes the content is in an iframe or dynamically loaded section that text extraction misses — the user can confirm whether the information is actually visible on their screen.

**3e. Inline verification**

For each claim in the URL group, verify against the extracted content. Apply the same 5-dimension comparison used by the claim-verifier agent:

1. **Accuracy** — does the claim faithfully represent the source's words and numbers?
2. **Inference** — does the claim draw conclusions the source supports?
3. **Completeness** — does the claim include relevant context, or does omission change meaning?
4. **Currency** — is the source data still current relative to the claim's timeframe?
5. **Agreement** — does the source support, contradict, or stay silent on the claim?

For each claim, determine:
- **Verified** — claim matches source, no deviations. Include the supporting excerpt.
- **Deviated** — discrepancy found. Create DeviationRecord(s) with type, severity, source_excerpt, and explanation using the same hedged language as automated verification ("the source appears to say..." not "the claim is wrong").
- **Still unavailable** — relevant passage not found in the extracted content despite the page being loaded. Note this with verification_notes explaining what was searched for and what the page actually contained.

**3f. Present results per URL**

Show the verification results for all claims against this source:

```
Source: [{Title}]({url})

claim-abc123: VERIFIED
  "Cloud spending grew 29%..." — matches source excerpt.

claim-def456: DEVIATED (misquotation, medium)
  Claim says "45% growth", source says "30-35% growth in Q3".

claim-ghi789: STILL UNAVAILABLE
  Relevant passage not found on page. The page contains product descriptions
  but no pricing data matching the claim.
```

Use AskUserQuestion: "How do you want to handle these results?" with options:
- **Accept all** — save all results and move to next source
- **Re-read page** — extract content again (user may have navigated to a different section)
- **Adjust** — override a specific claim's result (prompt for claim ID and what to change)
- **Skip without saving** — don't update these claims, move to next source

**3g. Save results**

On "Accept all" or after adjustments:
1. Update `claims.json` — change status from `source_unavailable` to `verified`, `deviated`, or keep as `source_unavailable` based on results. Attach DeviationRecords for deviated claims.
2. Write source cache to `sources/{url-hash}.json` with `fetch_method: "cobrowse_interactive"` — this distinguishes interactive recovery from the automated cobrowse fallback. (cogni-claims emits only `webfetch` / `cobrowse_interactive`; the shared `fetch_method` vocabulary also includes `webfetch_fulltext` — a fuller-body primary-tier web fetch — and `direct` — a non-web local source — both written by cogni-knowledge and recognized-but-never-emitted here, per `CLAUDE.md`'s Source Fetching Strategy.)
3. Write history event for each claim:
   ```json
   {
     "event": "cobrowse_recovery",
     "timestamp": "...",
     "data": {
       "previous_status": "source_unavailable",
       "new_status": "verified",
       "fetch_method": "cobrowse_interactive",
       "user_assisted": true
     }
   }
   ```

### Step 4: Session summary

After all URLs are processed (or the user ends the session):

```
Cobrowse Recovery Complete

Recovered: {n} of {total} unavailable claims
- {n} now verified (no deviations)
- {n} now deviated ({n} high, {n} medium, {n} low)
- {n} still unavailable (source gone or content not found)
- {n} skipped by user
```

If any claims remain `source_unavailable`, suggest: "Remaining unavailable claims can be resolved manually via `/claims resolve <id>` — you can provide alternative sources, accept as-is, or discard."

If deviated claims were found during recovery, suggest: "Use `/claims inspect <id>` to review the newly detected deviations, or `/claims resolve <id>` to handle them."

### Edge cases

- **User can't access the page either** (genuinely 404, domain expired, content removed): Note as `confirmed_unavailable` in the claim's `verification_notes` field. The claim stays `source_unavailable` but the history records that a human also confirmed the source is gone. Offer `/claims resolve <id>` to provide an alternative source or discard.

- **Page loads but relevant content is missing** (the page exists but the specific data point — e.g., a pricing table — is no longer there): The claim stays `source_unavailable` with a verification note like "Page accessible but pricing section no longer present — content may have been restructured." This is different from a 404 and gives the user better context for resolution.

- **User provides an alternative URL mid-session**: Navigate to the new URL, extract and verify. If verification succeeds, update the claim's `source_url` and `source_title` to the new source. This is a proper re-verification, not a resolution — the claim gets a fresh status based on the new source.

- **Session interrupted** (user says "End session" midway): Save all results collected so far. Report what was processed and what remains. Unprocessed claims stay `source_unavailable` — the user can resume with `/claims cobrowse` later.

- **Mixed results within a URL group** (some claims verify, others deviate or remain unavailable): Handle each claim independently. The user confirms the batch per URL, but individual claims can have different outcomes.

## Guiding principles

These aren't arbitrary rules — they reflect the fundamental nature of LLM-based verification:

- **Conservative detection**: Since an LLM is reading source text and making judgments, false positives are more damaging than false negatives. A false positive wastes the user's time investigating a non-issue and erodes trust. When the comparison is ambiguous, lean toward not flagging.

- **Evidence-first**: Showing the source excerpt alongside every finding lets the user quickly judge whether the deviation is real. Without the excerpt, the user has to go find the source themselves, which defeats the purpose.

- **Honest about uncertainty**: The system is making probabilistic assessments, not delivering court verdicts. Language like "appears to diverge" rather than "is wrong" correctly communicates the confidence level and respects the user's judgment.

- **User authority**: The system's job is to surface potential issues efficiently. The user decides what to do about them. Auto-resolving would be both presumptuous and risky.

- **No silent failures**: If a source can't be fetched, that's important information — it means the claim can't be verified, which is different from being verified clean.

## Source inspection

**Pre-dispatch guard:** Before dispatching source-inspector, check whether claude-in-chrome was available during the pre-flight check (Step 2.5). If `cobrowse_available = false`, do NOT dispatch the agent — tell the user directly:
- Source inspection requires claude-in-chrome, which was not available during the pre-flight check
- Recommendation: enable claude-in-chrome and retry, or skip inspection and proceed to resolve using the deviation data already available from verification

When claude-in-chrome is available and the user needs to see a source in context — whether from verify, inspect, or resolve mode — launch the `cogni-claims:source-inspector` agent with the source URL, the verbatim excerpt, the claim statement, and the deviation explanation. The source-inspector uses claude-in-chrome to open the page in the user's browser, extract the text, and locate the relevant passage.

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
