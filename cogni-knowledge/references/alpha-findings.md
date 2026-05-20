# Phase 4 alpha findings

Bugs and UX gaps surfaced during the internal alpha (Phase 4 of `absorption-roadmap.md`). Items prefixed `F` were discovered while attempting the first end-to-end `knowledge-research` + `knowledge-report` orchestrator-chain run against a fresh knowledge base.

F1–F5 are **chain-breakers** — without these fixes, the chain only completes with live ad-hoc workarounds (symlinks, sed-patches against ingested pages, hand-written wiki pages). F6–F10 are UX and resilience gaps that affect operator confidence but do not block the chain from running.

## Findings

| # | Surface | Status in v0.0.14 | One-line description |
|---|---|---|---|
| F1 | `cogni-knowledge/skills/knowledge-setup/SKILL.md:44-46` | **fixed** | Step 0 probe (`${CLAUDE_PLUGIN_ROOT}/../<plugin>/...`) only resolves the dev-repo sibling layout; marketplace cache layout (`../../<plugin>/<version>/...`) is not probed. Setup falsely aborts in cache installs. |
| F2 | `cogni-wiki/skills/wiki-ingest/scripts/_wiki_research.py:74-110` | **fixed** | `locate_research_project` only probes `cogni-research-<slug>/`. cogni-research v0.7.x+ creates `<slug>-<date>/` (or `<slug>/` with `--slug`) — the project is not findable. |
| F3 | `cogni-wiki/skills/wiki-ingest/scripts/batch_builder.py:435-441` | **fixed** | Reads `<project>/project-config.json` (legacy path). cogni-research v0.7.x+ writes `<project>/.metadata/project-config.json`. Discovery aborts. |
| F4 | `cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py:318-347` | **fixed** | `parse_frontmatter` treats `field: [[slug]]` as a one-element flow-sequence `["[slug]"]`, so downstream `isinstance(sq_ref, str)` checks silently fail. Per-sub-question pages end up with empty `sq_id` and link nowhere. |
| F5 | `cogni-wiki/skills/wiki-ingest/scripts/_wiki_research.py:41-51` | **subsumed by F4** | Path-prefixed wikilink (`[[01-contexts/data/ctx-foo]]`) appears unstripped. Real root cause was F4 returning a list — `strip_wikilink`'s existing `rsplit("/", 1)[-1]` already handles the path-prefix once it receives a string. No separate fix needed once F4 lands. |
| F6 | UX, `knowledge-research` chain | **deferred** | The wiki appears empty to the operator for ~80% of wall-clock (cogni-research runs before wiki-ingest fires). No progress milestones reach the orchestrator's stdout. Needs upstream milestone emission from cogni-research's phase pipeline. |
| F7 | UX, `knowledge-research` chain | **deferred** | No mid-chain confirmation gate. The user only confirms once (at `research-setup`) and then commits to the full chain including ingest. Operator-visible gate after research completes, before ingest fires, would be valuable. |
| F8 | Resilience, cogni-research section-researcher | **deferred** | No checkpoint/resume on API outage mid-chain. A 5xx mid-research today loses all phase state — the project directory persists but the section-researcher state is in-context only. Structural fix needs section-researcher refactor. |
| F9 | Resilience, cogni-research entities | **deferred** | Orphan source entities accumulate on partial-chain failure. Companion to F8 — once F8's checkpoint exists, the cleanup path can use it. |
| F10 | `cogni-research/scripts/initialize-project.sh` | **deferred (cogni-research issue)** | Writes empty `document_paths: []` even when project is initialised in wiki mode with `wiki_paths` set. Misleading on inspection. Fix belongs in cogni-research, not in cogni-knowledge or cogni-wiki — file separately. |

## v0.0.14 summary

Fixes F1, F2, F3, F4 land in v0.0.14. F5 closes transitively when F4 ships (verified — `_wiki_research.strip_wikilink:51` already strips path prefixes once it receives a string). F6–F10 are tracked here and remain open after v0.0.14.

Bundled with the v0.0.14 fixes are four PR-#267 reviewer-deferred items (A1–A4) — see the v0.0.14 entry in `cogni-knowledge/CHANGELOG.md` for the full bundle. F1's fix is rolled to the other six `knowledge-*` skills via A4.

## Next steps after v0.0.14

The v0.0.16 alpha re-run is the deliverable v0.0.14 unblocks. Reset a fresh knowledge base, drive `knowledge-research` end-to-end without operator intervention, then `knowledge-report` against the populated base. Successful re-run is the go-decision input for Phase 5 (v0.1.0 Preview) graduation.

F6–F10 remain open through Phase 5 and may be addressed individually as scoped sprints; none individually block Phase 5 graduation if the v0.0.16 alpha re-run is otherwise clean.
