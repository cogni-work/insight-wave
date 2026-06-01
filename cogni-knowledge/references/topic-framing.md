# Topic Framing Playbook

> **Adapted** from `cogni-research/references/topic-framing.md` (point-in-time fork). cogni-knowledge is **story-arc agnostic**, so all `story-arcs.json` / `corporate-visions` machinery and the upstream Rule 3 (arc compatibility) are dropped. The deliverable-horizon question maps to `target_words` + `prose_density` (cogni-knowledge has sub-questions, not report types), and the verification constraint points at `cogni-knowledge:knowledge-verify`.

LLM-facing reference for the **optional Step 0 — Topic Framing** in `knowledge-plan`. Step 0 turns a fuzzy intent into a sharp, scope-tested research prompt before decomposition (Step 2) runs. Framework-agnostic. Context-open. Skippable when the topic is already sharp, or when `--no-framing` / `--dry-run` is passed.

The job is five moves, in order: **ground → scan → sharpen → right-size → emit**. (The **scan** move is optional and fail-soft — see Step 0.2b.)

## When framing engages (and when it gets out of the way)

Inspect the user's invocation before doing anything else.

| Signal | Action |
|--------|--------|
| Short, vague intent (≤ ~15 words, no audience, no thesis, no scope cue) | **Engage** Step 0 |
| Long, structured `--topic` (audience + thesis + scope already named) | **Skip** Step 0 — straight to Step 0.5 |
| Explicit verbs: "frame", "sharpen", "scope", "help me write a research prompt", "rahmen", "schärfen", "Forschungsfrage zuspitzen" — or the `--frame` flag | **Engage** Step 0 regardless of length |
| `--no-framing` or `--dry-run` passed | **Skip** Step 0 (non-interactive / explicit opt-out) |
| User said "go" / "defaults" / "just start" + a one-line topic | **Skip** Step 0 — they want to move fast; defaults handle the rest |

"Sharp" means at least three of: explicit **audience**, named **status-quo belief** or **thesis**, defined **scope** (geography / segment / horizon), and a clear **deliverable shape** (decision brief / deep report / quick scan). If two or fewer are present, engage.

When framing engages, say so in one sentence before asking anything: *"Let me help frame this before we plan. Four quick questions, then I'll draft a prompt you can edit."* / German: *"Lass uns das Thema zuerst rahmen. Vier kurze Fragen, dann schlage ich einen Prompt vor."*

## Step 0.2 — Ground in context

Ask the user (text output) for any grounding material they want the framing to honour. Accept any form: a directory path (portfolio, research archive, briefing deck), a pasted block of text (executive ask, status-quo belief, prior research), a URL or file reference. "No context — just the rough idea" is a valid answer.

When the user supplies a path, read it conservatively: `Glob` for the top-level shape, `Read` the manifest / README if present, sample 2–3 representative files. Do **not** load every file — context is for framing, not analysis. **Cap the read at ~50 KB.** No network, no writes outside `<project_path>/.metadata/`.

This step is schema-agnostic by design. Files are files.

## Step 0.2b — Preliminary scoping scan (optional, fail-soft)

Before surfacing the load-bearing variables, ground the framing in what's actually searchable. Decomposition done purely from reasoning can target angles that have no findable content — strong-looking sub-questions that send the downstream curators to dead ends. A heavily-documented topic survives a vacuum decomposition; an emerging or sparse topic is where a quick pre-search earns its keep.

**Engage.** The scan rides framing's engage decision — it runs only when framing has engaged (a vague topic or `--frame`), and it is skipped when `--no-prelim-search` was passed. It therefore never runs on a sharp topic, `--no-framing`, or `--dry-run`, so run-1 / automation paths stay zero-web. No new decision point — if you got here, framing is already engaged.

