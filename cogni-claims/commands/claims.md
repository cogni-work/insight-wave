---
name: claims
description: Manage claim verification lifecycle — submit, verify, review dashboard, inspect, and resolve claims
usage: /claims <mode> [options] — modes: submit, verify, dashboard, inspect, resolve
argument-hint: "<mode> [options]"
aliases: [claim, verify-claims]
category: verification
allowed-tools: ["Read", "Write", "Bash", "Task", "AskUserQuestion", "WebFetch", "Glob", "Grep", "Skill"]
---

# Claims Command

Manage the full lifecycle of sourced claims: submission, verification against cited sources, dashboard review, source inspection, and user-guided resolution.

## Usage

```
/claims <mode> [options]
```

## Modes

### submit — Ingest new claims

```
/claims submit "claim statement" --source "https://url" --title "Source Title"
/claims submit --batch   (reads claims from context or file)
```

Submit one or more claims for tracking and future verification.

**Required for single claim:**
- First argument: the claim statement (quoted)
- `--source`: source URL
- `--title`: human-readable source title

**Batch mode:**
- `--batch`: submit multiple claims from the current conversation context or a provided JSON array
- Each batch item needs: statement, source_url, source_title

**Processing:**
1. Parse the claim(s) from arguments
2. Invoke the `cogni-claims:claims` skill with mode `submit`
3. Report how many claims were submitted and their IDs

### verify — Run verification pipeline

```
/claims verify
/claims verify --id claim-abc123
```

Verify unverified claims against their cited sources. Optionally re-verify a specific claim.

**Options:**
- `--id <claim-id>`: verify (or re-verify) a specific claim
- No options: verify all unverified claims

**Processing:**
1. Invoke the `cogni-claims:claims` skill with mode `verify`
2. The skill dispatches `claim-verifier` agents in parallel (one per unique source URL)
3. Present verification summary to user

### dashboard — Show claims overview

```
/claims dashboard
/claims dashboard --show-resolved
```

Display all claims grouped by status with actionable information.

**Options:**
- `--show-resolved`: include resolved claims in the display

**Processing:**
1. Invoke the `cogni-claims:claims` skill with mode `dashboard`
2. Render the formatted dashboard

### inspect — Review claim evidence

```
/claims inspect <claim-id>
```

Show detailed deviation evidence for a specific claim, with option to open the source in the browser.

**Required:**
- `<claim-id>`: the claim to inspect

**Processing:**
1. Invoke the `cogni-claims:claims` skill with mode `inspect`
2. Display deviation details with source excerpts
3. Offer browser inspection if deviations exist

### resolve — Resolve a deviated claim

```
/claims resolve <claim-id>
```

Present resolution options for a claim with detected deviations.

**Required:**
- `<claim-id>`: the claim to resolve (must have status `deviated`)

**Processing:**
1. Invoke the `cogni-claims:claims` skill with mode `resolve`
2. Present the claim, deviations, and evidence
3. Show resolution options via AskUserQuestion
4. Record the user's decision

## Examples

### Example 1: Submit a single claim
```
/claims submit "The global AI market will reach $1.8T by 2030" --source "https://example.com/report" --title "AI Market Forecast"
```

### Example 2: Verify all pending claims
```
/claims verify
```

### Example 3: View the dashboard
```
/claims dashboard
```

### Example 4: Inspect a specific claim
```
/claims inspect claim-abc123
```

### Example 5: Resolve a deviation
```
/claims resolve claim-abc123
```

## Working Directory

The command determines the working directory in this order:
1. `--dir <path>` if provided
2. Current working directory

Claims state is stored in `{working_dir}/cogni-claims/`.

## Integration

**Skill used:** `cogni-claims:claims` (main orchestrator)
**Agents used (via skill):** `cogni-claims:claim-verifier`, `cogni-claims:source-inspector`

**Execution pattern:**
Command → parses mode and args → invokes claims skill → skill dispatches agents → results returned to user

## Error Handling

- **No claims.json found**: Initialize workspace automatically
- **Invalid claim ID**: Report "Claim not found" with suggestion to run `/claims dashboard`
- **No unverified claims**: Report "All claims are already verified"
- **Invalid mode**: Show usage help with available modes
