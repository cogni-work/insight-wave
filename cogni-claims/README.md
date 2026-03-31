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

1. **Submit** claims with their source URLs — individually or batch-imported from markdown → `cogni-claims/claims.json` → consulting-deliver, synthesize
2. **Verify** them by fetching each source and detecting deviations (misquotation, unsupported conclusions, selective omission, data staleness, source contradiction)
3. **Review** a dashboard showing all claims grouped by status, with inline deviation summaries and severity indicators
4. **Inspect** flagged claims by opening the source in your browser with the relevant passage highlighted for side-by-side comparison
5. **Resolve** each deviation — correct the claim, dispute the finding, find an alternative source, discard, or accept as-is

## What it means for you

If you ship research, reports, or any content that leans on sourced claims, this is your safety net before publish.

- **Catch errors before they reach your audience.** Each claim is fetched against its cited source and checked for 5 deviation types — misquotation, unsupported conclusions, selective omission, data staleness, and source contradiction.
- **Stay in control.** Deviation detection is LLM-based. Findings are assessments for you to review, not verdicts — you decide whether to correct, dispute, or accept each one.
- **Keep a paper trail.** Every claim, verification result, and resolution decision is stored as structured JSON — a complete audit trail from assertion to source to decision.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

## Quick start

```
/claims submit --batch        # submit claims from a markdown file with citations
/claims verify                # verify all unverified claims against their sources
/claims dashboard             # see what needs attention
/claims inspect <claim-id>    # open the source in your browser to compare
/claims resolve <claim-id>    # decide what to do about a deviation
```

Or just describe what you want in natural language — the plugin figures out the right mode:

- "verify the claims in my research report"
- "what's the status of my claims?"
- "show me what the source actually says for that quantum computing claim"
- "let's fix the deviated claims one by one"

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
| `ClaimRecord` | claim_id, claim_text, source_url, status | A factual assertion with its cited source. Status: `unverified` → `verified` / `deviated` / `source_unavailable` |
| `DeviationRecord` | deviation_type, severity, evidence | A discrepancy found during verification. Types: misquotation, unsupported_conclusion, selective_omission, data_staleness, source_contradiction |
| `ResolutionRecord` | resolution_type, new_claim_text | How a deviation was resolved. Types: corrected, disputed, alternative_source, discarded, accepted_as_is |

See [skills/claim-entity/references/schema.md](skills/claim-entity/references/schema.md) for the full schema.

## How it works

Claims are stored in your project's `cogni-claims/` directory as JSON. When you verify, the plugin dispatches a **claim-verifier** agent per unique source URL — each agent fetches the page once and checks all claims referencing it. For deviated claims, the **source-inspector** agent can open the source in Chrome and highlight the relevant passage so you can see the discrepancy in context.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `claims` | skill | Main orchestrator — handles all five modes (submit, verify, dashboard, inspect, resolve) |
| `claim-entity` | skill | Cross-plugin data contract — defines ClaimRecord, DeviationRecord, and ResolutionRecord schemas |
| `claim-verifier` | agent | Fetches a source URL and verifies all claims referencing it |
| `source-inspector` | agent | Opens a source in the browser and highlights the relevant passage |
| `/claims` | command | Slash command entry point for all modes |

## Architecture

```
cogni-claims/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       2 verification skills
│   ├── claims/
│   └── claim-entity/
│       └── references/
│           └── schema.md         Entity schema definitions
├── agents/                       2 verification agents
│   ├── claim-verifier.md
│   └── source-inspector.md
└── commands/                     1 slash command
    └── claims.md
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-research | No | Research reports submit claims for verification via claim-entity contract |
| cogni-trends | No | Trend reports submit claims for verification |
| cogni-portfolio | No | Portfolio propositions submit claims for verification |
| cogni-sales | No | Sales pitches submit claims for verification |

cogni-claims is standalone — it provides a verification service that other plugins consume. No upstream dependencies are required.

## Contributing

Contributions welcome — bug fixes, new deviation types, verification improvements, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need a custom verification workflow, integration with your internal systems, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
