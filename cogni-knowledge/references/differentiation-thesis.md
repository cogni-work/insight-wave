# Differentiation thesis

Every shipped deep-research tool today produces a document and loses the underlying knowledge to chat history.

- OpenAI Deep Research → a report, then nothing.
- Perplexity Spaces → a thread, then nothing persistent that the next thread reads.
- GPT Researcher → a report file, no cross-project compounding.
- Anthropic's research feature → conversational; the next session starts fresh.

The reason this happens is structural: the LLM's knowledge of "what I just researched" lives in the conversation context, and the conversation context dies when the session ends. The artifacts shipped to the user (the report) are *outputs*, not *substrate* — they are not designed to be read back into a future research run, and the tools do not provide an automatic pathway for that to happen.

**cogni-knowledge inverts the posture.** A research run is not a one-shot output — it is a *contribution* to a persistent, queryable knowledge base. The base is a `cogni-wiki`: interlinked markdown, compiled once at ingest, with explicit `[[wikilinks]]` and YAML frontmatter that traces every page to a source. The next research run reads the base before going to the web.

## Why a wiki, not a vector store

A vector store would let the same compounding happen in principle, but in practice it loses three properties that matter for serious research:

1. **Cross-references are explicit, not statistical.** `[[wikilinks]]` say "page A is genuinely about page B"; cosine similarity can only say "page A's embedding is close to B's embedding" — a weaker, frequently-wrong signal that misses both real connections (different wording) and pretends connections that aren't there (similar wording, different meaning).
2. **Contradictions surface at ingest.** When `wiki-ingest` writes page B and page A already says something incompatible, the conflict is visible at file-write time. A vector store stores both and lets the retrieval layer hope for the best.

   This pillar is defended at three points in the pipeline, all pure-observability, zero-network, fail-soft. The literal ingest-time check (approach (b), #431, v0.1.61) ships as the `source-contradictor` agent at `knowledge-ingest` Step 4.6: when new sources land, their freshly-extracted claims are scored against the claims already on the related question group's pages (prior-run sources + the question node), surfacing "this new source disagrees with what the base already holds" before the source feeds any draft. It complements the synthesis-write-time layer (approach (a), #335) — the `wiki-contradictor` agent at `knowledge-finalize` Step 10.6, which scores a just-deposited synthesis against its cited pages' claims. The third layer — synthesis-vs-prior-syntheses (approach (c), #444, v0.1.62) — ships as a SECOND comparison pass inside that same `wiki-contradictor` agent (no new agent): off the same sentence-split of the new synthesis body it scores the new synthesis's assertive sentences against each prior synthesis's assertive sentences. Syntheses carry no claim block, so it uses an assertive-sentence comparison surface (`conflicting_claim_id: null`) rather than the cheap claim-vs-claim one (a) and (b) share — surfacing "this new synthesis forks from an earlier synthesis on the same base." With all three surfaces shipped, #431 closes.
3. **Debugging is reading.** When a query produces a wrong answer, the user reads markdown files to figure out why. With a vector store, the user has to reverse-engineer chunk retrieval scores.

See `cogni-wiki/README.md` §"Why this exists" for the longer form.

## Why this plugin exists separately from cogni-wiki

cogni-wiki is a **general-purpose** knowledge engine. It ingests anything: PDFs, interview notes, meeting transcripts, papers, web pages. The Karpathy pattern is domain-neutral.

cogni-knowledge is **opinionated about wiki-first research**. Specifically:

- It assumes there is a *bound* knowledge base — one wiki per topic area, recorded in a `binding.json` manifest.
- It assumes every research run on that area deposits into that wiki.
- It records each deposit's lineage so future runs can avoid circular evidence (Phase 2 cycle-guard).
- It does NOT support web-only one-shot mode — those users belong in `cogni-research` directly.

The opinionation is the value. cogni-wiki can ingest research, but it does not enforce "every research run goes here." cogni-knowledge does.

## The compounding loop

```
Run 1: research topic A          → ingest deposits source pages S1..S5
                                  → distill (Phase 4.5) deposits concept/entity pages C1..C3,
                                    each [[backlinking]] the sources whose claims it distils
Run 2: research adjacent topic B → curate reads the bound wiki, narrows web work to gaps (#309)
                                  → ingest deposits S6..S9
                                  → distill ENRICHES C1..C3 (new claims appended, source
                                    backlinks unioned, duplicate facts merged) and adds C4..C5
Run 3: research deeper subtopic  → reads S1..S9 + C1..C5 → minimal new web work
                                  → distill deposits/enriches a concept web dense with cross-references
```

The concept/entity web is the part that **compounds**: the same recurring concept gets one page that successive runs deepen, rather than N disconnected source extracts. The wiki gets denser, the cost per research run trends down (curate's read-before-web, #309), and the cross-project synthesis is visible in the concept pages' `distilled_claims:` + `[[backlinks]]` — no special query needed.

## What success looks like

In Phase 4 (alpha), we will measure:

- **Time-to-second-research.** Should drop as the wiki primes the second run.
- **Information density.** Count `[[wikilinks]]` between pages from different research projects (proxy for compounding).
- **Claims duplication.** Compare claim count vs. unique-source count. **Phase 4.5 `knowledge-distill` dedupes claims at deposit** (v0.1.13, #336): the distillation pass attaches each run's source claims to `type: concept` / `type: entity` pages, and `concept-store.py` merges duplicate facts deterministically (`norm_key` exact match, then a symmetric weighted-Jaccard ≥ 0.85, fail-safe to keep-both) — one fact, one claim line, multiple source `[[backlinks]]`. The measurable ratio is `distill-manifest.json::claims_deduped_total / claims_attached_total` (surfaced by `pipeline-summary.py`). URL-level dedup (`candidate-store.py`) still collapses same-URL candidates upstream; claim-level dedup is the distill layer's job. (Before v0.1.13 this metric was structurally unmet — the deposited base was a source+synthesis citation store with no claim-level dedup.)
- **User-perceived value.** Would the user pick `cogni-knowledge` over standalone `cogni-research`?

A positive alpha is what triggers Phase 6 (absorbing `cogni-research`). A negative alpha freezes `cogni-knowledge` as an experimental path and we do not migrate.
