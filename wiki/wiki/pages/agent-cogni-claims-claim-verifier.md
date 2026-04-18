---
id: agent-cogni-claims-claim-verifier
title: "cogni-claims:claim-verifier (agent)"
type: entity
tags: [cogni-claims, claims, agent, sonnet, web-fetch]
created: 2026-04-17
updated: 2026-04-18
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-claims/agents/claim-verifier.md
status: stable
related: [plugin-cogni-claims, concept-agent-model-strategy, concept-claim-lifecycle, concept-claims-propagation, concept-quality-gates, agent-cogni-claims-source-inspector, concept-script-output-format]
---

> A sonnet-tier verification agent inside [[plugin-cogni-claims]] — see [[concept-agent-model-strategy]] for tier rationale. Pairs with [[agent-cogni-claims-source-inspector]] for the cobrowse-recovery path.

The single-source verifier: fetch one URL via WebFetch, verify one or more claims against the fetched content, and return a deviation report as a strict JSON object.

## Key takeaways

- **One URL per dispatch.** Claims are grouped by source URL upstream; each instance of this agent receives one `source_url` and an array of `{id, statement}` claims to check against it. Grouping minimises fetches and is part of why the agent exists separately from the orchestrating skill.
- **WebFetch is the only automated path.** No browser fallback inside the agent. Any of `403`, timeout, empty body, or paywall-style content (short body with `login`/`subscribe` keywords) routes the claim to status `source_unavailable`. Sources that need browser access are recovered interactively via [[agent-cogni-claims-source-inspector]] / `/claims cobrowse` — see [[plugin-cogni-claims]] for the cobrowse hand-off.
- **Source content is cached** to `cogni-claims/sources/{url-hash}.json`, where the hash is `shasum -a 256` of the URL truncated to 16 chars. The cached record carries `url`, `fetched_at`, `fetch_method` (`"webfetch"`), `status`, `content`, and `error`.
- **Five dimensions → five deviation types.** Accuracy → `misquotation`, Inference → `unsupported_conclusion`, Completeness → `selective_omission`, Currency → `data_staleness`, Agreement → `source_contradiction`. Severity is one of `low | medium | high | critical`.
- **Source silent ≠ source supportive.** A source that does not address the claim's subject matter cannot support a claim about it — this is explicitly recorded as `unsupported_conclusion` at `medium` severity, not silently passed through. This is the load-bearing rule that prevents quiet false-positive verifications.
- **Conservative bias is the quality stance.** When a comparison is genuinely ambiguous, the agent does not flag — see [[concept-quality-gates]] for the broader "false positives erode trust" principle. Every finding must include a verbatim source excerpt; explanations use hedged language (`appears to`, `suggests`, `may indicate`) rather than definitive assertions.
- **Strict output contract.** A single JSON object on stdout — no markdown fences, no surrounding prose, no explanation outside the JSON — see [[concept-script-output-format]]. Each result carries `claim_id`, `status`, `source_excerpt`, `deviations[]`, and `verification_notes`.

## Inputs

The agent receives three named parameters in its task prompt:

| Parameter | Purpose |
|---|---|
| `working_dir` | Path to the project directory containing `cogni-claims/`; used to locate the sources cache and registry |
| `source_url` | The single URL to fetch and verify against |
| `claims` | Array of `{id, statement}` objects to check against this URL |

## Verification process

1. **Fetch source.** WebFetch the URL. On any failure, mark every claim against this source as `source_unavailable` and write the cache file with the failure reason.
2. **Per claim, locate the relevant passage.** If the source is silent on the claim's subject, record `unsupported_conclusion` (medium) and explain the silence — do not invent supportive context.
3. **Compare along the five dimensions.** Multiple deviations per claim are recorded, not just the first.
4. **Assess severity.** `low` (minor imprecision, meaning preserved) → `critical` (complete contradiction or fabrication).
5. **Extract evidence.** Verbatim 1–3-sentence excerpt from the source for every finding.
6. **Write explanation.** Hedged, not definitive.

## Status outcomes per claim

- `verified` — comparison found no deviation
- `deviated` — at least one deviation recorded with evidence
- `source_unavailable` — fetch failed; recovery via cobrowse is the next step

These flow into [[concept-claim-lifecycle]] as the input to user resolution.

## Pipeline position

This agent is the verifier in the larger [[concept-claims-propagation]] flow: upstream plugins (`cogni-trends`, `cogni-portfolio`, `cogni-research`, `cogni-consulting`) submit claims; the [[plugin-cogni-claims]] orchestrator dispatches one of these agents per unique source URL; deviations surface to the user for resolution; and resolutions cascade back to the originating entities via the entity provenance chain.

## Edge cases the agent handles

- **Very long source** — focus on passages containing claim keywords; do not attempt to read everything.
- **Different language** — note in `verification_notes`; attempt verification if the language is intelligible.
- **Vague claim** — set status to `verified` with a note that the claim is too general for precise verification rather than over-flagging.

## Sources

- [`cogni-claims/agents/claim-verifier.md`](https://github.com/cogni-work/insight-wave/blob/main/cogni-claims/agents/claim-verifier.md) — agent definition (frontmatter + system prompt)
