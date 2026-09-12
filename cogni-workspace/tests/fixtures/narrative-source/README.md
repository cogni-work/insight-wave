# Narrative source fixture

Arc-less source material for exercising the `text-to-narrative` skill end to end: arc detection over the registry's declarative blocks, the shortlist confirmation, the four drafting passes and the Phase 5 gates. Nothing here carries an `arc_id:` frontmatter key, so a run over this directory has to detect an arc rather than inherit one.

The files describe one topic — condition-based maintenance for European industrial operators — with enough cited numbers for a citation-grounded narrative at the default length. `make-buy-partner.md` frames the same topic as a comparison of three options against explicit criteria, so a detection run over that file alone should shortlist `strategic-choice` first.

Used by no discovered test suite directly (it sits one level below the `tests/*.sh` globs); the suites under `cogni-workspace/tests/` reach it by path when they need a source corpus, and the sibling `narrative-output/` directory carries finished narratives for the validator suite.
