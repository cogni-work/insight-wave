# knowledge-setup — curated wiki-output layout seed (Step 3.5b)

Reference-grade detail for `skills/knowledge-setup/SKILL.md` Step 3.5 sub-step (b).
This is the **verbatim** three-heredoc seed payload the orchestrator runs to overwrite
`wiki-setup`'s generic seeds with the curated, knowledge-native shape — extracted here
for progressive disclosure so the SKILL.md body stays lean. The body keeps the imperative
sub-step (b), the substitution rules, and the per-seed rationale bullets; this file holds
the exact heredoc bodies to run.

**Behavior is unchanged** — the orchestrator runs this block exactly as before; only its
storage location moved (body → reference). `tests/test_setup_seed_contract.sh` greps this
file for the per-string assertions that target the heredoc payload (the heredoc opener
lines and the seed-body contract text); every other Step-3.5 assertion still targets the
SKILL.md body prose.

## Substitution contract (recap — full rules live in the SKILL.md body)

Run all three `cat > … <<'EOF'` heredocs with a **quoted** delimiter (no shell expansion).
Substitute `<knowledge-title>` textually, and — on the SCHEMA.md `_Created:` subtitle line
**only** — today's date `YYYY-MM-DD`. Never replace-all on `YYYY-MM-DD` (the `audits/` tree
line carries `lint-YYYY-MM-DD.md` / `health-YYYY-MM-DD.md` as literal filename **patterns**),
and keep the in-body `<knowledge-root>/` tree root **literal** (a generic placeholder in the
deposited contract, not a substitution token). The log heredoc in sub-step (c) is the one
place that stays **unquoted** (it relies on `$(date)`) — it is NOT part of this block.

## Seed payload (run verbatim)

```
cat > <knowledge_root>/wiki/index.md <<'EOF'
# <knowledge-title>

<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:START -->
_Overview pending — authored on the first knowledge-finalize run._
<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:END -->

<!-- MACHINE-OWNED:ROOT-INDEX -->

_Curated map of this knowledge base. Each theme below links to its per-type sub-indexes with live counts — open one to read the pages._
EOF

cat > <knowledge_root>/wiki/overview.md <<'EOF'
# Overview

_The overview narrative now lives in the curated map intro at [index.md](index.md). This page keeps the running `## Recent syntheses` list._
EOF

cat > <knowledge_root>/SCHEMA.md <<'EOF'
# SCHEMA — <knowledge-title>

_Created: YYYY-MM-DD · knowledge-native contract (seeded by cogni-knowledge)_

This file is the contract for how this knowledge base is structured. It lives
inside the base (not inside the plugin) so the base stays self-describing even
if cogni-knowledge is uninstalled or replaced.

## Directory layout

    <knowledge-root>/
    ├── SCHEMA.md             This file — conventions and contract
    ├── raw/                  Immutable source documents (papers, transcripts, data)
    ├── assets/               Attachments referenced from pages
    ├── wiki/
    │   ├── index.md          Curated MAP front door (overview narrative + theme map)
    │   ├── overview.md       Stub — holds the running `## Recent syntheses` list
    │   ├── meta/             Control files: log.md, context_brief.md, open_questions.md
    │   ├── concepts/         type: concept — instance-free ideas, frameworks, mechanisms
    │   ├── entities/         type: entity — named orgs, laws, products, programs
    │   ├── people/           type: person — named humans (the Who facet)
    │   ├── sources/          type: source — ingested bodies with pre-extracted claims
    │   ├── questions/        type: question — research-question nodes with answer claims
    │   ├── syntheses/        type: synthesis — finalized research deposits
    │   ├── interviews/       type: interview — standalone interview deposits
    │   └── audits/           lint-YYYY-MM-DD.md / health-YYYY-MM-DD.md reports
    ├── .cogni-wiki/          Engine metadata (config.json, ingest queue)
    └── .cogni-knowledge/     Binding manifest + fetch cache (which research
                              projects fed this base)

The six indexed types (concepts, entities, people, sources, questions,
syntheses) each carry a machine-owned `index.md`
sub-index; `interviews/` and `audits/` are real on disk but not sub-indexed.
The generic wiki directories this pipeline never writes (`decisions/`,
`meetings/`, `notes/`, legacy flat `pages/`) are intentionally absent — one
appearing here was hand-added and sits outside the pipeline contract.

## Types — what goes where

- **concept** — a reusable, instance-free idea: a framework, mechanism,
  obligation, rule, regime, or discipline describable without naming one
  specific instance. **A concept title MUST be instance-free.** Test: if the
  title only makes sense as one organization's thing, it is an instance ⇒
  `entity`, never `concept`.
  The reusable idea behind an instance may still earn its own concept page.
- **entity** — a named instance: an organization, law, product, program,
  facility, team, service offering, or initiative — even one whose name
  sounds abstract.
- **person** — a named human (the Who facet); named humans live here, never
  in `entities/`.
- **source** — an ingested source body; its `pre_extracted_claims:`
  frontmatter is what drafts cite and the verifier scores against.
- **question** — one node per research sub-question; links its answering
  sources and may carry citable `answer_claims:`.
- **synthesis** — a finalized, verified research deposit (or filed-back query
  answer); cites its wiki provenance.
- **interview** — a standalone interview deposit.

Every page's frontmatter `type:` MUST match the directory it lives in.

## Linking

- `[[page-slug]]` for wiki pages — slug-only, no path; slugs are globally
  unique and resolve to their per-type directory.
- Standard markdown links for external URLs and `raw/` files.
- A forward `[[link]]` implies a prose reverse link on the target page
  (rule `R1_bidirectional_wikilink` — lint reports missing reverses).
  Two exemptions: synthesis-page `wiki://` citations need no reverse link
  (`R2_synthesis_wiki_source`), and audit reports are terminal on both ends
  (`R3_audit_report`). Lint findings cite these rule IDs.

## Golden rules

1. Claude writes the wiki; the user curates the raw sources.
2. Every query reads the wiki — never answers from memory.
3. Citations required — claims on pages trace to `raw/` files or URLs.
4. Append-only log (`wiki/meta/log.md`) — recorded, never rewritten.
EOF
```
