# cogni-claims

A [Claude Cowork](https://claude.ai/cowork) plugin that verifies whether sourced claims actually match what their cited sources say.

## Why this exists

LLMs cite sources confidently — but the citations are often wrong. Numbers get rounded into different claims, conclusions overshoot what the source actually says, and URLs sometimes point to pages that don't exist. The gap between "cited" and "correct" is large enough to cause real harm, and it's well-documented:

| Problem | Finding | Source |
|---------|---------|--------|
| Fabricated citations | 14–95% of LLM citations are hallucinated depending on domain (2.2M citations analyzed) | [GhostCite, 2025](https://arxiv.org/html/2602.06718) |
| Inaccurate citations | AI search engines fail to produce accurate citations in >60% of tests (8 engines tested) | [CJR Tow Center, 2025](https://www.cjr.org/tow_center/we-compared-eight-ai-search-engines-theyre-all-bad-at-citing-news.php) |
| Bibliographic errors | 45.4% of GPT-4o citations contain bibliographic errors (most commonly invalid DOIs); 19.9% entirely fabricated | [JMIR Mental Health, 2025](https://mental.jmir.org/2025/1/e80371) |
| Real-world harm | Lawyers sanctioned after submitting AI-fabricated case citations to court | [Mata v. Avianca, 2023](https://law.justia.com/cases/federal/district-courts/new-york/nysdce/1:2022cv01461/575354/54/) |

Every claim above has been verified against its source using this plugin. This plugin exists because "cited" doesn't mean "correct."

## What it is

A systematic claim-verification workflow for Claude Cowork. Other plugins generate sourced content — this one checks whether the sources actually say what's claimed. It's designed for cross-plugin use: submit claims from anywhere, verify and resolve them here.

## What it does

1. **Submit** claims with their source URLs — individually or batch-imported from markdown → `cogni-claims/claims.json` → cogni-consulting/consulting-deliver, synthesize
2. **Verify** them by fetching each source and detecting deviations (misquotation, unsupported conclusions, selective omission, data staleness, source contradiction)
3. **Review** a dashboard showing all claims grouped by status, with inline deviation summaries and severity indicators
4. **Inspect** flagged claims by opening the source in your browser with the relevant passage highlighted for side-by-side comparison
5. **Resolve** each deviation — correct the claim, dispute the finding, find an alternative source, discard, or accept as-is
6. **Cobrowse** sources that couldn't be reached automatically — you navigate logins, cookie banners, and dynamic content while Claude reads and verifies in real-time

## What it means for you

If you ship research, reports, or any content that leans on sourced claims, this is your safety net before publish.

- **Catch errors before they reach your audience.** Each claim is fetched against its cited source and checked for 5 deviation types — misquotation, unsupported conclusions, selective omission, data staleness, and source contradiction.
- **Stay in control.** Deviation detection is LLM-based. Findings are assessments for you to review, not verdicts — you decide whether to correct, dispute, or accept each one.
- **Keep a paper trail.** Every claim, verification result, and resolution decision is stored as structured JSON — a complete audit trail from assertion to source to decision.

## Installation

cogni-claims is part of the [insight-wave](https://github.com/cogni-work/insight-wave) plugin suite and installs automatically via the Claude Cowork marketplace. No manual setup required.

## Quick start

```
/claims submit --batch        # batch-import claims from a markdown file with citations
/claims verify                # verify all unverified claims against their sources
/claims dashboard             # review claim statuses and deviation summaries
/claims inspect <claim-id>    # open the source in your browser with the passage highlighted
/claims resolve <claim-id>    # decide what to do about a deviation
/claims cobrowse               # interactively recover sources that automated verification couldn't reach
```

Aliases: `/claim`, `/verify-claims`

Or just describe what you want in natural language — the plugin figures out the right mode:

- "verify the claims in my research report"
- "what's the status of my claims?"
- "show me what the source actually says for that quantum computing claim"
- "let's fix the deviated claims one by one"
- "let's look at those unavailable sources together"

## Try it

After installing, type one prompt:

> Search the web for LLM citation hallucination errors and verify the claims

Claude researches the topic, produces sourced findings, then automatically verifies each claim against its cited source. You'll see which claims check out and which don't — then you can resolve any deviations.

Results land in your project's `cogni-claims/` directory:

```
cogni-claims/
├── claims.json              # all claims with status + evidence
├── sources/                 # cached source content per URL
└── history/                 # audit trail per claim
```

## Data model

Three core entity types with defined status transitions:

| Entity | Key fields | Description |
|--------|-----------|-------------|
| `ClaimRecord` | claim_id, claim_text, source_url, status, entity_ref, propagated_at | A factual assertion with its cited source and optional provenance link to the entity file it describes. Status: `unverified` → `verified` / `deviated` / `source_unavailable` |
| `DeviationRecord` | deviation_type, severity, evidence | A discrepancy found during verification. Types: misquotation, unsupported_conclusion, selective_omission, data_staleness, source_contradiction |
| `ResolutionRecord` | resolution_type, new_claim_text | How a deviation was resolved. Types: corrected, disputed, alternative_source, discarded, accepted_as_is |

When claims are submitted with an `entity_ref` (pointing to the source entity file and field), resolved corrections can propagate back to update the original data. The `propagated_at` timestamp tracks whether a correction has been applied. See cogni-portfolio's `portfolio-verify` skill for the propagation workflow.

See [skills/claim-entity/references/schema.md](skills/claim-entity/references/schema.md) for the full schema.

## How it works

Claims are stored in your project's `cogni-claims/` directory as JSON. When you verify, the plugin dispatches a **claim-verifier** agent per unique source URL — each agent fetches the page once and checks all claims referencing it. For deviated claims, the **source-inspector** agent can open the source in Chrome and highlight the relevant passage so you can see the discrepancy in context.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `claims` | skill | Manage claim verification lifecycle — submit, verify, review dashboard, inspect, resolve, and cobrowse claims |
| `claim-entity` | skill | Cross-plugin data model for claim verification — defines ClaimRecord, DeviationRecord, and ResolutionRecord schemas |
| `claim-verifier` | agent | Verify claims against a single source URL |
| `source-inspector` | agent | Open a source URL in the browser and highlight the relevant passage for user inspection |
| `/claims` | command | Manage claim verification lifecycle — submit, verify, review dashboard, inspect, resolve, and cobrowse claims |

## Architecture

```
cogni-claims/
├── .claude-plugin/               Plugin manifest
├── skills/                       2 verification skills
│   ├── claims/                   Lifecycle orchestrator (submit → verify → resolve)
│   └── claim-entity/             Cross-plugin data contract and schema definitions
├── agents/                       2 verification agents
│   ├── claim-verifier.md         Source fetch and deviation detection
│   └── source-inspector.md       Browser-based passage highlighter
├── commands/                     1 slash command
│   └── claims.md                 Entry point for all six modes
└── claims-workspace/             Local runtime state (claims.json, sources, history)
```

## Dependencies

cogni-claims is standalone — it provides a verification service that other plugins consume. No upstream dependencies are required.

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-trends | No | Trend reports submit claims for verification via the claim-entity contract |
| cogni-portfolio | No | Portfolio propositions submit claims for verification |
| cogni-consulting | No | Consulting deliverables submit claims for pre-publish verification |

## Contributing

Contributions welcome — bug fixes, new deviation types, verification improvements, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Known Limitations

| ID | Issue | Severity | Affected Skills | Workaround |
|----|-------|----------|----------------|------------|
| KI-001 | Chrome native messaging host conflict between Cowork and Claude Code | S2-major | `/claims` (cobrowse) | Toggle native host configs by renaming the `.json` file for the unused product and restarting Chrome. See [known-issues registry](https://github.com/anthropics/managed-service/blob/main/cogni-docs/references/known-issues.md) for detailed steps. |

> When both Claude Desktop (Cowork) and Claude Code are installed, their competing native messaging host configurations cause browser automation tools to silently vanish. The `/claims` cobrowse mode falls back to web fetch only — claim verification still works, but interactive source inspection is unavailable until the conflict is resolved.

## Custom development

Need a custom verification workflow, integration with your internal systems, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
