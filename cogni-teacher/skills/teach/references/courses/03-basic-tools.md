# Course 3: Basic Tools

**Duration**: 45 minutes | **Modules**: 5 | **Prerequisites**: Course 2
**Plugins**: cogni-copywriting, cogni-narrative, cogni-claims
**Audience**: Consultants producing and verifying professional documents

---

## Module 1: Document Polishing with cogni-copywriting

### Theory (3 min)

**cogni-copywriting** polishes documents for executive readability. It applies
professional messaging frameworks to transform rough drafts into polished outputs.

**Six messaging frameworks**:
| Framework | Best For |
|-----------|----------|
| BLUF (Bottom Line Up Front) | Memos, status updates |
| Pyramid Principle | Strategy docs, analyses |
| SCQA (Situation-Complication-Question-Answer) | Problem-solving docs |
| STAR (Situation-Task-Action-Result) | Case studies, reviews |
| PSB (Problem-Solution-Benefit) | Proposals, pitches |
| FAB (Features-Advantages-Benefits) | Product/service descriptions |

**Key features**:
- Readability scoring: Flesch (English, target 50-60), Amstad (German, target 30-50)
- Bilingual support (English/German with language-specific style rules)
- Power Positions (IS-DOES-MEANS) for sales messaging
- Scope control: full, structure, tone, or formatting only

**Command**: `/copywrite <file> [--scope=full|structure|tone|formatting]`

### Demo

Walk through polishing a document:
1. Show a rough draft memo (create sample file)
2. Run `/copywrite memo.md --scope=full`
3. Compare before and after
4. Point out readability scores and framework application

### Exercise

Create a sample file `_teacher-exercises/rough-memo.md` with content:

```markdown
# Q1 Update

So basically we did a lot of stuff this quarter. Revenue went up by 15% which is
pretty good I think. We hired 3 new people. The client project is going ok but
there are some issues with the timeline. We need to figure out the budget
situation soon because it's getting complicated. Also the new tool we bought
is working well and the team likes it.
```

Ask the user to:
1. Run `/copywrite _teacher-exercises/rough-memo.md`
2. Compare the original and polished versions
3. Note which framework was applied and why

### Quiz

1. **Multiple choice**: Which framework is best for a status update memo?
   - a) FAB
   - b) BLUF (Bottom Line Up Front)
   - c) STAR
   - d) PSB
   **Answer**: b

2. **Hands-on**: What readability score did your polished memo receive?

### Recap

- cogni-copywriting applies professional messaging frameworks
- Six frameworks for different document types
- Readability scoring ensures executive-friendly output
- Use `/copywrite` with scope control for targeted polishing

---

## Module 2: Stakeholder Review with cogni-copywriting

### Theory (3 min)

The **reader** feature simulates how different stakeholders would read your document.
Five parallel personas review simultaneously:

| Persona | Focus |
|---------|-------|
| Executive | Strategic value, ROI, decision clarity |
| Technical | Feasibility, accuracy, implementation |
| Legal | Risk, compliance, liability |
| Marketing | Messaging, positioning, audience fit |
| End-user | Usability, clarity, practical value |

Each persona asks questions and flags concerns from their perspective. After
individual reviews, a **cross-persona synthesis** identifies consensus issues
and conflicting viewpoints.

**Optional auto-improve**: By default, the document is automatically improved
based on feedback. Use `--no-improve` to get feedback only.

**Command**: `/review-doc <file> [--no-improve] [--personas=exec,tech,legal]`

### Demo

Walk through a stakeholder review:
1. Take the polished memo from Module 1
2. Run `/review-doc polished-memo.md`
3. Show each persona's feedback
4. Show the cross-persona synthesis
5. Show the auto-improved version

### Exercise

Ask the user to:
1. Run `/review-doc` on their polished memo from Module 1
2. Read the executive persona's feedback
3. Read the synthesis — what consensus issues were found?

### Quiz

