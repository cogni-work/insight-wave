# Course 7: Visual Deliverables

**Duration**: 45 minutes | **Modules**: 5 | **Prerequisites**: Course 3
**Plugin**: cogni-visual
**Audience**: Consultants creating presentations and visual outputs

---

## Module 1: Visual Deliverable Types

### Theory (3 min)

**cogni-visual** transforms polished narratives and content into visual
deliverables. Six output types:

| Type | Format | Best For |
|------|--------|----------|
| Presentation Brief | Structured outline | Planning slide content before designing |
| Slide Deck | .pptx | Client presentations, board meetings |
| Big Picture Journey Map | Excalidraw | Strategic overviews, process visualization |
| Scrollable Web Narrative | HTML | Interactive online reports |
| Poster Storyboard | Visual layout | Print materials, event displays |
| Visual Assets | Various | Icons, diagrams, supporting graphics |

**Three rendering engines**:
- **PowerPoint (PPTX)** — Traditional slide decks
- **Excalidraw** — Hand-drawn style diagrams and journey maps
- **HTML/Web** — Interactive scrollable narratives

**Theme integration**: All visual outputs use the workspace theme (Course 2)
for consistent branding — colors, fonts, and layout follow your theme settings.

### Demo

Walk through the deliverable types:
1. Show examples of each type (or describe with visual language)
2. Explain when to use each format
3. Show how the same content appears in different formats
4. Point out theme application in each output

### Exercise

Ask the user to:
1. Think of their last client presentation
2. Which deliverable type would have been most effective?
3. Which format would they use for: (a) a board meeting, (b) a workshop, (c) an online report?

### Quiz

1. **Multiple choice**: Which rendering engine produces hand-drawn style diagrams?
   - a) PowerPoint
   - b) Excalidraw
   - c) HTML
   - d) PDF
   **Answer**: b

2. **Multiple choice**: Where do visual outputs get their branding from?
   - a) Each output is styled manually
   - b) The workspace theme set in cogni-workspace
   - c) A separate design tool
   - d) Claude's default styling
   **Answer**: b

### Recap

- 6 deliverable types for different communication needs
- 3 rendering engines: PPTX, Excalidraw, HTML
- Theme integration ensures consistent branding
- Choose format based on audience and context

---

## Module 2: Presentation Briefs & Slide Decks

### Theory (3 min)

**Presentation brief** — the planning step before designing slides:
- Defines slide-by-slide content structure
- Maps narrative arc to slide sequence
- Specifies key messages per slide
- Identifies data visualizations needed

**Slide deck generation** (.pptx):
- Creates formatted PowerPoint presentations
- Applies workspace theme (colors, fonts)
- Includes speaker notes
- Handles data visualizations (charts, tables)

**Best practice workflow**:
1. Start with polished narrative (from cogni-narrative)
2. Generate presentation brief (structure and content plan)
3. Review and adjust the brief
4. Generate slide deck from the brief
5. Fine-tune in PowerPoint if needed

### Demo

Walk through the brief-to-deck workflow:
1. Take a polished narrative (from Course 3 or sample)
2. Generate a presentation brief
3. Show the slide-by-slide structure
4. Generate the slide deck
5. Open the resulting .pptx and walk through slides

### Exercise

Ask the user to:
1. Take their narrative or polished document from previous courses
2. Ask Claude: "Create a presentation brief for this content"
3. Review the brief: Does the slide flow make sense? Are key messages clear?
4. Generate the slide deck from the brief

If no narrative available, create `_teacher-exercises/presentation-content.md`:

```markdown
# Digital Strategy Recommendation

## The Challenge
Mid-market companies are falling behind in AI adoption.
73% plan to increase spending, but only 28% have a clear strategy.

## Our Approach
1. Assessment: Evaluate current AI maturity
2. Roadmap: Prioritize high-impact use cases
3. Pilot: Launch first AI project within 90 days
4. Scale: Expand based on measured results

## Expected Results
- 2.3x average ROI within 18 months
- 40% reduction in manual analysis time
- Measurable improvement in decision quality
```

### Quiz

1. **Multiple choice**: What's the recommended order for creating presentations?
   - a) Jump straight to slide deck
   - b) Narrative → Brief → Review → Slide deck
   - c) Slide deck → Brief → Narrative
   - d) Brief → Narrative → Slide deck
   **Answer**: b

2. **Hands-on**: How many slides did your presentation brief recommend? Does the flow work?

### Recap

- Brief first, deck second — plan before designing
- Briefs map narrative arc to slide sequence
- Slide decks get workspace theme automatically
- Fine-tune in PowerPoint after generation

---

## Module 3: Big Picture Journey Maps

### Theory (3 min)

**Big Picture Journey Maps** use Excalidraw to create strategic overviews
and process visualizations. These are the "hand-drawn" diagrams that feel
approachable and engaging in workshops and strategy sessions.

**Use cases**:
- Customer journey visualization
- Strategic roadmaps
- Process flows and workflows
- Ecosystem maps
- Transformation timelines

**Excalidraw advantages**:
- Hand-drawn aesthetic feels less formal, more collaborative
- Interactive: zoom, pan, explore details
- Easy to update and iterate
- Can be embedded in presentations or shared standalone

**Creating journey maps**:
1. Provide the content/process to visualize
2. Specify the type: journey, roadmap, process, ecosystem
3. Claude generates the Excalidraw diagram
4. Review and refine interactively

### Demo

Walk through creating a journey map:
1. Define a simple process (e.g., the TIPS pipeline from Courses 4-5)
2. Ask Claude to create a big picture journey map
3. Show the resulting Excalidraw diagram
4. Demonstrate interactive exploration
5. Show how to iterate on the design

