# Topic Framing Playbook

LLM-facing reference for **Step 0 — Topic Framing** in `research-setup` (the design plan called this "Phase 0"; the implementation lives as Step 0 to align with the existing Step 1–4 numbering). Step 0 turns a fuzzy intent into a sharp, scope-tested, optionally arc-aligned research prompt before the configuration menu opens. Framework-agnostic. Context-open. Skippable when the topic is already sharp.

The job is four moves, in order: **ground → sharpen → right-size → emit**. Everything below is in service of those four moves.

## When framing engages (and when it gets out of the way)

Inspect the user's invocation before doing anything else.

| Signal | Action |
|--------|--------|
| Short, vague intent (≤ ~15 words, no audience, no thesis, no scope cue) | **Engage** Step 0 |
| Long, structured prompt (audience + thesis + scope already named) | **Skip** Step 0 — straight to Step 1 |
| Explicit verbs: "frame", "sharpen", "scope", "help me write a research prompt", "rahmen", "schärfen", "Forschungsfrage zuspitzen" | **Engage** Step 0 regardless of length |
| User pasted an existing research-prompt block matching the Step 0.5 template | **Skip** Step 0 — treat as already-framed input |
| User said "go" / "defaults" / "just start" + a one-line topic | **Skip** Step 0 — they want to move fast; defaults handle the rest |

"Sharp" means at least three of: explicit **audience**, named **status-quo belief** or **thesis**, defined **scope** (geography / segment / horizon), and a clear **deliverable shape** (decision brief / deep report / quick scan). If two or fewer are present, engage.

When framing engages, say so in one sentence before asking anything: *"Let me help frame this before we configure. Four quick questions, then I'll draft a prompt you can edit."* / German: *"Lass uns das Thema zuerst rahmen. Vier kurze Fragen, dann schlage ich einen Prompt vor."*

## Step 0.2 — Ground in context

Ask the user (text output) for any grounding material they want the framing to honour. Accept any form. Examples to offer:

- A directory path (portfolio, research archive, document folder, briefing deck).
- A pasted block of text — executive ask, status-quo belief, existing positioning, prior research.
- A URL or file reference.
- "No context — just the rough idea" is a valid answer.

When the user supplies a path, read it conservatively: `Glob` for the top-level shape (entity directories, README, configuration JSON), `Read` the manifest / README if present, sample 2–3 representative entity files. Do **not** load every file — context is for framing, not for analysis. Cap the read at ~50 KB.

When the user supplies a pasted blob, treat it as opaque background and quote at most one sentence back to confirm you read it.

This step is **schema-agnostic** by design. Don't assume `markets/` or `features/` directories exist. Files are files.

## Step 0.3 — Surface the load-bearing variables

Use a single `AskUserQuestion` turn with ≤ 4 questions. Each question is skippable ("not sure" / "I'll decide later" / "andere / weiß noch nicht" is always a valid answer that drops to safe defaults).

### Question bank (EN)

1. **Audience** — *"Who is the primary reader of the final report?"*
   - Examples to offer as options: `internal strategy team`, `executive sponsor / board`, `external client / customer`, `regulator / public stakeholder`, `analyst / academic`. "Other" lets the user type a custom audience (e.g., *"T-Mobile Polska B2B leadership + DT Group sponsors"*).

2. **Status-quo belief / thesis** — *"What assumption must the research challenge, confirm, or quantify?"*
   - Examples: *"X is not happening in our market"*, *"Y is a side issue, not strategic"*, *"Z will arrive too late to matter"*. Free-text answer. Keep what the user writes — this becomes the report's anchor.

3. **Framework preference** — *"Should the report follow a named messaging framework, or stay structurally neutral?"*
   - Options to surface (today): `corporate-visions` (Why Change → Why Now → Why You → Why Pay — fit for buying-decision, sales-enablement, strategic-investment audiences), `neutral / standard-research` (default — sections derived from sub-questions), `other / I'll decide later`.
   - Only `corporate-visions` is implemented as an arc today in `story-arcs.json`. If the user names `scqa`, `pyramid`, `BLUF`, `inverted-pyramid`, or another framework, **acknowledge** it, note that the arc engine doesn't enforce it yet, and fall back to `standard-research` for `story_arc_id` while keeping the user's preference in the framing notes so the writer can honour it in prose.

4. **Deliverable horizon** — *"What's the deliverable shape?"*
   - Options to offer: `quick scan` (~1.5–3K words, basic), `decision brief` (~3–5K words, detailed), `deep report` (~5–8K words, deep), `outline only`, `annotated bibliography / resource list`.
   - Map to `report_type` + `target_words` suggestions for Step 1 — never silently commit.

### Question bank (DE)

