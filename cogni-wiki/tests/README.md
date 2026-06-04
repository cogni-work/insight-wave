# cogni-wiki tests

Stdlib-only smoke tests for the per-type-directory migration introduced in v0.0.28.

## Layout

```
tests/
├── README.md
├── test_migrate_and_smoke.sh    End-to-end migrator + every-consumer smoke
└── fixtures/
    └── legacy-wiki/             Flat wiki/pages/ fixture (schema_version 0.0.4)
        ├── SCHEMA.md
        ├── raw/decision-log.md
        ├── wiki/
        │   ├── index.md
        │   ├── log.md
        │   ├── overview.md
        │   └── pages/
        │       ├── karpathy-pattern.md          type: concept
        │       ├── per-type-directories.md      type: concept
        │       ├── adopt-schema-version-0-0-5.md  type: decision
        │       └── lint-2026-04-15.md           audit report (R3 exempt)
        └── .cogni-wiki/config.json
```

## Run

```sh
bash tests/test_migrate_and_smoke.sh
```

The runner copies the legacy fixture to a temp directory, asserts every
consumer hard-fails on the legacy layout, runs `migrate_layout.py --apply`,
asserts pages landed in the right per-type dirs and audit reports under
`wiki/audits/`, asserts `schema_version` was bumped to `0.0.5`, asserts the
re-run is idempotent, and finally runs health / lint / dashboard / status /
backlink / extract against the migrated wiki and checks each emits
`success: true`.

stdlib-only — no pytest, no pip. Bash 3.2 + Python 3.8+.

CI integration is deferred (cogni-wiki has no CI today).

## Contract tests

For pure LLM skills (no scripts to execute), regression coverage is limited to **SKILL.md content invariants** — grep-based assertions that catch the most likely failure mode (a path or flag silently disappears from the contract) without pretending to verify LLM behaviour. For script-level surfaces, real Python harness assertions are used.

| Test | Asserts |
|------|---------|
| `test_wiki_from_research_flags.sh` | The `--allow-wiki-source` / `--cycle-guard-cleared` flag pair lifts the `report_source ∈ {wiki, hybrid}` abort at Step 0(3) and Step 1d (v0.0.40); project-config read path is `.metadata/project-config.json` (post-v0.0.40, not the stale bare-filename form). |
| `test_wiki_query_wiki_root.sh` | `--wiki-root` flag exists in the parameter table; Step 1 skips the upward cwd walk and verifies `<wiki-root>/.cogni-wiki/config.json` when the flag is set (v0.0.41). |
| `test_parse_frontmatter_wikilink.sh` | `_wikilib.parse_frontmatter` keeps `field: [[slug]]` as a string (was mis-parsed as `["[slug]"]` pre-v0.0.43, F4). Quoted form and real inline lists regression-checked. |
| `test_locate_research_project_naming.sh` | `_wiki_research.locate_research_project` resolves both legacy `cogni-research-<slug>/` and v0.7.x+ `<slug>/` / `<slug>-<date>/` (v0.0.43, F2). |
| `test_batch_builder_metadata_config.sh` | `batch_builder.discover_research` reads `.metadata/project-config.json` (v0.7.x+) with fallback to legacy `<project>/project-config.json` (v0.0.43, F3). |
| `test_source_page_type.sh` | `wiki-health` and `wiki-lint` accept the additive `type: source` page type added in v0.0.44 (#270) — a planted `wiki/sources/<slug>.md` page raises neither `invalid_type` nor `type_directory_mismatch`. Unblocks cogni-knowledge PR #269 milestone 6 `knowledge-ingest`. |
| `test_index_summary_clamp.sh` | `wiki_index_update.py --max-summary N` clamps an over-long `--summary` on a WORD boundary with `…` via `_wikilib.clamp_summary` (v0.0.47, #324) — output words are an exact prefix of the input (no mid-word "…Sonderka"), German ä/ö/ü survive, codepoint-counted. No flag → verbatim passthrough (backward-compat for every other caller). |
| `test_question_page_type.sh` | `wiki-health` and `wiki-lint` accept the additive `type: question` page type added in v0.0.50 (#407) — a planted `wiki/questions/<slug>.md` page raises neither `invalid_type` nor `type_directory_mismatch`. Unblocks cogni-knowledge #407 `knowledge-ingest` Step 4.5 (research-question nodes). |
| `test_index_move_slug.sh` | `wiki_index_update.py --move-slug <slug> --to-category <cat>` non-destructively relocates an existing index entry between headings: alphabetised under the target, summary preserved verbatim, source heading dropped only when drained empty (a curated prose lead-in keeps it), idempotent (2nd call → `noop`), `[[wikilink]]` set-membership unchanged, and mutually exclusive with slug-mode / `--reflow-only`. Part A of the question-anchored index migration. |

```sh
bash tests/test_wiki_from_research_flags.sh
bash tests/test_wiki_query_wiki_root.sh
bash tests/test_parse_frontmatter_wikilink.sh
bash tests/test_locate_research_project_naming.sh
bash tests/test_batch_builder_metadata_config.sh
bash tests/test_source_page_type.sh
bash tests/test_index_summary_clamp.sh
bash tests/test_question_page_type.sh
bash tests/test_index_move_slug.sh
```

The SKILL.md tests do not assert anything about LLM-driven behaviour — only that the contract surface that orchestrators (`cogni-knowledge:knowledge-report` / `cogni-knowledge:knowledge-query`) depend on remains intact. The script-level tests execute the actual code path and assert observable behaviour.

**Maintenance note.** The grep patterns assert exact parameter-table layout (`| `--flag-name` | No | Mode A & Mode B…`). Cosmetic reformats — column swap, extra column, switching from `|`-pipe tables to a different structure — will trip these tests even when the underlying contract is unchanged. When reformatting a parameter table in any covered SKILL.md, update the patterns in the matching test script.
