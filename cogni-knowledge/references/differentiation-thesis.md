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
Run 1: research topic A          → wiki has pages P1..P5
Run 2: research adjacent topic B → wiki-researcher reads P1..P5 from the bound wiki
                                  → finds gaps → fetches new sources only for the gaps
                                  → deposits new pages P6..P9, some [[wikilinking]] back to P1..P5
Run 3: research deeper subtopic  → reads P1..P9 → minimal new web work
                                  → deposits P10..P12, dense with cross-references
```

The wiki gets denser. The cost per research run trends down. The cross-project synthesis is visible in the markdown itself — no special query needed.

## What success looks like

In Phase 4 (alpha), we will measure:

- **Time-to-second-research.** Should drop as the wiki primes the second run.
- **Information density.** Count `[[wikilinks]]` between pages from different research projects (proxy for compounding).
- **Claims duplication.** Compare claim count vs. unique-source count. `wiki-ingest` dedupes claims at deposit.
- **User-perceived value.** Would the user pick `cogni-knowledge` over standalone `cogni-research`?

A positive alpha is what triggers Phase 6 (absorbing `cogni-research`). A negative alpha freezes `cogni-knowledge` as an experimental path and we do not migrate.
