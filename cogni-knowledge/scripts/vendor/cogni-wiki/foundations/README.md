# Foundations

Curated terminal pages for canonical consulting / product / strategy frameworks.

`wiki-prefill` copies these into a wiki's `wiki/concepts/` directory so every
new wiki starts with a shared vocabulary instead of re-deriving Porter's Five
Forces, Jobs-to-be-Done, MECE, … from whatever source the user happens to
drop into `raw/` first.

## Contract

- One file per concept, kebab-case slug, `type: concept`, `foundation: true`.
- 200–500 character body summarising the framework, plus a "When to reach for
  it" line so a `wiki-query` reader knows which problems it fits.
- Frontmatter `created:` / `updated:` use the literal placeholder
  `{{PREFILL_DATE}}`. `prefill_foundations.py` substitutes the current ISO
  date at copy time, then never rewrites the page on idempotent re-runs.
- One authoritative external URL in `sources:` (HBR, the original paper, the
  framework owner's canonical page). Never link to a wiki page from a
  foundation — by definition it has no per-wiki context yet.
- No `[[wikilinks]]` in the body. A foundation is a terminal page; if the
  reader needs cross-references they appear when downstream pages link into
  it, not from it.

## Filter sets

Used by `wiki-prefill --filter <set>`. A foundation can appear in multiple
sets via its `tags:`.

| Filter      | Tag             | Intent                                 |
|-------------|-----------------|----------------------------------------|
| `consulting`| `consulting`    | Classic management-consulting toolkit  |
| `product`   | `product`       | Product / design discovery frameworks  |
| `strategy`  | `strategy`      | Competitive / corporate strategy       |
| `all`       | (any)           | Everything (default)                   |

## Adding a new foundation

1. Write `<slug>.md` here, following the contract above.
2. Tag it with at least one filter set (`consulting`, `product`, `strategy`).
3. Confirm `wiki-prefill --list` surfaces it.
4. Add an assertion to `tests/test_prefill.sh` if the new file changes the
   default copy count.

## Why terminal?

Concepts like "Porter's Five Forces" don't need synthesis from sources you
have on hand — the framework is the framework. `wiki-update` refuses to edit
a `foundation: true` page without `--force`, `wiki-lint` skips its
`orphan_page` / `no_sources` / `stale_*` warnings, and `wiki-ingest` routes
collisions on a foundation slug to "ingest as a related case study"
rather than overwriting the canonical definition.