1. *"Wer ist der primäre Leser des Berichts?"* — Optionen: `internes Strategie-Team`, `Vorstand / Aufsichtsrat`, `externer Kunde`, `Regulator / Behörde`, `Analyst / Wissenschaft`, `andere`.
2. *"Welche Annahme oder Status-quo-Überzeugung soll die Recherche herausfordern, bestätigen oder quantifizieren?"* — Freitext.
3. *"Soll der Bericht einem benannten Framework folgen oder strukturell neutral bleiben?"* — Optionen: `corporate-visions` (Warum Veränderung → Warum jetzt → Warum Sie → Geschäftliche Auswirkungen), `neutral / Klassischer Forschungsbericht`, `andere / entscheide ich später`.
4. *"Welches Deliverable-Format?"* — Optionen: `Quick-Scan` (~1,5–3K Wörter, basic), `Entscheidungs-Brief` (~3–5K, detailed), `Tiefenbericht` (~5–8K, deep), `nur Outline`, `kommentierte Quellenliste / Resource`.

## Step 0.4 — Right-size scope

Before drafting the prompt, run a deterministic scope check on the implied structure.

### Rule 1 — Leaf-dimension aggregation

If any pillar / sub-question lists ≥ 8 leaf dimensions, **suggest aggregation** to a higher level and tell the user which level. Examples:

| Topic mentions | Aggregation prompt |
|----------------|--------------------|
| 39 features under one pillar | "Aggregate to 8 offerings — features are too granular to address per-item in a single report." |
| 21 sub-segments under one market pillar | "Cluster to 3–5 segments." |
| 12 regulations under one regulatory pillar | "Group to 3–4 regulation families (e.g., NIS2/KSC, DORA, EU AI Act, CRA)." |
| 15 competitors named | "Profile the top 5–7 by relevance; aggregate the rest into a category line." |

### Rule 2 — Artefact-budget against `target_words`

One pillar should produce **≤ 5 first-class artefacts** in the report body (charts, tables, JSON drop-ins, named comparisons). Across the whole report, scale the total artefact budget against `target_words`:

| `target_words` | Total first-class artefacts | First-class per pillar (typical 3–4 pillar report) |
|---------------:|----------------------------:|---------------------------------------------------:|
| 1500           | 3–4                         | 1                                                  |
| 3000           | 5–7                         | 2                                                  |
| 5000           | 8–10                        | 2–3                                                |
| 8000           | 12–15                       | 3–4                                                |
| 12000          | 16–20                       | 4–5                                                |

If the implied scope exceeds the budget, propose **two cuts**: a **preferred** cut (drop or aggregate one whole pillar of secondary value) and a **minimum** cut (keep all pillars but cap each to its share of the budget).

### Rule 3 — Arc compatibility

If `story_arc_id: corporate-visions` is on the table, surface the existing constraint (`report_type ∈ {detailed, deep}`, `output_language ∈ {en, de}`, `target_words ∈ [3000, 8000]`) **at framing time** so the menu in Step 1 doesn't need to re-litigate. If the user's deliverable-horizon choice or detected language conflicts, name the conflict and offer the two paths ("keep `corporate-visions` and switch to detailed/deep + EN/DE" vs. "keep your choice and drop to `standard-research`").

## Step 0.5 — Emit the sharpened research prompt

Produce **one** concise prompt block, ≤ 400 words, no narrative prose, bullet-able sub-questions per pillar. Write it to the working directory as `research-prompt.md` (if the project slug is already known, write to `<project-slug>/research-prompt.md`).

### Template

```markdown
# Research Prompt — {Working title, ≤ 12 words}

**Topic.** {One sentence — the question or thesis the report answers.}

**Audience.** {Who reads it.}

**Status-quo belief to challenge / thesis to defend.** {The provocative anchor.}

**Scope.** {Geography / segment / horizon. One line.}

**Working level.** {The aggregation level — e.g., "8 offerings, not 39 features"; "5 customer segments, not 21".}

## Pillars

### Pillar 1 — {short title}
{2–4 sub-questions as bullets. No prose.}

### Pillar 2 — {short title}
{...}

### Pillar 3 — {short title}
{...}

### Pillar 4 — {short title}
{...}

## Deliverables
- Report in `research/` following the {N}-pillar structure.
- {Drop-in artefacts: JSON / charts / matrices, named explicitly.}
- {One synthesis chart or table that lands the headline number.}

## Constraints
- Language: report in {EN|DE|...}; entity content in {language} where customer-facing.
- Cite {market-appropriate authority sources, named}.
- Verify quantitative + regulatory claims via `cogni-research:verify-report` before finalization.
```

Hard rules for the prompt:

- **≤ 400 words total.** If the draft is longer, cut — aggregate dimensions, drop the weakest sub-question per pillar, never trim the thesis or status-quo line.
- **No narrative prose.** Bullets and one-sentence anchors only. Step 0 produces a *prompt*, not a *report*.
- **≤ 5 sub-questions per pillar.** Right-sizing rules apply here too.
- **No silent decisions.** Every config hint (arc, report_type, target_words, market, output_language) is surfaced as a *suggestion* the user can override in the Step 1 menu — list them under a `## Suggested configuration` section beneath the prompt block, not inside it.

After writing the file, hand back to Step 1 with the suggested-config values pre-filled in working context. The user's next reply enters the normal config menu, where every suggestion is overridable.

## Worked example

