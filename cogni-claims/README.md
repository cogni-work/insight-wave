# cogni-claims

> **Preview** (v0.10) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop recommended)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

A systematic claim-verification workflow for the insight-wave ecosystem — other plugins generate sourced content; this one checks whether the cited sources actually say what is claimed.

## Why this exists

LLMs cite sources confidently, but the citations are often wrong — and the gap between "cited" and "correct" is large enough to cause real harm.

| Problem | What happens | Impact |
|---------|--------------|--------|
| Citations are hallucinated | A claim points to a source that never made it ([14–95% of LLM citations, depending on domain](https://arxiv.org/html/2602.06718)) | Readers trust a number that no source supports |
| Conclusions overshoot the source | The claim asserts more than the cited page says ([>60% of AI-search answers cite inaccurately](https://www.cjr.org/tow_center/we-compared-eight-ai-search-engines-theyre-all-bad-at-citing-news.php)) | Reports overstate evidence and lose credibility on review |
| Bibliographic details are wrong | Invalid DOIs, broken URLs, fabricated references ([45.4% of GPT-4o citations contain errors](https://mental.jmir.org/2025/1/e80371)) | A fact-checker can't trace the claim back to anything real |
| Errors reach high-stakes work | Unverified citations ship into published, sometimes legal, documents ([lawyers sanctioned over AI-fabricated case citations](https://law.justia.com/cases/federal/district-courts/new-york/nysdce/1:2022cv01461/575354/54/)) | Professional and legal consequences land after publish, when it's too late |

Every claim above was itself verified against its source using this plugin. "Cited" does not mean "correct."

## What it is

The citation-integrity layer for insight-wave: a verification engine that treats a cited claim and its source as two things that must agree, and the disagreement as the entity worth tracking. It is cross-plugin by design — claims submitted from anywhere in the ecosystem flow through the shared `claim-entity` data contract — and human-in-the-loop by principle, since LLM-detected discrepancies are assessments a person must adjudicate, never auto-applied corrections.

## What it does

1. **Submit** claims with their source URLs — individually or batch-imported from markdown → `cogni-claims/claims.json` → consulting-deliver
2. **Verify** them by fetching each source and detecting deviations (misquotation, unsupported conclusions, selective omission, data staleness, source contradiction)
3. **Review** a dashboard showing all claims grouped by status, with inline deviation summaries and severity indicators
4. **Inspect** flagged claims by opening the source in your browser with the relevant passage highlighted for side-by-side comparison
5. **Resolve** each deviation — correct the claim, dispute the finding, find an alternative source, discard, or accept as-is
6. **Cobrowse** sources that couldn't be reached automatically — you navigate logins, cookie banners, and dynamic content while Claude reads and verifies in real-time

## What it means for you

If you ship research, reports, or any content that leans on sourced claims, this is your safety net before publish.

- **Catch errors before your audience does.** Each claim is fetched against its cited source and checked for 5 deviation types, so misquotes and overshooting conclusions surface while you can still fix them.
- **Stay in control of every fix.** Detection is LLM-based, but 100% of findings route through an explicit human decision — correct, dispute, or accept. The tool flags; you decide.
- **Reconstruct the evidence chain in seconds.** Every claim, finding, and decision persists as structured JSON with timestamps and source excerpts — so an audit question a quarter later resolves in one `/claims inspect` call instead of half a day digging through old drafts.

## Known Limitations

> **Chrome native messaging host conflict between Cowork and Claude Code** (S2-major) — Browser-based claim source co-browsing unavailable when Claude Code's native host is active — claim verification falls back to web fetch only. Workaround: Toggle native messaging host configs by renaming the .json file for the unused product and restarting Chrome. See [Known Issues Registry](../docs/known-issues.md#ki-001) for details.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/claims submit --batch        # batch-import claims from a markdown file with citations
/claims verify                # verify all unverified claims against their sources
/claims dashboard             # review claim statuses and deviation summaries
/claims inspect <claim-id>    # open the source in your browser with the passage highlighted
/claims resolve <claim-id>    # decide what to do about a deviation
/claims cobrowse              # interactively recover sources that automated verification couldn't reach
```

Aliases: `/claim`, `/verify-claims`

Or just describe what you want in natural language — the plugin figures out the right mode:

- "verify the claims in my research report"
- "what's the status of my claims?"
- "show me what the source actually says for that quantum computing claim"
- "let's fix the deviated claims one by one"
- "let's look at those unavailable sources together"

## Try it

After installing, point it at a draft that carries cited claims and verify them in one pass:

> Run `/claims submit --batch report.md` then `/claims verify`

`submit` imports each `[Source: ...](URL)` citation as a claim; `verify` dispatches one fetcher per unique URL and checks every claim against what its source actually says. Then review the result:

> Run `/claims dashboard`

You'll see each claim grouped by status, with the deviation called out inline, e.g.:

```
cogni-claims — 7 verified, 2 deviated, 1 source_unavailable
  clm-3  deviated (high) — unsupported_conclusion
         claim: "adoption doubled in 2024"
         source appears to say: "adoption rose ~15% in 2024"
  clm-8  source_unavailable — WebFetch 403 (try /claims cobrowse)
```

Then resolve the flagged ones — correct the claim, dispute the finding, or accept it:

> Run `/claims resolve clm-3`

Each finding shows the source excerpt inline, so you can judge for yourself whether the deviation is real before acting on it. Everything lands in your project's `cogni-claims/` directory, where the registry, cached sources, and per-claim history give you a durable audit trail you can re-run or hand to a reviewer:

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

The lifecycle runs `submit → verify → review → inspect → resolve`, with `cobrowse` as a recovery branch. The ordering is deliberate: verification can only assess a claim once the claim and its source URL are both on record, and a human can only resolve a finding once verification has produced one with its evidence attached.

Claims persist in your project's `cogni-claims/` directory as JSON — one `ClaimRecord` per assertion, with any `DeviationRecord` and `ResolutionRecord` linked to it. Keeping the records on disk rather than in chat history is what lets the evidence chain survive across sessions.

On verify, the plugin groups claims by source URL and dispatches one **claim-verifier** agent per unique URL. Grouping matters: a page is fetched once no matter how many claims cite it, so a report leaning heavily on a single source doesn't trigger redundant fetches. Each agent reads the page and scores its claims against five deviation types, returning findings as JSON. Detection is intentionally conservative — when a comparison is genuinely ambiguous, the agent does not flag, because false positives erode the trust the tool depends on.

Fetching uses WebFetch as the sole automated method. If WebFetch is blocked (403, paywall, anti-bot), the claim is marked `source_unavailable` rather than silently assumed correct — unverifiable is not verified. Those sources are recovered through `/claims cobrowse`, where you dismiss cookie banners and log in while Claude reads via the browser. For any deviated claim, the **source-inspector** agent opens the page in Chrome and highlights the passage so you can judge the discrepancy in context before deciding.

## Components

| Component | Type | Description |
|-----------|------|-------------|
| `claims` | Skill | Manage claim verification lifecycle — submit, verify, review dashboard, inspect, resolve, and cobrowse claims |
| `claim-entity` | Skill | Cross-plugin data model for claim verification — defines ClaimRecord, DeviationRecord, and ResolutionRecord schemas |
| `claim-verifier` | Agent | Verify claims against a single source URL and return deviation analysis as JSON |
| `source-inspector` | Agent | Fetch a source URL via claude-in-chrome, locate the relevant passage, and present evidence to the user |
| `/claims` | Command | Manage claim verification lifecycle — submit, verify, review dashboard, inspect, resolve, and cobrowse claims |

## Architecture

```
cogni-claims/
├── .claude-plugin/plugin.json    Plugin manifest
├── README.md                     Plugin documentation
├── CLAUDE.md                     Developer guide
├── CONTRIBUTING.md               Contribution guidelines
├── LICENSE                       AGPL-3.0
├── skills/                       2 verification skills
│   ├── claims/                   Lifecycle orchestrator (submit → verify → resolve)
│   └── claim-entity/             Cross-plugin data contract and schema definitions
├── agents/                       2 verification agents
│   ├── claim-verifier.md         Source fetch and deviation detection
│   └── source-inspector.md       Browser-based passage highlighter
└── commands/                     1 slash command
    └── claims.md                 Entry point for all six modes
```

## Dependencies

cogni-claims is standalone — it provides a verification service that other plugins consume. No upstream dependencies are required.

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-trends | No | Trend reports submit claims for verification via the claim-entity contract |
| cogni-portfolio | No | Portfolio propositions submit claims for verification |
| cogni-knowledge | No | `knowledge-refresh --resweep` re-verifies cited claims against live source URLs |
| cogni-consult | No | Deliverables submit claims for pre-publish verification |

## Contributing

Contributions welcome — bug fixes, new deviation types, verification improvements, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need a custom verification workflow, a new deviation type for your domain, or integration with your internal review systems? [cogni-work.ai](https://cogni-work.ai) builds and maintains bespoke Claude Code automation for teams — or reach out directly at [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
