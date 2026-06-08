# Migration exit audit — Epic B (Migrate)

This is the **one-time proof** that the FMO Migrate epic is complete: no
non-`cogni-knowledge` skill, agent, or command file issues a **live dispatch**
to `cogni-research:` or `cogni-wiki:`. It is the handoff artifact that Epic C
(Archive) consumes:

- **Epic C's CI grep-guard** (the permanent enforcement) reads the
  authoritative command and the tolerated-residue list below so its repo-wide
  assertion does not false-positive on prose/doc mentions.
- **Epic C's archive-docs sweep** reads the class-(b) inventory below as its
  worklist for the user-facing docs that still name the soon-archived plugins.

The CI grep-guard itself is **not** part of this audit — it lands in Epic C.
This artifact only proves the guard *would* pass once prose mentions are
accounted for.

> Status at audit time: **invariant HOLDS** — zero class-(a) live dispatches in
> consumer scope. All residue is class-(b) docs/data mention.

## The migration invariant

> No file outside `cogni-knowledge/` (and outside the two plugins being archived,
> `cogni-research/` and `cogni-wiki/`) may **dispatch** `cogni-research:<skill>`,
> `cogni-wiki:<skill>`, or a `cogni-research`/`cogni-wiki` agent via
> `Skill(...)` or `Task(subagent_type=...)`.

A *dispatch* is a live invocation. A *mention* — a changelog entry, a "mirrors
X" pattern note, a deprecation pointer, a user-facing instruction in a README —
is **not** a dispatch and does not violate the invariant. Distinguishing the two
is the whole job of this audit, because a naive `grep cogni-wiki:` cannot.

## Scope and exclusions

The invariant is about **consumer plugins** — the plugins that used to call
research/wiki and were cut onto cogni-knowledge by Epic B's six children
(cogni-consulting, cogni-trends, cogni-workspace, cogni-narrative,
cogni-portfolio, plus the cogni-wiki `wiki-from-research` rotation). The audit
therefore excludes, by design:

| Excluded tree | Why out of scope |
|---|---|
| `cogni-knowledge/` | The **absorbing** plugin — it legitimately names `cogni-wiki:wiki-setup` as the engine it dispatches at setup, and names the absorbed skills as the native analogs it replaced. Not an external caller. |
| `cogni-research/`, `cogni-wiki/` | The plugins **being archived** in Epic C. Their own internal cross-references archive *with* them; they are not external callers that need cutting. |
| `_archive/` | Already-archived legacy chains. |
| top-level `wiki/`, `docs/` | Generated doc **mirrors** (catalog pages), not dispatch surfaces. |
| `cogni-workspace/wiki/` | The vendored, read-only doc-wiki catalog pages. |
| `**/references/` | Design/decision docs — provenance prose, not dispatches (this file lives here). |

## Authoritative command (corrected, prefix-agnostic)

> **Why the issue-body grep was wrong.** The command in #504's body anchored its
> exclusions with `^\./(wiki|docs)/` and leading-slash forms like
> `/cogni-knowledge/`. But `grep -rIn -E … .` on this repo emits paths **without**
> a leading `./` (e.g. `README.md:273`, `cogni-trends/CLAUDE.md:96`). Those
> anchors therefore silently fail to fire, so the doc-mirror and top-level
> excludes never apply and the result is ~300 noise hits. The corrected form
> below uses prefix-agnostic `(^|/)` anchors.

```bash
# Run from repo root. Returns ONLY the consumer-scope residue (should be all class-(b)).
grep -rIn -E 'cogni-(research|wiki):[a-z]' --include='*.md' --include='*.json' . \
  | grep -vE '(^|/)(cogni-knowledge|cogni-research|cogni-wiki|_archive)/' \
  | grep -vE '(^|/)wiki/' \
  | grep -vE '(^|/)docs/' \
  | grep -vE '(^|/)cogni-workspace/wiki/' \
  | grep -vE '/references/'
```

Live-dispatch probe (must return zero — confirms no class-(a) hit hides among
the mentions):

```bash
# Skill()/Task() invocations of cogni-research/cogni-wiki in consumer files.
grep -rIn -E '(Skill\(|subagent_type[^)]*|Task[^)]*)["'"'"']cogni-(research|wiki):' --include='*.md' . \
  | grep -vE '(^|/)(cogni-knowledge|cogni-research|cogni-wiki|_archive)/' \
  | grep -vE '/references/'
# → (no output) = ZERO live dispatches
```

## Cleared inventory

**Class-(a) live dispatches: 0.** The migration is complete.

**Class-(b) docs/data mentions: 10**, enumerated below with the reason each is a
mention and where it gets handled. (Line numbers are accurate at audit time and
may drift; the reason and disposition are the durable part.)

| # | Location | Kind | Disposition |
|---|---|---|---|
| 1 | `README.md` — `cogni-wiki:wiki-query` usage example | User-facing instruction | Epic C archive-docs sweep (root README) |
| 2 | `README.md` — `cogni-wiki:wiki-setup` "own knowledge base" instruction | User-facing instruction | Epic C archive-docs sweep (root README) |
| 3 | `cogni-visual/CLAUDE.md` — "supersedes the deprecated `cogni-research:export-report`" | Deprecation pointer | Leave (historical context) or Epic C docs sweep |
| 4–8 | `cogni-trends/CHANGELOG.md` (×5) — past-tense entries describing the already-landed `cogni-research:local-researcher` / `cogni-wiki:wiki-query` / `cogni-research:section-researcher` cuts | Changelog history | **Leave** — changelogs are immutable historical record |
| 9 | `cogni-trends/CLAUDE.md` — "`verify-trend-report` … mirroring `cogni-research:verify-report`" | Pattern reference | Leave (architectural prose) or Epic C docs sweep |
| 10 | `cogni-trends/skills/verify-trend-report/SKILL.md` — "Mirror of `cogni-research:verify-report`" | Pattern note **inside a SKILL.md** | **See handoff note ▼** |

## Handoff note for Epic C's CI grep-guard (#507)

One class-(b) mention lives inside a **SKILL.md** (inventory row 10):
`cogni-trends/skills/verify-trend-report/SKILL.md` contains the prose
`Mirror of cogni-research:verify-report`. It is **not** a dispatch — the
live-dispatch probe returns zero — but a naive repo-wide
`grep 'cogni-research:'` over skill files **would trip on it**. Epic C's
grep-guard must therefore do one of:

1. **Reword the prose** to drop the literal `cogni-research:` token (e.g.
   "Mirror of the research-plugin `verify-report` pattern"), then assert a hard
   zero over skill/agent/command files; **or**
2. **Scope the guard to dispatch shapes** — assert zero
   `Skill("cogni-(research|wiki):…")` / `Task(subagent_type="cogni-(research|wiki):…")`
   rather than zero substring matches — which tolerates prose mentions by
   construction.

Option 2 is the more robust guard (it tests the actual invariant, not a proxy),
but option 1 is a cheap belt-and-braces complement. The changelog entries
(rows 4–8) make a pure-substring guard untenable regardless, since changelog
history must not be rewritten — so the guard must either exclude `CHANGELOG.md`
or test dispatch shapes.
