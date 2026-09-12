# Narrative Language Quality

The editorial standard for narrative prose and its derivatives, in every language. Loaded at Phase 4 Pass 3 together with the language's own file (`language-en.md` or `language-de.md`), and nowhere earlier — evidence and argument are stable before expression is touched. It governs expression, not structure: never change the selected arc, the evidence, a claim's meaning or its citation to improve style.

## Core standard

Write executive prose, not report prose. The reader understands each sentence on first reading, feels a deliberate progression from paragraph to paragraph, and meets language specific enough that it could not be pasted unchanged into an unrelated narrative.

### 1. Lead with meaning

Put the central claim in the main clause and usually near the front of the sentence. Context may precede the claim only when the delay creates useful tension or prevents a misleading reading.

- Weak: "In light of accelerating regulatory change and a number of recent market developments, companies are beginning to reconsider their operating models."
- Better: "Regulatory change is forcing companies to reconsider their operating models."

Do not apply a mechanical word-position rule. The test is whether the reader reaches the point without wading through setup.

### 2. Give each sentence one primary job

A sentence may carry supporting detail, a contrast or a short list, but one dominant idea. Split sentences that combine separate claims, causes, consequences and recommendations with no hierarchy. Long sentences are allowed when their structure is easy to follow and the length creates flow; shortness is not a goal by itself.

### 3. Prefer actors and actions

Concrete subjects and strong verbs. Replace avoidable nominalizations and noun-plus-weak-verb constructions with direct action: "the implementation of the program" → "the company launched the program"; "a reduction in cycle time occurred" → "cycle time fell". Use the passive when the actor is unknown, irrelevant, deliberately backgrounded, or when continuity makes it clearer. Do not optimize for a fixed active-voice share.

### 4. Prefer specificity over intensity

If the evidence provides a number, actor, date, mechanism or observable consequence, use it instead of an adjective or intensifier: "revenue fell 12%" over "revenue fell significantly"; "three regulators" over "multiple stakeholders"; "approval now takes six weeks" over "approval has become considerably slower". Never invent specificity — when the evidence is qualitative, stay precise about what the source actually supports.

### 5. Remove corporate fog

Delete wording that delays or dilutes meaning without adding substance: "it is important to note", "in the context of", "with regard to", "increasingly" when no increase is evidenced, "plays an important role", "significant" or "substantial" without a defined basis, "leverage", "synergy", "holistic", "transformative", "strategic" when a more exact word exists, "solution", "capability", "resources", "stakeholders" or "value" when the actual object, actor or outcome can be named. Keep specialist terms that are the precise language of the domain; explain them only when the brief's audience requires it.

### 6. Control paragraph architecture

One dominant idea per paragraph; its first sentence normally states the claim. Within a paragraph prefer *claim → evidence or mechanism → consequence* when it fits the evidence, and vary the shape so the prose does not read as a template. End paragraphs with weight: the consequence, contrast, implication or memorable formulation, never a citation wrapper or an incidental qualification.

### 7. Create rhythm deliberately

Vary sentence length and syntax: short sentences for emphasis and turns, medium for most reasoning, an occasional longer one for accumulation or comparison. Avoid stretches where every sentence has the same length and shape, and avoid artificial punchiness where every thought is a fragment. Read each paragraph mentally aloud and rewrite anything that sounds bureaucratic, tangled, repetitive, breathless or machine-produced.

### 8. Make transitions consequential

A transition explains why the next idea follows — causal, temporal, comparative or strategic logic, never a topic label. Prefer "this changes the economics because…", "the constraint is no longer X; it is Y", "that advantage disappears when…", "the second-order effect is…", "together, these shifts move the decision from … to …". Avoid empty bridges such as "another important aspect is" or "the next point to consider is".

### 9. Use rhetoric only when the content earns it

Parallelism, controlled repetition, antithesis, tricolons and a short concluding sentence after a longer setup can sharpen a genuine contrast or give a conclusion cadence. They never substitute for evidence or reasoning. Use them sparingly, never stack several in one paragraph, and impose no quota.

### 10. Avoid synthetic rhetorical templates

Language models overproduce certain constructions. Treat these as warning patterns rather than absolute bans: "This is not merely X; it is Y." — "The question is no longer whether X, but how." — "In an increasingly complex world…" — "At the heart of this transformation…" — "The implications are profound." — "What emerges is a clear picture…" — "The future belongs to…" — repeated "not X, but Y" contrasts — repeated one-sentence rhetorical questions. Use a familiar construction only when it expresses a specific insight better than plainer alternatives, never to manufacture momentum.

## Citations in prose

The citation form is `Claim text<sup>[N](source-file.md)</sup>`, placed at the end of the clause it supports. Style edits move words, never markers: a sentence may be split or merged only if every `[N]` still sits on the claim it supports, and no edit changes a number, a name or a date the marker vouches for.

## Readability diagnostics

Readability measures locate passages worth reviewing. They are not acceptance criteria. Warning signs: several consecutive sentences need rereading; the main clause repeatedly arrives after long setup; nominalizations dominate a paragraph; four or more abstract nouns appear where actors or objects could be named; sentence length barely varies across a paragraph; adjacent paragraphs open with the same syntax; rhetorical questions or contrast templates repeat; the prose could serve another topic by changing only the nouns.

Do not enforce hard limits — a fixed maximum sentence length, a fixed Flesch score, an active-voice share, a required device count. Pass 4 runs the copywriter's readability script and revises once on a miss against the language target in `cogni-workspace/tests/fixtures/copywriter/readability.yml`; that single bounded gate is the only numeric check, and its sub-metrics (clause length, floskel count, sentence-length variance) are diagnostics that point at passages, never verdicts on the narrative.

## Final editorial pass

Before validation, revise once for each question:

1. **Meaning** — is the central claim unmistakable?
2. **Agency** — is it clear who or what acts where agency matters?
3. **Specificity** — did the prose use the most concrete evidence available without inventing detail?
4. **Economy** — can filler or abstraction be removed without flattening the argument?
5. **Rhythm** — does the paragraph vary naturally and land on its consequential idea?
6. **Originality** — does the wording sound specific to this evidence rather than generated from a generic executive template?
7. **Fidelity** — did every stylistic change preserve the underlying claim, evidence, qualification and citation?

## Bridge heading

A document that carries a trailing further-reading section uses one heading per language. The narrative skill itself emits a `**Sources**` block instead (see `validation.md`), so a generated narrative never carries this heading; the copywriter substitutes it positionally when it translates an older arc document that does.

| EN | DE | FR | IT | PL | NL | ES |
|----|----|----|----|----|----|----|
| Further Reading | Weiterführende Lektüre | Pour aller plus loin | Approfondimenti | Dalsza lektura | Verder lezen | Lecturas adicionales |
