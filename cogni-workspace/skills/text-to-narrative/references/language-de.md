# German Executive Prose

Apply only for German output, at Phase 4 Pass 3, after evidence and argument are stable, and on top of `language-shared.md`. German executive prose is not English executive prose translated word by word: the sentence carries its meaning through the verb bracket, and a draft that imports English information order reads as a translation even when every word is German.

## Sentence craft

**Satzklammer.** German main clauses hold the finite verb in second position and park the rest of the verb complex — participle, infinitive, separable prefix — at the end. Everything in between is the bracket's content. Keep the bracket light: when the reader has to hold four qualifiers before reaching "abgeschlossen", "eingeführt" or "ab", the sentence has failed on first reading. Close the bracket early and add the detail in a following sentence.

**Mittelfeld.** The field between the two verb parts takes the sentence's information in a natural order — known before new, short before long, time and cause before manner and place. A Mittelfeld crowded with adverbials, appositions and a relative clause slows comprehension more than the same words spread over two sentences. Break an overloaded Mittelfeld before it breaks the reader.

**Subject and finite verb close together.** Keep the subject and the finite verb within a few words of each other. A subordinate clause wedged between them ("Die Betreiber, die trotz steigender Kosten weiterhin auf …, verlieren …") makes the reader wait for the predicate; move the insertion after the verb or into its own sentence.

**Nebensätze.** Limit nesting. One subordinate clause carries a relationship; a second nested inside it hides it. Prefer a sequence of clear main clauses when the logical relationship stays explicit through the connector ("deshalb", "dennoch", "erst dann").

**Funktionsverbgefüge.** Replace the noun-plus-light-verb construction with the verb it hides: "eine Entscheidung treffen" → "entscheiden", "eine Analyse durchführen" → "analysieren", "zur Anwendung bringen" → "anwenden", "in Betracht ziehen" → "erwägen". The construction is legitimate only when it carries a nuance the verb lacks.

**Nominalstil.** Chains of nouns on "-ung", "-keit", "-ismus" and genitive attributes ("die Durchführung einer Bewertung der Optionen") are the report register the executive reader skims past. Turn the nominal chain into an actor and an action: "Wir müssen die Optionen bewerten." Keep compounds when they are idiomatic and precise ("Instandhaltungsbudget"); do not coin long novelty compounds that hide the underlying action.

**Anglizismen.** Prefer the German word where it exists and is precise: "Umsetzung" over "Implementierung", "Fähigkeit" over "Capability", "Vorreiter" over "First Mover", "Hebel" only when a lever is meant. Keep an English term when it is the domain's own name — a product, a standard, a framework label such as TIPS — and keep it in its English spelling. Never import English hype: "disruptiv", "transformativ" and "gamechanging" are the corporate fog rule 5 of `language-shared.md` names, in German.

**Register.** Confident, matter-of-fact wording; the formal second person ("Sie") throughout for You-Phrasing; no exclamation marks; numbers with the German decimal comma and thin-space thousands grouping or a plain figure, consistently.

## Examples

- "Die Durchführung einer Bewertung der Optionen ist erforderlich." → "Wir müssen die Optionen bewerten."
- "Die Fähigkeit zur schnellen Anpassung gewinnt zunehmend an Bedeutung." → "Unternehmen müssen sich schneller anpassen." — only when the evidence supports the actor and the necessity.
- "Aufgrund der Tatsache, dass …" → usually "Weil …" or a separate main clause.
- "Die Betreiber, die trotz der seit 2023 steigenden Instandhaltungskosten weiterhin auf kalendergesteuerte Wartung setzen, verlieren mehr Produktionsstunden." → "Betreiber, die weiter kalendergesteuert warten, verlieren mehr Produktionsstunden. Ihre Instandhaltungskosten steigen seit 2023 trotzdem."

## Orthography

Proper Unicode umlauts and ß throughout — title, subtitle, TL;DR, headings and body: ä, ö, ü, Ä, Ö, Ü, ß, never the ASCII digraphs ae, oe, ue, ss standing in for them. Common failures to scan for: "fuer", "ueber", "Aenderung", "groesste", "Fuehrung". File names, slugs and YAML keys stay ASCII; the narrative does not. Validation gate L1 in `validation.md` checks the ä/ö/ü digraphs mechanically over the whole narrative; ß written as `ss` cannot be decided mechanically because `ss` is legitimate German, so read for it in the Pass 3 language edit.

## Thresholds, by reference

The numeric targets German prose is measured against live in the copywriter skill and are not restated here, so there is one authority for each number:

- Clause length, sentence-rhythm variance and the Floskel list: `cogni-workspace/skills/copywriter/references/german-style-principles.md` (Wolf Schneider's maxims).
- The opening sentence — length, main-clause form, surprise before scene: `cogni-workspace/skills/copywriter/references/german-hook-principles.md`; the narrative's Executive TL;DR first sentence is where those rules apply.
- The German readability band and the diagnostics the script reports: `cogni-workspace/tests/fixtures/copywriter/readability.yml`, run by `cogni-workspace/skills/copywriter/scripts/readability.sh` in Pass 4.
