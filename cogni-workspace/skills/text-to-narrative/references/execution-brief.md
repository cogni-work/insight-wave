# Execution Brief (Phase 0)

Every narrative is written for someone, to serve a decision, in a voice, about a scope. Before Phase 0.5 runs, derive a per-run execution brief from four parameters and four non-parameter fields, and carry it through the four passes. A narrative that clears every Phase 5 gate can still be wrong for its reader — expert terminology for a general audience, a vendor-voiced close for an internal memo, global evidence in a DACH-only decision — and the brief is what prevents that.

## Fields

| Field | Kind | Values | Default |
|-------|------|--------|---------|
| Audience | parameter `--audience` | free text naming the reader (role, function, seniority) | senior business decision-makers |
| Purpose | parameter `--purpose` | free text naming the decision the narrative serves | understand the evidence and its strategic implications |
| Perspective | parameter `--perspective` | free text naming whose voice speaks (neutral analyst, the client's own leadership, a vendor, an advisor) | neutral analyst |
| Geography | parameter `--geography` | one or more market codes from `cogni-workspace/references/supported-markets-registry.json` — the `code` values such as `dach`, `de`, `at`, `fr`, `it`, `es`, `nl`, `pl`, `uk`, `us`, `eu`, `global` — comma-separated | source-defined scope |
| Knowledge level | inferred | `expert` / `informed` / `general` | `informed` |
| Tone | inferred | a short register description | concise analytical executive prose |
| Decision required | derived or explicit | the decision management should be able to take after reading | none unless supported by the request or source |
| Management ask | derived or explicit | the concrete approval, prioritization, funding, ownership or next move requested | none unless supported by the request or source |

`--geography` never takes free text or a country name. A value that is not a registry `code` is an error; report it with the registry path rather than guessing the code.

Knowledge level, tone, decision required and management ask are never flags. They are resolved from the request, project context and source material, and every extra flag is a surface a caller has to get right. Derive `decision_required` and `management_ask` only when the resolved purpose is decision-oriented; never manufacture either field from a merely descriptive purpose.

## Inference ladder

Resolve every field, including the inferred ones, down the same ladder and stop at the first rung that yields a value:

1. **Explicit instruction** — the parameter, or an instruction in the user's request.
2. **Project metadata** — `.metadata/plan.json` or `.metadata/project-config.json` in the project root Phase 1 step 8 resolves, and `narrative-config.json` in the source directory (keys `audience`, `purpose`, `perspective`, `geography`, `output_language`, `decision_required`, `management_ask`).
3. **Unambiguous conversation context** — something the user has already said in this session that settles the field.
4. **Source cues** — the sources' own framing: a report addressed to a board, market names in the data, a vendor's proposal voice.
5. **Default** — the value in the table above. For `decision_required` and `management_ask`, this rung yields no resolved value unless the request or source supports one.

Record which rung resolved each field. A field resolved at rung 5 is a default and is never written into frontmatter as if it were known.

## Materiality gate

Ask one compact clarification only when a field is unresolved above rung 5 **and** its value would change framing, terminology, emphasis, recommendations or evidence selection. One question, naming the field and offering the two or three answers the sources make plausible.

Never ask for what is explicit or safely inferable. Never ask more than one brief question per run. Under `--interactive false` never ask — take the default and continue. This is the second AskUserQuestion site in the skill after the Phase 2 arc confirmation, and it is gated by the same parameter.

## What the brief steers

| Pass | Field | Effect |
|------|-------|--------|
| Arc selection (Phase 2) | target | The requested output target breaks a tie in the registry's Step 5: when evidence and execution fit leave two or more defensible arcs, the one whose chain reads best in the requested target ranks higher. It never overrides an explicit or inherited arc. |
| Pass 1 — evidence draft | geography | When sources span markets, evidence from the named markets leads; other markets' evidence is context, not the argument. |
| Pass 2 — argument edit | purpose | The argumentative emphasis across the four elements and the close serve the named decision. |
| Pass 2 — argument edit | decision required, management ask | The closing implication explicitly states the resolved decision or concrete ask when either exists; it invents neither when both are unresolved. |
| Pass 2 — argument edit | perspective | Pronouns and ownership follow the voice: a neutral analyst says "operators"; the client's leadership says "we"; an advisor addressing the client says "you". |
| Pass 3 — language edit | audience, knowledge level | Vocabulary, acronym expansion on first use, and how much a mechanism is explained. `expert` keeps domain terms bare; `general` explains each mechanism once. |
| Pass 3 — language edit | tone | Register of the prose, within the executive-prose rules of `language-shared.md`. |
| Phase 5 — TL;DR synthesis | purpose, decision required, management ask | The Executive TL;DR's decision implication serves the purpose and names the resolved decision or concrete ask when present. |

`target` is the resolved `--target` invocation parameter carried alongside the brief, not an additional brief field — the `## Fields` table above remains authoritative.

## Frontmatter

When a field was resolved above rung 5, write it into the narrative's frontmatter as `target_audience`, `purpose`, `perspective`, `geography`, `decision_required` or `management_ask`. Never write a default into frontmatter: an unresolved field is absent, not fabricated.

## Prohibition

Never infer sensitive personal attributes about the audience — health, religion, ethnicity, political opinion, sexual orientation, or any protected characteristic — from a name, a role or a market. The audience is a professional role in a decision context, and that is all the brief models.
