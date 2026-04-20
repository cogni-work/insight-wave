# Page Frontmatter Schema

Every file in `wiki/pages/` (except `lint-YYYY-MM-DD.md` reports) begins with this YAML frontmatter block.

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
  - ../raw/<filename>                 # Relative path from wiki/pages/ to raw/ file
  - https://<url>                     # Or a stable external URL
publisher_url: https://<url>          # Optional. Canonical URL at the publisher
related:                              # Optional. Curated cross-reference list
  - <other-page-slug>
status: <optional>                    # Optional. e.g. "draft", "stable", "stale"
---
```

## Field rules

### `id` (required)

- Must match the filename stem exactly: a page at `wiki/pages/llm-wiki-pattern.md` has `id: llm-wiki-pattern`
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
| `learning` | A generalized takeaway drawn from multiple sources or experience |
| `note` | A loose observation that hasn't crystallized — often promoted later to `concept` or `learning` |

Pick the most specific type. `wiki-lint` will warn when a page's body has drifted far from its declared type.

### `tags` (optional)

- 0–8 tags per page, lowercase kebab-case
- Tags are free-form — there is no controlled vocabulary by default. `wiki-lint` reports tag typos (`mashine-learning` vs `machine-learning`) based on edit distance.

### `created` / `updated` (required)

- ISO date, `YYYY-MM-DD`
- `created` is set at page creation and never touched again
- `updated` is set to today on every edit — including backlink additions from `wiki-ingest`

### `sources` (optional but strongly encouraged)

- Relative paths to files under `<wiki-root>/raw/` — always `../raw/filename` from the page's location in `wiki/pages/`
- Or stable URLs
- A page with no sources is flagged `warn` by `wiki-lint` unless its `type` is `decision` or `note`

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
