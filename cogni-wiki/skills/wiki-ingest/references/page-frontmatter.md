# Page Frontmatter Schema

Every file in the per-type page dirs (except `lint-YYYY-MM-DD.md` reports) begins with this YAML frontmatter block.

## Full schema

```yaml
---
id: <slug>                            # REQUIRED. Must equal the filename without .md
title: <human-readable title>         # REQUIRED. Shown in index and backlinks
type: <one of allowed types>          # REQUIRED. See "Types" below
tags: [<tag1>, <tag2>, ...]           # Optional. Short, lowercase, kebab-case
created: YYYY-MM-DD                   # REQUIRED. Set at page creation, never changed
updated: YYYY-MM-DD                   # REQUIRED. Set at every edit
sources:                              # Optional but strongly encouraged
  - ../raw/<filename>                 # Relative path from wiki/<type>/ to raw/ file (the same `../raw/` form works from every per-type dir)
  - https://<url>                     # Or a stable external URL
  - wiki://<other-page-slug>          # Or a wiki-internal reference (synthesis pages)
publisher_url: https://<url>          # Optional. Canonical URL at the publisher
related:                              # Optional. Curated cross-reference list
  - <other-page-slug>
status: <optional>                    # Optional. e.g. "draft", "stable", "stale"
---
```

## Field rules

### `id` (required)

- Must match the filename stem exactly: a page at `wiki/<type>/llm-wiki-pattern.md` has `id: llm-wiki-pattern`
- Lowercase, alphanumeric, hyphens only
- Never change after creation — `wiki-update` and `wiki-lint` both treat `id` as the immutable handle for cross-references

### `title` (required)

- Human-readable, case-sensitive, may contain punctuation
- Changing the title is allowed; changing the `id` is not

### `type` (required)

One of:

| Type | When to use |
|------|-------------|
| `concept` | Framework, model, theory, idea — something you can describe without naming specific instances |
| `entity` | Specific person, organization, product, project, place |
| `summary` | A condensed version of one raw source, paper, or article |
| `decision` | A choice made and the reasoning — includes the alternatives considered |
| `interview` | A captured conversation: customer / expert / user / stakeholder. Use the `customer-call` tag to mark sales / customer-success calls, the most common variant |
| `meeting` | Internal or external meeting notes — agenda, discussion, decisions made, action items |
| `learning` | A generalized takeaway drawn from multiple sources or experience (typically authored by hand or filed during ingest). Use the `retro` tag for retrospectives |
| `synthesis` | An LLM-synthesised answer derived from other wiki pages — filed back by `wiki-query --file-back yes`. Sources are `wiki://<slug>` references to the pages it draws from, not raw files. Distinguishes wiki→wiki derivation from raw-source learnings |
| `note` | A loose observation that hasn't crystallized — often promoted later to `concept` or `learning` |
| `source` | An ingested source body (raw extract + frontmatter). Typically written by `cogni-knowledge:knowledge-ingest` as the substrate for downstream writers; generic enough that any external ingestor can produce them. Per-type semantics (e.g. `pre_extracted_claims:`) are owned by the ingestor — cogni-wiki only recognises the type and routes the page to `wiki/sources/` |

Pick the most specific type. `wiki-lint` will warn when a page's body has drifted far from its declared type.

`customer-call` and `retro` are deliberately **not** distinct types — they are scaffold variants distinguished by tag. This keeps the enum small while still giving `wiki-query` and the dashboard a way to slice by use case (`tag:customer-call`, `tag:retro`).

### Type → body template mapping

`wiki-ingest` Step 4 dispatches each `type` to a body scaffold under `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/templates/`:

| Type | Template file |
|------|---------------|
| `summary`, `concept`, `entity` | `default.md` |
| `interview` | `interview.md` (or `customer-call.md` when tagged `customer-call`) |
| `meeting` | `meeting.md` |
| `decision` | `decision.md` |
| `learning` | `learning.md` (or `retro.md` when tagged `retro`) |
| `synthesis` | n/a — `wiki-query --file-back yes` writes the body directly |
| `note` | n/a — pastes are short by design; default scaffold optional |
| `source` | n/a — body written by the ingestor (cogni-knowledge:knowledge-ingest owns the convention) |

See `./templates/README.md` for authoring conventions and per-template required `[[wikilinks]]`.

### `tags` (optional)

- 0–8 tags per page, lowercase kebab-case
- Tags are free-form — there is no controlled vocabulary by default. `wiki-lint` reports tag typos (`mashine-learning` vs `machine-learning`) based on edit distance.

### `created` / `updated` (required)

- ISO date, `YYYY-MM-DD`
- `created` is set at page creation and never touched again
- `updated` is set to today on every edit — including backlink additions from `wiki-ingest`

### `sources` (optional but strongly encouraged)

- Relative paths to files under `<wiki-root>/raw/` — always `../raw/filename` from the page's location in the per-type page dirs
- Or stable URLs
- Or `wiki://<slug>` for wiki-internal references — used by `type: synthesis` pages to cite the wiki pages they were derived from. `wiki-lint` validates that each `wiki://<slug>` target page exists (a missing target is a `broken_wiki_source` error).
- A page with no sources is flagged `warn` by `wiki-lint` unless its `type` is `decision` or `note`. A `type: synthesis` page with no `wiki://` source is flagged `synthesis_no_wiki_source` (warn) — synthesis pages must cite their wiki provenance.

### `publisher_url` (optional)

- A single canonical `https://` URL pointing to where the publication lives on the publisher's website.
- Used by **cogni-research wiki-researcher** to build clickable bibliography entries for wiki-sourced citations. Without it, citations to pages that were ingested from local PDFs (e.g. `sources: [../raw/foo.pdf]`) can only be linked via the wiki instance's `publisher_base_url` fallback — a publisher landing page rather than a per-document permalink.
- When `sources:` already contains an `https://` URL, that URL is assumed to be the publisher URL and `publisher_url` is redundant (but harmless — explicit wins on read).
- When `sources:` contains only local paths (`../raw/...`), add `publisher_url` if you know the canonical URL of the original publication. If you don't, leave it off — the wiki instance's `publisher_base_url` (see `.cogni-wiki/config.json`) still gives downstream citations a honest landing-page link.
- Never fabricate. An empty field is fine; a guessed URL is not.

### `related` (optional)

- Explicit curated cross-references, complementary to inline `[[wikilinks]]`
- Used by the dashboard to render a backlink graph without having to grep body text

### `status` (optional)

- Free-form label: `draft`, `stable`, `stale`, `contested`, etc.
- Used by `wiki-lint` and `wiki-update` to decide what to sweep

## Example

```yaml
---
id: llm-wiki-pattern
title: LLM Wiki Pattern (Karpathy)
type: concept
tags: [llms, knowledge-management, karpathy, compounding]
created: 2026-04-12
updated: 2026-04-12
sources:
  - ../raw/karpathy-llm-wiki-gist.md
  - https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
publisher_url: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
related:
  - compounding-knowledge
  - wiki-vs-rag
status: stable
---
```

## Synthesis page example

A `type: synthesis` page filed back by `wiki-query` looks like this — note `wiki://`-prefixed sources rather than `../raw/` paths:

```yaml
---
id: rlhf-vs-cai-comparison
title: RLHF vs Constitutional AI — wiki view
type: synthesis
tags: [llms, alignment, comparison]
created: 2026-05-05
updated: 2026-05-05
sources:
  - wiki://constitutional-ai
  - wiki://rlhf-overview
  - wiki://rlhf-limitations
---
```
