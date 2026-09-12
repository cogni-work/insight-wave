---
library_id: brief-conventions
version: 1.0.0
created: 2026-09-05
updated: 2026-09-05
---

# Brief Conventions

The conventions a brief of any of the four types — presentation, web, storyboard, infographic — follows, whoever writes it. They were consolidated from the three `story-to-*` producers that once wrote briefs here; those producers have retired, so a brief now arrives hand-authored against the templates and `EXAMPLE_*_BRIEF.md` files in this directory, or supplied by a caller, and the render chain reads it against these rules. The rule text lives here once. Where the three former copies differed, the stronger variant was kept and is marked.

## Interactive checkpoints

Interactive prompts let the user steer creative decisions at a few named points without micromanaging. Every prompt uses the structured AskUserQuestion format — unstructured prose renders as an empty prompt:

```
questions: [{
  question: "Your question here?",
  header: "Short Label",
  options: [
    { label: "Option Name", description: "What this means" },
    { label: "Another Option", description: "What this means" }
  ],
  multiSelect: false
}]
```

**On an empty or blank response, auto-select the best option and move on.** Never retry AskUserQuestion on an empty response. When `interactive` is `false`, skip every AskUserQuestion call and take the same auto-selection. (The never-retry clause came from the infographic copy; the other two had only the auto-select rule.)

## German fidelity

German briefs go to executives — as decks, embedded web narratives, printed posters and shared infographics. ASCII-ified umlauts (`ae`/`oe`/`ue`) immediately signal "machine-generated" and undermine credibility. Use real Unicode throughout the generated copy: ae→ä oe→ö ue→ü ss→ß. German number formatting: 2.661 (dot as thousands separator). Always state the language explicitly in the brief frontmatter.

This rule governs generated output copy only — headlines, body text, section and block labels, and CTA text. It does not govern filenames, slugs, or other machine identifiers, which transliterate umlauts deliberately. It also does not govern the trigger phrases in a skill's frontmatter description, where any ASCII spellings are deliberate: a user on a non-German keyboard types them that way, so respelling one silently drops German triggering coverage. Leave the frontmatter block unchanged when correcting umlauts anywhere else in a SKILL.md. (The carve-out paragraph came from the slides and web copies; the explicit-language sentence from the infographic copy.)

## Theme-driven visuals

The renderer owns all visual decisions — colors, fonts, spacing — by reading the theme directly. Briefs specify content and layout only. Omit every color and styling field — `Background:`, `Text-Color:`, `Icon-Color:`, `Role:`, `Intensity:`, `Mood:` — because the renderer ignores them and their presence creates ambiguity about who controls styling. The nested `intent.role` key of a 4.1 presentation brief is a different, permitted key and is not covered by this prohibition. `scripts/check-brief.py` (`no-color-fields`) rejects a brief that carries any of them; the web and infographic profiles add that format's own styling keys (`fill`, `color`, `background`, `textColor`; `Fill`, `Border-Color`). (The six-field list and the `intent.role` carve-out came from the slides copy; the web and infographic copies named three.)

## Good vs bad output

**Headlines** — assert, don't label:
- Bad: "Our Approach" (topic label — the reader must read the body to get the point)
- Good: "AI-Powered Monitoring Cuts Response Time from Hours to Seconds" (assertion — the message lands instantly)

**Number plays** — reframe for impact:
- Bad: "There were 688 incidents in 2023" (buried in body text)
- Good: hero number `688` isolated, sublabel `+ 2,661 related events`, supporting text explains scale

**Bullets** — scan-optimized, not sentences:
- Bad: "The security staff are unable to adequately cover all areas of the network on a 24/7 basis" (19 words)
- Good: "Staff cannot cover all areas 24/7" (6 words, max 10 words per bullet)

**CTAs** — imperative verb, not passive label:
- Bad: "Contact Us" (generic, no urgency)
- Good: "Schedule Your Security Assessment" (specific action tied to the conversion goal)

(The four-pair set came from the web copy; the slides skill keeps a longer, slide-specific version in its `05a-slide-copywriting.md`.)

## Printed paths are absolute

Every path printed to the user — in a hand-off box, a rendering prompt, or a response — is absolute. Never `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT` or a relative path: the receiving session has no access to this session's variables. That governs printed paths only; `$CLAUDE_PLUGIN_ROOT` remains the correct way to invoke a bundled script or read a bundled file.
