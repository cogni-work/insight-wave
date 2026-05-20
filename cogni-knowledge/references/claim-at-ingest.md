# Claims at ingest, not at draft

## What changed

| | v0.0.x | v0.1.0 |
|---|---|---|
| When are claims extracted? | After the draft is written, from the draft itself | At ingest time, from each fetched source body |
| Input to claim-extractor | `output/draft-vN.md` | `<wiki>/sources/<slug>.md` body |
| Where do claims live? | `02-sources/data/*-claims.json` in the cogni-research project | `pre_extracted_claims:` frontmatter list on each wiki source page |
| What does verify do? | Re-fetch each cited URL, compare claim to source body | Look up the cited wiki page, read its pre-extracted claims, score alignment |
| Cost of verify | 1 WebFetch per cited URL (~20–30 min for a 5K draft) | Zero network calls (~< 5 min for a 5K draft) |

## Why this is structurally better

Three properties fall out of moving extraction upstream:

1. **Verification is free.** Once a claim has been extracted from a source body and stored on the wiki page, verifying the draft is a string-match / paraphrase-detect operation. No network. No new model call to re-read the source. cogni-claims' 20–30 minute verify wall-clock on a 5K draft becomes a sub-5-minute pass.

2. **Unsupported draft assertions surface immediately.** A draft sentence that cites `[[some-wiki-page]]` but doesn't paraphrase any of the page's pre-extracted claims is flagged as `unsupported` without needing to re-read the source. The writer can no longer make up a fact that "the source said X" when the source's pre-extracted claims don't include X.

3. **The wiki becomes a claim graph.** Every source page carries its own claims. A future reader (or a future query agent) can ask "which pages assert X about Y" without re-reading source bodies. The wiki gains a queryable factual layer without a separate database.

## The trade-off

Extracting claims at ingest time means **every source the user ingests pays the claim-extraction cost upfront** — even if the user never writes a draft that cites it. v0.0.x deferred that cost to draft-time, paying only for what was cited.

For wiki-first research where the wiki is the substrate (every source likely gets cited eventually), the upfront cost amortizes. For one-shot research (write a report, throw it away), the upfront cost is waste — which is why one-shot users belong in `cogni-research` directly, not in `cogni-knowledge`.

## Claim shape on the wiki page

```yaml
---
type: source
slug: eu-ai-act-article-6
title: "Article 6 — Classification rules for high-risk AI systems"
sources: ["https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689"]
pre_extracted_claims:
  - id: clm-001
    text: "High-risk AI systems are listed in Annex III"
    excerpt_quote: "AI systems referred to in Annex III shall be considered high-risk"
    excerpt_position: 1432
    sub_question_refs: [sq-01]
    extracted_at: "2026-05-20T..."
  - id: clm-002
    text: "Article 6(3) creates an exception for AI systems that do not pose significant risk"
    excerpt_quote: "...where it does not pose a significant risk of harm to the health, safety or fundamental rights..."
    excerpt_position: 2891
    sub_question_refs: [sq-01, sq-03]
    extracted_at: "2026-05-20T..."
---

# Article 6 — Classification rules for high-risk AI systems

[source body here, with the excerpt positions referenced above]
```

`excerpt_position` is a Python `str` index (Unicode code-point offset, what `str.find` returns) into the body — NOT a UTF-8 byte offset. Used by `wiki-verifier` to render context around the excerpt when surfacing a deviation. Computed once at ingest and frozen; readers in other languages that lack native Unicode-aware indexing must convert from byte to code-point before slicing.

## Verify scoring

`wiki-verifier` reads each cited statement in the draft and scores against the pre-extracted claims on the cited page:

| Verdict | Definition |
|---------|------------|
| `verbatim` | Draft sentence is a near-exact paraphrase of one pre-extracted claim's `text` or `excerpt_quote` |
| `paraphrase` | Draft sentence makes the same factual claim, expressed differently |
| `unsupported` | Draft sentence cites the page but no pre-extracted claim on that page supports it |

Only `unsupported` triggers the revisor loop. `paraphrase` is the desired state; `verbatim` is acceptable but flagged in the dashboard so the operator can see copy-paste vs. synthesis ratios.

## Migration concern

v0.0.x knowledge bases have research project entries in `binding.research_projects[]` that point at cogni-research project dirs (with `02-sources/data/*-claims.json` claims). These remain readable — `knowledge-resume` and `knowledge-dashboard` surface them under a "legacy projects" section. No automatic migration; the user can re-ingest the underlying source URLs through the inverted pipeline if they want the legacy projects' claims on the wiki.