1. **Multiple choice**: How many personas review a document by default?
   - a) 2
   - b) 3
   - c) 5
   - d) 7
   **Answer**: c

2. **Open-ended**: Which persona's feedback was most useful for your memo? Why?

### Recap

- `/review-doc` simulates 5 stakeholder perspectives
- Cross-persona synthesis finds consensus and conflicts
- Auto-improve applies feedback automatically
- Filter personas with `--personas=` flag

---

## Module 3: Executive Narratives with cogni-narrative

### Theory (3 min)

**cogni-narrative** transforms structured content (research, data, analyses) into
compelling executive narratives using story arc frameworks.

**Six story arc frameworks**:
| Arc | Structure | Best For |
|-----|-----------|----------|
| Corporate Visions | Why Change → Why Now → Why You → Why Pay | Sales, pitches |
| Technology Futures | Emerging → Converging → Possible → Required | Tech strategy |
| Competitive Intelligence | Landscape → Shifts → Positioning → Implications | Market analysis |
| Strategic Foresight | Signals → Scenarios → Strategies → Decisions | Planning |
| Industry Transformation | Forces → Friction → Evolution → Leadership | Change management |
| Trend Panorama | Forces → Impact → Horizons → Foundations | Trend reports |

Output: 1,450-1,900 word executive narrative with 8 narrative techniques
(Pyramid Principle, Number Plays, etc.).

**Commands**:
- `/narrative [--arc=<id>] [--lang=en|de]` — Create narrative
- `/narrative-review <file>` — Score against quality gates
- `/narrative-adapt <file> --format=brief|talking-points|one-pager` — Create derivatives

### Demo

Walk through creating a narrative:
1. Show sample input (structured research notes)
2. Run `/narrative --arc=corporate-visions`
3. Walk through the output structure
4. Run `/narrative-review` on the result
5. Show the quality scorecard

### Exercise

Create a sample file `_teacher-exercises/research-notes.md` with content:

```markdown
# Digital Transformation Research

## Key Findings
- 73% of mid-market companies plan to increase AI spending in 2026
- Average ROI on AI projects: 2.3x within 18 months
- Main barriers: data quality (45%), talent shortage (38%), change resistance (31%)

## Market Context
- Cloud spending growing 22% YoY
- AI-native startups disrupting traditional consulting
- Client expectations shifting toward data-driven insights

## Recommendations
- Start with high-impact, low-complexity AI use cases
- Invest in data quality before scaling AI
- Build internal AI literacy programs
```

Ask the user to:
1. Run `/narrative --arc=strategic-foresight` on the research notes
2. Review the output — how was the data woven into a story?
3. Run `/narrative-review` to see the quality score

### Quiz

1. **Multiple choice**: Which arc is best for a sales pitch narrative?
   - a) Strategic Foresight
   - b) Corporate Visions (Why Change → Why Now → Why You → Why Pay)
   - c) Trend Panorama
   - d) Industry Transformation
   **Answer**: b

2. **Hands-on**: What quality score did your narrative receive? What grade?

### Recap

- cogni-narrative transforms research into executive narratives
- 6 story arc frameworks for different use cases
- Review scoring with quality gates (0-100, A-F grades)
- Adapt to derivatives: briefs, talking points, one-pagers

---

## Module 4: Narrative Adaptation

### Theory (3 min)

Not every audience needs a full 1,800-word narrative. **cogni-narrative adapt**
condenses narratives into derivative formats while preserving the story arc structure:

| Format | Length | Use Case |
|--------|--------|----------|
| Executive Brief | 300-500 words | C-suite summary, board prep |
| Talking Points | Bullet format | Presentations, speaking notes |
| One-Pager | ~1 page | Leave-behinds, quick reads |

The adaptation preserves:
- Story arc structure (same sections, same flow)
- Key data points and citations
- Narrative techniques (just compressed)

**Cross-plugin integration**: A polished narrative can be:
1. Adapted to talking points → used in presentations (cogni-visual)
2. Adapted to one-pager → polished further (cogni-copywriting)
3. Claims in the narrative → verified (cogni-claims)

