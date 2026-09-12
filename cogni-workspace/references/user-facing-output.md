# User-facing output

The canonical register for insight-wave plugins: which language, which surfaces
the rules cover, how a stored value is displayed, how a table reads, how a step
is announced, and what an executive register costs in words.

This is the horizontal layer's copy of the doctrine, so a vertical plugin does
not have to invent one. A plugin **overlays** it rather than restating it —
the overlay carries only what is genuinely its own: its state lexicon rows, its
coinage vocabulary, and any surface its own guards pin. Read this file first,
then the overlay.

**This file governs the main loop only.** A dispatched agent never sees it — a
subagent's prompt carries no `CLAUDE.md`, no settings language, no output style
and no skill body. A plugin whose agents produce user-facing prose owes them the
same doctrine through its own subagent contract, injected by a `SubagentStart`
hook, plus a resolved interaction language as a dispatch input. Those are one
contract with two delivery paths, not two contracts: check a rule changed here
against the agent-side copy.

## (a) Language

Resolve the **interaction language** the way the calling plugin resolves it. In
the absence of a plugin-specific ladder, the workspace `language` key in
`.claude/settings.local.json` is the default and Claude Code turns it into a
`# Language` system-prompt section. A plugin that distinguishes the interaction
language from a stored output language owns that separation in its own
reference — do not restate a ladder here. Everything below applies in whatever
language resolves.

**German orthography.** Write ß after a long vowel or a diphthong (Maßnahme,
außerhalb, Größe) and ss after a short vowel (dass, muss, Prozess).
Kein schweizerisches ss an ß-Stellen — the Swiss convention of writing ss in
every ß position is never used here. Umlauts are covered by the repo-wide
encoding convention that forbids ASCII substitutes.

Two other copies of this rule exist in this plugin and are deliberate, not
drift. `hooks/on-session-start-language.sh` injects it into every German session
with no file to load, which is the only path that reaches a session carrying no
skill and no overlay; `skills/copywriter/references/translation-en-to-de.md`
owns the fuller treatment with a substitution table. This paragraph is the copy a
plugin reading the register gets. A change to any of the three is checked against
the other two — the hook is the one that actually reaches an unadorned session,
so it is the one that must never be thinner than this.

**When the stored corpus disagrees.** The paragraph above is read once; a
project's stored files arrive as in-context evidence and out-argue it. A corpus
already written in Swiss ss therefore teaches every later turn to keep writing
it, and the drift reinforces itself silently. Check a corpus rather than trust
it. Treat a finding as the stored text being wrong, not the rule — and note that
a curated-pair scan has bounded recall, so a zero-finding report means nothing on
that list appeared, not that the corpus is correct.

## (b) Scope — every surface, not only prose

These rules govern **every** user-facing surface, not only prose: table cells,
column headers, list items, headings, count lines, step announcements, offer
lines, and the `description` of a tool call, whose own copy rules are (f).

A table is not an exemption from the register — it is where register failures are
most visible, because a column header reads as a label the system endorses.

## (c) Stored values are never displayed raw

An engine value is **never** displayed raw. Each plugin owns a lexicon mapping
its stored tokens to display words in each language it supports. A value missing
from that lexicon is a gap in the lexicon, not a licence to pass the raw value
through — add the row.

Where an English display string happens to equal the engine token, that is a
coincidence of vocabulary, not an exemption — the value still passes through the
lexicon rather than being printed because it "already looks like English".

A lexicon may be **open** (values the engine actually writes, so a new one is a
row to add) or **closed** (a fixed prose vocabulary with no backing field, where
a fourth value is an invention rather than a gap). State which, per entry, in the
overlay — the two failure modes are opposite and conflating them licenses
invented terms.

## (d) Table contract

1. A fixed, named column set — never derived at runtime from whatever keys the
   data happens to carry.
2. Natural-language headers. A field identifier as a column header is a defect.
3. An explicit sort, stated once, not left to the order the data arrived in.
4. A row cap, plus one overflow line naming what was not shown.
5. Drop degenerate columns — a column carrying an identical value in every row
   informs no one.
6. No table under four rows. Below that, prose or a list reads better.
7. A slug appears only where the reader needs it to *act*, in code form. Never
   as a header, and never as an entity's name.
8. A cell standing in for a missing or unmeasured **quantity or state** renders
   `—`, never a zero-valued token (`0/0`, `0 von 0`): zero reads as a
   measurement, the em-dash as "nothing here to measure". A value that could
   not be read is a third case again — name it rather than flattening it into
   either of the first two. This does not govern a boolean marker column (a
   glyph when true, blank when false), which is its own established idiom. And
   rule 5 never licenses dropping a column to hide a state the reader needs
   to see.

## (e) Step announcements and brevity budgets

Two tiers, split by irreversibility rather than by skill:

- **Read-only step**: one sentence, at most 25 words.
- **Work step** (writes state, or fans out over a project's entities): two
  sentences, at most 45 words, naming what comes back and what changes on disk.

One announcement per perceptible wait, never one per tool call.

Three rules keep the announcement cheap:

- **Announce before *or* report after — never both.** Saying it twice costs the
  reader a second pass and adds nothing.
- **Name the actors when they are domain entities, never the dispatch.** Name
  the stakeholders, the markets, the deliverables — not "four agents". The
  reader knows the domain, not the machinery.
- **No wall-clock estimates.** A wrong estimate is a trust withdrawal, which
  inverts what the announcement is for.

**Work narration.** A batch of edits is one perceptible step, not many. Announce
it with a single high-altitude line before making it — what is changing and why —
never a file-by-file preview. Afterwards, do not restate each individual edit or
diff back in prose: the change itself is the record, and re-narrating it buries
the answer in low-altitude detail. Close the batch with a compact summary —
which files were touched and to what collective purpose — not a walkthrough of
each diff. This does not contradict the announce-before-*or*-report-after rule
above: that rule binds per perceptible step, and a batch gets one opening line at
batch altitude plus one closing summary, never a per-edit narration.

**A numbered back-reference carries its name** — "option 2 (the open content
layer)", not "at 2". A bare ordinal makes the reader scroll back to recover what
it points at.

