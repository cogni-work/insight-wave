# The Karpathy LLM-Wiki Pattern

This file is the single source of truth for cogni-wiki's conceptual model. All skills cite it to avoid re-explaining the pattern in every `SKILL.md`.

## Origin

Andrej Karpathy, [LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f):

> "You never (or rarely) write the wiki yourself — the LLM writes and maintains all of it. The LLM does all the grunt work — the summarizing, cross-referencing, filing, and bookkeeping that makes a knowledge base actually useful over time."

Humans abandon personal wikis because maintenance is tedious — rewriting summaries, keeping cross-references current, spotting contradictions, deleting stale claims. LLMs are unusually good at exactly that bookkeeping. The wiki becomes a **compounding knowledge base**: every source added and every question asked leaves the wiki richer than before.

## The Three Layers

1. **Raw sources** (`raw/`) — immutable. Papers, articles, URLs, pasted transcripts, images, data files. The user curates this layer; Claude never rewrites it.
2. **The wiki** (`wiki/`) — LLM-maintained. Summaries, entity pages, concept pages, decisions, learnings — all interlinked via `[[wikilinks]]`, all with YAML frontmatter, all slug-named in a flat `pages/` directory.
3. **The schema** (`SCHEMA.md`) — the contract. Directory layout, frontmatter conventions, linking rules, log format. Copied into every wiki at setup time so the wiki is self-describing even if the plugin is uninstalled.

## Core Operations

| Operation | Skill | What Claude does |
|-----------|-------|-----------------|
| Ingest | `wiki-ingest` | Read a source → surface key takeaways → write a new page with frontmatter → update `index.md` → append to `log.md` → scan existing pages for relevant cross-references → add bidirectional `[[links]]` |
| Query | `wiki-query` | Always read `wiki/index.md` first, then relevant `wiki/pages/*.md`, **never answer from memory** → synthesize with `[[citations]]` → offer to file the answer back as a new page |
| Lint | `wiki-lint` | Audit for contradictions, stale dates, orphaned pages (no inbound links), broken `[[links]]`, missing frontmatter → write a severity-tiered report to `wiki/pages/lint-YYYY-MM-DD.md` → append to `log.md` |
| Update | `wiki-update` | Revise a page when knowledge changes → show diff before writing → require a source citation for new claims → sweep related pages for now-stale statements → append to `log.md` |

## Two Control Files

- **`wiki/index.md`** — the content-oriented catalog. One line per page: `- [[page-slug]] — one-sentence summary.` Organized by category. Claude consults this **before** drilling into specific pages so it knows what's already known.
- **`wiki/log.md`** — append-only chronological record. Format: `## [YYYY-MM-DD] {ingest|query|lint|update} | short note`. Never rewritten. Gives Claude (and the user) a temporal trail of what the wiki has learned.

## Forward → Reverse Link Contract

The bidirectional `[[wikilink]]` invariant is codified in each wiki's `SCHEMA.md` under "Forward → reverse link contract". Every rule there carries a stable `rule_id` (`R1_bidirectional_wikilink`, `R2_synthesis_wiki_source`, `R3_lint_report`) that `backlink_audit.py` propagates onto every candidate it proposes and `wiki-lint`'s `reverse_link_missing` check enforces. This is what makes the wiki portable: a human editing the wiki without Claude can follow the contract by hand, and the script and the schema can never silently drift apart because each candidate is tagged with the rule it claims to satisfy.

## Why This Beats RAG

Karpathy's argument: RAG rediscovers the same information every query. A wiki **accumulates**. Each ingest distills raw material into reusable form; each query reinforces or extends that form. After N ingests the wiki is a dense, structured artifact that costs pennies to read end-to-end — no vector store, no embeddings, no chunking heuristics. Plain markdown, plain backlinks, plain Unix tools.

Three structural advantages over RAG:

1. **Retrieval reliability.** RAG depends on embedding similarity, which silently misses semantic matches ("cancellation policy" won't match "ending your subscription"). The wiki loads pre-synthesized articles directly — if the content exists, the LLM sees it.
2. **Synthesis cost.** RAG pays a synthesis tax on every query, reconciling disparate fragments each time. The wiki pays that cost once at ingestion.
3. **Debuggability.** When RAG gives a wrong answer, tracing which chunks were retrieved requires reverse-engineering vector math. With the wiki, every claim traces to a readable markdown file.

**Honest scope.** The wiki's sweet spot is bounded knowledge bases under ~50K–100K tokens of compiled content. RAG remains the correct choice for large-scale corpora (100K+ documents), rapidly changing data, strict source-level attribution (legal/compliance), and multi-domain enterprise with RBAC. The strongest evidence from community benchmarks: the combined wiki+RAG approach outperformed either method alone.

## What This Plugin Adds on Top

- **Two extra skills** — `wiki-resume` (status dashboard) and `wiki-dashboard` (self-contained HTML overview) — beyond the reference five, matching cogni-* conventions where every plugin surfaces its own state.
- **Workspace-local convention** — wikis live under `cogni-wiki/{slug}/` in the current workspace, matching all other cogni-* plugins. Use `--wiki-root` to override.
- **Integration hooks (deferred)** — future versions will let upstream insight-wave plugins (cogni-research, cogni-narrative, cogni-consulting) deposit into and read from the wiki. MVP is standalone.

## Non-goals

- No vector search. No embeddings. No external index. The wiki is plain markdown files read top-to-bottom.
- No auto-federation across wikis. One wiki = one directory.
- No replacement for Claude Code's auto-memory system — that layer is for *Claude's learning about the user*. This plugin is for *the user's learning about their domain*.

## Reference Implementation

[kfchou/wiki-skills](https://github.com/kfchou/wiki-skills) is the closest prior art in the Claude Code ecosystem. cogni-wiki diverges only in (a) cogni-* naming conventions, (b) two extra skills for status/dashboard, and (c) workspace-relative wiki root matching cogni-* conventions.