### Demo

Walk through adaptation:
1. Take the narrative from Module 3
2. Run `/narrative-adapt narrative.md --format=brief`
3. Show the executive brief
4. Run `/narrative-adapt narrative.md --format=talking-points`
5. Compare the three formats side by side

### Exercise

Ask the user to:
1. Run `/narrative-adapt` on their narrative from Module 3 to create a one-pager
2. Compare: full narrative vs. one-pager — what was kept, what was cut?

### Quiz

1. **Multiple choice**: Which format is best for a board meeting leave-behind?
   - a) Full narrative
   - b) Talking points
   - c) One-pager
   - d) Executive brief
   **Answer**: c

2. **Open-ended**: Name one cross-plugin workflow involving narrative adaptation.

### Recap

- Three derivative formats: brief, talking points, one-pager
- Arc structure preserved in all formats
- Cross-plugin integration with copywriting, visual, claims
- Adapt once, use across deliverables

---

## Module 5: Claim Verification with cogni-claims

### Theory (3 min)

**cogni-claims** verifies that sourced claims in your documents actually match
their cited sources. It catches:

| Deviation Type | Example |
|----------------|---------|
| Misquotation | "Revenue grew 20%" when source says 18% |
| Unsupported conclusion | Drawing a conclusion the source doesn't support |
| Selective omission | Citing a study but omitting its caveats |
| Data staleness | Using outdated figures when newer data exists |
| Source contradiction | Claiming X when source says the opposite |

**Five-mode workflow**:
1. **Submit** — Register claims with their source URLs
2. **Verify** — Fetch sources and compare claims
3. **Dashboard** — Review all claims and their status
4. **Inspect** — Open source in browser to see context
5. **Resolve** — Accept, revise, or reject deviations

**Severity levels**: low, medium, high, critical

**Command**: `/claims <mode> [options]`

### Demo

Walk through claim verification:
1. Show a document with sourced claims
2. Submit claims: `/claims submit`
3. Verify: `/claims verify`
4. Show the dashboard: `/claims dashboard`
5. Show a deviation and the resolution options

### Exercise

Create a sample file `_teacher-exercises/claims-doc.md` with content:

```markdown
# Market Analysis

According to [Gartner](https://www.gartner.com), global IT spending will
reach $5.5 trillion in 2026, representing a 9.8% increase from 2025.

A [McKinsey report](https://www.mckinsey.com) found that 65% of organizations
now regularly use generative AI, nearly double from the previous year.
```

Ask the user to:
1. Submit the claims: `/claims submit`
2. Verify them: `/claims verify`
3. Review the dashboard: `/claims dashboard`
4. Discuss: were any deviations found? What type?

### Quiz

1. **Multiple choice**: What does "selective omission" mean in claim verification?
   - a) The claim is completely false
   - b) The claim cites a source but omits important caveats from it
   - c) The source URL is broken
   - d) The claim uses outdated data
   **Answer**: b

2. **Multiple choice**: What are the five modes of cogni-claims?
   - a) Create, edit, delete, archive, publish
   - b) Submit, verify, dashboard, inspect, resolve
   - c) Write, review, approve, reject, publish
   - d) Scan, detect, alert, fix, confirm
   **Answer**: b

### Recap

- cogni-claims catches citation errors before content ships
- Five deviation types: misquotation, unsupported, omission, staleness, contradiction
- Five-mode workflow: submit → verify → dashboard → inspect → resolve
- Essential quality gate for consulting deliverables

---

## Course Completion

Congratulations! You now command three essential cogni-works tools:
- **cogni-copywriting**: Polish documents with messaging frameworks and stakeholder review
- **cogni-narrative**: Transform research into executive narratives with story arcs
- **cogni-claims**: Verify sourced claims to ensure accuracy

**Cross-plugin workflow**: Research → Narrative → Review → Claims → Polish

**Next recommended course**: Course 4 — Trend Scouting & Selection
