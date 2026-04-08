# cogni-claims

Cross-plugin claim verification system — fetches cited sources, detects deviations between claims and what sources actually say, and guides users through resolution.

## Plugin Architecture

```
skills/                           2 claims skills
  claims/                           Verification orchestrator (submit, verify, dashboard, inspect, resolve, cobrowse)
    scripts/
      claims-store.sh               Workspace init, ID generation, registry I/O
    references/
      dashboard-format.md           Dashboard rendering rules and status grouping
      verification-protocol.md      Verification agent dispatch and result collection
  claim-entity/                     Cross-plugin data model contract
    references/
      schema.md                     Full JSON schema, field tables, deviation types, batch format
      workspace-conventions.md      Directory structure, file formats, caching rules
    examples/
      claim-lifecycle.json          End-to-end claim lifecycle example

agents/                           2 verification agents
  claim-verifier.md                 Fetch one source URL (WebFetch), verify all claims (sonnet)
  source-inspector.md               Open source in browser (claude-in-chrome), locate passage, present evidence (sonnet)

commands/                         1 slash command
  claims.md                         /claims — submit, verify, dashboard, inspect, resolve, cobrowse
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 2 | claims, claim-entity |
| Agents | 2 | claim-verifier (sonnet, WebFetch), source-inspector (sonnet, claude-in-chrome) |
| Commands | 1 | /claims (aliases: /claim, /verify-claims) — 6 modes: submit, verify, dashboard, inspect, resolve, cobrowse |

## Data Model

Three record types compose the claim lifecycle:

| Record | Key Fields | Purpose |
|--------|-----------|---------|
| ClaimRecord | id, statement, source_url, status, deviations[], resolution, entity_ref, propagated_at | Single verifiable claim with lifecycle state and entity provenance |
| DeviationRecord | type, severity, source_excerpt, explanation | Specific discrepancy between claim and source |
| ResolutionRecord | action, corrected_statement, rationale | User's decision on a deviated claim |

**Status lifecycle:**

```
unverified ──> verified           (no deviations)
unverified ──> deviated           (deviations detected)
unverified ──> source_unavailable (source unreachable)
deviated   ──> resolved           (user resolves all deviations)
any status ──> re-verify          (returns to verified/deviated/source_unavailable)
```

**5 deviation types:** misquotation, unsupported_conclusion, selective_omission, data_staleness, source_contradiction

**4 severity levels:** low, medium, high, critical

## Workspace Layout

```
{working_dir}/cogni-claims/
├── claims.json          Registry of all ClaimRecords
├── sources/{hash}.json  Cached source content per URL
└── history/{id}.json    Audit trail per claim
```

Initialized by `claims-store.sh init` (idempotent).

## Design Principles

- **Findings are assessments, not facts** — deviation detection is LLM-based and can be wrong. Explanations use hedged language ("the source appears to say") rather than definitive assertions ("the claim is wrong")
- **User confirmation for all resolutions** — auto-resolving would risk silently accepting bad corrections. The user always has final say
- **Conservative over aggressive** — false positives erode trust. When a comparison is genuinely ambiguous, not flagging is safer
- **Always include the source excerpt** — without evidence the user can't evaluate whether a finding is legitimate
- **Unverifiable is not verified** — if a source can't be fetched, the claim stays `source_unavailable` rather than defaulting to verified

## Cross-Plugin Integration

| Plugin | Direction | Integration |
|--------|-----------|-------------|
| cogni-trends | upstream | trend-report submits claims after report generation |
| cogni-portfolio | upstream | portfolio-verify submits claims from web-sourced entities |
| cogni-research | upstream | verify-report submits claims extracted from research drafts |
| cogni-consulting | upstream | consulting-deliver runs final claim verification before deliverables |

Claims are submitted via `cogni-claims:claims` skill in submit mode. The `claim-entity` skill defines the shared data contract any submitting plugin must follow.

## Pipeline Position

```
{submitting plugin} ──> cogni-claims:claims (submit) ──> claim-verifier agents (verify)
                                                      ──> source-inspector agent (inspect)
                                                      ──> user resolution (resolve)
                                                      ──> interactive cobrowse (cobrowse)
```

## Source Fetching Strategy

The claim-verifier agent uses **WebFetch** as the sole automated fetch method. If WebFetch fails (403, timeout, anti-bot, paywall), the claim is marked `source_unavailable` — there is no automatic browser fallback.

Sources that WebFetch cannot reach can be recovered interactively via `/claims cobrowse`, where the user assists with authentication, cookie dismissal, and navigation while Claude reads and verifies in real-time using claude-in-chrome.

The source-inspector agent (used in inspect mode) opens sources in the user's browser via claude-in-chrome for visual evidence review.

Source cache files record which method succeeded via `fetch_method`: `"webfetch"` or `"cobrowse_interactive"`.

### Interactive cobrowse recovery

When WebFetch fails and claims are marked `source_unavailable`, the `/claims cobrowse` mode provides an interactive recovery path. The user dismisses cookie banners, logs in, scrolls to load dynamic content, while Claude reads and verifies in real-time using claude-in-chrome. This recovers sources that need human interaction no automated tool can provide.

## Key Conventions

- Claim IDs generated by `claims-store.sh gen-id` — deterministic, collision-free
- One claim-verifier agent per unique source URL — multiple claims grouped by URL for single fetch
- Source content cached in `sources/{url-hash}.json` — re-verification re-fetches
- Resolution actions: `corrected`, `disputed`, `alternative_source`, `discarded`, `accepted_override`
- Plugin version lives at the marketplace entry in `.claude-plugin/marketplace.json` at the monorepo root (single source of truth for all relative-path plugins; `plugin.json` intentionally carries no `version` field)