User's rough intent: *"consider the dt-security-offerings portfolio and derive a research topic for T-Mobile Biznes Polska to onboard to this common portfolio. NatCos like T-Mobile Polska don't yet see ICT consolidation as a risk in their local business, and security specifically is treated as a side line."*

Step 0 grounding: user supplies the `dt-security-offerings` directory. Skill reads `portfolio.json` (or equivalent) + scans top-level entity directories. Notes: 8 offerings, mention of 39 features, DACH-anchored, EU sovereignty default.

Step 0 surfaced variables: audience = *T-Mobile Polska B2B leadership + DT Group sponsors*; status-quo = *"ICT consolidation isn't happening locally; security is a side line."*; framework = `corporate-visions`; horizon = *deep report (~5–8K)*.

Step 0 right-sizing: 39 features → **8 offerings** (Rule 1). Polish-readiness matrix capped at 8 rows. ≥ 5 sub-pillars proposed → aggregated to **4** (Why Change / Why Now / Why Us / Why Pay).

Step 0 emitted prompt (excerpt — the full version is the canonical example saved at the end of this file):

```markdown
# Research Prompt — T-Mobile Biznes Polska × DT Common Security Portfolio

**Topic.** Why T-Mobile Biznes Polska must adopt the DT common B2B security portfolio inside 18 months.
**Audience.** T-Mobile Polska B2B leadership + DT Group sponsors (EU Segment, T-Systems, T-Security).
**Status-quo belief to challenge.** "ICT consolidation isn't happening locally; security is a side line."
**Thesis.** Security is the renewal gate for the entire Polish B2B ICT wallet. Only the DT group portfolio + governance + integrated delivery defends it.
**Working level.** 8 DT offerings (not 39 features). Poland B2B. 2023–2028.

## Pillar 1 — Why Change
- Map Polish B2B security landscape against the DT 8-offering taxonomy (Orange Polska Cyberdefence, Asseco/Comp, EXATEL, MS E5/Defender, Palo Alto, CrowdStrike).
- Wallet shift from connectivity to security-led bundles 2023–2026.
- Where T-Mobile Polska B2B sits today.

## Pillar 2 — Why Now
- Polish regulatory calendar to 2027: KSC/NIS2-PL, DORA, EU AI Act, CRA — with in-scope counts, deadlines, DT offering each one pulls.
- Competitor moves last 18 months; PL-language MSSP desks.
- "Last responsible moment" timeline.

## Pillar 3 — Why Us
- Three proof points: common 8-offering taxonomy + EU sovereignty; aligned GTM / partner steering; integrated delivery across EU Segment ↔ T-Systems ↔ T-Security.
- Polish readiness per offering (ready / language overlay / local cert / local partner).
- 2–3 Q1 lighthouse offerings (likely MDR, KSC/NIS2 GRC, Sovereign Cloud Security).
- Magenta AT / Hrvatski HR onboarding precedents.

## Pillar 4 — Why Pay
- Direct security TAM/SAM/SOM Poland (enterprise-pl, mid-market-pl) — delta SOM vs. local-only baseline.
- Security-dependent ICT TAM/SAM/SOM (defended wallet). Key assumptions: security-attach precondition rate, renewal-loss probability without it, new-ICT uplift with it.
- Transition cost ranges; payback in quarters.

## Deliverables
- Report in `research/` with the 4-pillar structure.
- 2 × `markets/*-pl.json`, 2 × `customers/*-pl.json`, top 3–4 PL `competitors/`.
- 8-offering Polish readiness matrix.
- One value-at-stake chart (security captured + ICT defended vs. transition cost).

## Constraints
- Report in English; customer-facing entity content in Polish.
- Cite PMR, IDC Polska, Audytel, Gartner, CERT Polska/NASK, operator reports.
- Verify quantitative + regulatory claims via `cogni-research:verify-report` before finalization.
```

## Suggested configuration (for Step 1)

- `story_arc_id: corporate-visions`
- `report_type: deep`
- `target_words: 6000` (mid of 3000–8000)
- `market: pl`
- `output_language: en`
- `tone: analytical`

Step 1 renders the menu with these pre-filled; the user overrides anything before `initialize-project.sh` runs.

## Anti-patterns

- ❌ Producing a narrative ("Working title: ... Why this framing ... Central research question ... ") when the user asked for a prompt. Step 0 emits a prompt — the four-pillar narrative belongs in the report itself, not in the prompt that orders the report.
- ❌ Leaving 39 dimensions in one pillar because "the user didn't ask to cut it". Right-sizing is the value Step 0 adds — do the cut, name it, let the user undo it.
- ❌ Loading every file in a portfolio directory. Sample the manifest + 2–3 entity files; cap at ~50 KB. Step 0 is framing, not research.
- ❌ Silently choosing `corporate-visions` because the topic feels strategic. Always ask. The user's reply might be "no, neutral please" — and that answer matters.
- ❌ Skipping framing because the topic *looks* sharp at first glance. Apply the three-of-four sharpness test (audience, thesis, scope, deliverable). One missing element is fine; two missing means engage.
