# Brief Review Perspectives

Perspective sets for stakeholder review of visual briefs. The `brief-review-assessor` agent
selects one set based on the `brief_type` parameter and evaluates the brief against three
perspectives with five weighted criteria each.

Every visual deliverable ultimately serves an audience — the perspectives ensure the brief
works for the people who will experience the final output, not just the people who produce it.

## Perspective Sets

- [Slides (presentation-brief)](#slides)
- [Web Narrative (web-brief)](#web-narrative)
- [Storyboard (storyboard-brief)](#storyboard)
- [Infographic (infographic-brief)](#infographic)

---

## Slides

Presentation briefs become slide decks that a person presents to an audience. Three failure
modes to catch: poor visual communication (Designer), audience disengagement (Audience),
and presenter inability to deliver (Presenter).

### Perspective A: Communication Designer (30%)

You are a presentation design strategist. You evaluate whether the brief's slide architecture
communicates effectively as a visual medium — not whether the content is correct (that's the
narrative's job), but whether the brief translates it into slides that work.

#### 1. Slide Flow & Sequencing (25%)
Does the slide sequence build an argument, or is it a reshuffled document?
- **Pass**: Each slide clearly follows from the previous. The governing thought is established early and supported progressively. No slide feels out of place.
- **Warn**: 1-2 slides could be reordered without anyone noticing — they don't depend on what came before.
- **Fail**: The sequence reads like a list of topics rather than an argument. Slides could be shuffled without changing comprehension.

#### 2. Layout Variety (25%)
Does the brief use different layout types to match different message types, or does every slide use the same template?
- **Pass**: Layout types vary appropriately — hero numbers get number-highlight layouts, comparisons get split layouts, evidence gets chart layouts. No more than 2 consecutive slides share a layout type.
- **Warn**: Some monotony — 3+ consecutive slides share a layout type, or a layout type is used where another would serve the message better.
- **Fail**: Dominant layout (60%+ of slides use the same type). The brief treats layout selection as an afterthought rather than a communication decision.

#### 3. Information Hierarchy (20%)
Does each slide have a clear primary message, or are messages competing for attention?
- **Pass**: Every slide has one assertion headline, supported by 2-4 pieces of evidence. Hero numbers are isolated. No slide tries to convey more than one main idea.
- **Warn**: 1-2 slides pack too much — competing messages, dense bullet lists (5+ items), or evidence that overshadows the headline.
- **Fail**: Multiple slides are overloaded. Headlines are topic labels rather than assertions. Evidence and message are indistinguishable.

#### 4. Visual Rhythm (15%)
Does the brief create pacing variety — high-density evidence slides broken by breathing room?
- **Pass**: Dense data slides are followed by simpler slides (hero number, image, quote). No 3+ consecutive high-density slides.
- **Warn**: Minor pacing issues — 3 consecutive dense slides, or breathing room concentrated in one section.
- **Fail**: Uniformly dense throughout, or uniformly sparse. No rhythm.

#### 5. CTA & Closing Architecture (15%)
Does the brief end with a clear call to action that the presentation structure supports?
- **Pass**: Final slides build toward a specific CTA. The CTA is concrete (not "contact us") and the preceding slides provide the evidence needed to act.
- **Warn**: CTA exists but feels bolted on — the preceding slides don't build toward it.
- **Fail**: No clear CTA, or the presentation ends with a summary slide rather than a forward-looking action.

---

### Perspective B: Target Audience (40%)

You are the person sitting in the audience. You've seen hundreds of presentations. Your
attention is earned, not given. You evaluate whether this brief would keep you engaged and
leave you with a clear understanding.

#### 1. Message Clarity (30%)
After experiencing this presentation, could you explain the core argument to a colleague in one sentence?
- **Pass**: The governing thought is unmistakable. Every slide contributes to it. You'd leave knowing exactly what was said and why it matters.
- **Warn**: The overall message is discernible but some slides feel tangential. You'd leave with a general sense but might struggle to articulate the core argument crisply.
- **Fail**: No clear through-line. Individual slides make sense but don't accumulate into a coherent argument. You'd leave unsure what the main point was.

#### 2. Relevance & Resonance (25%)
Does this presentation speak to problems and opportunities you actually care about?
- **Pass**: The challenges and opportunities described match your reality. The language feels like it was written by someone who understands your context, not by someone who read a market report.
- **Warn**: Directionally relevant but uses generic abstractions. You recognize the space but don't feel personally addressed.
- **Fail**: Disconnected from your reality. Generic industry platitudes or problems you don't have.

#### 3. Evidence Credibility (20%)
Do the claims feel grounded, or does this feel like marketing?
- **Pass**: Key claims are supported by specific evidence — numbers with sources, concrete examples, named methodologies. Number plays make statistics memorable without distorting them.
- **Warn**: Some claims feel unsupported. Round numbers without attribution. Evidence exists but isn't woven into the narrative.
- **Fail**: Multiple unsupported claims. Hyperbolic language. You'd mentally flag several statements as "I'd need to verify that."

#### 4. Engagement Hooks (15%)
Does the presentation have moments that recapture attention — contrasts, surprises, provocations?
- **Pass**: At least 2-3 slides create a "lean forward" moment — an unexpected contrast, a striking number, a provocative question. The narrative has tension, not just information.
- **Warn**: Information is well-organized but flat. No surprises. You'd follow along but not be energized.
- **Fail**: Monotone information delivery. No emotional or intellectual hooks. Your mind would wander.

#### 5. Decision Enablement (10%)
Does this presentation equip you to take a next step or make a decision?
- **Pass**: You leave knowing what to do next, with enough evidence to justify that action internally. The ask is clear and the supporting data is sufficient.
- **Warn**: You're interested but would need a follow-up conversation before acting.
- **Fail**: Informative but not actionable. You learned something but have no clear path forward.

---

### Perspective C: Presenter (30%)

You are the person who will stand up and deliver this presentation. You evaluate whether the
brief gives you confidence to present — clear talking points, manageable complexity, and a
narrative you can own.

#### 1. Narrative Flow (30%)
Can you walk through these slides without losing the thread?
- **Pass**: The slide sequence tells a story you can narrate naturally. Transitions between slides are obvious. You wouldn't need to say "and now, moving on to..."
- **Warn**: Most transitions work but 1-2 feel forced. You'd need to rehearse those transitions specifically.
- **Fail**: The sequence doesn't flow as a spoken narrative. You'd need to create your own bridging material between multiple slides.

#### 2. Speaker Note Quality (25%)
Do the speaker notes give you enough to present confidently without being a script?
- **Pass**: Notes provide the key talking point and 1-2 supporting details per slide. They tell you what to emphasize, not what to read aloud.
- **Warn**: Notes exist but are either too sparse (just the headline restated) or too dense (full paragraphs that tempt reading verbatim).
- **Fail**: Missing notes, or notes that are copy-pasted prose rather than presentation-ready talking points.

#### 3. Complexity Management (20%)
Is each slide simple enough to explain in 60-90 seconds?
- **Pass**: Every slide can be delivered in under 90 seconds. Complex topics are split across multiple slides rather than crammed into one.
- **Warn**: 1-2 slides would take 2+ minutes to explain properly — too much content for a single slide.
- **Fail**: Multiple slides require extended explanation. The brief hasn't translated document complexity into presentation-appropriate chunks.

#### 4. Audience Interaction Points (15%)
Does the brief create natural moments for audience engagement?
- **Pass**: At least 1-2 slides naturally invite questions or discussion — provocative claims, diagnostic questions, comparison frameworks.
- **Warn**: The presentation is self-contained but doesn't create obvious discussion openings.
- **Fail**: Wall-to-wall content with no breathing room for audience interaction.

#### 5. Confidence to Present (10%)
Would you feel confident presenting this deck to a senior audience?
- **Pass**: Every claim is defensible. No slide makes you think "I hope they don't ask about this." The narrative feels authoritative without overreaching.
- **Warn**: 1-2 claims you'd want to verify or soften before presenting. Minor discomfort.
- **Fail**: Multiple claims you can't defend, or a narrative that overpromises. You'd want significant changes before presenting.

---

## Web Narrative

Web briefs become scrollable landing pages rendered via Pencil MCP. The audience experiences
these as web pages — they scroll, they skim, they decide in seconds whether to continue.

### Perspective A: UX Designer (30%)

You are a web experience designer. You evaluate whether the brief creates an effective scroll
experience that guides the user through the narrative.

#### 1. Scroll Flow (25%)
Does the section sequence create a natural scroll experience?
- **Pass**: Each section motivates scrolling to the next. The brief creates a "just one more section" pull. Opening section hooks immediately, closing section delivers the payoff.
- **Warn**: Most sections connect but 1-2 feel like interruptions in the flow.
- **Fail**: Sections feel like stacked cards rather than a flowing experience. No scroll momentum.

#### 2. Section Pacing (25%)
Does the brief vary section density and type to prevent fatigue?
- **Pass**: Alternation between high-density (feature grids, data) and breathing-room sections (hero images, quotes, CTAs). No 3+ consecutive dense sections.
- **Warn**: Some monotony — similar section types clustered together.
- **Fail**: Uniformly dense or uniformly sparse. No rhythm in the scroll experience.

#### 3. CTA Effectiveness (20%)
Are CTAs placed at moments of maximum motivation?
- **Pass**: Primary CTA follows the strongest evidence section. Secondary CTAs appear at natural decision points. CTAs are specific ("Start your 2-week pilot" not "Learn more").
- **Warn**: CTAs exist but placement is mechanical (end only) rather than strategic.
- **Fail**: No clear CTA, or CTA placed before the value case is made.

#### 4. Visual Hierarchy per Section (15%)
Does each section have a clear visual hierarchy within its layout type?
- **Pass**: Headlines are assertions, subtext provides context, evidence supports. Image prompts complement rather than decorate. Section types match content (features → feature grid, statistics → number highlight).
- **Warn**: 1-2 sections use a layout type that doesn't match their content purpose.
- **Fail**: Multiple sections have mismatched layout types or competing visual elements.

#### 5. Mobile Consideration (15%)
Would this brief work on smaller screens?
- **Pass**: Section types selected are responsive-friendly. No section depends on side-by-side comparison that breaks on mobile. Text lengths work for narrow viewports.
- **Warn**: 1-2 sections would degrade on mobile but core experience preserved.
- **Fail**: Multiple sections rely on wide layouts that would break the experience on mobile.

---

### Perspective B: Target Audience (40%)

You landed on this page — maybe from a search, a LinkedIn post, or a colleague's link.
You'll give it 5 seconds to earn your attention. You evaluate whether this brief would
keep you scrolling.

#### 1. Hook & Opening (30%)
Does the first section earn 5 more seconds of attention?
- **Pass**: The hero section makes an assertion that speaks to a problem you have. You immediately understand what this page will deliver and why it matters to you.
- **Warn**: The opening is professional but generic. You'd keep reading but without urgency.
- **Fail**: The opening is about the company, not about you. Self-congratulatory or jargon-heavy. You'd bounce.

#### 2. Value Clarity (25%)
As you scroll, can you easily extract what's being offered and why it matters?
- **Pass**: Each section passes the "so what?" test. Feature sections lead with outcomes, not capabilities. You understand the value without effort.
- **Warn**: Some sections describe features rather than outcomes. You understand what it does but not always why you should care.
- **Fail**: The page reads like a product specification. Technical accuracy without business relevance.

#### 3. Credibility (20%)
Do you trust what this page claims?
- **Pass**: Evidence is specific and attributed. Social proof feels authentic. Statistics are contextualized (not just big numbers). You'd share this page with a colleague without caveats.
- **Warn**: Some claims feel unsupported. Evidence exists but could be stronger.
- **Fail**: Marketing hype. Superlatives without substance. You'd mentally discount everything by 50%.

#### 4. Professional Impression (15%)
Does this page represent a company you'd want to work with?
- **Pass**: The page feels like a serious business communication. Authoritative tone, clean structure, no desperation signals (excessive CTAs, urgency manipulation, buzzword density).
- **Warn**: Mostly professional but uneven — some sections feel salesy while others feel consultative.
- **Fail**: Feels like a template. Generic enough to belong to any company. No distinctive voice.

#### 5. Conversion Path (10%)
Does this page make you want to take the next step?
- **Pass**: By the time you reach the CTA, the case has been made. You understand exactly what the next step is and why it's worth your time.
- **Warn**: You're interested but the CTA is vague or the leap from reading to acting is too large.
- **Fail**: No compelling reason to act. Interesting read but no forward momentum.

---

### Perspective C: Content Strategist (30%)

You are responsible for the content ecosystem this page lives in. You evaluate whether the
brief creates a page that performs — drives traffic, captures leads, builds authority.

#### 1. Strategic Fit (25%)
Does this page serve a clear purpose in the content funnel?
- **Pass**: The page has a defined funnel position (awareness, consideration, decision). Content depth and CTA specificity match that position. The page complements rather than duplicates other content.
- **Warn**: The page tries to serve multiple funnel stages, diluting effectiveness at any single stage.
- **Fail**: No clear strategic purpose. Content exists for its own sake.

#### 2. Shareability (25%)
Would someone share this page or reference it in conversation?
- **Pass**: At least 2-3 sections contain insights, statistics, or frameworks worth sharing. The page has standalone value beyond product promotion.
- **Warn**: Useful but not remarkable. Someone might bookmark it but wouldn't actively share.
- **Fail**: Pure product page. No thought leadership value. Nobody shares vendor product pages.

#### 3. Brand Consistency (20%)
Does the voice and positioning align with how the company presents itself elsewhere?
- **Pass**: Consistent tone throughout. Claims align with portfolio propositions. No positioning conflicts with other company materials.
- **Warn**: Minor tone shifts between sections. Mostly consistent but not seamless.
- **Fail**: Voice feels disconnected from company positioning. Or makes claims that contradict other materials.

#### 4. SEO & Discovery (15%)
Does the content structure support organic discovery?
- **Pass**: Headlines use natural language (not marketing-speak). Key concepts appear early. Section structure maps to likely search intents. Content depth supports topic authority.
- **Warn**: Content is good but headlines are clever rather than descriptive. Discovery depends on direct traffic.
- **Fail**: Headlines are internally-referencing slogans. Content structure doesn't match how people search for this topic.

#### 5. Lead Capture Integration (15%)
Does the brief create natural lead capture opportunities?
- **Pass**: Value-first content gates (download a framework, access a diagnostic, join a webinar) that offer genuine value in exchange for engagement.
- **Warn**: Only one CTA at the end. Missed opportunities for mid-page engagement.
- **Fail**: No lead capture mechanism, or gate-before-value approach that feels extractive.

---

## Storyboard

Storyboard briefs become multi-poster print sequences — typically 3-5 portrait posters displayed
side by side for executive walkthroughs. The audience experiences these physically, walking
along the poster wall.

### Perspective A: Print Designer (30%)

You are a print communication designer. You evaluate whether the brief creates posters that
work as physical objects — readable at distance, visually balanced, effective in print.

#### 1. Poster Composition (25%)
Does each poster have a clear visual hierarchy within its 1-3 stacked sections?
- **Pass**: Each poster has a dominant section (hero) and supporting sections. Visual weight is balanced. The poster reads top-to-bottom naturally.
- **Warn**: 1-2 posters have competing sections of equal weight — no clear visual entry point.
- **Fail**: Posters feel like stacked rectangles rather than composed pages. No visual hierarchy.

#### 2. Density Balance (25%)
Is information density appropriate for the poster position in the sequence?
- **Pass**: Opening poster is lighter (hero, governing thought). Middle posters carry the evidence. Closing poster is action-oriented. Density varies with narrative purpose.
- **Warn**: Uniform density across all posters. No pacing.
- **Fail**: Opening poster is as dense as evidence posters, or closing poster introduces new complexity instead of driving action.

#### 3. Readability at Distance (20%)
Would headlines and key messages be readable from 2-3 meters away?
- **Pass**: Headlines are concise (under 8 words). Section types selected support large text and clear visual elements. Key statistics are isolated as hero numbers.
- **Warn**: Most headlines work at distance but 1-2 are too long or require reading body text to understand.
- **Fail**: Headlines are full sentences. Key messages are buried in body text. The poster fails the "hallway test" — you can't grasp the message while walking past.

#### 4. Visual Consistency (15%)
Do the posters feel like a coherent set?
- **Pass**: Consistent section types, visual rhythm, and information density across the series. The posters clearly belong together as a sequence.
- **Warn**: Mostly consistent but 1 poster feels different in style or density.
- **Fail**: Posters look like they were designed independently. No visual thread connecting the series.

#### 5. Print Constraints (15%)
Does the brief respect portrait format and print limitations?
- **Pass**: Section types selected work in portrait orientation. No reliance on interactive elements, animations, or hover states. Content fits the poster count without cramming.
- **Warn**: 1-2 sections would need adaptation for portrait format.
- **Fail**: Section types selected are designed for landscape/web and would look wrong in portrait print.

---

### Perspective B: Target Audience (40%)

You are walking along a poster wall in a conference room, office hallway, or executive briefing
center. You evaluate whether the poster sequence tells a clear story as you walk.

#### 1. Walkthrough Comprehension (30%)
Can you understand the full story by walking left to right along the poster wall?
- **Pass**: Each poster builds on the previous. The story has a clear beginning (problem/context), middle (evidence/insight), and end (action/resolution). You arrive at the last poster understanding the complete argument.
- **Warn**: The overall story is clear but 1-2 transitions between posters feel disconnected.
- **Fail**: Posters feel like independent topics. Walking the wall doesn't build a cumulative understanding.

#### 2. Professional Impression (25%)
Do these posters represent credible, senior-level strategic communication?
- **Pass**: The poster series looks like it belongs in a Fortune 500 boardroom. Evidence is specific, tone is authoritative, claims are grounded.
- **Warn**: Mostly professional but 1-2 elements feel informal or underdeveloped.
- **Fail**: Looks like an internal draft rather than a finished deliverable. Not credible for external audiences.

#### 3. Information Retention (20%)
After walking the poster wall, would you remember the 3-4 key messages?
- **Pass**: Hero numbers, assertion headlines, and visual anchors create memory hooks. You'd recall the key statistics and core argument without notes.
- **Warn**: You'd remember the overall theme but not specific messages or data points.
- **Fail**: Information overload or underload — either too much to retain or too little to remember.

#### 4. Engagement Arc (15%)
Does the poster sequence create and resolve narrative tension?
- **Pass**: The opening poster creates urgency (problem, disruption, opportunity). Middle posters build evidence and insight. The closing poster resolves with a clear path forward.
- **Warn**: Information is well-organized but emotionally flat. No tension, no resolution.
- **Fail**: No arc. Posters present information in parallel rather than building a cumulative argument.

#### 5. Standalone Poster Value (10%)
Does each poster work individually (for someone who sees only one)?
- **Pass**: Each poster has enough context to make sense independently. The arc position (1/4, 2/4...) and poster headline orient the viewer even without the full sequence.
- **Warn**: Most posters work standalone but 1-2 require the previous poster for context.
- **Fail**: Posters are meaningless without the full sequence. No standalone comprehension.

---

### Perspective C: Exhibition Presenter (30%)

You are leading a group along the poster wall, presenting each poster and fielding questions.
You evaluate whether the storyboard supports live presentation.

#### 1. Physical Flow (30%)
Does the poster sequence support walking and presenting simultaneously?
- **Pass**: Each poster takes 3-5 minutes to present. Total walkthrough fits a 20-30 minute slot. Natural pause points between posters for questions.
- **Warn**: Some posters are too dense (8+ minutes) or too thin (under 2 minutes). Pacing is uneven.
- **Fail**: Total content exceeds 45 minutes, or some posters have too little to discuss.

#### 2. Discussion Anchor Quality (25%)
Do posters create moments for audience engagement?
- **Pass**: At least 2 posters contain provocative claims, diagnostic frameworks, or comparison data that naturally invite questions and discussion.
- **Warn**: Posters are informative but declarative. Discussion requires facilitator initiative.
- **Fail**: All posters are one-way information delivery. No hooks for engagement.

#### 3. Explanation Ease (20%)
Can you present each poster without reading from it?
- **Pass**: Headlines tell the story. Key data is visually prominent. You can point at visual elements and talk, rather than reading text aloud.
- **Warn**: Some sections require reading body text to convey the message.
- **Fail**: Posters are text-heavy. Presenting them means reading from the wall.

#### 4. Audience Adaptability (15%)
Can you adjust the walkthrough depth for different audiences?
- **Pass**: Each poster supports a 2-minute executive flyover OR a 5-minute detailed discussion. Multiple depth layers are available (headline, visual, body text, data).
- **Warn**: Works at one depth level. Executives would find it too detailed, or technical audiences too shallow.
- **Fail**: Locked into one presentation style with no flexibility.

#### 5. Q&A Readiness (10%)
Do the posters help you anticipate and handle audience questions?
- **Pass**: Evidence is specific enough to defend. No claims that would trigger "where does that number come from?" without an answer available. Data sources are referenced.
- **Warn**: 1-2 claims you'd want to verify before presenting. Minor vulnerability.
- **Fail**: Multiple indefensible claims or gaps that would undermine credibility when questioned.

---

---

## Infographic

Infographic briefs become single-page visual summaries rendered as self-contained HTML. The
audience scans these in 10 seconds — they glance at the hero number, read the title, absorb
2-3 supporting elements, and decide whether to act.

### Perspective A: Information Designer (30%)

You are a data visualization and information design specialist. You evaluate whether the brief
creates an effective visual hierarchy that communicates its message at a glance.

#### 1. Visual Hierarchy (25%)
Does the infographic have a clear scan path (title → hero number → supporting blocks → CTA)?
- **Pass**: The eye naturally follows a hierarchy. Hero numbers dominate, supporting blocks reinforce, nothing competes for primary attention.
- **Warn**: Mostly clear but 1-2 blocks compete for attention or feel equally weighted when they shouldn't be.
- **Fail**: No clear hierarchy. All blocks feel equal. The viewer doesn't know where to look first.

#### 2. Data-Ink Ratio (25%)
Is every visual element earning its place, or is there decorative noise?
- **Pass**: Every block carries information. No decorative elements without purpose. Word limits respected. Icons clarify rather than decorate.
- **Warn**: 1-2 blocks feel like filler — they don't add to the message.
- **Fail**: Multiple blocks are decorative rather than informative. Text walls where numbers should be. Icons that don't clarify.

#### 3. Layout Appropriateness (20%)
Does the selected layout type match the content pattern?
- **Pass**: Layout type is the natural fit for this content. Stat-heavy content gets stat-heavy layout. Processes get timeline-flow. The layout amplifies the message.
- **Warn**: Layout works but isn't optimal — a different layout type would serve this content better.
- **Fail**: Layout type contradicts the content. Process content in a hub-spoke layout. Data content in a list-grid.

#### 4. Block Density (15%)
Is the information density appropriate for this brief's style preset?
Resolve the block-count and word-count ceiling from the brief's `style_preset` frontmatter
field against the Content Density table in
`libraries/infographic-style-presets.md`. The dense `economist` preset and
the standard presets carry different budgets, so judge against the resolved ceiling, not a
fixed number.
- **Pass**: At least 3 content blocks and within the resolved block ceiling. Each block carries one idea. Total word count within the resolved word ceiling.
- **Warn**: Slightly dense — 1-2 blocks could be simplified or merged.
- **Fail**: Over the resolved block ceiling for this preset, or blocks with text walls. Fails the preset's scan/read test.

#### 5. Number Presentation (15%)
Are statistics formatted for maximum visual impact?
- **Pass**: Hero numbers are isolated in KPI cards. Numbers are ratio-framed for visceral impact. Before/after deltas are explicit. No numbers buried in prose.
- **Warn**: Numbers are present but not optimally formatted. Some could be more impactful with different framing.
- **Fail**: Numbers buried in text blocks. No hero number isolation. Statistics presented as prose rather than data.

---

### Perspective B: Target Audience (40%)

You've received this infographic — maybe in an email, on a screen in a meeting room, or
printed on a handout. You'll give it 10 seconds. You evaluate whether it communicates its
message in that window.

#### 1. 10-Second Comprehension (30%)
After 10 seconds of scanning, do you understand the core message?
- **Pass**: You know the topic, the main claim, and one supporting fact within 10 seconds. The title is an assertion. The hero number anchors the claim.
- **Warn**: You get the topic but the main claim is unclear. You'd need to read more carefully.
- **Fail**: After 10 seconds you're still figuring out what this infographic is about.

#### 2. Credibility (25%)
Do you trust what this infographic claims?
- **Pass**: Numbers are specific and sourced. Claims are assertions, not hype. The source line provides attribution. You'd forward this to a colleague.
- **Warn**: Some claims feel unsupported. Numbers are round or feel estimated.
- **Fail**: Marketing hype. Superlatives without evidence. You'd mentally discount everything.

#### 3. Relevance (20%)
Does this infographic speak to a problem or opportunity you care about?
- **Pass**: The title addresses a business problem. The data is contextually relevant. You understand why this matters to you.
- **Warn**: Informative but the "so what" isn't immediate. You understand the data but not why you should care.
- **Fail**: The infographic is about the provider, not about your problem. Self-congratulatory.

#### 4. Professional Impression (15%)
Does this look like a credible business communication?
- **Pass**: Clean, authoritative, appropriate style for the context. You'd share it externally without caveats.
- **Warn**: Mostly professional but 1-2 elements feel casual or draft-quality.
- **Fail**: Looks like a template. Not credible for external distribution.

#### 5. Action Clarity (10%)
Do you know what to do next?
- **Pass**: The CTA is clear, specific, and follows naturally from the evidence presented.
- **Warn**: CTA exists but is vague ("Learn more") or disconnected from the content.
- **Fail**: No clear next step. Informative but no forward momentum.

---

### Perspective C: Digital Producer (30%)

You are responsible for producing and distributing this infographic across channels — email,
social media, print handouts, internal decks. You evaluate whether the brief produces a
deliverable that works across these contexts.

#### 1. Rendering Feasibility (30%)
Can the renderer produce this infographic without issues?
- **Pass**: Block types are standard. Chart data is valid. Icon prompts are specific enough for SVG generation. No exotic rendering requirements.
- **Warn**: 1-2 blocks might need manual adjustment after rendering.
- **Fail**: Block combinations that the renderer can't handle. Invalid chart data. Vague icon prompts.

#### 2. Multi-Channel Adaptability (25%)
Would this infographic work across email, social media, and print?
- **Pass**: Content fits a single-page format. Text is readable at various scales. No dependency on interactivity. Print-friendly color contrast.
- **Warn**: Works in primary channel but would need adaptation for others.
- **Fail**: Only works in one specific medium. Too wide for mobile. Colors that print poorly.

#### 3. Brand Consistency (20%)
Does the style preset and content tone match the brand and context?
- **Pass**: Style preset matches the distribution context. Consistent tone throughout. Theme colors used appropriately.
- **Warn**: Mostly consistent but 1-2 elements feel off-brand.
- **Fail**: Style preset contradicts the brand context. Workshop-style infographic for a board meeting.

#### 4. Shareability (15%)
Would someone share, screenshot, or reference this infographic?
- **Pass**: At least 1-2 data points are share-worthy. The title is compelling enough to caption a social post. The infographic has standalone value.
- **Warn**: Useful but not remarkable. You'd save it but not actively share.
- **Fail**: No standalone value. Only useful in the context where it was created.

#### 5. Maintenance (10%)
Can this infographic be updated when data changes?
- **Pass**: Block structure is clean. Numbers and sources are clearly identified. Updating a quarter's data wouldn't require restructuring.
- **Warn**: Mostly updatable but some data points are embedded in prose rather than in structured blocks.
- **Fail**: Data is woven into narrative text. Updating requires rewriting multiple blocks.

---

## Conflict Resolution

When perspectives disagree, use these tiebreakers:

### Universal Rules (All Brief Types)

| Conflict | Resolution |
|----------|------------|
| Audience says "I don't understand"; Designer says "the structure is correct" | **Audience wins** — a structurally perfect brief that the audience can't follow has failed its purpose |
| Designer flags visual monotony; Audience says "I don't notice" | **Designer wins** — layout fatigue is real even when not consciously registered; varied layouts maintain attention over time |
| Presenter/Facilitator says "I can't explain this"; Designer says "it's the optimal layout" | **Presenter/Facilitator wins** — if the human delivering the content can't work with it, the design failed regardless of theoretical optimality |
| Two perspectives flag the same issue | **Escalate to HIGH** — cross-perspective agreement signals a real problem |
| All three perspectives flag the same issue | **Escalate to CRITICAL** — unanimous concern must be addressed |

### Type-Specific Rules

| Brief Type | Rule |
|-----------|------|
| **Slides** | Presenter confidence overrides Design elegance — claims the presenter can't defend in front of a senior audience must be softened or sourced |
| **Web** | Hook/opening section is sacred — if Audience flags the opening as weak, that's automatically CRITICAL regardless of other perspectives |
| **Storyboard** | Readability at distance overrides information density — if Print Designer flags readability, that's HIGH minimum even if content is strong |
| **Infographic** | 10-second comprehension is sacred — if Target Audience fails to understand the core message in 10 seconds, that's automatically CRITICAL regardless of design quality |

### Priority Tiers

- **CRITICAL**: Flagged by all 3 perspectives, OR Audience perspective scores fail on highest-weight criterion, OR type-specific auto-escalation (see above)
- **HIGH**: Flagged by 2 of 3 perspectives, OR affects a criterion weighted 25%+
- **OPTIONAL**: Single perspective, low-weight criterion (10-15%)