**Run.** Issue **2–3 broad `WebSearch` queries** on the grounded topic (in the topic's own language — this runs before `knowledge-plan` Step 0.5 resolves the market, so it needs no resolved market). Review the top result snippets and note:

- **dominant angles** — the framings the topic is actually discussed through;
- **key organizations** — the bodies/authorities that own the conversation;
- **recent developments** — what changed lately that a decomposition should reflect;
- **terminology** — the vocabulary real sources use (so sub-questions phrase searchable).

**Feed forward.** These observations inform **both** the sharpening turn (Step 0.3 — they shape the audience/thesis/scope options you surface) **and** `knowledge-plan` Step 2 decomposition (sub-question `query` + `theme_label` ground in the observed terminology). They are ephemeral working context — recorded as an optional `## Preliminary scan` note in `framing.md`, never a persisted plan field.

**Fail-soft.** Any error — no results, tool failure, an empty landscape — means *skip the scan silently* and fall through to today's pure-reasoning path. The scan never blocks framing; it only enriches it when it succeeds.

## Step 0.3 — Surface the load-bearing variables

Use a single `AskUserQuestion` turn with ≤ 4 questions. Each question is skippable ("not sure" / "I'll decide later" is always valid and drops to safe defaults).

### Question bank (EN)

1. **Audience** — *"Who is the primary reader of the final synthesis?"*
   - Options to offer: `internal strategy team`, `executive sponsor / board`, `external client / customer`, `regulator / public stakeholder`, `analyst / academic`. "Other" lets the user type a custom audience.

2. **Status-quo belief / thesis** — *"What assumption must the research challenge, confirm, or quantify?"*
   - Examples: *"X is not happening in our market"*, *"Y is a side issue, not strategic"*. Free-text — this becomes the synthesis's anchor.

3. **Register preference** — *"How should the synthesis read — a structured argument, or a comprehensive survey?"*
   - Map to `tone` + `prose_density` suggestions: a decision-oriented argument → `tone: analytical|persuasive` + `prose_density: executive` (BLUF + Pyramid, tight ceiling); a thorough survey → `tone: descriptive|objective` + `prose_density: standard`. Surface the suggestion; never silently commit.

4. **Deliverable horizon** — *"What's the deliverable shape?"*
   - Options: `quick scan` (~1.5–3K words), `decision brief` (~3–5K words), `deep report` (~5–8K words).
   - Map to a `target_words` suggestion for Step 0.5 — never silently commit.

### Question bank (DE)

1. *"Wer ist der primäre Leser der Synthese?"* — Optionen: `internes Strategie-Team`, `Vorstand / Aufsichtsrat`, `externer Kunde`, `Regulator / Behörde`, `Analyst / Wissenschaft`, `andere`.
2. *"Welche Annahme oder Status-quo-Überzeugung soll die Recherche herausfordern, bestätigen oder quantifizieren?"* — Freitext.
3. *"Wie soll die Synthese lesen — als strukturiertes Argument oder als umfassender Überblick?"* — Argument → `tone: analytical`, `prose_density: executive`; Überblick → `tone: descriptive`, `prose_density: standard`.
4. *"Welches Deliverable-Format?"* — `Quick-Scan` (~1,5–3K Wörter), `Entscheidungs-Brief` (~3–5K), `Tiefenbericht` (~5–8K).

## Step 0.4 — Right-size scope

Before drafting the prompt, run a deterministic scope check on the implied structure.

### Rule 1 — Leaf-dimension aggregation

If any theme lists ≥ 8 leaf dimensions, **suggest aggregation** to a higher level and tell the user which level. Examples: "Aggregate to 8 offerings — features are too granular for one synthesis." / "Cluster to 3–5 segments." / "Group to 3–4 regulation families." Remember `knowledge-plan` caps decomposition at **3–7 sub-questions**, so an over-broad topic must be aggregated or split into multiple plans.

### Rule 2 — Sub-question budget against `target_words`

Map the implied scope to the 3–7 sub-question cap:

| `target_words` | Sub-questions |
|---------------:|:-------------:|
| 1500           | 3             |
| 3000           | 3–5           |
| 4000           | 5–6           |
| 8000           | 6–7           |

If the implied scope exceeds the budget, propose **two cuts**: a **preferred** cut (drop or aggregate one whole theme of secondary value) and a **minimum** cut (keep all themes but cap each).

## Step 0.5 — Emit the sharpened research prompt

Produce **one** concise prompt block, ≤ 400 words, no narrative prose, bullet-able sub-questions per theme. Write it to `<project_path>/.metadata/framing.md` once the project path is resolved (mirrors cogni-research's `research-prompt.md`).

### Template

```markdown
# Research Prompt — {Working title, ≤ 12 words}

**Topic.** {One sentence — the question or thesis the synthesis answers.}

**Audience.** {Who reads it.}

**Status-quo belief to challenge / thesis to defend.** {The provocative anchor.}

**Scope.** {Geography / segment / horizon. One line.}

**Working level.** {The aggregation level — e.g., "8 offerings, not 39 features".}

## Themes (→ sub-questions)

### Theme 1 — {short title}
{1–2 sub-questions as bullets. No prose.}

### Theme 2 — {short title}
{...}

### Theme 3 — {short title}
{...}

## Constraints
- Language: synthesis in {EN|DE|...}.
- Cite {market-appropriate authority sources, named}.
- Verify quantitative + regulatory claims via `cogni-knowledge:knowledge-verify` (zero-network citation alignment) before finalize.
```

Hard rules for the prompt:

- **≤ 400 words total.** If longer, cut — aggregate dimensions, drop the weakest sub-question per theme, never trim the thesis or status-quo line.
- **No narrative prose.** Bullets and one-sentence anchors only. Step 0 produces a *prompt*, not a *synthesis*.
- **3–7 sub-questions total** across all themes (the `knowledge-plan` cap).
- **No silent decisions.** Every config hint (market, output_language, tone, prose_density, target_words, citation_format) is surfaced as a *suggestion* under a `## Suggested configuration` section **beneath** the prompt block, not inside it.

## Suggested configuration (for Step 0.5 resolution)

List the framing's suggested values so Step 0.5 can pre-fill them. The framing suggestion is a **new lowest-precedence tier** — it sits *below* an explicit flag and *below* the binding's `research_defaults`, so a base's persisted choices always win:

```
flag > binding research_defaults > framing suggestion > global/market default
```

- `market: <suggested>`
- `output_language: <suggested>`
- `tone: <suggested>` (from the register question)
- `prose_density: <suggested>` (from the register question)
- `target_words: <suggested>` (from the deliverable-horizon question)
- `citation_format: <suggested>` (usually `ieee` unless the audience implies otherwise)

After writing `framing.md`, hand back to Step 0.5 with the suggested-config values pre-filled in working context. The user's next reply enters the normal resolution, where every suggestion is overridable.

## Anti-patterns

- ❌ Producing a narrative when the user asked for a prompt. Step 0 emits a prompt.
- ❌ Leaving 39 dimensions in one theme because "the user didn't ask to cut it". Right-sizing is the value Step 0 adds — do the cut, name it, let the user undo it.
- ❌ Loading every file in a directory. Sample the manifest + 2–3 files; cap at ~50 KB.
- ❌ Skipping framing because the topic *looks* sharp at first glance. Apply the three-of-four sharpness test (audience, thesis, scope, deliverable).
- ❌ Inventing a `target_words` / `tone` instead of surfacing it as a suggestion — every config hint is overridable in Step 0.5.
- ❌ Running the scan on every topic — it rides framing's engage decision; sharp topics skip it (and so does `--no-prelim-search`).