Work narration is main-loop-only, in the style of (f) below: a dispatched agent's
user-facing surface is the envelope it returns, not a sequence of edits it
narrates, so an agent-side contract carries no counterpart and none is owed.

## (f) Tool-call descriptions

The `description` of a Bash tool call is rendered to the user, so it is user
copy. (b) names it a governed surface; this section owns its specifics.

Five constraints, all binding:

1. Written in the resolved interaction language, per (a).
2. Outcome-shaped — what the user gets back, not what the machine runs.
3. At most 6 words.
4. No script, file, or skill names. Those are engine vocabulary, and (c) no more
   exempts a description than it exempts a table cell.
5. Never derived from the script's filename or its header comment. A filename is
   an engineering label; deriving from it reproduces engine vocabulary in the one
   place the user reads it.

A description failing any of the five is a defect on the same footing as a raw
engine value in a table cell. This is a surface, not a debug channel.

A plugin may restate these five inline in its skills, and should where a
description can be written — wrongly — without ever opening this file. That
duplication is deliberate and is the plugin's to guard; unlike a resolution
ladder, which cannot be applied without opening its reference, these constraints
have to sit where the model always reads them.

Main-loop-only, deliberately: a dispatched agent's user-facing surface is the
envelope it returns, not its own tool calls, so an agent-side contract carries no
counterpart to this section and none is owed.

## (g) Prose anglicisms

(c) governs how a **stored engine token** is displayed. This section governs the
**prose word the reader reads** — vocabulary that carries no backing field and so
has no row to look up.

**German.** Before reaching for any vocabulary table, run the three-step test:

1. Does an equally precise German word exist? If yes, use it.
2. Is the anglicism established with no good German equivalent (*Meeting*,
   *Software*, *Update*)? If yes, keep it.
3. Is it a hyphenated English compound? Those almost always have a German
   rendering — replace them.

The test is German-specific, like the orthography paragraph in (a); the
acronym and never-invent rules below are not. A plugin resolving to a language
with no equivalent discipline stated here applies those two and skips the test
rather than transliterating it.

The method is the `copywriter` skill's, at
`skills/copywriter/references/german-style-principles.md`,
which also owns the substitution table and the checklist row binding it. It is
restated here rather than delegated because a vertical plugin reading this file
cannot resolve a path inside this one — `$CLAUDE_PLUGIN_ROOT` names the reading
plugin. The two copies are checked against each other; that reference is the
source.

Step 3 is what a plugin's own coinage table resolves to. That table belongs in
the overlay, not here: a coinage is by definition the plugin's own, and a shared
table would collect terms most plugins never write.

**Spell an acronym out once at first use** — ICP, OMTM, UVP — then use it freely
for the rest of the exchange. That is the default where no audience is resolved.
Where a plugin resolves one, `skills/copywriter/references/acronym-handling-principles.md`
tunes the expansion depth to it and names a set that is never expanded at all —
`IT`, `EU`, `USD`, `PDF`, regulation proper nouns, brand names — and it wins over
this default rather than contradicting it.

**Never invent a system term that does not exist.** An invented term is worse
than a leaked one: a leaked engine value can at least be looked up in the system,
while an invented one resolves nowhere the reader can reach — not in the
artifact, not in a manifest, not in this file. When a word is needed for a state,
take it from the plugin's lexicon per (c), or describe what happened in plain
language.

The naming discipline in this section has a subagent counterpart wherever a
plugin dispatches agents, because an agent's envelope prose is exactly where an
invented term surfaces. Unlike (f), which is main-loop-only by its own terms, a
rule changed here is checked against the agent-side copy.

## (h) Executive register and engine vocabulary

Write in an executive register: precise, concise, no filler, no restating the
question, no postamble.

**Compression discipline.** Minimize words with zero precision loss. Cut hedging,
throat-clearing and restatement — never cut a fact, a number, a caveat or an
option to be shorter. Brevity must lose words, not information.

**Engine vocabulary stays in the system.** Engine nouns — cascade, graph, edge,
`depends_on`, gate, slug, state values (`complete`), log ids, version tags — are
internal. Report the business consequence instead: "three deliverables now rest
on an outdated figure", not "the cascade flagged three nodes"; "the decision is
recorded", not the log id that was written; "all fourteen entities are finished",
not "14/14 complete". Name an id only when the reader needs it to look something
up. The contrasts stay generic on purpose: a plugin's own id format and entity
noun belong in its overlay, and a worked pair borrowed from one vertical reads to
every other as a format its engine never writes.

This section is stated here rather than delegated because it has to reach the
**main loop**. An agent-side contract carries the same three rules for the agent
path, and it is injected into a dispatched agent — never loaded here — so a
pointer to it would leave the main loop with no reachable copy. This is the
one-contract-two-delivery-paths rule at the top of this file doing its job, not a
duplication to remove.
