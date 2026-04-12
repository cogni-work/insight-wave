# cogni-wiki

> **Incubating** (v0.0.x) — skills may change or be removed at any time.

**A better RAG for personal and small-team knowledge work.** Instead of re-discovering the same information every query through embedding similarity, cogni-wiki has Claude compile sources once into a persistent, interlinked markdown wiki — no vector store, no chunking heuristics, no opaque retrieval. Knowledge compounds with every ingest; answers trace to readable markdown files, not vector math. Plain files, plain backlinks, plain Unix tools.

Based on [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) and the reference implementation by [kfchou/wiki-skills](https://github.com/kfchou/wiki-skills).

## Why this exists

RAG promised to give LLMs access to your private knowledge. In practice, every query re-discovers the same ground — embeddings silently miss semantic matches, synthesis happens from scratch each time, and nothing compounds across sessions. You pay a "synthesis tax" on every question, and when an answer is wrong, tracing which chunks were retrieved and why requires reverse-engineering opaque vector math.

Karpathy's insight: what if knowledge was **compiled once at ingestion** instead of **retrieved per query**? The LLM reads your sources, writes structured summaries, cross-references them, flags contradictions — and then every future query reads pre-synthesized articles directly. The wiki gets denser with each ingest. RAG stays flat.

| Problem | RAG | cogni-wiki |
|---------|-----|------------|
| Summarising a new source | On-the-fly each query | Compiled once, filed forever |
| Cross-references | Vector similarity (ephemeral, can miss) | Explicit `[[wikilinks]]` (audited) |
| Contradictions between sources | Hidden in retrieval noise | Surfaced by `wiki-lint` at ingest |
| Stale claims | Still retrievable, silently | Flagged and reconciled |
| Debugging wrong answers | Reverse-engineer vector math | Read the markdown file |
| Token efficiency | 2K–5K chunks re-retrieved per query | Pre-synthesized; up to 95% reduction vs full-doc loading |
| Compounding over time | No — same effort per query | Yes — wiki gets denser each ingest |

**Where RAG still wins:** Scale beyond ~50K–100K tokens of compiled content; rapidly changing data (daily feeds, inventory); strict source-level attribution for legal/compliance; multi-domain enterprise with role-based access. For those cases, use RAG — or combine both (the hybrid approach [never lost a single round](references/claude-research-karparthy.md) in head-to-head benchmarks).

## What it is

**IS:** A seven-skill plugin (`wiki-setup`, `wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-update`, `wiki-resume`, `wiki-dashboard`) that operates on a simple directory layout Claude maintains automatically.

**Wiki layout** (created by `wiki-setup`):

```
<wiki-root>/
├── SCHEMA.md                 The contract — conventions, frontmatter, linking rules
├── raw/                      Your immutable source documents
├── assets/                   Attachments
├── wiki/
│   ├── index.md              One-line summary of every page
│   ├── log.md                Append-only operation log
│   ├── overview.md           Evolving synthesis
│   └── pages/                Flat, slug-named markdown pages
└── .cogni-wiki/config.json   Plugin metadata
```

**Page frontmatter** (YAML):

```yaml
---
id: constitutional-ai
title: Constitutional AI
type: concept
tags: [llms, safety, karpathy]
created: 2026-04-12
updated: 2026-04-12
sources: [../raw/bai-et-al-2022.pdf]
---
```

## What it means for you

- **A knowledge base that compounds.** Every source you add leaves the wiki denser and more interconnected than before — the opposite of RAG, where every query starts from zero.
- **No memory-based answers.** `wiki-query` physically reads the wiki before answering. If the wiki is silent, the answer says so — no hallucinated filler.
- **A self-describing artifact.** `SCHEMA.md` ships inside every wiki so the wiki remains readable even if cogni-wiki is uninstalled or replaced.
- **Portable plain markdown.** No vector store, no embeddings, no proprietary format. Open the wiki in Obsidian, VS Code, or `grep` and it still works.
- **Diff-before-write discipline.** `wiki-update` shows the change before modifying a page and requires a source citation for every new claim.

## Installation

```bash
claude plugin install cogni-wiki
```

Configure the default wiki root (optional) in `.claude/cogni-wiki.local.md`:

```markdown
---
wiki_root: ~/cogni-wikis
default_wiki: primary
---
```

## Quick start

```
/cogni-wiki:wiki-setup                   # Bootstrap a new wiki
# (drop a paper in ~/cogni-wikis/primary/raw/)
/cogni-wiki:wiki-ingest                  # Summarise + cross-link
/cogni-wiki:wiki-query "what did I learn about X?"
/cogni-wiki:wiki-lint                    # After every 5–10 ingests
/cogni-wiki:wiki-dashboard               # Visual overview
/cogni-wiki:wiki-resume                  # "Where was I?"
```

## Relationship to Claude Code auto-memory

Claude Code already has an auto-memory system at `~/.claude/projects/.../memory/` — that layer is **Claude's learning about you** (feedback, preferences, session-spanning patterns). cogni-wiki is the complementary primitive: **your learning about your domain** — explicitly curated, portable across projects, queryable. No duplication; different intent.

## Credits

- **Andrej Karpathy** — [LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). The pattern this plugin implements.
- **kfchou/wiki-skills** — [reference Claude Code implementation](https://github.com/kfchou/wiki-skills). The five-skill shape (`wiki-init`, `wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-update`) that inspired this plugin's layout. cogni-wiki adds `wiki-resume` and `wiki-dashboard` to match cogni-* ecosystem conventions.

## License

AGPL-3.0-only — see `LICENSE`.

---

*Built by [Stephan de Haas](mailto:stephan@cogni-work.ai) as part of the [insight-wave](../) monorepo.*
