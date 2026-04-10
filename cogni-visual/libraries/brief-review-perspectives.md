# Brief Review Perspectives

Perspective sets for stakeholder review of visual briefs. The `brief-review-assessor` agent
selects one set based on the `brief_type` parameter and evaluates the brief against three
perspectives with five weighted criteria each.

Every visual deliverable ultimately serves an audience — the perspectives ensure the brief
works for the people who will experience the final output, not just the people who produce it.

## Perspective Sets

- [Slides (presentation-brief)](#slides)
- [Big Picture (big-picture-brief)](#big-picture)
- [Web Narrative (web-brief)](#web-narrative)
- [Storyboard (storyboard-brief)](#storyboard)
- [Big Block (big-block-brief)](#big-block)
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

## Big Picture

Big picture briefs become illustrated journey maps — large-format canvases where each station
is a landscape object telling part of the story spatially. The audience experiences these as
posters, workshop backdrops, or digital walkthroughs.

### Perspective A: Visual Storyteller (30%)

You are a visual narrative designer. You evaluate whether the brief creates a coherent visual
world where the story unfolds spatially — not just a list of topics with illustrations.

#### 1. Scene Coherence (25%)
Does the Story World work as a unified scene, or do the stations feel like separate illustrations placed on a background?
- **Pass**: Every station belongs in the same world. The metaphor (factory, cityscape, landscape) holds across all stations without forcing. Narrative connections between stations create a sense of journey.
- **Warn**: Most stations fit the Story World but 1-2 feel forced — the metaphor stretches to accommodate them.
- **Fail**: The Story World is superficial — stations are generic objects with topic labels rather than landscape elements that embody their content.

#### 2. Station Clarity (25%)
Does each station's `object_name` and description make the visual intent clear to a rendering artist?
- **Pass**: Every station has a vivid, specific object_name that implies visual form (e.g., "crumbling bridge with warning signs" not "challenge"). The 100-120 word body provides enough narrative for the artist to compose meaningful details.
- **Warn**: 1-2 stations have vague object names or thin descriptions that leave the artist guessing about visual intent.
- **Fail**: Multiple stations are abstract concepts disguised as objects. The artist would have to invent the visual meaning.

#### 3. Journey Flow (20%)
Does the left-to-right reading flow tell the story in a logical sequence?
- **Pass**: Station order follows the narrative arc naturally. The audience reads the story by walking left to right. Position numbers reinforce comprehension rather than feeling arbitrary.
- **Warn**: Generally logical but 1-2 stations could be swapped without affecting comprehension — their position isn't motivated by the narrative.
- **Fail**: Station order is arbitrary. The spatial sequence doesn't match the narrative sequence.

#### 4. Scale & Variety (15%)
Do stations vary in visual scale and complexity to create an interesting canvas?
- **Pass**: Mix of large anchor stations and smaller detail stations. No two adjacent stations have similar visual weight. The canvas would feel dynamic.
- **Warn**: Mostly uniform scale — stations feel like equal-sized cards rather than varied landscape elements.
- **Fail**: All stations have similar scale and complexity. The canvas would feel monotonous.

#### 5. Narrative Connection Quality (15%)
Do the `narrative_connection` descriptions between stations create meaningful spatial transitions?
- **Pass**: Connections describe spatial and thematic relationships ("the river flowing from Station 2's dam feeds Station 3's hydroelectric plant"). They guide the rendering artist's scene composition.
- **Warn**: Connections exist but are generic ("leads to next topic") rather than spatial/thematic.
- **Fail**: Connections are missing or purely logical ("therefore") rather than spatial.

---

### Perspective B: Target Audience (40%)

You are encountering this big picture as a poster, a workshop backdrop, or a digital walkthrough.
You evaluate whether you can understand the story by looking at it.

#### 1. Immediate Comprehension (30%)
Within 10 seconds of looking at this canvas, would you understand what it's about?
- **Pass**: The title, governing thought, and first station immediately orient you. The Story World metaphor is intuitive. You'd start exploring stations with a sense of the overall narrative.
- **Warn**: You'd understand the general topic but not the argument. The title and governing thought are clear but the station-level entry point isn't obvious.
- **Fail**: Confusing on first look. You wouldn't know where to start or what the canvas is about.

#### 2. Station Message Landing (25%)
Can you grasp each station's message from its headline and object without reading the full body text?
- **Pass**: Headlines are assertions (not topic labels). The object_name reinforces the message visually. You'd understand 80% of the story from headlines and visuals alone.
- **Warn**: Most headlines work but 1-2 are topic labels ("Digital Transformation") rather than assertions ("Legacy systems block 40% of innovation initiatives").
- **Fail**: Headlines are generic labels. You'd need to read all body text to understand the story.

#### 3. Emotional Engagement (20%)
Does the visual concept make you want to explore further?
- **Pass**: The Story World is evocative — it creates curiosity or recognition. You'd linger to explore details. The metaphor adds meaning beyond decoration.
- **Warn**: Competent but not compelling. You'd look at it but not be drawn in.
- **Fail**: Generic or confusing visual concept. You'd glance and move on.

#### 4. Professional Impression (15%)
Would you take this seriously in a business context?
- **Pass**: The canvas feels like a professional strategic communication tool. The tone is authoritative. Appropriate for boardrooms, conferences, and client workshops.
- **Warn**: Slightly informal or uneven. Mostly professional but 1-2 elements feel casual or forced.
- **Fail**: Feels like clipart or a school project. Not credible in a professional setting.

#### 5. Value Retention (10%)
After walking away, would you remember the key messages?
- **Pass**: The spatial layout and visual metaphors create memory anchors. You'd recall 3-4 key stations and their messages days later.
- **Warn**: You'd remember the overall topic but not specific stations or messages.
- **Fail**: Forgettable. The visual concept doesn't create lasting impressions.

---

### Perspective C: Workshop Facilitator (30%)

You are using this big picture as a facilitation tool — leading a group through the story,
pointing to stations, sparking discussion. You evaluate whether the canvas works as a
walkthrough and discussion anchor.

#### 1. Walkthrough-ability (30%)
Can you guide a group through this canvas station by station without losing their attention?
- **Pass**: The reading flow is intuitive. Each station transition is natural. You could walk along the canvas (physically or digitally) and the story unfolds. Body text provides enough depth for 2-3 minutes of commentary per station.
- **Warn**: Most transitions work but 1-2 require explanation ("now let's jump to..."). Body text is thin for some stations.
- **Fail**: The flow is confusing. You'd need to skip around, losing the audience.

#### 2. Discussion Anchor Quality (25%)
Do stations create natural discussion points for workshop participants?
- **Pass**: At least 3 stations contain provocative claims, diagnostic questions, or contrast points that would spark group discussion. Participants would naturally point at stations and say "but what about..."
- **Warn**: Stations present information but don't provoke. Discussion would require facilitator effort.
- **Fail**: All stations are declarative. No natural entry points for group engagement.

#### 3. Explanation Flow (20%)
Does the body text support verbal explanation without requiring verbatim reading?
- **Pass**: Body text provides talking points and key data. You can paraphrase naturally. Statistics and specifics are highlighted (number plays) so they're easy to reference while presenting.
- **Warn**: Body text reads like a document — you'd need to extract your own talking points.
- **Fail**: Body text is either too sparse for meaningful explanation or too dense to paraphrase.

#### 4. Group Adaptability (15%)
Could you adapt the walkthrough for different audience segments (executives, technical, mixed)?
- **Pass**: Stations have multiple layers — a headline for executives, body text for details, visual objects that resonate with technical and non-technical audiences.
- **Warn**: Works for one audience type but would need adaptation for others.
- **Fail**: Pitched at only one level with no flexibility for audience adjustment.

#### 5. Canvas Usability (10%)
Is the canvas practically usable in a workshop setting?
- **Pass**: 4-8 stations (manageable for a 30-60 minute walkthrough). Station sequence matches a natural facilitation arc (problem → insight → solution → action). Physical/digital navigation is intuitive.
- **Warn**: Too many stations (8+) for comfortable walkthrough, or sequence doesn't match facilitation needs.
- **Fail**: Too many stations to cover, or the sequence fights against natural facilitation flow.

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

## Big Block

Big block briefs become solution architecture diagrams — tier-banded grids showing solution
blocks, TIPS path connections, SPIs, foundations, and implementation roadmaps. The audience
uses these for investment decisions and implementation planning. These briefs are data-driven
(from TIPS value-modeler), not narrative-driven.

### Perspective A: Solution Architect (30%)

You are a solution architect evaluating whether this diagram accurately represents the solution
landscape and would serve as a credible architecture reference.

#### 1. Tier Logic (25%)
Are solutions classified into the correct Business Relevance tiers?
- **Pass**: Tier assignments match BR scores. Tier 1 (strategic) solutions are genuinely transformative. Tier 4 (foundational) solutions are genuine prerequisites. No tier inflation.
- **Warn**: 1-2 borderline classifications. Solutions near tier boundaries could reasonably be in either tier.
- **Fail**: Tier assignments feel arbitrary or marketing-driven. High-BR solutions in low tiers or vice versa.

#### 2. Connection Integrity (25%)
Do TIPS path connections between blocks represent real dependencies and synergies?
- **Pass**: Every connection maps to an actual Trend → Implication → Possibility → Solution path. Connections create a readable network — you can trace strategic themes across tiers.
- **Warn**: Most connections are clear but 1-2 seem artificially added for visual completeness.
- **Fail**: Connections are decorative rather than informative. You can't trace meaningful paths.

#### 3. Implementation Credibility (20%)
Does the wave assignment (implementation roadmap) reflect realistic sequencing?
- **Pass**: Wave 1 contains genuine quick wins and prerequisites. Wave 3 contains items that genuinely depend on Wave 1-2 outputs. The roadmap sequence is defensible.
- **Warn**: Mostly logical but 1-2 items could be resequenced without affecting the argument.
- **Fail**: Wave assignment feels arbitrary. No clear rationale for sequencing.

#### 4. Completeness (15%)
Does the diagram capture the full solution landscape from the value model?
- **Pass**: All significant solutions from the value model are represented. SPIs and foundations are present. No critical gaps.
- **Warn**: Minor solutions omitted for diagram clarity (acceptable) but documented.
- **Fail**: Significant solutions missing. The diagram misrepresents the solution landscape.

#### 5. Technical Accuracy (15%)
Are solution descriptions, portfolio mappings, and data points correct?
- **Pass**: Block labels, descriptions, and feature/proposition mappings match source data. BR scores are accurately transcribed.
- **Warn**: Minor labeling inconsistencies.
- **Fail**: Data errors — wrong BR scores, incorrect mappings, or solutions attributed to wrong TIPS paths.

---

### Perspective B: Investment Decision Maker (40%)

You are a senior leader evaluating this solution architecture to decide where to invest.
You need to understand the landscape, assess priorities, and build a business case.

#### 1. ROI Clarity (30%)
Can you understand the value of each investment tier?
- **Pass**: Each tier has a clear value narrative. You understand why Tier 1 is strategic (transformation potential) vs. Tier 4 (necessary foundation). The diagram supports "invest here first because..." reasoning.
- **Warn**: Tiers are visible but their strategic rationale isn't self-evident. You'd need an explanation.
- **Fail**: The tier structure looks like arbitrary grouping. You can't assess investment priorities from the diagram.

#### 2. Complexity Comprehension (25%)
Can you grasp the solution landscape without an architecture degree?
- **Pass**: The diagram is readable by non-technical executives. Solution blocks have business-language labels. Path connections are intuitive. You understand the landscape in under 5 minutes.
- **Warn**: Mostly accessible but some blocks or connections require technical background to interpret.
- **Fail**: The diagram is an architecture artifact, not a communication tool. Requires deep technical knowledge.

#### 3. Risk Visibility (20%)
Can you identify dependencies, bottlenecks, and risks?
- **Pass**: Foundation dependencies are clear — you can see what must be in place before strategic initiatives. Bottleneck solutions (many connections) are visually prominent. SPIs flag critical path indicators.
- **Warn**: Dependencies are present but you'd need to trace connections manually to identify risks.
- **Fail**: No risk visibility. The diagram presents solutions as independent rather than interdependent.

#### 4. Decision Support (15%)
Does the diagram provide enough structure to make investment sequencing decisions?
- **Pass**: The wave roadmap combined with tier bands gives you a clear "invest in what order" framework. You could present this to a board and defend the sequencing.
- **Warn**: The diagram informs but doesn't direct. You'd need additional analysis to make sequencing decisions.
- **Fail**: No actionable investment guidance. The diagram describes the landscape without prioritizing it.

#### 5. Confidence to Approve (10%)
Would you feel confident approving investment based on this architecture?
- **Pass**: The solution landscape feels comprehensive, the prioritization is defensible, and the implementation roadmap is realistic. You'd sign off with clarifying questions, not structural concerns.
- **Warn**: You'd approve with caveats — some areas need deeper analysis.
- **Fail**: Fundamental concerns about completeness, accuracy, or prioritization logic. You'd send it back.

---

### Perspective C: Sales Engineer (30%)

You are using this diagram in customer conversations — demo walkthroughs, solution workshops,
proposal presentations. You evaluate whether it works as a sales tool.

#### 1. Demo Flow (30%)
Can you walk a customer through this diagram in a structured way?
- **Pass**: A natural walkthrough path exists — top-down by tier, or left-right by TIPS theme, or wave-by-wave for roadmap discussions. Multiple entry points for different conversation needs.
- **Warn**: One walkthrough path works but it's the only option. Can't adapt for different conversation types.
- **Fail**: No natural walkthrough path. You'd need to jump around the diagram to tell a coherent story.

#### 2. Customer Conversation Support (25%)
Does this diagram help you answer customer questions?
- **Pass**: A customer pointing at any block gets a clear answer: what it is, why it matters, how it connects to other blocks, and when it would be implemented. The diagram anticipates customer questions.
- **Warn**: Most blocks are self-explanatory but 2-3 require supplementary explanation.
- **Fail**: The diagram creates more questions than it answers. Blocks are internally-labeled.

#### 3. Customization Points (20%)
Can you adapt this diagram for different customer scenarios?
- **Pass**: The tier/wave structure naturally supports "for your situation, focus on these blocks" conversations. Foundation vs. strategic distinction enables maturity-based recommendations.
- **Warn**: The diagram is fixed — useful as an overview but hard to customize per customer.
- **Fail**: No flexibility. The diagram presents one path for all customers.

#### 4. Competitive Differentiation (15%)
Does the diagram implicitly differentiate from competitors?
- **Pass**: Solution groupings, TIPS path connections, or implementation approach are unique enough that a competitor couldn't present the same diagram. The architecture reflects distinctive methodology.
- **Warn**: The solution categories are standard but the connections or sequencing add some differentiation.
- **Fail**: Generic solution architecture. Any systems integrator could present identical categories.

#### 5. Proposal Integration (10%)
Can this diagram serve as the architecture page in a proposal?
- **Pass**: Professional enough for client-facing proposals. Labels are customer-friendly. The diagram tells a story, not just displays data. Would enhance a proposal's credibility.
- **Warn**: Needs cleanup before including in a proposal — some internal terminology or dense labeling.
- **Fail**: Internal artifact only. Not presentable to customers without significant rework.

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
Is the information density appropriate for a single-page scan?
- **Pass**: 4-8 content blocks. Each block carries one idea. No block requires more than 3 seconds to absorb. Total word count under 150.
- **Warn**: Slightly dense — 1-2 blocks could be simplified or merged.
- **Fail**: Overloaded. More than 8 content blocks, or blocks with text walls. Fails the 10-second scan test.

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
| **Big Picture** | Story World coherence overrides individual station quality — one weak station in a strong world is better than strong stations in a forced metaphor |
| **Web** | Hook/opening section is sacred — if Audience flags the opening as weak, that's automatically CRITICAL regardless of other perspectives |
| **Storyboard** | Readability at distance overrides information density — if Print Designer flags readability, that's HIGH minimum even if content is strong |
| **Infographic** | 10-second comprehension is sacred — if Target Audience fails to understand the core message in 10 seconds, that's automatically CRITICAL regardless of design quality |
| **Big Block** | Technical accuracy is non-negotiable — Solution Architect failures on tier logic or connection integrity are automatically CRITICAL |

### Priority Tiers

- **CRITICAL**: Flagged by all 3 perspectives, OR Audience perspective scores fail on highest-weight criterion, OR type-specific auto-escalation (see above)
- **HIGH**: Flagged by 2 of 3 perspectives, OR affects a criterion weighted 25%+
- **OPTIONAL**: Single perspective, low-weight criterion (10-15%)