### Exercise

Ask the user to:
1. Choose a process they frequently explain to clients
2. Ask Claude: "Create a big picture journey map for [their process]"
3. Review the result: Is the flow clear? Are the right elements highlighted?
4. Request one refinement

### Quiz

1. **Multiple choice**: Why use Excalidraw over PowerPoint for journey maps?
   - a) It's faster to create
   - b) Hand-drawn style feels more collaborative and approachable
   - c) It's required for consulting
   - d) It has more features
   **Answer**: b

2. **Open-ended**: Name one consulting scenario where a big picture map would be more effective than slides.

### Recap

- Big picture maps = strategic overviews in hand-drawn style
- Excalidraw: approachable, interactive, easy to iterate
- Great for workshops, strategy sessions, client discussions
- Provides visual complement to formal slide decks

---

## Module 4: Web Narratives & Posters

### Theory (3 min)

**Scrollable web narratives** (HTML):
- Interactive online reports that scroll like a story
- Embed data visualizations, charts, and images
- Perfect for sharing insights digitally
- Can be hosted on any web server or shared as files
- Responsive design works on desktop and mobile

**Poster storyboards**:
- Visual layouts for print or digital display
- Event posters, infographic-style summaries
- Combine text, visuals, and data in a single view
- Export as PDF or image formats

**When to use each**:
| Format | Audience | Channel | Duration |
|--------|----------|---------|----------|
| Web narrative | Remote stakeholders | Email/link | 5-10 min read |
| Poster | Event attendees | Print/screen | 2-3 min scan |
| Slides | Meeting attendees | Presentation | 20-45 min talk |
| Journey map | Workshop participants | Interactive | Ongoing reference |

### Demo

Walk through creating a web narrative:
1. Take polished content from previous courses
2. Generate a scrollable web narrative
3. Show the HTML output — sections, transitions, embedded data
4. Discuss sharing options (file, hosted, embedded)

Walk through creating a poster:
1. Condense key findings into poster format
2. Show the visual layout
3. Discuss print vs. digital display options

### Exercise

Ask the user to:
1. Choose content from a previous exercise
2. Pick the most suitable format for their use case: web narrative or poster
3. Generate it with Claude
4. Review: Does the format match the communication need?

### Quiz

1. **Multiple choice**: When is a web narrative better than a slide deck?
   - a) For live presentations
   - b) For sharing insights digitally with remote stakeholders
   - c) For print materials
   - d) For workshop exercises
   **Answer**: b

2. **Multiple choice**: Poster storyboards are best for:
   - a) Detailed analysis with many data points
   - b) Quick visual summaries for events or displays
   - c) Interactive exploration
   - d) Long-form reading
   **Answer**: b

### Recap

- Web narratives: interactive scrollable reports for digital sharing
- Posters: visual summaries for events and displays
- Choose format based on audience, channel, and attention span
- All formats use workspace theme for consistency

---

## Module 5: The Complete Deliverable Pipeline

### Theory (3 min)

The full cogni-works pipeline from research to visual delivery:

```
Research (tips) → Select (tips) → Report (tips) →
Verify (claims) → Polish (copywriting) → Narrate (narrative) →
Adapt (narrative) → Visualize (visual)
```

**Choosing the right output**:
- Board meeting: Slide deck + executive brief
- Client workshop: Journey map + presentation
- Digital report: Web narrative + one-pager
- Event: Poster + visual assets
- Sales pitch: Slide deck with portfolio messaging

**Practical tips for consultants**:
1. Start visual planning early — don't wait until content is final
2. Use presentation briefs to align with stakeholders on structure
3. Generate multiple formats from the same content — reuse is free
4. Always apply the workspace theme before generating visuals
5. Review all visual outputs — AI-generated designs may need refinement

### Demo

Walk through the complete pipeline:
1. Show the journey from raw research to final visual deliverable
2. Recap each plugin's role in the chain
3. Show multiple outputs from the same source content
4. Discuss the time savings vs. traditional consulting workflows

### Exercise

Ask the user to:
1. Map their current consulting workflow to the cogni-works pipeline
2. Identify: Where do they spend the most time today?
3. Which cogni-works tools would save the most time?
4. Plan one real project deliverable using the full pipeline

### Quiz

1. **Hands-on**: Describe your ideal deliverable pipeline for your next client project using cogni-works tools.

2. **Multiple choice**: What should you always set up before generating visual deliverables?
   - a) A new Claude account
   - b) The workspace theme for consistent branding
   - c) A paid Excalidraw subscription
   - d) A design brief from a graphic designer
   **Answer**: b

### Recap

- Full pipeline: research → verify → polish → narrate → visualize
- Choose output format based on audience, channel, attention span
- Generate multiple formats from same content
- Workspace theme ensures brand consistency throughout

---

## Course Completion

Congratulations! You've completed the entire cogni-teacher curriculum!

**Your cogni-works toolkit**:
1. **Claude Cowork** — Your agentic AI platform
2. **cogni-workspace** — Shared project foundation
3. **cogni-obsidian** — Knowledge management dashboard
4. **cogni-copywriting** — Document polishing & stakeholder review
5. **cogni-narrative** — Executive narrative transformation
6. **cogni-claims** — Citation verification
7. **cogni-tips** — Strategic trend research pipeline
8. **cogni-portfolio** — Product/service messaging
9. **cogni-visual** — Presentations & visual deliverables

**The consulting workflow**:
```
Workspace Setup → Research → Analyze → Write → Verify → Polish → Present
```

Every step has a cogni-works plugin. Your expertise drives the strategy;
the tools execute the heavy lifting.
