# Charter Framing Playbook

> Companion to `topic-framing.md`. Same five-move *shape* (ground → scan → sharpen → right-size → emit), one level **up**. Do **not** duplicate `topic-framing.md` — this file owns only what is base-scoped. See also: `topic-framing.md` for per-research-question framing at `knowledge-plan` Step 0.4.

LLM-facing reference for the **charter interview** in `knowledge-setup` Step 2.5. The charter steers the *whole knowledge base* before any research runs: it captures what the base is about, who reads its syntheses, where its boundaries are, and which themes to cover first.

## The two-level model

cogni-research has one project = one topic, so framing happens once, per topic. cogni-knowledge is different: **one base accumulates many topics over time**. So framing splits into two levels:

| Level | Where | Captures | Persisted to |
|-------|-------|----------|--------------|
| **Charter** (coarse) | `knowledge-setup` Step 2.5 — **once per base** | domain · audience · scope · seed themes | `binding.json::charter` + `topic_lineage.open_themes[]` (schema 0.1.4) |
| **Per-question framing** (fine) | `knowledge-plan` Step 0.4 — **once per run** | audience · status-quo thesis · register · deliverable horizon → `tone`/`prose_density`/`target_words` | `<project>/.metadata/framing.md` (`topic-framing.md`) |

The charter is the missing coarse layer. It is **inherited grounding**: `knowledge-plan` Step 0.4 reads `charter.{domain,audience,scope}` and injects it into the per-question *ground* move, so every run is anchored to the base instead of framing cold. The charter deliberately carries **only** domain/audience/scope/themes — the writer-quality knobs (`tone`/`prose_density`/`citation_format`/`target_words`) stay per-run on `knowledge-plan`.

## When the charter interview engages (and when it gets out of the way)

The base **must be steered** — an unframed base is the problem this solves — so the interview is **default-on with an explicit opt-out**, the inverse of topic-framing's "skip when sharp" default.

| Signal | Action |
|--------|--------|
| Interactive run, charter fields not all supplied by flag | **Engage** (the default) |
| `--no-charter` passed | **Skip** the interview AND the Step 5 on-ramp (flag-or-default init) |
| All of `--charter-domain`/`--charter-audience`/`--charter-scope` supplied via flags (non-interactive) | **Skip** — the charter is fully resolved from flags |

When engaging, say so in one sentence first: *"Let me frame this knowledge base before we set it up — a few quick questions so every future research run is anchored to it."* / German: *"Lass uns die Wissensbasis zuerst rahmen — ein paar kurze Fragen, damit jede künftige Recherche darauf aufbaut."*

## The five moves (base-scoped)

1. **Ground** — identical to `topic-framing.md` Step 0.2: ask for any grounding material (path / pasted text / URL / "no context"), read conservatively, **cap ~50 KB**, no network, no writes outside the base.
2. **Scan** — identical posture to `topic-framing.md` Step 0.2b: optional, fail-soft, `--no-prelim-search` opts out; 2–3 broad `WebSearch` queries on the **domain** (not a single research question) to ground the seed-theme suggestions. Any error → skip silently.
3. **Sharpen** — one `AskUserQuestion` turn, ≤ 4 skippable questions, base-scoped bank below. The four charter questions (domain, audience, scope, seed themes) fill the `AskUserQuestion` 4-question cap, so the market + output-language questions (from `knowledge-setup` Step 2.5) spill into an immediate follow-up turn; only fold them into the same turn when one or more charter questions are pre-supplied by flag and the budget allows.
4. **Right-size** — seed themes are a *backlog*, not a single run's scope, so there is no 3–7 cap here (that cap is per-run, in `topic-framing.md`). Just keep the seed list tight (3–6) — it is the candidate menu for the first research question, not an exhaustive roadmap.
5. **Emit** — the charter is written by `knowledge-binding.py init` (Step 4), not a `framing.md` file. There is no separate emit artifact at the base level; the binding **is** the persisted charter.

## Question bank (EN)

1. **Domain** — *"In one sentence, what is this knowledge base about?"* → `charter.domain`. Free text; the anchor every future run inherits.
2. **Audience** — *"Who reads the syntheses this base produces?"* → `charter.audience`. Offer the same option list as `topic-framing.md`'s audience question: `internal strategy team`, `executive sponsor / board`, `external client / customer`, `regulator / public stakeholder`, `analyst / academic`; "Other" for a custom audience.
3. **Scope** — *"What's in and out of scope? (geography / segment / horizon)"* → `charter.scope`. Free text, one line — the in/out boundary (e.g. "EU only, mid-market SaaS, 2024-2027").
4. **Seed themes** — *"Which 3–6 themes should this base cover first?"* → `topic_lineage.open_themes[]`. multiSelect over scan-derived suggestions + "Other". These become the candidate menu for the Step 5 first-question on-ramp.

Every question is skippable — "I'll decide later" drops to the safe default (charter field → `""`, no seed themes).

## Question bank (DE)

1. *"Worum geht es bei dieser Wissensbasis — in einem Satz?"* → `charter.domain`.
2. *"Wer liest die Synthesen, die diese Basis produziert?"* — Optionen: `internes Strategie-Team`, `Vorstand / Aufsichtsrat`, `externer Kunde`, `Regulator / Behörde`, `Analyst / Wissenschaft`, `andere` → `charter.audience`.
3. *"Was ist im und außerhalb des Geltungsbereichs? (Geografie / Segment / Zeithorizont)"* → `charter.scope`.
4. *"Welche 3–6 Themen soll die Basis zuerst abdecken?"* (Mehrfachauswahl) → `open_themes[]`.

## Feed-forward: the charter as inherited grounding

After the binding is written, the charter is durable steering for the life of the base:

- **`knowledge-plan` Step 0.4** reads `charter.{domain,audience,scope}` and injects it into the per-question *ground* move (the base-level → per-question handoff), so a sharp per-question framing under a populated charter defaults its audience/scope to the charter rather than asking cold. Fail-soft on a pre-0.1.4 base (empty charter → today's behaviour).
- **`knowledge-setup` Step 5** offers the seed themes (`open_themes[]`) as the candidate menu for the first research question, chaining the chosen one into `knowledge-plan --frame`.
- **`knowledge-resume` / `knowledge-dashboard`** surface `charter.domain` + the `open_themes[]` backlog read-only.

## Anti-patterns

- ❌ Re-asking the per-question framing questions (status-quo thesis, register, deliverable horizon) at the base level. Those are per-run — they belong in `topic-framing.md`, not the charter.
- ❌ Putting the writer-quality knobs (`tone`/`prose_density`/`citation_format`/`target_words`) in the charter. They stay per-run; the charter is domain/audience/scope/themes only.
- ❌ Treating seed themes as a fixed roadmap. They are a starting backlog — the user adds/drops topics freely over the base's life.
- ❌ Blocking setup on the interview in automation. `--no-charter` / a flag-only init skips it and still writes a complete schema-0.1.4 binding.
- ❌ Letting a scan failure abort framing. The scan is fail-soft — any error means fall through to pure reasoning.
