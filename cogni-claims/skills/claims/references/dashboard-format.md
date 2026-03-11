# Dashboard Format

## Overview

The claims dashboard presents all claims grouped by status, with actionable information for user decision-making. Render as markdown in the conversation.

## Dashboard Layout

### Summary Header

```markdown
## Claims Dashboard

**Project:** {working_dir}
**Total claims:** {count} | Verified: {n} | Deviated: {n} | Unverified: {n} | Unavailable: {n} | Resolved: {n}
**Last updated:** {timestamp}
```

### Status Sections

Present sections in this order (skip empty sections):

#### 1. Deviations Requiring Attention

Claims with `status: deviated` and severity `medium` or higher. Sort by severity descending (critical first).

```markdown
### Deviations Requiring Attention ({count})

| ID | Claim (truncated) | Deviation | Severity | Source |
|----|-------------------|-----------|----------|--------|
| `claim-abc1` | "The AI market will reach $1.8T..." | unsupported_conclusion | **critical** | [AI Report](url) |
| `claim-def2` | "Revenue grew 45% year-over-year..." | misquotation | **high** | [Q4 Results](url) |

> Use `/claims inspect <id>` to review evidence, `/claims resolve <id>` to take action.
```

#### 2. Low-Severity Deviations

Claims with `status: deviated` and severity `low`. These are informational.

```markdown
### Low-Severity Deviations ({count})

| ID | Claim (truncated) | Deviation | Note |
|----|-------------------|-----------|------|
| `claim-ghi3` | "Approximately 60% of respondents..." | misquotation | Source says "59.7%" |
```

#### 3. Verified Claims

Claims with `status: verified`.

```markdown
### Verified Claims ({count})

| ID | Claim (truncated) | Source |
|----|-------------------|--------|
| `claim-jkl4` | "The study surveyed 1,200 participants..." | [Survey Report](url) |
```

#### 4. Source Unavailable

Claims with `status: source_unavailable`.

```markdown
### Source Unavailable ({count})

| ID | Claim (truncated) | Source | Reason |
|----|-------------------|--------|--------|
| `claim-mno5` | "According to internal data..." | [Internal](url) | 403 Forbidden |

> Consider providing alternative sources with `/claims resolve <id>`.
```

#### 5. Unverified

Claims with `status: unverified` (not yet processed).

```markdown
### Pending Verification ({count})

{count} claims awaiting verification. Run `/claims verify` to process.
```

#### 6. Resolved

Claims with `status: resolved`. Collapsed by default (show count only).

```markdown
### Resolved ({count})

{count} claims resolved. Use `/claims dashboard --show-resolved` to display.
```

## Resolution Prompt

When presenting resolution options for a specific claim (via `/claims resolve <id>`):

```markdown
## Resolve: claim-{id}

**Claim:** "{full statement}"
**Source:** [{title}]({url})
**Deviation:** {type} (severity: {severity})

**Source excerpt:**
> {verbatim excerpt from source}

**Assessment:** {explanation}

---

**Resolution options:**

1. **Correct** — Update the claim to match the source
2. **Dispute** — Mark the deviation finding as incorrect
3. **Alternative source** — Provide a different source URL
4. **Discard** — Remove this claim
5. **Accept as-is** — Keep the claim despite the deviation

Which action to take?
```

Present this using AskUserQuestion with the five options. Always include the source excerpt and explanation so the user has full context for their decision.

## Truncation Rules

- Claim statements in tables: truncate to 50 characters with "..."
- Source excerpts in resolution view: show full text (do not truncate)
- Source titles in links: show full title
- Dashboard shows at most 20 claims per section; add "and {n} more..." for overflow

## Sorting

- Deviated claims: severity descending (critical > high > medium > low), then submitted_at descending
- Verified claims: submitted_at descending
- Unverified claims: submitted_at ascending (oldest first = verify next)
- Resolved claims: resolved_at descending
